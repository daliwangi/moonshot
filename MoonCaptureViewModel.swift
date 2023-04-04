//
//  MoonCaptureViewModel.swift
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-03.
//

import Foundation
import Combine

class MoonCaptureViewModel: ObservableObject {
    @Published var instructionText: String = "将镜头对准月亮" {
        didSet {
            debugPrint("Instruction text updated: \(instructionText)")
        }
    }

    func updateInstructionText(newText: String) {
        DispatchQueue.main.async {
            self.instructionText = newText
        }
    }
}
