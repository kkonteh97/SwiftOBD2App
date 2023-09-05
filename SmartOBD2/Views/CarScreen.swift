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
    @Environment(\.colorScheme) var colorScheme
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }


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

                
                
                HStack {
                    
                    TextField("Enter Command", text: $command)
                        .font(.system(size: 16))
                        .padding()
                        .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(LinearGradient(Color.startColor(for: colorScheme)))
                            .shadow(color: Color.darkEnd,  radius: 5, x: -3, y: -3)
                            .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)

                                                    )
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                    
                    
                    Button {
                        guard !command.isEmpty else { return }
                        Task {
                            do {
                                let response = try await viewModel.sendMessage(command)
                                history.append(History(command: command, response: response))
                                
                            } catch {
                                print("Error setting up adapter: \(error)")
                            }
                        }
                        self.command = ""
                        
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .resizable()
                            .frame(width: 29, height: 30)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(
                               Circle()
                                .fill(LinearGradient(Color.startColor(for: colorScheme), Color.endColor(for: colorScheme)))
                           .shadow(color: shadowColor, radius: 5, x: 3, y: 3)
                           .shadow(color: shadowColor, radius: 5, x: -3, y: -3)
                           )
                    }
                    .padding(.trailing)
                }
                .frame(minHeight: CGFloat(50))
                .padding()
                .background(Color.gray.opacity(0.1))
            }
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
        CarScreen(viewModel: CarScreenViewModel(elmManager: ELM327()))
    
    }
}
