import Testing
@testable import FlipboardSwift

struct TextContentRendererTests {
    @Test
    func producesExactlyRowsByColumnsCells() {
        let grid = TextContentRenderer.cells(text: "hi", horizontalAlignment: .left, verticalAlignment: .top, rows: 3, columns: 4)
        #expect(grid.count == 3)
        for row in grid {
            #expect(row.count == 4)
        }
    }

    @Test
    func everyCellDefaultsToFlapKind() {
        let grid = TextContentRenderer.cells(text: "hi", horizontalAlignment: .left, verticalAlignment: .top, rows: 2, columns: 2)
        for row in grid {
            for cell in row {
                #expect(cell.kind == .flap)
            }
        }
    }

    @Test
    func returnsEmptyGridForZeroRowsOrColumns() {
        #expect(TextContentRenderer.cells(text: "hi", horizontalAlignment: .left, verticalAlignment: .top, rows: 0, columns: 4).isEmpty)
        #expect(TextContentRenderer.cells(text: "hi", horizontalAlignment: .left, verticalAlignment: .top, rows: 4, columns: 0).isEmpty)
    }

    @Test
    func cyclePolicyIsAppliedPerCharacter() {
        let grid = TextContentRenderer.cells(
            text: "a1",
            horizontalAlignment: .left,
            verticalAlignment: .top,
            rows: 1,
            columns: 2,
            cyclePolicy: { $0.isNumber ? .digitsOnly : .alphanumeric }
        )
        #expect(grid[0][0].character == "a")
        #expect(grid[0][0].cycle == .alphanumeric)
        #expect(grid[0][1].character == "1")
        #expect(grid[0][1].cycle == .digitsOnly)
    }

    @Test
    func textLongerThanGridIsTruncated() {
        let grid = TextContentRenderer.cells(text: "hello world this is way too long", horizontalAlignment: .left, verticalAlignment: .top, rows: 1, columns: 3)
        #expect(grid.count == 1)
        #expect(grid[0].count == 3)
    }
}
