//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth

class SettingsScreenViewModel: ObservableObject {
    let elmManager: ElmManager
        
    init(elmManager: ElmManager) {
        self.elmManager = elmManager
    }
    func setupAdapter(setupOrder: [SetupStep]) async throws {
        do {
            try await elmManager.setupAdapter(setupOrder: setupOrder)
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
            setupOrder.move(fromOffsets: source, toOffset: destination)
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
//                Task {
//                    do {
////                        let response = try await viewModel.sendMessageAsync(message: command)
////                        print(response)
//
//                    } catch {
//                        print("Error setting up adapter: \(error)")
//                    }
//                }
                
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
        SettingsScreen(viewModel: SettingsScreenViewModel(elmManager: ElmManager.self as! ElmManager))
    }
}
