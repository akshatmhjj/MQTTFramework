import Foundation
import Network

protocol TransportDelegate: AnyObject {
    func transport(_ transport: Transport, didUpdateState state: NWConnection.State)
    func transport(_ transport: Transport, didReceiveData data: Data)
    func transport(_ transport: Transport, didError error: Error)
}

/// A low-level networking layer that wraps Apple's `Network.framework` to provide
/// asynchronous TCP and TLS communication for the MQTT protocol.
class Transport: @unchecked Sendable {
    /// The underlying network connection.
    private var connection: NWConnection?
    
    /// The serial queue for handling connection events and data processing.
    private let queue = DispatchQueue(label: "com.mqtt.transport")
    
    /// Delegate to receive connection state updates and incoming data.
    weak var delegate: TransportDelegate?
    
    /// Establishes a connection to the specified host and port.
    /// - Parameters:
    ///   - host: The hostname or IP address of the MQTT broker.
    ///   - port: The port number (usually 1883 for TCP or 8883 for TLS).
    ///   - useTLS: Whether to use Secure Sockets Layer (TLS).
    func connect(host: String, port: UInt16, useTLS: Bool = false) {
        let hostName = NWEndpoint.Host(host)
        let portNumber = NWEndpoint.Port(rawValue: port)!
        let parameters: NWParameters = useTLS ? .tls : .tcp
        
        connection = NWConnection(host: hostName, port: portNumber, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            self.delegate?.transport(self, didUpdateState: state)
            if case .ready = state {
                self.receive()
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    func send(data: Data, completion: @escaping @Sendable (Error?) -> Void) {
        connection?.send(content: data, completion: .contentProcessed({ error in
            completion(error)
        }))
    }
    
    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                self.delegate?.transport(self, didReceiveData: data)
            }
            
            if let error = error {
                self.delegate?.transport(self, didError: error)
                return
            }
            
            if !isComplete {
                self.receive()
            }
        }
    }
}
