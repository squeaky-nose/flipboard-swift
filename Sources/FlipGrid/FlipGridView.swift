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
            ForEach(viewModel.cells.indices, id: \.self) { row in
                ForEach(viewModel.cells[row].indices, id: \.self) { column in
                    let cell = viewModel.cells[row][column]

                    cellView(row: row, column: column, cell: cell)
                        .frame(width: viewModel.flapSize.width,
                               height: viewModel.flapSize.height)
                        .id(cell.id)
                        // Animate when new views are inserted/removed
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        // Animate visual updates to the content itself (iOS/tvOS 17+)
                        .contentTransition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: viewModel.cells
        )
        .readSize($viewModel.canvasSize)
    }

    @ViewBuilder
    private func cellView(row: Int, column: Int, cell: FlipCell) -> some View {
        switch cell.kind {
        case .flap:
            FlipboardView(
                fontSize: viewModel.fontSize,
                targetLetter: Binding(
                    get: { viewModel.cells[row][column].character },
                    set: { viewModel.cells[row][column].character = $0 }
                ),
                cycle: cell.cycle
            )
        case .label:
            Text(String(cell.character))
                .font(.system(size: viewModel.fontSize, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fontWeight(.bold)
                .foregroundColor(.flapText)
        }
    }
}

#Preview {
    FlipGridView(dataSource: FlipGridDataSource())
        .padding()
}
