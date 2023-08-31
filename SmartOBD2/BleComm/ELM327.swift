//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth

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
    case AT0100
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
    func sendMessageAsync(_ message: String,  withTimeoutSecs: Int) async throws -> String
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
    
    // VIN Number
    var vinNumber = ""
    
    // ECU's Found
    @Published var ecuFound: [[String]] = []

    
    // MARK: - Initialization
    
    init(bleManager: BLEManaging) {
        self.bleManager = bleManager
    }
    
    // MARK: - Message Sending
    
    enum ResultEnum {
        case success(String)
        case failed(SetupError)
    }
    
    // Send a message asynchronously
    func sendMessageAsync(_ message: String, withTimeoutSecs: Int = 5) async throws -> String  {
        do {
            let response: String = try await withTimeout(seconds: 0.5) { [self] in
                let res = try await bleManager.sendMessageAsync(message, withTimeoutSecs: withTimeoutSecs)
                return res
            }
            return response
        } catch {
            print("Error: \(error)")
            throw error // Re-throw the error to the caller if needed
        }
    }
    
    
    // MARK: - Setup Steps
    
    // Possible setup errors
    enum SetupError: Error {
        case invalidResponse
        case timeout
    }
    
    func okResponse(message: String) async throws -> String {
        /*
         Handle responses with ok
         Commands thats only respond with ok are processed here
         */
        let response = try await bleManager.sendMessageAsync(message, withTimeoutSecs: 1)
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
                    _ = try await sendMessageAsync("ATZ")                               // reset command Responds with Device Info
                case .ATRV:
                    _ = try await sendMessageAsync("ATRV")                              // get the voltage
                    
                case .ATDPN:
                    let currentProtocol = try await sendMessageAsync("ATDPN")           // Describe current protocol number
                    obdProtocol = PROTOCOL(rawValue: currentProtocol) ?? .P0
                    
                    if let setupStep = SetupStep(rawValue: "ATSP\(currentProtocol)") {
                        setupOrderCopy.append(setupStep)                                // append current protocol to setupOrderCopy
                    }
                    
                case .ATSP0, .ATSP1, .ATSP2, .ATSP3, .ATSP4, .ATSP5, .ATSP6, .ATSP7, .ATSP8, .ATSP9, .ATSPA, .ATSPB, .ATSPC:
                    do {
                        try await testProtocol(step: step)                              // test the protocol
                        // we in this
                        if let setupStep = SetupStep(rawValue: "AT0100") {
                            setupOrderCopy.append(setupStep)
                        }
                        print("Setup Completed successfulleh")
                    } catch {
                        obdProtocol = obdProtocol.nextProtocol()
                        print("well that didn't work lets try \(obdProtocol.description)")
                        if obdProtocol == .NONE {
                            throw error
                        }
                        if let setupStep = SetupStep(rawValue: "ATSP\(obdProtocol.rawValue)") {
                            setupOrderCopy.append(setupStep)                            // append next protocol fi setupOrderCopy
                        }
                    }
                case .AT0100:
                    do {
                        let vinResponse = try await sendMessageAsync("0902")             // Try to get VIN
                        vinNumber = try await decodeVIN(response: vinResponse)
                        do {
                            let vinInfo = try await getVINInfo(vin: vinNumber)
                            print(vinInfo)
                            
                        } catch {
                            print(error)
                        }
                    } catch {
                        throw error
                    }
                }
            
                print("Completed step: \(step)")
                
            } catch {
                throw error
            }
            currentIndex += 1
        }
        // Setup Complete will attempt to get the VIN Number
    }
    
    // MARK: - Protocol Testing
    
    func testProtocol(step: SetupStep) async throws {
        do {
            // test protocol by sending 0100 and checking for 41 00 response
            /*
             while we here might as well get the supported pids
             */
            _ = try await okResponse(message: step.rawValue)
            print("Testing protocol: \(obdProtocol.rawValue)")
            
            // send 0100 message two times just to make sure first might contain "searching"
            let _ = try await sendMessageAsync("0100")
            let response2 = try await sendMessageAsync("0100")
 
            await getECUs(response: response2)
            // Turn header off now
            _ = try await okResponse(message: "ATH0")
        } catch {
            throw error
        }
    }
    
    func getECUs(response: String) async {
        // Find the indices of "41 00" in the response
        let ecuSegments = response.components(separatedBy: " ")

        var indicesOf41: [Int] = []
        for (index, segment) in ecuSegments.enumerated() {
            if segment == "41" && index + 1 < ecuSegments.count && ecuSegments[index + 1] == "00" {
                indicesOf41.append(index)
            }
        }
        
        // Extract headers for each "41 00" response
        for indexOf41 in indicesOf41 {
            // Determine the start and end of the header based on the context
            let headerStartIndex = max(indexOf41 - 5, 0) // Adjust the backward window size as needed
            let headerEndIndex = indexOf41

            // Extract the header segments
            let header = Array(ecuSegments[headerStartIndex..<headerEndIndex - 1])
            await getSupportedPIDs(header: header)
            // get supported pids
            await MainActor.run {
                self.ecuFound.append(header)
            }
            print(ecuFound)
        }
    }
    
    func getSupportedPIDs(header: [String]) async  {
        do {
            _ = try await okResponse(message: "AT CRA\(header.joined())")

            let response = try await sendMessageAsync("0100").components(separatedBy: " ")
            print(response)
            
            let indexof41 = response.firstIndex(of: "41") ?? response.endIndex
            let startIndex = response.index(indexof41, offsetBy: 2, limitedBy: response.endIndex) ?? response.endIndex
            // filter 55 out
            let bytes = response[startIndex...]
                .filter { $0 != "55" }
                .compactMap { UInt8(String($0), radix: 16) }
            
            print(bytes)
            
            // Convert each byte to binary and join them together
            let binaryData = bytes.flatMap { Array(String($0, radix: 2).leftPadding(toLength: 8, withPad: "0")) }
            
            // Define the PID numbers based on the binary data
            let supportedPIDs = binaryData.enumerated()
                .compactMap { index, bit -> String? in
                    if bit == "1" {
                        let pidNumber = String(format: "%02X", index + 1)
                        return pidNumber
                    }
                    return nil
                    
                }
            
            let _ = supportedPIDs.map { pid in
                PIDs(rawValue: pid)
            }
            
            
            //        // remove nils
            //        self.supportedPIDsByECU = supportedPIDsByECU
            //                                    .map { $0 }
            //                                    .compactMap { $0 }
            //
            //        self.pidDescriptions = supportedPIDsByECU
            //                                    .map { $0?.description }
            //                                    .compactMap { $0 }
            
        } catch {
        }
    }
    
    // MARK: - Decoding VIN
    
    func decodeVIN(response: String) async throws -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            print("Prefix not found in the response")
            throw SetupError.invalidResponse
        }
        // Extract the VIN hex string after "49 02"
        let vinHexString = response[prefixIndex...]
            .split(separator: " ")
            .joined() // Remove spaces
        
        // Convert the hex string to ASCII characters
        var asciiString = ""
        var hex = vinHexString
        while !hex.isEmpty {
            let startIndex = hex.startIndex
            let endIndex = hex.index(startIndex, offsetBy: 2)
            
            if let hexValue = UInt8(hex[startIndex..<endIndex], radix: 16) {
                let unicodeScalar = UnicodeScalar(hexValue)
                asciiString.append(Character(unicodeScalar))
            } else {
                print("Error converting hex to UInt8")
            }
            
            hex.removeFirst(2)
        }
        
        // Remove non-alphanumeric characters from the VIN
        let vinNumber = asciiString.replacingOccurrences(
            of: "[^a-zA-Z0-9]",
            with: "",
            options: .regularExpression
        )
        // getvininfo
        return vinNumber
    }
    
    func getVINInfo(vin: String) async throws -> VINResults {
        let endpoint = "https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/\(vin)?format=json"
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(VINResults.self, from: data)
            return decoded
        } catch {
            print(error)
        }
        return VINResults(Results: [])
    }
}







    
    
    
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
