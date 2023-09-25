//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth

struct CarlyObd {
    static let elmServiceUUID = "FFE0"
    static let elmCharactericUUID = "FFE1"
}

struct MainView: View {
    @State private var selectedPIDValues: [OBDCommand: String] = [:]
    @State private var selectedPID: OBDCommand?
    @State var displayType: BottomSheetType = .none

    @Environment(\.colorScheme) var colorScheme
    
    let elm327: ELM327
    let homeViewModel: HomeViewModel
    let carScreenViewModel: CarScreenViewModel

    init() {
        self.elm327 = ELM327(bleManager: BLEManager.shared)
        self.carScreenViewModel = CarScreenViewModel(elm327: elm327)
        self.homeViewModel = HomeViewModel(elm327: elm327)
    }

    var body: some View {
        ZStack {
            LinearGradient(Color.darkStart, Color.darkEnd)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)
                TabView {
                    HomeView(viewModel: homeViewModel)
                        .padding()
                        .tabItem {
                            Image(systemName: "car.fill")
                            Text("Dashboard")
                        }

                    CarScreen(viewModel: carScreenViewModel)
                        .tabItem {
                            Image(systemName: "car.fill")
                            Text("Dashboard")
                        }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(width: frame.width, height: frame.height)

                BottomSheet(viewModel: homeViewModel, displayType: $displayType, maxHeight: proxy.size.height)
            }
            //            .blur(radius: getBlurRadius())
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "car.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vehicle Information")
                    Text("Read Data From your Vehicle")
                }
            }
            
            Divider().padding(.vertical, 8)

            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Diagnostics")
                    .foregroundColor(.white)
            }   
            
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Live Data")
                    .foregroundColor(.white)
                
            }   
            
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Digital Garage")
                    .foregroundColor(.white)
                
            }   
//            bluetoothSection
//            testsSection
//            diagnosticsSection

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { 
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(Color.darkStart, Color.darkEnd))
        }
    }

    private var bluetoothSection: some View {
        VStack {
            GroupBox(label: SettingsLabelView(labelText: "Adapter",
                                              labelImage: "wifi.circle")) {
                Divider().padding(.vertical, 4)
                //                Text("Device: \(viewModel.elmAdapter?.name ?? "")")
                    .font(.headline)
            }
        }
    }

    private var testsSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "Emissions test", labelImage: "wifi.circle")) {
            Divider().padding(.vertical, 4)

            Text("Current drive cycle status:")
                .font(.headline)

            Text("Status Since DTC Reset:")
                .font(.headline)

        }
    }

    private var diagnosticsSection: some View {
        VStack {

            GroupBox(label: SettingsLabelView(labelText: "Diagnostics", labelImage: "wifi.circle")) {
                Divider().padding(.vertical, 4)

                Text("Scan For Trouble Codes")
                    .font(.headline)
            }
        }
    }
}

#Preview {
    MainView()
}
