//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth


protocol ElmManager {
    // Define the methods and properties required by elm327
    func sendMessageAsync(_ message: String,  withTimeoutSecs: Int) async throws -> String
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo
}

struct OBDInfo {
    var vin: String?
    var ecus: [String] = []
    var obdProtocol: PROTOCOL = .NONE
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
    
    // want to return vin if available, header status, echo status, ecu, currently selected ecu
    
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo {
        /*
         Perform the setup process
         
         */
        var obdInfo = OBDInfo()

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
                        obdInfo.ecus = try await testProtocol(step: step)
                        
                        // test the protocol
                        obdInfo.obdProtocol = obdProtocol
                        if let setupStep = SetupStep(rawValue: "AT0902") {
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
                    
                // Setup Complete will attempt to get the VIN Number
                case .AT0902:
                    do {
                        let vinResponse = try await sendMessageAsync("0902")             // Try to get VIN
                        let vin = try await decodeVIN(response: vinResponse)
                        obdInfo.vin = vin
                        do {
                            let vinInfo = try await getVINInfo(vin: vin)
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
        return obdInfo
    }
    
    // MARK: - Protocol Testing
    
    func testProtocol(step: SetupStep) async throws -> [String] {
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
 
            let headers = await getECUs(response: response2)

            // Turn header off now
            _ = try await okResponse(message: "ATH0")
            return headers

        } catch {
            throw error
        }
    }
    
    func getECUs(response: String) async -> [String] {
        // Find the indices of "41 00" in the response
        let ecuSegments = response.components(separatedBy: " ")
        var headers: [String] = []


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
            headers.append(header.joined(separator: " "))
            let _ = await getSupportedPIDs(header: header)
        }
        return headers
    }
    
    func getSupportedPIDs(header: [String]) async -> [String] {
        var supportedPIDs: [String] = []
        do {
            if !header.contains("10") {
                print("not ecu")
                return []
            }
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
            supportedPIDs = binaryData.enumerated()
                .compactMap { index, bit -> String? in
                    if bit == "1" {
                        let pidNumber = String(format: "%02X", index + 1)
                        return pidNumber
                    }
                    return nil
                    
                }
            
            
            // remove nils
            let _ = supportedPIDs
                                        .map { $0 }
                                        .compactMap { $0 }
    
        } catch {
        }
        return supportedPIDs
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







    
    
   
