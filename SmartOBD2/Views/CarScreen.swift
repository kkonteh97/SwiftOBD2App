//
//  CarScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI

struct History: Identifiable {
    var id = UUID()
    var command : String
    var response : String
}

struct CarScreen: View {
    @ObservedObject var viewModel: CarScreenViewModel
    @State private var command: String = ""
    @State private var history: [History] = []
    



    var body: some View {
            VStack {
                
                ForEach(history) { history in
                    VStack {
                        HStack {
                            Text(history.command)
                                .font(.system(size: 20))
                            Spacer()
                            Text(history.response)
                                .font(.system(size: 20))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                    }
                }

                
                
                
                TextField("Enter Command", text: $command)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                
                
                Button(action: {
                    Task {
                        do {
                            let response = try await viewModel.sendMessage(command)
                            history.append(History(command: command, response: response))
                        
                        
                            
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
            .padding()
        }
}

struct CarInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 20))
            Spacer()
            Text(value)
                .font(.system(size: 20))
        }
    }
}

struct CarScreen_Previews: PreviewProvider {
    static var previews: some View {
        CarScreen(viewModel: CarScreenViewModel(elmManager: ElmManager.self as! ElmManager))
    }
}
