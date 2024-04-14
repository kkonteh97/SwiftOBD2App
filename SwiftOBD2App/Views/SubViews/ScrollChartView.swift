//
//  ScrollChartView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/29/23.
//

import SwiftUI
import Charts

struct ScrollChartView: View {
    private let height: CGFloat = 200
    private let pagingAnimationDuration: CGFloat = 0.2

    @State var chartContentContainerWidth: CGFloat = .zero
    @State private var yAxisWidth: CGFloat = .zero

    @GestureState private var translation: CGFloat = .zero
    @State private var offset: CGFloat = .zero

    @State var dataItem: DataItem

    init(dataItem: DataItem) {
        self.dataItem = dataItem
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                withAnimation(.easeOut(duration: pagingAnimationDuration)) {
                    let offset = self.offset + value.translation.width
                    let maxOffset = chartContentContainerWidth - yAxisWidth
                    self.offset = max(0, min(maxOffset, offset))
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    chartContent
                        .frame(width: chartContentContainerWidth * 3, height: height)
                        .offset(x: offset - chartContentContainerWidth)
                        .offset(x: offset + translation)
                        .gesture(drag)
                }
                .frame(width: chartContentContainerWidth)
                .clipped()

                chartYAxis
                    .modifier(YAxisWidthModifier())
                    .onPreferenceChange(YAxisWidthPreferenceyKey.self) { newValue in
                        yAxisWidth = newValue
                        chartContentContainerWidth = geometry.size.width - yAxisWidth
                    }
            }
        }
        .frame(height: height)
    }

    var chartContent: some View {
        chart
            .chartYScale(domain: dataItem.command.properties.minValue ... dataItem.command.properties.maxValue)
            .chartXAxis {
               AxisMarks(
                format: .dateTime.hour().minute(),
                preset: .extended,
                values: .stride(by: .minute, roundLowerBound: true)
               )
           }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                                AxisGridLine()
                }
            }
            .chartPlotStyle {
                $0.background(.blue.opacity(0.1))
            }
    }

    var chart: some View {
        GraphView(dataItem: dataItem,
                  chartContentContainerWidth: $chartContentContainerWidth
        )
    }

    var chartYAxis: some View {
        chart
            .chartYScale(domain: dataItem.command.properties.minValue ... dataItem.command.properties.maxValue)
            .foregroundStyle(.clear)
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic(desiredCount: 6))
            }
            .chartPlotStyle {
                $0.frame(width: 0)
            }
    }
}

struct GraphView: View {
    @State var dataItem: DataItem
    @State var data: [PIDMeasurement] = []
    @Binding var chartContentContainerWidth: CGFloat
    @State var upperBound: Double?

    var body: some View {
        chart
    }

    let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

    private var chart: some View {
        Chart(dataItem.measurements, id: \.id) { dataPoint in
            LineMark(
                x: .value("time", dataPoint.id, unit: .second),
                y: .value("Value", dataPoint.value)
            )
            .lineStyle(StrokeStyle(lineWidth: 2.0))
            .interpolationMethod(.linear)
        }
        .onReceive(timer, perform: updateData)
        .onChange(of: data.count, perform: { _ in
//            chartContentContainerWidth = CGFloat(value) * 10
        })
    }

    private let measurementTimeLimit: TimeInterval = 120 // 10 minutes

    func updateData(_: Date) {
        let time: Date = Date()
        let value = Double.random(in: 0 ... 250)
        let measurement = PIDMeasurement(time: time, value: value)
        data.append(measurement)
        data = data.filter { $0.id.timeIntervalSinceNow > -self.measurementTimeLimit }

    }
}

struct YAxisWidthPreferenceyKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct YAxisWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: YAxisWidthPreferenceyKey.self,
                                    value: geometry.size.width)
            }
        )
    }
}

#Preview {
    ScrollChartView(dataItem: DataItem(command: .mode1(.speed),
                                       selectedGauge: .gaugeType1))
}
