//
//  InteractiveAvatarView+ViewModel.swift
//  HeyGen
//
//  Created by Hwan Moon Lee on 3/10/25.
//

import SwiftUI
import LiveKit
import AVFoundation

extension InteractiveAvatarView {
    final class ViewModel: ObservableObject {
        @Published var isPreparingRoom: Bool = false
        @Published var hasFinishedSession: Bool = false
        @Published var chatMessages: [InteractiveAvatarChatMessage] = []
        @Published var isSendingMessage: Bool = false
        @Published var showChatHistory: Bool = true
        @Published var isUserTalking: Bool = false
        @Published var isTextInputMode: Bool = false
        @Published var errorMessage: String?
        
        @Published private var roomConnectionState: ConnectionState = .disconnected
        @Published private var avatarTalkingEvents: [AvatarStartTalkingEvent] = []
        
        private var session: Streaming.Session?
        private var accessToken: String?

        private var currentMessageId: UUID = UUID()
        private var currentMessage: String = ""
        
        private let avatarOpeningMessage: String = "Welcome to HeyGen! I’m your Interactive Avatar guide, here to help you explore the amazing world of real-time interactive avatars—let’s dive in together! What would you like to know first?"

        private let webSocketManager = WebSocketManager()
        
        private let room: Room
        private var _connectTask: Task<Void, Error>?
        
        let preview: InteractiveAvatarPreview
        
        public init(preview: InteractiveAvatarPreview) {
            self.preview = preview
            try? AudioManager.shared.setRecordingAlwaysPreparedMode(false)
            room = Room(roomOptions: RoomOptions(defaultAudioCaptureOptions: AudioCaptureOptions(echoCancellation: true,
                                                                                                 autoGainControl: true,
                                                                                                 noiseSuppression: true),
                                                 adaptiveStream: true,
                                                 dynacast: true))
            room.add(delegate: self)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        deinit {
            DispatchQueue.main.async {
                try? AudioManager.shared.stopLocalRecording()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        
        var avatarName: String {
            preview.avatarName
        }
        
        var previewImageUrl: URL? {
            preview.previewImageUrl
        }
        
        var isAvatarTalking: Bool {
            !avatarTalkingEvents.isEmpty
        }
        
        var showUserSpeakingState: Bool {
            isUserTalking && !isTextInputMode
        }
        
        var shouldShowRoomView: Bool {
            guard interactiveAvatar != nil else { return false }
            return roomConnectionState == .connected || roomConnectionState == .reconnecting
        }
        
        var interactiveAvatar: Participant? {
            room.remoteParticipants.first?.value
        }
        
        var localParticipant: LocalParticipant {
            room.localParticipant
        }
        
        func start() {
            withAnimation {
                errorMessage = nil
                isPreparingRoom = true
                chatMessages = []
            }
            Task {
                do {
                    let sessionResponse = try await Streaming.new(param: preview.streamingSessionParam()).request()
                    await MainActor.run { session = sessionResponse.data }
                    if let sessionId = sessionResponse.data?.sessionId {
                        let _ = try await Streaming.start(sessionId: sessionId).request()
                        let accessTokenResponse = try await Streaming.createToken(sessionId: sessionId).request()
                        if let token = accessTokenResponse.data?.token, let url = ApiConfig.streamingWebSocketUrl(sessionId: sessionId, sessionToken: token, openingMessage: avatarOpeningMessage) {
                            accessToken = token
                            webSocketManager.connect(sessionId: sessionId, sessionToken: token, url: url)
                        }
                        if let accessToken = sessionResponse.data?.accessToken, let url = sessionResponse.data?.url {
                            await MainActor.run { try? AudioManager.shared.startLocalRecording() }
                            try await connect(url: url,
                                              token: accessToken)
                            if !room.localParticipant.isMicrophoneEnabled() {
                                try await room.localParticipant.setMicrophone(enabled: true)
                            }
                            try await Task.sleep(nanoseconds: UInt64(4 * Double(NSEC_PER_SEC)))
                            await MainActor.run {
                                withAnimation {
                                    chatMessages.append(InteractiveAvatarChatMessage(id: UUID(),
                                                                    isUserMessage: false,
                                                                    message: avatarOpeningMessage))
                                    isPreparingRoom = false
                                }
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        withAnimation {
                            isPreparingRoom = false
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }

        func stop() {
            Task {
                do {
                    guard let sessionId = session?.sessionId else { return }
                    try AudioManager.shared.stopLocalRecording()
                    let _ = try await Streaming.stop(sessionId: sessionId).request()
                    webSocketManager.disconnect()
                    try await room.localParticipant.setMicrophone(enabled: false)
                    await room.disconnect()
                } catch {
                    
                }
                await MainActor.run {
                    cancelConnect()
                    session = nil
                    accessToken = nil
                    hasFinishedSession = true
                    chatMessages = []
                }
            }
        }
        
        func send(_ text: String) {
            Task {
                guard let session, let accessToken else { return }
                await MainActor.run { withAnimation { isSendingMessage = true } }
                do {
                    let _ = try await Streaming.task(sessionId: session.sessionId,
                                                          accessToken: accessToken,
                                                          text: text,
                                                          isRepeat: false).request()
                } catch {
                }
                await MainActor.run { withAnimation { isSendingMessage = false } }
            }
        }
        
        private func connect(url: String, token: String) async throws {
            let connectTask = Task.detached { [weak self] in
                guard let self else { return }
                try await self.room.connect(url: url,token: token)
            }
            _connectTask = connectTask
            try await connectTask.value
        }
        
        private func cancelConnect() {
            _connectTask?.cancel()
        }
    }
}

extension InteractiveAvatarView.ViewModel: RoomDelegate {
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        Task.detached { @MainActor [weak self] in
            guard let self else { return }
            self.roomConnectionState = connectionState
            if case .disconnected = connectionState,
               let error = room.disconnectError,
               error.type != .cancelled
            {
                self.errorMessage = error.message
            }
        }
    }

    func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isUserTalking = self.localParticipant.isSpeaking
        }
    }

    func room(_: Room, participant _: RemoteParticipant?, didReceiveData data: Data, forTopic _: String) {
        do {
            let decoder = StreamingEventDecoder()
            let event = try decoder.decodeMessage(data)
            var isTalkingEnded: Bool = false
            var isUserMessage: Bool = false
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch event {
                case let avatarStartTalkingEvent as AvatarStartTalkingEvent: self.avatarTalkingEvents.append(avatarStartTalkingEvent)
                case let avatarStopTalkingEvent as AvatarStopTalkingEvent: self.avatarTalkingEvents.removeAll { $0.taskId == avatarStopTalkingEvent.taskId }
                case let messageEvent as AvatarTalkingMessageEvent: self.currentMessage += messageEvent.message
                case is AvatarTalkingEndEvent: isTalkingEnded = true
                case is UserStartTalkingEvent:()
                case is UserStopTalkingEvent:()
                case let userMessage as UserTalkingMessageEvent: self.currentMessage += userMessage.message
                case is UserTalkingEndEvent:
                    isUserMessage = true
                    isTalkingEnded = true
                default: ()
                }
                
                if isTalkingEnded {
                    withAnimation {
                        self.chatMessages.append(InteractiveAvatarChatMessage(id: self.currentMessageId,
                                                                              isUserMessage: isUserMessage,
                                                                              message: self.currentMessage))
                    }
                    self.currentMessageId = UUID()
                    self.currentMessage = ""
                }
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
    
    func room(_: Room, participant _: LocalParticipant, didPublishTrack publication: LocalTrackPublication) { }
    
    func room(_ room: Room, localParticipant: LocalParticipant, didFailToPublish track: LocalTrackPublication, error: Error) { }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) { }
    
    func room(_ room: Room, participant: LocalParticipant, remoteDidSubscribeTrack publication: LocalTrackPublication) { }
    
    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) { }

    func room(_: Room, participant _: Participant, trackPublication _: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) { }
    
    func room(_: Room, trackPublication _: TrackPublication, didUpdateE2EEState state: E2EEState) { }

    func room(_ room: Room, participant: Participant, didUpdatePermissions permissions: ParticipantPermissions) { }
}

struct InteractiveAvatarChatMessage: Hashable {
    let id: UUID
    let isUserMessage: Bool
    let message: String
}


// MARK: - Streaming Event

protocol StreamingEvent {
    var type: String { get }
}

struct AvatarStartTalkingEvent: StreamingEvent {
    let type = "avatar_start_talking"
    let taskId: String
}

struct AvatarStopTalkingEvent: StreamingEvent {
    let type = "avatar_stop_talking"
    let taskId: String
}

struct AvatarTalkingMessageEvent: StreamingEvent {
    let type = "avatar_talking_message"
    let message: String
}

struct AvatarTalkingEndEvent: StreamingEvent {
    let type = "avatar_end_message"
}

struct UserTalkingMessageEvent: StreamingEvent {
    let type = "user_talking_message"
    let message: String
}

struct UserTalkingEndEvent: StreamingEvent {
    let type = "user_end_message"
}

struct UserStartTalkingEvent: StreamingEvent {
    let type = "user_start"
}

struct UserStopTalkingEvent: StreamingEvent {
    let type = "user_stop"
}

// MARK: - Streaming Event Decoder

class StreamingEventDecoder {
    enum MessageError: Error {
        case decodingFailed
        case invalidJSON
        case invalidFormat
        case unknownEventType
    }
    
    func decodeMessage(_ data: Data) throws -> StreamingEvent {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            throw MessageError.invalidJSON
        }
        switch type {
        case "avatar_start_talking":
            guard let taskId = json["task_id"] as? String else {
                throw MessageError.invalidFormat
            }
            return AvatarStartTalkingEvent(taskId: taskId)
            
        case "avatar_stop_talking":
            guard let taskId = json["task_id"] as? String else {
                throw MessageError.invalidFormat
            }
            return AvatarStopTalkingEvent(taskId: taskId)
            
        case "avatar_talking_message":
            guard let message = json["message"] as? String else {
                throw MessageError.invalidFormat
            }
            return AvatarTalkingMessageEvent(message: message)
            
        case "avatar_end_message":
            return AvatarTalkingEndEvent()
            
        case "user_talking_message":
            guard let message = json["message"] as? String else {
                throw MessageError.invalidFormat
            }
            return UserTalkingMessageEvent(message: message)
            
        case "user_end_message":
            return UserTalkingEndEvent()
            
        case "user_start":
            return UserStartTalkingEvent()
            
        case "user_stop":
            return UserStopTalkingEvent()
            
        default:
            throw MessageError.unknownEventType
        }
    }
}

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    
    func connect(sessionId: String, sessionToken: String, url: URL) {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("websocket opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("websocket closed with code: \(closeCode)")
    }
}

