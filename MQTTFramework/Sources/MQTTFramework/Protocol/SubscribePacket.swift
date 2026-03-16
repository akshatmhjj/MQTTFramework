import Foundation

/// The SUBSCRIBE packet is sent from the Client to the Server to create one or more Subscriptions.
struct SubscribePacket: MQTTPacket {
    let type: MQTTPacketType = .subscribe
    
    /// Identifier used to match SUBACK responses.
    let packetID: UInt16
    
    /// List of topic filters and their requested QoS levels.
    let topics: [(String, UInt8)]
    
    /// Serializes the SUBSCRIBE packet into its binary representation.
    func serialize() -> Data {
        var variableHeader = Data()
        variableHeader.append(UInt8(packetID >> 8))
        variableHeader.append(UInt8(packetID & 0xFF))
        
        var payload = Data()
        for (topic, qos) in topics {
            payload.appendMQTTString(topic)
            payload.append(qos)
        }
        
        let header = encodeFixedHeader(type: .subscribe, flags: 0x02, remainingLength: variableHeader.count + payload.count)
        return header + variableHeader + payload
    }
}
