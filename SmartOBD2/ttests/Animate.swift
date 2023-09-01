//
//  Animate.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/23/23.
//

import SwiftUI
struct DashedCircleRoadShape: Shape {
    let numberOfDashes: Int
    let dashLength: CGFloat
    let gapLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.size.width, rect.size.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        
        for i in 0..<numberOfDashes {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(numberOfDashes)
            let startX = center.x + radius * cos(angle)
            let startY = center.y + radius * sin(angle)
            let endX = center.x + (radius - dashLength) * cos(angle)
            let endY = center.y + (radius - dashLength) * sin(angle)
            
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        
        return path
    }
}

struct DashedCircleRoadView: View {
    let numberOfDashes: Int = 30
    let dashLength: CGFloat = 8
    let gapLength: CGFloat = 3
    @State private var animate = false
    @State private var rotation =  0.0


    let startingAngle: CGFloat = .pi / 2 // 90 degrees

    var body: some View {
        ZStack {
            DashedCircleRoadShape(numberOfDashes: numberOfDashes, dashLength: dashLength, gapLength: gapLength)
                .stroke(style: StrokeStyle(lineWidth: 14, dash: [dashLength, gapLength]))
                .frame(width: 250, height: 250)
            GeometryReader { geometry in
                let circleRadius = min(geometry.size.width, geometry.size.height) / 3.9
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                let totalAngle = CGFloat.pi * 4 // Total angle to travel around the circle
                
                let angle = startingAngle + totalAngle * rotation


//                let angle = 2 * .pi * CGFloat(8) / CGFloat(numberOfDashes)

                let carX = center.x + circleRadius * cos(angle)
                let carY = center.y + circleRadius * sin(angle)

                
                
                Image("car")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .position(x: carX, y: carY)
                    .rotationEffect(.degrees(angle * -90 / CGFloat.pi)) // Rotate to maintain orientation
                    

            }
            .onAppear() {
//                        animate.toggle() // Start the animation
                withAnimation(.linear(duration: 1.2)) {
                    self.rotation = 1
                }
            }
        }
    }
}

struct Animate: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<20) { i in
                let circles: Int = (i + 1) * 3
                ForEach(0..<circles, id:\.self) { j in
                    Circle()
                        .frame(width: 3, height: 3)
                        .offset(x: -(CGFloat(i) * 5))
                        .rotationEffect(.degrees(Double(j) * 2))
                        .rotationEffect(.degrees(animate ? 0 : 360))
                        .animation(.linear(duration: 0.6).repeatForever(autoreverses: false), value: animate)
                
                }
            
            }
        }
        .preferredColorScheme(.dark)
    }
        
}

#Preview {
    DashedCircleRoadView()
}
