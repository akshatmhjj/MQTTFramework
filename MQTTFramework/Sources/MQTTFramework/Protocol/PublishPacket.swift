import Foundation

/// The PUBLISH packet is sent by a Client to a Server or vice-versa to transport an application message.
public struct PublishPacket: MQTTPacket {
    public let type: MQTTPacketType = .publish
    
    /// The topic name to which the message is published.
    public let topic: String
    
    /// The application message payload.
    public let payload: Data
    
    /// Quality of Service level (0, 1, or 2).
    public let qos: UInt8
    
    /// Whether the message should be retained by the broker.
    public let retain: Bool
    
    /// Optional identifier for QoS 1 and 2 messages.
    public let packetID: UInt16?

    public init(topic: String, payload: Data, qos: UInt8, retain: Bool, packetID: UInt16?) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
        self.packetID = packetID
    }
    
    public func serialize() -> Data {
        var variableHeader = Data()
        variableHeader.appendMQTTString(topic)
        
        if qos > 0, let pID = packetID {
            variableHeader.append(UInt8(pID >> 8))
            variableHeader.append(UInt8(pID & 0xFF))
        }
        
        var flags: UInt8 = 0
        if retain { flags |= 0x01 }
        flags |= (qos << 1)
        
        let header = encodeFixedHeader(type: .publish, flags: flags, remainingLength: variableHeader.count + payload.count)
        return header + variableHeader + payload
    }
}
