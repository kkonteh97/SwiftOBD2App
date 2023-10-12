//
//  ELM327Parser.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/19/23.
//

import Foundation

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

enum FrameError: Error {
    case oddFrame
    case invalidSize
    case missingDataLength
    case invalidDataLength
    case nonContiguousFrame
}

extension ELM327 {
    func call(_ lines: [String], idBits: Int) -> [Message]? {

        let (obdLines, nonOBDLines) = lines.reduce(into: ([String](), [String]())) { result, line in
            let lineNoSpaces = line.replacingOccurrences(of: " ", with: "")
            if isHex(lineNoSpaces) {
                result.0.append(lineNoSpaces)
            } else {
                result.1.append(line)
            }
        }

        let frames = obdLines.compactMap { raw in
            let frame = Frame(raw: raw)
            return parseFrame(frame, idBits: idBits) ? frame : nil
        }

        var framesByECU = [ECUID: [Frame]]()
        for frame in frames {
            if let txID = frame.txID {
                if var frameArray = framesByECU[txID] {
                    frameArray.append(frame)
                    framesByECU[txID] = frameArray
                } else {
                    framesByECU[txID] = [frame]
                }
            }
        }

        var messages = [Message]()
        for ecu in framesByECU.keys {
            let message = Message(frames: framesByECU[ecu] ?? [])
            if parseMessage(message) {
                message.ecu = ECUID(rawValue: ecu.rawValue) ?? ECUID.unknown
                messages.append(message)
            }
        }

        let nonOBDMessages = nonOBDLines.map { line in
            Message(frames: [Frame(raw: line)])
        }

        messages.append(contentsOf: nonOBDMessages)

        return messages.isEmpty ? nil : messages
    }

    func parseFrame(_ frame: Frame, idBits: Int) -> Bool {
        var raw = frame.raw
        if idBits == 11 {
            raw = "00000" + raw
        }

        guard validateFrame(raw: raw, idBits: idBits, frame: frame) else {
            return false
        }

        if idBits == 11 {
            parse11BitFrame(raw: raw, frame: frame)
        } else {
            parse29BitFrame(raw: raw, frame: frame)
        }

        return true
    }

    private func parse11BitFrame(raw: String, frame: Frame) {
        frame.priority = raw.hexBytes[2] & 0x0F
        frame.addrMode = raw.hexBytes[3] & 0xF0

        if frame.addrMode == 0xD0 {
            frame.rxID = raw.hexBytes[3] & 0x0F
            frame.txID = ECUID(rawValue: 0xF1)
        } else if (raw.hexBytes[3] & 0x08) != 0 {
            frame.rxID = 0xF1
            frame.txID = ECUID(rawValue: raw.hexBytes[3] & 0x07)
        } else {
            frame.txID = ECUID(rawValue: 0xF1)
            frame.rxID = raw.hexBytes[3] & 0x07
        }

        frame.data = Data(raw.hexBytes[4...])
        frame.type = FrameType(rawValue: frame.data[0] & 0xF0) ?? nil

        if ![.singleFrame, .firstFrame, .consecutiveFrame].contains(frame.type) {
            print("Dropping frame carrying unknown PCI frame type")
            return
        }
        if frame.type == .singleFrame {
            frame.dataLen = UInt8(frame.data[0] & 0x0F)
            if frame.dataLen == 0 {
                return
            }
        } else if frame.type == .firstFrame {
            frame.dataLen = UInt8((UInt16(frame.data[0] & 0x0F) << 8) + UInt16(frame.data[1]))
            if frame.dataLen == 0 {
                return
            }
        } else if frame.type == .consecutiveFrame {
            frame.seqIndex = frame.data[0] & 0x0F
        }
    }

    func parse29BitFrame(raw: String, frame: Frame) {
        frame.priority = raw.hexBytes[0]
        frame.addrMode = raw.hexBytes[1]
        frame.rxID = raw.hexBytes[2]
        frame.txID = ECUID(rawValue: raw.hexBytes[3])
        frame.data = Data(raw.hexBytes[4...])
        frame.type = FrameType(rawValue: frame.data[0] & 0xF0) ?? nil
    }

    func parseMessage(_ message: Message) -> Bool {
        let frames = message.frames

        if frames.count == 1 {
            return parseSingleFrameMessage(message)
        } else {
            return parseMultiFrameMessage(message)
        }
    }

    func parseSingleFrameMessage(_ message: Message) -> Bool {
        guard let frame = message.frames.first, frame.type == .singleFrame else {
            print("Received lone frame not marked as single frame")
            return false
        }

        // extract data, ignore PCI byte and anything after the marked length
        //             [      Frame       ]
        //                [     Data      ]
        // 00 00 07 E8 06 41 00 BE 7F B8 13 xx xx xx xx, anything else is ignored
        guard let dataLen = frame.dataLen, dataLen > 0 else {
            print("Received single frame with no data")
            return false
        }

        message.data = Data(frame.data[2..<(1 + Int(dataLen))])
        return true
    }

    func parseMultiFrameMessage(_ message: Message) -> Bool {
        let firstFrames = message.frames.filter { $0.type == .firstFrame }
        let consecutiveFrames = message.frames.filter { $0.type == .consecutiveFrame }

        guard firstFrames.count == 1 else {
            print("Received multiple frames marked FF")
            return false
        }

        guard !consecutiveFrames.isEmpty else {
            print("Never received frame marked CF")
            return false
        }
        // Calculate sequence indices, sort, and check contiguity
        let sortedConsecutiveFrames = sortAndCheckContiguity(consecutiveFrames)
        // Extract and assemble data
        if let assembledData = assembleData(firstFrame: firstFrames[0], consecutiveFrames: sortedConsecutiveFrames) {
            message.data = assembledData
            return true
        } else {
            return false
        }
    }

    func sortAndCheckContiguity(_ consecutiveFrames: [Frame]) -> [Frame] {
        // Sort the frames by their sequence index
        let sortedFrames = consecutiveFrames.sorted { $0.seqIndex < $1.seqIndex }
        // Check contiguity and filter out any frames that are not contiguous
        var contiguousFrames: [Frame] = [sortedFrames[0]]
        for index in 1..<sortedFrames.count {
            let prev = contiguousFrames.last!
            let curr = sortedFrames[index]

            // Calculate the expected next sequence index
            let expectedSeqIndex = (prev.seqIndex + 1) & 0x0F

            if curr.seqIndex == expectedSeqIndex {
                // The frame is contiguous, add it to the list
                contiguousFrames.append(curr)
            } else {
                // The frame is not contiguous, print a warning
                print("""
                      Received non-contiguous frame with sequence index \(curr.seqIndex), expected \(expectedSeqIndex)
                      """)
            }
        }
        return contiguousFrames
    }

    func assembleData(firstFrame: Frame, consecutiveFrames: [Frame]) -> Data? {
        let assembledFrame: Frame = firstFrame
        // Extract data from consecutive frames, skipping the PCI byte
        for frame in consecutiveFrames {
            print("Assembling frame with sequence index \(frame.seqIndex)")
            assembledFrame.data.append(frame.data)
        }
        return extractDataFromFrame(assembledFrame, startIndex: 3)
    }

    func extractDataFromFrame(_ frame: Frame, startIndex: Int) -> Data? {
        guard let frameDataLen = frame.dataLen else {
            print("Missing data length in frame")
            return nil
        }
        let endIndex = startIndex + Int(frameDataLen)
        guard endIndex <= frame.data.count else {
            print("Invalid data length in frame")
            return nil
        }
        return frame.data[startIndex..<endIndex]
    }

    func isContiguous(_ indices: [UInt8]) -> Bool {
        var last = indices[0]
        for indice in indices {
            if indice != last + 1 {
                return false
            }
            last = indice
        }
        return true
    }

    func isHex(_ str: String) -> Bool {
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEF")
        return str.uppercased().rangeOfCharacter(from: hexChars.inverted) == nil
    }

    func validateFrame(raw: String, idBits: Int, frame: Frame) -> Bool {
        if raw.count % 2 != 0 {
            print("Dropping frame for being odd")
            return false
        }

        let rawBytes = raw.hexBytes

        if rawBytes.count < 6 || rawBytes.count > 12 {
            print("Dropped frame for invalid size")
            return false
        }

        return true
    }
}
