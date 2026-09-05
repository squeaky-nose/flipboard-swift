//
//  GridResolvedDimensions.swift
//  FlipboardSwift
//

/// The grid's actual current row/column count, whatever `GridDimensions` mode produced it —
/// published back from `FlipGridViewModel` so a caller that only sets `.autoFit` (letting tile count
/// derive from canvas size and `size`, the classic behaviour) can still know how many rows/columns
/// are currently on screen, e.g. to render a `FlipboardPayloadRenderer` grid sized to fit.
public struct GridResolvedDimensions: Equatable, Sendable {
    public var rows: Int
    public var columns: Int

    public init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }
}
