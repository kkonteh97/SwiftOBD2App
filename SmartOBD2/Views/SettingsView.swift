//
//  SettingsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/13/23.
//

import SwiftUI
import Combine
import CoreBluetooth

class SettingsViewModel: ObservableObject {
    @Published var peripherals: [CBPeripheral] = []

    let bleManager: BLEManager
    private var cancellables = Set<AnyCancellable>()


    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        bleManager.$foundPeripherals
            .sink { peripherals in
                self.peripherals = peripherals
            }
            .store(in: &cancellables)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.peripherals, id: \.self) { peripheral in
                    Text(peripheral.name ?? "Unknown")
                }
            }
        }
    }
}

struct ProtocolPicker: View {
    @Binding var selectedProtocol: PROTOCOL

    var body: some View {
        HStack {
            Text("OBD Protocol: ")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Select Protocol", selection: $selectedProtocol) {
                ForEach(PROTOCOL.asArray, id: \.self) { protocolItem in
                    Text(protocolItem.description).tag(protocolItem)
                }
            }
        }
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
    SettingsView(viewModel: SettingsViewModel(bleManager: BLEManager()))
}
