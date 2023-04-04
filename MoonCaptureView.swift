//
//  MoonCaptureView.swift
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-01.
//

import SwiftUI

struct MoonCaptureView: View {
    @ObservedObject var viewModel: MoonCaptureViewModel

    var body: some View {
        VStack {
            Text(viewModel.instructionText)
                .foregroundColor(Color.white)
                .padding()

            UIViewRepresentableMoonCaptureView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
        }
    }
}


struct UIViewRepresentableMoonCaptureView: UIViewRepresentable {
    var viewModel: MoonCaptureViewModel

    func makeUIView(context: Context) -> UIView {
        let moonCaptureViewController = MoonCaptureViewController()
        moonCaptureViewController.viewModel = viewModel
        debugPrint("ViewModel assigned to MoonCaptureViewController")
        return moonCaptureViewController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

struct MoonCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        MoonCaptureView(viewModel: MoonCaptureViewModel())
    }
}
