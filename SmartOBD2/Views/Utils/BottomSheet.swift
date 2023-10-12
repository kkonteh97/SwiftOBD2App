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

    @GestureState var gestureOffset: CGFloat = 0

    @Binding var displayType: BottomSheetType

    let maxHeight: CGFloat
    @State private var isLoading = false

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
         maxHeight: CGFloat,
         @ViewBuilder backgroundView: () -> Content
    ) {
        self.viewModel = viewModel
        self.maxHeight = maxHeight
        self._displayType = displayType
        self.backgroundView = backgroundView()
    }

    var body: some View {
        ZStack {
            backgroundView
                .blur(radius: getBlurRadius())

            VStack {
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
