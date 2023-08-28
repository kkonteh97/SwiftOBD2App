//
//  CarScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI

struct CarScreen: View {
//    @ObservedObject var viewModel: BLEManager // Declare the view model as a property
    
    var body: some View {
            VStack {
//                statusIndicator
//                    .padding(.bottom, 15)
                
//                carDetails
                Spacer()
                HStack {
                    VStack {
                        Text("Supported PIDs")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
//                        ForEach(Array(viewModel.pidDescriptions.enumerated()), id: \.element) { index, pid in
//                            VStack {
//                                Text("\(pid)")
//                            }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        }
                        Spacer()
                    }
//                    VStack {
//                        Text("Values")
//                            .font(.system(size: 20))
//                            .fontWeight(.bold)
//                        Text("RPM: \(viewModel.Engine_RPM)")
//                        Text("Speed: \(viewModel.Vehicle_speed)")
//                        Text("Engine Load: \(viewModel.engine_load)")
//                        Text("Coolant Temp: \(viewModel.coolant_temp)")
//                            
//                    }
                }
            }
            .padding()
                
        }
    
//    private var statusIndicator: some View {
//            HStack {
//                Spacer()
//                ZStack {
//                    Circle()
//                        .foregroundColor(viewModel.initialized ? .green : .red)
//                        .frame(width: 60, height: 60)
//
//                    Text(viewModel.initialized ? "Ready" : "Not Ready")
//                        .font(.system(size: 10))
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                }
//                Spacer()
//            }
//        }
//    
    
    
//    private var carDetails: some View {
//            VStack(alignment: .leading, spacing: 10) {
//                CarInfoRow(label: "VIN", value: viewModel.VIN)
//                CarInfoRow(label: "Make", value: viewModel.carMake)
//                CarInfoRow(label: "Model", value: viewModel.carModel)
//                CarInfoRow(label: "Year", value: viewModel.carYear)
//                CarInfoRow(label: "Engine", value: "\(viewModel.carCylinders) cylinders")
//            
//            }
//        }
}

struct CarInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 20))
            Spacer()
            Text(value)
                .font(.system(size: 20))
        }
    }
}

struct CarScreen_Previews: PreviewProvider {
    static var previews: some View {
        CarScreen()
    }
}
