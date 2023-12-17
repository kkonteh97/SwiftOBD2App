//
//  DashBoardView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import SwiftUI

struct DashBoardView: View {
    @ObservedObject var liveDataViewModel: LiveDataViewModel

    var body: some View {
        LiveDataView(viewModel: liveDataViewModel)
    }
}

struct LogsView: View {
    var body: some View {
        Text("Hello World")
    }
}

//#Preview {
//    DashBoardView(liveDataViewModel: LiveDataViewModel(obdService: OBDService(),
//                                                       garage: Garage()))
//}
