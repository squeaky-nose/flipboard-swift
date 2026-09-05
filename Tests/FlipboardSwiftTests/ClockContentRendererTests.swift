import Testing
import Foundation
@testable import FlipboardSwift
import FlipboardSwiftProtocol

struct ClockContentRendererTests {
    // A fixed reference date so formatting is deterministic regardless of when the test runs.
    private var referenceDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 9
        components.minute = 5
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }

    @Test
    func formatsTimeInTheRequestedTimezone() {
        let clock = FlipboardClockPayload(timezoneIdentifier: "UTC")
        #expect(ClockContentRenderer.text(for: clock, referenceDate: referenceDate) == "09:05")
    }

    @Test
    func includesLabelWhenPresent() {
        let clock = FlipboardClockPayload(timezoneIdentifier: "UTC", label: "London")
        #expect(ClockContentRenderer.text(for: clock, referenceDate: referenceDate) == "London\n09:05")
    }

    // The concrete regression test for "clock only ever cycles digits" — digit characters must get
    // the narrower .digitsOnly cycle, not the full alphabet.
    @Test
    func digitCellsUseDigitsOnlyCycleButOtherCharactersDont() {
        let clock = FlipboardClockPayload(timezoneIdentifier: "UTC")
        let grid = ClockContentRenderer.cells(for: clock, rows: 1, columns: 5, referenceDate: referenceDate)

        let flatCells = grid.flatMap { $0 }
        let digitCells = flatCells.filter { $0.character.isNumber }
        let nonDigitCells = flatCells.filter { !$0.character.isNumber }

        #expect(!digitCells.isEmpty)
        for cell in digitCells {
            #expect(cell.cycle == .digitsOnly)
        }
        for cell in nonDigitCells {
            #expect(cell.cycle == .full)
        }
    }
}
