//
//  handleVIN.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/12/23.
//

import Foundation

extension BLEManager {
    
    func decodeVIN(for status: ELM327.QUERY.SETUP_STEP, response: (Bool, [String]))  -> ELM327.QUERY.SETUP_STEP? {
        // Unpack the response tuple
        let (_, responseStrings) = response
        
        // Join the response strings into a single string
        let responseString = responseStrings.joined(separator: " ")
        print(responseString)
        // Find the index of the occurrence of "49 02"
        if let prefixIndex = responseString.range(of: "49 02")?.upperBound {
            // Extract the VIN hex string after "49 02"
            let vinHexString = responseString[prefixIndex...]
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
            self.VIN = vinNumber
            // getvininfo
            Task {
                do {
                    let vinInfo = try await getVINInfo(vin: vinNumber)
                    DispatchQueue.main.async {
                                self.carMake = vinInfo.Results[0].Make
                                self.carModel = vinInfo.Results[0].Model
                                self.carYear = vinInfo.Results[0].ModelYear
                                self.carCylinders = vinInfo.Results[0].EngineCylinders
//                        self.requestPids()

                            }
                    print(vinInfo)

                } catch {
                    print(error)
                }
            }
            print(vinNumber)
        } else {
            print("Prefix not found in the response")
        }
        
        return setupStatus.next()
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
