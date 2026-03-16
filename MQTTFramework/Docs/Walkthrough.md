# MQTT Framework Walkthrough

I have designed and implemented a reusable, lightweight MQTT framework for Apple platforms. This framework is built from scratch using Apple's `Network.framework`, avoiding dependencies like `CocoaMQTT` or `CocoaAsyncSocket`.

## Key Features
- **Zero Dependencies**: Pure Swift implementation using `Network.framework`.
- **MQTT 3.1.1 Compliant**: Core packets like `CONNECT`, `PUBLISH`, `SUBSCRIBE`, and `PING` are implemented.
- **Swift 6 Ready**: Uses `@unchecked Sendable` where appropriate for modern concurrency safety.
- **Reusable**: Structured as a Swift Package for easy integration.

## Architecture

The framework is divided into three main layers:

1.  **Transport Layer**: `Transport.swift` wraps `NWConnection` to provide a clean interface for TCP/TLS networking.
2.  **Protocol Layer**: Individual structs for each MQTT packet type handle binary serialization and parsing.
3.  **Client Layer**: `MQTTClient.swift` manages the state machine (connecting, connected, etc.) and provides the public API.

Detailed flow diagrams and data processing steps can be found in the [Architectural Flow Document](file:///Users/akshatmahajan/.gemini/antigravity/brain/fca6c921-eff3-4bf8-9717-bea792c83df6/architecture_flow.md).

## Code Components

### Transport Layer
The `Transport` class handles the low-level socket communication.
[Transport.swift](file:///Users/akshatmahajan/.gemini/antigravity/playground/stellar-flare/MQTTFramework/Sources/MQTTFramework/Transport/Transport.swift)

### MQTT Packets
Packets are modeled as structs conforming to the `MQTTPacket` protocol.
[MQTTPacket.swift](file:///Users/akshatmahajan/.gemini/antigravity/playground/stellar-flare/MQTTFramework/Sources/MQTTFramework/Protocol/MQTTPacket.swift)
[ConnectPacket.swift](file:///Users/akshatmahajan/.gemini/antigravity/playground/stellar-flare/MQTTFramework/Sources/MQTTFramework/Protocol/ConnectPacket.swift)

### Client API
The `MQTTClient` is the main entry point for users.
[MQTTClient.swift](file:///Users/akshatmahajan/.gemini/antigravity/playground/stellar-flare/MQTTFramework/Sources/MQTTFramework/Client/MQTTClient.swift)

## Usage Example

```swift
let client = MQTTClient(clientID: "my_device")
client.delegate = self

// Connect to broker
client.connect(host: "broker.emqx.io", port: 1883)

// In delegate:
func mqttClient(_ client: MQTTClient, didChangeState state: MQTTClient.State) {
    if state == .connected {
        client.subscribe(to: "test/topic")
        client.publish(topic: "test/topic", message: "Hello MQTT".data(using: .utf8)!)
    }
}
```

## Verification Results

### Build Status
The framework builds successfully using `swift build`.
- **macOS Requirement**: 10.14+
- **Swift Version**: 5.9+

### Unit Tests
Tests verify the correctness of binary serialization.
[MQTTFrameworkTests.swift](file:///Users/akshatmahajan/.gemini/antigravity/playground/stellar-flare/MQTTFramework/Tests/MQTTFrameworkTests/MQTTFrameworkTests.swift)
