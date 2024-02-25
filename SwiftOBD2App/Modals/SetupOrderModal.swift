//
//  SetupOrderModal.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import SwiftUI

struct SetupOrderModal: View {
    @Binding var isModalPresented: Bool
    @Binding var setupOrder: [OBDCommand.General]
    @State private var newItem: OBDCommand.General = .ATD

    func move(from source: IndexSet, to destination: Int) {
        setupOrder.move(fromOffsets: source, toOffset: destination)
    }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(setupOrder, id: \.self) { step in
                        Text(step.properties.description.uppercased())
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: { indexSet in
                        setupOrder.remove(atOffsets: indexSet)
                    })
                }
                .navigationBarItems(trailing: Button("Done", action: {
                    isModalPresented.toggle()
                }))
                HStack {
                    Picker("Add Step", selection: $newItem) {
//                        ForEach(SetupStep.allCases, id: \.self) { step in
//                            Text(step.rawValue.uppercased())
//                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Button("Add", action: {
                        setupOrder.append(newItem)
                        newItem = .ATD
                    })
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    SetupOrderModal(isModalPresented: .constant(true),
                    setupOrder: .constant([.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATDPN]))

}
