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


    @State private var chartContentContainerWidth: CGFloat = .zero
    @State private var yAxisWidth: CGFloat = .zero

    @GestureState private var translation: CGFloat = .zero
    @State private var offset: CGFloat = .zero

    @State var dataItem: DataItem

    init(
         dataItem: DataItem
    ) {
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
                        .offset(x: offset - 300)
                        .offset(x: offset + translation)
                        .gesture(drag)

                    Text("")
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
                .chartYAxis(.hidden)
                .chartYAxis {
                   AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                       AxisGridLine()
           }
       }
    }

    var chart: some View {
        GraphView(dataItem: dataItem)
    }

    var chartYAxis: some View {
          chart
            .foregroundStyle(.clear)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4))
            }
            .chartPlotStyle {
                $0.frame(width: 0)
        }
    }
}

struct GraphView: View {
    @State var dataItem: DataItem
    @State var data: [PIDMeasurement] = []

    @State var upperBound: Double?

    var body: some View {
        chart
    }

    let timer = Timer.publish(
        every: 0.4,
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
//        .onReceive(timer, perform: updateData)
    }

    func updateData(_: Date) {
        let time: Date = Date()
        if dataItem.command.properties.command == "0D" {
            let value = Double.random(in: 0 ... 250)
            let measurement = PIDMeasurement(time: time, value: value)
            data.append(measurement)
        } else {
            let value = Double.random(in: 700 ... 3000)
            let measurement = PIDMeasurement(time: time, value: value)
            data.append(measurement)
        }
    }
}

struct YAxisWidthPreferenceyKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct YAxisWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear.preference(key: YAxisWidthPreferenceyKey.self, value: geometry.size.width)
            }
        )
    }
}

#Preview {
    ScrollChartView(dataItem: DataItem(command: .speed, selectedGauge: .gaugeType1))
}
