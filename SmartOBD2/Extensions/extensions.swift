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
    
    func hexToBytes() -> [UInt8]? {
        var dataBytes: [UInt8] = []
        for i in stride(from: 0, to: count, by: 2) {
            let startIndex = index(self.startIndex, offsetBy: i)
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
