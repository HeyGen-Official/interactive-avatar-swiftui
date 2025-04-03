//
//  CustomButton.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/25/25.
//

import SwiftUI

struct CustomButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primaryHighlight)
                .cornerRadius(8)
        }
    }
}
