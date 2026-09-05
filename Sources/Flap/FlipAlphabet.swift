//
//  FlipAlphabet.swift
//  FlipboardSwift
//

/// The ordered sequence of characters a flap tile steps through while animating from one character
/// to another. `.full` is the original behaviour (every tile cycles through the whole alphabet
/// regardless of content) and stays the default; narrower cycles exist so content that only ever
/// shows digits (a clock) doesn't visually roll through letters mid-transition.
public enum FlipAlphabet: Sendable, Equatable {
    case full
    case digitsOnly
    case alphanumeric

    private static let empty: [Character] = Array(" ")
    private static let uppercase: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
    private static let digits: [Character] = Array("0123456789")
    private static let colours: [Character] = Array("🟥🟧🟨🟩🟦🟪🟫⬛⬜")

    public var characters: [Character] {
        switch self {
        case .full:
            return Self.empty + Self.uppercase + Self.lowercase + Self.digits + Self.colours
        case .digitsOnly:
            return Self.empty + Self.digits
        case .alphanumeric:
            return Self.empty + Self.uppercase + Self.lowercase + Self.digits
        }
    }
}
