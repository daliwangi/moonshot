//
//  ContentView.swift
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-01.
//

import SwiftUI

struct ContentView: View {
    @State private var isMoonCaptureViewPresented = false
    @StateObject private var viewModel = MoonCaptureViewModel() // 添加 viewModel

    var body: some View {
        VStack {
            Button("拍摄月亮") {
                isMoonCaptureViewPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .fullScreenCover(isPresented: $isMoonCaptureViewPresented, content: {
            MoonCaptureView(viewModel: viewModel)
        })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
