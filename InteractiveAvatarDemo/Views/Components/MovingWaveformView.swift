//
//  MovingWaveformView.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/25/25.
//

import SwiftUI

struct MovingWaveformView: View {
    @State private var waveValues: [CGFloat] = [0.1, 0.3, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.7, 0.3, 0.5, 0.1, 0.3, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.7, 0.3, 0.5]
    @State private var timer: Timer?
    let animationDuration: Double = 0.15 // Speed of movement
    
    @Binding var isAnimating: Bool
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(waveValues.indices, id: \.self) { index in
                Rectangle()
                    .fill(Color.primaryHighlight)
                    .frame(width: 2, height: isAnimating ? (waveValues[index] * height) : 3) // Dynamic height
                    .animation(.easeInOut(duration: animationDuration), value: waveValues[index])
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
        .onAppear {
            if isAnimating {
                startAnimating()
            }
        }
        .onDisappear {
            stopAnimating()
        }
    }
    
    func startAnimating() {
        stopAnimating()
        timer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
            if let firstValue = waveValues.first {
                waveValues.removeFirst() // Shift right
                waveValues.append(firstValue) // Append removed value to the end (repeat cycle)
            }
        }
    }
    
    func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
}
