//
//  GuageView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/17/23.
//

import SwiftUI

struct GaugeConstants {
    static let gaugeSize: CGSize = CGSize(width: 175, height: 175) // Adjust the size of the gauge view
    static let needleSize: CGSize = CGSize(width: 70, height: 3.5) // Adjust the size of the needle
    static let tickWidthSmall: CGFloat = 1.5 // Adjust the width of the small tick
    static let tickWidthBig: CGFloat = 3.5 // Adjust the width of the big tick
    static let tickHeightSmall: CGFloat = 5 // Adjust the height of the small tick
    static let tickHeightBig: CGFloat = 15 // Adjust the height of the big tick
    static let circleSize: CGSize = CGSize(width: 10, height: 10) // Adjust the size of the circle
}

struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height/2))
        path.addLine(to: CGPoint(x: rect.width , y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        return path
    }
}

struct CustomGaugeView: View {
    let coveredRadius: Double
    let maxValue: Double
    let steperSplit: Double
    let shrink: Bool

    @Binding var value: Double

    init(coveredRadius: Double, maxValue: Double, steperSplit: Double, value: Binding<Double>) {
        self.coveredRadius = coveredRadius
        self._value = value

        if maxValue > 999 {
            self.maxValue = maxValue / 1000
            self.steperSplit = steperSplit / 1000
            self.shrink = true
        } else {
            self.maxValue = maxValue
            self.steperSplit = steperSplit
            self.shrink = false
        }
    }

    private var tickCount: Double {
        return maxValue/steperSplit
    }

    // colormix white to red
    func colorMix(percent: Int) -> Color {
        let red = Double(percent) / 100
        return Color(red: red, green: 1 - red, blue: 0)
    }

    func tickText(at tick: Double, text: String) -> some View {
        let percent = (tick * 100) / tickCount
        let startAngle = coveredRadius/2 * -1 + 90
        let stepper = coveredRadius/Double(tickCount)
        let rotation = startAngle + stepper * Double(tick)
        return Text(text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(colorMix(percent: Int(percent)))
                    .rotationEffect(.init(degrees: -1 * rotation), anchor: .center)
                    .offset(x: -60, y: 0)
                    .rotationEffect(Angle.degrees(rotation))
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
                       height: tick % 2 == 0 ? 10 : 5) // alternet small big dash
            Spacer()
        }.rotationEffect(rotation)
    }

    var body: some View {
        ZStack {
//            Circle()
//                .strokeBorder(.gray, lineWidth: 2)

//            Circle()
//                .fill(Color.gray)
//                .frame(width: 125)
//                .shadow(color: Color.gray, radius: 10)
//                .shadow(color: Color.darkStart, radius: 10)
//                .blur(radius: 1.0)

            Text(String(format: "%.3f", $value.wrappedValue))
                .font(.system(size: 40, design: .rounded))
                .foregroundColor(.white)

            ForEach(0..<Int(tickCount)*2 + 1, id: \.self) { tick in
                self.tick(at: tick, totalTicks: Int(self.tickCount)*2)
            }

//            ForEach(0..<Int(tickCount) + 1, id: \.self) { tick in
//                self.tickText(at: Double(tick), text: "\(self.steperSplit*tick)")
//            }

            Needle()
                .fill(Color.red)
                .frame(width: GaugeConstants.needleSize.width, height: GaugeConstants.needleSize.height)
                .offset(x: -GaugeConstants.needleSize.width / 2 - 25, y: 0)
                .rotationEffect(.init(degrees: getAngle(value: Double( shrink ? value / 1000 : value))))

        }.frame(width: GaugeConstants.gaugeSize.width, height: GaugeConstants.gaugeSize.height, alignment: .center)
    }

    func getAngle(value: Double) -> Double {
        return (value/Double(maxValue))*coveredRadius - coveredRadius/2 + 90
    }
}


struct GuageView_Previews: PreviewProvider {
    static var previews: some View {
        CustomGaugeView(coveredRadius: 250, maxValue: 80, steperSplit: 10, value: .constant(20))
    }
}
