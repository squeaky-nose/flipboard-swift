//
//  NowPlayingContentRenderer.swift
//  FlipboardSwift
//

public enum NowPlayingContentRenderer {
    public static func text(for info: NowPlayingInfo) -> String {
        if let album = info.album, !album.isEmpty {
            return "\(info.title)\n\(info.artist)\n\(album)"
        }
        return "\(info.title)\n\(info.artist)"
    }

    public static func cells(for info: NowPlayingInfo, rows: Int, columns: Int) -> [[FlipCell]] {
        TextContentRenderer.cells(
            text: text(for: info),
            horizontalAlignment: .center,
            verticalAlignment: .center,
            rows: rows,
            columns: columns
        )
    }
}
