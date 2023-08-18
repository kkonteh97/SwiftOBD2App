//
//  CarScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI

struct CarScreen: View {
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel

    
    var body: some View {
            VStack {
                statusIndicator
                    .padding(.bottom, 15)
                
                carDetails
                Spacer()
                VStack {
                    Text("Supported PIDs")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    ForEach(bluetoothViewModel.pidDescriptions, id: \.self) { pid in
                        VStack {
                            Text("\(pid)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    }
                    Spacer()
                }
            }
            .padding()
        }
    
    private var statusIndicator: some View {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .foregroundColor(bluetoothViewModel.initialized ? .green : .red)
                        .frame(width: 60, height: 60)

                    Text(bluetoothViewModel.initialized ? "Ready" : "Not Ready")
                        .font(.system(size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
            }
        }
    private var carDetails: some View {
            VStack(alignment: .leading, spacing: 10) {
                CarInfoRow(label: "VIN", value: bluetoothViewModel.VIN)
                CarInfoRow(label: "Make", value: bluetoothViewModel.carMake)
                CarInfoRow(label: "Model", value: bluetoothViewModel.carModel)
                CarInfoRow(label: "Year", value: bluetoothViewModel.carYear)
                CarInfoRow(label: "Engine", value: "\(bluetoothViewModel.carCylinders) cylinders")
            
            }
        }
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
