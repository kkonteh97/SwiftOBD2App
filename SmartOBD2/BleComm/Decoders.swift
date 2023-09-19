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

func bytesToInt(_ byteArray: [UInt8]) -> Int {
    var value = 0
    var power = 0

    for byte in byteArray.reversed() {
        value += Int(byte) << power
        power += 8
    }

    return value
}

struct UAS {
    let signed: Bool
    let scale: Double
    let unit: Unit
    let offset: Double

    init(signed: Bool, scale: Double, unit: Unit, offset: Double = 0.0) {
        self.signed = signed
        self.scale = scale
        self.unit = unit
        self.offset = offset
    }
    func twosComp(_ value: Int, length: Int) -> Int {
        let mask = (1 << length) - 1
        return value & mask
    }

    func decode(bytes: [UInt8]) -> Measurement<Unit>? {
            var value = bytesToInt(bytes)

            if signed {
                value = twosComp(value, length: bytes.count * 8)
            }

            let scaledValue = Double(value) * scale + offset
            return Measurement(value: scaledValue, unit: unit)
    }
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
