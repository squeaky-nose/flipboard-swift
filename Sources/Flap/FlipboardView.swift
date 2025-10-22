//
//  FlipboardView.swift
//  Flipper
//
//  Created by Sushant Verma on 12/10/2025.
//

import SwiftUI
import Combine

// Higher-level view that handles sequential flipping through intermediate letters
public struct FlipboardView: View {
    let fontSize: CGFloat
    let cornerRadius: CGFloat = 10
    @Binding var targetLetter: Character
    @State private var currentLetter: Character = " "
    @State private var flipTask: Task<Void, Never>? = nil

    @StateObject private var viewModel = FlapViewModel()

    public init(fontSize: CGFloat, targetLetter: Binding<Character>) {
        self.fontSize = fontSize
        self._targetLetter = targetLetter
    }

    public var body: some View {
        ZStack(alignment: .center) {
            Color.flapBackground
                .cornerRadius(cornerRadius)

            Text(viewModel.displayLetter)
                .font(.system(size: fontSize, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.flapText)
                .padding(10)
                .frame(maxWidth: .infinity)
                .animation(.linear(duration: viewModel.animationSpeed*4), value: viewModel.displayLetter)

            Color.flapSeparator
                .frame(height: 2)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.flapSeparator)
        }
        .onAppear {
            viewModel.displayLetter = String(currentLetter)
        }
        .onChange(of: targetLetter) { _, newTarget in
            // Cancel any in-flight stepping task to avoid overlapping animations
            flipTask?.cancel()

            flipTask = Task {
                let flipPlan = viewModel.rotation(from: currentLetter, to: targetLetter)

                for letter in flipPlan {
                    if Task.isCancelled { return }

                    Task { @MainActor in
                        viewModel.displayLetter = String(letter)
                        currentLetter = letter
                    }
                    try? await Task.sleep(for: .seconds(viewModel.animationSpeed))
                }
            }
        }
    }
}

// Preview
#Preview {
    @Previewable @State var letter: Character = "A"
    VStack {
        FlipboardView(fontSize: 50, targetLetter: $letter)
        Button("Flip to A") {
            letter = "A"
        }
        Button("Flip to z") {
            letter = "z"
        }
    }
}
