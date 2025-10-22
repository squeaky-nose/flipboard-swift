//
//  View+ReadSize.swift
//
//  Created by Sushant Verma on 16/8/2023.
//

import SwiftUI

/* Usage:
    struct SomeView: View {

        @State var scrollViewSize: CGSize = .zero

        let isSubscriber: Bool = true

        var body: some View {
            ScrollView { geometry
                Image("theMatrix")
                    .resizable()
                    .scaledToFill()
                    .frame(width: scrollViewSize.width,
                           height: scrollViewSize.width * (3 / 4))
                    .clipped()
            }
            .readSize($scrollViewSize)
        }
    }
 */

private struct SizeReader: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { reader in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: reader.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { size in
                self.size = size
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize

    nonisolated(unsafe) static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextValue = nextValue()
        value = CGSize(width: value.width + nextValue.width, height: value.height + nextValue.height)
    }
}

extension View {
    /// A SwiftUI modifier to communicate the view's current size
    func readSize(_ size: Binding<CGSize>) -> some View {
        modifier(SizeReader(size: size))
    }
}
