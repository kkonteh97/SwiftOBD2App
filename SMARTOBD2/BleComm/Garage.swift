//
//  Garage.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

struct Vehicle: Codable, Identifiable, Equatable {
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool {
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
    @Published var garageVehicles: [Vehicle] = []

    private var nextId = 1 // Initialize with the next integer ID

    @Published var currentVehicleId: Int? {
        didSet {
            if let currentVehicleId = currentVehicleId {
                UserDefaults.standard.set(currentVehicleId, forKey: "currentCarId")
            }
        }
    }

    init () {
        // Load garageVehicles from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "garageVehicles"),
           let decodedVehicles = try? JSONDecoder().decode([Vehicle].self, from: data) {
            self.garageVehicles = decodedVehicles
        }

        // Determine the next available integer ID
        if let maxId = garageVehicles.map({ $0.id }).max() {
              self.nextId = maxId + 1
        }

        // Load currentVehicleId from UserDefaults
        self.currentVehicleId = UserDefaults.standard.integer(forKey: "currentCarId")
    }

    func addVehicle(make: String, model: String, year: String, vin: String = "", obdinfo: OBDInfo? = nil) {
        let vehicle = Vehicle(id: nextId, vin: vin, make: make, model: model, year: year, obdinfo: obdinfo)
        garageVehicles.append(vehicle)
        nextId += 1
        saveGarageVehicles()
        currentVehicleId = vehicle.id
        print("Added vehicle \(vehicle)")
    }

    // set current vehicle by id
    func setCurrentVehicle(by id: Int) {
        currentVehicleId = id
    }

    func deleteVehicle(_ car: Vehicle) {
        garageVehicles.removeAll(where: { $0.id == car.id })
        if car.id == currentVehicleId { // check if the deleted car was the current one
            currentVehicleId = garageVehicles.first?.id // make the first car in the garage as the current car
        }
        saveGarageVehicles()
    }

    // get vehicle by id from garageVehicles
    func getVehicle(id: Int) -> Vehicle? {
        return garageVehicles.first(where: { $0.id == id })
    }

    func saveGarageVehicles() {
        if let encodedData = try? JSONEncoder().encode(garageVehicles) {
            UserDefaults.standard.set(encodedData, forKey: "garageVehicles")
        }
    }
}
