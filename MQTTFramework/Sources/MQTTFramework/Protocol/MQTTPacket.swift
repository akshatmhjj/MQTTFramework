import Foundation

public enum MQTTPacketType: UInt8 {
    case connect = 1
    case connack = 2
    case publish = 3
    case puback = 4
    case pubrec = 5
    case pubrel = 6
    case pubcomp = 7
    case subscribe = 8
    case suback = 9
    case unsubscribe = 10
    case unsuback = 11
    case pingreq = 12
    case pingresp = 13
    case disconnect = 14
}

/// Represents a generic MQTT Control Packet as defined in the MQTT 3.1.1 specification.
public protocol MQTTPacket {
    /// The specific type of the MQTT packet.
    var type: MQTTPacketType { get }
    
    /// Serializes the packet into raw binary data for transmission.
    /// - Returns: A Data object containing the serialized packet bytes.
    func serialize() -> Data
}

extension MQTTPacket {
    /// Encodes the Fixed Header for any MQTT packet.
    /// The fixed header contains the packet type, flags, and the remaining length
    /// encoded as a variable-length integer.
    /// - Parameters:
    ///   - type: The MQTT packet type.
    ///   - flags: Type-specific flags (4 bits).
    ///   - remainingLength: The length of the variable header plus the payload.
    /// - Returns: Data containing the encoded fixed header.
    func encodeFixedHeader(type: MQTTPacketType, flags: UInt8, remainingLength: Int) -> Data {
        var data = Data()
        let byte1 = (type.rawValue << 4) | (flags & 0x0F)
        data.append(byte1)
        
        var length = remainingLength
        repeat {
            var byte = UInt8(length & 0x7F)
            length >>= 7
            if length > 0 {
                byte |= 0x80
            }
            data.append(byte)
        } while length > 0
        
        return data
    }
}

extension Data {
    mutating func appendMQTTString(_ string: String) {
        let utf8 = string.data(using: .utf8) ?? Data()
        let length = UInt16(utf8.count)
        self.append(UInt8(length >> 8))
        self.append(UInt8(length & 0xFF))
        self.append(utf8)
    }
}
