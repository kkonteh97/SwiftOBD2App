//
//  ViewBuilder.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/14/23.
//

import SwiftUI

struct HeaderViewR: View {
    let title: String
    let description: String?
    let iconName: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text(description ?? "")
                .font(.callout)
            Image(systemName: iconName ?? "")
            
            RoundedRectangle(cornerRadius: 5)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct HeaderViewGeneric<Content:View>: View {
    let title: String
    let content: Content
    
    init(title:String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            content
            
            RoundedRectangle(cornerRadius: 5)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
}


struct ViewBuildertest: View {
    var body: some View {
        VStack {
            HeaderViewR(title: "title", description: "hello", iconName: "heart.fill")
            HeaderViewR(title: "title", description: nil, iconName: "")
            HeaderViewGeneric(title: "Generic Title"){
                Text("hello")
                
            }
            
            Spacer()
        }
        
    }
}

struct ViewBuildertest_Previews: PreviewProvider {
    static var previews: some View {
        ViewBuildertest()
    }
}
