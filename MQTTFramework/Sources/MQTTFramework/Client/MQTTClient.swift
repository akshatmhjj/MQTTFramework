import Foundation
import Network

/// The primary interface for interacting with an MQTT broker.
/// Manages connection state, packet routing, and provides high-level methods for
/// publishing and subscribing.
public class MQTTClient: @unchecked Sendable {
    /// Internal transport layer for TCP/TLS communication.
    private let transport = Transport()
    
    /// Unique identifier for this client.
    private var clientID: String
    
    /// Keep-alive interval in seconds.
    private var keepAlive: UInt16
    
    /// The current connection state of the client.
    private var state: State = .disconnected {
        didSet {
            // Notify delegate whenever state changes
            delegate?.mqttClient(self, didChangeState: state)
        }
    }
    
    /// Delegate to receive notifications about state changes, messages, and errors.
    public weak var delegate: MQTTClientDelegate?
    
    /// Initializes a new MQTT client.
    /// - Parameters:
    ///   - clientID: The ID used to identify the client to the broker. Defaults to a random UUID.
    ///   - keepAlive: The keep-alive interval in seconds. Defaults to 60.
    public init(clientID: String = "MQTTFramework_\(UUID().uuidString.prefix(8))", keepAlive: UInt16 = 60) {
        self.clientID = clientID
        self.keepAlive = keepAlive
        self.transport.delegate = self
    }
    
    /// Connects to the MQTT broker.
    /// - Parameters:
    ///   - host: The hostname or IP address of the broker.
    ///   - port: The port number (default 1883).
    ///   - useTLS: Whether to use TLS encryption.
    public func connect(host: String, port: UInt16 = 1883, useTLS: Bool = false) {
        state = .connecting
        transport.connect(host: host, port: port, useTLS: useTLS)
    }
    
    /// Gracefully disconnects from the MQTT broker by sending a DISCONNECT packet.
    public func disconnect() {
        state = .disconnecting
        let disconnect = DisconnectPacket()
        transport.send(data: disconnect.serialize()) { _ in
            self.transport.disconnect()
            self.state = .disconnected
        }
    }
    
    /// Publishes a message to a specific topic.
    /// - Parameters:
    ///   - topic: The topic to publish to.
    ///   - message: The raw payload data.
    ///   - qos: Quality of Service level (0, 1, or 2).
    ///   - retain: Whether the broker should retain this message.
    public func publish(topic: String, message: Data, qos: UInt8 = 0, retain: Bool = false) {
        let packet = PublishPacket(topic: topic, payload: message, qos: qos, retain: retain, packetID: qos > 0 ? 1 : nil)
        transport.send(data: packet.serialize()) { _ in }
    }
    
    /// Subscribes to a specific topic to receive messages.
    /// - Parameters:
    ///   - topic: The topic filter to subscribe to.
    ///   - qos: The maximum requested Quality of Service level.
    public func subscribe(to topic: String, qos: UInt8 = 0) {
        let packet = SubscribePacket(packetID: 1, topics: [(topic, qos)])
        transport.send(data: packet.serialize()) { _ in }
    }
}

extension MQTTClient: TransportDelegate {
    func transport(_ transport: Transport, didUpdateState transportState: NWConnection.State) {
        switch transportState {
        case .ready:
            sendConnectPacket()
        case .failed(let error):
            delegate?.mqttClient(self, didError: error)
            state = .disconnected
        case .cancelled:
            state = .disconnected
        default:
            break
        }
    }
    
    func transport(_ transport: Transport, didReceiveData data: Data) {
        // Basic packet router
        guard !data.isEmpty else { return }
        let typeByte = data[0] >> 4
        guard let type = MQTTPacketType(rawValue: typeByte) else { return }
        
        switch type {
        case .connack:
            if let packet = ConnAckPacket.parse(data: data) {
                if packet.returnCode == 0 {
                    state = .connected
                } else {
                    // Handle connection error
                }
            }
        case .publish:
            handlePublish(data: data)
        case .pingresp:
            // Handle ping response
            break
        default:
            break
        }
    }
    
    func transport(_ transport: Transport, didError error: Error) {
        delegate?.mqttClient(self, didError: error)
    }
    
    private func sendConnectPacket() {
        let connect = ConnectPacket(clientID: clientID, cleanSession: true, keepAlive: keepAlive, username: nil, password: nil)
        transport.send(data: connect.serialize()) { _ in }
    }
    
    private func handlePublish(data: Data) {
        // Very basic parser for demonstration
        // In a full implementation, we'd use a dedicated parser for each packet type
        var offset = 1 // Skip header
        
        // Decode remaining length
        var remainingLength = 0
        var multiplier = 1
        repeat {
            let byte = data[offset]
            remainingLength += Int(byte & 127) * multiplier
            multiplier *= 128
            offset += 1
        } while (data[offset-1] & 128) != 0
        
        // Decode Topic
        let topicLen = Int(data[offset]) << 8 | Int(data[offset + 1])
        offset += 2
        guard let topic = String(data: data.subdata(in: offset..<(offset+topicLen)), encoding: .utf8) else { return }
        offset += topicLen
        
        let message = data.subdata(in: offset..<data.count)
        delegate?.mqttClient(self, didReceiveMessage: message, onTopic: topic)
    }
}
