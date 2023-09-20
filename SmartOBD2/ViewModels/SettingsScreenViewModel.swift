//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

struct Vehicle: Codable {
    let make: String
    let model: String
    let year: Int
    let obdinfo: OBDInfo
}

struct OBDInfo: Codable {
    var vin: String?
    var supportedPIDs: [OBDCommand]?
    var obdProtocol: PROTOCOL = .NONE
}

struct Manufacturer: Codable {
    let make: String
    let models: [Model]
}

struct Model: Codable {
    let name: String
    let years: [Int]
}

struct GarageVehicle: Codable, Identifiable {
    let id: UUID
    var vin: String = ""
    let make: String
    let model: String
    let year: String
    var obdinfo: OBDInfo?
}

struct PIDData {
    let pid: OBDCommand
    var value: Double
    var unit: String
}

class SettingsScreenViewModel: ObservableObject {
    @Published var garageVehicles: [GarageVehicle] = []
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

    @Published var selectedCar: GarageVehicle?
    @Published var selectedManufacturer = -1 {
        didSet {
            selectedModel = -1
            selectedYear = -1
            selectedCar = nil
        }
    }

    let elm327: ELM327
    var carData: [Manufacturer] = []

    private var cancellables = Set<AnyCancellable>()

    var models: [Model] {
        return (0 ..< carData.count).contains(selectedManufacturer) ? carData[selectedManufacturer].models : []
    }

    var years: [Int] {
        return (0 ..< models.count).contains(selectedModel) ? models[selectedModel].years : []
    }

    init(elm327: ELM327) {
        self.elm327 = elm327
        loadGarageVehicles()
        subscribeToElmAdapterChanges()

        // Load garageVehicles from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "garageVehicles"),
           let decodedVehicles = try? JSONDecoder().decode([GarageVehicle].self, from: data) {
            self.garageVehicles = decodedVehicles
        }
    }

    private func subscribeToElmAdapterChanges() {
        elm327.bleManager.$elmAdapter
            .sink { [weak self] elmAdapter in
                self?.elmAdapter = elmAdapter
            }
            .store(in: &cancellables)
    }


    private func loadGarageVehicles() {
        do {
            let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
            let data = try Data(contentsOf: url)
            self.carData = try JSONDecoder().decode([Manufacturer].self, from: data)

        } catch {

        }
    }

    private var isRequestingPids = false

    @Published var pidData: [OBDCommand: PIDData] = [:]

    func startRequestingPID(pid: OBDCommand) {
        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            while isRequestingPids {
                await self.elm327.requestPIDs(pid) { pidData in
                    if let pidData = pidData {
                        // Handle the valid PID data here
                        DispatchQueue.main.async { // Ensure UI updates on the main thread
                            self.pidData[pid] = pidData
                        }
                    } else {
                        // Handle the case where the request failed or returned nil data
                        print("Request failed or returned nil data")
                    }
                }
            }
        }
    }

    func addVehicle(make: String, model: String, year: String, vin: String = "", obdinfo: OBDInfo? = nil) {
        let selectedCar = GarageVehicle(id: UUID(), vin: vin, make: make, model: model, year: year, obdinfo: obdinfo)
        garageVehicles.append(selectedCar)
        print(garageVehicles)
        saveGarageVehicles()
    }

    func saveGarageVehicles() {
        if let encodedData = try? JSONEncoder().encode(garageVehicles) {
            UserDefaults.standard.set(encodedData, forKey: "garageVehicles")
        }
    }

    func setupAdapter(setupOrder: [SetupStep]) async throws {
        let obdInfo = try await elm327.setupAdapter(setupOrder: setupOrder)
        DispatchQueue.main.async {
            self.obdInfo = obdInfo
            self.selectedProtocol = obdInfo.obdProtocol
        }
        if let vin = obdInfo.vin {
            do {
                if var vehicle =  self.garageVehicles.first(where: { $0.vin == vin }) {
                    vehicle.obdinfo = obdInfo
                    return
                }

                let vinInfo = try await getVINInfo(vin: vin)
                DispatchQueue.main.async {
                    self.vinInput = vin
                    guard let vinInfo = vinInfo.Results.first else {
                        return
                    }
                    self.addVehicle(
                        make: vinInfo.make, model: vinInfo.model, year: vinInfo.modelYear, vin: vin, obdinfo: obdInfo
                    )
                }
                print(vinInfo)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func deleteVehicle(_ car: GarageVehicle) {
        garageVehicles.removeAll(where: { $0.id == car.id })
        saveGarageVehicles()
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
