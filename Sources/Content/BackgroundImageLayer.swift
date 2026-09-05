//
//  BackgroundImageLayer.swift
//  FlipboardSwift
//

import SwiftUI

/// Blurs and dims an image behind content so flap tiles stay legible on top — shared by the clock's
/// optional map background and the now-playing renderer's blurred artwork, instead of each
/// implementing its own background treatment.
///
/// This modifier only composites an already-loaded image; it does not generate a map snapshot or
/// fetch artwork over the network itself — that's a per-platform concern (e.g. `MKMapSnapshotter` on
/// Apple platforms) best wired up and visually verified against a real simulator/device, which
/// belongs with the AppleTV app work rather than this platform-agnostic rendering package.
public struct BackgroundImageLayer: ViewModifier {
    let image: PlatformImage?
    let blurRadius: CGFloat
    let dimOpacity: Double

    public init(image: PlatformImage?, blurRadius: CGFloat = 20, dimOpacity: Double = 0.55) {
        self.image = image
        self.blurRadius = blurRadius
        self.dimOpacity = dimOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background {
                if let image {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: blurRadius)
                        .overlay(Color.black.opacity(dimOpacity))
                        .clipped()
                } else {
                    Color.flapBackground
                }
            }
    }
}

public extension View {
    func backgroundImage(_ image: PlatformImage?, blurRadius: CGFloat = 20, dimOpacity: Double = 0.55) -> some View {
        modifier(BackgroundImageLayer(image: image, blurRadius: blurRadius, dimOpacity: dimOpacity))
    }
}
