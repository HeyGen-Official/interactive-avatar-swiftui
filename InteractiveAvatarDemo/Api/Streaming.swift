//
//  Streaming.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/18/25.
//

import Foundation

struct Streaming {
    struct Session: Codable {
        let sessionId: String
        let sdp: String?
        let accessToken: String
        let url: String
        //        let iceServers: [Any]?
        //        let iceServers2: [Any]?
        let isPaid: Bool
        let sessionDurationLimit: Int
        let realtimeEndpoint: String
    }
    
    struct SessionParam: RequestParamsProtocol {
        struct Voice: RequestParamsProtocol {
            var voiceId: String?
        }
        
        let avatarName: String
        let shareCode: String?
        let knowledgeBaseId: String
        var voice: Voice?
        var version: String = "v2"
        var waitList: Bool = false
        var videoEncoding: String = "H264"
        var quality: String = "high"
        var source: String = "share"
        var language: String = "en"
        var iaIsLivekitTransport: Bool = true
    }
    
    struct StreamingToken: Codable {
        let token: String
    }
}

struct ApiGenericDataResponse<T: Codable>: Codable {
    let data: T?
}

struct ApiDataResponse<T: Codable>: Codable {
    let code: Int
    let data: T?
    let msg: String?
    let message: String?
}

struct ApiResponse: Codable {
    let code: Int
    let msg: String?
    let message: String?
}

extension Streaming {
    static func new(param: SessionParam) -> ApiRequest<ApiDataResponse<Session>> {
        ApiRequest(
            endpoint: "/v1/realtime.new",
            method: .post,
            parameters: param.asDictionary()
        )
    }
    
    static func start(sessionId: String) -> ApiRequest<ApiResponse> {
        ApiRequest(
            endpoint: "/v1/realtime.start",
            method: .post,
            parameters: ["session_id": sessionId]
        )
    }
    
    static func createToken(sessionId: String) -> ApiRequest<ApiGenericDataResponse<StreamingToken>> {
        ApiRequest(
            endpoint: "/v1/streaming.create_token",
            method: .post,
            parameters: ["session_id": sessionId, "paid": true]
        )
    }
    
    static func stop(sessionId: String) -> ApiRequest<ApiResponse> {
        ApiRequest(
            endpoint: "/v1/realtime.stop",
            method: .post,
            parameters: ["session_id": sessionId]
        )
    }
    
    static func task(sessionId: String, accessToken: String, text: String, isRepeat: Bool) -> ApiRequest<ApiResponse> {
        ApiRequest(
            endpoint: "/v1/streaming.task",
            method: .post,
            parameters: ["session_id": sessionId, "text": text, "task_type": isRepeat ? "repeat" : "talk"]
        )
    }
}
