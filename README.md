# MQTTFramework

A lightweight, reusable MQTT 3.1.1 client framework for Apple platforms, built from scratch using Apple's `Network.framework`.

## Features

- **Zero Dependencies**: Pure Swift implementation using only Apple's native `Network.framework`.
- **MQTT 3.1.1 Compliant**: Implementation of core packets including `CONNECT`, `PUBLISH`, `SUBSCRIBE`, and `PING`.
- **Swift 6 Ready**: Designed with modern concurrency in mind, using `@unchecked Sendable` where appropriate for thread safety.
- **Lightweight & Fast**: Minimal overhead, leveraging the power of `NWConnection` for optimized network performance.

## Requirements

- **macOS**: 10.14+
- **iOS / iPadOS**: (Framework is ready for cross-platform integration)
- **Swift**: 5.9+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/akshatmhjj/MQTTFramework.git", from: "1.0.0")
]
```

Or add it via Xcode: `File > Add Packages...` and enter the repository URL.

## Quick Start

```swift
import MQTTFramework
import Foundation

// 1. Initialize the client
let client = MQTTClient(clientID: "my_swift_device")
client.delegate = self

// 2. Connect to the broker
client.connect(host: "broker.emqx.io", port: 1883)

// 3. Implement the delegate
extension MyClass: MQTTClientDelegate {
    func mqttClient(_ client: MQTTClient, didChangeState state: MQTTClient.State) {
        if state == .connected {
            print("Connected to broker!")
            
            // Subscribe to a topic
            client.subscribe(to: "test/topic")
            
            // Publish a message
            let message = "Hello from Swift!".data(using: .utf8)!
            client.publish(topic: "test/topic", message: message)
        }
    }
    
    func mqttClient(_ client: MQTTClient, didReceiveMessage message: Data, onTopic topic: String) {
        let payload = String(data: message, encoding: .utf8) ?? "Binary Data"
        print("Received message on \(topic): \(payload)")
    }
    
    func mqttClient(_ client: MQTTClient, didError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}
```

## Architecture

The framework is architected into three primary layers:

1.  **Transport Layer**: Handles low-level socket communication using `NWConnection`.
2.  **Protocol Layer**: Manages the binary serialization and parsing of MQTT 3.1.1 packets.
3.  **Client Layer**: Provides the high-level public API (`MQTTClient`) and maintains the connection state machine.

For more details on internal data flows, see the [ArchitectureFlow.md](Docs/ArchitectureFlow.md).

## Supported Packets

- [x] CONNECT / CONNACK
- [x] PUBLISH
- [x] SUBSCRIBE / SUBACK
- [x] PINGREQ / PINGRESP
- [x] DISCONNECT

## License

This project is licensed under the MIT License - see the LICENSE file for details.
