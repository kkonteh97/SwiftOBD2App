//
//  Obd2Parser.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/7/23.
//

import Foundation

public func linesToStrArray(_ linesToParse: [String]) -> [String] {
    var allBytesTogether: [String] = []

    for line in linesToParse {
        let bytesArr = line.split {$0 == " "}.map(String.init)
        for bytes in bytesArr {
            allBytesTogether.append(bytes)
        }
    }
    return allBytesTogether
}

public func linesToStr(_ linesToParse: [String]) -> String {
    var endStr = ""

    for str in linesToParse {
        endStr.append(str)
    }

    // return all but last character
    return String(endStr.dropLast())
}

class OBDParser: NSObject {

    // SINGLETON INSTANCE
    static let sharedInstance = OBDParser()

    override fileprivate init() {
        super.init()
    }

    ////////////////////////////////////////////////////////
    // MARK: PARSING
    ////////////////////////////////////////////////////////

    func parse_0101(_ linesToParse: [String], obdProtocol: PROTOCOL) -> Int {
        print("Parsing 0101")

        let linesAsStrArr = linesToStrArray(linesToParse)

        if linesAsStrArr.count > 1 {
            if let numberOfDtcs = Int(linesAsStrArr[2]) {
                return numberOfDtcs - 80
            } else {
//                log.error("Number of DTCs could not be parsed from \(linesAsStrArr)")
                return 0
            }
        } else {return 0}
    }
}
