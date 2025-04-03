//
//  InteractiveAvatarDemoApp.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/18/25.
//

import SwiftUI

@main
struct InteractiveAvatarDemoApp: App {
    
    @StateObject private var router = Router()
    @StateObject private var avatarStorage = AvatarStorage()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                Group {
                    InteractiveAvatarListView()
                }
                .navigationDestination(for: Router.Destination.self) { destination in
                    switch destination {
                    case .avatar(let preview):
                        InteractiveAvatarView(preview: preview)
                    }
                }
            }
            .environmentObject(router)
            .environmentObject(avatarStorage)
        }
    }
}

/// **Router** is an `ObservableObject` responsible for managing navigation within the app.
/// It maintains a `path` of destinations, allowing navigation to specific screens or back.
///
/// - Usage:
///   - Use `navigate(to:)` to push a new destination onto the navigation stack.
///   - Use `navigateToRoot()` to return to the root view.
///   - Use `navigateBack(_:)` to go back by a specific number of steps.
class Router: ObservableObject {
    
    /// The navigation stack that holds the history of destinations.
    @Published var path: [Router.Destination] = []
    
    // MARK: - Navigation Methods
    
    /// Navigates to the specified destination by appending it to the navigation path.
    ///
    /// - Parameter route: The destination to navigate to.
    func navigate(to route: Router.Destination) {
        path.append(route)
    }
    
    /// Navigates back to the root view by clearing the navigation stack.
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    /// Navigates back by a specified number of steps.
    ///
    /// - Parameter count: The number of steps to go back (default is `1`).
    /// - Note: Ensures that the removal count does not exceed the existing navigation stack size.
    func navigateBack(_ count: Int = 1) {
        path.removeLast(min(count, path.count))
    }
}

// MARK: - Router Destination Enum

extension Router {
    /// **Destination** defines the various navigation destinations in the app.
    enum Destination: Hashable {
        case avatar(preview: InteractiveAvatarPreview)
    }
}


/// **AvatarStorage** is an `ObservableObject` responsible for managing avatar data persistence
/// using `UserDefaults`. It allows saving, loading, adding, and deleting avatars.
///
/// The `avatarsUpdatedAt` property provides a timestamp for UI updates when avatar data changes.
class AvatarStorage: ObservableObject {
    
    /// The key used to store and retrieve avatar data from `UserDefaults`.
    private let key = "savedAvatars"
    
    /// Published property to notify the UI when avatar data is updated.
    @Published var avatarsUpdatedAt = Date()
    
    // MARK: - Methods
    
    /// Saves an array of `InteractiveAvatarPreview` objects to `UserDefaults`.
    ///
    /// - Parameter avatars: The array of avatars to be saved.
    /// - Note: This method also updates `avatarsUpdatedAt` to trigger UI refresh.
    func saveAvatars(_ avatars: [InteractiveAvatarPreview]) {
        do {
            let data = try JSONEncoder().encode(avatars)
            UserDefaults.standard.set(data, forKey: key)
            avatarsUpdatedAt = Date()
        } catch {
            print("❌ Failed to encode avatars: \(error)")
        }
    }
    
    /// Loads avatars from `UserDefaults`.
    ///
    /// - Returns: An array of `InteractiveAvatarPreview` objects, or an empty array if no data exists.
    func loadAvatars() -> [InteractiveAvatarPreview] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([InteractiveAvatarPreview].self, from: data)
        } catch {
            print("❌ No avatars found, or failed to decode: \(error)")
            return []
        }
    }
    
    /// Adds a new avatar to the stored list.
    ///
    /// - Parameter newAvatar: The `InteractiveAvatarPreview` object to add.
    /// - Note: The new avatar is appended to the existing list before saving.
    func addAvatar(_ newAvatar: InteractiveAvatarPreview) {
        var avatars = loadAvatars()
        avatars.append(newAvatar)
        saveAvatars(avatars)
    }
    
    /// Deletes a specific avatar from the stored list.
    ///
    /// - Parameter avatar: The `InteractiveAvatarPreview` object to remove.
    /// - Note: The method removes all occurrences of the matching avatar before saving.
    func deleteAvatar(_ avatar: InteractiveAvatarPreview) {
        var avatars = loadAvatars()
        avatars.removeAll { $0 == avatar }
        saveAvatars(avatars)
    }
}
