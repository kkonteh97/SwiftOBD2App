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
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let lightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let lightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)

    static let automotivePrimary = Color(red: 27 / 255, green: 109 / 255, blue: 207 / 255)
    static let automotiveSecondary = Color(red: 241 / 255, green: 143 / 255, blue: 1 / 255)
    static let automotiveAccent = Color(red: 228 / 255, green: 57 / 255, blue: 60 / 255)
    static let automotiveBackground = Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)

    static func startColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkStart : .lightStart
    }

    static func endColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkEnd : .lightEnd
    }
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
