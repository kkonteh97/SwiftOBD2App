//
//  extensions.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import SwiftUI

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    enum ColorScheme {
        case light
        case dark
    }

    static func currentColorScheme() -> ColorScheme {
        return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
    }

//    static func startColor(for colorScheme: ColorScheme = currentColorScheme()) -> Color {
//        switch colorScheme {
//            case .dark: return Color(red: 238 / 255, green: 244 / 255, blue: 237 / 255)
//            case .light: return Color(red: 241 / 255, green: 242 / 255, blue: 246 / 255)
//        }
//    }
//
    static func endColor(for colorScheme: ColorScheme = currentColorScheme()) -> Color {
        switch colorScheme {
            case .dark: return Color(red: 37 / 255, green: 38 / 255, blue: 31 / 255)
            case .light: return Color(red: 220 / 255, green: 221 / 235, blue: 226 / 255)
        }
    }

    static func automotivePrimaryColor() -> Color {
        return Color(red: 141 / 255, green: 169 / 255, blue: 196 / 255)
    }

    static func automotiveSecondaryColor() -> Color {
        return Color(red: 231 / 255, green: 76 / 255, blue: 60 / 255)
    }

    static func automotiveAccentColor() -> Color {
        return Color(red: 46 / 255, green: 204 / 255, blue: 113 / 255)
    }

    static func automotiveBackgroundColor() -> Color {
        return Color(red: 158 / 255, green: 144 / 255, blue: 127 / 255)
    }
    static let lightGray = Color(red: 13 / 255, green: 27 / 255, blue: 42 / 255)
    static let cyclamen = Color(red: 46 / 255, green: 64 / 255, blue: 89 / 255)
    static let pinknew = Color(red: 119 / 255, green: 141 / 255, blue: 169 / 255)

    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingAmount = max(0, toLength - count)
        let padding = String(repeating: character, count: paddingAmount)
        return padding + self
    }

    func hexToBytes() -> [UInt8]? {
        var dataBytes: [UInt8] = []
        for hex in stride(from: 0, to: count, by: 2) {
            let startIndex = index(self.startIndex, offsetBy: hex)
            if let endIndex = index(startIndex, offsetBy: 2, limitedBy: self.endIndex) {
                let byteString = self[startIndex..<endIndex]

                if let byte = UInt8(byteString, radix: 16) {
                    dataBytes.append(byte)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        return dataBytes
    }
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
