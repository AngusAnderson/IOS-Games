import Foundation
import Network
import Security
import CommonCrypto

nonisolated enum RoomSecurity {
    static let minimumPasswordLength = 4
    static let maximumPasswordLength = 128

    private static let derivationSalt = Data(
        "imposter-room-tls-psk-v1".utf8
    )

    private static let keyIdentity = Data(
        "imposter-room-v1".utf8
    )

    enum SecurityError: LocalizedError {
        case invalidPassword
        case keyDerivationFailed
        case randomGenerationFailed

        var errorDescription: String? {
            switch self {
            case .invalidPassword:
                return "Use a password of 4–128 characters."

            case .keyDerivationFailed:
                return "Could not prepare the room security key."

            case .randomGenerationFailed:
                return "Could not generate a random room password."
            }
        }
    }

    static func isValidPassword(_ password: String) -> Bool {
        (minimumPasswordLength...maximumPasswordLength)
            .contains(password.count)
    }

    static func generatePassword() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 18)

        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(
                kSecRandomDefault,
                buffer.count,
                buffer.baseAddress!
            )
        }

        guard status == errSecSuccess else {
            throw SecurityError.randomGenerationFailed
        }

        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    static func deriveKey(from password: String) throws -> Data {
        guard isValidPassword(password) else {
            throw SecurityError.invalidPassword
        }

        let passwordBytes = Array(password.utf8)

        var derivedBytes = [UInt8](
            repeating: 0,
            count: 32
        )

        let status = passwordBytes.withUnsafeBytes { passwordBuffer in
            derivationSalt.withUnsafeBytes { saltBuffer in
                derivedBytes.withUnsafeMutableBytes { outputBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer
                            .bindMemory(to: Int8.self)
                            .baseAddress,
                        passwordBytes.count,
                        saltBuffer
                            .bindMemory(to: UInt8.self)
                            .baseAddress,
                        derivationSalt.count,
                        CCPseudoRandomAlgorithm(
                            kCCPRFHmacAlgSHA256
                        ),
                        200_000,
                        outputBuffer
                            .bindMemory(to: UInt8.self)
                            .baseAddress,
                        outputBuffer.count
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw SecurityError.keyDerivationFailed
        }

        return Data(derivedBytes)
    }

    static func makeParameters(key: Data) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let options = tls.securityProtocolOptions

        let sharedKey = key.withUnsafeBytes {
            DispatchData(bytes: $0)
        }

        let identity = keyIdentity.withUnsafeBytes {
            DispatchData(bytes: $0)
        }

        sec_protocol_options_add_pre_shared_key(
            options,
            sharedKey as __DispatchData,
            identity as __DispatchData
        )

        sec_protocol_options_set_min_tls_protocol_version(
            options,
            .TLSv12
        )

        sec_protocol_options_set_max_tls_protocol_version(
            options,
            .TLSv12
        )

        sec_protocol_options_add_tls_ciphersuite(
            options,
            SSLCipherSuite(
                TLS_PSK_WITH_AES_128_GCM_SHA256
            )
        )

        return NWParameters(
            tls: tls,
            tcp: NWProtocolTCP.Options()
        )
    }
}
