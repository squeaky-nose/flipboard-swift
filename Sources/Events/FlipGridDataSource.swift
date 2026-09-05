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

    @Published public var size: Int

    /// `.autoFit` (default) derives tile count from canvas size and `size`, matching the original
    /// behaviour. `.fixed` sets an explicit row/column count regardless of canvas size — needed for
    /// AppleTV's remote up/down control to set tile count directly.
    @Published public var dimensions: GridDimensions = .autoFit

    public init(initialSize: Int = 5) {
        self.size = initialSize
    }
}
