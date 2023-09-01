//
//  extensions.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import SwiftUI

extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let lightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let lightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)

    static func startColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkStart : .lightStart
    }

    static func endColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkEnd : .lightEnd
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
