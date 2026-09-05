//
//  FlipGridViewModel.swift
//  Flipper
//
//  Created by Sushant Verma on 18/10/2025.
//

import Combine
import CoreGraphics
import SwiftUI

/// Whether a cell animates as a split-flap tile or prints as static text — needed so scoreboard
/// column labels (and similar fixed text) don't flip like dynamic content does.
public enum CellKind: Sendable, Equatable {
    case flap
    case label
}

public struct FlipCell: Identifiable, Equatable {
    public let id: UUID
    public var row: Int
    public var column: Int
    public var character: Character
    public var kind: CellKind
    public var cycle: FlipAlphabet

    public init(row: Int, column: Int, character: Character, kind: CellKind = .flap, cycle: FlipAlphabet = .full, id: UUID = UUID()) {
        self.id = id
        self.row = row
        self.column = column
        self.character = character
        self.kind = kind
        self.cycle = cycle
    }
}

@MainActor
public class FlipGridViewModel: ObservableObject {
    let dataSource: FlipGridDataSource
    @Published var itemSpacing: CGFloat = 0

    private var lastKnownCanvasSize: CGSize = .zero
    @Published var canvasSize: CGSize = .zero
    @Published var flapCount: CGSize = .zero
    @Published var spacerCount: CGSize = .zero
    @Published var spacerSize: CGSize = .zero
    @Published var flapSize: CGSize = .zero
    @Published var fontSize: CGFloat = 1
    @Published var numberOfItems: Int = 0
    @Published var columns: [GridItem] = []

    @Published var cells: [[FlipCell]] = []

    private let logger = AutoLogger.unifiedLogger()

    private var cancellables = Set<AnyCancellable>()

    public init(dataSource: FlipGridDataSource) {
        logger.info("Creating FlipGridViewModel")
        self.dataSource = dataSource

        $canvasSize
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] size in
                guard let self else { return }

                lastKnownCanvasSize = size
                recalculateGrid(size)
                setContent(dataSource)
            }
            .store(in: &cancellables)

        dataSource
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }

                recalculateGrid(lastKnownCanvasSize)
                setContent(dataSource)
            }
            .store(in: &cancellables)
    }

    private func recalculateGrid(_ availableSize: CGSize) {
        itemSpacing = CGFloat(5 * dataSource.size)

        switch dataSource.dimensions {
        case .autoFit:
            let minItemSize = CGSize(width: 14 * dataSource.size,
                                     height: 18 * dataSource.size)
            flapCount = CGSize(width: floor(availableSize.width / (minItemSize.width + itemSpacing)),
                               height: floor(availableSize.height / (minItemSize.height + itemSpacing)))
        case let .fixed(rows, columns):
            // Explicit tile count regardless of canvas size — tiles scale to fill the available
            // space instead of the count changing. This is what lets AppleTV's remote up/down set
            // tile count directly, instead of faking it via `size`.
            flapCount = CGSize(width: max(0, columns), height: max(0, rows))
        }

        spacerCount = CGSize(width: max(0, flapCount.width - 1),
                             height: max(0, flapCount.height - 1))
        spacerSize = CGSize(width: floor(spacerCount.width * itemSpacing),
                            height: floor(spacerCount.height * itemSpacing))

        if flapCount.width > 0, flapCount.height > 0 {
            flapSize = CGSize(width: floor((availableSize.width - spacerSize.width) / flapCount.width),
                              height: floor((availableSize.height - spacerSize.height) / flapCount.height))
        } else {
            // Avoid propagating NaN/Inf sizes into SwiftUI layout when the canvas is too small to
            // fit even one tile (or a `.fixed` grid is asked for zero rows/columns).
            flapSize = .zero
        }

        fontSize = flapSize.height / 2
        numberOfItems = Int(flapCount.width * flapCount.height)
        columns = [ GridItem(.adaptive(minimum: max(flapSize.width, 1)), spacing: itemSpacing) ]
    }

    @MainActor
    public func setContent(_ dataSource: FlipGridDataSource) {
        let lineLength = Int(flapCount.width)
        let maxLines = max(1, Int(flapCount.height))

        var lines = GridLayout.splitIntoLines(dataSource.message, maxLength: lineLength)
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines))
        }
        lines = GridLayout.verticallyAlign(lines, to: maxLines, alignment: dataSource.verticalTextAlignment)

        let content = lines
            .map { GridLayout.pad($0, to: lineLength, alignment: dataSource.horizontalTextAlignment) }
            .joined(separator: "")

        setContent(content)
    }

    public func setContent(_ content: String) {
        let rows = Int(flapCount.height)
        let columnsCount = Int(flapCount.width)

        guard rows > 0, columnsCount > 0 else {
            cells = []
            numberOfItems = 0
            return
        }

        let maxCount = rows * columnsCount
        let chars = Array(content.prefix(maxCount))
        let padded = chars + Array(repeating: Character(" "),
                                   count: max(0, maxCount - chars.count))

        let centerRow = (rows - 1) / 2
        let centerColumn = (columnsCount - 1) / 2

        var newGrid: [[FlipCell]] = []
        var index = 0
        for row in 0..<rows {
            let centeredRow = row - centerRow
            var rowCells: [FlipCell] = []
            for column in 0..<columnsCount {
                let centeredColumn = column - centerColumn
                let character = index < padded.count ? padded[index] : " "
                index += 1
                rowCells.append(FlipCell(row: centeredRow, column: centeredColumn, character: character))
            }
            newGrid.append(rowCells)
        }

        setCells(newGrid)
    }

    /// Sets the grid's content directly from an already-laid-out grid of cells (produced by
    /// `FlipboardPayloadRenderer`/`ClockContentRenderer`/etc.), rather than a single wrapped string —
    /// needed for content with a mix of flap and label cells (a scoreboard) or a non-full flip
    /// alphabet (a clock's digits). Existing cell identities are preserved by (row, column) position
    /// so ticking content (a clock) updates its tiles in place instead of insert/remove-animating
    /// the whole grid on every refresh.
    public func setCells(_ grid: [[FlipCell]]) {
        var merged: [[FlipCell]] = []
        for (row, rowCells) in grid.enumerated() {
            var mergedRow: [FlipCell] = []
            for (column, newCell) in rowCells.enumerated() {
                if row < cells.count, column < cells[row].count {
                    var existing = cells[row][column]
                    existing.row = newCell.row
                    existing.column = newCell.column
                    existing.character = newCell.character
                    existing.kind = newCell.kind
                    existing.cycle = newCell.cycle
                    mergedRow.append(existing)
                } else {
                    mergedRow.append(newCell)
                }
            }
            merged.append(mergedRow)
        }

        cells = merged
        numberOfItems = merged.reduce(0) { $0 + $1.count }
    }
}
