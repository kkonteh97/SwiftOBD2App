//
//  GarageView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/2/23.
//

import SwiftUI

struct GarageView: View {
    @ObservedObject var viewModel: GarageViewModel
    @State private var showingSheet = false

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(viewModel.garage.garageVehicles) { vehicle in
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(vehicle.make)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                 .foregroundColor(.white)

                            Text(vehicle.model)
                                .font(.system(size: 14, weight: .bold, design: .default))
                                .foregroundColor(.white)

                            Text(vehicle.year)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button {
                            viewModel.deleteVehicle(vehicle)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 125, alignment: .leading)
                    .background(viewModel.currentVehicle?.id == vehicle.id ? Color.blue : Color.clear)
                    .padding(.bottom, 15)
                    .onTapGesture {
                        withAnimation {
                            viewModel.garage.setCurrentVehicle(by: vehicle.id)
                        }
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Garage")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: 
            Button {
                showingSheet.toggle()
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            .sheet(isPresented: $showingSheet) {
                AddVehicleView(viewModel: AddVehicleViewModel(garage: viewModel.garage))
            }
        )
    }
}

#Preview {
    GarageView(viewModel: GarageViewModel(garage: Garage()))
        .background(LinearGradient(.darkStart, .darkEnd))
}
