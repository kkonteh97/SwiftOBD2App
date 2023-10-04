//
//  BottomSheetViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import Foundation
import Combine

class BottomSheetViewModel: ObservableObject {

    @Published var garage: Garage
    @Published var obdInfo = OBDInfo()

    @Published var garageVehicles: [GarageVehicle] = []

    private var cancellables = Set<AnyCancellable>()

    let obdService: OBDService

    init(obdService: OBDService, garage: Garage) {
        self.obdService = obdService
        self.garage = garage

        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)
    }

    func addVehicle(make: String, model: String, year: String, vin: String) {
        garage.addVehicle(make: make, model: model, year: year, vin: vin)
    }

    func deleteVehicle(_ vehicle: GarageVehicle) {
        garage.deleteVehicle(vehicle)
    }

    func setupAdapter(setupOrder: [SetupStep]) async throws {
        let obdInfo = try await obdService.setupAdapter(setupOrder: setupOrder)

        DispatchQueue.main.async {
            self.obdInfo = obdInfo
        }

        if let vin = obdInfo.vin {
                if let vehicle =  garage.garageVehicles.first(where: { $0.vin == vin }) {
                    // set selected car
//                    DispatchQueue.main.async {
//                        self.selectedCar = vehicle
//                    }

                }

                let vinInfo = try await getVINInfo(vin: vin)

                DispatchQueue.main.async {
                    guard let vinInfo = vinInfo.Results.first else {
                        return
                    }
                    self.garage.addVehicle(
                        make: vinInfo.Make, model: vinInfo.Model, year: vinInfo.ModelYear, vin: vin, obdinfo: obdInfo
                    )
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
