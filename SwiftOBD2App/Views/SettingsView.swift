//
//  SettingsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/13/23.
//

import SwiftUI
import SwiftOBD2

class SettingsViewModel: ObservableObject {

    var garage: Garage

    init(_ garage: Garage) {
        self.garage = garage
    }

    func switchToDemoMode(_ isDemoMode: Bool) {
        garage.switchToDemoMode(isDemoMode)
//        obdService.switchToDemoMode(isDemoMode)
    }
}

struct SettingsView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @State var isDemoMode = false

    var body: some View {
        VStack {
            Spacer()
        }
        .padding()
    }
}


struct ProtocolPicker: View {
    @Binding var selectedProtocol: PROTOCOL

    var body: some View {
        HStack {
            Text("OBD Protocol: ")

            Picker("Select Protocol", selection: $selectedProtocol) {
                ForEach(PROTOCOL.asArray, id: \.self) { protocolItem in
                    Text(protocolItem.description).tag(protocolItem)
                }
            }
        }                
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RoundedRectangleStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.endColor())
            )
    }
}

#Preview {
    SettingsView()
        .environmentObject(GlobalSettings())
}
