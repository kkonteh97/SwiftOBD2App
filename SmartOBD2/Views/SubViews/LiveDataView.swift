//
//  LiveDataView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

struct LiveDataView: View {
    @ObservedObject var viewModel: LiveDataViewModel

    @State private var rpm: Double = 0
    @State private var speed: Double = 0
    @State private var showingSheet = false

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                Button {
                    showingSheet.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()

            Button {
                viewModel.startRequestingPIDs()
            } label: {
                Text("Start")
                    .font(.title)
                    .padding()
            }

           ForEach(viewModel.pidsToRequest, id: \.self) { pid in
                HStack {
                    Text(pid.description)
                        .font(.caption)
                    Spacer()
                    Text("\(viewModel.data[pid]??.value ?? 0, specifier: "%.0f") \(viewModel.data[pid]??.unit.symbol ?? "")")
                        .font(.title)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(RoundedRectangleStyle())
            }

            ScrollView(.vertical, showsIndicators: false) {
                if let car = viewModel.currentVehicle {
                    if let supportedPIDs = car.obdinfo?.supportedPIDs {
                        ForEach(supportedPIDs, id: \.self) { pid in
                            HStack {
                                Text(pid.description)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(RoundedRectangleStyle())
                            .onTapGesture {
                                viewModel.addPIDToRequest(pid)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .sheet(isPresented: $showingSheet) {
            AddPIDView(viewModel: viewModel)
        }
    }
}

#Preview {
    ZStack {
        LiveDataView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                  garage: Garage()))
    }
}
