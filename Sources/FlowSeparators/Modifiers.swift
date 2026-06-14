@_exported import Flow
import SwiftUI

// The separator feature modifiers. Each sets its own environment value and registers the shared
// ``SeparatorComposer`` into the flow composition chain, so the core ``HFlow``/``VFlow`` hands body
// construction to this target. `import FlowSeparators` to use them.

extension View {
    /// Draws `separator` between adjacent items on the same line in the nearest enclosing
    /// ``HFlow`` or ``VFlow``. The separator participates in layout: its breadth factors into
    /// line breaking and is suppressed at line boundaries.
    ///
    /// - Parameter separator: A view builder producing the separator view.
    public func itemSeparator<S: View>(@ViewBuilder _ separator: @escaping () -> S) -> some View {
        environment(\._flowItemSeparator, { AnyView(separator()) })
            .registerFlowComposer(SeparatorComposer())
    }

    /// Draws `separator` between adjacent lines in the nearest enclosing ``HFlow`` or ``VFlow``.
    /// The separator becomes its own line in the layout, with normal line spacing on both sides.
    ///
    /// - Parameter separator: A view builder producing the separator view.
    public func lineSeparator<S: View>(@ViewBuilder _ separator: @escaping () -> S) -> some View {
        environment(\._flowLineSeparator, { AnyView(separator()) })
            .registerFlowComposer(SeparatorComposer())
    }
}
