//
//  FlipGridViewModel.swift
//  Flipper
//
//  Created by Sushant Verma on 18/10/2025.
//

import Combine
import CoreGraphics
import SwiftUI

extension Notification.Name {
    public static let myCustomNotification = Notification.Name("myCustomNotification")
}

@MainActor
public class FlipGridViewModel: ObservableObject {
    let minItemSize: CGSize
    let itemSpacing: CGFloat

    @Published var canvasSize: CGSize = .zero
    @Published var itemsCount: CGSize = .zero
    @Published var spacerCount: CGSize = .zero
    @Published var spacerSize: CGSize = .zero
    @Published var itemSize: CGSize = .zero
    @Published var fontSize: CGFloat = 1
    @Published var numberOfItems: Int = 0
    @Published var columns: [GridItem] = []

    @Published var letters: [Character] = []

    private let logger = AutoLogger.unifiedLogger()

    private var cancellables = Set<AnyCancellable>()

    public init(minItemSize: CGSize = CGSize(width: 70, height: 90),
        itemSpacing: CGFloat = 24) {
        logger.info("Creating FlipGridViewModel")
        self.minItemSize = minItemSize
        self.itemSpacing = itemSpacing

        $canvasSize
            .receive(on: RunLoop.main)
            .sink { [weak self] size in
                self?.recalculateGrid(size)
                self?.setContent("")
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .myCustomNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let text = notification.userInfo?["text"] as? String {
                    self?.setContent(text)
                }
            }
            .store(in: &cancellables)

        recalculateGrid(canvasSize)
        setContent("")
    }

    private func recalculateGrid(_ availableSize: CGSize) {
        itemsCount = CGSize(width: floor(availableSize.width / (minItemSize.width + itemSpacing)),
                            height: floor(availableSize.height / (minItemSize.height + itemSpacing)))
        spacerCount = CGSize(width: max(0, itemsCount.width - 1),
                             height: max(0, itemsCount.height - 1))
        spacerSize = CGSize(width: spacerCount.width * itemSpacing,
                            height: spacerCount.height * itemSpacing)
        itemSize = CGSize(width: (availableSize.width - spacerSize.width)/itemsCount.width,
                          height: (availableSize.height - spacerSize.height)/itemsCount.height)
        fontSize = itemSize.height/2
        numberOfItems = Int(itemsCount.width * itemsCount.height)
        columns = [ GridItem(.adaptive(minimum: itemSize.width), spacing: itemSpacing) ]
    }

    public func setContent(_ content: String) {
        let maxCount = max(1, numberOfItems)
        let chars = Array(content.prefix(maxCount))
        let padded = chars + Array(repeating: Character(" "), count: max(0, maxCount - chars.count))
        if letters.count != maxCount {
            letters = Array(padded.prefix(maxCount))
        } else {
            for i in 0..<maxCount {
                letters[i] = padded[i]
            }
        }
    }
}

