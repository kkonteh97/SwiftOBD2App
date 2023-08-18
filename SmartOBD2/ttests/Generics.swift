//
//  Generics.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/14/23.
//

import SwiftUI

struct StringModel {
    let info: String?
    
    func removeInfo() -> StringModel {
        return StringModel(info: nil)
    }
}

struct GenericModel<T> {
    
    let info: T?
    
    func removeInfo() -> GenericModel {
        return GenericModel(info: nil)
    }
}

class GenericsVM: ObservableObject {
    @Published var sm = StringModel(info:"Hello world")
    @Published var gm = GenericModel(info:"Hello world")
    
    func removeData() {
        sm = sm.removeInfo()
        gm = gm.removeInfo()
    }
}


struct GenericView<T:View>: View {
    let content: T
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
            content
        }
    }
}

struct Generics: View {
    @StateObject private var vm = GenericsVM()
    
    
    var body: some View {
        VStack {
            //GenericView(title: "new View")
            Text(vm.sm.info ?? "no data")
            Text(vm.gm.info ?? "no data")
                
        }
        .onTapGesture {
            vm.removeData()

        }
    }
}

struct Generics_Previews: PreviewProvider {
    static var previews: some View {
        Generics()
    }
}
