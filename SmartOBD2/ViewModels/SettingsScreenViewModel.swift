//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

struct Manufacturer: Codable {
    let make: String
    let models: [CarModel]
}

struct CarModel: Codable {
    let name: String
    let years: [Int]
}

struct GarageVehicle: Codable, Identifiable {
    let id: UUID
    let make: String
    let model: String
    let year: String
}

class SettingsScreenViewModel: ObservableObject {
    @Published var garageVehicles: [GarageVehicle] = [GarageVehicle(id: UUID(), make: "Honda", model: "Civic", year: "2019")]
    @Published var obdInfo = OBDInfo()
    @Published var elmAdapter: CBPeripheral?
    @Published var vinInput = ""
    @Published var vinInfo: VINInfo?
    @Published var selectedProtocol: PROTOCOL = .AUTO
    @Published var selectedYear = -1
    @Published var selectedModel = -1 {
        didSet {
            selectedYear = -1
        }
    }
    @Published var selectedCar: GarageVehicle? = nil
    @Published var selectedManufacturer = -1 {
        didSet {
            selectedModel = -1
            selectedYear = -1
            selectedCar = nil
        }
    }
    
    let elm327: ELM327
    let bleManager: BLEManager
    let carData: [Manufacturer]

    private var cancellables = Set<AnyCancellable>()

    var models: [CarModel] {
        return (0 ..< carData.count).contains(selectedManufacturer) ? carData[selectedManufacturer].models : []
    }

    var years: [Int] {
        return (0 ..< models.count).contains(selectedModel) ? models[selectedModel].years : []
    }

    init(elm327: ELM327, bleManager: BLEManager) {
        let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        carData = try! JSONDecoder().decode([Manufacturer].self, from: data)
        self.elm327 = elm327
        self.bleManager = bleManager
        subscribeToElmAdapterChanges()
    }

    private func subscribeToElmAdapterChanges() {
        bleManager.$elmAdapter
            .sink { [weak self] elmAdapter in
                self?.elmAdapter = elmAdapter
            }
            .store(in: &cancellables)
    }

    func addVehicle() {
        let selectedCar = GarageVehicle(id: UUID(), make: carData[selectedManufacturer].make, model: models[selectedModel].name, year: String(years[selectedYear]))
            garageVehicles.append(selectedCar)
            print(garageVehicles)
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
                    self.vinInfo = vinInfo.Results.first
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
