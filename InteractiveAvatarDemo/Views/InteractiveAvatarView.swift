//
//  InteractiveAvatarView.swift
//  HeyGen
//
//  Created by Hwan Moon Lee on 3/10/25.
//

import SwiftUI
import SDWebImageSwiftUI
import LiveKit

struct InteractiveAvatarView: View {
    
    @EnvironmentObject private var router: Router
    
    @StateObject var viewModel: ViewModel
    
    @State var videoAspectRatio: CGFloat = 1

    init(preview: InteractiveAvatarPreview) {
        _viewModel = StateObject(wrappedValue: ViewModel(preview: preview))
    }
    
    var isLandscape: Bool {
        videoAspectRatio >= 1
    }
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    InteractiveAvatarChatHistoryView()
                    InteractiveAvatarChatControlView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            VStack {
                ZStack {
                    WebImage(url: viewModel.previewImageUrl)
                        .resizable()
                        .onSuccess { image, _, _ in
                            DispatchQueue.main.async {
                                videoAspectRatio = image.size.width / image.size.height
                            }
                        }
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                    InteractiveAvatarVideoView()
                        .aspectRatio(videoAspectRatio, contentMode: .fit)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isAvatarTalking ? Color.primaryHighlight.opacity(0.5) : Color.white.opacity(0.2), lineWidth: viewModel.isAvatarTalking ? 3 : 1)
                    }
                    .padding(viewModel.isAvatarTalking ? 1.5 : 0.5)
                }
                if isLandscape {
                    Spacer()
                }
            }
            .overlay {
                if viewModel.shouldShowRoomView {
                    ZStack(alignment: .topTrailing) {
                        Button {
                            viewModel.stop()
                        } label: {
                            Image("icon_close_md")
                                .opacity(0.5)
                                .shadow(radius: 5)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)
                }
            }
        }
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.avatarName)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            viewModel.stop()
            router.navigateBack()
        }, label: {
            Image("icon_back")
        }))
        .background(
            LinearGradient(colors: Color.backgroundGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct InteractiveAvatarChatControlView: View {
    
    @EnvironmentObject private var viewModel: InteractiveAvatarView.ViewModel
    
    @State var newMessage: String = ""
    @FocusState var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.shouldShowRoomView {
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            viewModel.showChatHistory.toggle()
                        }
                    }, label: {
                        Image(systemName: viewModel.showChatHistory ? "clock.fill" : "clock")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    })
                    
                    if viewModel.isTextInputMode {
                        HStack(spacing: 8) {
                            TextField("Type a message...", text: $newMessage)
                                .focused($isTextFieldFocused)
                                .foregroundStyle(.white)
                                .submitLabel(.send)
                                .onSubmit {
                                    sendMessage()
                                }
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: {
                                sendMessage()
                            }, label: {
                                Image(systemName: "paperplane")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .opacity(newMessage.isEmpty ? 0.5 : 1)
                            })
                            .disabled(viewModel.isSendingMessage || newMessage.isEmpty)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Color.backgroundElevated.cornerRadius(8))
                    } else {
                        MovingWaveformView(isAnimating: $viewModel.isUserTalking, height: 36)
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewModel.isTextInputMode.toggle()
                            if viewModel.isTextInputMode {
                                isTextFieldFocused = true
                            }
                        }
                    }, label: {
                        Image(systemName: viewModel.isTextInputMode ? "microphone" : "keyboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    })
                }
            } else {
                Text(message)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(viewModel.errorMessage == nil ? .white : Color.errorRed)
                if viewModel.isPreparingRoom {
                    HStack {
                        Spacer()
                        LoadingIndicator()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                } else {
                    CustomButton(text: "Start") {
                        viewModel.start()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.backgroundElevated)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.showUserSpeakingState ? Color.primaryHighlight.opacity(0.5) : Color.white.opacity(0.2), lineWidth: viewModel.showUserSpeakingState ? 3 : 1)
        }
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        viewModel.send(newMessage)
        newMessage = ""
    }
    
    private var message: String {
        if viewModel.isPreparingRoom {
            return "Loading up your avatar now for a realtime interactive experience."
        } else if let errorMessage = viewModel.errorMessage {
            return errorMessage
        } else if viewModel.hasFinishedSession {
            return "👋 Your session has been closed. Thank you for using HeyGen Interactive Avatar. If you would like to chat again, please click ‘Start’"
        }
        return "Enjoy a chat!"
    }

}

struct InteractiveAvatarVideoView: View {

    @EnvironmentObject private var viewModel: InteractiveAvatarView.ViewModel
    
    var videoViewMode: VideoView.LayoutMode = .fit
    
    @State private var isRendering: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.shouldShowRoomView,
               let publication = viewModel.interactiveAvatar?.mainVideoPublication,
               let track = publication.track as? VideoTrack
            {
                ZStack(alignment: .topLeading) {
                    SwiftUIVideoView(track,
                                     layoutMode: videoViewMode,
                                     isRendering: $isRendering)
                    
                    if !isRendering {
                        ZStack {
                            LoadingIndicator()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }
}

struct InteractiveAvatarChatHistoryView: View {
    
    private let scrollToBottomId: String = "scrollToBottomId"

    @EnvironmentObject private var viewModel: InteractiveAvatarView.ViewModel
    
    var height: CGFloat = 250
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        VStack(spacing: 8) {
                            ForEach(viewModel.chatMessages, id: \.self) { message in
                                ChatMessageView(message: message)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 250, alignment: .bottom)
                    Spacer().frame(height: 0).id(scrollToBottomId)
                }
            }
            .frame(maxHeight: height, alignment: .bottom)
            .onChange(of: viewModel.chatMessages) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .mask(LinearGradient(
                gradient: Gradient(colors: [ Color.black.opacity(0), Color.black, Color.black ]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .opacity(viewModel.showChatHistory ? 1 : 0)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                proxy.scrollTo(scrollToBottomId, anchor: .bottom)
            }
        }
    }
    
    struct ChatMessageView: View {
        let message: InteractiveAvatarChatMessage
        var body: some View {
            HStack(alignment: .top) {
                Image(message.isUserMessage ? "icon_user" : "icon_hey")
                    .resizable()
                    .frame(width: 18, height: 18, alignment: .top)
                    .padding(.vertical, 5)
                Text(message.message)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 18)
                    .padding(5)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black.opacity(0.25))
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

public extension Participant {
    var mainVideoPublication: TrackPublication? {
        firstCameraPublication
    }
    
    var mainVideoTrack: VideoTrack? {
        firstCameraVideoTrack
    }
    
}

struct InteractiveAvatarPreview: Codable, Hashable, Identifiable {
    let quality: String
    let avatarId: String
    let previewImg: String
    let needRemoveBackground: Bool
    let knowledgeBaseId: String
    let shareCode: String?
    let username: String
    var voiceId: String?
    var source: String?
    var avatarName: String
    var isLocal: Bool = false
    
    var previewImageUrl: URL? {
        URL(string: previewImg)
    }
    
    var id: String {
        avatarId
    }
}

extension InteractiveAvatarPreview {
    func streamingSessionParam() -> Streaming.SessionParam {
        return  Streaming.SessionParam(avatarName: avatarId,
                                       shareCode: shareCode,
                                       knowledgeBaseId: knowledgeBaseId,
                                       voice: Streaming.SessionParam.Voice(voiceId: voiceId),
                                       source: source ?? "share")
    }
}
