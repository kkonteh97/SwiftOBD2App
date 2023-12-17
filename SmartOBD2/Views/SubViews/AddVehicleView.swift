//
//  AddVehicleView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/10/23.
//

import SwiftUI

struct Manufacturer: Codable, Hashable {
    let make: String
    let models: [Model]
}

struct Model: Codable, Hashable  {
    let name: String
    let years: [String]
}


class AddVehicleViewModel: ObservableObject {
    @Published var carData: [Manufacturer]?
    var setupOrder: [OBDCommand.General] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]

    let garage: Garage
    let obdService: OBDService


    init(garage: Garage,
         obdService: OBDService
    ) {
        self.garage = garage
        self.obdService =  obdService
    }

    func fetchData() throws {
        let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
        let data = try Data(contentsOf: url)
        self.carData = try JSONDecoder().decode([Manufacturer].self, from: data)
    }


    func addVehicle(make: String, model: String, year: String,
                    vin: String = "", obdinfo: OBDInfo? = nil) {
        garage.addVehicle(make: make, model: model, year: year)
    }

    func detectVehicle(device: OBDDevice) async throws -> VINInfo? {
        let obdInfo = try await obdService.startConnection(setupOrder: self.setupOrder, device: device,
                                                        obdinfo: OBDInfo()
        )
        print(obdInfo)
        guard let vin = obdInfo.vin else {
            return nil
        }
        print(vin)

        guard let vinInfo = try await getVINInfo(vin: vin).Results.first else {
            return nil
        }

        DispatchQueue.main.async {
            self.garage.addVehicle(
                make: vinInfo.Make, 
                model: vinInfo.Model,
                year: vinInfo.ModelYear,
                obdinfo: obdInfo
            )
        }
        return vinInfo
    }
}

struct AddVehicleView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                List {
                    NavigationLink(destination: AutoAddVehicleView(viewModel: viewModel, isPresented: $isPresented)) {
                        Text("Automagically Select Vehicle")
                    }
                    NavigationLink(destination: ManuallyAddVehicleView(viewModel: viewModel, isPresented: $isPresented)) {
                        Text( "Manually Select Vehicle")
                    }
                    .onAppear {
                        do {
                            try viewModel.fetchData()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                .navigationTitle("Add Vehicle")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AutoAddVehicleView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @EnvironmentObject var globalSettings: GlobalSettings

    @Binding var isPresented: Bool
    @State var statusMessage: String = ""
    @State var isLoading: Bool = false
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Before you start:")
                .font(.title)
            VStack(alignment: .leading, spacing: 10) {
                Text("Plug in the scanner to the OBD port")
                    .font(.subheadline)

                Text("Turn on your vehicles engine")
                    .font(.subheadline)

                Text("Make sure that Bluetooth is on")
                    .font(.subheadline)
            }
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2.0, anchor: .center)
                } else {
                    HStack {
                        Text(statusMessage)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 100)
            .padding(.horizontal, 10)

            Button {
                isLoading = true
                Task {
                    do {
                        guard let vinInfo = try await viewModel.detectVehicle(device: globalSettings.userDevice) else {
                            DispatchQueue.main.async {
                                statusMessage = "Vehicle Not Detected"
                                isLoading = false
                            }
                            return
                        }
                        DispatchQueue.main.async {
                                isLoading = false
                                statusMessage = "Found Vehicle"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            statusMessage = "Make: \(vinInfo.Make)\nModel: \(vinInfo.Model)\nYear: \(vinInfo.ModelYear)"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isPresented = false
                        }
                    } catch {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            statusMessage = "Error: \(error.localizedDescription)"
                            isLoading = false
                        }
                    }
                }
            } label: {
                Text("Detect Vehicle")
                    .font(.headline)
            }
        }
    }
}

struct ManuallyAddVehicleView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @Binding var isPresented: Bool

    var body: some View {
            if let carData = viewModel.carData {
                List {
                    ForEach(carData.sorted(by: { $0.make < $1.make }), id: \.self) { manufacturer in
                        NavigationLink(
                            destination: ModelView(viewModel: viewModel,
                                                   isPresented: $isPresented,
                                                   manufacturer: manufacturer),
                            label: {
                                Text(manufacturer.make)
                            })
                    }
                }
                .navigationTitle("Select Make")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ProgressView()
            }
    }
}

struct ModelView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @State var selectedModel: Model?
    @Binding var isPresented: Bool

    let manufacturer: Manufacturer

    var body: some View {
        List {
            ForEach(manufacturer.models.sorted(by: { $0.name < $1.name }), id: \.self) { carModel in
                NavigationLink(
                    destination: YearView(viewModel: viewModel,
                                          isPresented: $isPresented,
                                          carModel: carModel,
                                          manufacturer: manufacturer),
                    label: {
                        Text(carModel.name)
                    })
            }
        }
        .navigationBarTitle(manufacturer.make)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct YearView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @Binding var isPresented: Bool

    let carModel: Model
    let manufacturer: Manufacturer

    var body: some View {
        List {
            ForEach(carModel.years.sorted(by: { $0 > $1 }), id: \.self) { year in
                NavigationLink(
                    destination: ConfirmView(viewModel: viewModel,
                                             isPresented: $isPresented,
                                             carModel: carModel,
                                             manufacturer: manufacturer,
                                             year: year
                                            ),
                    label: {
                        Text("\(year)")
                            .font(.headline)
                    })
            }
        }
        .navigationBarTitle(manufacturer.make + " " + carModel.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConfirmView: View {
    @ObservedObject var viewModel: AddVehicleViewModel
    @Binding var isPresented: Bool

    let carModel: Model
    let manufacturer: Manufacturer
    let year: String

    var body: some View {
        VStack {
            Text("\(year) \(manufacturer.make) \(carModel.name)")
                .font(.title)
                .padding()
            Button {
                viewModel.addVehicle(
                    make: manufacturer.make,
                    model: carModel.name,
                    year: year
                )
                isPresented = false

            } label: {
                VStack {
                    Text("Add Vehicle")
                }
                .frame(width: 200, height: 50)                    
            }
        }
    }
}

//#Preview {
//    AutoAddVehicleView(viewModel: AddVehicleViewModel(garage: Garage(),
//                                                      obdService: OBDService()
//                                                     ),
//                       isPresented: .constant(true)
//    )
//    .environmentObject(GlobalSettings())
//}
//        ScrollView(.vertical, showsIndicators: false) {
//            ForEach(0 ..< viewModel.carData.count, id: \.self) { carIndex in
//                VStack(alignment: .center, spacing: 20) {
//                    Text(self.viewModel.carData[carIndex].make)
//                }
//                .padding()
//                .frame(maxWidth: .infinity, maxHeight: 200)
//                .background {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(self.viewModel.carData[carIndex].make == selectMake ? .blue : .green)
//                }
//                .onTapGesture {
//                    withAnimation {
//                        selectMake = self.viewModel.carData[carIndex].make
//                    }
//                }
//            }
//        }
//        .safeAreaInset(edge: .bottom, content: {
//            if selectMake != nil {
//                VStack {
//                    Text("Next")
//                        .transition(.move(edge: .top))
//                }
//                .frame(width: 200, height: 50)
//                .background {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Color(.systemGray6))
//                }
//            }
//        })
//        .padding()
