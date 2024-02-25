//
//  CustomTabBarView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
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

struct CustomTabBarView<Content: View>: View {
    @ObservedObject var viewModel: CustomTabBarViewModel
    @State var isLoading = false

    @State var localSelection: TabBarItem
    @State var whiteStreakProgress: CGFloat = 0.0
    @State private var shouldGrow = false

    @Binding var selection: TabBarItem
    @EnvironmentObject var globalSettings: GlobalSettings
    @GestureState var gestureOffset: CGFloat = 0
    @Namespace private var namespace

    let maxHeight: CGFloat
    let backgroundView: Content
    let tabs: [TabBarItem]

    var garageVehicles: [Vehicle] {
        viewModel.garageVehicles
    }

    init(
        tabs: [TabBarItem],
        viewModel: CustomTabBarViewModel,
        selection: Binding<TabBarItem>,
        maxHeight: CGFloat,
        @ViewBuilder         backgroundView: () -> Content
    ) {
        self.viewModel       = viewModel
        self.tabs            = tabs
        self._selection      = selection
        self._localSelection = State(initialValue: selection.wrappedValue)
        self.maxHeight       = maxHeight
        self.backgroundView  = backgroundView()
    }

    private var offset: CGFloat {
        switch globalSettings.displayType {
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

    var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 40) {
                tabBar
                    .frame(maxHeight: maxHeight * 0.1)
                    .onChange(of: selection, perform: { value in
                        withAnimation(.easeInOut) {
                            localSelection = value
                    }})

                carInfoView
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, maxHeight: maxHeight * 0.4 - maxHeight * 0.1)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background { Color.raisinblack }
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
                out = value.translation.height})
            .onEnded({ value in
                let snapDistanceFullScreen = self.maxHeight * 0.60
                let snapDistanceHalfScreen =  self.maxHeight * 0.85
                if value.location.y <= snapDistanceFullScreen {
                    globalSettings.displayType = .fullScreen
                } else if value.location.y > snapDistanceFullScreen  &&
                            value.location.y <= snapDistanceHalfScreen {
                    globalSettings.displayType = .halfScreen
                    if viewModel.connectionState == .connectedToVehicle {
                        animateWhiteStreak()
                    }
                } else {
                    globalSettings.displayType = .quarterScreen
            }}))

            if viewModel.connectionState != .connectedToVehicle  {
                connectButton
                    .offset(y: self.offset + self.gestureOffset - maxHeight * 0.5)
                    .animation(.interactiveSpring(response: 0.5, 
                                                  dampingFraction: 0.8,
                                                  blendDuration: 0), 
                               value: gestureOffset
                )
            }
        }
        .onAppear {
            if viewModel.currentVehicle == nil {
                globalSettings.statusMessage = "No Vehicle Selected"
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

extension CustomTabBarView {
    private var connectButton: some View {
        ZStack {
            Button(action: {
                connectButtonAction()
            }) {
                if !isLoading {
                    Text("START")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(35)
            .background(Color(red: 39/255, green: 110/255, blue: 241/255))
            .mask(
                Circle()
                    .frame(width: 80, height: 80)
            )
            .shadow(radius: 5)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                Ellipse()
                    .foregroundColor(Color.clear)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .scaleEffect(shouldGrow ? 1.5 : 1.0)
                            .opacity(shouldGrow ? 0.0 : 1.0)
                    )
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            self.shouldGrow = true
                    }
                }
            }
        }
    }

    private func connectButtonAction() {
        guard !isLoading else {
            return
        }
        self.isLoading = true
        toggleDisplayType(to: .halfScreen)
        Task {
            do {
                try await viewModel.setupAdapter(setupOrder: viewModel.setupOrder, device: globalSettings.userDevice)
                DispatchQueue.main.async {
                    globalSettings.statusMessage = "Connected to Vehicle"
                    globalSettings.showAltText = true
                    withAnimation {
                        self.isLoading = false
                        animateWhiteStreak()
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        globalSettings.showAltText  = false
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    toggleDisplayType(to: .quarterScreen)
                }
            } catch OBDServiceError.noVehicleSelected {
                DispatchQueue.main.async {
                    globalSettings.statusMessage = "Add A Vehicle In Garage"
                    withAnimation {
                        self.isLoading = false
                    }
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    globalSettings.statusMessage = "Error Connecting to Vehicle"
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        }
    }

    private func toggleDisplayType(to displayType: BottomSheetType) {
        withAnimation(.interactiveSpring(response: 0.5,
                                         dampingFraction: 0.8,
                                         blendDuration: 0)
        ) {
            globalSettings.displayType = displayType
        }
    }

    func animateWhiteStreak() {
        withAnimation(.linear(duration: 2.0)) {
            self.whiteStreakProgress = 1.0 // Animate to 100%
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

    private var carInfoView: some View {
        HStack(spacing: 20) {
            if let car =  viewModel.currentVehicle {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(globalSettings.showAltText ? globalSettings.statusMessage : car.year + " " + car.make + " " + car.model)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .fontWeight(.bold)
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

                    Text("VIN: " + (car.obdinfo.vin ?? "No Vin"))
                            .font(.caption)

                    Text("Protocol: " + (car.obdinfo.obdProtocol?.description ?? "Unknown"))
                            .font(.caption)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(globalSettings.statusMessage)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .fontWeight(.bold)
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

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    ZStack {
        GeometryReader { proxy in
            CustomTabBarView(tabs: [.dashBoard, .features],
                             viewModel: CustomTabBarViewModel(OBDService(), Garage()),
                             selection: .constant(.dashBoard),
                             maxHeight: proxy.size.height
            ) {
                Color.blue
            }
            .environmentObject(GlobalSettings())
        }
    }
}
