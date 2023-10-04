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
                Text("Vehicle Diagnostics")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding()
                Button {
                    print("Button tapped")
                } label: {
                    Text("Start")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    VehicleDiagnosticsView(viewModel: HomeViewModel(obdService: OBDService(bleManager: BLEManager()), garage: Garage()))
}
