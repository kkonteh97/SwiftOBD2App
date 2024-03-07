//
//  LiveDataView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine
import SwiftOBD2

enum DataDisplayMode {
    case gauges
    case graphs
}

struct LiveDataView: View {
    @ObservedObject var viewModel = LiveDataViewModel()
    @State private var displayMode = DataDisplayMode.gauges
    @State private var showingSheet = false
    @State var isRequesting: Bool = false
    @State private var enLarge = false
    @State private var selectedPID: DataItem?

    @Namespace var namespace

    @EnvironmentObject var globalSettings: GlobalSettings
    @EnvironmentObject var obdService: OBDService

    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    @Binding var displayType: BottomSheetType
    @Binding var statusMessage: String?
    @Binding var isDemoMode: Bool

    init(displayType: Binding<BottomSheetType>,
         statusMessage: Binding<String?>,
         isDemoMode: Binding<Bool>
    ) {
        self._displayType = displayType
        self._statusMessage = statusMessage
        self._isDemoMode = isDemoMode
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BackgroundView(isDemoMode: $isDemoMode)
            VStack {
                headerButtons
                Picker("Display Mode", selection: $displayMode) {
                    Text("Gauges").tag(DataDisplayMode.gauges)
                    Text("Graphs").tag(DataDisplayMode.graphs)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 20)

                switch displayMode {
                case .gauges:
                    if !enLarge {
                        gaugeView
                    } else {
                        gaugePicker
                    }

                case .graphs:
                    ScrollView(.vertical, showsIndicators: false) {
                        ForEach(viewModel.order, id: \.self) { cmd in
                            if let dataItem = viewModel.data[cmd] {
                                Text(dataItem.command.properties.description +
                                     " " +
                                     String(dataItem.value) +
                                     " " +
                                     (dataItem.unit ?? "")
                                )
                                ScrollChartView(dataItem: dataItem)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            AddPIDView(viewModel: viewModel)
        }
        .onDisappear {
            viewModel.saveDataItems()
        }
    }

    private var gaugeView: some View {
        LazyVGrid(columns: columns) {
            ForEach(viewModel.order, id: \.self) { cmd in
                if let dataItem = viewModel.data[cmd] {
                    GaugeView(dataItem: dataItem,
                              value: dataItem.value,
                              selectedGauge: nil
                    )
                    .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 0.0) {
                        selectedPID = dataItem
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            enLarge.toggle()
                        }
                    }
                }
            }
        }
        .matchedGeometryEffect(id: "Gauge", in: namespace)
    }

    private var gaugePicker: some View {
        GaugePickerView(viewModel: viewModel,
                        enLarge: $enLarge,
                        selectedPID: $selectedPID,
                        namespace: namespace
        )
    }

    private var headerButtons: some View {
        HStack(alignment: .top) {
            Button(action: toggleRequestingPIDs) {
                Text(isRequesting ? "Stop" : "Start").font(.title)
            }
            Spacer()
            Button(action: { showingSheet.toggle() }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }

    private func toggleRequestingPIDs() {
        guard obdService.connectionState == .connectedToVehicle else {
            statusMessage = "Not Connected"
            toggleDisplayType(to: .halfScreen)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    statusMessage = nil
                }
            }
            return
        }
        switch viewModel.isRequesting {
        case true:
            stopRequestingPIDs()
        case false:
            startRequestingPIDs()
        }
    }

    func startRequestingPIDs() {
        guard viewModel.isRequestingPids == false else {
            return
        }
        viewModel.isRequestingPids = true
        toggleDisplayType(to: .none)
        UIApplication.shared.isIdleTimerDisabled = true

        obdService.startContinuousUpdates(viewModel.order)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Finished")
                case .failure(let error):
                    print("Error: \(error)")
                    stopRequestingPIDs()
                }
            }, receiveValue: { measurements in
                updateDataItems(measurements: measurements)
            })
            .store(in: &viewModel.cancellables)
    }

    func updateDataItems(measurements: [OBDCommand: MeasurementResult]) {
        for (pid, measurement) in measurements {
            if let _ = viewModel.data[pid] {
                viewModel.data[pid]?.value = measurement.value
                viewModel.data[pid]?.unit = measurement.unit.symbol
            }
        }
    }

    func stopRequestingPIDs() {
        guard viewModel.isRequestingPids == true else {
            return
        }
        UIApplication.shared.isIdleTimerDisabled = false
        viewModel.isRequestingPids = false
        viewModel.cancellables.removeAll()
        toggleDisplayType(to: .quarterScreen)
    }

    private func toggleDisplayType(to displayType: BottomSheetType) {
        withAnimation(.interactiveSpring(response: 0.5,
                                         dampingFraction: 0.8,
                                         blendDuration: 0)
        ) {
            globalSettings.displayType = displayType
        }
    }
}

#Preview {
    LiveDataView(displayType: .constant(.quarterScreen),
                 statusMessage: .constant(""),
                 isDemoMode: .constant(false))
    .environmentObject(GlobalSettings())
    .environmentObject(OBDService())
}
