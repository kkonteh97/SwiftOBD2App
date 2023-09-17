//
//  Utils.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation

struct TimedOutError: Error, Equatable {}

public func withTimeout<R>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> R
) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
        defer {
            group.cancelAll()
        }
        
        // Start actual work.
        group.addTask {
            let result = try await operation()
            try Task.checkCancellation()
            return result
        }
        // Start timeout child task.
        group.addTask {
            if seconds > 0 {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
            try Task.checkCancellation()
            // We’ve reached the timeout.
            throw TimedOutError()
        }
        // First finished child task wins, cancel the other task.
        let result = try await group.next()!
        return result
    }
}



enum RESPONSE {
    
    enum ERROR: String {
        
        case QUESTION_MARK = "?",
             ACT_ALERT = "ACT ALERT",
             BUFFER_FULL = "BUFFER FULL",
             BUS_BUSSY = "BUS BUSSY",
             BUS_ERROR = "BUS ERROR",
             CAN_ERROR = "CAN ERROR",
             DATA_ERROR = "DATA ERROR",
             ERRxx = "ERR",
             FB_ERROR = "FB ERROR",
             LP_ALERT = "LP ALERT",
             LV_RESET = "LV RESET",
             NO_DATA = "NO DATA",
             RX_ERROR = "RX ERROR",
             STOPPED = "STOPPED",
             UNABLE_TO_CONNECT = "UNABLE TO CONNECT"
        
        static let asArray: [ERROR] = [QUESTION_MARK, ACT_ALERT, BUFFER_FULL, BUS_BUSSY,
                                       BUS_ERROR, CAN_ERROR, DATA_ERROR, ERRxx, FB_ERROR,
                                       LP_ALERT, LV_RESET, NO_DATA, RX_ERROR,STOPPED,
                                       UNABLE_TO_CONNECT]
    }
}
enum SetupStep: String, CaseIterable, Identifiable {
    case ATD
    case ATZ
    case ATRV
    case ATL0
    case ATE0
    case ATH1
    case ATAT1
    case ATSTFF
    case ATDPN
    case ATSP0
    case ATSP1
    case ATSP2
    case ATSP3
    case ATSP4
    case ATSP5
    case ATSP6
    case ATSP7
    case ATSP8
    case ATSP9
    case ATSPA
    case ATSPB
    case ATSPC
    case AT0902
    var id: String { self.rawValue }
}

enum PROTOCOL: String, Codable {
    case
    AUTO = "0",
    P1 = "1",
    P2 = "2",
    P3 = "3",
    P4 = "4",
    P5 = "5",
    P6 = "6",
    P7 = "7",
    P8 = "8",
    P9 = "9",
    PA = "A",
    PB = "B",
    PC = "C",
    NONE = "None"
    
    var description: String {
        switch self {
        case .AUTO: return "0: Automatic"
        case .P1: return "1: SAE J1850 PWM (41.6 kbaud)"
        case .P2: return "2: SAE J1850 VPW (10.4 kbaud)"
        case .P3: return "3: ISO 9141-2 (5 baud init, 10.4 kbaud)"
        case .P4: return "4: ISO 14230-4 KWP (5 baud init, 10.4 kbaud)"
        case .P5: return "5: ISO 14230-4 KWP (fast init, 10.4 kbaud)"
        case .P6: return "6: ISO 15765-4 CAN (11 bit ID,500 Kbaud)"
        case .P7: return "7: ISO 15765-4 CAN (29 bit ID,500 Kbaud)"
        case .P8: return "8: ISO 15765-4 CAN (11 bit ID,250 Kbaud)"
        case .P9: return "9: ISO 15765-4 CAN (29 bit ID,250 Kbaud)"
        case .PA: return "A: SAE J1939 CAN (11* bit ID, 250* kbaud)"
        case .PB: return "B: USER1 CAN (11* bit ID, 125* kbaud)"
        case .PC: return "C: USER1 CAN (11* bit ID, 50* kbaud)"
        case .NONE: return "None"
        }
    }
    
    var id_bits: Int {
        switch self {
        case .P6, .P8, .PB: return 11
        default: return 29
        }
    }
    
    func nextProtocol() -> PROTOCOL{
        switch self {
        case .PC:
            return .PB
        case .PB:
            return .PA
        case .PA:
            return .P9
        case .P9:
            return .P8
        case .P8:
            return .P7
        case .P7:
            return .P6
        case .P6:
            return .P5
        case .P5:
            return .P4
        case .P4:
            return .P3
        case .P3:
            return .P2
        case .P2:
            return .P1
        case .P1:
            return .AUTO
        default:
            return .NONE
        }
    }
    
    static let asArray: [PROTOCOL] = [AUTO, P1, P2, P3, P4, P5, P6, P7, P8, P9, PA, PB, PC, NONE]


}


enum GET_DTCS_STEP{
    
    //Setup goes in this order
    case
    send_0101,
    send_03,
    finished,
    none
    
    func next() -> GET_DTCS_STEP{
        switch (self) {
            
        case .send_0101: return .send_03
        case .send_03: return .finished
        case .finished: return .none
        case .none: return .none
        }
    }
}//END GET_DTCS_STEP

enum PIDs: String, Codable {
    case pid00 = "00"
    case pid01 = "01"
    case pid02 = "02"
    case pid03 = "03"
    case pid04 = "04"
    case pid05 = "05"
    case pid06 = "06"
    case pid07 = "07"
    case pid08 = "08"
    case pid09 = "09"
    case pid0A = "0A"
    case pid0B = "0B"
    case pid0C = "0C"
    case pid0D = "0D"
    case pid0E = "0E"
    case pid0F = "0F"
    case pid10 = "10"
    case pid11 = "11"
    case pid12 = "12"
    case pid14 = "14"
    case pid15 = "15"
    case pid16 = "16"
    case pid17 = "17"
    case pid18 = "18"
    case pid19 = "19"
    case pid1A = "1A"
    case pid1B = "1B"
    case pid1D = "1D"
    case pid1F = "1F"
    case pid21 = "21"
    case pid22 = "22"
    case pid23 = "23"
    case pid24 = "24"
    case pid25 = "25"
    case pid26 = "26"
    case pid27 = "27"
    case pid28 = "28"
    case pid29 = "29"
    case pid2A = "2A"
    case pid2B = "2B"
    case pid2C = "2C"
    case pid2D = "2D"
    case pid2E = "2E"
    case pid2F = "2F"
    case pid30 = "30"
    case pid31 = "31"
    case pid32 = "32"
    case pid33 = "33"
    case pid34 = "34"
    case pid35 = "35"
    case pid36 = "36"
    case pid37 = "37"
    case pid38 = "38"
    case pid39 = "39"
    case pid3A = "3A"
    case pid3B = "3B"
    case pid3C = "3C"
    case pid3D = "3D"
    case pid3E = "3E"
    case pid3F = "3F"
    case pid40 = "40"
    case pid41 = "41"
    case pid42 = "42"
    case pid43 = "43"
    case pid44 = "44"
    case pid45 = "45"
    case pid46 = "46"
    case pid47 = "47"
    case pid48 = "48"
    case pid49 = "49"
    case pid4A = "4A"
    case pid4B = "4B"
    case pid4C = "4C"
    case pid4D = "4D"
    case pid4E = "4E"
    case pid4F = "4F"
    case pid50 = "50"
    case pid51 = "51"
    case pid52 = "52"
    case pid53 = "53"
    case pid54 = "54"
    case pid55 = "55"
    case pid56 = "56"
    case pid57 = "57"
    case pid58 = "58"
    case pid59 = "59"
    case pid5A = "5A"
    case pid5B = "5B"
    case pid5C = "5C"
    case pid5D = "5D"
    case pid5E = "5E"
    case pid5F = "5F"
    case pid60 = "60"
    case pid61 = "61"
    case pid62 = "62"
    case pid63 = "63"
    case pid64 = "64"
    case pid65 = "65"
    case pid66 = "66"
    case pid67 = "67"
    case pid68 = "68"
    case pid69 = "69"
    case pid6A = "6A"
    case pid6B = "6B"
    case pid6C = "6C"
    case pid6D = "6D"
    case pid6E = "6E"
    case pid6F = "6F"
    case pid70 = "70"
    case pid71 = "71"
    case pid72 = "72"
    case pid73 = "73"
    case pid74 = "74"
    case pid75 = "75"
    case pid76 = "76"
    case pid77 = "77"
    case pid78 = "78"
    case pid79 = "79"
    case pid7A = "7A"
    case pid7B = "7B"
    case pid7C = "7C"
    case None = "none"
    
    func nextPID() -> PIDs{
        switch self {
        case .pid04:
            return .pid05
            
        case .pid05:
            return .pid06
        case .pid06:
            return .pid07
        case .pid07:
            return .pid08
        case .pid08:
            return .pid09
        case .pid09:
            return .pid0A
        case .pid0A:
            return .pid0B
        case .pid0B:
            return .pid0C
        case .pid0C:
            return .pid0D
        case .pid0D:
            return .pid0E
        case .pid0E:
            return .pid0F
        case .pid0F:
            return .pid10
        case .pid10:
            return .pid11
        case .pid11:
            return .pid12
        case .pid12:
            return .pid14
        case .pid14:
            return .pid15
        case .pid15:
            return .pid16
        case .pid16:
            return .pid17
        case .pid17:
            return .pid18
        case .pid18:
            return .pid19
        case .pid19:
            return .pid1A
        case .pid1A:
            return .pid1B
        case .pid1B:
            return .pid1D
        case .pid1D:
            return .pid1F
        case .pid1F:
            return .pid21
        case .pid21:
            return .pid22
        case .pid22:
            return .pid23
        case .pid23:
            return .pid24
        case .pid24:
            return .pid25
        case .pid25:
            return .pid26
        case .pid26:
            return .pid27
        case .pid27:
            return .pid28
        case .pid28:
            return .pid29
        case .pid29:
            return .pid2A
        case .pid2A:
            return .pid2B
        case .pid2B:
            return .None
        case .None:
            return .None
        default:
            return .None
            
        }
    }
    
    
    var descriptions: String {
        switch self {
        case .pid00: return "PIDs supported [01 - 20]"
        case .pid01: return "Monitor status since DTCs cleared."
        case .pid02: return "Freeze DTC"
        case .pid03: return "Fuel system status"
        case .pid04: return "Calculated engine load"
        case .pid05: return "Engine coolant temperature"
        case .pid06: return "Short term fuel trim—Bank 1"
        case .pid07: return "Long term fuel trim—Bank 1"
        case .pid08: return "Short term fuel trim—Bank 2"
        case .pid09: return "Long term fuel trim—Bank 2"
        case .pid0A: return "Fuel pressure (gauge pressure)"
        case .pid0B: return "Intake manifold absolute pressure"
        case .pid0C: return "Engine speed"
        case .pid0D: return "Vehicle speed"
        case .pid0E: return "Timing advance"
        case .pid0F: return "Intake air temperature"
        case .pid10: return "Mass air flow sensor (MAF) air flow rate"
        case .pid11: return "Throttle position"
        case .pid12: return "Commanded secondary air status"
        case .pid14: return "Oxygen Sensor 1\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid15: return "Oxygen Sensor 2\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid16: return "Oxygen Sensor 3\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid17: return "Oxygen Sensor 4\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid18: return "Oxygen Sensor 5\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid19: return "Oxygen Sensor 6\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid1A: return "Oxygen Sensor 7\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid1B: return "Oxygen Sensor 8\n   AB: Voltage\n   B: Short term fuel trim"
        case .pid1D: return "Oxygen sensors present (in 4 banks)"
        case .pid1F: return "Run time since engine start"
        case .pid21: return "Distance traveled with malfunction indicator lamp (MIL) on"
        case .pid22: return "Fuel Rail Pressure (relative to manifold vacuum)"
        case .pid23: return "Fuel Rail Gauge Pressure (diesel, or gasoline direct injection)"
        case .pid24: return "Oxygen Sensor 1 Voltage"
        case .pid25: return "Oxygen Sensor 2 Voltage"
        case .pid26: return "Oxygen Sensor 3 Voltage"
        case .pid27: return "Oxygen Sensor 4 Voltage"
        case .pid28: return "Oxygen Sensor 5 Voltage"
        case .pid29: return "Oxygen Sensor 6 Voltage"
        case .pid2A: return "Oxygen Sensor 7 Voltage"
        case .pid2B: return "Oxygen Sensor 8 Voltage"
        case .pid2C: return "Commanded EGR"
        case .pid2D: return "EGR Error"
        case .pid2E: return "Commanded evaporative purge"
        case .pid2F: return "Fuel Level Input"
        case .pid30: return "Number of warm-ups since codes cleared"
        case .pid31: return "Distance traveled since codes cleared"
        case .pid32: return "Evap. System Vapor Pressure"
        case .pid33: return "Absolute Barometric Pressure"
        case .pid34: return "Oxygen Sensor 1 Current"
        case .pid35: return "Oxygen Sensor 2 Current"
        case .pid36: return "Oxygen Sensor 3 Current"
        case .pid37: return "Oxygen Sensor 4 Current"
        case .pid38: return "Oxygen Sensor 5 Current"
        case .pid39: return "Oxygen Sensor 6 Current"
        case .pid3A: return "Oxygen Sensor 7 Current"
        case .pid3B: return "Oxygen Sensor 8 Current"
        case .pid3C: return "Catalyst Temperature: Bank 1, Sensor 1"
        case .pid3D: return "Catalyst Temperature: Bank 2, Sensor 1"
        case .pid3E: return "Catalyst Temperature: Bank 1, Sensor 2"
        case .pid3F: return "Catalyst Temperature: Bank 2, Sensor 2"
        case .pid40: return "PIDs supported [41 - 60]"
        case .pid41: return "Monitor status this drive cycle"
        case .pid42: return "Control module voltage"
        case .pid43: return "Absolute load value"
        case .pid44: return "Fuel–Air commanded equivalence ratio"
        case .pid45: return "Relative throttle position"
        case .pid46: return "Ambient air temperature"
        case .pid47: return "Absolute throttle position B"
        case .pid48: return "Absolute throttle position C"
        case .pid49: return "Accelerator pedal position D"
        case .pid4A: return "Accelerator pedal position E"
        case .pid4B: return "Accelerator pedal position F"
        case .pid4C: return "Commanded throttle actuator"
        case .pid4D: return "Time run with MIL on"
        case .pid4E: return "Time since trouble codes cleared"
        case .pid4F: return "Maximum value for Fuel–Air equivalence ratio, oxygen sensor voltage, oxygen sensor current, and intake manifold absolute pressure"
        case .pid50: return "Maximum value for air flow rate from mass air flow sensor"
        case .pid51: return "Fuel Type"
        case .pid52: return "Ethanol fuel %"
        case .pid53: return "Absolute Evap system Vapor Pressure"
        case .pid54: return "Evap system vapor pressure"
        case .pid55: return "Short term secondary oxygen sensor trim, A: bank 1, B: bank 3"
        case .pid56: return "Long term secondary oxygen sensor trim, A: bank 1, B: bank 3"
        case .pid57: return "Short term secondary oxygen sensor trim, A: bank 2, B: bank 4"
        case .pid58: return "Long term secondary oxygen sensor trim, A: bank 2, B: bank 4"
        case .pid59: return "Fuel rail absolute pressure"
        case .pid5A: return "Relative accelerator pedal position"
        case .pid5B: return "Hybrid battery pack remaining life"
        case .pid5C: return "Engine oil temperature"
        case .pid5D: return "Fuel injection timing"
        case .pid5E: return "Engine fuel rate"
        case .pid5F: return "Emission requirements to which vehicle is designed"
        case .pid60: return "PIDs supported [61 - 80]"
        case .pid61: return "Driver's demand engine - percent torque"
        case .pid62: return "Actual engine - percent torque"
        case .pid63: return "Engine reference torque"
        case .pid64: return "Engine percent torque data"
        case .pid65: return "Auxiliary input / output supported"
        case .pid66: return "Mass air flow sensor"
        case .pid67: return "Engine coolant temperature"
        case .pid68: return "Intake air temperature sensor"
        case .pid69: return "Commanded EGR and EGR Error"
        case .pid6A: return "Commanded Diesel intake air flow control and relative intake air flow position"
        case .pid6B: return "Exhaust gas recirculation temperature"
        case .pid6C: return "Commanded throttle actuator control and relative throttle position"
        case .pid6D: return "Fuel pressure control system"
        case .pid6E: return "Injection pressure control system"
        case .pid6F: return "Turbocharger compressor inlet pressure"
        case .pid70: return "Boost pressure control"
        case .pid71: return "Variable Geometry turbo (VGT) control"
        case .pid72: return "Wastegate control"
        case .pid73: return "Exhaust pressure"
        case .pid74: return "Turbocharger RPM"
        case .pid75: return "Turbocharger temperature"
        case .pid76: return "Turbocharger temperature"
        case .pid77: return "Charge air cooler temperature (CACT)"
        case .pid78: return "Exhaust Gas temperature (EGT) Bank 1"
        case .pid79: return "Exhaust Gas temperature (EGT) Bank 2"
        case .pid7A: return "Diesel particulate filter (DPF)"
        case .pid7B: return "Diesel particulate filter (DPF)"
        case .pid7C: return "Diesel Particulate filter (DPF) temperature"
        case .None:
            return ""
        }
    }
}



