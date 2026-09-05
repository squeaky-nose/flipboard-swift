//
//  ScoreboardContentRenderer.swift
//  FlipboardSwift
//

import FlipboardSwiftProtocol

/// Lays a scoreboard out onto the character grid: one grid-row per scoreboard row (plus a header
/// row when it fits), columns sized evenly across the available width. Each cell's `FlipboardScoresPayload.Cell`
/// case maps directly to a `FlipCell.kind` — `.flap` animates, `.label` prints statically.
public enum ScoreboardContentRenderer {
    public static func cells(for scores: FlipboardScoresPayload, rows: Int, columns: Int) -> [[FlipCell]] {
        let columnCount = scores.columns.count
        guard rows > 0, columns > 0, columnCount > 0 else { return [] }

        let includeHeader = rows > scores.rows.count
        var lines: [[FlipboardScoresPayload.Cell]] = []
        if includeHeader {
            lines.append(scores.columns.map { .label($0.label) })
        }
        for row in scores.rows {
            lines.append([row.rank, row.name] + row.scores)
        }
        lines = Array(lines.prefix(rows))

        let columnWidth = max(1, (columns - max(0, columnCount - 1)) / columnCount)
        let centerRow = (rows - 1) / 2
        let centerColumn = (columns - 1) / 2

        var grid: [[FlipCell]] = []
        for rowIndex in 0..<rows {
            let centeredRow = rowIndex - centerRow
            let line = rowIndex < lines.count ? lines[rowIndex] : []
            grid.append(rowOfCells(for: line, columnWidth: columnWidth, totalColumns: columns, centeredRow: centeredRow, centerColumn: centerColumn))
        }
        return grid
    }

    private static func rowOfCells(for line: [FlipboardScoresPayload.Cell],
                                    columnWidth: Int,
                                    totalColumns: Int,
                                    centeredRow: Int,
                                    centerColumn: Int) -> [FlipCell] {
        var rowCells: [FlipCell] = []

        for (index, cell) in line.enumerated() {
            let (text, kind): (String, CellKind)
            switch cell {
            case let .flap(value): (text, kind) = (value, .flap)
            case let .label(value): (text, kind) = (value, .label)
            }

            let isLastColumn = index == line.count - 1
            let width = isLastColumn ? max(columnWidth, totalColumns - rowCells.count) : columnWidth
            let padded = GridLayout.pad(String(text.prefix(width)), to: width, alignment: .left)

            for character in padded {
                guard rowCells.count < totalColumns else { break }
                rowCells.append(FlipCell(row: centeredRow, column: rowCells.count - centerColumn, character: character, kind: kind))
            }
        }

        while rowCells.count < totalColumns {
            rowCells.append(FlipCell(row: centeredRow, column: rowCells.count - centerColumn, character: " ", kind: .label))
        }

        return rowCells
    }
}
