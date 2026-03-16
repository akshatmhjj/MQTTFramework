import Foundation

/// The PINGREQ packet is sent from a Client to the Server to inform the Server that the Client is still alive.
struct PingReqPacket: MQTTPacket {
    let type: MQTTPacketType = .pingreq
    
    func serialize() -> Data {
        // Fixed Header followed by 0 length
        return Data([0xC0, 0x00])
    }
}

/// The PINGRESP packet is sent by the Server to the Client in response to a PINGREQ packet.
struct PingRespPacket: MQTTPacket {
    let type: MQTTPacketType = .pingresp
    
    func serialize() -> Data {
        return Data([0xD0, 0x00])
    }
}

/// The DISCONNECT packet is the last Control Packet sent from the Client to the Server.
/// It indicates that the Client is disconnecting cleanly.
struct DisconnectPacket: MQTTPacket {
    let type: MQTTPacketType = .disconnect
    
    func serialize() -> Data {
        return Data([0xE0, 0x00])
    }
}
