//
//  test.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/18/23.
//

import SwiftUI

// constants

struct TestView: View {
    @State private var bottomSheetShown = false

     var body: some View {
         GeometryReader { geometry in
             Color.green
             BottomSheetView(
                 isOpen: self.$bottomSheetShown,
                 maxHeight: geometry.size.height * 0.6
             ) {
                 Color.blue
             }
         }.edgesIgnoringSafeArea(.all)
     }
}

#Preview {
    TestView()
}
