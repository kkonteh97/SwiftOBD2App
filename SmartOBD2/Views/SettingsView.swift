//
//  SettingsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/13/23.
//

import SwiftUI

class SettingsViewModel: ObservableObject {

    var obdService: OBDService
    var garage: Garage

    init(_ obdService: OBDService, _ garage: Garage) {
        self.obdService = obdService
        self.garage = garage
    }

    func switchToDemoMode(_ isDemoMode: Bool) {
        garage.switchToDemoMode(isDemoMode)
        obdService.switchToDemoMode(isDemoMode)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var globalSettings: GlobalSettings
    @State var isDemoMode = false

    var body: some View {
        VStack {
            Picker("OBD2 Adapter", selection: $globalSettings.userDevice) {
                ForEach(OBDDevice.allCases.filter { isDemoMode ?  $0 == .mockOBD : $0 != .mockOBD }, id: \.self) { device in
                    Text(device.properties.DeviceName)
                        .tag(device)
                }
            }
            .pickerStyle(.navigationLink)

            Toggle("Demo Mode", isOn: $isDemoMode)
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .onChange(of: isDemoMode) { value in
                    switch value {
                        case true:
                            globalSettings.userDevice = .mockOBD
                        case false:
                            print(isDemoMode)
                    }
                    viewModel.switchToDemoMode(value)

                }
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
    SettingsView(viewModel: SettingsViewModel(OBDService(), Garage()))
        .environmentObject(GlobalSettings())
}
