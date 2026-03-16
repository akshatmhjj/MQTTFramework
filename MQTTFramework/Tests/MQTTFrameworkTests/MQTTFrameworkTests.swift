import XCTest
@testable import MQTTFramework

/// Unit tests to verify the correctness of MQTT packet serialization and parsing logic.
final class MQTTFrameworkTests: XCTestCase {
    
    func testConnectPacketSerialization() {
        let packet = ConnectPacket(clientID: "testClient", cleanSession: true, keepAlive: 60, username: nil, password: nil)
        let data = packet.serialize()
        
        // Expected bytes for "testClient" connection
        // Fixed Header: 0x10, Remaining Length
        // Protocol Name: 0x00, 0x04, 'M', 'Q', 'T', 'T'
        // Protocol Level: 0x04
        // Flags: 0x02 (Clean Session)
        // Keep Alive: 0x00, 0x3C
        // Client ID: 0x00, 0x0A, 't', 'e', 's', 't', 'C', 'l', 'i', 'e', 'n', 't'
        
        XCTAssertEqual(data[0], 0x10)
        XCTAssertTrue(data.count > 10)
        
        // Offset for Client ID length (2 bytes for proto, 4 for name, 1 level, 1 flags, 2 keepalive = 10 bytes + variable length total)
        // Actually it's:
        // 0-1: Header
        // 2-3: Proto length (00 04)
        // 4-7: "MQTT"
        // 8: Level (04)
        // 9: Flags (02)
        // 10-11: Keepalive (00 3C)
        // 12-13: Client ID length (00 0A)
        // 14...: "testClient"
        
        XCTAssertEqual(data[8], 0x04)
        XCTAssertEqual(data[9], 0x02)
        XCTAssertEqual(data[10], 0x00)
        XCTAssertEqual(data[11], 0x3C)
    }
    
    func testConnAckParsing() {
        let rawData = Data([0x20, 0x02, 0x01, 0x00])
        let packet = ConnAckPacket.parse(data: rawData)
        
        XCTAssertNotNil(packet)
        XCTAssertEqual(packet?.sessionPresent, true)
        XCTAssertEqual(packet?.returnCode, 0)
    }
    
    func testPublishPacketSerialization() {
        let payload = "hello".data(using: .utf8)!
        let packet = PublishPacket(topic: "test/topic", payload: payload, qos: 0, retain: false, packetID: nil)
        let data = packet.serialize()
        
        XCTAssertEqual(data[0], 0x30) // Publish, QoS 0
        // Topic length: 0x00, 0x0A (10 bytes)
        // Content: "test/topic" (10 bytes)
        // Payload: "hello" (5 bytes)
        // Total variable header + payload = 2 + 10 + 5 = 17 bytes
        XCTAssertEqual(data[1], 17)
    }
}
