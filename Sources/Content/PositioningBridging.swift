//
//  PositioningBridging.swift
//  FlipboardSwift
//

import FlipboardSwiftProtocol

/// Bridges the wire-protocol alignment enums to this package's own (which predate the protocol
/// package and are used more broadly, e.g. by `FlipGridDataSource`).
extension HorizontalTextAlignment {
    init(_ alignment: AlignmentHorizontal) {
        switch alignment {
        case .left: self = .left
        case .center: self = .center
        case .right: self = .right
        }
    }
}

extension VerticalTextAlignment {
    init(_ alignment: AlignmentVertical) {
        switch alignment {
        case .top: self = .top
        case .center: self = .center
        case .bottom: self = .bottom
        }
    }
}
