//
//  SettingsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/13/23.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var userDevice: OBDDevice = .carlyOBD {
        didSet {
            obdService.userDevice = userDevice
        }
    }

    private var cancellables = Set<AnyCancellable>()
    var obdService: OBDService

    init(obdService: OBDService) {
        self.obdService = obdService
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var globalSettings: GlobalSettings

    var body: some View {
        VStack {
            Picker("OBD2 Adapter", selection: $viewModel.userDevice) {
                ForEach(OBDDevice.allCases.filter { $0 != .mockOBD }, id: \.self) { device in
                        Text(device.properties.DeviceName)
                            .tag(device)
                }
            }
            .pickerStyle(.navigationLink)

            Toggle("Demo Mode", isOn: $viewModel.obdService.isDemoMode)
                .toggleStyle(SwitchToggleStyle(tint: .red))

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
    SettingsView(viewModel: SettingsViewModel(obdService: OBDService()))
        .environmentObject(GlobalSettings())
}
