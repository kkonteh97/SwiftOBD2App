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
                HStack {
                    GaugeView(coveredRadius: 280, maxValue: 80, steperSplit: 10, value: $bluethoothViewModel.rpm)
                        .frame(width: 150, height: 150, alignment: .center)
                    // speed
                }
                Text("\(bluethoothViewModel.rpm) RPM")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.leading, 20)
                
                Button("Start RPM") {
                    guard let characteristic = bluethoothViewModel.ecuCharacteristic else { return }
                    elmComm.startRPMRequest(characteristic: characteristic, peripheral: bluethoothViewModel.connectedPeripheral!)
                }
                
            }
            .tabItem {
                Image(systemName: "wrench.and.s crewdriver")
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
                Text(bluethoothViewModel.connected ? "Connected to \(bluethoothViewModel.carly)" : "Not Connected")
            }
            
            VStack {
                
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTab()
    }
}
