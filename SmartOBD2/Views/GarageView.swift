//
//  GarageView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/2/23.
//

import SwiftUI
import Combine

class GarageViewModel: ObservableObject {
    @Published var garage: Garage

    @Published var garageVehicles: [GarageVehicle] = []
    private var cancellables = Set<AnyCancellable>()

    init(garage: Garage) {
        self.garage = garage
        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)
    }

    func deleteVehicle(_ vehicle: GarageVehicle) {
        garage.deleteVehicle(vehicle)
    }
}

struct GarageView: View {
    @ObservedObject var viewModel: GarageViewModel
    @Binding var selectedVehicle: Int

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    var body: some View {
        VStack {
            ForEach(garageVehicles) { vehicle in
                HStack(spacing: 10) {
                    Text(vehicle.make)
                    Spacer()
                    Text(vehicle.model)
                    Spacer()
                    Text(vehicle.year)
                    Spacer()
                    Button {
                        viewModel.deleteVehicle(vehicle)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .modifier(RoundedRectangleStyle())
                .onTapGesture {
                    withAnimation {
                        selectedVehicle =  vehicle.id
                    }
                }
            }
        }
    }
}

#Preview {
    GarageView(viewModel: GarageViewModel(garage: Garage()), selectedVehicle: .constant(1))
}
