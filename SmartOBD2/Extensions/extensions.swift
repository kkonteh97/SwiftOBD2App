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

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingAmount = max(0, toLength - count)
        let padding = String(repeating: character, count: paddingAmount)
        return padding + self
    }
}

extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
