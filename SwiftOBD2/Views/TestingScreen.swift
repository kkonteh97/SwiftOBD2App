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

class TestingScreenViewModel: ObservableObject {
    @Published var lastMessageID: String = ""
}

struct TestingScreen: View {
    @StateObject var viewModel = TestingScreenViewModel()
    @State private var history: [History] = []
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCommand: OBDCommand = OBDCommand.mode6(.MONITOR_O2_B1S1)
    @State private var displayMode = TestingDisplayMode.bluetooth
    @State private var selectedPeripheral: Peripheral?
    @State private var command = ""


    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) var dismiss
    @Binding var displayType: BottomSheetType

    @EnvironmentObject var obd2Service: OBDService
    @EnvironmentObject var garage: Garage

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: .constant(false))
            VStack {
                Picker("Display Mode", selection: $displayMode) {
                    Text("Messages").tag(TestingDisplayMode.messages)
                    Text("Bluetooth Query").tag(TestingDisplayMode.bluetooth)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch displayMode {
                case .messages:
                    messagesSection
                case .bluetooth:
                    bluetoothSection
                }
            }
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
    }

    func sendCommand(command: OBDCommand)  {
        Task {
            do {
                print("Sending Command: \(command.properties.command)")
                let response = try await obd2Service.elm327.sendMessageAsync(command.properties.command)
                print("Response: \(response.joined(separator: " "))")
                let messages = try OBDParcer(response, idBits: 11).messages
                guard let data = messages[0].data else { return }
                let decodedValue = command.properties.decoder.decode(data: data)
                switch decodedValue {
                case .measurementMonitor(let value):
                    for test in value.tests {
//                        print("name: \(String(describing: test.value.name))\nValue: \(test.value.value ?? 0)\nMax: \(String(describing: test.value.max)) \nMin: \(String(describing: test.value.passed))")
                    }
                case .statusResult(let value):
                    print("Status: \(value)")
                default:
                    return
                }
                history.append(History(command: command.properties.command,
                                       response: response.joined(separator: " "))
                )
            } catch {
                print("Error setting up adapter: \(error)")
            }
        }
    }

    private var messagesSection: some View {
        VStack {
            Text("Request History")
                .font(.system(size: 20))

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(history, id: \.id) { history in
                        TestMessageView(message: history)
                    }
                }
                .onChange(of: viewModel.lastMessageID) { id in
                    withAnimation{
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }

                HStack {
                    if let supportedPids =  garage.currentVehicle?.obdinfo.supportedPIDs {
                        Picker("Select A command", selection: $selectedCommand) {
                            ForEach(supportedPids, id: \.self) { pid in
                                Text(pid.properties.description)
                                    .tag(pid)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Spacer()
                    Button {
                        sendCommand(command: selectedCommand)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 30))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical)

                HStack {
                    TextField("Enter Command", text: $command)
                        .keyboardShortcut("m", modifiers: .command)
                        .defersSystemGestures(on: .vertical)
                        .foregroundColor(.black)

                    Button {
                        guard !command.isEmpty else { return }
                        Task {
                            do {
                                let response = try await sendMessage()
                                history.append(History(command: command,
                                                       response: response.joined(separator: " "))
                                )
                            } catch {
                                print("Error setting up adapter: \(error)")
                            }
                        }

                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 30))
                            .fontWeight(.semibold)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 25)
                )
            }
            .font(.system(size: 16))
        }
        .padding()
    }

    func sendMessage() async throws -> [String] {
        let response = try await obd2Service.elm327.sendMessageAsync(command)
            return response
    }

    private var bluetoothSection: some View {
        VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    if let peripherals = obd2Service.foundPeripherals {
                        ForEach(peripherals) { peripheral in
                            PeripheralRow(peripheral: peripheral)
                                .onTapGesture {
                                    self.selectedPeripheral = peripheral
                                }
                        }
                    }
                }
                .sheet(item: $selectedPeripheral) { peripheral in
                    PeripheralInfo(peripheral: peripheral)
                }
                Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
//            viewModel.startScanning()
        }
    }
}

struct PeripheralRow: View {
    let peripheral: Peripheral
    @EnvironmentObject var obd2Service: OBDService

    var body: some View {
        HStack {
            Text(peripheral.name)
            Text(String(peripheral.rssi))
            Spacer()
            Text(obd2Service.connectedPeripheral?.identifier == peripheral.peripheral.identifier ? "Connected" : "Tap to Connect")
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

struct PeripheralInfo: View {
    @State var peripheral: Peripheral
    @EnvironmentObject var obd2Service: OBDService

    var body: some View {
        VStack(alignment: .leading) {
            Text(peripheral.peripheral.name ?? "Unknown Device")
                .font(.system(size: 24, weight: .bold))

            Text("PeripheralUUID: \(peripheral.peripheral.identifier.uuidString)")

            HStack {
                Button("Connect") {
                    obd2Service.bleManager.connect(to: peripheral.peripheral)
                }
                .buttonStyle(.bordered)
                Button("Disconnect") {
                    obd2Service.disconnectPeripheral(peripheral: peripheral)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)

            ScrollView(.vertical, showsIndicators: false) {
                ForEach(peripheral.peripheral.services ?? [], id:\.uuid) { service in
                    ServiceRow(service: service)
                }
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ServiceRow: View {
    let service: CBService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Service: \(service.uuid)")

            Text("Characteristics")
            ForEach(service.characteristics ?? [], id: \.uuid) { characteristic in
                CharacteristicRow(characteristic: characteristic)
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .padding(.vertical)
    }
}

struct CharacteristicRow: View {
    let characteristic: CBCharacteristic
    @State var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(characteristic.uuid)")

                Text("Properties: [\(propertiesAsString())]")

            if let response = response {
                Text("response: \(response)")
            }
        }
        .font(.system(size: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
//        .onTapGesture {
//            Task {
//                let response = try await viewModel.testCharacteristic(characteristic)
//                DispatchQueue.main.async {
//                    self.response = response
//                }
//            }
//        }
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

struct History: Identifiable {
    var id = UUID()
    var command: String
    var response: String
}

struct TestMessageView: View {
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

//class TestingScreenViewModel: ObservableObject {
//
//    let obdService: OBDServiceProtocol
//    let garage: GarageProtocol
//    private var cancellables = Set<AnyCancellable>()
//
//    @Published var command: String = ""
//    @Published var currentVehicle: Vehicle?
//    @Published var isRequestingPids = false
//    @Published var lastMessageID: String = ""
//    @Published var peripherals: [Peripheral] = []
//
//    @Published var connectPeripheral: CBPeripheralProtocol?
//
//    init(_ obdService: OBDServiceProtocol, _ garage: GarageProtocol) {
//        self.obdService = obdService
//        self.garage = garage
//        garage.currentVehiclePublisher
//            .sink { currentVehicle in
//                self.currentVehicle = currentVehicle
//            }
//            .store(in: &cancellables)
//
//        obdService.foundPeripheralsPublisher
//            .sink { peripherals in
//                self.peripherals = peripherals
//            }
//            .store(in: &cancellables)
//
//    }
//
//    func sendMessage() async throws -> [String] {
//        return try await obdService.elm327.sendMessageAsync(command, withTimeoutSecs: 5)
//    }
//
//    func startScanning() {
//        obdService.bleManager.startScanning()
//    }
//
//    func connect(to peripheral: Peripheral) {
//        Task {
//            do {
//                let connectedPeripheral = try await obdService.connect(to: peripheral)
//                print("Connected to to ", connectedPeripheral.name ?? "No Name")
////                let services = try await obdService.elm327.bleManager.discoverServicesAsync(for: connectedPeripheral)
////                for service in services {
////                    print(service)
////                    let characteristics = try await obdService.elm327.bleManager.discoverCharacteristicsAsync(connectedPeripheral, for: service)
////                    for characteristic in characteristics {
////                        print(characteristic)
//////                        if characteristic.uuid.uuidString == "FFF1" {
//////                            let data = try await testCharacteristic(characteristic)
//////                            print("data ", data)
//////                        }
////                    }
////                }
//
//                DispatchQueue.main.async {
//                    self.connectPeripheral = connectedPeripheral
//                }
//
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//
//    func testCharacteristic(_ characteristic: CBCharacteristic) async throws -> String {
//        let data = try await obdService.bleManager.sendMessageAsync("ATZ", characteristic: characteristic)
//        print("here ", data)
//        return data.joined(separator: " ")
//    }
//
//    func requestPid(_ command: OBDCommand) {
//        guard !isRequestingPids else {
//            return
//        }
//        isRequestingPids = true
//        Task {
//            do {
//                let messages = try await obdService.elm327.requestPIDs([command])
//                guard !messages.isEmpty else {
//                    return
//                }
//                guard let data = messages[0].data else {
//                    return
//                }
//                print(data.compactMap { String(format: "%02X", $0) }.joined(separator: " "))
//                let decodedValue = command.properties.decoder.decode(data: data[1...])
//                switch decodedValue {
//                    //            case .measurementMonitor(let measurement):
//                    //                print(measurement.tests)
//                case .measurementResult(let status):
//                    print(status.value)
//                case .stringResult(let status):
//                    print(status)
//
//                case .statusResult(let status):
//                    print(status)
//
//                default :
//                    print("Not a measurement monitor")
//                }
//                DispatchQueue.main.async {
//                    self.isRequestingPids = false
//                }
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//}

#Preview {
        TestingScreen(viewModel: TestingScreenViewModel(), displayType: .constant(.quarterScreen))
        .environmentObject(GlobalSettings())
        .environmentObject(OBDService())
        .environmentObject(Garage())
}
