import Foundation
import Network

/// Provides callbacks for important MQTT client events.
public protocol MQTTClientDelegate: AnyObject {
    /// Called when the connection state of the client changes.
    func mqttClient(_ client: MQTTClient, didChangeState state: MQTTClient.State)
    
    /// Called when a new application message is received on a subscribed topic.
    /// - Parameters:
    ///   - client: The MQTT client instance.
    ///   - message: The raw message payload.
    ///   - topic: The topic the message was received on.
    func mqttClient(_ client: MQTTClient, didReceiveMessage message: Data, onTopic topic: String)
    
    /// Called when an error occurs in the client or transport layer.
    func mqttClient(_ client: MQTTClient, didError error: Error)
}

extension MQTTClient {
    public enum State {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
}
