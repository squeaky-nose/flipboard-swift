//
//  FlipGridDatasource.swift
//  FlipboardSwift
//
//  Created by Sushant Verma on 1/11/2025.
//

import Combine

public class FlipGridDataSource: ObservableObject {

    @Published public var horizontalTextAlignment: HorizontalTextAlignment = .left
    @Published public var verticalTextAlignment: VerticalTextAlignment = .top

    @Published public var message: String = ""

    /// A pre-rendered grid (from `FlipboardPayloadRenderer`/`ClockContentRenderer`/etc.), for content
    /// that needs more than a single aligned/wrapped string — a mix of flap and label cells, or a
    /// non-full flip alphabet. When set, this takes priority over `message`; set back to `nil` to
    /// return to the plain-text path.
    @Published public var cells: [[FlipCell]]? = nil

    @Published public var size: Int

    /// `.autoFit` (default) derives tile count from canvas size and `size`, matching the original
    /// behaviour: bigger `size` means a bigger minimum tile, which means fewer of them fit (and vice
    /// versa) — the classic "up/down changes both tile count and tile size together" feel. `.fixed`
    /// sets an explicit row/column count regardless of canvas size instead, for a caller that wants
    /// an exact grid shape.
    @Published public var dimensions: GridDimensions = .autoFit

    /// The grid's actual current row/column count, published back by `FlipGridViewModel` once it's
    /// measured its canvas — read this (rather than trying to predict it from `dimensions`/`size`)
    /// when you need to size a `FlipboardPayloadRenderer` grid to fit. `nil` until the view has laid
    /// out at least once.
    @Published public internal(set) var resolvedDimensions: GridResolvedDimensions?

    public init(initialSize: Int = 5) {
        self.size = initialSize
    }
}
