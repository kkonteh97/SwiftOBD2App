//
//  AsyncBootcamp.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/24/23.
//

import SwiftUI

class AsyncBootcampVM: ObservableObject {
    @Published var dataArray: [String] = []
    
    func addTitle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dataArray.append("Title1: \(Thread.current)")
        }
    }
    
    func addTitle2() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let title = "Title2 : \(Thread.current)"
            DispatchQueue.main.async {
                self.dataArray.append(title)
            }
        }
        
        
    }
    
}

struct AsyncBootcamp: View {
    @StateObject private var viewModel = AsyncBootcampVM()
    var body: some View {
        List {
            ForEach(viewModel.dataArray, id: \.self) { data in
                Text(data)
            }
        }
        .onAppear {
            viewModel.addTitle()
            viewModel.addTitle2()
        }
    }
    
}

#Preview {
    AsyncBootcamp()
}
