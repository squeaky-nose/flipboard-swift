//
//  GridDimensions.swift
//  FlipboardSwift
//

/// How a `FlipGridView`'s tile count is determined.
public enum GridDimensions: Sendable, Equatable {
    /// Tile count derives from the available canvas size and `FlipGridDataSource.size` (the
    /// original behaviour) — more/fewer tiles fit as the view resizes.
    case autoFit
    /// An explicit tile count, regardless of canvas size (tiles scale to fill the available space
    /// instead of the count changing). This is what lets AppleTV's remote up/down control set the
    /// tile count directly, rather than faking it by shrinking/growing tile size.
    case fixed(rows: Int, columns: Int)
}
