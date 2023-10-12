//
//  commands.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/14/23.
//

import Foundation

struct Status {
    var MIL: Bool = false
    var dtcCount: UInt8 = 0
    var ignitionType: String = ""

    var misfireMonitoring: StatusTest
    var fuelSystemMonitoring: StatusTest
    var componentMonitoring: StatusTest

    // Add other properties for SPARK_TESTS and COMPRESSION_TESTS here
    init() {
        misfireMonitoring = StatusTest()
        fuelSystemMonitoring = StatusTest()
        componentMonitoring = StatusTest()
    }
}

struct StatusTest {
    var name: String = ""
    var supported: Bool = false
    var ready: Bool = false

    init(_ name: String = "", _ supported: Bool = false, _ ready: Bool = false) {
        self.name = name
        self.supported = supported
        self.ready = ready
    }
}

enum ECU: UInt8, Codable {
    case ALL = 0b11111111
    case ALLKNOWN = 0b11111110
    case UNKNOWN = 0b00000001
    case ENGINE = 0b00000010
    case TRANSMISSION = 0b00000100
}

struct OBDCommandConfiguration {
    let name: String
    let description: String
    let cmd: String
    let bytes: Int
    let decoder: Decoder
    let ecu: ECU
    let fast: Bool
}

enum OBDCommand: CaseIterable, Codable, Identifiable, Comparable {
    case pidsA
    case status
    case freezeDTC
    case fuelStatus
    case engineLoad
    case coolantTemp
    case shortFuelTrim1
    case longFuelTrim1
    case shortFuelTrim2
    case longFuelTrim2
    case fuelPressure
    case intakePressure
    case rpm
    case speed
    case timingAdvance
    case intakeTemp
    case maf
    case throttlePos
    case pidsB

    func command(mode: String) -> String {
        switch self {
        case .pidsA:              return mode + "00"
        case .status:             return mode + "01"
        case .freezeDTC:          return mode + "02"
        case .fuelStatus:         return mode + "03"
        case .engineLoad:         return mode + "04"
        case .coolantTemp:        return mode + "05"
        case .shortFuelTrim1:     return mode + "06"
        case .longFuelTrim1:      return mode + "07"
        case .shortFuelTrim2:     return mode + "08"
        case .longFuelTrim2:      return mode + "09"
        case .fuelPressure:       return mode + "0A"
        case .intakePressure:     return mode + "0B"
        case .rpm:                return mode + "0C"
        case .speed:              return mode + "0D"
        case .timingAdvance:      return mode + "0E"
        case .intakeTemp:         return mode + "0F"
        case .maf:                return mode + "10"
        case .throttlePos:        return mode + "11"
        case .pidsB:              return mode + "20"
        }
    }

    var id: UUID { UUID() }

    var description: String {
        switch self {
        case .pidsA:              return "Supported PIDs [01-20]"
        case .status:             return "Status since DTCs cleared"
        case .freezeDTC:          return "DTC that triggered the freeze frame"
        case .fuelStatus:         return "Fuel System Status"
        case .engineLoad:         return "Calculated Engine Load"
        case .coolantTemp:        return "Coolant temperature"
        case .shortFuelTrim1:     return "Short Term Fuel Trim - Bank 1"
        case .longFuelTrim1:      return "Long Term Fuel Trim - Bank 1"
        case .shortFuelTrim2:     return "Short Term Fuel Trim - Bank 2"
        case .longFuelTrim2:      return "Long Term Fuel Trim - Bank 2"
        case .fuelPressure:       return "Fuel Pressure"
        case .intakePressure:     return "Intake Manifold Pressure"
        case .speed:              return "Vehicle Speed"
        case .rpm:                return "RPM"
        case .timingAdvance:      return "Timing Advance"
        case .intakeTemp:         return "Intake Air Temp"
        case .maf:                return "Air Flow Rate (MAF)"
        case .throttlePos:        return "Throttle Position"
        case .pidsB:              return "Supported PIDs [21-40]"
        }
    }

    var bytes: Int {
        switch self {
        case .pidsA:              return 4
        case .status:             return 4
        case .freezeDTC:          return 4
        case .fuelStatus:         return 4
        case .engineLoad:         return 1
        case .coolantTemp:        return 1
        case .shortFuelTrim1:     return 2
        case .longFuelTrim1:      return 2
        case .shortFuelTrim2:     return 2
        case .longFuelTrim2:      return 2
        case .fuelPressure:       return 1
        case .intakePressure:     return 2
        case .rpm:                return 2
        case .speed:              return 1
        case .timingAdvance:      return 2
        case .intakeTemp:         return 1
        case .maf:                return 2
        case .throttlePos:        return 1
        case .pidsB:              return 4
        }
    }

    var decoder: Decoder {
        switch self {
        case .pidsA:             return .pid
        case .status:            return .status
        case .freezeDTC:         return .singleDTC
        case .fuelStatus:        return .fuelStatus
        case .engineLoad:        return .percent
        case .coolantTemp:       return .temp
        case .shortFuelTrim1:    return .percentCentered
        case .longFuelTrim1:     return .percentCentered
        case .shortFuelTrim2:    return .percentCentered
        case .longFuelTrim2:     return .percentCentered
        case .fuelPressure:      return .fuelPressure
        case .intakePressure:    return .pressure
        case .rpm:               return .uas0x07
        case .speed:             return .uas0x09
        case .timingAdvance:     return .timingAdvance
        case .intakeTemp:        return .temp
        case .maf:               return .uas0x27
        case .throttlePos:       return .percent
        case .pidsB:             return .pid
        }
    }

    static var pidGetters: [OBDCommand] = {
        var getters: [OBDCommand] = []
        for command in OBDCommand.allCases {
            if command.decoder == .pid {
                getters.append(command)
            }
        }
        return getters
    }()
}

//
// struct OBDCommand: Codable, Hashable {
//    var name: String
//    var description: String
//    var cmd: String
//    var bytes: Int
//    var decoder: Decoder
//    var ecu: ECU
//    var fast: Bool
//
//    init(_ name: String, description: String, cmd: String, bytes: Int, decoder: Decoder, ecu: ECU, fast: Bool = false) {
//         self.name = name
//         self.description = description
//         self.cmd = cmd
//         self.bytes = bytes
//         self.decoder = decoder
//         self.ecu = ecu
//         self.fast = fast
//     }
//
//    static func generateCommand(_ name: String, mode: String, cmd: String, description: String, bytes: Int, decoder: Decoder, ecu: ECU, fast: Bool = false) -> OBDCommand {
//        return OBDCommand(name, description: description, cmd: "\(mode)\(cmd)", bytes: bytes, decoder: decoder, ecu: ecu, fast: fast)
//    }
//
//    static var commands: [String: OBDCommand] {
//            var commandDictionary = [String: OBDCommand]()
//
//            // Populate the dictionary with your commands
//            for command in Self.mode1 {
//                commandDictionary[command.name] = command
//            }
//
//            return commandDictionary
//    }
// }
//
// extension OBDCommand {
//    static var mode1: [OBDCommand] {
//        return [
//            generateCommand("PIDS_A", mode: "01", cmd: "00", description: "Supported PIDs [01-20]", bytes: 6, decoder: .pid, ecu: ECU.ENGINE),
//            generateCommand("status", mode: "01", cmd: "01", description: "Status since DTCs cleared", bytes: 6, decoder: .status, ecu: ECU.ENGINE, fast: true),
//            generateCommand("freezeDTC", mode: "01", cmd: "02", description: "DTC that triggered the freeze frame", bytes: 4, decoder: .singleDTC, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_STATUS", mode: "01", cmd: "03", description: "Fuel System Status", bytes: 4, decoder: .fuelStatus, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ENGINE_LOAD", mode: "01", cmd: "04", description: "Calculated Engine Load", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("COOLANT_TEMP", mode: "01", cmd: "05", description: "Engine Coolant Temperature", bytes: 3, decoder: .temp, ecu: ECU.ENGINE, fast: true),
//            generateCommand("SHORT_FUEL_TRIM_1", mode: "01", cmd: "06", description: "Short Term Fuel Trim - Bank 1", bytes: 3, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("LONG_FUEL_TRIM_1", mode: "01", cmd: "07", description: "Long Term Fuel Trim - Bank 1", bytes: 3, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("SHORT_FUEL_TRIM_2", mode: "01", cmd: "08", description: "Short Term Fuel Trim - Bank 2", bytes: 3, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("LONG_FUEL_TRIM_2", mode: "01", cmd: "09", description: "Long Term Fuel Trim - Bank 2", bytes: 3, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_PRESSURE", mode: "01", cmd: "0A", description: "Fuel Pressure", bytes: 3, decoder: .fuelPressure, ecu: ECU.ENGINE, fast: true),
//            generateCommand("INTAKE_PRESSURE", mode: "01", cmd: "0B", description: "Intake Manifold Pressure", bytes: 3, decoder: .pressure, ecu: ECU.ENGINE, fast: true),
//            generateCommand("rpm", mode: "01", cmd: "0C", description: "Engine RPM", bytes: 4, decoder: .uas0x07, ecu: ECU.ENGINE, fast: true),
//            generateCommand("speed", mode: "01", cmd: "0D", description: "Vehicle Speed", bytes: 3, decoder: .uas0x09, ecu: ECU.ENGINE, fast: true),
//            generateCommand("TIMING_ADVANCE", mode: "01", cmd: "0E", description: "Timing Advance", bytes: 3, decoder: .timingAdvance, ecu: ECU.ENGINE, fast: true),
//            generateCommand("INTAKE_TEMP", mode: "01", cmd: "0F", description: "Intake Air Temp", bytes: 3, decoder: .temp, ecu: ECU.ENGINE, fast: true),
//            generateCommand("MAF", mode: "01", cmd: "10", description: "Air Flow Rate (MAF)", bytes: 4, decoder: .uas0x27, ecu: ECU.ENGINE, fast: true),
//            generateCommand("THROTTLE_POS", mode: "01", cmd: "11", description: "Throttle Position", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("AIR_STATUS", mode: "01", cmd: "12", description: "Secondary Air Status", bytes: 3, decoder: .airStatus, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_SENSORS", mode: "01", cmd: "13", description: "O2 Sensors Present", bytes: 3, decoder: .o2Sensors, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B1S1", mode: "01", cmd: "14", description: "O2: Bank 1 - Sensor 1 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B1S2", mode: "01", cmd: "15", description: "O2: Bank 1 - Sensor 2 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B1S3", mode: "01", cmd: "16", description: "O2: Bank 1 - Sensor 3 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B1S4", mode: "01", cmd: "17", description: "O2: Bank 1 - Sensor 4 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B2S1", mode: "01", cmd: "18", description: "O2: Bank 2 - Sensor 1 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B2S2", mode: "01", cmd: "19", description: "O2: Bank 2 - Sensor 2 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B2S3", mode: "01", cmd: "1A", description: "O2: Bank 2 - Sensor 3 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_B2S4", mode: "01", cmd: "1B", description: "O2: Bank 2 - Sensor 4 Voltage", bytes: 4, decoder: .sensorVoltage, ecu: ECU.ENGINE, fast: true),
//            generateCommand("OBD_COMPLIANCE", mode: "01", cmd: "1C", description: "OBD Standards Compliance", bytes: 3, decoder: .obdCompliance, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_SENSORS_ALT", mode: "01", cmd: "1D", description: "O2 Sensors Present (alternate)", bytes: 3, decoder: .o2SensorsAlt, ecu: ECU.ENGINE, fast: true),
//            generateCommand("AUX_INPUT_STATUS", mode: "01", cmd: "1E", description: "Auxiliary input status (power take off)", bytes: 3, decoder: .auxInputStatus, ecu: ECU.ENGINE, fast: true),
//            generateCommand("RUN_TIME", mode: "01", cmd: "1F", description: "Engine Run Time", bytes: 4, decoder: .uas0x12, ecu: ECU.ENGINE, fast: true),
//            generateCommand("PIDS_B", mode: "01", cmd: "20", description: "Supported PIDs [21-40]", bytes: 6, decoder: .pid, ecu: ECU.ENGINE, fast: true),
//            generateCommand("DISTANCE_W_MIL", mode: "01", cmd: "21", description: "Distance Traveled with MIL on", bytes: 4, decoder: .uas0x25, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_RAIL_PRESSURE_VAC", mode: "01", cmd: "22", description: "Fuel Rail Pressure (relative to vacuum)", bytes: 4, decoder: .uas0x19, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_RAIL_PRESSURE_DIRECT", mode: "01", cmd: "23", description: "Fuel Rail Pressure (direct inject)", bytes: 4, decoder: .uas0x1B, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S1_WR_VOLTAGE", mode: "01", cmd: "24", description: "02 Sensor 1 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S2_WR_VOLTAGE", mode: "01", cmd: "25", description: "02 Sensor 2 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S3_WR_VOLTAGE", mode: "01", cmd: "26", description: "02 Sensor 3 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S4_WR_VOLTAGE", mode: "01", cmd: "27", description: "02 Sensor 4 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S5_WR_VOLTAGE", mode: "01", cmd: "28", description: "02 Sensor 5 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S6_WR_VOLTAGE", mode: "01", cmd: "29", description: "02 Sensor 6 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S7_WR_VOLTAGE", mode: "01", cmd: "2A", description: "02 Sensor 7 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S8_WR_VOLTAGE", mode: "01", cmd: "2B", description: "02 Sensor 8 WR Lambda Voltage", bytes: 6, decoder: .sensorVoltageBig, ecu: ECU.ENGINE, fast: true),
//            generateCommand("COMMANDED_EGR", mode: "01", cmd: "2C", description: "Commanded EGR", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EGR_ERROR", mode: "01", cmd: "2D", description: "EGR Error", bytes: 3, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EVAPORATIVE_PURGE", mode: "01", cmd: "2E", description: "Commanded Evaporative Purge", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_LEVEL", mode: "01", cmd: "2F", description: "Fuel Level Input", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("WARMUPS_SINCE_DTC_CLEAR", mode: "01", cmd: "30", description: "Number of warm-ups since codes cleared", bytes: 3, decoder: .uas0x01, ecu: ECU.ENGINE, fast: true),
//            generateCommand("DISTANCE_SINCE_DTC_CLEAR", mode: "01", cmd: "31", description: "Distance traveled since codes cleared", bytes: 4, decoder: .uas0x25, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EVAP_VAPOR_PRESSURE", mode: "01", cmd: "32", description: "Evaporative system vapor pressure", bytes: 4, decoder: .evapPressure, ecu: ECU.ENGINE, fast: true),
//            generateCommand("BAROMETRIC_PRESSURE", mode: "01", cmd: "33", description: "Barometric Pressure", bytes: 3, decoder: .pressure, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S1_WR_CURRENT", mode: "01", cmd: "34", description: "02 Sensor 1 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S2_WR_CURRENT", mode: "01", cmd: "35", description: "02 Sensor 2 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S3_WR_CURRENT", mode: "01", cmd: "36", description: "02 Sensor 3 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S4_WR_CURRENT", mode: "01", cmd: "37", description: "02 Sensor 4 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S5_WR_CURRENT", mode: "01", cmd: "38", description: "02 Sensor 5 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S6_WR_CURRENT", mode: "01", cmd: "39", description: "02 Sensor 6 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S7_WR_CURRENT", mode: "01", cmd: "3A", description: "02 Sensor 7 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("O2_S8_WR_CURRENT", mode: "01", cmd: "3B", description: "02 Sensor 8 WR Lambda Current", bytes: 6, decoder: .currentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("CATALYST_TEMP_B1S1", mode: "01", cmd: "3C", description: "Catalyst Temperature: Bank 1 - Sensor 1", bytes: 4, decoder: .uas0x16, ecu: ECU.ENGINE, fast: true),
//            generateCommand("CATALYST_TEMP_B2S1", mode: "01", cmd: "3D", description: "Catalyst Temperature: Bank 2 - Sensor 1", bytes: 4, decoder: .uas0x16, ecu: ECU.ENGINE, fast: true),
//            generateCommand("CATALYST_TEMP_B1S2", mode: "01", cmd: "3E", description: "Catalyst Temperature: Bank 1 - Sensor 2", bytes: 4, decoder: .uas0x16, ecu: ECU.ENGINE, fast: true),
//            generateCommand("CATALYST_TEMP_B2S2", mode: "01", cmd: "3F", description: "Catalyst Temperature: Bank 2 - Sensor 2", bytes: 4, decoder: .uas0x16, ecu: ECU.ENGINE, fast: true),
//            generateCommand("PIDS_C", mode: "01", cmd: "40", description: "Supported PIDs [41-60]", bytes: 6, decoder: .pid, ecu: ECU.ENGINE, fast: true),
//            generateCommand("STATUS_DRIVE_CYCLE", mode: "01", cmd: "41", description: "Monitor status this drive cycle", bytes: 6, decoder: .status, ecu: ECU.ENGINE, fast: true),
//            generateCommand("CONTROL_MODULE_VOLTAGE", mode: "01", cmd: "42", description: "Control module voltage", bytes: 4, decoder: .uas0x0B, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ABSOLUTE_LOAD", mode: "01", cmd: "43", description: "Absolute load value", bytes: 4, decoder: .absoluteLoad, ecu: ECU.ENGINE, fast: true),
//            generateCommand("COMMANDED_EQUIV_RATIO", mode: "01", cmd: "44", description: "Commanded equivalence ratio", bytes: 4, decoder: .uas0x1E, ecu: ECU.ENGINE, fast: true),
//            generateCommand("RELATIVE_THROTTLE_POS", mode: "01", cmd: "45", description: "Relative throttle position", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("AMBIANT_AIR_TEMP", mode: "01", cmd: "46", description: "Ambient air temperature", bytes: 3, decoder: .temp, ecu: ECU.ENGINE, fast: true),
//            generateCommand("THROTTLE_POS_B", mode: "01", cmd: "47", description: "Absolute throttle position B", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("THROTTLE_POS_C", mode: "01", cmd: "48", description: "Absolute throttle position C", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ACCELERATOR_POS_D", mode: "01", cmd: "49", description: "Accelerator pedal position D", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ACCELERATOR_POS_E", mode: "01", cmd: "4A", description: "Accelerator pedal position E", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ACCELERATOR_POS_F", mode: "01", cmd: "4B", description: "Accelerator pedal position F", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("THROTTLE_ACTUATOR", mode: "01", cmd: "4C", description: "Commanded throttle actuator", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("RUN_TIME_MIL", mode: "01", cmd: "4D", description: "Time run with MIL on", bytes: 4, decoder: .uas0x34, ecu: ECU.ENGINE, fast: true),
//            generateCommand("TIME_SINCE_DTC_CLEARED", mode: "01", cmd: "4E", description: "Time since trouble codes cleared", bytes: 4, decoder: .uas0x34, ecu: ECU.ENGINE, fast: true),
//            generateCommand("MAX_VALUES", mode: "01", cmd: "4F", description: "Various Max values", bytes: 6, decoder: .drop, ecu: ECU.ENGINE, fast: true),
//            generateCommand("MAX_MAF", mode: "01", cmd: "50", description: "Maximum value for mass air flow sensor", bytes: 6, decoder: .maxMaf, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_TYPE", mode: "01", cmd: "51", description: "Fuel Type", bytes: 3, decoder: .fuelType, ecu: ECU.ENGINE, fast: true),
//            generateCommand("ETHANOL_PERCENT", mode: "01", cmd: "52", description: "Ethanol Fuel Percent", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EVAP_VAPOR_PRESSURE_ABS", mode: "01", cmd: "53", description: "Absolute Evap system Vapor Pressure", bytes: 4, decoder: .absEvapPressure, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EVAP_VAPOR_PRESSURE_ALT", mode: "01", cmd: "54", description: "Evap system vapor pressure", bytes: 4, decoder: .evapPressureAlt, ecu: ECU.ENGINE, fast: true),
//            generateCommand("SHORT_O2_TRIM_B1", mode: "01", cmd: "55", description: "Short term secondary O2 trim - Bank 1", bytes: 4, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("LONG_O2_TRIM_B1", mode: "01", cmd: "56", description: "Long term secondary O2 trim - Bank 1", bytes: 4, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("SHORT_O2_TRIM_B2", mode: "01", cmd: "57", description: "Short term secondary O2 trim - Bank 2", bytes: 4, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("LONG_O2_TRIM_B2", mode: "01", cmd: "58", description: "Long term secondary O2 trim - Bank 2", bytes: 4, decoder: .percentCentered, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_RAIL_PRESSURE_ABS", mode: "01", cmd: "59", description: "Fuel rail pressure (absolute)", bytes: 4, decoder: .uas0x1B, ecu: ECU.ENGINE, fast: true),
//            generateCommand("RELATIVE_ACCEL_POS", mode: "01", cmd: "5A", description: "Relative accelerator pedal position", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("HYBRID_BATTERY_REMAINING", mode: "01", cmd: "5B", description: "Hybrid battery pack remaining life", bytes: 3, decoder: .percent, ecu: ECU.ENGINE, fast: true),
//            generateCommand("OIL_TEMP", mode: "01", cmd: "5C", description: "Engine oil temperature", bytes: 3, decoder: .temp, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_INJECT_TIMING", mode: "01", cmd: "5D", description: "Fuel injection timing", bytes: 4, decoder: .injectTiming, ecu: ECU.ENGINE, fast: true),
//            generateCommand("FUEL_RATE", mode: "01", cmd: "5E", description: "Engine fuel rate", bytes: 4, decoder: .fuelRate, ecu: ECU.ENGINE, fast: true),
//            generateCommand("EMISSION_REQ", mode: "01", cmd: "5F", description: "Designed emission requirements", bytes: 3, decoder: .drop, ecu: ECU.ENGINE, fast: true)
//        ]
//    }
//
//    static var modes: [[OBDCommand]] {
//            return [mode1]
//    }
//
//    static var pidGetters: [OBDCommand] = {
//        var getters: [OBDCommand] = []
//        for mode in modes {
//                for cmd in mode where cmd .decoder == .pid {
//                        getters.append(cmd)
//            }
//        }
//        return getters
//    }()
//
//    // getCommand by name
//
//    static func getCommand(_ name: String) -> OBDCommand? {
//        for mode in modes {
//            for cmd in mode where cmd.name == name {
//                return cmd
//            }
//        }
//        return nil
//    }
// }
