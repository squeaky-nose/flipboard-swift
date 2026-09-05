//
//  FlapViewModel.swift
//  Flipper
//
//  Created by Sushant Verma on 15/10/2025.
//

import SwiftUI
import Combine

class FlapViewModel: ObservableObject {
    let cycle: FlipAlphabet

    @Published var displayLetter: String = " "
    let animationSpeed: TimeInterval = 0.03

    init(cycle: FlipAlphabet = .full) {
        self.cycle = cycle
    }

    func rotation(from fromChar: Character, to toChar: Character) -> [Character] {
        guard fromChar != toChar else {
            // No need to rotate
            return []
        }

        let alphabet = cycle.characters
        let currentIndex = alphabet.firstIndex(of: fromChar)
        let targetIndex = alphabet.firstIndex(of: toChar)

        switch (currentIndex, targetIndex) {
        case (nil, nil):
            // both unknown - just cycle
            return [toChar]
        case (nil, _):
            // from is unknown - cycle from start
            return Array(alphabet[...targetIndex!])
        case (_, nil):
            let nextIndex = alphabet.index(after: currentIndex!)
            return Array(alphabet[nextIndex...]) + [toChar]
        case (_, _):
            // both are valid
            break
        }

        guard let currentIndex = alphabet.firstIndex(of: fromChar),
              let targetIndex = alphabet.firstIndex(of: toChar) else {
            // If either character isn't in the alphabet, snap directly
            return [toChar]
        }

        let nextIndex = alphabet.index(after: currentIndex)
        if targetIndex > currentIndex {
            //forward
            return Array(alphabet[nextIndex...targetIndex])
        } else {
            let fractureToEnd = Array(alphabet[nextIndex...])
            let startToFacture = Array(alphabet[...targetIndex])

            return fractureToEnd + startToFacture
        }
    }

}
