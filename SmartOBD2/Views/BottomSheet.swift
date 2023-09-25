//
//  BottomSheet.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/21/23.
//

import SwiftUI

enum Constants {
    static let radius: CGFloat = 16
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.1
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidth: CGFloat = 60
    static let maxHeightRatio: CGFloat = 0.9
}

enum BottomSheetType {
    case fullScreen
    case halfScreen
    case none
}

struct BottomSheet: View {
    @GestureState var gestureOffset: CGFloat = 0
    @ObservedObject var viewModel: HomeViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isLoading = false

    @Binding var displayType: BottomSheetType
    let maxHeight: CGFloat

    private var offset: CGFloat {
        switch displayType {
        case .fullScreen :
            return maxHeight * 0.10
        case .halfScreen :
            return maxHeight * 0.60
        case .none :
            return maxHeight * 0.90
        }
    }

    init(viewModel: HomeViewModel,displayType: Binding<BottomSheetType>, maxHeight: CGFloat) {
        self.viewModel = viewModel
        self.maxHeight = maxHeight
        self._displayType = displayType
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    BottomSheetContent(displayType: $displayType, viewModel: viewModel, maxHeight: maxHeight)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .offset(y: max(self.offset + self.gestureOffset, 0))
                .background(.clear)
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, 
                                              blendDuration: 0), value: gestureOffset)
                .gesture(DragGesture().updating($gestureOffset, body: { value, out, _ in
                    out = value.translation.height
                })
                .onEnded({ value in
                    let snapDistanceFullScreen = self.maxHeight * 0.60
                    let snapDistanceHalfScreen =  self.maxHeight * 0.85
                    if value.location.y <= snapDistanceFullScreen {
                        self.displayType = .fullScreen
                    } else if value.location.y > snapDistanceFullScreen  &&  value.location.y <= snapDistanceHalfScreen {
                        self.displayType = .halfScreen
                    } else {
                        self.displayType = .none
                    }
                }))
                
                if viewModel.elm327.bleManager.connectionState != .connectedToVehicle {
                    self.connectButton
                        .offset(y: self.offset + self.gestureOffset - maxHeight * 0.6)
                        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: gestureOffset)
                        .opacity(displayType == .fullScreen ? 0 : 1)
                }
            }
        }
    }

    private var connectButton: some View {
        ZStack {
            Button(action: {
                Task {
                    handleConnectButtonTapped()
                }
            }) {
                if !isLoading {
                    Text("Connect")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(35)
            .background(Color(red:39/255, green:110/255, blue:241/255))
            .mask(
                Circle()
                    .frame(width: 80, height: 80)
            )
            .shadow(radius: shadowRadius)
            .disabled(viewModel.elm327.bleManager.connectionState == .connectedToVehicle)
            GoButtonAnimation(isLoading: $isLoading)
        }
    }


    private func handleConnectButtonTapped() {
        self.isLoading = true
        Task {
            do {
                try await viewModel.setupAdapter(setupOrder: setupOrder)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }


    // Blur Radius for BG...
    func getBlurRadius() -> CGFloat {
        let progress = -offset / (UIScreen.main.bounds.height - 100)
        return progress * 30
    }
}



struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> some UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct CustomCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        GeometryReader { proxy in
            Color.blue
            BottomSheet(viewModel: HomeViewModel(elm327: ELM327(bleManager: BLEManager())),displayType: .constant(.none), maxHeight: proxy.size.height)
        }
        //            .blur(radius: getBlurRadius())
    }
}

//    private var elmSection: some View {
//        GroupBox(label: SettingsLabelView(labelText: "ELM", labelImage: "info.circle")) {
//            Divider().padding(.vertical, 4)
//
//            ProtocolPicker(selectedProtocol: $viewModel.selectedProtocol)
//
//            HStack {
//                Button("Setup Order") {
//                    isSetupOrderPresented.toggle()
//                }
//                .buttonStyle(ShadowButtonStyle())
//                .sheet(isPresented: $isSetupOrderPresented) {
//                    SetupOrderModal(isModalPresented: $isSetupOrderPresented, setupOrder: $setupOrder)
//                }
//            }
//        }
//    }
