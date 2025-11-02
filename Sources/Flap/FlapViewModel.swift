//
//  FlapViewModel.swift
//  Flipper
//
//  Created by Sushant Verma on 15/10/2025.
//

import SwiftUI
import Combine

class FlapViewModel: ObservableObject {

    private static let empty: [Character] = Array(" ")
    private static let uppercase: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
    private static let digits: [Character] = Array("0123456789")
    private static let colours: [Character] = Array("🟥🟧🟨🟩🟦🟪🟫⬛⬜")

    private static let alphabet: [Character] = empty + uppercase + lowercase + digits + colours

    @Published var displayLetter: String = " "
    let animationSpeed: TimeInterval = 0.03

    func rotation(from fromChar: Character, to toChar: Character) -> [Character] {
        guard fromChar != toChar else {
            // No need to rotate
            return []
        }

        let currentIndex = Self.alphabet.firstIndex(of: fromChar)
        let targetIndex = Self.alphabet.firstIndex(of: toChar)

        switch (currentIndex, targetIndex) {
        case (nil, nil):
            // both unknown - just cycle
            return [toChar]
        case (nil, _):
            // from is unknown - cycle from start
            return Array(Self.alphabet[...targetIndex!])
        case (_, nil):
            let nextIndex = Self.alphabet.index(after: currentIndex!)
            return Array(Self.alphabet[nextIndex...]) + [toChar]
        case (_, _):
            // both are valid
            break
        }

        guard let currentIndex = Self.alphabet.firstIndex(of: fromChar),
              let targetIndex = Self.alphabet.firstIndex(of: toChar) else {
            // If either character isn't in the alphabet, snap directly
            return [toChar]
        }

        let nextIndex = Self.alphabet.index(after: currentIndex)
        if targetIndex > currentIndex {
            //forward
            return Array(Self.alphabet[nextIndex...targetIndex])
        } else {
            let fractureToEnd = Array(Self.alphabet[nextIndex...])
            let startToFacture = Array(Self.alphabet[...targetIndex])

            return fractureToEnd + startToFacture
        }
    }

}
