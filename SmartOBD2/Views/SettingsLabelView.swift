//
//  SettingsLabelView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/8/23.
//

import SwiftUI

struct SettingsLabelView: View {
    // MARK: Properties
    var labelText: String
    var labelImage: String

    // MARK: Body
    var body: some View {
        HStack {
            Text(labelText.uppercased()).fontWeight(.bold)
            Spacer()
            Image(systemName: labelImage)
        }
    }
}

#Preview {
    SettingsLabelView(labelText: "Ola", labelImage: "car.side")
}
