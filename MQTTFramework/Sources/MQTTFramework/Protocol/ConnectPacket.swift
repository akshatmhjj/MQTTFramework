import Foundation

/// The CONNECT packet is the first packet sent from the Client to the Server.
/// It contains client identification, clean session flag, keep alive timer, and optional credentials.
public struct ConnectPacket: MQTTPacket {
    public let type: MQTTPacketType = .connect
    
    /// The unique identifier for the client.
    public let clientID: String
    
    /// If true, the server must discard any previous session and start a new one.
    public let cleanSession: Bool
    
    /// The maximum interval in seconds between messages sent by the client.
    public let keepAlive: UInt16
    
    /// Optional username for authentication.
    public let username: String?
    
    /// Optional password for authentication.
    public let password: String?

    public init(clientID: String, cleanSession: Bool, keepAlive: UInt16, username: String?, password: String?) {
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.username = username
        self.password = password
    }
    
    /// Serializes the CONNECT packet into its binary representation.
    public func serialize() -> Data {
        var payload = Data()
        
        // Protocol Name: "MQTT"
        payload.appendMQTTString("MQTT")
        
        // Protocol Level: 4 represents MQTT 3.1.1
        payload.append(4)
        
        // Connect Flags: bitmask for session behavior and credentials presence
        var flags: UInt8 = 0
        if cleanSession { flags |= 0x02 }
        if username != nil { flags |= 0x80 }
        if password != nil { flags |= 0x40 }
        payload.append(flags)
        
        // Keep Alive timer
        payload.append(UInt8(keepAlive >> 8))
        payload.append(UInt8(keepAlive & 0xFF))
        
        // Payload includes ClientID and optional Username/Password
        payload.appendMQTTString(clientID)
        
        if let username = username {
            payload.appendMQTTString(username)
        }
        if let password = password {
            payload.appendMQTTString(password)
        }
        
        let header = encodeFixedHeader(type: .connect, flags: 0, remainingLength: payload.count)
        return header + payload
    }
}
