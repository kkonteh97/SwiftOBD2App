//
//  Decoders.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/18/23.
//

import Foundation

func bytesToInt(_ byteArray: Data) -> Int {
    var value = 0
    var power = 0

    for byte in byteArray.reversed() {
        value += Int(byte) << power
        power += 8
    }
    return value
}

struct BitArray {
    private var data: Data
    var binaryArray: [Int] = []

    init(data: Data) {
        self.data = data
        for byte in data {
            for bit in 0..<8 {
                binaryArray.append(Int((byte >> UInt8(7 - bit)) & 1))
            }
        }
    }

    subscript(index: Int) -> Bool {
        let byteIndex = index / 8
        let bitIndex = index % 8
        return (data[byteIndex] & UInt8(1 << bitIndex)) != 0
    }

    func value(at range: Range<Int>) -> UInt8 {
        var value: UInt8 = 0
        for bit in range {
            value = value << 1
            value = value | UInt8(binaryArray[bit])
        }
        return value
    }
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

    func decode(bytes: Data) -> Measurement<Unit>? {
        var value = bytesToInt(bytes)

        if signed {
            value = twosComp(value, length: bytes.count * 8)
        }

        let scaledValue = Double(value) * scale + offset
        return Measurement(value: scaledValue, unit: unit)
    }
}

extension Unit {
    static let percent = Unit(symbol: "%")
    static let count = Unit(symbol: "count")
    static let celsius = Unit(symbol: "°C")
    static let degrees = Unit(symbol: "°")
    static let gramsPerSecond = Unit(symbol: "g/s")
    static let none = Unit(symbol: "")
    static let kmh = Unit(symbol: "km/h")
    static let rpm = Unit(symbol: "rpm")
    static let kPa = Unit(symbol: "kPa")
    static let bar = Unit(symbol: "bar")
}

let uasIDS: [UInt8: UAS] = [
    // Unsigned
    0x01: UAS(signed: false, scale: 1.0, unit: Unit.count),
    0x02: UAS(signed: false, scale: 0.1, unit: Unit.count),
    0x07: UAS(signed: false, scale: 0.25, unit: Unit.rpm),
    0x09: UAS(signed: false, scale: 1, unit: Unit.kmh),
    0x12: UAS(signed: false, scale: 1, unit: UnitDuration.seconds),

    0x27: UAS(signed: false, scale:  0.01, unit: Unit.gramsPerSecond),

    // Signed
    0x81: UAS(signed: true, scale: 1.0, unit: Unit.count),
    0x82: UAS(signed: true, scale: 0.1, unit: Unit.count)
]

enum Decoder: Codable {
    case pid
    case status
    case singleDTC
    case fuelStatus
    case percent
    case temp
    case percentCentered
    case fuelPressure
    case pressure
    case uas0x07
    case uas0x09
    case uas0x12
    case timingAdvance
    case uas0x27
    case airStatus
    case o2Sensors
    case sensorVoltage
    case obdCompliance
    case o2SensorsAlt
    case auxInputStatus
    case uas0x25
    case uas0x19
    case uas0x1B
    case uas0x01
    case uas0x16
    case uas0x0B
    case uas0x1E
    case evapPressure
    case sensorVoltageBig
    case currentCentered
//    case absoluteLoad
//    case drop
//    case uas0x34
//    case maxMaf
//    case fuelType
//    case absEvapPressure
//    case evapPressureAlt
//    case injectTiming
//    case dtc
//    case fuelRate
    case none

    func decode(data: Data) -> OBDDecodeResult? {
        switch self {
        case .pid:                   
            return nil
        case .status:                
            return .statusResult(status(data))
        case .uas0x09:
            guard let measurement = decodeUAS(data, id: 0x09) else { return .noResult }
            return .measurementResult(measurement)
        case .uas0x07:
            guard let measurement = decodeUAS(data, id: 0x07) else { return .noResult }
            return .measurementResult(measurement)
        case .temp: 
            guard let temp = temp(data) else { return .noResult }
            return .measurementResult(temp)
        case .percent:
            guard let percent = percent(data) else { return .noResult }
            return .measurementResult(percent)
        case .currentCentered:
            guard let currentCentered = currentCentered(data) else { return .noResult }
            return .measurementResult(currentCentered)
        case .airStatus:
            guard let airStatus = currentCentered(data) else { return .noResult }
            return .measurementResult(airStatus)
        case .singleDTC:
            guard let dtcs = singleDtc(data) else { return .noResult }
            return .stringResult(dtcs)
        case .fuelStatus:
            return nil
        case .percentCentered:
            guard let percentCentered = percent(data) else { return .noResult }
            return .measurementResult(percentCentered)
        case .fuelPressure:
            guard let fuelPressure = percent(data) else { return .noResult }
            return .measurementResult(fuelPressure)
        case .pressure:
            guard let pressure = pressure(data) else { return .noResult }
            return .measurementResult(pressure)
        case .timingAdvance: 
            guard let timingAdvance = timingAdvance(data) else { return .noResult }
            return .measurementResult(timingAdvance)

        case .obdCompliance:
            return nil
        case .o2SensorsAlt:
            return nil
        case .uas0x12:
            guard let uasValue =  decodeUAS(data, id: 0x12) else { return .noResult }
            return .measurementResult(uasValue)
        case .o2Sensors:
            return nil

        case .sensorVoltage:
            guard let voltage = voltage(data) else { return .noResult }
            return .measurementResult(voltage)
        case .auxInputStatus:
            return nil

        case .uas0x19:
            guard let uasValue = decodeUAS(data, id: 0x19) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x1B:
            guard let uasValue = decodeUAS(data, id: 0x1B) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x01:
            guard let uasValue = decodeUAS(data, id: 0x01) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x16:
            guard let uasValue = decodeUAS(data, id: 0x16) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x0B:
            guard let uasValue = decodeUAS(data, id: 0x0B) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x1E:
            guard let uasValue = decodeUAS(data, id: 0x1E) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x25:
            guard let uasValue = decodeUAS(data, id: 0x25) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x27:
            guard let uasValue = decodeUAS(data, id: 0x27) else { return .noResult }
            return .measurementResult(uasValue)
        case .sensorVoltageBig:
            return nil
        case .evapPressure:
            return nil
        case .none:
            return nil
        }
    }

    func voltage(_ data: Data) -> Measurement<Unit>? {
        guard data.count == 2 else { return nil }
        let voltage = Double(data.first ?? 0) / 200
        return Measurement(value: voltage, unit: UnitElectricPotentialDifference.volts)
    }

    func decodeUAS(_ data: Data, id: UInt8) -> Measurement<Unit>? {
        return uasIDS[id]?.decode(bytes: data)
    }

    func singleDtc(_ data: Data) -> String? {
        return parseDTC(data)
    }

    func parseDTC(_ data: Data) -> String? {
        if (data.count != 2) || (data == Data([0x00, 0x00])) {
            return nil
        }

        // BYTES: (16,      35      )
        // HEX:    4   1    2   3
        // BIN:    01000001 00100011
        //         [][][  in hex   ]
        //         | / /
        // DTC:    C0123
        var dtc = ["P", "C", "B", "U"][Int(data[0]) >> 6]  // the last 2 bits of the first byte
        dtc += String((data[0] >> 4) & 0b0011)  // the next pair of 2 bits. Mask off the bits we read above
        let dtcString = dtc
        return dtcString
    }

    // 0 to 765 kPa
    func fuelPressure(_ data: Data) -> Measurement<Unit>? {
        var value = data[0]
        value *= 3
        return  Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    // 0 to 255 kPa
    func pressure(_ data: Data) -> Measurement<Unit>? {
        let value = data[0]
        return Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    func percent(_ data: Data) -> Measurement<Unit>? {
        var value = Double(data.first ?? 0)
        value = value * 100.0 / 255.0
        return Measurement(value: value, unit: Unit.percent)
    }

    func percentCentered(_ data: Data) -> Measurement<Unit>? {
        var value = Double(data.first ?? 0)
        value = (value - 128) * 100.0 / 128.0
        return Measurement(value: value, unit: Unit.percent)
    }

    func currentCentered(_ data: Data) -> Measurement<Unit>? {
         let value = (Double(bytesToInt(data[2..<4])) / 256.0) - 128.0
         return Measurement(value: value, unit: UnitElectricCurrent.amperes)
     }

    func airStatus(_ data: Data) -> Measurement<Unit>? {
           let bits = BitArray(data: data).binaryArray

           let numSet = bits.filter { $0 == 1 }.count
           if numSet == 1 {
               let index = 7 - bits.firstIndex(of: 1)!
               return Measurement(value: Double(index), unit: UnitElectricCurrent.amperes)
           }
           return nil
       }

    func temp(_ data: Data) -> Measurement<Unit>? {
        let value = Double(bytesToInt(data)) - 40.0
        return Measurement(value: value, unit: UnitTemperature.celsius)
    }

    func timingAdvance(_ data: Data) -> Measurement<Unit>? {
            let value = Double(data.first ?? 0) / 2.0 - 64.0
            return  Measurement(value: value, unit: UnitAngle.degrees)
    }

    func status(_ data: Data) -> Status {
        let IGNITIONTYPE = ["Spark", "Compression"]

        //            ┌Components not ready
        //            |┌Fuel not ready
        //            ||┌Misfire not ready
        //            |||┌Spark vs. Compression
        //            ||||┌Components supported
        //            |||||┌Fuel supported
        //  ┌MIL      ||||||┌Misfire supported
        //  |         |||||||
        //  10000011 00000111 11111111 00000000
        //  00000000 00000111 11100101 00000000
        //  10111110 00011111 10101000 00010011
        //   [# DTC] X        [supprt] [~ready]

        // convert to binaryarray
        let bits = BitArray(data: data)

        var output = Status()
        output.MIL = bits.binaryArray[0] == 1
        output.dtcCount = bits.value(at: 1..<8)
        output.ignitionType = IGNITIONTYPE[bits.binaryArray[12]]

        // load the 3 base tests that are always present

        for (index, name) in baseTests.reversed().enumerated() {
            processBaseTest(name, index, bits, &output)
        }
        return output
    }

    func processBaseTest(_ testName: String, _ index: Int, _ bits: BitArray, _ output: inout Status) {
        let test = StatusTest(testName, (bits.binaryArray[13 + index] != 0), (bits.binaryArray[9 + index] == 0))
        switch testName {
        case "MISFIRE_MONITORING":
            output.misfireMonitoring = test
        case "FUEL_SYSTEM_MONITORING":
            output.fuelSystemMonitoring = test
        case "COMPONENT_MONITORING":
            output.componentMonitoring = test
        default:
            break
        }
    }


    //    func fuelStatus(_ messages: [Message]) -> (String?, String?) {
    //        guard let data = messages.first?.data.dropFirst(2) else {
    //            return (nil, nil)
    //        }
    //
    //        let FUEL_STATUS = ["Status1", "Status2", "Status3"]
    //
    //        let bits = BitArray(data: data).binaryArray
    //
    //        var status1: String? = nil
    //        var status2: String? = nil
    //
    //        if bits[0..<8].count(1) == 1 {
    //                if let index = bits[0..<8].firstIndex(of: true), 7 - index < FUEL_STATUS.count {
    //                    status1 = FUEL_STATUS[7 - index]
    //                } else {
    //                    NSLog("Invalid response for fuel status (high bits set)")
    //                }
    //            } else {
    //                NSLog("Invalid response for fuel status (multiple/no bits set)")
    //            }
    //
    //            if bits[8..<16].count(true) == 1 {
    //                if let index = bits[8..<16].firstIndex(of: true), 7 - index < FUEL_STATUS.count {
    //                    status2 = FUEL_STATUS[7 - index]
    //                } else {
    //                    NSLog("Invalid response for fuel status (high bits set)")
    //                }
    //            } else {
    //                NSLog("Invalid response for fuel status (multiple/no bits set)")
    //            }
    //
    //            return (status1, status2)
    //    }
}

let baseTests = [
    "MISFIRE_MONITORING",
    "FUEL_SYSTEM_MONITORING",
    "COMPONENT_MONITORING"
]

let sparkTests = [
    "CATALYST_MONITORING",
    "HEATED_CATALYST_MONITORING",
    "EVAPORATIVE_SYSTEM_MONITORING",
    "SECONDARY_AIR_SYSTEM_MONITORING",
    nil,
    "OXYGEN_SENSOR_MONITORING",
    "OXYGEN_SENSOR_HEATER_MONITORING",
    "EGR_VVT_SYSTEM_MONITORING"
]

let compressionTests = [
    "NMHC_CATALYST_MONITORING",
    "NOX_SCR_AFTERTREATMENT_MONITORING",
    nil,
    "BOOST_PRESSURE_MONITORING",
    nil,
    "EXHAUST_GAS_SENSOR_MONITORING",
    "PM_FILTER_MONITORING",
    "EGR_VVT_SYSTEM_MONITORING"
]
