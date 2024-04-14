//
//  CustomTabBarView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
//

import SwiftUI
import SwiftOBD2

enum BottomSheetType {
    case fullScreen
    case halfScreen
    case quarterScreen
    case none
}

struct CustomTabBarView<Content: View>: View {
    @State var isLoading = false
    @Binding var displayType: BottomSheetType

    @State var localSelection: TabBarItem
    @State var whiteStreakProgress: CGFloat = 0.0
    @State private var shouldGrow = false

    @Binding var selection: TabBarItem
    @GestureState var gestureOffset: CGFloat = 0
    @Namespace private var namespace

    let maxHeight: CGFloat
    let backgroundView: Content
    let tabs: [TabBarItem]

    @Binding var statusMessage: String?
    @EnvironmentObject var obdService: OBDService
    @EnvironmentObject var garage: Garage

    init(
        tabs: [TabBarItem],
        selection: Binding<TabBarItem>,
        maxHeight: CGFloat,
        displayType: Binding<BottomSheetType>,
        statusMessage: Binding<String?>,
        @ViewBuilder         backgroundView: () -> Content
    ) {
        self.tabs            = tabs
        self._selection      = selection
        self._localSelection = State(initialValue: selection.wrappedValue)
        self.maxHeight       = maxHeight
        self._displayType     = displayType
        self._statusMessage = statusMessage
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
            return maxHeight * 1
        }
    }

    @State private var showAddCarScreen = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView

                if displayType != .none {
                    VStack(spacing: 35) {
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
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
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
                                    displayType = .fullScreen
                                } else if value.location.y > snapDistanceFullScreen  &&
                                            value.location.y <= snapDistanceHalfScreen {
                                    displayType = .halfScreen
                                    if obdService.connectionState == .connectedToVehicle {
                                        animateWhiteStreak()
                                    }
                                } else {
                                    displayType = .quarterScreen
                                }}))
                    if obdService.connectionState != .connectedToVehicle {
                        connectButton
                            .offset(y: self.offset + self.gestureOffset - maxHeight * 0.5)
                            .animation(.interactiveSpring(response: 0.5,
                                                          dampingFraction: 0.8,
                                                          blendDuration: 0),
                                       value: gestureOffset
                            )
                    }
                }
            }
            .navigationDestination(isPresented: $showAddCarScreen) {
                ManuallyAddVehicleView(isPresented: $showAddCarScreen)
            }
            .onAppear {
                if garage.currentVehicle == nil {
                    statusMessage = "No Vehicle Selected"
                }
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
        Button(action: {
                connectButtonAction()
        }) {
            ZStack {
                if !isLoading {
                    Text("START")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.opacity)
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
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
        .buttonStyle(CustomButtonStyle())
        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
    }

    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(width: 80, height: 80)
                .background(content: {
                    Circle()
                        .fill(Color(red: 39/255, green: 110/255, blue: 241/255))
                })
                .scaleEffect(configuration.isPressed ? 1.5 : 1)
                .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
        }
    }

    @MainActor
    private func connectButtonAction() {
        Task {
            guard !isLoading else {
                return
            }
            self.isLoading = true
            let notificationFeedback = UINotificationFeedbackGenerator()
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            notificationFeedback.prepare()
            impactFeedback.impactOccurred()

            var vehicle = garage.currentVehicle ?? garage.newVehicle()

            do {
                self.statusMessage = "Initializing OBD Adapter (BLE)"
                toggleDisplayType(to: .halfScreen)

                vehicle.obdinfo =  try await obdService.startConnection()
                vehicle.obdinfo?.supportedPIDs = await obdService.getSupportedPIDs()

//                if vehicle.make == "None",
//                   let vin = vehicle.obdinfo?.vin,
//                        vin.count > 0,
//                            let vinResults = try? await getVINInfo(vin: vin).Results[0] {
//                    vehicle.make = vinResults.Make
//                    vehicle.model = vinResults.Model
//                    vehicle.year = vinResults.ModelYear
//                } else {
//                    showAddCarScreen = true
//                }

                garage.updateVehicle(vehicle)
                garage.setCurrentVehicle(to: vehicle)

                notificationFeedback.notificationOccurred(.success)
                withAnimation {
                    self.statusMessage = "Connected to Vehicle"
                    self.isLoading = false
                    animateWhiteStreak()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.statusMessage  = nil
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    toggleDisplayType(to: .quarterScreen)
                }

            } catch {
                notificationFeedback.notificationOccurred(.error)
                self.statusMessage = "Error Connecting to Vehicle"
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }

    private func toggleDisplayType(to displayType: BottomSheetType) {
        withAnimation(.interactiveSpring(response: 0.5,
                                         dampingFraction: 0.8,
                                         blendDuration: 0)
        ) {
            self.displayType = displayType
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
                .font(.system(size: 12, weight: .bold, design: .rounded))
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
        .padding(.horizontal)
    }

    private func switchToTab(tab: TabBarItem) {
        selection = tab
    }

    private var carInfoView: some View {
        VStack {
                VStack(alignment: .center) {
                    if let statusMessage =  statusMessage {
                        Text(statusMessage)
                    } else {
                        Text(garage.currentVehicle?.year ?? "")
                        + Text(" ")
                        + Text(garage.currentVehicle?.make ?? "")
                        + Text(" ")
                        + Text(garage.currentVehicle?.model ?? "")
                    }
                }
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

            VStack {
                HStack {
                    Text("VIN" )
                    Spacer()
                    Text(garage.currentVehicle?.obdinfo?.vin ?? "")
                }
                HStack {
                    Text("Protocol")
                    Spacer()
                    Text(garage.currentVehicle?.obdinfo?.obdProtocol?.description ?? "")
                }
                HStack {
                    Text("ELM connection")
                    Spacer()
                    Text(obdService.connectionState == .connectedToAdapter || obdService.connectionState == .connectedToVehicle  ? "Connected" : "disconnected")
                        .foregroundStyle(obdService.connectionState == .connectedToAdapter || obdService.connectionState == .connectedToVehicle ? .green : .red)
                }

                HStack {
                    Text("ECU connection")
                    Spacer()
                    Text(obdService.connectionState == .connectedToVehicle ? "Connected" : "disconnected")
                        .foregroundStyle(obdService.connectionState == .connectedToVehicle ? .green : .red)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 10)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        GeometryReader { proxy in
            CustomTabBarView(tabs: [.dashBoard, .features],
                             selection: .constant(.dashBoard),
                             maxHeight: proxy.size.height,
                             displayType: .constant(.halfScreen),
                             statusMessage: .constant(nil)
            ) {
                BackgroundView(isDemoMode: .constant(false))
            }
            .environmentObject(Garage())
            .environmentObject(OBDService())
        }
    }
}
