//
//  StartButton.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/26/23.
//

import SwiftUI

struct StartButton: View {
    @Environment(\.colorScheme) var colorScheme
    var startColor: Color { Color.sstartColor(for: colorScheme) }
    var endColor: Color { Color.sendColor(for: colorScheme) }
    var shadowColor: Color { colorScheme == .dark ? .sdarkStart : .slightStart }
    
    var body: some View {
        Circle()
            .fill(LinearGradient(endColor, startColor))
            .shadow(color: shadowColor, radius: 10, x: -10, y: -10)
            .shadow(color: shadowColor, radius: 10, x: 10, y: 10)
            .blur(radius: 3)
    }
}

extension Color {
    static let sdarkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let sdarkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let slightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let slightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)

    static func sstartColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .sdarkStart : .slightStart
    }

    static func sendColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .sdarkEnd : .slightEnd
    }
}

#Preview {
    StartButton()
}
struct ButtonBackgroun<S: Shape>: View {
    var isHighlighted: Bool
    var shape: S

    @Environment(\.colorScheme) var colorScheme
    var startColor: Color { Color.startColor(for: colorScheme) }
    var endColor: Color { Color.endColor(for: colorScheme) }
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }

    var body: some View {
        ZStack {
            shape
                .fill(LinearGradient(endColor, startColor))
                .shadow(color: shadowColor, radius: 10, x: -10, y: -10)
                .shadow(color: shadowColor, radius: 10, x: 10, y: 10)
                .blur(radius: isHighlighted ? 4 : 3)
        }
    }
}
