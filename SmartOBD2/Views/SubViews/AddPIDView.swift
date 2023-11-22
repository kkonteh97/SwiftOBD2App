//
//  AddPIDView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/10/23.
//

import SwiftUI
import Combine

class AddPIDViewModel: ObservableObject {
    let garage: Garage
    var cancellables = Set<AnyCancellable>()

    @Published var currentVehicle: Vehicle?

    init(garage: Garage) {
        self.garage = garage
        garage.$currentVehicleId
            .sink { currentVehicleId in
                self.currentVehicle = self.garage.garageVehicles.first(where: { $0.id == currentVehicleId })
            }
            .store(in: &cancellables)
    }
}

struct AddPIDView: View {
    @ObservedObject var viewModel: LiveDataViewModel
    var body: some View {
        if let car = viewModel.currentVehicle {
            VStack(alignment: .leading) {
                Text("Supported sensors for \(car.year) \(car.make) \(car.model)")
                Divider().background(Color.white)

                ScrollView(.vertical, showsIndicators: false) {
                    if let supportedPIDs = car.obdinfo?.supportedPIDs {
                        ForEach(supportedPIDs, id: \.self) { pid in
                            HStack {
                                Text(pid.properties.description)
                                    .font(.caption)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.endColor())
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(viewModel.data.keys.contains(pid) ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .onTapGesture {
                                viewModel.addPIDToRequest(pid)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    }
}

#Preview {
    AddPIDView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                            garage: Garage()))
}
