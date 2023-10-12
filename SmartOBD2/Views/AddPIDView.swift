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

    @Published var currentVehicle: GarageVehicle?

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
        ScrollView(.vertical, showsIndicators: false) {
            if let car = viewModel.currentVehicle {
                if let supportedPIDs = car.obdinfo?.supportedPIDs {
                    ForEach(supportedPIDs, id: \.self) { pid in
                        HStack {
                            Text(pid.description)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(RoundedRectangleStyle())
                        .onTapGesture {
                            viewModel.addPIDToRequest(pid)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AddPIDView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                            garage: Garage()))
}
