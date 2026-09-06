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
        // The canvas size must come from an outer GeometryReader whose own size is determined
        // solely by *its* parent — never from measuring the grid's own rendered content. LazyVGrid
        // is designed for use inside a ScrollView: its reported size reflects its total content
        // extent (all rows), not a clamped viewport, even inside `.frame(maxHeight: .infinity)`.
        // Measuring via a GeometryReader in the grid's own `.background` (the previous approach)
        // therefore picks up that inflated content size instead of the true available space —
        // more rows rendered -> a bigger "canvas" measurement -> recalculateGrid thinks more rows
        // fit -> even more rows rendered, an unbounded loop with no dependency on Combine at all.
        // The explicit `.frame(width:height:)` + `.clipped()` below hard-bounds the grid to the
        // outer measurement regardless, so even a transient shape mismatch can't visually overflow.
        GeometryReader { geometry in
            LazyVGrid(columns: viewModel.columns, spacing: viewModel.itemSpacing) {
                ForEach(viewModel.cells.indices, id: \.self) { row in
                    ForEach(viewModel.cells[row].indices, id: \.self) { column in
                        let cell = viewModel.cells[row][column]

                        // Every cell gets a fixed, pre-computed size here rather than sizing
                        // itself — `flapSize` is derived once, at the top, in
                        // `FlipGridViewModel.recalculateGrid` from the outer GeometryReader's
                        // `canvasSize` above. No cell (nor `FlipboardView`/the flap tile it wraps)
                        // does its own geometry measurement; see the outer GeometryReader comment
                        // above and `FlipboardView`'s own comment for why letting a child measure
                        // itself is exactly what caused the original resize feedback-loop bug.
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
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
            .animation(
                .spring(response: 0.35, dampingFraction: 0.85),
                value: viewModel.cells
            )
            .onAppear { viewModel.canvasSize = geometry.size }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.canvasSize = newSize
            }
        }
    }

    @ViewBuilder
    private func cellView(row: Int, column: Int, cell: FlipCell) -> some View {
        switch cell.kind {
        case .flap:
            FlipboardView(
                fontSize: viewModel.fontSize,
                // Bounds-checked rather than a direct subscript: this closure captures `row`/
                // `column` at the moment this specific cell view was created, but `viewModel.cells`
                // can shrink to a smaller shape (a resize) while this exact view is still alive —
                // e.g. mid-way through its `.transition(removal: .opacity)` fade-out below — and
                // SwiftUI can still re-invoke a soon-to-be-removed view's binding during that
                // window. A direct `viewModel.cells[row][column]` then indexes past the end of the
                // new, smaller array and crashes; falling back to a blank character is harmless
                // since this view is on its way out either way.
                targetLetter: Binding(
                    get: {
                        guard viewModel.cells.indices.contains(row),
                              viewModel.cells[row].indices.contains(column)
                        else { return " " }
                        return viewModel.cells[row][column].character
                    },
                    set: { newValue in
                        guard viewModel.cells.indices.contains(row),
                              viewModel.cells[row].indices.contains(column)
                        else { return }
                        viewModel.cells[row][column].character = newValue
                    }
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
