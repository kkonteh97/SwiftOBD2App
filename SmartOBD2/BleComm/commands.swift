//
//  commands.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/14/23.
//

import Foundation

 enum ECU: UInt8, Codable {
    case ALL = 0b11111111
    case ALL_KNOWN = 0b11111110
    case UNKNOWN = 0b00000001
    case ENGINE = 0b00000010
    case TRANSMISSION = 0b00000100
}



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
let UAS_IDS: [UInt8: UAS] = [
    // Unsigned
    0x01: UAS(signed: false, scale: 1.0, unit: Unit.count),
    0x02: UAS(signed: false, scale: 0.1, unit: Unit.count),
    0x09: UAS(signed: false, scale: 1, unit: Unit.kph),
    0x07: UAS(signed: false, scale: 0.25, unit: Unit.rpm),

    // Add more entries for other IDs...

    // Signed
    0x81: UAS(signed: true, scale: 1.0, unit: Unit.count),
    0x82: UAS(signed: true, scale: 0.1, unit: Unit.count),
    // Add more entries for other IDs...
]

struct OBDCommand: Codable, Hashable {
    enum Decoder: Codable {
        case pid
        case status
        case single_dtc
        case fuel_status
        case percent
        case temp
        case percent_centered
        case fuel_pressure
        case pressure
        case uas0x07
        case uas0x09
        case timing_advance
        case uas0x27
        case air_status
        case o2_sensors
        case sensor_voltage
        case obd_compliance
        case o2_sensors_alt
        case aux_input_status
        case uas0x12
        case uas0x25
        case uas0x19
        case uas0x1B
        case uas0x01
        case uas0x16
        case uas0x0B
        case uas0x1E
        case evap_pressure
        case sensor_voltage_big
        case current_centered
        case absolute_load
        case drop
        case uas0x34
        case max_maf
        case fuel_type
        case abs_evap_pressure
        case evap_pressure_alt
        case inject_timing
        case dtc
        case fuel_rate
    }

    var name: String
    var description: String
    var cmd: String
    var bytes: Int
    var decoder: Decoder
    var ecu: ECU
    var fast: Bool
    
    func hexStringToUInt8(_ hexString: [String]) -> [UInt8]? {
        // Converts each list value to a UInt8
        let v = hexString.compactMap { UInt8($0, radix: 16) }
        return v.isEmpty ? nil : v
        }

    
    func decode(data: [String]) -> Measurement<Unit>? {
            switch decoder {
            case .percent:
                return percent(data: data)
            case .percent_centered:
                return percentCentered(data: data)
            case .current_centered:
                return currentCentered(data: data)
            case .uas0x09:
                return decodeUAS(data: data, id: 0x09)
            case .uas0x07:
                return decodeUAS(data: data, id: 0x07)

            default:
                return nil
                
            // Add cases for other decoders as needed
            }
        }
    
    
    func decodeUAS(data: [String], id: UInt8) -> Measurement<Unit>? {
            let bytes = data[3...4].compactMap { UInt8($0, radix: 16) }
            print(bytes)
            return UAS_IDS[id]?.decode(bytes: bytes)
        }
    
    
    func percent(data: [String]) -> Measurement<Unit>? {
        let d = data[3...]
        guard var v = Double(d[0]) else {
            return nil
        }
        v = v * 100.0 / 255.0
        return Measurement(value: v, unit: .percent)
    }
    
    
    // -100 to 100 %
    func percentCentered(data: [String]) -> Measurement<Unit>? {
        let d = data[3...]
        
        guard var v = Double(d[0]) else {
            return nil
        }
        
        v = (v - 128) * 100.0 / 128.0
        return Measurement(value: v, unit: .percent)
    }
    
    
    func currentCentered(data: [String]) -> Measurement<Unit>? {
           
           let d = Array(data[2...])
           guard let v = hexStringToUInt8(d) else {
               return nil
           }
           let centeredValue = (Double(bytesToInt(Array(v[2..<4]))) / 256.0) - 128.0
        return Measurement(value: centeredValue, unit: UnitElectricCurrent.milliamperes)
       }
}


struct Modes {
    static let MODE_1 = "01"
    static let MODE_2 = "02"
    static let MODE_3 = "03"
    static let MODE_4 = "04"
    static let MODE_6 = "06"
    
    static func generateCommands(modeIdentifier: String) -> [OBDCommand] {
        let mode = modeIdentifier
        return [
            //    #                      name                             description                    cmd  bytes       decoder           ECU       fast
            OBDCommand(name: "PIDS_A"                     , description: "Supported PIDs [01-20]"                   , cmd: mode + "00", bytes: 6, decoder: .pid,                   ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "STATUS"                     , description: "Status since DTCs cleared"                , cmd: mode + "01", bytes: 6, decoder: .status,                ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FREEZE_DTC"                 , description: "DTC that triggered the freeze frame"      , cmd: mode + "02", bytes: 4, decoder: .single_dtc,            ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_STATUS"                , description: "Fuel System Status"                       , cmd: mode + "03", bytes: 4, decoder: .fuel_status,           ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ENGINE_LOAD"                , description: "Calculated Engine Load"                   , cmd: mode + "04", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "COOLANT_TEMP"               , description: "Engine Coolant Temperature"               , cmd: mode + "05", bytes: 3, decoder: .temp,                  ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "SHORT_FUEL_TRIM_1"          , description: "Short Term Fuel Trim - Bank 1"            , cmd: mode + "06", bytes: 3, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "LONG_FUEL_TRIM_1"           , description: "Long Term Fuel Trim - Bank 1"             , cmd: mode + "07", bytes: 3, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "SHORT_FUEL_TRIM_2"          , description: "Short Term Fuel Trim - Bank 2"            , cmd: mode + "08", bytes: 3, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "LONG_FUEL_TRIM_2"           , description: "Long Term Fuel Trim - Bank 2"             , cmd: mode + "09", bytes: 3, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_PRESSURE"              , description: "Fuel Pressure"                            , cmd: mode + "0A", bytes: 3, decoder: .fuel_pressure,         ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "INTAKE_PRESSURE"            , description: "Intake Manifold Pressure"                 , cmd: mode + "0B", bytes: 3, decoder: .pressure,              ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "RPM"                        , description: "Engine RPM"                               , cmd: mode + "0C", bytes: 4, decoder: .uas0x07,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "SPEED"                      , description: "Vehicle Speed"                            , cmd: mode + "0D", bytes: 3, decoder: .uas0x09,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "TIMING_ADVANCE"             , description: "Timing Advance"                           , cmd: mode + "0E", bytes: 3, decoder: .timing_advance,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "INTAKE_TEMP"                , description: "Intake Air Temp"                          , cmd: mode + "0F", bytes: 3, decoder: .temp,                  ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "MAF"                        , description: "Air Flow Rate (MAF)"                      , cmd: mode + "10", bytes: 4, decoder: .uas0x27,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "THROTTLE_POS"               , description: "Throttle Position"                        , cmd: mode + "11", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "AIR_STATUS"                 , description: "Secondary Air Status"                     , cmd: mode + "12", bytes: 3, decoder: .air_status,            ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_SENSORS"                 , description: "O2 Sensors Present"                       , cmd: mode + "13", bytes: 3, decoder: .o2_sensors,            ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B1S1"                    , description: "O2: Bank 1 - Sensor 1 Voltage"            , cmd: mode + "14", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B1S2"                    , description: "O2: Bank 1 - Sensor 2 Voltage"            , cmd: mode + "15", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B1S3"                    , description: "O2: Bank 1 - Sensor 3 Voltage"            , cmd: mode + "16", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B1S4"                    , description: "O2: Bank 1 - Sensor 4 Voltage"            , cmd: mode + "17", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B2S1"                    , description: "O2: Bank 2 - Sensor 1 Voltage"            , cmd: mode + "18", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B2S2"                    , description: "O2: Bank 2 - Sensor 2 Voltage"            , cmd: mode + "19", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B2S3"                    , description: "O2: Bank 2 - Sensor 3 Voltage"            , cmd: mode + "1A", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_B2S4"                    , description: "O2: Bank 2 - Sensor 4 Voltage"            , cmd: mode + "1B", bytes: 4, decoder: .sensor_voltage,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "OBD_COMPLIANCE"             , description: "OBD Standards Compliance"                 , cmd: mode + "1C", bytes: 3, decoder: .obd_compliance,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_SENSORS_ALT"             , description: "O2 Sensors Present (alternate)"           , cmd: mode + "1D", bytes: 3, decoder: .o2_sensors_alt,        ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "AUX_INPUT_STATUS"           , description: "Auxiliary input status (power take off)"  , cmd: mode + "1E", bytes: 3, decoder: .aux_input_status,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "RUN_TIME"                   , description: "Engine Run Time"                          , cmd: mode + "1F", bytes: 4, decoder: .uas0x12,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "PIDS_B"                     , description: "Supported PIDs [21-40]"                   , cmd: mode + "20", bytes: 6, decoder: .pid,                   ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "DISTANCE_W_MIL"             , description: "Distance Traveled with MIL on"            , cmd: mode + "21", bytes: 4, decoder: .uas0x25,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_RAIL_PRESSURE_VAC"     , description: "Fuel Rail Pressure (relative to vacuum)"  , cmd: mode + "22", bytes: 4, decoder: .uas0x19,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_RAIL_PRESSURE_DIRECT"  , description: "Fuel Rail Pressure (direct inject)"       , cmd: mode + "23", bytes: 4, decoder: .uas0x1B,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S1_WR_VOLTAGE"           , description: "02 Sensor 1 WR Lambda Voltage"            , cmd: mode + "24", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S2_WR_VOLTAGE"           , description: "02 Sensor 2 WR Lambda Voltage"            , cmd: mode + "25", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S3_WR_VOLTAGE"           , description: "02 Sensor 3 WR Lambda Voltage"            , cmd: mode + "26", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S4_WR_VOLTAGE"           , description: "02 Sensor 4 WR Lambda Voltage"            , cmd: mode + "27", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S5_WR_VOLTAGE"           , description: "02 Sensor 5 WR Lambda Voltage"            , cmd: mode + "28", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S6_WR_VOLTAGE"           , description: "02 Sensor 6 WR Lambda Voltage"            , cmd: mode + "29", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S7_WR_VOLTAGE"           , description: "02 Sensor 7 WR Lambda Voltage"            , cmd: mode + "2A", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S8_WR_VOLTAGE"           , description: "02 Sensor 8 WR Lambda Voltage"            , cmd: mode + "2B", bytes: 6, decoder: .sensor_voltage_big,    ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "COMMANDED_EGR"              , description: "Commanded EGR"                            , cmd: mode + "2C", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EGR_ERROR"                  , description: "EGR Error"                                , cmd: mode + "2D", bytes: 3, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EVAPORATIVE_PURGE"          , description: "Commanded Evaporative Purge"              , cmd: mode + "2E", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_LEVEL"                 , description: "Fuel Level Input"                         , cmd: mode + "2F", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "WARMUPS_SINCE_DTC_CLEAR"    , description: "Number of warm-ups since codes cleared"   , cmd: mode + "30", bytes: 3, decoder: .uas0x01,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "DISTANCE_SINCE_DTC_CLEAR"   , description: "Distance traveled since codes cleared"    , cmd: mode + "31", bytes: 4, decoder: .uas0x25,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EVAP_VAPOR_PRESSURE"        , description: "Evaporative system vapor pressure"        , cmd: mode + "32", bytes: 4, decoder: .evap_pressure,         ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "BAROMETRIC_PRESSURE"        , description: "Barometric Pressure"                      , cmd: mode + "33", bytes: 3, decoder: .pressure,              ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S1_WR_CURRENT"           , description: "02 Sensor 1 WR Lambda Current"            , cmd: mode + "34", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S2_WR_CURRENT"           , description: "02 Sensor 2 WR Lambda Current"            , cmd: mode + "35", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S3_WR_CURRENT"           , description: "02 Sensor 3 WR Lambda Current"            , cmd: mode + "36", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S4_WR_CURRENT"           , description: "02 Sensor 4 WR Lambda Current"            , cmd: mode + "37", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S5_WR_CURRENT"           , description: "02 Sensor 5 WR Lambda Current"            , cmd: mode + "38", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S6_WR_CURRENT"           , description: "02 Sensor 6 WR Lambda Current"            , cmd: mode + "39", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S7_WR_CURRENT"           , description: "02 Sensor 7 WR Lambda Current"            , cmd: mode + "3A", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "O2_S8_WR_CURRENT"           , description: "02 Sensor 8 WR Lambda Current"            , cmd: mode + "3B", bytes: 6, decoder: .current_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "CATALYST_TEMP_B1S1"         , description: "Catalyst Temperature: Bank 1 - Sensor 1"  , cmd: mode + "3C", bytes: 4, decoder: .uas0x16,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "CATALYST_TEMP_B2S1"         , description: "Catalyst Temperature: Bank 2 - Sensor 1"  , cmd: mode + "3D", bytes: 4, decoder: .uas0x16,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "CATALYST_TEMP_B1S2"         , description: "Catalyst Temperature: Bank 1 - Sensor 2"  , cmd: mode + "3E", bytes: 4, decoder: .uas0x16,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "CATALYST_TEMP_B2S2"         , description: "Catalyst Temperature: Bank 2 - Sensor 2"  , cmd: mode + "3F", bytes: 4, decoder: .uas0x16,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "PIDS_C"                     , description: "Supported PIDs [41-60]"                   , cmd: mode + "40", bytes: 6, decoder: .pid,                   ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "STATUS_DRIVE_CYCLE"         , description: "Monitor status this drive cycle"          , cmd: mode + "41", bytes: 6, decoder: .status,                ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "CONTROL_MODULE_VOLTAGE"     , description: "Control module voltage"                   , cmd: mode + "42", bytes: 4, decoder: .uas0x0B,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ABSOLUTE_LOAD"              , description: "Absolute load value"                      , cmd: mode + "43", bytes: 4, decoder: .absolute_load,         ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "COMMANDED_EQUIV_RATIO"      , description: "Commanded equivalence ratio"              , cmd: mode + "44", bytes: 4, decoder: .uas0x1E,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "RELATIVE_THROTTLE_POS"      , description: "Relative throttle position"               , cmd: mode + "45", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "AMBIANT_AIR_TEMP"           , description: "Ambient air temperature"                  , cmd: mode + "46", bytes: 3, decoder: .temp,                  ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "THROTTLE_POS_B"             , description: "Absolute throttle position B"             , cmd: mode + "47", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "THROTTLE_POS_C"             , description: "Absolute throttle position C"             , cmd: mode + "48", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ACCELERATOR_POS_D"          , description: "Accelerator pedal position D"             , cmd: mode + "49", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ACCELERATOR_POS_E"          , description: "Accelerator pedal position E"             , cmd: mode + "4A", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ACCELERATOR_POS_F"          , description: "Accelerator pedal position F"             , cmd: mode + "4B", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "THROTTLE_ACTUATOR"          , description: "Commanded throttle actuator"              , cmd: mode + "4C", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "RUN_TIME_MIL"               , description: "Time run with MIL on"                     , cmd: mode + "4D", bytes: 4, decoder: .uas0x34,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "TIME_SINCE_DTC_CLEARED"     , description: "Time since trouble codes cleared"         , cmd: mode + "4E", bytes: 4, decoder: .uas0x34,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "MAX_VALUES"                 , description: "Various Max values"                       , cmd: mode + "4F", bytes: 6, decoder: .drop,                  ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "MAX_MAF"                    , description: "Maximum value for mass air flow sensor"   , cmd: mode + "50", bytes: 6, decoder: .max_maf,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_TYPE"                  , description: "Fuel Type"                                , cmd: mode + "51", bytes: 3, decoder: .fuel_type,             ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "ETHANOL_PERCENT"            , description: "Ethanol Fuel Percent"                     , cmd: mode + "52", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EVAP_VAPOR_PRESSURE_ABS"    , description: "Absolute Evap system Vapor Pressure"      , cmd: mode + "53", bytes: 4, decoder: .abs_evap_pressure,     ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EVAP_VAPOR_PRESSURE_ALT"    , description: "Evap system vapor pressure"               , cmd: mode + "54", bytes: 4, decoder: .evap_pressure_alt,     ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "SHORT_O2_TRIM_B1"           , description: "Short term secondary O2 trim - Bank 1"    , cmd: mode + "55", bytes: 4, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "LONG_O2_TRIM_B1"            , description: "Long term secondary O2 trim - Bank 1"     , cmd: mode + "56", bytes: 4, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "SHORT_O2_TRIM_B2"           , description: "Short term secondary O2 trim - Bank 2"    , cmd: mode + "57", bytes: 4, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "LONG_O2_TRIM_B2"            , description: "Long term secondary O2 trim - Bank 2"     , cmd: mode + "58", bytes: 4, decoder: .percent_centered,      ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_RAIL_PRESSURE_ABS"     , description: "Fuel rail pressure (absolute)"            , cmd: mode + "59", bytes: 4, decoder: .uas0x1B,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "RELATIVE_ACCEL_POS"         , description: "Relative accelerator pedal position"      , cmd: mode + "5A", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "HYBRID_BATTERY_REMAINING"   , description: "Hybrid battery pack remaining life"       , cmd: mode + "5B", bytes: 3, decoder: .percent,               ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "OIL_TEMP"                   , description: "Engine oil temperature"                   , cmd: mode + "5C", bytes: 3, decoder: .temp,                  ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_INJECT_TIMING"         , description: "Fuel injection timing"                    , cmd: mode + "5D", bytes: 4, decoder: .inject_timing,         ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "FUEL_RATE"                  , description: "Engine fuel rate"                         , cmd: mode + "5E", bytes: 4, decoder: .fuel_rate,             ecu: ECU.ENGINE, fast: true),
            OBDCommand(name: "EMISSION_REQ"               , description: "Designed emission requirements"           , cmd: mode + "5F", bytes: 3, decoder: .drop,                  ecu: ECU.ENGINE, fast: true),
            
            // Add more commands here...
        ]
    }
    // Define Mode 1 commands using the common function
    static var mode1: [OBDCommand] {
        return generateCommands(modeIdentifier: "01")
    }
    // modes
    static var modes: [[OBDCommand]] {
        return [mode1]
    }
    
    // getModeAndPID
    
    
    
    static var pid_getters: [OBDCommand] = {
        // returns a list of PID GET commands
        var getters: [OBDCommand] = []
        for mode in Modes.modes {
            for cmd in mode {
                if cmd.decoder == .pid {
                    getters.append(cmd)
                }
            }
        }
        return getters
    }()
    
}
