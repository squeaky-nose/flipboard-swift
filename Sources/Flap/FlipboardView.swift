//
//  FlipboardView.swift
//  Flipper
//
//  Created by Sushant Verma on 12/10/2025.
//

import SwiftUI
import Combine

// Higher-level view that handles sequential flipping through intermediate letters
//
// Deliberately has no GeometryReader (or any other self-measurement) of its own. Its size is
// entirely dictated by the `.frame(width:height:)` its caller (`FlipGridView`'s `cellView`)
// applies, which in turn comes from `flapSize` — computed once, at the top, in
// `FlipGridViewModel.recalculateGrid` from the single outer GeometryReader in `FlipGridView`.
// A child that measures its own rendered content instead of accepting a size handed down from
// the top is exactly what caused the original resize bug: each cell's reported size would depend
// on what it currently displayed, letting a small change in content feed back into a change in
// canvas measurement, feed back into a change in layout, forever. Keep sizing one-directional —
// top-level canvas -> `flapSize` -> this view's `.frame()` — never the reverse.
public struct FlipboardView: View {
    let fontSize: CGFloat
    let cornerRadius: CGFloat = 10
    @Binding var targetLetter: Character
    @State private var currentLetter: Character
    @State private var flipTask: Task<Void, Never>? = nil

    @StateObject private var viewModel: FlapViewModel

    public init(fontSize: CGFloat, targetLetter: Binding<Character>, cycle: FlipAlphabet = .full) {
        self.fontSize = fontSize
        self._targetLetter = targetLetter
        // Both `currentLetter` (the rotation baseline) and the view model's displayed letter are
        // seeded from the letter this view is actually created to show — never a hardcoded blank.
        // A resize gives every tile a fresh identity (new FlipCell id, see `FlipGridViewModel.
        // setCells`'s shape-changed branch), so this init path runs again even for tiles whose
        // target letter isn't changing at all. `onChange(of: targetLetter)` below only fires on a
        // later *change*, never for the initial value, so a tile seeded at blank here would stay
        // blank on screen until its letter happened to change to something else — exactly the bug
        // this seeding fixes. See `FlapViewModel.init` for the other half of this.
        self._currentLetter = State(initialValue: targetLetter.wrappedValue)
        self._viewModel = StateObject(wrappedValue: FlapViewModel(cycle: cycle, initialLetter: targetLetter.wrappedValue))
    }

    public var body: some View {
        ZStack(alignment: .center) {
            Color.flapBackground
                .cornerRadius(cornerRadius)

            Text(viewModel.displayLetter)
                .font(.system(size: fontSize, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .fontWeight(.bold)
                .foregroundColor(.flapText)
                // Scales with fontSize rather than a flat 10pt: a fixed inset barely registers on
                // tv's typically-large tiles, but on a small tile (Mac's grid now goes well below
                // tv's minimum size) it eats a large fraction of the available width, squeezing a
                // wide glyph like an emoji into much less room than it actually has.
                .padding(.horizontal, max(2, fontSize * 0.08))
                .frame(maxWidth: .infinity)
                .animation(.linear(duration: viewModel.animationSpeed*4), value: viewModel.displayLetter)

            Color.flapSeparator
                .frame(height: 2)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.flapSeparator)
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
    @Previewable @State var letter: Character = " "
    VStack {
        FlipboardView(fontSize: 60, targetLetter: $letter)
            .frame(width: 70, height: 90)
        Button("Flip to A") {
            letter = "A"
        }
        Button("Flip to z") {
            letter = "z"
        }
        Button("Flip to 🥔") {
            letter = "🥔"
        }
    }
}
