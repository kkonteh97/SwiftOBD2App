//
//  VehicleDiagnosticsView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import SwiftOBD2

struct Stage: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
}

struct DiagnosticsScreen: View {
    @State private var startPoint = UnitPoint(x: -1, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)

    @Binding var stages: [Stage]
    @Binding var requestingTroubleCodes: Bool
    @Binding var requestingTroubleCodesError: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 220, height: 100)
                    .overlay(alignment: .leading) {
                        if stages.last?.name != "Complete" {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.5), .darkEnd.opacity(0.5)]), startPoint: startPoint, endPoint: endPoint))
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.darkEnd.opacity(0.5))
                        }
                    }

                Image("car")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

            }
            .frame(maxWidth: .infinity)
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: true)) {
                    self.startPoint = UnitPoint(x: 1, y: 0.5)
                    self.endPoint = UnitPoint(x: 1.5, y: 0.5)
                }
            }
            .padding(.top)

            VStack(alignment: .leading, spacing: 10) {

                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(stages, id: \.self) { stage in
                            Text(stage.name)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(stages.dropLast()) { _ in
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.green)
                        }
                        ZStack(alignment: .center) {
                            if stages.last?.name == "Complete" {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.green)
                            } else {
                                if !requestingTroubleCodesError {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding(5)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white, lineWidth: 1)
                    }
                    .animation(.linear(duration: 0.5), value: stages.last)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .animation(.linear(duration: 0.5), value: stages.last)
            if stages.last?.name == "Complete" || requestingTroubleCodesError {
                Button {
                    requestingTroubleCodes = false
                } label: {
                    Text("Continue")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                    //                    .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                }
                .padding()
                .buttonStyle(.plain)
                .transition(.slide)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
    }
}

struct VehicleDiagnosticsView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @EnvironmentObject var garage: Garage
    @EnvironmentObject var obd2Service: OBDService

    @Environment(\.dismiss) var dismiss
    @Binding var displayType: BottomSheetType
    @Binding var isDemoMode: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var loading = false
    @State private var clearCodeAlert = false
    @State var troubleCodes: [ECUID:[TroubleCode]] = [:]

    @State var requestingTroubleCodes = false
    @State var requestingTroubleCodesError = false
    let notificationFeedback = UINotificationFeedbackGenerator()
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    func appendStage(_ stage: Stage) {
        stages.append(stage)
    }

    var current: Vehicle?

    @MainActor
    func scanForTroubleCodes() async {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        notificationFeedback.prepare()
        requestingTroubleCodesError = false

        guard var currentVehicle = garage.currentVehicle else {
            self.alertMessage = "No vehicle selected"
            showAlert = true
            requestingTroubleCodes = false
            return
        }
        stages = [Stage(name: "Getting engine parameters")]
        appendStage(Stage(name: "Starting diagnostics"))

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard let status = try await self.getStatus() else {
                appendStage(Stage(name: "No status codes found"))
                requestingTroubleCodesError = true
                return
            }
            currentVehicle.status = status
            appendStage(Stage(name: "DTC count: \(status.dtcCount)"))
            guard status.dtcCount > 0  else {
                appendStage(Stage(name: "No trouble codes found"))
                appendStage(Stage(name: "Complete"))
                return
            }
            appendStage(Stage(name: "Reading trouble codes"))
            let codes = try await obd2Service.scanForTroubleCodes()
            try await Task.sleep(nanoseconds: 2_500_000_000)

            appendStage(Stage(name: "Trouble codes found"))

            for (ecu, troubleCodes) in codes {
                withAnimation {
                    self.troubleCodes[ecu] = troubleCodes
                    for troubleCode in troubleCodes {
                        appendStage(Stage(name: troubleCode.code + ": " + troubleCode.description))
                    }
                }
            }
            currentVehicle.troubleCodes = troubleCodes

            garage.updateVehicle(currentVehicle)

            appendStage(Stage(name: "Complete"))
            notificationFeedback.notificationOccurred(.success)
        } catch {
            notificationFeedback.notificationOccurred(.error)
            self.alertMessage = error.localizedDescription
            showAlert = true
            requestingTroubleCodesError = true
        }
    }

    func getStatus() async throws -> Status? {
        let statusResult = try await obd2Service.getStatus()
        switch statusResult {
        case .success(let status):
            guard let response = status.statusResult else {
                    appendStage(Stage(name: "No status codes found"))
                    requestingTroubleCodesError = true
                    return nil
            }
            return response
        case .failure(let error):
            print(error.localizedDescription)
            return nil
        }
    }

    @MainActor
    func clearCode() async {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        notificationFeedback.prepare()

        do {
            try await obd2Service.clearTroubleCodes()
            self.loading = true
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print(error.localizedDescription)
            notificationFeedback.notificationOccurred(.error)
            self.alertMessage = error.localizedDescription
            self.showAlert = true
        }
    }

    @Namespace var animation
    @State var stages: [Stage] = []
    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: $isDemoMode)
            if requestingTroubleCodes {
                DiagnosticsScreen(stages: $stages,
                                  requestingTroubleCodes: $requestingTroubleCodes,
                                  requestingTroubleCodesError: $requestingTroubleCodesError)
                .transition(.opacity)
                .animation(.easeInOut, value: requestingTroubleCodes)
                .matchedGeometryEffect(id: "diagnostics", in: animation)
            } else {
                VStack(alignment: .leading) {
                    if let currentVehicle = garage.currentVehicle {
                        Image("car")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .topLeading) {
                                VStack(alignment: .leading) {
                                    Text("\(currentVehicle.year) \(currentVehicle.make)")
                                    Text("\(currentVehicle.model)")
                                }
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            }

                        HStack {
                            Text("DTC count:")
                            Spacer()
                            if  let dtcCount = currentVehicle.status?.dtcCount {
                                Text(String(dtcCount))
                            }
                        }
                        .listRowBackground(Color.darkStart.opacity(0.3))
                        .padding()
                        Text("Confirmed Codes")
                            .padding(.horizontal)
                        if  let codes = currentVehicle.troubleCodes {
                            ForEach(Array(codes.keys), id: \.self) { ecuid in
                                ForEach(codes[ecuid] ?? [], id: \.self) { troubleCode in
                                    VStack {
                                        HStack(spacing: 20) {
                                            Text(troubleCode.code)
                                            Text(troubleCode.description)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    }
                                    .transition(.slide)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .animation(.easeInOut, value: troubleCode)
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.inset)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    Spacer()
                }
                .matchedGeometryEffect(id: "diagnostics", in: animation)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .alert("", isPresented: $showAlert) {} message: {
            Text(alertMessage)
        }
        .alert("Wait", isPresented: $clearCodeAlert) {
            Button("Cancel", role: .cancel) {}

            Button("Clear Codes", role: .destructive) {
                guard !loading else { return }
                self.loading = true
                Task {
                    await scanForTroubleCodes()
                    loading = false
                }
            }

        } message: {
            Text("Do not attempt to clear codes while the engine is running. Clearing codes while the engine is running can cause serious damage to your vehicle.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation {
                        displayType = .quarterScreen
                        dismiss()
                    }
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button("Clear Codes", role: .destructive) {
                    clearCodeAlert = true
                }
                .buttonStyle(.bordered)
                .disabled(loading)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Scan", role: .none) {
                    guard !requestingTroubleCodes else { return }
                    withAnimation {
                        self.requestingTroubleCodes = true
                    }
                    Task {
                        await scanForTroubleCodes()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(loading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
            }
        }
    }
}

#Preview {
    NavigationView {
        VehicleDiagnosticsView(displayType: .constant(.quarterScreen), isDemoMode: .constant(false))
            .environmentObject(GlobalSettings())
            .environmentObject(Garage())
    }
}
