import SwiftUI

/// The way line breaking treats flexible items. The default behavior is `.natural`.
public enum FlexibilityBehavior: Sendable {
    /// The layout chooses the minimum space for the view, regardless of how much it can expand
    case minimum
    /// The layout allows the views to expand as they naturally do.
    case natural
    /// If a view can expand, it allows to "push" out other views and fill a whole row on its own.
    case maximum
}

/// A view to manually insert breaks into flow layout, allowing precise control over line breaking.
public struct LineBreak: View {
    /// Initializes a new line break view
    @inlinable
    public init() {}

    @inlinable
    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .layoutValue(key: IsLineBreakLayoutValueKey.self, value: true)
    }
}

extension View {
    /// Allows flow layout elements to be started on new lines, allowing precise control over line breaking.
    @inlinable
    public func startInNewLine(_ enabled: Bool = true) -> some View {
        layoutValue(key: ShouldStartInNewLineLayoutValueKey.self, value: enabled)
    }

    /// Allows modifying the flexibility behavior of views so that flow can layout them accordingly.
    /// This modifier can be placed outside of flow layout too, and propagate to all flow layouts inside that view tree (using environment).
    /// The default flexibility of each item in a flow is `.natural`.
    @inlinable
    public func flexibility(_ behavior: FlexibilityBehavior) -> some View {
        layoutValue(key: FlexibilityLayoutValueKey.self, value: behavior)
            .environment(\.flexibility, behavior)
    }

    /// Caps the nearest enclosing ``HFlow`` or ``VFlow`` to `limit` lines.
    ///
    /// Items beyond the limit are hidden from view but still participate in
    /// line-breaking so the layout remains consistent.  Pass `nil` to remove
    /// any previously set limit.
    ///
    /// - Parameter limit: Maximum number of lines (rows for `HFlow`, columns
    ///   for `VFlow`). `nil` keeps every line.
    @inlinable public func maxLines(_ limit: Int?) -> some View {
        environment(\.maxLines, limit)
    }

    /// Caps the nearest enclosing ``HFlow`` or ``VFlow`` to `limit` lines and
    /// appends `overflow` at the end of the last visible line to indicate how
    /// many items were hidden.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of lines (rows for `HFlow`, columns for `VFlow`). Must be ≥ 1.
    ///   - overflow: A view builder that receives the number of hidden items.
    @inlinable
    public func maxLines<O: View>(
        _ limit: Int,
        @ViewBuilder overflow: @escaping (Int) -> O
    ) -> some View {
        environment(\.maxLines, limit)
            .environment(\._flowOverflowBuilder, { AnyView(overflow($0)) })
    }

    /// Draws `separator` between adjacent items on the same line in the nearest enclosing
    /// ``HFlow`` or ``VFlow``. The separator participates in layout: its breadth factors into
    /// line breaking and is suppressed at line boundaries.
    ///
    /// - Parameter separator: A view builder producing the separator view.
    @inlinable
    public func itemSeparator<S: View>(@ViewBuilder _ separator: @escaping () -> S) -> some View {
        environment(\._flowItemSeparator, { AnyView(separator()) })
    }

    /// Draws `separator` between adjacent lines in the nearest enclosing ``HFlow`` or ``VFlow``.
    /// The separator becomes its own line in the layout, with normal line spacing on both sides.
    ///
    /// - Parameter separator: A view builder producing the separator view.
    @inlinable
    public func lineSeparator<S: View>(@ViewBuilder _ separator: @escaping () -> S) -> some View {
        environment(\._flowLineSeparator, { AnyView(separator()) })
    }
}
