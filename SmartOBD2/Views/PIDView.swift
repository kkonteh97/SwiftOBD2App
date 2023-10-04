//
//  PIDView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/17/23.
//

import SwiftUI

class PIDViewModel: ObservableObject {
    let elm327: ELM327

    init(elm327: ELM327) {
        self.elm327 = elm327
    }

    private var isRequesting = false
    @Published var rpm: Double = 0.0
    @Published var speed: Double = 0.0

    func startRequestingPID() {
        guard connectionState == .connectedToVehicle else {
            return
        }

        guard !isRequesting else {
            return
        }

        let rpmPid = OBDCommand.rpm

        let speedPid = OBDCommand.speed

        let pids = [rpmPid, speedPid]

        isRequesting = true

        Task {
            while isRequesting {
                for pid in pids {
                    await self.elm327.requestPIDs(pid) { pidData in
                        if let pidData = pidData {
                            // Handle the valid PID data here
                            DispatchQueue.main.async { // Ensure UI updates on the main thread
                                if pid == rpmPid {
                                    self.rpm = pidData.value / 1000
                                } else if pid == speedPid {
                                    print(pidData.value)
                                    self.speed = Double(pidData.value)
                                }

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

struct PIDView: View {
    @ObservedObject var viewModel: PIDViewModel

    var body: some View {
            VStack {
                GaugeView(coveredRadius: 280, maxValue: 8, steperSplit: 1, value: $viewModel.rpm)
                GaugeView(coveredRadius: 280, maxValue: 260, steperSplit: 20, value: $viewModel.speed)

            }
            .onAppear(
                perform: {
                    viewModel.startRequestingPID()
                }

            )

    }
}

#Preview {
    PIDView(viewModel: PIDViewModel(elm327: ELM327(bleManager: BLEManager())))
}
