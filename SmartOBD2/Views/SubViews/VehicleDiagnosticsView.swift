//
//  VehicleDiagnosticsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI

struct VehicleDiagnosticsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            LinearGradient(.darkStart, .darkEnd)
                .ignoresSafeArea()

            VStack {
                Text("Health Status")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 20)

                Text("Last Store Trouble Codes")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 20)

                Button {
                    print("Button tapped")
                } label: {
                    Text("Check for Trouble Codes")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    var navTitle: String {
           if let currentVehicle = viewModel.currentVehicle {
               return "\(currentVehicle.year) \(currentVehicle.make) \(currentVehicle.model)"
           } else {
               return "Garage Empty"
           }
       }
}

#Preview {
    ZStack {
        VehicleDiagnosticsView(viewModel: HomeViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                        garage: Garage()))
    }
}
