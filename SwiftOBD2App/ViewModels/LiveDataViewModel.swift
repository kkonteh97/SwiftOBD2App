//
//  LiveDataViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import Combine
import SwiftUI
import SwiftOBD2

struct PIDMeasurement: Identifiable, Comparable, Hashable, Codable {
    static func < (lhs: PIDMeasurement, rhs: PIDMeasurement) -> Bool {
        lhs.id < rhs.id
    }

    let id: Date
    let value: Double

    init(time: Date, value: Double) {
           self.value = value
            self.id = time
       }
}

class DataItem: Identifiable, Codable {
    let command: OBDCommand
    var value: Double
    var unit: String?
    var selectedGauge: GaugeType?
    var measurements: [PIDMeasurement]

    init(command: OBDCommand,
         value: Double = 0,
         unit: String? = nil,
         selectedGauge: GaugeType? = nil,
         measurements: [PIDMeasurement] = []
    ) {
        self.command = command
        self.value = value
        self.unit = unit
        self.selectedGauge = selectedGauge
        self.measurements = measurements
    }
}

class LiveDataViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()


    @Published var isRequestingPids = false

    @Published var data: [OBDCommand : DataItem] = [:]
    @Published var order: [OBDCommand] = []
    @Published var isRequesting: Bool = false

    private let measurementTimeLimit: TimeInterval = 120

    init() {

        UserDefaults.standard.removeObject(forKey: "pidData")

        if let piddata = UserDefaults.standard.data(forKey: "pidData"),
           let pidData = try? JSONDecoder().decode([DataItem].self, from: piddata) {
            for item in pidData {
                self.data[item.command] = item
                self.order.append(item.command)
            }
        } else {
            // default pids SPEED and RPM
            data[.mode1(.rpm)] = DataItem(command: .mode1(.rpm), value: 754,selectedGauge: .gaugeType4)
            data[.mode1(.speed)] = DataItem(command: .mode1(.speed), value: 34,selectedGauge: .gaugeType1)
            order.append(.mode1(.rpm))
            order.append(.mode1(.speed))
        }
    }

    deinit {
        saveDataItems()
    }

    func saveDataItems() {
        if let encodedData = try? JSONEncoder().encode(Array(data.values)) {
            UserDefaults.standard.set(encodedData, forKey: "pidData")
        }
    }

    func addPIDToRequest(_ pid: OBDCommand) {
        guard order.count < 6 else { return }
        if !data.keys.contains(pid) {
            data[pid] = DataItem(command: pid, selectedGauge: .gaugeType1)
            order.append(pid)
        } else {
            data.removeValue(forKey: pid)
            if let index = order.firstIndex(of: pid) {
                order.remove(at: index)
            }
        }
    }
}

