//
//  TabBarItem.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import SwiftUI

enum TabBarItem: Hashable {
    case dashBoard
    case features

    var iconName: String {
        switch self {
        case .dashBoard:
            return "gauge.open.with.lines.needle.33percent"
        case .features:
            return "person"
        }
    }

    var title: String {
        switch self {
        case .dashBoard:
            return "Dashboard"
        case .features:
            return "Features"
        }
    }

    var color: Color {
        switch self {
        case .dashBoard:
            return Color.red
        case .features:
            return Color.blue
        }
    }
}
