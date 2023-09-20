//
//  Decoders.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/18/23.
//

import Foundation

extension Unit {
    static let percent = Unit(symbol: "%")
    static let count = Unit(symbol: "count")
    static let degreeCelsius = Unit(symbol: "°C")
    static let kph = Unit(symbol: "kph")
    static let rpm = Unit(symbol: "rpm")
}

let uasIDS: [UInt8: UAS] = [
    // Unsigned
    0x01: UAS(signed: false, scale: 1.0, unit: Unit.count),
    0x02: UAS(signed: false, scale: 0.1, unit: Unit.count),
    0x07: UAS(signed: false, scale: 0.25, unit: Unit.rpm),
    0x09: UAS(signed: false, scale: 1, unit: Unit.kph),
    0x12: UAS(signed: false, scale: 1, unit: UnitDuration.seconds),

    // Signed
    0x81: UAS(signed: true, scale: 1.0, unit: Unit.count),
    0x82: UAS(signed: true, scale: 0.1, unit: Unit.count)
]
