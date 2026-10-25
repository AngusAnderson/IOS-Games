import Foundation
import Network
import Observation

@MainActor
@Observable
final class NearbyGameNetwork {
    static let serviceType = "_imposter-sec._tcp"

    private(set) var localID = UUID()
    var localName: String

    var isHosting = false
    var isJoining = false
    var isConnected = false

    var discoveredHosts: [HostInfo] = []
    var connectionError: String?

    var onMessage: ((GameMessage, UUID?) -> Void)?
    var onAssignedID: ((UUID) -> Void)?
    
    var onPlayerDisconnected: ((UUID) -> Void)?
    var admissionRejection: ((String) -> String?)?

    var isPreparingHost = false

    @ObservationIgnored
    private var listener: NWListener?

    @ObservationIgnored
    private var browser: NWBrowser?

    @ObservationIgnored
    private var connections: [UUID: NWConnection] = [:]

    @ObservationIgnored
    private var buffers: [UUID: Data] = [:]

    @ObservationIgnored
    private var registeredPlayers: Set<UUID> = []

    @ObservationIgnored
    private var hostConnectionID: UUID?

    @ObservationIgnored
    private var timeoutTask: Task<Void, Never>?

    @ObservationIgnored
    private var sessionID = UUID()

    private(set) var hostedRoomPassword: String?

    struct HostInfo: Identifiable, Hashable {
        let id: UUID
        let name: String
        let endpoint: NWEndpoint
    }

    nonisolated private enum Packet: Codable, Sendable {
        case hello(name: String)
        case welcome(playerID: UUID)
        case rejected(reason: String)
        case disconnected(reason: DisconnectReason)
        case game(GameMessage)
    }

    init(name: String = "Player") {
        localName = name
    }

    // MARK: - Hosting

    func startHosting(password: String) async {
        guard !isPreparingHost, !isHosting else {
            return
        }

        stopNetworking()

        connectionError = nil
        isPreparingHost = true

        let currentSession = sessionID

        hostedRoomPassword = password

        defer {
            if sessionID == currentSession {
                isPreparingHost = false
            }
        }

        do {
            let key = try await Task.detached(
                priority: .userInitiated
            ) {
                try RoomSecurity.deriveKey(from: password)
            }.value

            guard sessionID == currentSession else {
                return
            }

            let parameters = RoomSecurity.makeParameters(key: key)

            let listener = try NWListener(
                using: parameters
            )

            listener.service = NWListener.Service(
                name: localName,
                type: Self.serviceType
            )

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self,
                        self.sessionID == currentSession
                    else {
                        return
                    }

                    switch state {
                    case .ready:
                        self.isHosting = true
                        print("HOST: Protected listener ready")

                    case .failed(let error):
                        self.isHosting = false
                        self.connectionError =
                            "Hosting failed: \(error)"

                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    guard let self,
                        self.sessionID == currentSession
                    else {
                        connection.cancel()
                        return
                    }

                    self.attach(
                        connection,
                        id: UUID(),
                        isClient: false,
                        session: currentSession
                    )
                }
            }

            self.listener = listener

            listener.start(queue: .main)
        } catch {
            guard sessionID == currentSession else {
                return
            }

            connectionError =
                "Could not create protected room: \(error.localizedDescription)"
        }
    }

    // MARK: - Discovery

    func startBrowsing() {
        stopNetworking()
        connectionError = nil
        
        print("NETWORK VERSION: TCP / NWBrowser")
        print("Browsing service:", Self.serviceType)

        let currentSession = sessionID

        let discoveryParameters = NWParameters.tcp
        discoveryParameters.includePeerToPeer = true

        let browser = NWBrowser(
            for: .bonjour(
                type: Self.serviceType,
                domain: nil
            ),
            using: discoveryParameters
        )
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self,
                      self.sessionID == currentSession
                else {
                    return
                }

                if case .failed(let error) = state {
                    self.connectionError =
                        "Could not search for games: \(error)"
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self,
                      self.sessionID == currentSession
                else {
                    return
                }

                let previous = self.discoveredHosts

                self.discoveredHosts = results.compactMap { result in
                    guard case let .service(name, _, _, _) =
                        result.endpoint
                    else {
                        return nil
                    }

                    let id = previous.first {
                        $0.endpoint == result.endpoint
                    }?.id ?? UUID()

                    return HostInfo(
                        id: id,
                        name: name,
                        endpoint: result.endpoint
                    )
                }
                .sorted { $0.name < $1.name }
            }
        }

        self.browser = browser
        browser.start(queue: .main)
    }

    // MARK: - Joining

    func join(
        host: HostInfo,
        password: String
    ) async {
        guard !isJoining, !isConnected else {
            return
        }

        guard RoomSecurity.isValidPassword(password) else {
            connectionError = "Use a password of 16–128 characters."
            return
        }

        connectionError = nil
        isJoining = true

        let currentSession = sessionID

        do {
            let key = try await Task.detached(
                priority: .userInitiated
            ) {
                try RoomSecurity.deriveKey(from: password)
            }.value

            guard sessionID == currentSession else {
                return
            }

            browser?.cancel()
            browser = nil

            let id = UUID()

            hostConnectionID = id

            let connection = NWConnection(
                to: host.endpoint,
                using: RoomSecurity.makeParameters(key: key)
            )

            attach(
                connection,
                id: id,
                isClient: true,
                session: currentSession
            )

            timeoutTask?.cancel()

            timeoutTask = Task { [weak self] in
                do {
                    try await Task.sleep(for: .seconds(10))
                } catch {
                    return
                }

                guard let self,
                    self.sessionID == currentSession,
                    self.isJoining
                else {
                    return
                }

                self.close(
                    id,
                    reason:
                        "Could not enter the room. Check the password "
                        + "and that the host is still available."
                )
            }
        } catch {
            guard sessionID == currentSession else {
                return
            }

            isJoining = false

            connectionError =
                "Could not prepare connection: \(error.localizedDescription)"
        }
    }

    // MARK: - Connection lifecycle

    private func attach(
        _ connection: NWConnection,
        id: UUID,
        isClient: Bool,
        session: UUID
    ) {
        connections[id] = connection
        buffers[id] = Data()

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self,
                      self.sessionID == session,
                      self.connections[id] != nil
                else {
                    return
                }

                switch state {
                case .ready:
                    print("NETWORK: Connection ready: \(id)")

                    self.receiveNext(
                        id: id,
                        session: session
                    )

                    if isClient {
                        self.send(
                            .hello(name: self.localName),
                            to: id
                        )
                    }

                case .waiting(let error):
                    print("NETWORK: Waiting: \(error)")

                case .failed(let error):
                    let message: String

                    if isClient {
                        message =
                            "Could not establish a protected connection. "
                            + "Check the room password and host availability. "
                            + "(\(error))"
                    } else {
                        message =
                            "An incoming protected connection failed: \(error)"
                    }

                    self.close(
                        id,
                        reason: message
                    )

                case .cancelled:
                    self.close(id, reason: nil)

                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
    }

    // MARK: - Framed receiving

    private func receiveNext(
        id: UUID,
        session: UUID
    ) {
        guard let connection = connections[id] else {
            return
        }

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65_536
        ) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self,
                      self.sessionID == session,
                      self.connections[id] != nil
                else {
                    return
                }

                if let data, !data.isEmpty {
                    self.buffers[id, default: Data()].append(data)

                    do {
                        try self.processPackets(from: id)
                    } catch {
                        self.close(
                            id,
                            reason: "Invalid game message: \(error)"
                        )
                        return
                    }
                }

                if let error {
                    self.close(
                        id,
                        reason: "Receive failed: \(error)"
                    )
                } else if isComplete {
                    self.close(
                        id,
                        reason: "The other player disconnected."
                    )
                } else {
                    self.receiveNext(
                        id: id,
                        session: session
                    )
                }
            }
        }
    }

    private func processPackets(from id: UUID) throws {
        guard var buffer = buffers[id] else {
            return
        }

        // Each packet is a four-byte big-endian length,
        // followed by JSON.
        while buffer.count >= 4 {
            let length = buffer.prefix(4).reduce(UInt32(0)) {
                ($0 << 8) | UInt32($1)
            }

            guard length > 0, length <= 1_048_576 else {
                throw TransportError.invalidPacket
            }

            let packetLength = Int(length)

            guard buffer.count >= 4 + packetLength else {
                break
            }

            let payload = Data(
                buffer.dropFirst(4).prefix(packetLength)
            )

            buffer = Data(buffer.dropFirst(4 + packetLength))

            let packet = try JSONDecoder().decode(
                Packet.self,
                from: payload
            )

            handlePacket(packet, from: id)
        }

        if connections[id] != nil {
            buffers[id] = buffer
        }
    }

    private func handlePacket(
        _ packet: Packet,
        from id: UUID
    ) {
        switch packet {
        case .hello(let suppliedName):
            guard isHosting,
                  !registeredPlayers.contains(id)
            else {
                return
            }

            let name = suppliedName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty, name.count <= 40 else {
                send(
                    .rejected(reason: "Choose a name of 1–40 characters."),
                    to: id,
                    closeAfterSending: true
                )
                return
            }

            guard let admissionRejection else {
                send(
                    .rejected(reason: "The host is not ready for players."),
                    to: id,
                    closeAfterSending: true
                )
                return
            }

            if let reason = admissionRejection(name) {
                send(
                    .rejected(reason: reason),
                    to: id,
                    closeAfterSending: true
                )
                return
            }

            registeredPlayers.insert(id)

            send(
                .welcome(playerID: id),
                to: id
            )

            onMessage?(.join(name: name), id)

        case .welcome(let playerID):
            guard !isHosting,
                  id == hostConnectionID,
                  isJoining
            else {
                return
            }

            localID = playerID

            isJoining = false
            isConnected = true

            timeoutTask?.cancel()
            timeoutTask = nil

            onAssignedID?(playerID)

            print("CLIENT: Joined as \(playerID)")

        case .rejected(let reason):
            guard !isHosting,
                  id == hostConnectionID
            else {
                return
            }

            close(
                id,
                reason: reason
            )

        case .disconnected(let reason):
            guard !isHosting,
                  id == hostConnectionID
            else {
                return
            }

            close(
                id,
                reason: reason.message
            )

        case .game(let message):
            if isHosting {
                guard registeredPlayers.contains(id) else {
                    return
                }

                switch message {
                case .submitClue, .submitVote:
                    onMessage?(message, id)

                case .leave:
                    close(id, reason: nil)

                default:
                    break
                }
            } else {
                guard id == hostConnectionID,
                      isConnected
                else {
                    return
                }

                switch message {
                case .publicState, .privateRole, .playerJoined:
                    onMessage?(message, nil)

                default:
                    break
                }
            }
        }
    }

    // MARK: - Sending

    func sendToHost(_ message: GameMessage) async {
        guard isConnected, let id = hostConnectionID else {
            connectionError = "You are not connected to a host."
            return
        }

        send(.game(message), to: id)
    }

    func sendToPlayer(
        _ message: GameMessage,
        playerID: UUID
    ) async {
        guard registeredPlayers.contains(playerID) else {
            return
        }

        send(.game(message), to: playerID)
    }

    func broadcast(_ message: GameMessage) async {
        for id in registeredPlayers {
            send(.game(message), to: id)
        }
    }

    private func send(
        _ packet: Packet,
        to id: UUID,
        closeAfterSending: Bool = false
    ) {
        guard let connection = connections[id] else {
            return
        }

        let session = sessionID

        do {
            let payload = try JSONEncoder().encode(packet)

            guard payload.count <= 1_048_576 else {
                throw TransportError.invalidPacket
            }

            var length = UInt32(payload.count).bigEndian

            var framed = withUnsafeBytes(of: &length) {
                Data($0)
            }

            framed.append(payload)

            connection.send(
                content: framed,
                completion: .contentProcessed { [weak self] error in
                    Task { @MainActor [weak self] in
                        guard let self,
                              self.sessionID == session
                        else {
                            return
                        }

                        if let error {
                            self.close(
                                id,
                                reason: "Send failed: \(error)"
                            )
                        } else if closeAfterSending {
                            self.close(id, reason: nil)
                        }
                    }
                }
            )

            if closeAfterSending {
                Task { @MainActor [weak self] in
                    do {
                        try await Task.sleep(for: .seconds(2))
                    } catch {
                        return
                    }

                    guard let self,
                          self.sessionID == session
                    else {
                        return
                    }

                    self.close(id, reason: nil)
                }
            }
        } catch {
            close(
                id,
                reason: "Could not encode message: \(error)"
            )
        }
    }

    // MARK: - Cleanup

    private func close(
        _ id: UUID,
        reason: String?
    ) {
        guard let connection = connections.removeValue(
            forKey: id
        ) else {
            return
        }

        let wasRegistered = registeredPlayers.remove(id) != nil

        connection.stateUpdateHandler = nil
        connection.cancel()

        buffers.removeValue(forKey: id)

        if id == hostConnectionID {
            timeoutTask?.cancel()
            timeoutTask = nil

            hostConnectionID = nil
            isJoining = false
            isConnected = false
        }

        if let reason {
            connectionError = reason
        }

        if isHosting, wasRegistered {
            onPlayerDisconnected?(id)
        }
    }

    func stopNetworking() {
        sessionID = UUID()

        timeoutTask?.cancel()
        timeoutTask = nil

        browser?.cancel()
        browser = nil

        listener?.cancel()
        listener = nil

        hostedRoomPassword = nil

        for connection in connections.values {
            connection.stateUpdateHandler = nil
            connection.cancel()
        }

        connections.removeAll()
        buffers.removeAll()
        registeredPlayers.removeAll()

        hostConnectionID = nil

        isHosting = false
        isPreparingHost = false
        isJoining = false
        isConnected = false
        discoveredHosts = []
    }

    private enum TransportError: Error {
        case invalidPacket
    }
    
    // MARK: - Host moderation

    func removePlayer(_ playerID: UUID) {
        guard isHosting,
              registeredPlayers.contains(playerID)
        else {
            return
        }

        disconnectPlayer(
            playerID,
            reason: .removedByHost
        )
    }

    private func disconnectPlayer(
        _ playerID: UUID,
        reason: DisconnectReason
    ) {
        guard connections[playerID] != nil else {
            return
        }

        let wasRegistered = registeredPlayers.remove(playerID) != nil

        if wasRegistered {
            onPlayerDisconnected?(playerID)
        }

        send(
            .disconnected(reason: reason),
            to: playerID,
            closeAfterSending: true
        )
    }
}
