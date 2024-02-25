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
    @Published var showError = false

    init() {
        do {
            try fetchData()
            showError = false
        } catch {
            showError = true
        }
    }

    func fetchData() throws {
        let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
        let data = try Data(contentsOf: url)
        self.carData = try JSONDecoder().decode([Manufacturer].self, from: data)
    }
}

struct AddVehicleView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(isDemoMode: .constant(false))
                VStack {
                    List {
                        NavigationLink(destination: AutoAddVehicleView(isPresented: $isPresented)) {
                            Text("Auto-detect Vehicle")
                        }
                        .listRowBackground(Color.darkStart.opacity(0.3))

                        NavigationLink(destination: ManuallyAddVehicleView(isPresented: $isPresented)) {
                            Text( "Manually Add Vehicle")
                        }
                        .listRowBackground(Color.darkStart.opacity(0.3))
                    }
                    .scrollContentBackground(.hidden)

                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AutoAddVehicleView: View {
    @EnvironmentObject var garage: Garage
    @EnvironmentObject var obdService: OBDService

    @Binding var isPresented: Bool
    @State var statusMessage: String = ""
    @State var isLoading: Bool = false

    let notificationFeedback = UINotificationFeedbackGenerator()
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack(alignment: .center) {
            BackgroundView(isDemoMode: .constant(false))
            VStack(alignment: .center, spacing: 10) {
                Text("Before you start")
                    .font(.title)
                Text("Plug in the scanner to the OBD port\nTurn on your vehicles engine\nMake sure that Bluetooth is on")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                detectButton
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            .padding(.bottom, 40)
        }
    }

    var detectButton: some View {
        VStack {
            Text(statusMessage)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.bottom)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2.0, anchor: .center)
            } else {
                Button {
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    detectVehicle()
                } label: {
                    Text("Detect Vehicle")
                        .padding(10)
                }
                .buttonStyle(.bordered)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            }
        }
        .frame(maxHeight: 200)
    }

    func detectVehicle() {
        isLoading = true
        notificationFeedback.prepare()

        Task {
            do {
                guard let vinInfo = try await connect() else {
                    DispatchQueue.main.async {
                        statusMessage = "Vehicle Not Detected"
                        isLoading = false
                    }
                    return
                }
                DispatchQueue.main.async {
                    statusMessage = "Found Vehicle"
                    notificationFeedback.notificationOccurred(.success)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    statusMessage = "Make: \(vinInfo.Make)\nModel: \(vinInfo.Model)\nYear: \(vinInfo.ModelYear)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isLoading = false
                    isPresented = false
                }
            } catch {
                DispatchQueue.main.async {
                    statusMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    func connect() async throws -> VINInfo? {
        var obdInfo = OBDInfo()
        try await obdService.startConnection(&obdInfo)
        guard let vin = obdInfo.vin else {
            return nil
        }

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

struct ManuallyAddVehicleView: View {
    @ObservedObject var viewModel = AddVehicleViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: .constant(false))
            if let carData = viewModel.carData {
                List {
                    ForEach(carData.sorted(by: { $0.make < $1.make }), id: \.self) { manufacturer in
                        NavigationLink(
                            destination: ModelView(isPresented: $isPresented,
                                                   manufacturer: manufacturer),
                            label: {
                                Text(manufacturer.make)
                            })
                    }
                    .listRowBackground(Color.darkStart.opacity(0.3))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.inset)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Select Make")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelView: View {
    @State var selectedModel: Model?
    @Binding var isPresented: Bool

    let manufacturer: Manufacturer

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: .constant(false))
            List {
                ForEach(manufacturer.models.sorted(by: { $0.name < $1.name }), id: \.self) { carModel in
                    NavigationLink(
                        destination: YearView(isPresented: $isPresented,
                                              carModel: carModel,
                                              manufacturer: manufacturer),
                        label: {
                            Text(carModel.name)
                        })
                }
                .listRowBackground(Color.darkStart.opacity(0.3))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.inset)
        }
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
    }
}

struct YearView: View {
    @Binding var isPresented: Bool

    let carModel: Model
    let manufacturer: Manufacturer

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: .constant(false))
            List {
                ForEach(carModel.years.sorted(by: { $0 > $1 }), id: \.self) { year in
                    NavigationLink(
                        destination: ConfirmView(isPresented: $isPresented,
                                                 carModel: carModel,
                                                 manufacturer: manufacturer,
                                                 year: year),
                        label: {
                            Text("\(year)")
                                .font(.headline)
                        })
                }
                .listRowBackground(Color.darkStart.opacity(0.3))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.inset)
        }
        .navigationBarTitle(manufacturer.make + " " + carModel.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConfirmView: View {
    @EnvironmentObject var garage: Garage
    @Binding var isPresented: Bool

    let carModel: Model
    let manufacturer: Manufacturer
    let year: String

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: .constant(false))
            VStack {
                Text("\(year) \(manufacturer.make) \(carModel.name)")
                    .font(.title)
                    .padding()
                Button {
                    garage.addVehicle(
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
}

#Preview {
    AddVehicleView(isPresented: .constant(true))
            .environmentObject(GlobalSettings())
            .environmentObject(OBDService())
            .environmentObject(Garage())

}

struct BackgroundView: View {
    @Binding var isDemoMode: Bool

    var body: some View {
            LinearGradient(Color.darkStart.opacity(0.8), .darkEnd.opacity(0.4))
                .ignoresSafeArea()

            if isDemoMode {
                ZStack {
                    Text("Demo Mode")
                        .font(.system(size: 40, weight: .semibold)) // Reduced font size
                        .foregroundColor(Color.charcoal.opacity(0.2))
                        .offset(y: -5)
                        .shadow(color: .black, radius: 5, x: 3, y: 3) // Softened shadow
                        .rotationEffect(.degrees(-30))

                    Text("Demo Mode")
                        .font(.system(size: 40, weight: .semibold)) // Reduced font size
                        .foregroundColor(Color.black.opacity(0.2))
                        .offset(y: 2)
                        .rotationEffect(.degrees(-30))
                }
            }
    }
}

//func getVINInfo(vin: String) async throws -> VINResults {
//    let endpoint = "https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/\(vin)?format=json"
//
//    guard let url = URL(string: endpoint) else {
//        throw URLError(.badURL)
//    }
//
//    let (data, response) = try await URLSession.shared.data(from: url)
//
//    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//        throw URLError(.badServerResponse)
//    }
//
//    let decoder = JSONDecoder()
//    let decoded = try decoder.decode(VINResults.self, from: data)
//    return decoded
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
