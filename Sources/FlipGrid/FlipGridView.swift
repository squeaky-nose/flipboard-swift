//
//  FlipGridView.swift
//  FlipboardTV
//
//  Created by Sushant Verma on 16/10/2025.
//

import SwiftUI

public struct FlipGridView: View {

    @StateObject private var viewModel: FlipGridViewModel

    public init(dataSource: FlipGridDataSource) {
        _viewModel = StateObject(wrappedValue: .init(dataSource: dataSource))
    }

    public var body: some View {
        LazyVGrid(columns: viewModel.columns, spacing: viewModel.itemSpacing) {
            if viewModel.numberOfItems > 0 {
                ForEach(0..<viewModel.letters.count, id: \.self) { i in
                    FlipboardView(
                        fontSize: viewModel.fontSize,
                        targetLetter: Binding(
                            get: { viewModel.letters[i] },
                            set: { viewModel.letters[i] = $0 }
                        )
                    )
                    .frame(width: viewModel.flapSize.width, height: viewModel.flapSize.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readSize($viewModel.canvasSize)
    }

    @ViewBuilder
    private var diagnosticView: some View {
        let f: (CGFloat) -> String = { String(format: "%.1f", $0) }
        let rows: [(title: String, value: String)] = [
            ("canvasSize", "\(f(viewModel.canvasSize.width)) × \(f(viewModel.canvasSize.height))"),
            ("itemsCount", "\(Int(viewModel.flapCount.width)) × \(Int(viewModel.flapCount.height))"),
            ("spacerCount", "\(Int(viewModel.spacerCount.width)) × \(Int(viewModel.spacerCount.height))"),
            ("spacerSize", "\(f(viewModel.spacerSize.width)) × \(f(viewModel.spacerSize.height))"),
            ("itemSize", "\(f(viewModel.flapSize.width)) × \(f(viewModel.flapSize.height))"),
            ("numberOfItems", "\(viewModel.numberOfItems)")
        ]

        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 300), alignment: .leading)
        ], spacing: 8) {
            ForEach(rows, id: \.title) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(width: 700)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    FlipGridView(dataSource: FlipGridDataSource())
        .padding()
}

