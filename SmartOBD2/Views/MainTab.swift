//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI

struct MainTab: View {
    @ObservedObject private var bluethoothViewModel = BluetoothViewModel()
    @EnvironmentObject var elmComm: ELMComm
    
    var body: some View {
        TabView {
            VStack {
                ForEach(bluethoothViewModel.supportedPIDsByECU.keys.sorted(), id: \.self) { ecu in
                    Text("ECU: \(ecu)")
                    ForEach(bluethoothViewModel.supportedPIDsByECU[ecu]!, id: \.self) { pid in
                        Text("PID: \(pid)")
                    }
                }
                
                Text("\(bluethoothViewModel.rpm) RPM")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.leading, 20)
                
                Button("Start RPM") {
                    print("Start RPM")
                    
                }
            }
            .tabItem {
                Image(systemName: "wrench.and.screwdriver")
                Text("Settings")
            }
            
            VStack {
                Text("""
                     Plug in your ELM327 device and turn on your car.
                     
                     Make sure your device is paired with your phone.
                     
                     Press the button below to start scanning for devices.
                     """)
                .padding(.bottom, 40)
                
                
                
            }
            .tabItem {
                Image(systemName: "car.front.waves.up")
                Text(bluethoothViewModel.connected ? "Connected to \(bluethoothViewModel.deviceName)" : "Connect")
                
            }
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    // Status square
                    ZStack {
                        Circle()
                            .foregroundColor(bluethoothViewModel.initialized ? .green : .red)
                            .frame(width: 60, height: 60)
                        
                        Text(bluethoothViewModel.initialized ? "Ready" : "Not Ready")
                            .font(.system(size: 10))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                // history dictionary
                
                ForEach(bluethoothViewModel.history.sorted(by: <), id: \.key) { key, value in
                    HStack {
                        Text("\(key)")
                        Spacer()
                        Text("\(value)")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                TextField("Enter Command", text: $bluethoothViewModel.command)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                
                
                
                
                Button(action: {
                    bluethoothViewModel.sendMessage(bluethoothViewModel.command)
                }, label: {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
                .disabled(!bluethoothViewModel.connected)
                
                
                
            }
            .padding(20)
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
    
    
}

struct VINResults: Codable {
    let Results: [VINInfo]
}



struct VINInfo: Codable{
    let Make: String
    let Model: String
    let ModelYear: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTab()
    }
}
