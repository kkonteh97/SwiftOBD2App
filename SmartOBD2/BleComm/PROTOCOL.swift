//
//  PROTOCOL.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/16/23.
//

import Foundation

extension String {
    var hexBytes: [UInt8] {
        var position = startIndex
        return (0..<count/2).compactMap { _ in
            defer { position = index(position, offsetBy: 2) }
            return UInt8(self[position...index(after: position)], radix: 16)
        }
    }
}

class Message {
    var frames: [Frame]
    var ecu: ECUID?
    var data = Data()
    var txID: UInt8? {
        return frames.first?.txID?.rawValue
    }
    init(frames: [Frame], ecu: ECUID = ECUID.unknown, data: Data = Data()) {
        self.frames = frames
        self.ecu = ecu
        self.data = data
    }
}

enum ECUID: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
    case unknown = 0x02
}

enum TxId: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
}

extension Data {
    func bitCount() -> Int {
        return self.count * 8
    }

    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
}
