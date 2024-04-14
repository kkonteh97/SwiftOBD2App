//
//  SplashScreenView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/23/23.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding private var isActive: Bool
    init(isActive: Binding<Bool>) {
        self._isActive = isActive
    }

    @State private var size = 0.7
    @State private var opacity = 0.4
    @State private var animate = false

    let numberOfDashes: Int = 30
    let dashLength: CGFloat = 8
    let gapLength: CGFloat = 3
    let startingAngle: CGFloat = .pi / 2
    @State private var rotation =  0.0
    @State private var carX =  -100.0
    let size1: CGFloat = 250
    var offset: CGFloat = 200

    var body: some View {
            VStack {
                VStack {
                    ZStack {
                        VStack(spacing: 40) {
                            Text("SwiftOBD2")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Give us a star on GitHub")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(opacity)
                        .scaleEffect(size, anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)

                        GeometryReader { geometry in
                            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            Image("car")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 100, height: 100)
                                .foregroundStyle(
                                    LinearGradient(Color.red, Color.blue)
                                )
                                .position(x: carX + center.x, y: center.y + 10)
                        }
                        .onAppear {
                            withAnimation(.spring(duration: 1.4, bounce: 0.4, blendDuration: 2)) {
                                self.rotation = 1
                                self.carX = 0.0
                                self.size = 1.2
                                self.opacity = 0.9
                            }
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = false
                    }
                }
            }
            .preferredColorScheme(.dark)
//            .background(LinearGradient(.darkStart, .darkEnd))
    }
}

#Preview {
    SplashScreenView(isActive: .constant(false))
}
