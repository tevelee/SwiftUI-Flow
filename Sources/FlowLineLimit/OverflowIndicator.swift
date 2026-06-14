import Flow
import SwiftUI

// MARK: - Overflow indicator marker

extension View {
    /// Tags this view as the overflow indicator and wires the hidden-count reporter, so the layout
    /// keeps it out of line breaking, places it on the last visible line, and reports how many items
    /// the cap hid. The overflow view itself is composed as a sibling by ``LineLimitComposer``.
    func overflowIndicator(reporter: @escaping @Sendable (Int) -> Void) -> some View {
        layoutValue(key: IsOverflowLayoutValueKey.self, value: true)
            .layoutValue(key: OverflowReporterKey.self, value: reporter)
            .layoutValue(key: IsAuxiliaryLayoutValueKey.self, value: true)
    }
}
