//
//  GarageView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/2/23.
//

import SwiftUI

struct GarageView: View {
    @ObservedObject var viewModel: GarageViewModel
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) var dismiss

    @State private var isAddingVehicle = false

    var body: some View {
        ZStack {
            LinearGradient(.darkStart, .darkEnd)
                .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(viewModel.garage.garageVehicles) { vehicle in
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(vehicle.make)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                 .foregroundColor(.white)

                            Text(vehicle.model)
                                .font(.system(size: 14, weight: .bold, design: .default))
                                .foregroundColor(.white)

                            Text(vehicle.year)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button {
                            viewModel.deleteVehicle(vehicle)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 125, alignment: .leading)
                    .background(viewModel.currentVehicle == vehicle ? Color.blue : Color.clear)
                    .padding(.bottom, 15)
                    .onTapGesture {
                        withAnimation {
                            viewModel.setCurrentVehicle(by: vehicle.id)
                        }
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Garage")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    globalSettings.displayType = .quarterScreen
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }

            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingVehicle = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $isAddingVehicle) {
            AddVehicleView(viewModel: AddVehicleViewModel(garage: viewModel.garage, obdService: viewModel.obdService),
                           isPresented: $isAddingVehicle
            )
        }
    }
}

#Preview {
    GarageView(viewModel: GarageViewModel(garage: Garage(), obdService: OBDService()))
        .background(LinearGradient(.darkStart, .darkEnd))
}


//class MockGarage: ObservableObject, GarageProtocol {
//    @Published var garageVehicles: [Vehicle]
//    @Published var currentVehicleId: Int? {
//        didSet {
//            if let currentVehicleId = currentVehicleId {
//                UserDefaults.standard.set(currentVehicleId, forKey: "currentCarId")
//            }
//        }
//    }
//
//    var currentVehicleIdPublisher: Published<Int?>.Publisher { $currentVehicleId }
//
//    @Published var currentVehicle: Vehicle?
//
//    init() {
//        self.garageVehicles = [Vehicle(id: 1,
//                                       make: "Toyota",
//                                       model: "Camry",
//                                       year: "2019",
//                                       obdinfo: OBDInfo(vin: "",
//                                                        supportedPIDs: [OBDCommand.mode1(.speed),
//                                                                        OBDCommand.mode1(.coolantTemp),
//                                                                        OBDCommand.mode1(.fuelPressure),
//                                                                        OBDCommand.mode1(.fuelLevel),
//                                                                        OBDCommand.mode1(.barometricPressure),
//                                                                        OBDCommand.mode1(.fuelType),
//                                                                        OBDCommand.mode1(.ambientAirTemp),
//                                                                        OBDCommand.mode1(.engineOilTemp),
//                                                                        OBDCommand.mode1(.engineLoad),
//                                                                        ],
//                                                        obdProtocol: .NONE,
//                                                        ecuMap: [:])
//                                      ),
//                               Vehicle(id: 2,
//                                         make: "Nissan",
//                                         model: "Altima",
//                                         year: "2019")
//        ]
//        self.currentVehicleId = currentVehicleId
//        self.currentVehicle = garageVehicles[0]
//    }
//
//    func setCurrentVehicle(by id: Int) {
//        self.currentVehicleId = id
//        self.currentVehicle = garageVehicles.first(where: { $0.id == id })
//        print("setting")
//    }
//
//    func deleteVehicle(_ car: Vehicle) {
//        print("Deleting \(car)")
//    }
//}
