# Implementation Analysis: Custom Framework vs. CocoaMQTT

This document analyzes the engineering efforts invested in building our custom `MQTTFramework` and how it differs from using a standard library like `CocoaMQTT`.

## 1. What was written to eliminate CocoaMQTT?

To build an independent framework, we had to implement the entire MQTT stack from the ground up. In a standard setup using `CocoaMQTT`, most of these layers are abstracted away:

*   **The Transport Layer**: `CocoaMQTT` depends on `CocoaAsyncSocket`. We replaced this by writing a custom `Transport` class using Apple's modern `Network.framework` (`NWConnection`). This required manual handling of socket states (`ready`, `failed`, `waiting`) and buffering.
*   **Binary Packet Engineering**: We manually implemented the MQTT 3.1.1 byte-level specification for:
    *   **Variable Length Encoding**: Encoding and decoding the "Remaining Length" field (using a multiplier-based algorithm).
    *   **Field Serialization**: Manually converting Swift strings and integers into big-endian byte arrays for headers.
    *   **Packet Parsing**: Writing a custom router that reads the first nibble of an incoming byte stream to identify packet types (0x20 for CONNACK, 0x30 for PUBLISH, etc.).
*   **State Machine Logic**: We built a custom state machine (`MQTTClient.State`) to track the lifecycle of a connection independently of any third-party logic.

## 2. Where did the effort go?

Our primary efforts were concentrated in three areas:

1.  **Protocol Compliance**: Ensuring that the raw bytes we send exactly match the MQTT 3.1.1 spec (e.g., proper header flags for `PUBLISH` or `SUBSCRIBE`).
2.  **Concurrency Safety**: Leveraging Swift 6 features like `@unchecked Sendable` to ensure the library is safe for modern multi-threaded apps.
3.  **Zero-Dependency Architecture**: The "effort" here was architectural—refusing to take the "easy path" of importing a library, ensuring that our binary footprint remains tiny and we have zero risk of dependency hell (where one library update breaks another).

## 3. Implementation Comparison: Framework vs. Tooling

### Is it "Easy" to implement?
*   **Using a Framework (`CocoaMQTT`)**: **Easy to implement.** You get everything (QoS 2, persistence, TLS) out of the box in 5 minutes.
*   **Building a Framework (Custom)**: **Hard to implement.** Requires deep knowledge of TCP, binary data manipulation, and the MQTT specification.

### Why do it this way?
Despite the difficulty, a custom implementation is superior for specific use cases:

| Feature | CocoaMQTT | Custom MQTTFramework |
| :--- | :--- | :--- |
| **Dependencies** | High (CocoaAsyncSocket) | **Zero** |
| **Binary Size** | Larger | **Extremely Minimal** |
| **Control** | Limited to API | **Full control over every byte** |
| **Platform Optimization** | Legacy Socket APIs | **Modern Network.framework** |

## 4. How does this affect the final product?

1.  **Stability**: By using Apple's `Network.framework`, the app is more stable on modern iOS/macOS versions as it uses the same underlying stack as the OS itself.
2.  **Maintenance**: No need to worry about third-party library vulnerabilities or abandonment. 
3.  **Performance**: Lower memory usage and CPU overhead because we only run the code we actually need, without the bloat of a one-size-fits-all library.

---
**Summary**: While implementing this from scratch required significantly more effort than importing `CocoaMQTT`, the result is a high-performance, modern, and completely owned codebase that is perfectly optimized for the Apple ecosystem.
