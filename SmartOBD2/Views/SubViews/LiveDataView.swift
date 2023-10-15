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
            .sheet(isPresented: $showingSheet) {
                AddPIDView(viewModel: viewModel)
            }

            ForEach(viewModel.data, id: \.command) { dataItem in
                HStack {
                    Text(dataItem.command.description)
                        .font(.caption)

                    Spacer()
                    Text("\(viewModel.decodeMeasurementToString(dataItem.measurement))")

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(RoundedRectangleStyle())
            }
            Spacer()
        }
        .onAppear {
            print("helo")
        }
    }
}

#Preview {
    ZStack {
        LiveDataView(viewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                  garage: Garage()))
    }
}
