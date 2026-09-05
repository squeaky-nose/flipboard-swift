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
    /// behaviour. `.fixed` sets an explicit row/column count regardless of canvas size — needed for
    /// AppleTV's remote up/down control to set tile count directly.
    @Published public var dimensions: GridDimensions = .autoFit

    public init(initialSize: Int = 5) {
        self.size = initialSize
    }
}
