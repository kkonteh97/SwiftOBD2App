//
//  LiveDataViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import Combine
import SwiftUI

enum OBDDecodeResult {
    case stringResult(String)
    case statusResult(Status)
    case measurementResult(Measurement<Unit>)
    case noResult
}

struct PIDMeasurement: Identifiable, Comparable, Hashable {
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

class DataItem: Identifiable, ObservableObject {
    let id = UUID()
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
    let obdService: OBDService
    let garage: Garage
    private var cancellables = Set<AnyCancellable>()


    @Published var currentVehicle: GarageVehicle?

    @Published var isRequestingPids = false

    @Published var data: [OBDCommand : DataItem] = [.speed: DataItem(command: .speed, selectedGauge: .gaugeType1),
                                                    .rpm: DataItem( command: .rpm, selectedGauge: .gaugeType1)]

    @Published var order: [OBDCommand] = [.speed, .rpm]

    private var timer: Timer?
    private var appendMeasurementsTimer: DispatchSourceTimer?
    private let measurementTimeLimit: TimeInterval = 600 // 10 minutes

    init(obdService: OBDService, garage: Garage) {
        self.obdService = obdService
        self.garage = garage
        garage.$currentVehicleId
                .sink { currentVehicleId in
                    self.currentVehicle = self.garage.garageVehicles.first(where: { $0.id == currentVehicleId })
                }
                .store(in: &cancellables)
    }


    func addPIDToRequest(_ pid: OBDCommand) {
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

    private func restartTimer() {
        stopTimer()
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        stopTimer()
        appendMeasurementsTimer?.cancel()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01,
                                     repeats: true) { [weak self] _ in
            self?.startRequestingPIDs()
        }
        startAppendMeasurementsTimer()
    }

    func controlRequestingPIDs(status: Bool) {
        if status {
            guard timer == nil else { return }
            startTimer()
        } else {
            stopTimer()
            appendMeasurementsTimer?.cancel()
            isRequestingPids = false
        }
    }

    func startAppendMeasurementsTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.appendMeasurements()
        }
        timer.resume()
        appendMeasurementsTimer = timer
    }

    func appendMeasurements() {
        DispatchQueue.main.async {
              for (_, item) in self.data {
                  item.measurements.append(PIDMeasurement(time: Date(), value: item.value))
            }
        }
    }

    func startRequestingPIDs() {
        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            let messages = await obdService.elm327.requestPIDs(order)
            updateDataItems(messages: messages, keys: order)
        }
    }

    private func updateDataItems(messages: [Message], keys: [OBDCommand]) {
        guard !messages.isEmpty else {
                return
        }
        guard let data = messages[0].data else {
            return
        }
        DispatchQueue.main.async {
            var res = BatchedResponse(response: data)
            keys.forEach { cmd in
                if let value = res.getValueForCommand(cmd) {
                    // Update the data directly
                    if let existingItem = self.data[cmd] {
                        let newValue = decodeMeasurementToDouble(value)
                        existingItem.value = newValue
                    }
                }
            }
            self.isRequestingPids = false
        }
    }
}

func decodeMeasurementToBindingDouble(_ measurement: OBDDecodeResult?) -> Binding<Double> {
    guard let measurement = measurement else {
        return .constant(0)
    }
    switch measurement {
    case .stringResult(let value):
        return .constant(Double(value) ?? 0)
    case .statusResult(_):
        return .constant(0)
    case .measurementResult(let value):
        return .constant(value.value)
    case .noResult:
        return .constant(0)
    }
}

func decodeToMeasurement(_ result: OBDDecodeResult) -> Measurement<Unit> {
    switch result {
    case .measurementResult(let value):
        return value
    default:
        return Measurement(value: 0, unit: UnitSpeed.kilometersPerHour)
    }
}

func decodeMeasurementToDouble(_ measurement: OBDDecodeResult?) -> Double {
    guard let measurement = measurement else {
        return 0
    }
    switch measurement {
    case .stringResult(let value):
        return Double(value) ?? 0
    case .statusResult(_):
        return 0
    case .measurementResult(let value):
        return value.value
    case .noResult:
        return 0
    }
}

func decodeMeasurementToString(_ measurement: OBDDecodeResult?) -> String {
    guard let measurement = measurement else {
        return "N/A"
    }
    switch measurement {
    case .stringResult(let value):
        return value
    case .statusResult(let value):
        return String(describing: value)
    case .measurementResult(let value):
        return "\(value.value) \(value.unit.symbol)"
    case .noResult:
        return "No Result"
    }
}
