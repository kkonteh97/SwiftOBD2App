//
//  GaugePickerView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/29/23.
//

import SwiftUI

enum GaugeType: String, CaseIterable, Identifiable, Codable {
    case gaugeType1
    case gaugeType2
    case gaugeType3
    case gaugeType4
    // Add more gauge types as needed
    var id: Int {
        switch self {
        case .gaugeType1:
            0
        case .gaugeType2:
            1
        case .gaugeType3:
            2
        case .gaugeType4:
            3
        }
    }
}

struct GaugePickerView: View {
    @ObservedObject var viewModel: LiveDataViewModel
    @Binding var enLarge: Bool

    @Binding var selectedPID: DataItem?
    var namespace: Namespace.ID?

    @State private var currentIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.7
            let cardHeight = cardWidth * 1.5

            VStack {
                if let dataItem = selectedPID {
                    ZStack {
                        ForEach(GaugeType.allCases, id: \.self) { gaugeType in
                            GaugeView(
                                dataItem: dataItem,
                                value: dataItem.value,
                                selectedGauge: gaugeType
                            )
                            .frame(width: cardWidth, height: cardHeight)
                            .offset(x: CGFloat(gaugeType.id - currentIndex) * (geometry.size.width * 0.6))
                            .background(Color.clear)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let cardWidth = geometry.size.width * 0.3
                                let offset = value.translation.width / cardWidth

                                withAnimation(.spring()) {
                                    if value.translation.width < -offset {
                                        currentIndex = min(currentIndex + 1, GaugeType.allCases.count - 1)
                                    } else if value.translation.width > offset {
                                        currentIndex = max(currentIndex - 1, 0)
                                    }
                                }
                            }
                    )

                    Button {
                        viewModel.data[dataItem.command]?.selectedGauge = GaugeType.allCases[currentIndex]
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            enLarge.toggle()
                        }
                    } label : {
                        Text("Exit")
                            .font(.caption)
                    }
                } else {
                    EmptyView() // Display an empty view when selectedGauge is nil
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .matchedGeometryEffect(id: "Gauge", in: namespace ?? Namespace().wrappedValue)
        }
    }
}

struct GaugeView: View {
    @State var dataItem: DataItem
    var value: Double

    var selectedGauge: GaugeType? = nil

    var body: some View {
        gaugeView(for: selectedGauge ?? dataItem.selectedGauge ?? .gaugeType2)
    }

    @ViewBuilder
    func gaugeView(for gaugeType: GaugeType) -> some View {
        switch gaugeType {
        case .gaugeType1:
            GaugeType1(dataItem: dataItem, value: value)
        case .gaugeType2:
            GaugeType2(dataItem: dataItem, value: value)
        case .gaugeType3:
            GaugeType3(dataItem: dataItem, value: value)
        case .gaugeType4:
            GaugeType4(dataItem: dataItem, value: value)
        }
    }
}

struct GaugeType1: View {
    @State var dataItem: DataItem
    var value: Double

    var body: some View {
        CustomGaugeView(
            coveredRadius: 280,
            maxValue:  dataItem.command.properties.maxValue,
            steperSplit: dataItem.command.properties.steperSplit,
            value: $dataItem.value
        )
    }
}

struct GaugeType2: View {
    @State var dataItem: DataItem
    var value: Double

    var body: some View {
        Gauge(value: value,
              in: 0...Double(dataItem.command.properties.maxValue)
        ) {
            Text( dataItem.command.properties.description)
                .font(.caption)
        } currentValueLabel: {
            Text(String(dataItem.value) + " " + (dataItem.unit ?? ""))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct GaugeType3: View {
    @State var dataItem: DataItem
    var value: Double

    var body: some View {
        Gauge(value: dataItem.value, in: 0...Double(dataItem.command.properties.maxValue)) {
            Text(dataItem.command.properties.description)
                .font(.caption)
        } currentValueLabel: {
            Text(String(dataItem.value) + " " + (dataItem.unit ?? ""))
        }
        .gaugeStyle(.linearCapacity)
        .frame(width: 200)
    }
}

struct GaugeType4: View {
    @State var dataItem: DataItem
    var value: Double

    var body: some View {
        Gauge(value: value , in: 0...Double( dataItem.command.properties.maxValue)) {
            Image(systemName: "gauge.medium")
                .font(.system(size: 50.0))
        } currentValueLabel: {
            Text(String(dataItem.value) + " " + (dataItem.unit ?? ""))
        }
        .gaugeStyle(SpeedometerGaugeStyle())
    }
}

struct SpeedometerGaugeStyle: GaugeStyle {
    private var purpleGradient = LinearGradient(gradient: Gradient(colors: [ Color(red: 207/255, green: 150/255, blue: 207/255), Color(red: 107/255, green: 116/255, blue: 179/255) ]), startPoint: .trailing, endPoint: .leading)

    func makeBody(configuration: Configuration) -> some View {
        ZStack {

            Circle()
                .foregroundColor(Color(.systemGray6))

            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(purpleGradient, lineWidth: 20)
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineCap: .butt, lineJoin: .round, dash: [1, 34], dashPhase: 0.0))
                .rotationEffect(.degrees(135))

            VStack {
                configuration.currentValueLabel
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Text("KM/H")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.gray)
            }

        }
        .frame(width: 175, height: 175)

    }
}

#Preview {
    GaugePickerView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                 garage: Garage()),
                    enLarge: .constant(false),
                    selectedPID: .constant(nil),
                    namespace: nil
    )
}
