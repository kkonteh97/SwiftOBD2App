//
//  AddVehicleView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/10/23.
//

import SwiftUI

class AddVehicleViewModel: ObservableObject {
    var carData: [Manufacturer] = []
    let garage: Garage

    init(garage: Garage) {
        self.garage = garage
        loadVehicles()
    }

    private func loadVehicles() {
        do {
            let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
            let data = try Data(contentsOf: url)
            self.carData = try JSONDecoder().decode([Manufacturer].self, from: data)
        } catch {
            print("error loading vehicles")
        }
    }

    func addVehicle(make: String, model: String, year: String,
                    vin: String = "", obdinfo: OBDInfo? = nil) {
        garage.addVehicle(make: make, model: model, year: year)
    }
}

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddVehicleViewModel
    @State var selectMake: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(0 ..< viewModel.carData.count, id: \.self) { carIndex in
                VStack(alignment: .center, spacing: 20) {
                    Text(self.viewModel.carData[carIndex].make)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(self.viewModel.carData[carIndex].make == selectMake ? .blue : .green)
                }
                .onTapGesture {
                    withAnimation {
                        selectMake = self.viewModel.carData[carIndex].make
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            if selectMake != nil {
                VStack {
                    Text("Next")
                        .transition(.move(edge: .top))
                }
                .frame(width: 200, height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                }
            }
        })
        .padding()
    }
}

#Preview {
    AddVehicleView(viewModel: AddVehicleViewModel(garage: Garage()))
}
