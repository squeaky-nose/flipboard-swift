//
//  FlipGridViewModel.swift
//  Flipper
//
//  Created by Sushant Verma on 18/10/2025.
//

import Combine
import CoreGraphics
import SwiftUI

@MainActor
public class FlipGridViewModel: ObservableObject {
    let dataSource: FlipGridDataSource
    @Published var itemSpacing: CGFloat = 0

    private var lastKnownCanvasSize: CGSize = .zero
    @Published var canvasSize: CGSize = .zero
    @Published var flapCount: CGSize = .zero
    @Published var spacerCount: CGSize = .zero
    @Published var spacerSize: CGSize = .zero
    @Published var flapSize: CGSize = .zero
    @Published var fontSize: CGFloat = 1
    @Published var numberOfItems: Int = 0
    @Published var columns: [GridItem] = []

    @Published var letters: [Character] = []

    private let logger = AutoLogger.unifiedLogger()

    private var cancellables = Set<AnyCancellable>()

    public init(dataSource: FlipGridDataSource) {
        logger.info("Creating FlipGridViewModel")
        self.dataSource = dataSource

        $canvasSize
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] size in
                guard let self else { return }

                lastKnownCanvasSize = size
                recalculateGrid(size)
                setContent(dataSource)
            }
            .store(in: &cancellables)

        dataSource
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }

                recalculateGrid(lastKnownCanvasSize)
                setContent(dataSource)
            }
            .store(in: &cancellables)
    }

    private func recalculateGrid(_ availableSize: CGSize) {
        let minItemSize = CGSize(width: 14 * dataSource.size,
                                 height: 18 * dataSource.size)
        itemSpacing = CGFloat(5 * dataSource.size)
        flapCount = CGSize(width: floor(availableSize.width / (minItemSize.width + itemSpacing)),
                           height: floor(availableSize.height / (minItemSize.height + itemSpacing)))
        spacerCount = CGSize(width: max(0, flapCount.width - 1),
                             height: max(0, flapCount.height - 1))
        spacerSize = CGSize(width: floor(spacerCount.width * itemSpacing),
                            height: floor(spacerCount.height * itemSpacing))
        flapSize = CGSize(width: floor((availableSize.width - spacerSize.width)/flapCount.width),
                          height: floor((availableSize.height - spacerSize.height)/flapCount.height))
        fontSize = flapSize.height/2
        numberOfItems = Int(flapCount.width * flapCount.height)
        columns = [ GridItem(.adaptive(minimum: flapSize.width), spacing: itemSpacing) ]
    }

    @MainActor
    public func setContent(_ dataSource: FlipGridDataSource) {
        let lineLength = Int(flapCount.width)
        let maxLines = max(1, Int(flapCount.height))

        // 1. break text into logical lines based on width
        var lines = splitString(dataSource.message,
                                maxLength: lineLength)

        // 2. ensure we have at most the visible rows
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines))
        }

        // 3. vertically align: add empty padded lines based on `verticalAlignment`
        if lines.count < maxLines {
            let emptyLine = "" // we'll pad it below per-line
            let missing = maxLines - lines.count

            switch dataSource.verticalTextAlignment {
            case .top:
                // existing behavior: content at top, extra at bottom
                lines.append(contentsOf: Array(repeating: emptyLine, count: missing))

            case .bottom:
                // push content down
                lines = Array(repeating: emptyLine, count: missing) + lines

            case .center:
                let top = missing / 2
                let bottom = missing - top
                lines = Array(repeating: emptyLine, count: top) + lines + Array(repeating: emptyLine, count: bottom)
            }
        }

        // 4. horizontally pad every line to exact width (right-aligned like before)
        let content = lines
            .map { pad($0, to: lineLength, alignment: dataSource.horizontalTextAlignment) }
            .joined(separator: "")

        setContent(content)
    }

    public func setContent(_ content: String) {
        let maxCount = max(1, numberOfItems)
        let chars = Array(content.prefix(maxCount))
        let padded = chars + Array(repeating: Character(" "),
                                   count: max(0, maxCount - chars.count))
        if letters.count != maxCount {
            letters = Array(padded.prefix(maxCount))
        } else {
            for i in 0..<maxCount {
                letters[i] = padded[i]
            }
        }
    }

    private func splitString(_ input: String, maxLength: Int) -> [String] {
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

    private func pad(_ line: String, to length: Int, alignment: HorizontalTextAlignment = .left) -> String {
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
