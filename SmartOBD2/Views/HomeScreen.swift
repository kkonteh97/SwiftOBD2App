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
           HStack(alignment: .top) {
               Circle()
                   .frame(width: 40, height: 40)
                   .foregroundColor(.pink)
                   .overlay(
                       Image("car")
                           .resizable()
                           .frame(width: 30, height: 30)
                           .foregroundColor(.white)  // Image color
                   )
               
               VStack(alignment: .leading, spacing: 4) {
                   Text("SmartOBD2")
                       .font(.headline)
                       .foregroundColor(colorScheme == .dark ? .white : .black)
                   
                   Text(text)
                       .foregroundColor(colorScheme == .dark ? .white : .black)
               }
               .padding(.leading, 8)
               .background(Color.gray.opacity(0.1))  // Message bubble background color

           }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .cornerRadius(10)
            .onAppear {
                typeWriter()
            }
    }
}

enum Obd2Devices {
    case carlyObd
    var BLE_ELM_SERVICE_CHARACTERISTIC_UUID: Int {
            switch self {
            case .carlyObd:
                return 65505
            }
        }
    
    var BLE_CHARACTERISTIC_DESCRIPTOR_UUID: Int {
            switch self {
            case .carlyObd:
                return 10498
            }
        }
    
    var BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID: Int {
            switch self {
            case .carlyObd:
                return 10790
            }
        }
    
    var BLE_DEVICE_FIRMWARE_UUID: Int {
            switch self {
            case .carlyObd:
                return 6154
            }
        }
    var BLE_ELM_SERVICE_UUID: Int {
            switch self {
            case .carlyObd:
                return 65504
            }
        }
    
}



struct HomeScreen: View {
    @State var typingMessage: String = ""
    @ObservedObject var chatViewModel: ChatViewModel
//    @ObservedObject var bleViewModel: BLEManager
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false // Add this state variable


    
    @State private var shouldAnimateNewMessage = false
    @State private var isToggled = false
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }


    func messageView(message: Message) -> some View {
        
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if message.role == .assistant {
                typeWriterAnimation(finalText: message.content)
                Spacer()
            }
            
        }
    }
    var startColor: Color { Color.startColor(for: colorScheme) }
    var endColor: Color { Color.endColor(for: colorScheme) }
    
    var body: some View {
        ZStack {
            LinearGradient(colorScheme == .dark ? Color.darkStart : Color.lightStart, colorScheme == .dark ? Color.darkEnd : Color.lightEnd)
                .edgesIgnoringSafeArea(.all)
            
            
            VStack {
                ZStack {
                    ScrollView {
                        ForEach(chatViewModel.messages.filter({$0.role != .system}), id:\.id) { message in
                            messageView(message: message)
                                .transition(.move(edge: message.role == .user ? .trailing : .leading))
                        }
                    }
                    VStack {
                        Toggle(isOn: $isToggled) {
                            Text("Start")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(ButtonToggleStyle())
                        
                    }
                    .frame(width: 20, height: 20)
                }
                HStack {
                    TextField("Message...", text: $typingMessage,  axis: .vertical)
                        .font(.system(size: 16))
                        .padding()
                        .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(LinearGradient(startColor))
                                    .shadow(color: Color.darkEnd,  radius: 5, x: -3, y: -3)
                                    .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)

                            )
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                
                    Button  {
                        guard !typingMessage.isEmpty else {
                            return
                        }
                        chatViewModel.sendMessage(message: typingMessage)
                        typingMessage = ""
                        
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .resizable()
                            .frame(width: 29, height: 30)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(LinearGradient(startColor, endColor).opacity(0.5))
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
            .onAppear {
                if !hasAppeared {
                    let text = "Locate the obd port\nPlug in OBD2 Device\nTurn on your car\nPress the Start Button below"
                    let message = Message(id: UUID(), role: .assistant, content: text, createdAt: Date())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        chatViewModel.messages.append(message)
                    }
                    hasAppeared = true

                }
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(chatViewModel: ChatViewModel())
    }
}

struct ButtonBackground<S: Shape>: View {
    var isHighlighted: Bool
    var shape: S
    @Environment(\.colorScheme) var colorScheme
    
    var startColor: Color { Color.startColor(for: colorScheme) }
    var endColor: Color { Color.endColor(for: colorScheme) }
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }


    var body: some View {
        ZStack {
                shape
                    .fill(LinearGradient(isHighlighted ? endColor : startColor, isHighlighted ? startColor : endColor))

                    .shadow(color: shadowColor, radius: 10, x: -10, y: -10)
                    .shadow(color: Color.darkEnd, radius: 10, x: 10, y: 10)
                    .blur(radius: isHighlighted ? 4 : 3)
        }
    }
}
struct ButtonBackground2<S: Shape>: View {
    var isHighlighted: Bool
    var shape: S

    @Environment(\.colorScheme) var colorScheme
    var startColor: Color { Color.startColor(for: colorScheme) }
    var endColor: Color { Color.endColor(for: colorScheme) }
    var shadowColor: Color { colorScheme == .dark ? .darkStart : .lightStart }

    var body: some View {
        ZStack {
            shape
                .fill(LinearGradient(endColor, startColor))
                .shadow(color: shadowColor, radius: 10, x: -10, y: -10)
                .shadow(color: shadowColor, radius: 10, x: 10, y: 10)
                .blur(radius: isHighlighted ? 4 : 3)
        }
    }
}


struct ButtonToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        
        Button(action: {
            configuration.isOn.toggle()
            print("pressed")
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
        }) {
            configuration.label
                .frame(width: 90, height: 90)
                .contentShape(RoundedRectangle(cornerRadius: 45))
        }
        .background(
            ButtonBackground(isHighlighted: configuration.isOn, shape: RoundedRectangle(cornerRadius: 45))
        )
        .animation(Animation.easeOut.speed(2.5), value: configuration.isOn)    
        
    }
}


extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let lightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let lightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)

    static func startColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkStart : .lightStart
    }

    static func endColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkEnd : .lightEnd
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

