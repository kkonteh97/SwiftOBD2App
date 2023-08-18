//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel

    
    var body: some View {
        VStack {
            List {
                ForEach(bluetoothViewModel.history, id: \.self) { value in
                    HStack {
                        Text("\(value)")
                    }
                }
            }
            TextField("Enter Command", text: $bluetoothViewModel.command)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            
            Button(action: {
                bluetoothViewModel.sendMessage(bluetoothViewModel.command)
            }, label: {
                Text("Send")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            .disabled(!bluetoothViewModel.connected)
        }
        
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
