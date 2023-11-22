//
//  LiveDataView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

enum DataDisplayMode {
    case gauges
    case graphs
}

struct LiveDataView: View {
    @ObservedObject var viewModel: LiveDataViewModel
    @State private var displayMode = DataDisplayMode.gauges
    @State private var showingSheet = false
    @State var isRequesting: Bool = false

    @State private var enLarge = false

    @State private var selectedPID: DataItem?

    @Binding var displayType: BottomSheetType
    @Namespace var namespace

    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    init(viewModel: LiveDataViewModel, 
         displayType: Binding<BottomSheetType>
    ) {
        self.viewModel = viewModel
        self._displayType = displayType
    }

    var body: some View {
        GeometryReader { geometry in
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
            if viewModel.isRequestingPids {
                viewModel.controlRequestingPIDs(status: false)
                self.displayType = .quarterScreen
                self.isRequesting = false
            } else {
                viewModel.controlRequestingPIDs(status: true)
                self.displayType = .none
                isRequesting = true
            }
        }
}

//                .chartYAxis {
//                    AxisMarks(position: .leading)
//                }


//    let linearGradient = LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0)]),
//                                        startPoint: .top,
//                                        endPoint: .bottom)
//    var body: some View {
//        GroupBox(dataItem.command.properties.description) {
//            Chart {
//                ForEach(data) { data in
//                    LineMark(
//                        x: .value("time", data.timeString),
//                        y: .value("Value", data.value)
//                    )
//                    .lineStyle(StrokeStyle(lineWidth: 2.0))
//                    .interpolationMethod(.cardinal)
//                }
//            }
//            .onReceive(timer, perform: updateData)
//            .chartXAxis(.hidden)
//            .chartYScale(domain: 0 ... dataItem.command.properties.maxValue)
//        }
//    }

#Preview {
    ZStack {
        LiveDataView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                  garage: Garage()), 
                     displayType: .constant(.quarterScreen)
        )
    }
}
