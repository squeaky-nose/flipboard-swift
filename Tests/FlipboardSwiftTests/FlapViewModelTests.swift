import Testing
@testable import FlipboardSwift

struct FlapViewModelTests {
    @Test
    func defaultsToABlankDisplayLetterWhenNoInitialLetterIsGiven() {
        let viewModel = FlapViewModel(cycle: .full)
        #expect(viewModel.displayLetter == " ")
    }

    // Regression test for a bug where every tile went blank on a resize: `FlipboardView` gets a
    // brand-new `FlapViewModel` whenever its grid's shape changes (see `FlipGridViewModel.
    // setCells`), even for tiles whose target letter isn't actually changing. `displayLetter` used
    // to always start at a hardcoded blank space and rely on `onChange(of: targetLetter)` to reach
    // the real letter — but that only fires on a later *change*, never for the initial value, so
    // an unchanged tile stayed blank forever. `initialLetter` must seed `displayLetter` directly.
    @Test
    func initialLetterSeedsTheDisplayedLetterWithoutNeedingAFlip() {
        let viewModel = FlapViewModel(cycle: .full, initialLetter: "D")
        #expect(viewModel.displayLetter == "D")
    }

    @Test
    func sameCharacterProducesNoRotation() {
        let viewModel = FlapViewModel(cycle: .full)
        #expect(viewModel.rotation(from: "a", to: "a").isEmpty)
    }

    @Test
    func rotationEndsOnTheTargetCharacter() {
        let viewModel = FlapViewModel(cycle: .full)
        let plan = viewModel.rotation(from: "a", to: "d")
        #expect(plan.last == "d")
    }

    @Test
    func digitsOnlyCycleNeverProducesALetter() {
        let viewModel = FlapViewModel(cycle: .digitsOnly)
        let plan = viewModel.rotation(from: "1", to: "9")
        #expect(plan.allSatisfy { $0.isNumber })
    }

    @Test
    func digitsOnlyCycleWrapsThroughSpaceWhenGoingBackwards() {
        // 9 -> 1 has no forward path within 0...9, so it must wrap via the cycle's start (space).
        let viewModel = FlapViewModel(cycle: .digitsOnly)
        let plan = viewModel.rotation(from: "9", to: "1")
        #expect(plan.last == "1")
        #expect(plan.allSatisfy { $0.isNumber || $0 == " " })
    }

    @Test
    func bothCharactersUnknownToTheCycleSnapsDirectlyToTarget() {
        // Neither emoji is in .digitsOnly, so there's no path to step through — direct snap.
        let viewModel = FlapViewModel(cycle: .digitsOnly)
        #expect(viewModel.rotation(from: "🥔", to: "🥑") == ["🥑"])
    }

    @Test
    func unknownSourceCyclesFromTheStartOfTheAlphabet() {
        // The source character isn't in .digitsOnly but the target is, so it cycles from the
        // cycle's first character up to the target rather than snapping.
        let viewModel = FlapViewModel(cycle: .digitsOnly)
        let plan = viewModel.rotation(from: "🥔", to: "5")
        #expect(plan.last == "5")
        #expect(plan.first == " ")
    }
}
