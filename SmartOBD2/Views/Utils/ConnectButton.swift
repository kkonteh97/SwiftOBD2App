//
//  ConnectButton.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/20/23.
//

import SwiftUI

let buttonSize: CGFloat = 50
let imageSize: CGFloat = 50.0
let borderWidth: CGFloat = 2.0
let shadowRadius: CGFloat = 10.0

struct ConnectButton: View {
    let color: Color
    let text: String
    @Binding var isLoading: Bool
    let action: () -> Void

    init(color: Color,
         text: String,
         isLoading: Binding<Bool>,
         action: @escaping () -> Void
    ) {
        self.color = color
        self.text = text
        self._isLoading = isLoading
        self.action = action
    }
    var body: some View {
        ZStack {
            Button(action: {
                action()
            }) {
                if !isLoading {
                    Text(text)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(35)
            .background(color)
            .mask(
                Circle()
                    .frame(width: 80, height: 80)
            )
            .shadow(radius: shadowRadius)
            GoButtonAnimation(isLoading: $isLoading)
        }
    }
}

struct GoButtonAnimation: View {
    @State private var shouldGrow = false
    @Binding var isLoading: Bool
    var body: some View {
        if isLoading {
                ProgressView() // Replace with your spinner view
                    .scaleEffect(1.5)
            } else {
                Ellipse()
                    .foregroundColor(Color.clear)
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .scaleEffect(shouldGrow ? 1.5 : 1.0)
                            .opacity(shouldGrow ? 0.0 : 1.0)
                    )
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            self.shouldGrow = true
                        }
                    }
            }
    }
}
