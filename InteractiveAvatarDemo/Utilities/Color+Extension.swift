//
//  Color+Extension.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/18/25.
//

import SwiftUI

public extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
    
    var uiColor: UIColor? {
        guard let cgColor = cgColor else { return nil }
        return UIColor(cgColor: cgColor)
    }
}


extension Color {
    
    ///#7559FF
    static let primaryHighlight: Color = Color(hex: 0x7559FF)
    
    ///#292A30
    static let grey: Color = Color(hex: 0x292A30)
    
    ///#232323, #000000
    static let backgroundGradient: [Color] = [Color(hex: 0x232323), Color.black]
    
    ///#151515
    static let backgroundElevated: Color = Color(hex: 0x151515)
    
    ///#1F1F1F
    static let backgroundElevated2: Color = Color(hex: 0x1F1F1F)
    
    ///#DE1111
    static let errorRed: Color = Color(hex: 0xDE1111)
}
