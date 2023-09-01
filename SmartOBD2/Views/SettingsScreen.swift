//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth
   

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATDPN]
    @State private var isModalPresented = false
    @State private var obdInfo: OBDInfo?


    var body: some View {
        VStack {
            
            if let obdInfo = obdInfo {
                Text("VIN: \(obdInfo.vin ?? "N/A")")
                    .font(.headline)
                    .frame(alignment: .leading)
                Text("OBD Protocol: \(obdInfo.obdProtocol.description)")
                    .font(.headline)
                    .frame(alignment: .leading)

                
                List {
                    ForEach(obdInfo.ecuData.keys.sorted(), id: \.self) { header in
                        if let supportedPIDs = obdInfo.ecuData[header] {
                            VStack(alignment: .leading) {
                                Text("Header: \(header)")
                                    .font(.headline)
                                Text("Supported PIDs: \(supportedPIDs.joined(separator: ", "))")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .opacity(0.8)
            }

            Button(action: {
                isModalPresented.toggle()
            }, label: {
                Text("Change Setup Order")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            .sheet(isPresented: $isModalPresented, content: {
                SetupOrderModal(isModalPresented: $isModalPresented, setupOrder: $setupOrder)
            })
            
            Button(action: {
                Task {
                    do {
                        let result = try await viewModel.setupAdapter(setupOrder: setupOrder)
                        obdInfo = result
                    } catch {
                        print("Error setting up adapter: \(error)")
                    }
                }
                
            }, label: {
                Text("Setup")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            
            
            
        }
        
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen(viewModel: SettingsScreenViewModel(elmManager: ElmManager.self as! ElmManager))
    }
}
