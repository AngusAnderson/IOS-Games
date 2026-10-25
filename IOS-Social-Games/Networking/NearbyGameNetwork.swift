import Foundation
import Network
import Observation

@MainActor
@Observable
final class NearbyGameNetwork {
    static let serviceType = "_imposter-game._tcp"

    private(set) var localID = UUID()
    var localName: String

    var isHosting = false
    var isJoining = false
    var isConnected = false

    var discoveredHosts: [HostInfo] = []
    var connectionError: String?

    var onMessage: ((GameMessage, UUID?) -> Void)?
    var onAssignedID: ((UUID) -> Void)?

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

    struct HostInfo: Identifiable, Hashable {
        let id: UUID
        let name: String
        let endpoint: NWEndpoint
    }

    // This is transport metadata, separate from game messages.
    nonisolated private enum Packet: Codable, Sendable {
        case hello(name: String)
        case welcome(playerID: UUID)
        case game(GameMessage)
    }

    init(name: String = "Player") {
        localName = name
    }

    // MARK: - Hosting

    func startHosting() {
        stopNetworking()
        connectionError = nil

        let currentSession = sessionID

        do {
            let listener = try NWListener(using: .tcp)

            listener.service = NWListener.Service(
                name: localName,
                type: Self.serviceType
            )

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self,
                          self.sessionID == currentSession
                    else {
                        return
                    }

                    switch state {
                    case .ready:
                        self.isHosting = true
                        print("HOST: Listener ready")

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
                Task { @MainActor in
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
            connectionError = "Could not create listener: \(error)"
        }
    }

    // MARK: - Discovery

    func startBrowsing() {
        stopNetworking()
        connectionError = nil
        
        print("NETWORK VERSION: TCP / NWBrowser")
        print("Browsing service:", Self.serviceType)

        let currentSession = sessionID

        let browser = NWBrowser(
            for: .bonjour(
                type: Self.serviceType,
                domain: nil
            ),
            using: .tcp
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

    func join(host: HostInfo) async {
        guard !isJoining, !isConnected else {
            return
        }

        connectionError = nil
        isJoining = true

        // Stop discovery only. Do not stop the entire session.
        browser?.cancel()
        browser = nil

        let id = UUID()
        let currentSession = sessionID

        hostConnectionID = id

        let connection = NWConnection(
            to: host.endpoint,
            using: .tcp
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
                reason: "Joining timed out. Check the host is still in its lobby."
            )
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
                    self.close(
                        id,
                        reason: "Connection failed: \(error)"
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
        case .hello(let name):
            guard isHosting,
                  !registeredPlayers.contains(id)
            else {
                return
            }

            let name = name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty, name.count <= 40 else {
                close(id, reason: "Invalid player name.")
                return
            }

            registeredPlayers.insert(id)

            // The host chooses the player's ID.
            send(.welcome(playerID: id), to: id)

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

        case .game(let message):
            if isHosting {
                guard registeredPlayers.contains(id) else {
                    return
                }

                // Clients can submit actions, not overwrite state.
                switch message {
                case .submitClue, .submitVote, .leave:
                    onMessage?(message, id)

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
        to id: UUID
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
                    guard let error else {
                        return
                    }

                    Task { @MainActor in
                        guard let self,
                              self.sessionID == session
                        else {
                            return
                        }

                        self.close(
                            id,
                            reason: "Send failed: \(error)"
                        )
                    }
                }
            )
        } catch {
            close(id, reason: "Could not encode message: \(error)")
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

        connection.stateUpdateHandler = nil
        connection.cancel()

        buffers.removeValue(forKey: id)
        registeredPlayers.remove(id)

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
    }

    func stopNetworking() {
        // Ignore callbacks from the previous session.
        sessionID = UUID()

        timeoutTask?.cancel()
        timeoutTask = nil

        browser?.cancel()
        browser = nil

        listener?.cancel()
        listener = nil

        for connection in connections.values {
            connection.stateUpdateHandler = nil
            connection.cancel()
        }

        connections.removeAll()
        buffers.removeAll()
        registeredPlayers.removeAll()

        hostConnectionID = nil

        isHosting = false
        isJoining = false
        isConnected = false
        discoveredHosts = []
    }

    private enum TransportError: Error {
        case invalidPacket
    }
}
