//
//  InteractiveAvatarListView.swift
//  HeyGen
//
//  Created by Hwan Moon Lee on 3/10/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct InteractiveAvatarListView: View {
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var avatarStorage: AvatarStorage
    
    @State var showAddNewAvatarSheet: Bool = false
    @State var avatarToEdit: InteractiveAvatarPreview?
    @State var localAvatars: [InteractiveAvatarPreview] = []
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: Array(repeatElement(GridItem(.flexible(), spacing: 12), count: 2)), spacing: 12) {
                    ForEach(Self.avatars, id: \.self) { avatar in
                        InteractiveAvatarCell(avatar: avatar)
                            .onTapGesture {
                                router.navigate(to: .avatar(preview: avatar))
                            }
                    }
                    ForEach(localAvatars, id: \.self) { avatar in
                        InteractiveAvatarCell(avatar: avatar)
                            .overlay {
                                ZStack(alignment: .topTrailing) {
                                    Button {
                                        avatarToEdit = avatar
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            }
                            .onTapGesture {
                                router.navigate(to: .avatar(preview: avatar))
                            }
                    }
                }
                .padding(12)
                .padding(.bottom, UIWindow.safeAreaBottomPadding + 12 + 44)
            }
            .clipped()
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Interactive Avatars")
        .background(
            LinearGradient(colors: Color.backgroundGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        .overlay {
            ZStack(alignment: .bottom) {
                CustomButton(text: "Add Your Avatar") {
                    showAddNewAvatarSheet.toggle()
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .sheet(isPresented: Binding(
            get: { showAddNewAvatarSheet || avatarToEdit != nil },
            set: { newValue in
                if !newValue {
                    showAddNewAvatarSheet = false
                    avatarToEdit = nil
                }
            }
        )) {
            AddNewAvatarView(previewForEdit: avatarToEdit)
        }
        .onChange(of: avatarStorage.avatarsUpdatedAt, { _, _ in
            localAvatars = avatarStorage.loadAvatars()
        })
        .onAppear {
            localAvatars = avatarStorage.loadAvatars()
        }
    }
}

struct InteractiveAvatarCell: View {
    
    let avatar: InteractiveAvatarPreview

    var body: some View {
        Rectangle()
            .aspectRatio(1.0, contentMode: .fit)
            .foregroundStyle(Color.backgroundElevated.opacity(0.75))
            .overlay {
                ZStack {
                    WebImage(url: avatar.previewImg.url)
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay {
                ZStack(alignment: .bottom) {
                    HStack {
                        Text(avatar.avatarName)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                        Spacer()
                    }
                    .padding(8)
                    .background {
                        LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.4), Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .cornerRadius(8)
            .contentShape(Rectangle())
            .clipped()
    }
}

// MARK: - Demo Interactive Avatar List

extension InteractiveAvatarListView {
    static let avatars: [InteractiveAvatarPreview] = [
        InteractiveAvatarPreview(quality: "high",
                                 avatarId: "Santa_Fireplace_Front_public",
                                 previewImg: "https://files2.heygen.ai/avatar/v3/3b4e464bf15f4194b082be0e631354c6_46860/preview_target.webp",
                                 needRemoveBackground: false,
                                 knowledgeBaseId: "d76e51bbcca743d6b93750eaf93c4d9b",
                                 shareCode: "",
                                 username: "",
                                 voiceId: "83f8d11946b24588857a491e1841c667",
                                 source: "app",
                                 avatarName: "Santa Fireplace Front"),
        InteractiveAvatarPreview(quality: "high",
                                 avatarId: "Ann_Doctor_Standing2_public",
                                 previewImg: "https://files2.heygen.ai/avatar/v3/699a4c2995914d39b2cb311a930d7720_45570/preview_talk_3.webp",
                                 needRemoveBackground: false,
                                 knowledgeBaseId: "177ea67376364fbfb5dbc1f304f4916a",
                                 shareCode: "",
                                 username: "",
                                 voiceId: "2e4de8a01f3b4e9c96794045e2f12779",
                                 source: "app",
                                 avatarName: "Ann Doctor Standing"),
        InteractiveAvatarPreview(quality: "high",
                                 avatarId: "Judy_Teacher_Standing_public",
                                 previewImg: "https://files2.heygen.ai/avatar/v3/6cd7031aa97e496897391dd44dae56be_45630/preview_talk_1.webp",
                                 needRemoveBackground: false,
                                 knowledgeBaseId: "cdb979191b0c4cdf974bf9c9305f9d7b",
                                 shareCode: "",
                                 username: "",
                                 voiceId: "7ffb69e578d4492587493c26ebcabc31",
                                 source: "app",
                                 avatarName: "Judy Teacher Standing"),
        InteractiveAvatarPreview(quality: "high",
                                 avatarId: "Wayne_20240711",
                                 previewImg: "https://files2.heygen.ai/avatar/v3/a3fdb0c652024f79984aaec11ebf2694_34350/preview_target.webp",
                                 needRemoveBackground: false,
                                 knowledgeBaseId: "demo-1",
                                 shareCode: "",
                                 username: "",
                                 voiceId: "2411aaf820874397a44530f94032bfdc",
                                 source: "app",
                                 avatarName: "Wayne"),
    ]
}
