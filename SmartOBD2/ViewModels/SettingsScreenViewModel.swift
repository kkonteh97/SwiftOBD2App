//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation

class SettingsScreenViewModel: ObservableObject {
    let elm327: ELM327
    
    @Published var obdInfo = OBDInfo()
    
    init(elm327: ELM327) {
        self.elm327 = elm327
    }
    
    func setupAdapter(setupOrder: [SetupStep]) async throws {
        let obdInfo = try await elm327.setupAdapter(setupOrder: setupOrder)
        DispatchQueue.main.async {
            self.obdInfo = obdInfo
        }
        if let vin = self.obdInfo.vin {
            do {
                let _ = try await getVINInfo(vin: vin)
            } catch {
                print(error.localizedDescription)
            }
        }
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
