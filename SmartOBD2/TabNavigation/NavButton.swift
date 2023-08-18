//
//  NavButton.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/12/23.
//

import SwiftUI

struct FloatingMenuButton : View {
    
    @Binding var show : Bool
    
    
    var body: some View {
            ZStack {
                VStack(spacing : 20) {
                    
                    if self.show {
                        
                        Button(action: {
                            self.show.toggle()
                        }) {
                            Image(systemName: "house").resizable().frame(width: 25, height: 15).padding(22)
                        }
                        .background(Color.gray)
                        .foregroundColor(Color.white)
                        .clipShape(Circle())
                        
                        Button(action: {
                            self.show.toggle()
                        }) {
                            Image(systemName: "car").resizable().frame(width: 25, height: 15).padding(22)
                        }
                        .background(Color.gray)
                        .foregroundColor(Color.white)
                        .clipShape(Circle())
                        
                        Button(action: {
                            self.show.toggle()
                        }) {
                            Image(systemName: "wrench.and.screwdriver").resizable().frame(width: 25, height: 15).padding(22)
                        }
                        .background(Color.gray)
                        .foregroundColor(Color.white)
                        .clipShape(Circle())
                    }
                    Button(action: {
                        self.show.toggle()
                    }) {
                        Image(systemName: "chevron.up").resizable().frame(width: 25, height: 15).padding(22)
                    }
                    .background(Color.green)
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
                    .rotationEffect(.init(degrees: self.show ? 180 : 0))
                }
                .animation(_:.spring(), value: self.show)
            }
    }
}


struct NavButton: View {
    @State var show = false

    @State private var dragAmount: CGPoint?
        var body: some View {
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        
                        FloatingMenuButton(show: $show)
                            .frame(width: 50, height: 50)
                            .padding(0)
                            .position(dragAmount ?? CGPoint(x: geometry.size.width-34, y: geometry.size.height-100))
                            .gesture(
                                DragGesture()
                                    .onChanged { self.dragAmount = $0.location }
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
            .padding(0)
        }
    }

struct NavButton_Previews: PreviewProvider {
    static var previews: some View {
        NavButton()
    
    }
}
