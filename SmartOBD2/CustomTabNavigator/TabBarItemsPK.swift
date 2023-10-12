//
//  TabBarItemsPK.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
//

import SwiftUI

struct TabBarItemsPK: PreferenceKey {
    static var defaultValue: [TabBarItem] = []

    static func reduce(value: inout [TabBarItem], nextValue: () -> [TabBarItem]) {
        value += nextValue()
    }
}

struct TabBarItemsViewModifier: ViewModifier {
    let tab: TabBarItem
    @Binding var selection: TabBarItem

    func body(content: Content) -> some View {
        content
            .opacity(selection == tab ? 1 : 0)
            .preference(key: TabBarItemsPK.self, value: [tab])
    }
}

extension View {
    func tabBarItem(tab: TabBarItem, selection: Binding<TabBarItem>) -> some View {
         modifier(TabBarItemsViewModifier(tab: tab, selection: selection))
    }
}
