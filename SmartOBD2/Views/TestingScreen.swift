//
//  CarScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth

enum TestingDisplayMode {
    case messages
    case bluetooth
}

struct TestingScreen: View {
    @ObservedObject var viewModel: TestingScreenViewModel
    @State private var history: [History] = []
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCommand: OBDCommand = OBDCommand.mode1(.speed)
    @State private var displayMode = TestingDisplayMode.bluetooth
    @State private var selectedPeripheral: Peripheral?

    var body: some View {
        VStack {
            Picker("Display Mode", selection: $displayMode) {
                Text("Messages").tag(TestingDisplayMode.messages)
                Text("Bluetooth Query").tag(TestingDisplayMode.bluetooth)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)

            switch displayMode {
            case .messages:
                Text("Request History")
                    .font(.system(size: 20))

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ForEach(history, id: \.id) { history in
                            MessageView(message: history)
                        }
                    }
                    .onChange(of: viewModel.lastMessageID) { id in
                        withAnimation{
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }

                if let car = viewModel.garage.currentVehicle {
                    if let supportedPIDs = car.obdinfo.supportedPIDs {
                        HStack {
                            Picker("Select A command", selection: $selectedCommand) {
                                ForEach(supportedPIDs, id: \.self) { pid in
                                    Text(pid.properties.description)
                                        .tag(pid)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
                            })
                        }
                        .padding(.vertical)
                    }
                }

                HStack {
                    TextField("Enter Command", text: $viewModel.command)
                        .padding()
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                        )
                        .defersSystemGestures(on: .vertical)

                    Button {
                        guard !viewModel.command.isEmpty else { return }
                        Task {
                            do {
                                let response = try await viewModel.sendMessage()
                                history.append(History(command: viewModel.command,
                                                       response: response.joined(separator: " "))
                                )
                            } catch {
                                print("Error setting up adapter: \(error)")
                            }
                        }

                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .foregroundColor(.blue)
                            .padding(10)
                            .padding(.horizontal, 5)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                }
                .padding()

        case .bluetooth:
                bluetoothSection
            }
        }
    }

    private var bluetoothSection: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(viewModel.peripherals) { peripheral in
                    PeripheralRow(peripheral: peripheral)
                        .onTapGesture {
                            self.selectedPeripheral = peripheral
                    }
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.startScanning()
        }
        .sheet(item: $selectedPeripheral) { peripheral in
            PeripheralInfo(viewModel: viewModel, peripheral: peripheral)
        }
    }
}

struct PeripheralInfo: View {
    @ObservedObject var viewModel: TestingScreenViewModel
    var peripheral: Peripheral

    var body: some View {
        VStack {
                HStack {
                    Text(peripheral.name)
                    Spacer()
                    if viewModel.connectPeripheral != nil {
                        Button(action: {}) {
                            Text("Disconnect")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .padding()
                        }
                    } else {
                        Button(action: { viewModel.connect(to: peripheral) }) {
                            Text("Connect")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .padding()
                        }
                    }
                }
            if let connectPeripheral = viewModel.connectPeripheral {
                Text("peripheralUUID: \(peripheral.peripheral.identifier.uuidString)")
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(connectPeripheral.services ?? [], id:\.uuid) { service in
                        ServiceRow(viewModel: viewModel, service: service)
                    }
                }
            }
                Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ServiceRow: View {
    @ObservedObject var viewModel: TestingScreenViewModel
    let service: CBService

    var body: some View {
        VStack(alignment: .leading) {
            Text("Service")
                .font(.system(size: 20))

            Text("\(service.uuid)")
                .font(.system(size: 16))

            Divider().background(Color.white).padding(10)
            HStack {
                Text("Characteristics")
                Spacer()
            }
            ForEach(service.characteristics ?? [], id: \.uuid) { characteristic in
                CharacteristicRow(viewModel: viewModel, characteristic: characteristic)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.charcoal)
        }
    }
}

struct CharacteristicRow: View {
    @ObservedObject var viewModel: TestingScreenViewModel
    let characteristic: CBCharacteristic
    @State var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(characteristic.uuid)")
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Properties: ")
                    .font(.system(size: 12))
                Text("[\(propertiesAsString())]")
                    .font(.system(size: 12))
            }
            if let response = response {
                Text("response: \(response)")
                    .font(.system(size: 12))
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: 75)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.charcoal)
        }
        .onTapGesture {
            Task {
                let response = try await viewModel.testCharacteristic(characteristic)
                DispatchQueue.main.async {
                    self.response = response
                }
            }
        }
    }
    // Helper function to convert properties to a readable string
       private func propertiesAsString() -> String {
           var propertiesString = ""
           if characteristic.properties.contains(.read) {
               propertiesString += "Read, "
           }
           if characteristic.properties.contains(.write) {
               propertiesString += "write, "
           }

           if characteristic.properties.contains(.notify) {
               propertiesString += "Notify, "
           }

           // Remove trailing comma and space, if any
           if propertiesString.hasSuffix(", ") {
               propertiesString.removeLast(2)
           }
           return propertiesString
       }
}

struct PeripheralRow: View {
    let peripheral: Peripheral

    var body: some View {
        HStack {
            Text(peripheral.name)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.charcoal)
        }
    }
}

struct History: Identifiable {
    var id = UUID()
    var command: String
    var response: String
}

struct MessageView: View {
    var message: History

    var body: some View {
        HStack{
            Text(message.command)
            Spacer()
            Text(message.response)

        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.charcoal)
        }
    }
}

//struct CarScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        TestingScreen(viewModel: TestingScreenViewModel(obdService: OBDService(), 
//                                                        garage: Garage())
//        )
//    }
//}
