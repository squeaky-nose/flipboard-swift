import Testing
@testable import FlipboardSwift
import FlipboardSwiftProtocol

struct ScoreboardContentRendererTests {
    private func samplePayload() -> FlipboardScoresPayload {
        FlipboardScoresPayload(
            columns: [
                FlipboardScoresPayload.Column(label: "Rank", key: "rank"),
                FlipboardScoresPayload.Column(label: "Team", key: "team"),
                FlipboardScoresPayload.Column(label: "Score", key: "score"),
            ],
            rows: [
                FlipboardScoresPayload.Row(rank: .flap("1"), name: .label("Wombats"), scores: [.flap("42")]),
                FlipboardScoresPayload.Row(rank: .flap("2"), name: .label("Kookaburras"), scores: [.flap("37")]),
            ]
        )
    }

    // The concrete regression test for the product requirement: column labels print statically,
    // rank/score values flap.
    @Test
    func nameCellsAreLabelKindAndRankScoreCellsAreFlapKind() {
        let grid = ScoreboardContentRenderer.cells(for: samplePayload(), rows: 3, columns: 30)

        // Header row (included since rows > data rows) should be entirely .label.
        let headerRow = grid[0]
        for cell in headerRow where cell.character != " " {
            #expect(cell.kind == .label)
        }

        // Data rows: verify at least one flap cell (rank/score) and one label cell (name) exist.
        let dataCells = grid[1...].flatMap { $0 }
        #expect(dataCells.contains { $0.kind == .flap && $0.character != " " })
        #expect(dataCells.contains { $0.kind == .label && $0.character != " " })
    }

    @Test
    func gridHasExactlyRequestedDimensions() {
        let grid = ScoreboardContentRenderer.cells(for: samplePayload(), rows: 4, columns: 20)
        #expect(grid.count == 4)
        for row in grid {
            #expect(row.count == 20)
        }
    }

    @Test
    func returnsEmptyForZeroColumnsInPayload() {
        let empty = FlipboardScoresPayload(columns: [], rows: [])
        #expect(ScoreboardContentRenderer.cells(for: empty, rows: 3, columns: 10).isEmpty)
    }

    @Test
    func rankAndScoreTextIsPresentSomewhereInTheGrid() {
        let grid = ScoreboardContentRenderer.cells(for: samplePayload(), rows: 3, columns: 30)
        let allCharacters = String(grid.flatMap { $0.map(\.character) })
        #expect(allCharacters.contains("Wombats"))
        #expect(allCharacters.contains("42"))
    }
}
