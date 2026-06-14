import SwiftUI

// MARK: - Overflow wrapper

/// Wraps a flow layout to support `.maxLines(_:overflow:)` with a live hidden-item count.
/// - Note: Do not use this type directly. Use ``HFlow/maxLines(_:overflow:)`` or ``VFlow/maxLines(_:overflow:)`` instead.
public struct _FlowWithOverflow<Content: View, Overflow: View>: View {  // swiftlint:disable:this type_name
    @Environment(\.flexibility) private var flexibility

    @usableFromInline
    let layout: AnyLayout
    @usableFromInline
    let content: Content
    @usableFromInline
    let overflowBuilder: (Int) -> Overflow

    @StateObject private var state = Reported(0)

    @inlinable
    init(layout: AnyLayout, content: Content, overflowBuilder: @escaping (Int) -> Overflow) {
        self.layout = layout
        self.content = content
        self.overflowBuilder = overflowBuilder
    }

    public var body: some View {
        let reporter = state.reporter()
        return layout {
            content
                .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
                .environment(\.maxLines, nil)
                .environment(\._flowOverflowBuilder, nil)
            overflowBuilder(state.value)
                .overflowIndicator(reporter: reporter)
        }
    }
}

extension View {
    /// Tags this view as the overflow indicator and wires the hidden-count reporter, so the layout
    /// keeps it out of line breaking, places it on the last visible line, and reports how many items
    /// the cap hid.
    func overflowIndicator(reporter: @escaping @Sendable (Int) -> Void) -> some View {
        layoutValue(key: IsOverflowLayoutValueKey.self, value: true)
            .layoutValue(key: OverflowReporterKey.self, value: reporter)
    }
}
