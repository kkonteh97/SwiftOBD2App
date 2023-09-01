//
//  TabBarItem.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/16/23.
//

import Foundation
import SwiftUI

//struct TabBarItem: Hashable {
//    let iconName: String
//    let title: String
//    let color: Color
//}


enum TabBarItem: Hashable {
    case home, favourites, profile
    
    var iconName: String {
        switch self {
        case  .home: return "house"
        case  .favourites: return "wrench.and.screwdriver"
        case  .profile: return "gear"
        }
    }
    var title: String {
        switch self {
            
        case  .home: return "Home"
        case  .favourites: return "Favourites"
        case  .profile: return "Profile"
        }

    }
    
    var color: Color {
        switch self {
            
        case  .home: return .red
        case  .favourites: return .blue
        case  .profile: return .green
        }
    }
}

