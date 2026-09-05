//
//  FlipboardPayloadRenderer.swift
//  FlipboardSwift
//

import FlipboardSwiftProtocol

/// Centralizes "how to render each payload type" in one place, so every app consuming this package
/// doesn't need its own copy of this switch statement.
public enum FlipboardPayloadRenderer {
    public static func cells(for payload: FlipboardPayload, rows: Int, columns: Int) -> [[FlipCell]] {
        switch payload {
        case let .block(block):
            return TextContentRenderer.cells(
                text: block.text,
                horizontalAlignment: HorizontalTextAlignment(block.position.horizontalAlignment),
                verticalAlignment: VerticalTextAlignment(block.position.verticalAlignment),
                rows: rows,
                columns: columns
            )
        case let .clock(clock):
            return ClockContentRenderer.cells(for: clock, rows: rows, columns: columns)
        case let .scores(scores):
            return ScoreboardContentRenderer.cells(for: scores, rows: rows, columns: columns)
        }
    }
}
