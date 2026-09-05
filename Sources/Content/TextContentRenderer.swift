//
//  TextContentRenderer.swift
//  FlipboardSwift
//

import Foundation

/// Lays plain text out onto a fixed-size character grid: word-wrap, vertical alignment, horizontal
/// padding, then one `FlipCell` per character. Shared by raw text blocks, the clock, and now-playing
/// renderers, which all reduce to "some text, laid out on a grid" underneath.
public enum TextContentRenderer {
    public static func cells(text: String,
                              horizontalAlignment: HorizontalTextAlignment,
                              verticalAlignment: VerticalTextAlignment,
                              rows: Int,
                              columns: Int,
                              cyclePolicy: (Character) -> FlipAlphabet = { _ in .full }) -> [[FlipCell]] {
        guard rows > 0, columns > 0 else { return [] }

        var lines = GridLayout.splitIntoLines(text, maxLength: columns)
        if lines.count > rows {
            lines = Array(lines.prefix(rows))
        }
        lines = GridLayout.verticallyAlign(lines, to: rows, alignment: verticalAlignment)

        let content = lines
            .map { GridLayout.pad($0, to: columns, alignment: horizontalAlignment) }
            .joined(separator: "")

        let maxCount = rows * columns
        let chars = Array(content.prefix(maxCount))
        let padded = chars + Array(repeating: Character(" "), count: max(0, maxCount - chars.count))

        let centerRow = (rows - 1) / 2
        let centerColumn = (columns - 1) / 2

        var grid: [[FlipCell]] = []
        var index = 0
        for row in 0..<rows {
            let centeredRow = row - centerRow
            var rowCells: [FlipCell] = []
            for column in 0..<columns {
                let centeredColumn = column - centerColumn
                let character = index < padded.count ? padded[index] : " "
                index += 1
                rowCells.append(FlipCell(row: centeredRow,
                                          column: centeredColumn,
                                          character: character,
                                          cycle: cyclePolicy(character)))
            }
            grid.append(rowCells)
        }
        return grid
    }
}
