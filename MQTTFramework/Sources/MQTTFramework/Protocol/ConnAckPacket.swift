import Foundation

/// The CONNACK packet is sent by the Server in response to a CONNECT packet received from a Client.
public struct ConnAckPacket: MQTTPacket {
    public let type: MQTTPacketType = .connack
    
    /// Indicates if the server already has session state for this client.
    public let sessionPresent: Bool
    
    /// Connect return code (0 for success, others for various errors).
    public let returnCode: UInt8
    
    /// Parses a raw binary CONNACK packet.
    /// - Parameter data: The raw data received from the broker.
    /// - Returns: A decoded ConnAckPacket if parsing is successful.
    public static func parse(data: Data) -> ConnAckPacket? {
        guard data.count >= 4 else { return nil }
        // Byte 0: Fixed Header (0x20)
        // Byte 1: Remaining Length (2)
        // Byte 2: Connack Flags
        // Byte 3: Connect Return Code
        
        let sessionPresent = (data[2] & 0x01) != 0
        let returnCode = data[3]
        
        return ConnAckPacket(sessionPresent: sessionPresent, returnCode: returnCode)
    }
    
    public func serialize() -> Data {
        var data = Data([0x20, 0x02])
        data.append(sessionPresent ? 0x01 : 0x00)
        data.append(returnCode)
        return data
    }
}
