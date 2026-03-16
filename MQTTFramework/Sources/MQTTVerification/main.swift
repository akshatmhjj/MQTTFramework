import Foundation
import MQTTFramework

print("🚀 Starting MQTTFramework Diagnostic Verification...")
print("--------------------------------------------------")

var passedCount = 0
var failedCount = 0

func assertTest(_ condition: Bool, _ name: String) {
    if condition {
        print("✅ PASSED: \(name)")
        passedCount += 1
    } else {
        print("❌ FAILED: \(name)")
        failedCount += 1
    }
}

// 1. Connect Packet Serialization
func testConnectPacketSerialization() {
    let packet = ConnectPacket(clientID: "testClient", cleanSession: true, keepAlive: 60, username: nil, password: nil)
    let data = packet.serialize()
    
    assertTest(data[0] == 0x10, "Connect Packet Header (0x10)")
    assertTest(data.count > 10, "Connect Packet Length")
    assertTest(data[8] == 0x04, "Connect Protocol Level (4)")
    assertTest(data[9] == 0x02, "Connect Flags (Clean Session)")
    assertTest(data[10] == 0x00 && data[11] == 0x3C, "Connect Keep Alive (60s)")
}

// 2. ConnAck Parsing
func testConnAckParsing() {
    let rawData = Data([0x20, 0x02, 0x01, 0x00])
    let packet = ConnAckPacket.parse(data: rawData)
    
    assertTest(packet != nil, "ConnAck Parsing (Not Nil)")
    assertTest(packet?.sessionPresent == true, "ConnAck Session Present")
    assertTest(packet?.returnCode == 0, "ConnAck Return Code (Success)")
}

// 3. Publish Packet Serialization
func testPublishPacketSerialization() {
    let payload = "hello".data(using: .utf8)!
    let packet = PublishPacket(topic: "test/topic", payload: payload, qos: 0, retain: false, packetID: nil)
    let data = packet.serialize()
    
    assertTest(data[0] == 0x30, "Publish Packet Header (0x30 - QoS 0)")
    assertTest(data[1] == 17, "Publish Packet Remaining Length (17)")
    
    // Check topic length (0x00, 0x0A for "test/topic")
    assertTest(data[2] == 0x00 && data[3] == 0x0A, "Publish Topic Length")
}

// Run Tests
print("Running Packet Serialization Tests...")
testConnectPacketSerialization()
testConnAckParsing()
testPublishPacketSerialization()

print("--------------------------------------------------")
print("📊 Summary: \(passedCount) Passed, \(failedCount) Failed")

if failedCount > 0 {
    print("❌ Verification Failed!")
    exit(1)
} else {
    print("✅ All systems functional!")
    exit(0)
}
