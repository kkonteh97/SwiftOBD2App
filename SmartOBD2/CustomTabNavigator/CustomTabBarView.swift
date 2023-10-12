//
//  CustomTabBarView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
//

import SwiftUI
import Combine

struct CustomTabBarView<Content: View>: View {
    @ObservedObject var viewModel: BottomSheetViewModel

    @State private var isLoading = false
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State var localSelection: TabBarItem
    @State private var whiteStreakProgress: CGFloat = 0.0
    @State private var showConnectedText = false

    @Binding var selection: TabBarItem
    @Binding var displayType: BottomSheetType

    @GestureState var gestureOffset: CGFloat = 0
    @Namespace private var namespace

    private var cancellables = Set<AnyCancellable>()

    let maxHeight: CGFloat
    let backgroundView: Content
    let tabs: [TabBarItem]

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    init(
        tabs: [TabBarItem],
        viewModel: BottomSheetViewModel,
        selection: Binding<TabBarItem>,
        displayType: Binding<BottomSheetType>,
        maxHeight: CGFloat,
        @ViewBuilder         backgroundView: () -> Content
    ) {
        self.viewModel       = viewModel
        self.tabs            = tabs
        self._selection      = selection
        self._displayType    = displayType
        self._localSelection = State(initialValue: selection.wrappedValue)
        self.maxHeight       = maxHeight
        self.backgroundView  = backgroundView()
    }

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

    private func handleConnectButtonTapped() {
        self.isLoading = true
        Task {
            do {
                try await viewModel.setupAdapter(setupOrder: setupOrder)
                DispatchQueue.main.async {
                    self.showConnectedText = true
                    withAnimation {
                        self.isLoading = false
                        self.displayType = .halfScreen
                        connectionState = .initailized
                        self.animateWhiteStreak()
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.showConnectedText = false
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8,
                                                     blendDuration: 0)) {
                        self.displayType = .quarterScreen
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 0) {
                tabBar
                    .onChange(of: selection, perform: { value in
                        withAnimation(.easeInOut) {
                            localSelection = value
                    }})
                    .frame(maxHeight: maxHeight * 0.1)

                carInfoView
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity, maxHeight: maxHeight * 0.4 - maxHeight * 0.1)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                Color.raisinblack
            }
            .cornerRadius(10)
            .offset(y: max(self.offset + self.gestureOffset, 0))
            .animation(.interactiveSpring(
                response: 0.5,
                dampingFraction: 0.8,
                blendDuration: 0),
                       value: gestureOffset
            )
            .gesture(
                DragGesture()
                    .updating($gestureOffset, body: { value, out, _ in
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

            if connectionState != .initailized {
                ConnectButton(color: Color(red: 39/255, green: 110/255, blue: 241/255),
                              text: "Connect",
                              isLoading: $isLoading
                ) {
                    handleConnectButtonTapped()
                }
                .offset(y: self.offset + self.gestureOffset - maxHeight * 0.5)
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8,
                                              blendDuration: 0), value: gestureOffset)
                .transition(.move(edge: .bottom))
            }

        }
    }
}

extension CustomTabBarView {
    private func tabView(tab: TabBarItem) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(localSelection == tab ? tab.color : .gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rect", in: namespace)
                }
            }
        )
    }

    private var tabBar: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                tabView(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(.top, 30)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
        .padding(.horizontal)
    }

    private func switchToTab(tab: TabBarItem) {
        selection = tab
    }

    private func animateWhiteStreak() {
        withAnimation(.linear(duration: 2.0)) {
            self.whiteStreakProgress = 1.0 // Animate to 100%
        }
    }

    private var carInfoView: some View {
        VStack {
            HStack(spacing: 20) {
                if let car =  viewModel.currentVehicle {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .center, spacing: 10) {
                            if !showConnectedText {
                                Text(car.year + " " + car.make + " " + car.model)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .fontWeight(.bold)
                            } else {
                                Text("Connected to Vehicle")
                                       .font(.system(size: 22, weight: .bold, design: .rounded))
                                       .fontWeight(.bold)
                                       .foregroundColor(.green)

                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(content: {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .trim(from: 0, to: whiteStreakProgress)
                                            .stroke(
                                                AngularGradient(
                                                    gradient: .init(colors: [.green]),
                                                    center: .center,
                                                    startAngle: .zero,
                                                    endAngle: .degrees(360)
                                                ),
                                                style: StrokeStyle(lineWidth: 1, lineCap: .round)
                                            )
                                    )
                            })

                            Text("Protocol \n" + (car.obdinfo?.obdProtocol.description ?? "Unknown"))
                                .font(.caption)

                            Text("VIN \n" + car.vin)
                                .font(.caption)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

            }
        }
    }
}

#Preview {
    GeometryReader { proxy in
        CustomTabBarView(tabs: [.dashBoard, .features],
                         viewModel: BottomSheetViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                         garage: Garage()),
                         selection: .constant(.dashBoard),
                         displayType: .constant(.halfScreen),
                         maxHeight: proxy.size.height
        ) {
            Color.blue
        }
    }
}
