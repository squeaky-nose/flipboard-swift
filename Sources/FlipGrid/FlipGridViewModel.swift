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

        // Deliberately not `dataSource.objectWillChange` — recalculateGrid() writes back to
        // dataSource.resolvedDimensions (also `@Published`, so also part of objectWillChange),
        // which would re-enter this very sink mid-recalculation on every change and interleave two
        // partially-complete passes over @Published state, producing visible glitches.
        //
        // Geometry-affecting inputs only: changing these requires recomputing flapCount/flapSize
        // (and so resolvedDimensions) before redisplaying content at the new shape.
        Publishers.MergeMany([
            dataSource.$size.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            dataSource.$dimensions.dropFirst().map { _ in () }.eraseToAnyPublisher(),
        ])
        .receive(on: RunLoop.main)
        .sink { [weak self] in
            guard let self else { return }

            recalculateGrid(lastKnownCanvasSize)
            setContent(dataSource)
        }
        .store(in: &cancellables)

        // Content-only inputs: these change what's displayed within the *current* shape, not the
        // shape itself, so they only need setContent — never recalculateGrid. This matters
        // concretely for `cells`: the app writes it in direct response to `resolvedDimensions`
        // changing (re-rendering content for the new size), so if that write also re-triggered
        // recalculateGrid, it would write resolvedDimensions again, which the app would react to
        // again, forever — a real, previously-observed reentrant loop, not just a hypothetical one.
        Publishers.MergeMany([
            dataSource.$message.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            dataSource.$horizontalTextAlignment.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            dataSource.$verticalTextAlignment.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            dataSource.$cells.dropFirst().map { _ in () }.eraseToAnyPublisher(),
        ])
        .receive(on: RunLoop.main)
        .sink { [weak self] in
            guard let self else { return }

            setContent(dataSource)
        }
        .store(in: &cancellables)
    }

    /// Reserved so the grid's computed total size never sits exactly on the measured canvas
    /// boundary — stretching tiles to consume 100% of the available space with zero slack means
    /// any real-world subpixel/rounding difference between this math and SwiftUI's actual layout
    /// pushes the last row/column just past the edge, where `.clipped()` cuts it off outright.
    private static let layoutSafetyMargin: CGFloat = 2

    /// The single top-level place all grid sizing is computed — `flapSize`, `columns`, `flapCount`,
    /// `fontSize` all come from here and flow one-directionally down to the views: `FlipGridView`
    /// hands `flapSize` to each cell's `.frame()`, and `FlipboardView` (the flap tile) accepts that
    /// frame rather than measuring its own content. `availableSize` itself must come from the
    /// outer GeometryReader in `FlipGridView` (via `canvasSize`), not from measuring any child's
    /// rendered size — see that view's comment for why the reverse direction caused a real,
    /// previously-shipped resize feedback loop (bigger content -> bigger measured canvas -> even
    /// bigger content, unbounded).
    private func recalculateGrid(_ availableSize: CGSize) {
        itemSpacing = CGFloat(5 * dataSource.size)
        let safeAvailableSize = CGSize(width: max(0, availableSize.width - Self.layoutSafetyMargin),
                                        height: max(0, availableSize.height - Self.layoutSafetyMargin))

        switch dataSource.dimensions {
        case .autoFit:
            let minItemSize = CGSize(width: 14 * dataSource.size,
                                     height: 18 * dataSource.size)
            flapCount = CGSize(width: floor(safeAvailableSize.width / (minItemSize.width + itemSpacing)),
                               height: floor(safeAvailableSize.height / (minItemSize.height + itemSpacing)))
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
            flapSize = CGSize(width: floor((safeAvailableSize.width - spacerSize.width) / flapCount.width),
                              height: floor((safeAvailableSize.height - spacerSize.height) / flapCount.height))
        } else {
            // Avoid propagating NaN/Inf sizes into SwiftUI layout when the canvas is too small to
            // fit even one tile (or a `.fixed` grid is asked for zero rows/columns).
            flapSize = .zero
        }

        fontSize = flapSize.height / 2
        numberOfItems = Int(flapCount.width * flapCount.height)

        let rows = Int(flapCount.height)
        let columnCount = Int(flapCount.width)

        // Exactly `columnCount` fixed-width columns — not a single `.adaptive(minimum:)` item.
        // `.adaptive` lets LazyVGrid compute its own column count from the available width, which
        // can differ (even by one) from `columnCount` here due to rounding; since `cells` is a flat
        // sequence of `rows * columnCount` views to LazyVGrid, any such mismatch wraps rows at the
        // wrong boundary — the "correct total but jagged trailing row" pattern. Forcing the exact
        // column count makes LazyVGrid's wrapping match this grid's actual [row][column] shape.
        columns = columnCount > 0
            ? Array(repeating: GridItem(.fixed(max(flapSize.width, 1)), spacing: itemSpacing), count: columnCount)
            : []
        let newResolvedDimensions = (rows > 0 && columnCount > 0)
            ? GridResolvedDimensions(rows: rows, columns: columnCount)
            : nil
        // Only assign when actually different, to avoid firing dataSource's Published/objectWillChange
        // publishers (and anything downstream observing them, like MainViewModel) redundantly.
        if dataSource.resolvedDimensions != newResolvedDimensions {
            dataSource.resolvedDimensions = newResolvedDimensions
        }
    }

    @MainActor
    public func setContent(_ dataSource: FlipGridDataSource) {
        if let cells = dataSource.cells {
            logger.debug("setContent: using dataSource.cells, shape \(cells.count, privacy: .public)x\(cells.first?.count ?? 0, privacy: .public)")
            setCells(cells)
            return
        }
        logger.debug("setContent: dataSource.cells is nil, falling back to the message/alignment path")

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
        let previousRows = cells.count
        let previousColumns = cells.first?.count ?? 0
        let newRows = grid.count
        let newColumns = grid.first?.count ?? 0

        guard previousRows == newRows, previousColumns == newColumns else {
            // The grid's shape itself changed (a resize), not just its content within a stable
            // shape. Position-based identity has no meaning across a shape change — row/column N
            // held completely unrelated content before and after — so merging by position here
            // would make most tiles think their content "changed" and flip through the whole
            // alphabet trying to reach an essentially random new character, all at once. Starting
            // fresh instead lets the new content simply appear (SwiftUI's insertion/removal
            // transition on cell identity handles it cleanly).
            logger.debug("setCells: shape changed \(previousRows, privacy: .public)x\(previousColumns, privacy: .public) -> \(newRows, privacy: .public)x\(newColumns, privacy: .public), replacing all cell identities")
            cells = grid
            numberOfItems = grid.reduce(0) { $0 + $1.count }
            return
        }
        logger.debug("setCells: merging into existing \(newRows, privacy: .public)x\(newColumns, privacy: .public) grid, preserving cell identity by position")

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
