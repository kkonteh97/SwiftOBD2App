//
//  GuageView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/17/23.
//

import SwiftUI

struct GaugeConstants {
    static let gaugeSize: CGSize = CGSize(width: 150, height: 150) // Adjust the size of the gauge view
    static let needleSize: CGSize = CGSize(width: 70, height: 3.5) // Adjust the size of the needle
    static let tickWidthSmall: CGFloat = 1.5 // Adjust the width of the small tick
    static let tickWidthBig: CGFloat = 2.5 // Adjust the width of the big tick
    static let tickHeightSmall: CGFloat = 5 // Adjust the height of the small tick
    static let tickHeightBig: CGFloat = 10 // Adjust the height of the big tick
    static let circleSize: CGSize = CGSize(width: 10, height: 10) // Adjust the size of the circle
}

struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height/2))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        return path
    }
}

struct GaugeView: View {
    let coveredRadius: Double
    let maxValue: Int
    let steperSplit: Int

    @Binding var value: Double

    private var tickCount: Int {
        return maxValue/steperSplit
    }

    func colorMix(percent: Int) -> Color {
        let percent = Double(percent)
        let tempG = (100.0-percent)/100
        let green: Double = tempG < 0 ? 0 : tempG
        let tempR = 1+(percent-100.0)/100.0
        let red: Double = tempR < 0 ? 0 : tempR
        return Color.init(red: red, green: green, blue: 0)
    }

    func tickText(at tick: Int, text: String) -> some View {
        let percent = (tick * 100) / tickCount
        let startAngle = coveredRadius/2 * -1 + 90
        let stepper = coveredRadius/Double(tickCount)
        let rotation = startAngle + stepper * Double(tick)
        return Text(text)
                .foregroundColor(colorMix(percent: percent))
                .rotationEffect(.init(degrees: -1 * rotation), anchor: .center)
                .offset(x: -45, y: 0).rotationEffect(Angle.degrees(rotation))
    }

    func tick(at tick: Int, totalTicks: Int) -> some View {
        let percent = (tick * 100) / totalTicks
        let startAngle = coveredRadius/2 * -1
        let stepper = coveredRadius/Double(totalTicks)
        let rotation = Angle.degrees(startAngle + stepper * Double(tick))
        return VStack {
            Rectangle()
                .fill(colorMix(percent: percent))
                .frame(width: tick % 2 == 0 ? 5 : 3,
                       height: tick % 2 == 0 ? 20 : 10) // alternet small big dash
            Spacer()
        }.rotationEffect(rotation)
    }

    var body: some View {
        ZStack {
            ForEach(0..<tickCount*2 + 1, id: \.self) { tick in
                self.tick(at: tick,
                          totalTicks: self.tickCount*2)
            }
            ForEach(0..<tickCount+1, id: \.self) { tick in
                self.tickText(at: tick, text: "\(self.steperSplit*tick)")
            }
            Needle()
                .fill(Color.red)
                .frame(width: GaugeConstants.needleSize.width, height: GaugeConstants.needleSize.height)
                .offset(x: -GaugeConstants.needleSize.width / 2, y: 0)
                .rotationEffect(.init(degrees: getAngle(value: Double(value))))

            Circle()
                    .frame(width: GaugeConstants.circleSize.width, height: GaugeConstants.circleSize.height)
                    .foregroundColor(.red)
        }.frame(width: GaugeConstants.gaugeSize.width, height: GaugeConstants.gaugeSize.height, alignment: .center)
    }

    func getAngle(value: Double) -> Double {
        return (value/Double(maxValue))*coveredRadius - coveredRadius/2 + 90
    }
}

struct GuageView_Previews: PreviewProvider {
    static var previews: some View {
        GaugeView(coveredRadius: 250, maxValue: 80, steperSplit: 10, value: .constant(20))
    }
}
