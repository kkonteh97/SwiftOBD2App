//
//  HomeScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI



struct typeWriterAnimation: View {
    @State var text: String = ""
    var finalText: String
    var position = 0
    @Environment(\.colorScheme) var colorScheme

    
    func typeWriter(at position: Int = 0) {
        if position == 0 {
            text = ""
        }
        if position < finalText.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                text.append(finalText[position])
                typeWriter(at: position + 1)
            }
        }
    }
    
    
    var body: some View {
        VStack(spacing: 16.0) {
            Text(text)
                .padding(8)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
        .onAppear {
            typeWriter()
        }
    }
}


struct HomeScreen: View {
    @ObservedObject private var viewModel = ViewModel()
    


    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages.filter({$0.role != .system}), id:\.id) { message in
                    messageView(message: message)
                }
            }
            HStack {
                TextField("message", text: $viewModel.currentMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .cornerRadius(50)
                    .padding(.horizontal)
                Button {
                    viewModel.sendMessage()

                } label: {
                    Image(systemName: "arrow.up.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }

        }
    }
    
    func messageView(message: Message) -> some View {
        
        HStack {
            if message.role == .user {Spacer()}
            Text(message.content)
                .padding(8)
                .foregroundColor(.white)
                .background(message.role == .user ? Color.blue : Color.gray)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                .transition(.opacity)
            
            if message.role == .assistant {Spacer()}
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
