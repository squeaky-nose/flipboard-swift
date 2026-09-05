import Testing
@testable import FlipboardSwift
import FlipboardSwiftProtocol

struct FlipboardPayloadRendererTests {
    @Test
    func blockPayloadRendersAsFlapCells() {
        let payload = FlipboardPayload.block(block: FlipboardBlockPayload(text: "hi", position: .center))
        let grid = FlipboardPayloadRenderer.cells(for: payload, rows: 2, columns: 4)
        #expect(grid.count == 2)
        #expect(grid.flatMap { $0 }.allSatisfy { $0.kind == .flap })
    }

    @Test
    func clockPayloadDispatchesToClockRenderer() {
        let payload = FlipboardPayload.clock(clock: FlipboardClockPayload(timezoneIdentifier: "UTC"))
        let grid = FlipboardPayloadRenderer.cells(for: payload, rows: 1, columns: 5)
        #expect(grid.flatMap { $0 }.contains { $0.character.isNumber })
    }

    @Test
    func scoresPayloadDispatchesToScoreboardRendererWithLabelCells() {
        let payload = FlipboardPayload.scores(scores: FlipboardScoresPayload(
            columns: [FlipboardScoresPayload.Column(label: "Score", key: "score")],
            rows: [FlipboardScoresPayload.Row(rank: .flap("1"), name: .label("Wombats"), scores: [])]
        ))
        let grid = FlipboardPayloadRenderer.cells(for: payload, rows: 2, columns: 20)
        #expect(grid.flatMap { $0 }.contains { $0.kind == .label })
    }
}
