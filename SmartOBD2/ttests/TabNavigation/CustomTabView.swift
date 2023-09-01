//
//  CustomTabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/12/23.
//

import SwiftUI

struct CustomTabView: View {
    let tabs: [TabBarItem]
    
    @Binding var tabSelection: TabBarItem
    @Binding var show : Bool
    @State private var dragAmount: CGPoint?


    
    var body: some View {
        tabBarV3
    }
}


struct CustomTabView_Previews: PreviewProvider {
    static let tabs: [TabBarItem] = [.home, .favourites, .profile
        ]

    
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabView(tabs: tabs, tabSelection: .constant(tabs.first!), show: .constant(true))
        }
    }
}

extension CustomTabView {
    private func customTabView(tab: TabBarItem) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.subheadline)
            Text(tab.title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
        }
        .foregroundColor(tabSelection == tab ? tab.color : Color.gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(tabSelection == tab ? tab.color.opacity(0.2): Color.clear)
        .cornerRadius(10)
    }
    
    private var tabBarV1: some View {
        HStack {
            ForEach(tabs, id:\.self) { tab in
                customTabView(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(6)
        .background(.white)
    }
    
    private func switchToTab(tab: TabBarItem) {
        withAnimation(.easeInOut) {
            tabSelection = tab
        }
    }
}

extension CustomTabView {
    private func customTabView2(tab: TabBarItem) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.subheadline)
            Text(tab.title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
        }
        .foregroundColor(tabSelection == tab ? tab.color : Color.gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if tabSelection == tab {
                   RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                }})
    }
    
    private var tabBarV2: some View {
        HStack {
            ForEach(tabs, id:\.self) { tab in
                customTabView2(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(6)
        .background(.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

extension CustomTabView {
    private func customTabView3(tab: TabBarItem) -> some View {
        Button {
            self.show.toggle()
            switchToTab(tab: tab)
        } label: {
            ZStack {
                Circle()
                    .fill(tabSelection == tab ? tab.color : Color.clear)
                    .frame(width: 50, height: 50)
                Image(systemName: tab.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(tabSelection == tab ? Color.white : Color.gray)

            }
        }
        .background(
            ZStack {
                if tabSelection == tab {
                   RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color)
                }})
        .foregroundColor(Color.white)
    }
    
    private var tabBar: some View {
        ZStack {
            VStack(spacing : 20) {
                if self.show {
                    
                    ForEach(tabs, id:\.self) { tab in
                        customTabView3(tab: tab)
                            .onTapGesture {
                                switchToTab(tab: tab)
                            }
                    }
                }
                Spacer()
                Button(action: {
                    self.show.toggle()
                }){
                    Image(systemName: "chevron.up")
                        .resizable()
                        .frame(width: 22, height: 12)
                        .padding(22)
                }
                .background(Color.green)
                .foregroundColor(Color.white)
                .clipShape(Circle())
                .rotationEffect(.init(degrees: self.show ? 180 : 0))
            }
            .animation(.spring(), value: self.show)

        }
    }
    
    private var tabBarV3: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    tabBar
                        .frame(width: 50, height: 50)
                        .padding(0)
                        .position(
                            x: max(16, min(dragAmount?.x ?? geometry.size.width - 34, geometry.size.width - 34)),
                            y: max(100, min(dragAmount?.y ?? geometry.size.height - 100, geometry.size.height - 100))
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newDragAmount = CGPoint(x: value.location.x, y: value.location.y)
                                    withAnimation {
                                        dragAmount = newDragAmount
                                    }
                                                                }
                                .onEnded { value in
                                    var currentPostion = value.location
                                    
                                    if currentPostion.x > (geometry.size.width/2) {
                                        currentPostion.x = geometry.size.width-34
                                    } else {
                                        currentPostion.x =  16
                                    }
                                    
                                    withAnimation(.easeOut(duration: 0.05)) {
                                        dragAmount = currentPostion
                                    }
                                }
                        )
                }
            }
        }
    }

}


