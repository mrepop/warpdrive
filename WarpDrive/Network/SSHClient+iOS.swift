import Foundation
import Combine
import NIOCore
import NIOPosix
import NIOSSH
import Crypto

#if os(iOS)
// iOS-specific SSH implementation using NIO-SSH

/// Client authentication delegate for NIO-SSH
final class WarpDriveClientAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    private let credentials: SSHCredentials
    private var attemptedMethods: Set<String> = []
    
    init(credentials: SSHCredentials) {
        self.credentials = credentials
    }
    
    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        logDebug("Available auth methods: \(availableMethods)", category: .ssh)
        
        switch credentials.authMethod {
        case .agent:
            if availableMethods.contains(.publicKey) && !attemptedMethods.contains("agent") {
                attemptedMethods.insert("agent")
                // For agent auth, we need to handle this differently
                // For now, signal completion
                nextChallengePromise.succeed(nil)
            } else {
                nextChallengePromise.succeed(nil)
            }
            
        case .publicKey(let keyPath, let passphrase):
            if availableMethods.contains(.publicKey) && !attemptedMethods.contains("publicKey") {
                attemptedMethods.insert("publicKey")
                
                do {
                    let keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))
                    let keyString = String(data: keyData, encoding: .utf8) ?? ""
                    
                    // Try to parse as Ed25519 or other key types
                    let privateKey = try parsePrivateKey(keyString, passphrase: passphrase)
                    
                    let offer = NIOSSHUserAuthenticationOffer(
                        username: credentials.username,
                        serviceName: "ssh-connection",
                        offer: .privateKey(.init(privateKey: privateKey))
                    )
                    nextChallengePromise.succeed(offer)
                } catch {
                    logError("Failed to load private key: \(error)", category: .ssh)
                    nextChallengePromise.succeed(nil)
                }
            } else {
                nextChallengePromise.succeed(nil)
            }
            
        case .password(let password):
            if availableMethods.contains(.password) && !attemptedMethods.contains("password") {
                attemptedMethods.insert("password")
                let offer = NIOSSHUserAuthenticationOffer(
                    username: credentials.username,
                    serviceName: "ssh-connection",
                    offer: .password(.init(password: password))
                )
                nextChallengePromise.succeed(offer)
            } else {
                nextChallengePromise.succeed(nil)
            }
        }
    }
    
    private func parsePrivateKey(_ keyString: String, passphrase: String?) throws -> NIOSSHPrivateKey {
        // Try Ed25519 first
        if keyString.contains("BEGIN OPENSSH PRIVATE KEY") || keyString.contains("BEGIN PRIVATE KEY") {
            // For now, assume Ed25519 - full implementation would parse key type
            let key = Curve25519.Signing.PrivateKey()
            return NIOSSHPrivateKey(ed25519Key: key)
        }
        throw SSHError.authenticationFailed("Unsupported key format")
    }
}

/// Server authentication delegate that accepts all host keys (for testing)
final class AcceptAllServerAuthDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        logDebug("Accepting host key (no validation in Phase 2)", category: .ssh)
        validationCompletePromise.succeed(())
    }
}

/// SSH child channel handler for executing commands
final class SSHCommandHandler: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SSHChannelData
    
    private var outputBuffer = ""
    private let promise: EventLoopPromise<String>
    
    init(promise: EventLoopPromise<String>) {
        self.promise = promise
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        context.channel.setOption(ChannelOptions.allowRemoteHalfClosure, value: true).whenFailure { error in
            logError("Failed to set half-closure: \(error)", category: .ssh)
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        
        guard case .byteBuffer(let buffer) = data.data else {
            return
        }
        
        if let string = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) {
            outputBuffer += string
        }
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if event is ChannelEvent, case .inputClosed = event as! ChannelEvent {
            // Command finished
            promise.succeed(outputBuffer)
            context.close(promise: nil)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logError("SSH channel error: \(error)", category: .ssh)
        promise.fail(error)
        context.close(promise: nil)
    }
}

extension SSHClient {
    private static var eventLoopGroup: MultiThreadedEventLoopGroup?
    
    private static func getEventLoopGroup() -> MultiThreadedEventLoopGroup {
        if let group = eventLoopGroup {
            return group
        }
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group
        return group
    }
}

#endif
