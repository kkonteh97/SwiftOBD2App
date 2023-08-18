//
//  PKBC.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/15/23.
//

import SwiftUI

struct PKBC: View {
    
    @State private var text: String = "Hello world"
    
    var body: some View {
        NavigationView {
            VStack {
                SecondScreen(text: text)
                    .navigationTitle("Nav Title")
                    .customTitle("new value!!!!")

                }
            }
        .onPreferenceChange(CustomTitlePK.self, perform: { value in
            self.text = value
        })
        
        }
}

struct PKBC_Previews: PreviewProvider {
    static var previews: some View {
        PKBC()
    }
}
struct SecondScreen: View {
    let text: String

    var body: some View {
        Text(text)
    }
}

extension View {
    func customTitle(_ title: String) -> some View {
        self.preference(key: CustomTitlePK.self, value: title)
    }
}




struct CustomTitlePK: PreferenceKey {
    static var defaultValue: String = ""

    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
    

}
