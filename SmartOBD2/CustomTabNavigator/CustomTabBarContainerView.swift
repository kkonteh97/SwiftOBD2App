//
//  CustomTabBarContainerView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
//

import SwiftUI

struct CustomTabBarContainerView<Content: View>: View {
    @ObservedObject var viewModel: BottomSheetViewModel

    @Binding var selection: TabBarItem
    let maxHeight: Double
    let content: Content
    @State private var tabs: [TabBarItem] = []
    @Binding private var displayType: BottomSheetType

    init(
         selection: Binding<TabBarItem>,
         displayType: Binding<BottomSheetType>,
         maxHeight: Double,
         viewModel: BottomSheetViewModel,
         @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self._displayType = displayType
        self.maxHeight = maxHeight
        self.viewModel = viewModel
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            CustomTabBarView(
                        tabs: tabs,
                        viewModel: viewModel,
                        selection: $selection,
                        displayType: $displayType,
                        maxHeight: proxy.size.height
                ) {
                    content
                        .ignoresSafeArea()
                }
                .onPreferenceChange(TabBarItemsPK.self, perform: { value in
                    self.tabs = value
            })
        }
    }
}

struct CustomTabBarContainerView_Previews: PreviewProvider {
    static let tabs: [TabBarItem] = [
        .dashBoard,
        .features
    ]

    static var previews: some View {
        GeometryReader { proxy in

            CustomTabBarContainerView(selection: .constant(tabs.first!),
                                      displayType: .constant(.quarterScreen),
                                      maxHeight: proxy.size.height,
                                      viewModel: BottomSheetViewModel(obdService: OBDService(bleManager: BLEManager()),
                                                                      garage: Garage())
            ) {
                Color.red
            }
        }
    }
}
