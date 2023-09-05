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
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isModalPresented = false
    @State private var obdInfo: OBDInfo?
    @State private var isAnimating = false


    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isModalPresented.toggle()
                }, label: {
                    Text("Change Setup Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 170, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
                .sheet(isPresented: $isModalPresented, content: {
                    SetupOrderModal(isModalPresented: $isModalPresented, setupOrder: $setupOrder)
                })
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.setupAdapter(setupOrder: setupOrder)
                            isAnimating.toggle()
                        } catch {
                            print("Error setting up adapter: \(error.localizedDescription)")
                        }
                    }
                }, label: {
                    Text("Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 170, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
            }
            Text("VIN: \(viewModel.obdInfo.vin ?? "")")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("OBD Protocol: \(viewModel.obdInfo.obdProtocol.description)")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            
            ForEach(viewModel.obdInfo.ecuData.keys.sorted(), id: \.self) { header in
                if let supportedPIDs = viewModel.obdInfo.ecuData[header] {
                    Section {
                        VStack(alignment: .leading) {
                            Section(header: 
                                        Text(header)
                                            .font(.headline)

                            ) {
                                ForEach(supportedPIDs, id: \.self) { pid in
                                    Text("PID: \(pid)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            
            Spacer()
        }
    }
        
}
struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen(viewModel: SettingsScreenViewModel(elm327: ELM327()))
    }
}
