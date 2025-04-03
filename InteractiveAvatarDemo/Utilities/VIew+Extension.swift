//
//  VIew+Extension.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/24/25.
//

import UIKit

extension UIWindow {
    public static var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow })
    }
    
    public static var safeAreaInsets: UIEdgeInsets {
        keyWindow?.safeAreaInsets ?? .zero
    }
    
    public static var safeAreaTopPadding: CGFloat {
        UIWindow.keyWindow?.safeAreaInsets.top ?? 0
    }
    
    public static var safeAreaBottomPadding: CGFloat {
        UIWindow.keyWindow?.safeAreaInsets.bottom ?? 0
    }
}

extension UIWindow {
    static func getTopViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}
