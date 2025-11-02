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

    @Published public var message: String

    public init() {
        self.message = ""
    }
}
