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
    case quarterScreen
    case none
}

struct BottomSheet<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: BottomSheetViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isLoading = false

    @GestureState var gestureOffset: CGFloat = 0

    @Binding var displayType: BottomSheetType
    @Binding var selectedCar: Int

    let maxHeight: CGFloat

    private var offset: CGFloat {
        switch displayType {
        case .fullScreen:
            return maxHeight * 0.02
        case .halfScreen:
            return maxHeight * 0.60
        case .quarterScreen:
            return maxHeight * 0.90
        case .none:
            return maxHeight * 1.20
        }
    }

    let backgroundView: Content

    init(
         viewModel: BottomSheetViewModel,
         displayType: Binding<BottomSheetType>,
         selectedCar: Binding<Int>,
         maxHeight: CGFloat,
         @ViewBuilder backgroundView: () -> Content
    ) {
        self.viewModel = viewModel
        self.maxHeight = maxHeight
        self._displayType = displayType
        self._selectedCar = selectedCar
        self.backgroundView = backgroundView()

    }

    var body: some View {
        ZStack {
            backgroundView
                .blur(radius: getBlurRadius())

            VStack {
                BottomSheetContent(
                                   displayType: $displayType,
                                   selectedVehicle: $selectedCar,
                                   viewModel: viewModel,
                                   maxHeight: maxHeight
                )
            }
            .background {
                        Color.pinknew
                                .opacity(0.6)
            }
            .cornerRadius(20)
            .offset(y: max(self.offset + self.gestureOffset, 0))
            .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8,
                                          blendDuration: 0), value: gestureOffset)
            .gesture(
                DragGesture().updating($gestureOffset, body: { value, out, _ in
                out = value.translation.height
            })
            .onEnded({ value in
                let snapDistanceFullScreen = self.maxHeight * 0.60
                let snapDistanceHalfScreen =  self.maxHeight * 0.85
                if value.location.y <= snapDistanceFullScreen {
                    self.displayType = .fullScreen
                } else if value.location.y > snapDistanceFullScreen  &&
                            value.location.y <= snapDistanceHalfScreen {
                    self.displayType = .halfScreen
                } else {
                    self.displayType = .quarterScreen
                }
            }))
            if connectionState != .connectedToVehicle {
                self.connectButton
                    .offset(y: self.offset + self.gestureOffset - maxHeight * 0.6)
                    .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8,
                                                  blendDuration: 0), value: gestureOffset)
                    .opacity(getOpacityRadius())
                    .transition(.opacity)
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
            .background(Color(red: 39/255, green: 110/255, blue: 241/255))
            .mask(
                Circle()
                    .frame(width: 80, height: 80)
            )
            .shadow(radius: shadowRadius)
            .disabled(connectionState == .connectedToVehicle)

            GoButtonAnimation(isLoading: $isLoading)
        }
    }

    private func handleConnectButtonTapped() {
        self.isLoading = true
        Task {
            do {
                try await viewModel.setupAdapter(setupOrder: setupOrder)
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                        self.displayType = .halfScreen
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    // Blur Radius for BG...
    func getOpacityRadius() -> CGFloat {
        let progress = (offset + gestureOffset) / ((UIScreen.main.bounds.height) * 0.50)
        return progress
    }

    func getBlurRadius() -> CGFloat {
        let progress = 1 - (offset + gestureOffset) / (UIScreen.main.bounds.height * 0.50)
        return progress * 30
    }

}

struct CustomCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct BottomSheetPreview: View {
    @State var displayType: BottomSheetType = .none

    var body: some View {
        GeometryReader { proxy in
            BottomSheet(viewModel: BottomSheetViewModel(
                        obdService: OBDService(bleManager: BLEManager()),
                        garage: Garage()),
                        displayType: $displayType,
                        selectedCar: .constant(0),
                        maxHeight: proxy.size.height
            ) {
                Color.blue
            }
        //            .blur(radius: getBlurRadius())
    }
    }
}

#Preview {
    BottomSheetPreview()
}
