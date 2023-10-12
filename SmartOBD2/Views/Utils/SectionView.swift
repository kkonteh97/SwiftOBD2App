//
//  SectionView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI

struct SectionView<Destination: View>: View {
    let title: String
    let subtitle: String
    let iconName: String
    let destination: Destination

    init(
        title: String,
        subtitle: String,
        iconName: String,
        destination: Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.destination = destination
    }

    var body: some View {
        NavigationLink {
            destination
        }label: {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                HStack {
                    Text(subtitle)
                        .lineLimit(2)
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .frame(width: 160, height: 160)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cyclamen)
            }
        }
    }
}

#Preview {
    SectionView(title: "hello", subtitle: "ola", iconName: "car.fill", destination: Text("hello"))
}
