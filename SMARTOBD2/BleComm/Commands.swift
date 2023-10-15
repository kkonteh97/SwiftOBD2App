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
    case airStatus
    case O2Sensor
    case O2Bank1Sensor1
    case O2Bank1Sensor2
    case O2Bank1Sensor3
    case O2Bank1Sensor4
    case O2Bank2Sensor1
    case O2Bank2Sensor2
    case O2Bank2Sensor3
    case O2Bank2Sensor4
    case obdcompliance
    case O2SensorsALT
    case auxInputStatus
    case runTime
    case pidsB
    case distanceWMIL
    case fuelRailPressureVac
    case fuelRailPressureDirect
    case O2Sensor1WRVolatage
    case O2Sensor2WRVolatage
    case O2Sensor3WRVolatage
    case O2Sensor4WRVolatage
    case O2Sensor5WRVolatage
    case O2Sensor6WRVolatage
    case O2Sensor7WRVolatage
    case O2Sensor8WRVolatage
    case commandedEGR
    case EGRError
    case evaporativePurge
    case fuelLevel
    case warmUpsSinceDTCCleared
    case distanceSinceDTCCleared
    case evapVaporPressure
    case barometricPressure
    case O2Sensor1WRCurrent
    case O2Sensor2WRCurrent
    case O2Sensor3WRCurrent
    case O2Sensor4WRCurrent
    case O2Sensor5WRCurrent
    case O2Sensor6WRCurrent
    case O2Sensor7WRCurrent
    case O2Sensor8WRCurrent
    case catalystTempB1S1
    case catalystTempB2S1
    case catalystTempB1S2
    case catalystTempB2S2
    case pidsC

    var command: String {
        switch self {
        case .pidsA:                    return "00"
        case .status:                   return "01"
        case .freezeDTC:                return "02"
        case .fuelStatus:               return "03"
        case .engineLoad:               return "04"
        case .coolantTemp:              return "05"
        case .shortFuelTrim1:           return "06"
        case .longFuelTrim1:            return "07"
        case .shortFuelTrim2:           return "08"
        case .longFuelTrim2:            return "09"
        case .fuelPressure:             return "0A"
        case .intakePressure:           return "0B"
        case .rpm:                      return "0C"
        case .speed:                    return "0D"
        case .timingAdvance:            return "0E"
        case .intakeTemp:               return "0F"
        case .maf:                      return "10"
        case .throttlePos:              return "11"
        case .airStatus:                return "12"
        case .O2Sensor:                 return "13"
        case .O2Bank1Sensor1:           return "14"
        case .O2Bank1Sensor2:           return "15"
        case .O2Bank1Sensor3:           return "16"
        case .O2Bank1Sensor4:           return "17"
        case .O2Bank2Sensor1:           return "18"
        case .O2Bank2Sensor2:           return "19"
        case .O2Bank2Sensor3:           return "1A"
        case .O2Bank2Sensor4:           return "1B"
        case .obdcompliance:            return "1C"
        case .O2SensorsALT:             return "1D"
        case .auxInputStatus:           return "1E"
        case .runTime:                  return "1F"
        case .pidsB:                    return "20"
        case .distanceWMIL:             return "21"
        case .fuelRailPressureVac:      return "22"
        case .fuelRailPressureDirect:   return "23"
        case .O2Sensor1WRVolatage:      return "24"
        case .O2Sensor2WRVolatage:      return "25"
        case .O2Sensor3WRVolatage:      return "26"
        case .O2Sensor4WRVolatage:      return "27"
        case .O2Sensor5WRVolatage:      return "28"
        case .O2Sensor6WRVolatage:      return "29"
        case .O2Sensor7WRVolatage:      return "2A"
        case .O2Sensor8WRVolatage:      return "2B"
        case .commandedEGR:             return "2C"
        case .EGRError:                 return "2D"
        case .evaporativePurge:         return "2E"
        case .fuelLevel:                return "2F"
        case .warmUpsSinceDTCCleared:   return "30"
        case .distanceSinceDTCCleared:  return "31"
        case .evapVaporPressure:        return "32"
        case .barometricPressure:       return "33"
        case .O2Sensor1WRCurrent:       return "34"
        case .O2Sensor2WRCurrent:       return "35"
        case .O2Sensor3WRCurrent:       return "36"
        case .O2Sensor4WRCurrent:       return "37"
        case .O2Sensor5WRCurrent:       return "38"
        case .O2Sensor6WRCurrent:       return "39"
        case .O2Sensor7WRCurrent:       return "3A"
        case .O2Sensor8WRCurrent:       return "3B"
        case .catalystTempB1S1:         return "3C"
        case .catalystTempB2S1:         return "3D"
        case .catalystTempB1S2:         return "3E"
        case .catalystTempB2S2:         return "3F"
        case .pidsC:                    return "40"
        }
    }

    var id: UUID { UUID() }

    var description: String {
        switch self {
        case .pidsA:                    return "Supported PIDs [01-20]"
        case .status:                   return "Status since DTCs cleared"
        case .freezeDTC:                return "DTC that triggered the freeze frame"
        case .fuelStatus:               return "Fuel System Status"
        case .engineLoad:               return "Calculated Engine Load"
        case .coolantTemp:              return "Coolant temperature"
        case .shortFuelTrim1:           return "Short Term Fuel Trim - Bank 1"
        case .longFuelTrim1:            return "Long Term Fuel Trim - Bank 1"
        case .shortFuelTrim2:           return "Short Term Fuel Trim - Bank 2"
        case .longFuelTrim2:            return "Long Term Fuel Trim - Bank 2"
        case .fuelPressure:             return "Fuel Pressure"
        case .intakePressure:           return "Intake Manifold Pressure"
        case .speed:                    return "Vehicle Speed"
        case .rpm:                      return "RPM"
        case .timingAdvance:            return "Timing Advance"
        case .intakeTemp:               return "Intake Air Temp"
        case .maf:                      return "Air Flow Rate (MAF)"
        case .throttlePos:              return "Throttle Position"
        case .airStatus:                return "Secondary Air Status"
        case .O2Sensor:                 return "O2 Sensors Present"
        case .O2Bank1Sensor1:           return "O2: Bank 1 - Sensor 1 Voltage"
        case .O2Bank1Sensor2:           return "O2: Bank 1 - Sensor 2 Voltage"
        case .O2Bank1Sensor3:           return "O2: Bank 1 - Sensor 3 Voltage"
        case .O2Bank1Sensor4:           return "O2: Bank 1 - Sensor 4 Voltage"
        case .O2Bank2Sensor1:           return "O2: Bank 2 - Sensor 1 Voltage"
        case .O2Bank2Sensor2:           return "O2: Bank 2 - Sensor 2 Voltage"
        case .O2Bank2Sensor3:           return "O2: Bank 2 - Sensor 3 Voltage"
        case .O2Bank2Sensor4:           return "O2: Bank 2 - Sensor 4 Voltage"
        case .obdcompliance:            return "OBD Standards Compliance"
        case .O2SensorsALT:             return "O2 Sensors Present (alternate)"
        case .auxInputStatus:           return "Auxiliary input status (power take off)"
        case .runTime:                  return "Engine Run Time"
        case .pidsB:                    return "Supported PIDs [21-40]"
        case .distanceWMIL:             return "Distance Traveled with MIL on"
        case .fuelRailPressureVac:      return "Fuel Rail Pressure (relative to vacuum)"
        case .fuelRailPressureDirect:   return "Fuel Rail Pressure (direct inject)"
        case .O2Sensor1WRVolatage:      return "02 Sensor 1 WR Lambda Voltage"
        case .O2Sensor2WRVolatage:      return "02 Sensor 2 WR Lambda Voltage"
        case .O2Sensor3WRVolatage:      return "02 Sensor 3 WR Lambda Voltage"
        case .O2Sensor4WRVolatage:      return "02 Sensor 4 WR Lambda Voltage"
        case .O2Sensor5WRVolatage:      return "02 Sensor 5 WR Lambda Voltage"
        case .O2Sensor6WRVolatage:      return "02 Sensor 6 WR Lambda Voltage"
        case .O2Sensor7WRVolatage:      return "02 Sensor 7 WR Lambda Voltage"
        case .O2Sensor8WRVolatage:      return "02 Sensor 8 WR Lambda Voltage"
        case .commandedEGR:             return "Commanded EGR"
        case .EGRError:                 return "EGR Error"
        case .evaporativePurge:         return "Commanded Evaporative Purge"
        case .fuelLevel:                return "Number of warm-ups since codes cleared"
        case .warmUpsSinceDTCCleared:   return "Distance traveled since codes cleared"
        case .distanceSinceDTCCleared:  return "Distance traveled since codes cleared"
        case .evapVaporPressure:        return "Evaporative system vapor pressure"
        case .barometricPressure:       return "Barometric Pressure"
        case .O2Sensor1WRCurrent:       return "02 Sensor 1 WR Lambda Current"
        case .O2Sensor2WRCurrent:       return "02 Sensor 2 WR Lambda Current"
        case .O2Sensor3WRCurrent:       return "02 Sensor 3 WR Lambda Current"
        case .O2Sensor4WRCurrent:       return "02 Sensor 4 WR Lambda Current"
        case .O2Sensor5WRCurrent:       return "02 Sensor 5 WR Lambda Current"
        case .O2Sensor6WRCurrent:       return "02 Sensor 6 WR Lambda Current"
        case .O2Sensor7WRCurrent:       return "02 Sensor 7 WR Lambda Current"
        case .O2Sensor8WRCurrent:       return "02 Sensor 8 WR Lambda Current"
        case .catalystTempB1S1:         return "Catalyst Temperature: Bank 1 - Sensor 1"
        case .catalystTempB2S1:         return "Catalyst Temperature: Bank 2 - Sensor 1"
        case .catalystTempB1S2:         return "Catalyst Temperature: Bank 1 - Sensor 2"
        case .catalystTempB2S2:         return "Catalyst Temperature: Bank 1 - Sensor 2"
        case .pidsC:                    return "Supported PIDs [41-60]"
        }
    }

    var bytes: Int {
        switch self {
        case .pidsA:                    return 5
        case .status:                   return 5
        case .freezeDTC:                return 5
        case .fuelStatus:               return 5
        case .engineLoad:               return 2
        case .coolantTemp:              return 2
        case .shortFuelTrim1:           return 3
        case .longFuelTrim1:            return 3
        case .shortFuelTrim2:           return 3
        case .longFuelTrim2:            return 3
        case .fuelPressure:             return 2
        case .intakePressure:           return 3
        case .rpm:                      return 4
        case .speed:                    return 2
        case .timingAdvance:            return 3
        case .intakeTemp:               return 2
        case .maf:                      return 3
        case .throttlePos:              return 2
        case .airStatus:                return 2
        case .O2Sensor:                 return 2
        case .O2Bank1Sensor1:           return 2
        case .O2Bank1Sensor2:           return 2
        case .O2Bank1Sensor3:           return 2
        case .O2Bank1Sensor4:           return 2
        case .O2Bank2Sensor1:           return 2
        case .O2Bank2Sensor2:           return 2
        case .O2Bank2Sensor3:           return 2
        case .O2Bank2Sensor4:           return 2
        case .obdcompliance:            return 2
        case .O2SensorsALT:             return 2
        case .auxInputStatus:           return 2
        case .runTime:                  return 2
        case .pidsB:                    return 5
        case .distanceWMIL:             return 4
        case .fuelRailPressureVac:      return 4
        case .fuelRailPressureDirect:   return 4
        case .O2Sensor1WRVolatage:      return 6
        case .O2Sensor2WRVolatage:      return 6
        case .O2Sensor3WRVolatage:      return 6
        case .O2Sensor4WRVolatage:      return 6
        case .O2Sensor5WRVolatage:      return 6
        case .O2Sensor6WRVolatage:      return 6
        case .O2Sensor7WRVolatage:      return 6
        case .O2Sensor8WRVolatage:      return 6
        case .commandedEGR:             return 4
        case .EGRError:                 return 4
        case .evaporativePurge:         return 4
        case .fuelLevel:                return 4
        case .warmUpsSinceDTCCleared:   return 4
        case .distanceSinceDTCCleared:  return 4
        case .evapVaporPressure:        return 4
        case .barometricPressure:       return 4
        case .O2Sensor1WRCurrent:       return 4
        case .O2Sensor2WRCurrent:       return 4
        case .O2Sensor3WRCurrent:       return 4
        case .O2Sensor4WRCurrent:       return 4
        case .O2Sensor5WRCurrent:       return 4
        case .O2Sensor6WRCurrent:       return 4
        case .O2Sensor7WRCurrent:       return 4
        case .O2Sensor8WRCurrent:       return 4
        case .catalystTempB1S1:         return 4
        case .catalystTempB2S1:         return 4
        case .catalystTempB1S2:         return 4
        case .catalystTempB2S2:         return 4
        case .pidsC:                    return 6
        }
    }

    var decoder: Decoder {
        switch self {
        case .pidsA:                    return .pid
        case .status:                   return .status
        case .freezeDTC:                return .singleDTC
        case .fuelStatus:               return .fuelStatus
        case .engineLoad:               return .percent
        case .coolantTemp:              return .temp
        case .shortFuelTrim1:           return .percentCentered
        case .longFuelTrim1:            return .percentCentered
        case .shortFuelTrim2:           return .percentCentered
        case .longFuelTrim2:            return .percentCentered
        case .fuelPressure:             return .fuelPressure
        case .intakePressure:           return .pressure
        case .rpm:                      return .uas0x07
        case .speed:                    return .uas0x09
        case .timingAdvance:            return .timingAdvance
        case .intakeTemp:               return .temp
        case .maf:                      return .uas0x27
        case .throttlePos:              return .percent
        case .airStatus:                return .airStatus
        case .O2Sensor:                 return .o2Sensors
        case .O2Bank1Sensor1:           return .sensorVoltage
        case .O2Bank1Sensor2:           return .sensorVoltage
        case .O2Bank1Sensor3:           return .sensorVoltage
        case .O2Bank1Sensor4:           return .sensorVoltage
        case .O2Bank2Sensor1:           return .sensorVoltage
        case .O2Bank2Sensor2:           return .sensorVoltage
        case .O2Bank2Sensor3:           return .sensorVoltage
        case .O2Bank2Sensor4:           return .sensorVoltage
        case .obdcompliance:            return .obdCompliance
        case .O2SensorsALT:             return .o2SensorsAlt
        case .auxInputStatus:           return .auxInputStatus
        case .runTime:                  return .uas0x12
        case .pidsB:                    return .pid
        case .distanceWMIL:             return .uas0x25
        case .fuelRailPressureVac:      return .uas0x19
        case .fuelRailPressureDirect:   return .uas0x1B
        case .O2Sensor1WRVolatage:      return .sensorVoltageBig
        case .O2Sensor2WRVolatage:      return .sensorVoltageBig
        case .O2Sensor3WRVolatage:      return .sensorVoltageBig
        case .O2Sensor4WRVolatage:      return .sensorVoltageBig
        case .O2Sensor5WRVolatage:      return .sensorVoltageBig
        case .O2Sensor6WRVolatage:      return .sensorVoltageBig
        case .O2Sensor7WRVolatage:      return .sensorVoltageBig
        case .O2Sensor8WRVolatage:      return .sensorVoltageBig
        case .commandedEGR:             return .percent
        case .EGRError:                 return .percentCentered
        case .evaporativePurge:         return .percent
        case .fuelLevel:                return .percent
        case .warmUpsSinceDTCCleared:   return .uas0x01
        case .distanceSinceDTCCleared:  return .uas0x25
        case .evapVaporPressure:        return .evapPressure
        case .barometricPressure:       return .pressure
        case .O2Sensor1WRCurrent:       return .currentCentered
        case .O2Sensor2WRCurrent:       return .currentCentered
        case .O2Sensor3WRCurrent:       return .currentCentered
        case .O2Sensor4WRCurrent:       return .currentCentered
        case .O2Sensor5WRCurrent:       return .currentCentered
        case .O2Sensor6WRCurrent:       return .currentCentered
        case .O2Sensor7WRCurrent:       return .currentCentered
        case .O2Sensor8WRCurrent:       return .currentCentered
        case .catalystTempB1S1:         return .uas0x16
        case .catalystTempB2S1:         return .uas0x16
        case .catalystTempB1S2:         return .uas0x16
        case .catalystTempB2S2:         return .uas0x16
        case .pidsC:                    return .pid
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
