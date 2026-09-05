import Testing
import CoreGraphics
import Foundation
@testable import FlipboardSwift

@MainActor
struct FlipGridViewModelTests {
    // The debounce on canvasSize is 50ms; poll for up to 2s rather than sleeping a fixed amount,
    // to keep this fast on a healthy run and still reliable under load.
    private func waitUntil(timeoutSeconds: Double = 2, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    // The concrete regression test for ".fixed should set tile count directly, not derive it from
    // canvas size" — the original design only had .autoFit, faked by AppleTV shrinking `size`.
    @Test
    func fixedDimensionsProduceExactlyTheRequestedTileCount() async {
        let dataSource = FlipGridDataSource()
        dataSource.dimensions = .fixed(rows: 4, columns: 7)
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        viewModel.canvasSize = CGSize(width: 1000, height: 1000)
        await waitUntil { viewModel.flapCount == CGSize(width: 7, height: 4) }

        #expect(viewModel.flapCount == CGSize(width: 7, height: 4))
    }

    @Test
    func fixedDimensionsStayConstantAcrossDifferentCanvasSizes() async {
        let dataSource = FlipGridDataSource()
        dataSource.dimensions = .fixed(rows: 3, columns: 5)
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        viewModel.canvasSize = CGSize(width: 300, height: 300)
        await waitUntil { viewModel.flapCount == CGSize(width: 5, height: 3) }
        #expect(viewModel.flapCount == CGSize(width: 5, height: 3))

        viewModel.canvasSize = CGSize(width: 2000, height: 2000)
        await waitUntil { viewModel.flapSize.width > 50 }
        // Tile count is unchanged; only tile size grows to fill the larger canvas.
        #expect(viewModel.flapCount == CGSize(width: 5, height: 3))
    }

    @Test
    func autoFitDerivesTileCountFromCanvasSize() async {
        let dataSource = FlipGridDataSource(initialSize: 1)
        dataSource.dimensions = .autoFit
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        viewModel.canvasSize = CGSize(width: 200, height: 200)
        await waitUntil { viewModel.flapCount.width > 0 }

        #expect(viewModel.flapCount.width > 0)
        #expect(viewModel.flapCount.height > 0)
    }

    @Test
    func zeroSizeCanvasProducesNoNaNOrInfiniteTileSize() async {
        let dataSource = FlipGridDataSource()
        dataSource.dimensions = .autoFit
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        viewModel.canvasSize = .zero
        await waitUntil(timeoutSeconds: 0.5) { viewModel.canvasSize == .zero }
        try? await Task.sleep(nanoseconds: 100_000_000) // let the debounced pipeline settle

        #expect(!viewModel.flapSize.width.isNaN)
        #expect(!viewModel.flapSize.height.isNaN)
        #expect(viewModel.flapSize.width.isFinite)
        #expect(viewModel.flapSize.height.isFinite)
    }

    @Test
    func dataSourceCellsTakePriorityOverMessage() async {
        let dataSource = FlipGridDataSource()
        dataSource.dimensions = .fixed(rows: 1, columns: 1)
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        viewModel.canvasSize = CGSize(width: 100, height: 100)
        await waitUntil { viewModel.flapCount == CGSize(width: 1, height: 1) }

        dataSource.message = "should not appear"
        dataSource.cells = [[FlipCell(row: 0, column: 0, character: "Z", kind: .label)]]

        await waitUntil { viewModel.cells.first?.first?.character == "Z" }

        #expect(viewModel.cells.first?.first?.character == "Z")
        #expect(viewModel.cells.first?.first?.kind == .label)
    }

    @Test
    func setCellsPreservesIdentityByPositionAcrossUpdates() {
        let dataSource = FlipGridDataSource()
        let viewModel = FlipGridViewModel(dataSource: dataSource)

        let first = [[FlipCell(row: 0, column: 0, character: "1")]]
        viewModel.setCells(first)
        let firstID = viewModel.cells[0][0].id

        let second = [[FlipCell(row: 0, column: 0, character: "2")]]
        viewModel.setCells(second)

        #expect(viewModel.cells[0][0].id == firstID)
        #expect(viewModel.cells[0][0].character == "2")
    }
}
