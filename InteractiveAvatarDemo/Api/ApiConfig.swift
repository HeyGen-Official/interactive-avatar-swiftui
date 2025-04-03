//
//  ApiConfig.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/25/25.
//

import Foundation

struct ApiConfig {
    static let baseUrl: String = "https://api.heygen.com"
    static let streamingWebSocketBaseUrl: String = "wss://api.heygen.com/v1/ws/streaming.chat"
    static let apiKey: String = "YOUR_API_KEY"
}

extension ApiConfig {
    static func streamingWebSocketUrl(sessionId: String, sessionToken: String, openingMessage: String) -> URL? {
        URL(string: "\(streamingWebSocketBaseUrl)?session_id=\(sessionId)&session_token=\(sessionToken)&audio_transport=livekit&arch_version=v2&stt_language=en&silence_response=false&opening_text=\(openingMessage)")
    }
}
