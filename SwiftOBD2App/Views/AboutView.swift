//
//  AboutView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/1/23.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 100) {
            Text("SMARTOBD2 Version 1.0")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.bottom, 10)
            VStack {
                Text(
                     """
                        SMARTOBD2 lets you monitor your car's health and
                        performance in real-time. It also lets you diagnose
                        your car's problems and provides you with a
                        solution to fix them.
                     """
                )
                .multilineTextAlignment(.leading)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 10)

                Text("Dedicated to my Dad\n Lang Konteh")
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }

            VStack {
                Text("©2023 Konteh Inc")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)

                Text("All rights reserved")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Select a Make")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    globalSettings.displayType = .quarterScreen
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }

            }

        }
    }
}

#Preview {
    AboutView()
}
