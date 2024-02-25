//
//  AddPIDView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/10/23.
//

import SwiftUI
import Combine

struct AddPIDView: View {
    @ObservedObject var viewModel: LiveDataViewModel
    @EnvironmentObject var garage: Garage

    var body: some View {
        if let car = garage.currentVehicle {
            VStack(alignment: .leading) {
                Text("Supported sensors for \(car.year) \(car.make) \(car.model)")
                Divider().background(Color.white)

                ScrollView(.vertical, showsIndicators: false) {
                    if let supportedPIDs = car.obdinfo.supportedPIDs  {
                        ForEach(supportedPIDs.filter { $0.properties.live }.sorted(), id: \.self) { pid in
                            HStack {
                                Text(pid.properties.description)
                                    .font(.system(size: 14, weight: .semibold, design: .default))
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
//                                    .fill(Color.endColor())
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(viewModel.data.keys.contains(pid) ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            )
                            .padding(.horizontal)
                            .onTapGesture {
                                viewModel.addPIDToRequest(pid)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    }
}

#Preview {
    AddPIDView(viewModel: LiveDataViewModel())
        .environmentObject(Garage())
}
