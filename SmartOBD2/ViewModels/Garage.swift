//
//  Garage.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import Foundation
import UIKit

struct GarageVehicle: Codable, Identifiable, Equatable {
    static func == (lhs: GarageVehicle, rhs: GarageVehicle) -> Bool {
        return lhs.id == rhs.id
    }

    let id: Int
    var vin: String = ""
    let make: String
    let model: String
    let year: String
    var obdinfo: OBDInfo?
}

class Garage: ObservableObject {
    @Published var garageVehicles: [GarageVehicle] = [
           GarageVehicle(id: 1, make: "Nissan", model: "Altima", year: "2016")
    ]

    private var nextId = 2 // Initialize with the next integer ID

    init () {
        // Load garageVehicles from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "garageVehicles"),
           let decodedVehicles = try? JSONDecoder().decode([GarageVehicle].self, from: data) {
            self.garageVehicles = decodedVehicles
        }

        // Determine the next available integer ID
        if let maxId = garageVehicles.map({ $0.id }).max() {
              self.nextId = maxId + 1
        }
    }

    func addVehicle(make: String, model: String, year: String, vin: String = "", obdinfo: OBDInfo? = nil) {
            let vehicle = GarageVehicle(id: nextId, vin: vin, make: make, model: model, year: year, obdinfo: obdinfo)
            garageVehicles.append(vehicle)
            saveGarageVehicles()
            nextId += 1 // Increment the ID for the next vehicle
    }

    func deleteVehicle(_ car: GarageVehicle) {
        garageVehicles.removeAll(where: { $0.id == car.id })
        saveGarageVehicles()
    }

    // get vehicle by id from garageVehicles
    func getVehicle(id: Int) -> GarageVehicle? {
        return garageVehicles.first(where: { $0.id == id })
    }

    func saveGarageVehicles() {
        if let encodedData = try? JSONEncoder().encode(garageVehicles) {
            UserDefaults.standard.set(encodedData, forKey: "garageVehicles")
        }
    }
}
