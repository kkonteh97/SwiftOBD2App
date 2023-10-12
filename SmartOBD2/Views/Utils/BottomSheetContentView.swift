//
//  BottomSheetContentView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/21/23.
//

import SwiftUI

// struct BottomSheetContent: View {
//    @Binding var displayType: BottomSheetType
//
//    @ObservedObject var viewModel: BottomSheetViewModel
//
//    @State private var isExpandedCarInfo = false
//    @State private var isExpandedOtherCars = false
//
//    @Environment(\.colorScheme) var colorScheme
//
//    var maxHeight: CGFloat // Height of the content section
//
//    func displayToggle() {
//        switch displayType {
//        case .quarterScreen:
//            displayType = .halfScreen
//        case .halfScreen:
//            displayType = .fullScreen
//        case .fullScreen:
//            displayType = .quarterScreen
//        case .none:
//            displayType = .quarterScreen
//        }
//    }
//
//    private var indicator: some View {
//        VStack {
//            RoundedRectangle(cornerRadius: Constants.radius)
//                .fill(Color.secondary)
//                .frame(
//                    width: Constants.indicatorWidth,
//                    height: Constants.indicatorHeight
//                )
//        }.onTapGesture {
//            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
//                displayToggle()
//            }
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            VStack {
//                self.indicator
//                    .padding(10)
//            }
//            .frame(maxWidth: .infinity, maxHeight: (maxHeight * 0.1))
//            .padding()
//        }
//    }
// }
//
// #Preview {
//    ZStack {
//        GeometryReader { proxy in
//            BottomSheetContent(displayType: .constant(.quarterScreen),
//                               viewModel: BottomSheetViewModel(obdService: OBDService(bleManager: BLEManager()),
//                                                               garage: Garage(selectedCarId: .constant(0)), selectVehicleId: .constant(0)),
//                               maxHeight: proxy.size.height
//            )
//        }
//    }
// }

// struct ShadowButtonStyle: ButtonStyle {
//    @Environment(\.colorScheme) var colorScheme
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.headline)
//            .frame(width: 170, height: 50)
//            .background(
//                RoundedRectangle(cornerRadius: 25)
//                    .fill(LinearGradient(.startColor(), .endColor()))
//                    .shadow(color: .endColor(), radius: 5, x: -3, y: -3)
//                    .shadow(color: .startColor(), radius: 5, x: 3, y: 3)
//            )
//    }
// }
