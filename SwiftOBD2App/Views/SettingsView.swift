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

    @EnvironmentObject var obdService: OBDService
    @Environment(\.dismiss) var dismiss
    @Binding var displayType: BottomSheetType

    @Binding var isDemoMode: Bool

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: $isDemoMode)
            VStack {
                List {
                    connectionSection
                        .listRowBackground(Color.clear)

                    displaySection
                        .listRowBackground(Color.darkStart.opacity(0.3))

                    otherSection
                        .listRowSeparator(.automatic)
                        .listRowBackground(Color.darkStart.opacity(0.3))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        displayType = .quarterScreen
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    }
                }
            }
            .gesture(DragGesture().onEnded({
                if $0.translation.width > 100 {
                    displayType = .quarterScreen
                    dismiss()
                }
            }))
        }
    }

    var displaySection: some View {
        Section(header: Text("Display").font(.system(size: 20, weight: .bold, design: .rounded))) {
            Picker("Units", selection: $globalSettings.selectedUnit) {
                ForEach(MeasurementUnits.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
    }

    var connectionSection: some View {
        Section(header: Text("Connection").font(.system(size: 20, weight: .bold, design: .rounded))) {
            Picker("Connection Type", selection: $obdService.connectionType) {
                ForEach(ConnectionType.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .background(Color.darkStart.opacity(0.3))

            switch obdService.connectionType {
            case .bluetooth:
                NavigationLink(destination: Text("Bluetooth Settings")) {
                    Text("Bluetooth Settings")
                }
            case .wifi:
                Text("Wifi Settings")

            case .demo:
                Text("Demo Mode")
            }
        }
        .listRowSeparator(.hidden)

    }

    var otherSection: some View {
        Section(header: Text("Other").font(.system(size: 20, weight: .bold, design: .rounded))) {
            NavigationLink(destination: AboutView()) {
                Text("About")
            }
        }
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
    SettingsView(displayType: .constant(.fullScreen), isDemoMode: .constant(true))
        .environmentObject(GlobalSettings())
}
