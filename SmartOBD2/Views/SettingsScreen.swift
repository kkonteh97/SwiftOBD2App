//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth

enum SetupStep: String, CaseIterable, Identifiable {
    case ATD
    case ATZ
    case ATL0
    case ATE0
    case ATH1
    case ATAT1
    case ATSTFF
    case ATDPN
    case ATSP0
    case ATSP1
    case ATSP2
    case ATSP3
    case ATSP4
    case ATSP5
    case ATSP6
    case ATSP7
    case ATSP8
    case ATSP9
    case ATSPA
    case ATSPB
    case ATSPC
    var id: String { self.rawValue }
}

enum PROTOCOL: String {
    case
    P0 = "0",
    P1 = "1",
    P2 = "2",
    P3 = "3",
    P4 = "4",
    P5 = "5",
    P6 = "6",
    P7 = "7",
    P8 = "8",
    P9 = "9",
    PA = "A",
    PB = "B",
    PC = "C",
    NONE = "None"
    
    static let asArray: [PROTOCOL] = [P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, PA, PB, PC, NONE]
    
    func nextProtocol() -> PROTOCOL{
        switch self {
        case .PC:
            return .PB
        case .PB:
            return .PA
        case .PA:
            return .P9
        case .P9:
            return .P8
        case .P8:
            return .P7
        case .P7:
            return .P6
        case .P6:
            return .P5
        case .P5:
            return .P4
        case .P4:
            return .P3
        case .P3:
            return .P2
        case .P2:
            return .P1
        case .P1:
            return .P0
        default:
            return .NONE
        }
    }
}

class SettingsScreenViewModel: ObservableObject {
    @Published var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATDPN]

    var BLE_ELM_SERVICE_UUID = CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)
    var BLE_ELM_CHARACTERISTIC_UUID = CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID)
    
    let bleManager: BLEManager
    
    var obdProtocol: PROTOCOL = .NONE

    init(bleManager: BLEManager) {
            self.bleManager = bleManager
    }
    
    func sendMessageAsync(message: String) async throws -> String {
            return try await bleManager.sendMessageAsync(message: message)
    }
    
    enum SetupError: Error {
        case invalidResponse
    }
    
    
    func successfullResponse(message: String) async throws -> String {
        let response = try await bleManager.sendMessageAsync(message: message)
        if response.contains("OK") {
            return response
        } else {
            throw SetupError.invalidResponse
        }
    }
    
    
    func setupAdapter(setupOrder: [SetupStep]) async throws {
        var setupOrderCopy = setupOrder
        var currentIndex = 0 // Track the current index

        while currentIndex < setupOrderCopy.count {
            let step = setupOrderCopy[currentIndex]
            do {
                switch step {
                case .ATD:
                    _ = try await successfullResponse(message: "ATD")
                case .ATZ:
                    // Response to ATZ Command is the Device Info
                    _ = try await sendMessageAsync(message: "ATZ")
                case .ATL0:
                    _ = try await successfullResponse(message: "ATL0")
                case .ATE0:
                    _ = try await successfullResponse(message: "ATE0")
                case .ATH1:
                    _ = try await successfullResponse(message: "ATH1")

                case .ATAT1:
                    _ = try await successfullResponse(message: "ATAT1")

                case .ATSTFF:
                    _ = try await successfullResponse(message: "ATSTFF")
                case .ATDPN:
                    // gets the current protocol number need echo off
                    let currentProtocol = try await sendMessageAsync(message: "ATDPN")
                    if let setupStep = SetupStep(rawValue: "ATSP\(currentProtocol)") {
                        print("here")
                       setupOrderCopy.append(setupStep)
                    }
                    
                case .ATSP0, .ATSP1, .ATSP2, .ATSP3, .ATSP4, .ATSP5, .ATSP6, .ATSP7, .ATSP8, .ATSP9, .ATSPA, .ATSPB, .ATSPC:
                    do {
                        _ = try await successfullResponse(message: step.rawValue)
                        try await testProtocol()
                    } catch {
                        obdProtocol = obdProtocol.nextProtocol()
                        if let setupStep = SetupStep(rawValue: "ATSP\(obdProtocol.rawValue)") {
                            
                           setupOrderCopy.append(setupStep)
                        }
                    }
                }
            } catch {
                throw error
            }
            currentIndex += 1 // Move to the next index
        }
    }
    
//    func appendProtocolSetupSteps(obdProtocol: PROTOCOL) throws {
//        switch obdProtocol {
//        case .NONE:
//            // Skip appending steps for the "None" protocol
//            break
//        default:
//
//        }
//    }

    func testProtocol() async throws {
        do {
            let response = try await sendMessageAsync(message: "0100")
            print(response)
        } catch {
            throw error  // Propagate the error if the test fails
        }
    }
    
    func getProtocol()  async throws {
        
        do {
            let currentProtocol = try await sendMessageAsync(message: "ATDPN")
            obdProtocol = PROTOCOL(rawValue: currentProtocol) ?? .P6
        } catch {
            throw error
        }
    }
}

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel // Declare the view model as a property
    @State var command: String = ""
    @State var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATDPN]

    
    func move(from source: IndexSet, to destination: Int) {
            viewModel.setupOrder.move(fromOffsets: source, toOffset: destination)
    }
    
    var body: some View {
        VStack {
               List {
                ForEach(setupOrder) { step in
                    Text(step.rawValue.uppercased())
                        .font(.title)
                        .foregroundColor(.blue)
                        
                }
                .onMove(perform: move)
            }
            Button(action: {
                Task {
                        do {
                            try await viewModel.setupAdapter(setupOrder: setupOrder)
                        } catch {
                            print("Error setting up adapter: \(error)")
                        }
                    }
                
                self.command = ""
                
            }, label: {
                Text("Send")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            TextField("Enter Command", text: $command)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            
            Button(action: {
                Task {
                    do {
                        let response = try await viewModel.sendMessageAsync(message: command)
                        print(response)

                    } catch {
                        print("Error setting up adapter: \(error)")
                    }
                }
                
                self.command = ""
                
            }, label: {
                Text("Send")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
//            .disabled(!viewModel.adapterReady)
        }
        
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen(viewModel: SettingsScreenViewModel(bleManager: BLEManager(serviceUUID: CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID), characteristicUUID: CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID))))
    }
}
