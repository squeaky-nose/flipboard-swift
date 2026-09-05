import Testing
@testable import FlipboardSwift

struct GridLayoutTests {
    @Test
    func splitsLongLinesOnWordBoundaries() {
        let lines = GridLayout.splitIntoLines("the quick brown fox", maxLength: 10)
        #expect(lines == ["the quick", "brown fox"])
    }

    @Test
    func preservesIntentionalBlankLines() {
        let lines = GridLayout.splitIntoLines("first\n\nthird", maxLength: 10)
        #expect(lines == ["first", "", "third"])
    }

    @Test
    func verticallyAlignsTop() {
        let aligned = GridLayout.verticallyAlign(["a"], to: 3, alignment: .top)
        #expect(aligned == ["a", "", ""])
    }

    @Test
    func verticallyAlignsBottom() {
        let aligned = GridLayout.verticallyAlign(["a"], to: 3, alignment: .bottom)
        #expect(aligned == ["", "", "a"])
    }

    @Test
    func verticallyAlignsCenter() {
        let aligned = GridLayout.verticallyAlign(["a"], to: 4, alignment: .center)
        #expect(aligned == ["", "a", "", ""])
    }

    @Test
    func padsLeftAligned() {
        #expect(GridLayout.pad("hi", to: 5, alignment: .left) == "hi   ")
    }

    @Test
    func padsRightAligned() {
        #expect(GridLayout.pad("hi", to: 5, alignment: .right) == "   hi")
    }

    @Test
    func padsCenterAligned() {
        #expect(GridLayout.pad("hi", to: 6, alignment: .center) == "  hi  ")
    }

    @Test
    func padDoesNothingWhenLineAlreadyAtOrOverLength() {
        #expect(GridLayout.pad("hello", to: 5, alignment: .left) == "hello")
        #expect(GridLayout.pad("hello world", to: 5, alignment: .left) == "hello world")
    }
}
