//
//  CustomTabBarContainerView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/16/23.
//

import SwiftUI

struct CustomTabBarContainerView<Content: View> : View {
    
    @Binding var selection: TabBarItem
    
    let content: Content
    @State private var tabs: [TabBarItem] = []
    @State private var show = false
    
    
    public init(selection: Binding<TabBarItem>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
        

    }
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                content
                
                CustomTabView(tabs: tabs, tabSelection: $selection, show: $show)
                    .padding(.horizontal, 10)
            }
        }
        .onPreferenceChange(TabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}

struct CustomTabBarContainerView_Previews: PreviewProvider {
    static let tabs: [TabBarItem] = [.home, .favourites, .profile
        ]
    static var previews: some View {
        CustomTabBarContainerView(selection: .constant(tabs.first!)) {
            Color.red
        }
    }
}
