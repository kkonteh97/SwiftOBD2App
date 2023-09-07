//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

class SettingsScreenViewModel: ObservableObject {
    let elm327: ELM327
    
    @Published var obdInfo = OBDInfo()
    let bleManager: BLEManager
    @Published var elmAdapter: CBPeripheral?
    private var cancellables = Set<AnyCancellable>()
    @Published var vinInput = ""
    @Published var vinInfo: VINInfo?
    @Published var selectedProtocol: PROTOCOL = .AUTO

    init(elm327: ELM327, bleManager: BLEManager) {
        self.elm327 = elm327
        self.bleManager = bleManager
        // Subscribe to changes in elmAdapter
        bleManager.$elmAdapter
            .sink { [weak self] elmAdapter in
                self?.elmAdapter = elmAdapter
            }
            .store(in: &cancellables)
    }
    
    func setupAdapter(setupOrder: [SetupStep]) async throws {
        let obdInfo = try await elm327.setupAdapter(setupOrder: setupOrder)
        DispatchQueue.main.async {
            self.obdInfo = obdInfo
            self.selectedProtocol = obdInfo.obdProtocol
        }
        if let vin = obdInfo.vin {
            do {
                let vinInfo = try await getVINInfo(vin: vin)
                DispatchQueue.main.async {
                    self.vinInput = vin
                    self.vinInfo = vinInfo.Results[0]
                }
                print(vinInfo)
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
