//
//  CustomTabBarContainerView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/4/23.
//

import SwiftUI

struct CustomTabBarContainerView<Content: View>: View {
    @Binding var selection: TabBarItem
    let maxHeight: Double
    let content: Content
    @State private var tabs: [TabBarItem] = []
    @Binding var displayType: BottomSheetType
    @Binding var statusMessage: String?
    init(
         selection: Binding<TabBarItem>,
         maxHeight: Double,
         displayType: Binding<BottomSheetType>,
         statusMessage: Binding<String?>,
         @ViewBuilder content: () -> Content
    ) {
        self._selection       = selection
        self.maxHeight        = maxHeight
        self._displayType     = displayType
        self._statusMessage = statusMessage
        self.content          = content()
    }

    var body: some View {
        GeometryReader { proxy in
            CustomTabBarView(
                        tabs: tabs,
                        selection: $selection,
                        maxHeight: proxy.size.height,
                        displayType: $displayType,
                        statusMessage: $statusMessage
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

//struct CustomTabBarContainerView_Previews: PreviewProvider {
//    static let tabs: [TabBarItem] = [.dashBoard, .features]
//    static var previews: some View {
//        GeometryReader { proxy in
//            CustomTabBarContainerView(selection: .constant(tabs.first!),
//                                      maxHeight: proxy.size.height,
//                                      viewModel: CustomTabBarViewModel(obdService: OBDService(),
//                                                                      garage: Garage())
//            ) {
//                Color.red
//            }
//        }
//    }
//}
