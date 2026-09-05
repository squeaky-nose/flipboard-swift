//
//  ClockContentRenderer.swift
//  FlipboardSwift
//

import Foundation
import FlipboardSwiftProtocol

public enum ClockContentRenderer {
    public static func text(for clock: FlipboardClockPayload, referenceDate: Date = Date()) -> String {
        let timeZone = clock.timezoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone

        let timeString = formatter.string(from: referenceDate)
        if let label = clock.label, !label.isEmpty {
            return "\(label)\n\(timeString)"
        }
        return timeString
    }

    /// Digits only ever cycle through other digits while flipping — never the full alphabet — both
    /// because it's cheaper (far fewer intermediate steps) and because a clock rolling through
    /// letters mid-transition would look like a glitch rather than a feature. Everything else
    /// (a label, the ':' separator) keeps the full alphabet.
    public static func cells(for clock: FlipboardClockPayload, rows: Int, columns: Int, referenceDate: Date = Date()) -> [[FlipCell]] {
        TextContentRenderer.cells(
            text: text(for: clock, referenceDate: referenceDate),
            horizontalAlignment: HorizontalTextAlignment(clock.position.horizontalAlignment),
            verticalAlignment: VerticalTextAlignment(clock.position.verticalAlignment),
            rows: rows,
            columns: columns,
            cyclePolicy: { $0.isNumber ? .digitsOnly : .full }
        )
    }
}
