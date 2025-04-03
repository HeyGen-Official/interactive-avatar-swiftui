//
//  AddNewAvatarView.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/25/25.
//

import SwiftUI

struct AddNewAvatarView: View {
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var avatarStorage: AvatarStorage
    
    @FocusState var isAvatarIdFocused: Bool
    @State var avatarId: String = ""
    
    @FocusState var isAvatarNameFocused: Bool
    @State var avatarName: String = ""
    
    @FocusState var isPreviewImageUrlFocused: Bool
    @State var previewImageUrl: String = ""
    
    @FocusState var isKnowledgeBaseIdFocused: Bool
    @State var knowledgeBaseId: String = ""
    
    @FocusState var isVoiceIdFocused: Bool
    @State var voiceId: String = ""
    
    @State var needRemoveBackground: Bool = false
    
    @State var saveForLater: Bool = true

    let previewForEdit: InteractiveAvatarPreview?
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .foregroundStyle(.white)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(height: 64)
            
            ScrollView(content: {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        TitleView(title: "Avatar ID")
                        InputField(placeholder: "Avatar ID",
                                   text: $avatarId,
                                   isFocused: _isAvatarIdFocused) {
                            isAvatarNameFocused = true
                        }
                    }
                    
                    VStack(spacing: 8) {
                        TitleView(title: "Avatar Name")
                        InputField(placeholder: "Avatar Name",
                                   text: $avatarName,
                                   isFocused: _isAvatarNameFocused) {
                            isPreviewImageUrlFocused = true
                        }
                    }
                    
                    VStack(spacing: 8) {
                        TitleView(title: "Preview Image URL")
                        InputField(placeholder: "Avatar Name",
                                   text: $previewImageUrl,
                                   isFocused: _isPreviewImageUrlFocused) {
                            isKnowledgeBaseIdFocused = true
                        }
                    }
                    
                    VStack(spacing: 8) {
                        TitleView(title: "Knowledge Base ID")
                        InputField(placeholder: "Knowledge Base ID",
                                   text: $knowledgeBaseId,
                                   isFocused: _isKnowledgeBaseIdFocused) {
                            isVoiceIdFocused = true
                        }
                    }
                    
                    VStack(spacing: 8) {
                        TitleView(title: "Voice ID")
                        InputField(placeholder: "Voice ID",
                                   text: $voiceId,
                                   isFocused: _isVoiceIdFocused) {
                            
                        }
                    }
                    
                    Toggle(isOn: $needRemoveBackground) {
                        TitleView(title: "Need Remove Background")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.primaryHighlight))
                    .padding(.vertical, 8)
                    
                    Toggle(isOn: $saveForLater) {
                        TitleView(title: "Save For Later")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.primaryHighlight))
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            })
        }
        .background(
            LinearGradient(colors: Color.backgroundGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        .overlay {
            ZStack(alignment: .bottom) {
                VStack(spacing: 12) {
                    CustomButton(text: ctaTitle) {
                        saveAvatar()
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.8)

                    if isEditMode {
                        Button {
                            if let previewForEdit {
                                avatarStorage.deleteAvatar(previewForEdit)
                                close()
                            }
                        } label: {
                            Text("Delete")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.errorRed)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                }
                .padding(12)
                .background(Color.black.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            guard let previewForEdit else { return }
            avatarId = previewForEdit.avatarId
            knowledgeBaseId = previewForEdit.knowledgeBaseId
            avatarName = previewForEdit.avatarName
            voiceId = previewForEdit.voiceId ?? ""
            previewImageUrl = previewForEdit.previewImg
        }
    }
    
    private func close() {
        UIWindow.keyWindow?.rootViewController?.dismiss(animated: true)
    }
    
    private var isEditMode: Bool {
        previewForEdit != nil
    }
    
    private var title: String {
        isEditMode ? "Edit Interactive Avatar" : "Add New Interactive Avatar"
    }
    
    private var ctaTitle: String {
        isEditMode ? "Update" : "Add"
    }
    
    private var isValid: Bool {
        !avatarId.isEmpty && !avatarName.isEmpty && !previewImageUrl.isEmpty && !knowledgeBaseId.isEmpty && !voiceId.isEmpty
    }
    
    private func saveAvatar() {
        guard isValid else { return }
        guard saveForLater else { return }
        if let previewForEdit {
            avatarStorage.deleteAvatar(previewForEdit)
        }
        avatarStorage.addAvatar(InteractiveAvatarPreview(quality: "high",
                                                         avatarId: avatarId,
                                                         previewImg: previewImageUrl,
                                                         needRemoveBackground: needRemoveBackground,
                                                         knowledgeBaseId: knowledgeBaseId,
                                                         shareCode: "app",
                                                         username: "",
                                                         voiceId: voiceId,
                                                         avatarName: avatarName,
                                                         isLocal: true))
        close()
    }
}

extension AddNewAvatarView {
    struct TitleView: View {
        let title: String
        var body: some View {
            HStack {
                Text(title)
                    .foregroundStyle(Color.white.opacity(0.75))
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
        }
    }
    
    struct InputField: View {
        let placeholder: String
        @Binding var text: String
        @FocusState var isFocused: Bool
        var onSubmit: (() -> Void)? = nil
        
        var body: some View {
            HStack {
                TextField(
                    placeholder,
                    text: $text
                )
                .foregroundStyle(.white)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    isFocused = false
                    onSubmit?()
                }
                .multilineTextAlignment(.leading)
                .textInputAutocapitalization(.never)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(Color.backgroundElevated2)
            }
        }
    }
}
