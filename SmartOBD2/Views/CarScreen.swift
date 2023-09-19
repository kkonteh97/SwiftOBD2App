//
//  CarScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI

struct History: Identifiable {
    var id = UUID()
    var command: String
    var response: String
}

struct CarScreen: View {
    @ObservedObject var viewModel: CarScreenViewModel
    @State private var history: [History] = []
    @Environment(\.colorScheme) var colorScheme
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(history) { history in
                    VStack {
                        Text(history.command)
                            .font(.system(size: 20))
                        Spacer()
                        Text(history.response)
                            .font(.system(size: 20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()

                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Enter Command", text: $viewModel.command)
                        .font(.system(size: 16))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(Color.startColor(for: colorScheme)))
                                .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                                .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)
                        )
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                    Button {
                        guard !viewModel.command.isEmpty else { return }
                        Task {
                            do {
                                print(viewModel.command)
                                let response = try await viewModel.sendMessage()
                                history.append(History(command: viewModel.command,
                                                       response: response.joined(separator: "\n"))
                                )
                                viewModel.command = ""
                            } catch {
                                print("Error setting up adapter: \(error)")
                            }
                        }

                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .resizable()
                            .frame(width: 29, height: 30)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(LinearGradient(Color.startColor(for: colorScheme),
                                                         Color.endColor(for: colorScheme)))
                                    .shadow(color: shadowColor, radius: 5, x: 3, y: 3)
                                    .shadow(color: shadowColor, radius: 5, x: -3, y: -3)
                            )
                    }
                    .padding(.trailing)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }

        }
    }
}

struct CarScreen_Previews: PreviewProvider {
    static var previews: some View {
        CarScreen(viewModel: CarScreenViewModel(elm327: ELM327(bleManager: BLEManager())))

    }
}
