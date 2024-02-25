//
//  BottomSheetViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

class CustomTabBarViewModel: ObservableObject {
    @Published var garage: Garage
    @Published var garageVehicles: [Vehicle] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var currentVehicle: Vehicle?

    var setupOrder: [OBDCommand.General] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    private var cancellables = Set<AnyCancellable>()

    let obdService: OBDService

    init(_ obdService: OBDService, _ garage: Garage) {
        self.obdService = obdService
        self.garage = garage
        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)

        garage.$currentVehicle
                .sink { currentVehicle in
                    self.currentVehicle = currentVehicle
                }
                .store(in: &cancellables)

        obdService.$connectionState
            .sink { connectionState in
                self.connectionState = connectionState
            }
            .store(in: &cancellables)
    }

    func addVehicle(make: String, model: String, year: String) {
        garage.addVehicle(make: make, model: model, year: year)
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        garage.deleteVehicle(vehicle)
    }

//    func setupAdapter(setupOrder: [OBDCommand.General]) async throws {
//        guard var vehicle = currentVehicle else { throw OBDServiceError.noVehicleSelected }
//        let obdInfo = try await obdService.startConnection(setupOrder: setupOrder, obdinfo: vehicle.obdinfo)
//        vehicle.obdinfo = obdInfo
//        let finalVehicle = vehicle
//        DispatchQueue.main.async {
//            self.garage.updateVehicle(finalVehicle)
//            self.garage.setCurrentVehicle(by: finalVehicle.id)
//        }
//    }
}

func getVINInfo(vin: String) async throws -> VINResults {
    let endpoint = "https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/\(vin)?format=json"

    print(endpoint)
    guard let url = URL(string: endpoint) else {
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(VINResults.self, from: data)
    return decoded
}

//if let vin = obdInfo.vin {
//        if let vehicle =  garage.garageVehicles.first(where: { $0.vin == vin }) {
//            // set selected car
//            DispatchQueue.main.async {
//                self.garage.currentVehicleId = vehicle.id
//            }
//            return
//        }
//    do {
//
//        let vinInfo = try await getVINInfo(vin: vin)
//
//        DispatchQueue.main.async {
//            guard let vinInfo = vinInfo.Results.first else {
//                return
//            }
//            self.garage.addVehicle(
//                make: vinInfo.Make, model: vinInfo.Model, year: vinInfo.ModelYear, vin: vin, obdinfo: obdInfo
//            )
//        }
//    } catch {
//        print(error)
//    }
//}
