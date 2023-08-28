//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth


enum SetupStep: String, CaseIterable, Identifiable {
    case ATD
    case ATZ
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
    var id: String { self.rawValue }
}

enum PROTOCOL: String {
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
    
    case
    P0 = "0",
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
    
    static let asArray: [PROTOCOL] = [P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, PA, PB, PC, NONE]
    
    var description: String {
        switch self {
        case .P0: return "0: Automatic"
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
            return .P0
        default:
            return .NONE
        }
    }
}

protocol ElmManager {
    // Define the methods and properties required by your elm327
    func sendMessageAsync(_ message: String) async throws -> String
    func setupAdapter(setupOrder: [SetupStep]) async throws
}

class ELM327: ObservableObject, ElmManager {
    // MARK: - Properties

    
    // Bluetooth UUIDs
    var BLE_ELM_SERVICE_UUID = CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)
    var BLE_ELM_CHARACTERISTIC_UUID = CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID)
    
    // Bluetooth manager
    let bleManager: BLEManaging

    
    // OBD protocol
    var obdProtocol: PROTOCOL = .NONE
    
    // MARK: - Initialization
    
    init(bleManager: BLEManaging) {
        self.bleManager = bleManager
    }
    
    // MARK: - Message Sending
    
    // Send a message asynchronously
    func sendMessageAsync(_ message: String) async throws -> String {
        return try await bleManager.sendMessageAsync(message)
    }
    
    // MARK: - Setup Steps
    
    // Possible setup errors
    enum SetupError: Error {
        case invalidResponse
    }
    
    func okResponse(message: String) async throws -> String {
        /*
        Handle responses with ok
        Commands thats only respond with ok are processed here
         */
        let response = try await bleManager.sendMessageAsync(message)
        if response.contains("OK") {
            return response
        } else {
            throw SetupError.invalidResponse
        }
    }
    
    func setupAdapter(setupOrder: [SetupStep]) async throws {
        /*
         Perform the setup process

         */
        var setupOrderCopy = setupOrder
        var currentIndex = 0
        
        while currentIndex < setupOrderCopy.count {
            let step = setupOrderCopy[currentIndex]
            do {
                switch step {
                case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF:
                    _ = try await okResponse(message: step.rawValue)
                    
                case .ATZ:
                    _ = try await sendMessageAsync("ATZ")                      // reset command Responds Device Info
                    
                case .ATDPN:
                    let currentProtocol = try await sendMessageAsync("ATDPN") // Describe current protocol number
                    obdProtocol = PROTOCOL(rawValue: currentProtocol) ?? .P0
                    
                    if let setupStep = SetupStep(rawValue: "ATSP\(currentProtocol)") {
                        setupOrderCopy.append(setupStep)                                // append current protocol to setupOrderCopy
                    }
                    
                case .ATSP0, .ATSP1, .ATSP2, .ATSP3, .ATSP4, .ATSP5, .ATSP6, .ATSP7, .ATSP8, .ATSP9, .ATSPA, .ATSPB, .ATSPC:
                    do {
                        _ = try await okResponse(message: step.rawValue)
                        try await testProtocol()                                        // test the protocol
                                                                                        // we in this
                        print("Setup Completed successfulleh")
                        break
                    } catch {
                        obdProtocol = obdProtocol.nextProtocol()
                        print("well that didn't work lets try \(obdProtocol.description)")
                        if let setupStep = SetupStep(rawValue: "ATSP\(obdProtocol.rawValue)") {
                            setupOrderCopy.append(setupStep)                            // append next protocol fi setupOrderCopy
                        }
                    }
                }
                print("Completed step: \(step)")
            } catch {
                throw error
            }
            currentIndex += 1
        }
    }
    
    // MARK: - Protocol Testing
    
    func testProtocol() async throws {
        do {
            // test protocol by sending 0100 and checking for 41 00 response
            /*
             while we here might as well get the supported pids
             */
            print("Testing protocol: \(obdProtocol.rawValue)")
            
            let response = try await sendMessageAsync("0100")
            guard response.contains("41 00") else {
                throw SetupError.invalidResponse
            }
            
            let response2 = try await sendMessageAsync("0100")
            if !response2.contains("41 00") {
                throw SetupError.invalidResponse
            }
            
        } catch {
            throw error
        }
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
    

    
    
    
    enum QUERY: String {
        case
        Q_ATD = "ATD",
        Q_ATZ = "ATZ",
        Q_ATE0 = "ATE0",
        Q_ATH0 = "ATH",
        Q_ATH1 = "ATH1",
        Q_ATDPN = "ATDPN",
        Q_ATSPC = "ATSPC",
        Q_ATSPB = "ATSPB",
        Q_ATSPA = "ATSPA",
        Q_ATSP9 = "ATSP9",
        Q_ATSP8 = "ATSP8",
        Q_ATSP7 = "ATSP7",
        Q_ATSP6 = "ATSP6",
        Q_ATSP5 = "ATSP5",
        Q_ATSP4 = "ATSP4",
        Q_ATSP3 = "ATSP3",
        Q_ATSP2 = "ATSP2",
        Q_ATSP1 = "ATSP1",
        Q_ATSP0 = "ATSP0",
        Q_0100 = "0100",
        Q_0101 = "0101",
        Q_0902 = "0902",
        Q_03 = "03",
        Q_07 = "07",

        NONE = "None"
        
        static let asArray: [QUERY] = [Q_ATD, Q_ATZ, Q_ATE0,Q_ATH0,
                                       Q_ATH1, Q_ATDPN, Q_ATSPC,Q_ATSPB,
                                       Q_ATSPA,Q_ATSP9, Q_ATSP8,Q_ATSP7,
                                       Q_ATSP6,Q_ATSP5, Q_ATSP4,Q_ATSP3,
                                       Q_ATSP2,Q_ATSP1, Q_ATSP0,Q_0100,
                                       Q_0101 ,Q_0902, Q_03, Q_07, NONE]
        
                                       
                                       
        
        enum SETUP_STEP: String{
            
            case
            send_ATD =  "ATD",
            send_ATZ =  "ATZ",
            send_ATE1 =  "ATE0",
            send_ATH0 =  "ATH0",
            send_ATH1 =  "ATH1",
            send_ATDPN =  "ATDPN",
            send_ATSPC =  "ATSPC",
            send_ATSPB =  "ATSPB",
            send_ATSPA =  "ATSPA",
            send_ATSP9 =  "ATSP9",
            send_ATSP8 =  "ATSP8",
            send_ATSP7 =  "ATSP7",
            send_ATSP6 =  "ATSP6",
            send_ATSP5 =  "ATSP5",
            send_ATSP4 =  "ATSP4",
            send_ATSP3 =  "ATSP3",
            send_ATSP2 =  "ATSP2",
            send_ATSP1 =  "ATSP1",
            send_ATSP0 =  "ATSP0",
            send_0902 =  "0902",
            send_ATL0 =  "ATL0",
            send_ATAT1 =  "ATAT1",
            send_ATSTFF =  "ATSTFF",
            send_ATCRA =  "ATCRA",
            test_SELECTED_PROTOCOL_1,
            test_SELECTED_PROTOCOL_2,
            test_SELECTED_PROTOCOL_FINISHED,
            finished,
            none
            /* currently getting response from 2 ecus, 10 is engine control
              other is transmission, not standard
             can filter out ecu 10 with AT CRA <Header>10
             ATH1 save value of 0100 command
             ATH0 save value of 0100 command diff is the header..
            lets do it!!
            */
            func next() -> SETUP_STEP{
                switch (self) {
                    
                case .send_ATD: return .send_ATZ
                case .send_ATZ: return .send_ATL0
                case .send_ATL0 : return .send_ATE1
                case .send_ATE1: return .send_ATH1
                case .send_ATH1: return .send_ATAT1
                case .send_ATAT1: return .send_ATSTFF
                case .send_ATSTFF: return .send_ATDPN
                case .send_ATDPN: return .send_ATSPC
                case .send_ATSPC, .send_ATSPB, .send_ATSPA, .send_ATSP9, .send_ATSP8, .send_ATSP7,.send_ATSP6, .send_ATSP5, .send_ATSP4, .send_ATSP3, .send_ATSP2, .send_ATSP1, .send_ATSP0: return .test_SELECTED_PROTOCOL_1
                case .finished: return .none
                case .test_SELECTED_PROTOCOL_1: return .send_ATCRA
                case .send_ATCRA: return .send_ATH0
                case .send_ATH0: return .test_SELECTED_PROTOCOL_2
                case .test_SELECTED_PROTOCOL_2: return .send_0902
                case .send_0902: return .test_SELECTED_PROTOCOL_FINISHED
                case .test_SELECTED_PROTOCOL_FINISHED: return .test_SELECTED_PROTOCOL_FINISHED
                case .none: return .none
                }
            }
        }//END SETUP_STEP
        
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
    }//END QUERY
    
    enum PIDs: String {
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
            }
        }

        
        var description: String {
            switch self {
            case .pid04:
                return "Calculated engine load"
            case .pid05:
                return "Engine coolant temperature"
            case .pid06:
                return "Short term fuel trim—Bank 1"
            case .pid07:
                return "Long term fuel trim—Bank 1"
            case .pid08:
                return "Short term fuel trim—Bank 2"
            case .pid09:
                return "Long term fuel trim—Bank 2"
            case .pid0A:
                return "Fuel pressure (gauge pressure)"
            case .pid0B:
                return "Intake manifold absolute pressure"
            case .pid0C:
                return "Engine speed"
            case .pid0D:
                return "Vehicle speed"
            case .pid0E:
                return "Timing advance"
            case .pid0F:
                return "Intake air temperature"
            case .pid10:
                return "Mass air flow sensor (MAF) air flow rate"
            case .pid11:
                return "Throttle position"
            case .pid12:
                return "Commanded secondary air status"
            case .pid14:
                return "Oxygen Sensor 1\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid15:
                return "Oxygen Sensor 2\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid16:
                return "Oxygen Sensor 3\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid17:
                return "Oxygen Sensor 4\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid18:
                return "Oxygen Sensor 5\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid19:
                return "Oxygen Sensor 6\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid1A:
                return "Oxygen Sensor 7\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid1B:
                return "Oxygen Sensor 8\n   AB: Voltage\n   B: Short term fuel trim"
            case .pid1D:
                return "Oxygen sensors present (in 4 banks)"
            case .pid1F:
                return "Run time since engine start"
            case .pid21:
                return "Distance traveled with malfunction indicator lamp (MIL) on"
            case .pid22:
                return "Fuel Rail Pressure (relative to manifold vacuum)"
            case .pid23:
                return "Fuel Rail Gauge Pressure (diesel, or gasoline direct injection)"
            case .pid24:
                return "Oxygen Sensor 1 Voltage"
            case .pid25:
                return "Oxygen Sensor 2 Voltage"
            case .pid26:
                return "Oxygen Sensor 3 Voltage"
            case .pid27:
                return "Oxygen Sensor 4 Voltage"
            case .pid28:
                return "Oxygen Sensor 5 Voltage"
            case .pid29:
                return "Oxygen Sensor 6 Voltage"
            case .pid2A:
                return "Oxygen Sensor 7 Voltage"
            case .pid2B:
                return "Oxygen Sensor 8 Voltage"
            
            case .None:
                return ""
            }
        }
    }
