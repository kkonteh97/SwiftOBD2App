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

class Frame {
    var raw: String
    var data = Data()
    var priority: UInt8?
    var addrMode: UInt8?
    var rxID: UInt8?
    var txID: ECUID?
    var type: FrameType?
    var seqIndex: UInt8 = 0 // Only used when type = CF
    var dataLen: UInt8?

    init(raw: String) {
        self.raw = raw
    }
}

enum FrameType: UInt8, Codable {
    case singleFrame = 0x00
    case firstFrame = 0x10
    case consecutiveFrame = 0x20
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
