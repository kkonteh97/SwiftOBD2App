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
    
    func sendMessage(_ message: String) async throws -> String  {
        return try await elmManager.sendMessageAsync(message, withTimeoutSecs: 5)
    }
}


struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel // Declare the view model as a property
    @State var command: String = ""
    @State var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATDPN]
    
    @State private var isModalPresented = false
    @State private var newItem: SetupStep = .ATD // New item to add

    
    
    func move(from source: IndexSet, to destination: Int) {
        setupOrder.move(fromOffsets: source, toOffset: destination)
    }
    
    var body: some View {
        VStack {
            Button(action: {
                isModalPresented.toggle()
            }, label: {
                Text("Open Modal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            .sheet(isPresented: $isModalPresented, content: {
                NavigationView {
                    VStack {
                        List {
                            ForEach(setupOrder) { step in
                                Text(step.rawValue.uppercased())
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            .onMove(perform: move)
                            .onDelete(perform: { indexSet in
                                                            setupOrder.remove(atOffsets: indexSet)
                                                        })
                        }
                        .navigationBarItems(trailing: Button("Done", action: {
                            isModalPresented.toggle()
                        }))
                        HStack {
                            Picker("Add Step", selection: $newItem) {
                                ForEach(SetupStep.allCases, id: \.self) { step in
                                    Text(step.rawValue.uppercased())
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Button("Add", action: {
                                setupOrder.append(newItem)
                                newItem = .ATD // Reset the new item for the next addition
                            })
                        }
                        .padding(.horizontal)
                                
                    }
                }
            })
            
            Button(action: {
                Task {
                    do {
                        try await viewModel.setupAdapter(setupOrder: setupOrder)
                    } catch {
                        print("Error setting up adapter: \(error)")
                    }
                }
                
            }, label: {
                Text("Setup")
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
                        let response = try await viewModel.sendMessage(command)
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
        SettingsScreen(viewModel: SettingsScreenViewModel(elmManager: ElmManager.self as! ElmManager))
    }
}
