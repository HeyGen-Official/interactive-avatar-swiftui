//
//  LoadingIndicator.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/18/25.
//

import SwiftUI

struct LoadingIndicator: View {
    private let size: Double
    @Binding private var shouldAnimate: Bool
    
    init(size: Double = 16, shouldAnimate: Binding<Bool> = .constant(true)) {
        self.size = size
        _shouldAnimate = shouldAnimate
    }
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(width: size, height: size)
            .overlay {
                SpinnerView(shouldAnimate: shouldAnimate)
                    .scaleEffect(size / 40)
            }
    }
}

struct SpinnerView: UIViewRepresentable {
    let shouldAnimate: Bool
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "icon_loading"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ imageView: UIImageView, context: Context) {
        if shouldAnimate {
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.fromValue = 0
            rotation.toValue = 2 * Double.pi
            rotation.duration = 2
            rotation.repeatCount = .infinity
            rotation.isRemovedOnCompletion = false
            rotation.fillMode = .forwards
            imageView.layer.add(rotation, forKey: "spinAnimation")
        } else {
            imageView.layer.removeAnimation(forKey: "spinAnimation")
        }
    }
}


#Preview {
    LoadingIndicator(shouldAnimate: .constant(true))
}
