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

class DataItem: Identifiable, Codable, ObservableObject {
    let command: OBDCommand
    @Published var value: Double
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

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case command
        case value
        case unit
        case selectedGauge
        case measurements
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        command = try container.decode(OBDCommand.self, forKey: .command)
        value = try container.decode(Double.self, forKey: .value)
        unit = try container.decode(String.self, forKey: .unit)
        selectedGauge = try container.decode(GaugeType.self, forKey: .selectedGauge)
        measurements = try container.decode([PIDMeasurement].self, forKey: .measurements)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
        try container.encode(selectedGauge, forKey: .selectedGauge)
        try container.encode(measurements, forKey: .measurements)
    }

    func update(_ value: Double) {
        self.value = value
        measurements.append(PIDMeasurement(time: Date(), value: value))
        if measurements.count > 100 {
            measurements.removeFirst()
        }
    }
}

class LiveDataViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    @Published var isRequestingPids = false

    @Published var pidData: [DataItem] = []
    @Published var isRequesting: Bool = false

    private let measurementTimeLimit: TimeInterval = 120

    init() {

        UserDefaults.standard.removeObject(forKey: "pidData")

        if let piddata = UserDefaults.standard.data(forKey: "pidData"),
           let pidData = try? JSONDecoder().decode([DataItem].self, from: piddata) {
            self.pidData = pidData
        } else {
            // default pids SPEED and RPM
            pidData = [DataItem(command: .mode1(.rpm), value: 0, selectedGauge: .gaugeType4),
                       DataItem(command: .mode1(.speed), value: 0, selectedGauge: .gaugeType1)]
        }
    }

    deinit {
        saveDataItems()
    }

    func saveDataItems() {
        if let encodedData = try? JSONEncoder().encode(pidData) {
            UserDefaults.standard.set(encodedData, forKey: "pidData")
        }
    }

    func addPIDToRequest(_ pid: OBDCommand) {
        guard pidData.count < 6 else { return }
        if !pidData.contains(where: { $0.command == pid }) {
            pidData.append(DataItem(command: pid, selectedGauge: .gaugeType1))
        } else {
            pidData.removeAll(where: { $0.command == pid })
        }
    }
}
