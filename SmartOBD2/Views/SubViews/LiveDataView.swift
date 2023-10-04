//
//  LiveDataView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine
class LiveDataViewModel: ObservableObject {
    let pids: [OBDCommand] = [OBDCommand.speed, OBDCommand.rpm]

    let obdService: OBDService

    private var isRequestingPids = false

    init(obdService: OBDService) {
        self.obdService = obdService
    }

    @Published var pidData: [OBDCommand: PIDData] = [:]
    fileprivate var cancellables = Set<AnyCancellable>()

    func startRequestingPIDs() {

        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            while isRequestingPids {
                for pid in pids {
                    await obdService.elm327.requestPIDs(pid) { pidData in
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
    }
}

struct LiveDataView: View {
    @ObservedObject var viewModel: LiveDataViewModel

    @State private var rpm: Double = 0
    @State private var speed: Double = 0

    var body: some View {
        VStack {
            Text("Speed: " + String(speed) + " km/h")
                        .font(.title)
                        .padding()
            GaugeView(coveredRadius: 280, maxValue: 8, steperSplit: 1, value: $rpm)
        }
        .onAppear(
            perform: {
                viewModel.startRequestingPIDs()
                viewModel.$pidData
                    .sink { pidData in
                        if let newRpm = pidData[OBDCommand.rpm]?.value {
                            rpm = newRpm / 1000
                        }

                        if let newSpeed = pidData[OBDCommand.speed]?.value {
                            speed = newSpeed
                            print("ola", speed)
                        }
                    }
                    .store(in: &viewModel.cancellables)
            }

        )
    }
}

#Preview {
    LiveDataView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager())))
}
