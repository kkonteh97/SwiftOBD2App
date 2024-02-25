//
//  GarageView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/2/23.
//

import SwiftUI

struct GarageView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @EnvironmentObject var garage: Garage

    @Environment(\.dismiss) var dismiss
    @Binding var displayType: BottomSheetType
    @Binding var isDemoMode: Bool

    @State private var isAddingVehicle = false

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: $isDemoMode)
            VStack {
                List(garage.garageVehicles, id: \.self, selection: $garage.currentVehicle) { vehicle in
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
                        if garage.currentVehicle?.id == vehicle.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .listRowBackground(garage.currentVehicle?.id == vehicle.id ? Color.blue : Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", role: .destructive) {
                            garage.deleteVehicle(vehicle)
                        }
                    }
                }
                .padding(.top, 25)
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    displayType = .quarterScreen
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Vehicle", role: .none) {
                    isAddingVehicle = true
                }
                .buttonStyle(.bordered)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            }
        }
        .gesture(DragGesture().onEnded({
            if $0.translation.width > 100 {
                displayType = .quarterScreen
                dismiss()
            }
        }))
        .sheet(isPresented: $isAddingVehicle) {
            AddVehicleView(isPresented: $isAddingVehicle)
        }
    }
}

#Preview {
    NavigationView {
        GarageView(displayType: .constant(.quarterScreen),
                   isDemoMode: .constant(false))
        .background(LinearGradient(.darkStart, .darkEnd))
        .environmentObject(GlobalSettings())
        .environmentObject(Garage())
    }
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
