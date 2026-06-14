@_exported import Flow
import SwiftUI

// The line-limit feature modifiers. Each sets its own environment value and registers the shared
// ``LineLimitComposer`` into the flow composition chain, so the core ``HFlow``/``VFlow`` hands body
// construction to this target. `import FlowLineLimit` to use them.

extension View {
    /// Caps the nearest enclosing ``HFlow`` or ``VFlow`` to `limit` lines.
    ///
    /// Items beyond the limit are hidden from view but still participate in
    /// line-breaking so the layout remains consistent.  Pass `nil` to remove
    /// any previously set limit.
    ///
    /// - Parameter limit: Maximum number of lines (rows for `HFlow`, columns
    ///   for `VFlow`). `nil` keeps every line.
    public func maxLines(_ limit: Int?) -> some View {
        environment(\.maxLines, limit)
            .registerFlowComposer(LineLimitComposer())
    }

    /// Caps the nearest enclosing ``HFlow`` or ``VFlow`` to `limit` lines and
    /// appends `overflow` at the end of the last visible line to indicate how
    /// many items were hidden.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of lines (rows for `HFlow`, columns for `VFlow`). Must be ≥ 1.
    ///   - overflow: A view builder that receives the number of hidden items.
    public func maxLines<O: View>(
        _ limit: Int,
        @ViewBuilder overflow: @escaping (Int) -> O
    ) -> some View {
        environment(\.maxLines, limit)
            .environment(\._flowOverflowBuilder, { AnyView(overflow($0)) })
            .registerFlowComposer(LineLimitComposer())
    }
}
