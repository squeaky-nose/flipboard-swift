//
//  GridLayout.swift
//  FlipboardSwift
//

import Foundation

/// Word-wrap, vertical alignment, and horizontal padding shared by every content renderer (plain
/// text, clock, scoreboard) so each one doesn't reimplement the same layout primitives.
enum GridLayout {
    static func splitIntoLines(_ input: String, maxLength: Int) -> [String] {
        guard maxLength > 0 else { return [] }
        var result: [String] = []

        // Normalize newlines to \n and split while preserving intentional blank lines
        let normalized = input
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        for rawLineSubstring in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            let rawLine = String(rawLineSubstring)

            var currentLine = ""

            for word in rawLine.split(separator: " ") {
                if currentLine.isEmpty {
                    currentLine = String(word)
                } else if currentLine.count + word.count + 1 <= maxLength {
                    currentLine += " \(word)"
                } else {
                    result.append(currentLine)
                    currentLine = String(word)
                }
            }

            if !currentLine.isEmpty {
                result.append(currentLine)
            } else if rawLine.isEmpty {
                // preserve intentional blank lines
                result.append("")
            }
        }

        return result
    }

    static func verticallyAlign(_ lines: [String], to maxLines: Int, alignment: VerticalTextAlignment) -> [String] {
        guard lines.count < maxLines else { return lines }
        let missing = maxLines - lines.count

        switch alignment {
        case .top:
            return lines + Array(repeating: "", count: missing)
        case .bottom:
            return Array(repeating: "", count: missing) + lines
        case .center:
            let top = missing / 2
            let bottom = missing - top
            return Array(repeating: "", count: top) + lines + Array(repeating: "", count: bottom)
        }
    }

    static func pad(_ line: String, to length: Int, alignment: HorizontalTextAlignment = .left) -> String {
        guard line.count < length else { return line }
        let spaces = length - line.count

        switch alignment {
        case .left:
            return line + String(repeating: " ", count: spaces)
        case .right:
            return String(repeating: " ", count: spaces) + line
        case .center:
            let left = spaces / 2
            let right = spaces - left
            return String(repeating: " ", count: left) + line + String(repeating: " ", count: right)
        }
    }
}
