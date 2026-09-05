//
//  NowPlayingInfo.swift
//  FlipboardSwift
//

import Foundation

/// What a server renders when showing what's currently playing. Deliberately **not** part of
/// `flipboard-swift-protocol` — this is never sent over the wire. A server sources this from its own
/// OS's media APIs and renders it locally; a client never constructs or transmits one.
///
/// Not `Sendable`: `artwork` is a platform image (UIImage/NSImage), which isn't Sendable. This value
/// is only ever passed around synchronously within view/view-model code on the main actor.
public struct NowPlayingInfo: Equatable {
    public var title: String
    public var artist: String
    public var album: String?
    public var elapsedSeconds: Double
    public var durationSeconds: Double?
    public var artwork: PlatformImage?

    public init(title: String,
                artist: String,
                album: String? = nil,
                elapsedSeconds: Double = 0,
                durationSeconds: Double? = nil,
                artwork: PlatformImage? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.elapsedSeconds = elapsedSeconds
        self.durationSeconds = durationSeconds
        self.artwork = artwork
    }

    public static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.elapsedSeconds == rhs.elapsedSeconds
            && lhs.durationSeconds == rhs.durationSeconds
            && lhs.artwork === rhs.artwork
    }
}
