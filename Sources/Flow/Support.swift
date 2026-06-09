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

/// Cache to store certain properties of subviews in the layout (flexibility, spacing preferences, layout priority).
/// Even though it needs to be public (because it's part of the layout protocol conformance),
/// it's considered an internal implementation detail.
public struct FlowLayoutCache {
    @usableFromInline
    struct SubviewCache {
        @usableFromInline
        var priority: Double
        @usableFromInline
        var spacing: ViewSpacing
        @usableFromInline
        var ideal: Size
        @usableFromInline
        var max: Size
        @usableFromInline
        var layoutValues: LayoutValues
        @usableFromInline
        struct LayoutValues {
            @usableFromInline
            var shouldStartInNewLine: Bool
            @usableFromInline
            var isLineBreak: Bool
            @usableFromInline
            var flexibility: FlexibilityBehavior

            @inlinable
            init(
                shouldStartInNewLine: Bool,
                isLineBreak: Bool,
                flexibility: FlexibilityBehavior
            ) {
                self.shouldStartInNewLine = shouldStartInNewLine
                self.isLineBreak = isLineBreak
                self.flexibility = flexibility
            }
        }

        @usableFromInline
        var overflowReporter: (@Sendable (Int) -> Void)?

        @inlinable
        init(_ subview: some Subview, axis: Axis) {
            priority = subview.priority
            spacing = subview.spacing
            ideal = subview.dimensions(.unspecified).size(on: axis)
            max = subview.dimensions(.infinity).size(on: axis)
            layoutValues = LayoutValues(
                shouldStartInNewLine: subview[ShouldStartInNewLineLayoutValueKey.self],
                isLineBreak: subview[IsLineBreakLayoutValueKey.self],
                flexibility: subview[FlexibilityLayoutValueKey.self]
            )
            overflowReporter = subview[OverflowReporterKey.self]
        }
    }

    @usableFromInline
    let subviewsCache: [SubviewCache]

    /// Index of the overflow-indicator subview (the last subview if it carries `IsOverflowLayoutValueKey`),
    /// or `nil` when no overflow indicator is present. Computed once during `makeCache`.
    @usableFromInline
    let overflowSubviewIndex: Int?

    /// Single-entry memo of the most recent line-breaking result. `sizeThatFits`
    /// and `placeSubviews` run back-to-back with the same proposal, so caching the
    /// last result lets the second pass skip the (potentially expensive) line
    /// breaking. Keyed on the proposed breadth and depth — the only proposal inputs
    /// the line-breaking step depends on. Cleared whenever the cache is rebuilt.
    @usableFromInline
    var lineBreaking: LineBreakingResult?

    @usableFromInline
    struct LineBreakingKey: Equatable {
        @usableFromInline
        var breadth: CGFloat
        @usableFromInline
        var depth: CGFloat

        @usableFromInline
        init(proposedSize: ProposedViewSize, axis: Axis) {
            breadth = proposedSize.value(on: axis)
            depth = proposedSize.value(on: axis.perpendicular)
        }
    }

    @usableFromInline
    struct LineBreakingResult {
        @usableFromInline
        var key: LineBreakingKey
        @usableFromInline
        var lines: LineBreakingOutput

        @inlinable
        init(key: LineBreakingKey, lines: LineBreakingOutput) {
            self.key = key
            self.lines = lines
        }
    }

    @inlinable
    init(_ subviews: some Subviews, axis: Axis) {
        subviewsCache = subviews.map { SubviewCache($0, axis: axis) }
        overflowSubviewIndex = subviews.indices.last.flatMap {
            subviews[$0][IsOverflowLayoutValueKey.self] ? $0 : nil
        }
    }

    @inlinable
    func cachedLineBreaking(for key: LineBreakingKey) -> LineBreakingOutput? {
        lineBreaking?.key == key ? lineBreaking?.lines : nil
    }

    @inlinable
    mutating func cacheLineBreaking(_ lines: LineBreakingOutput, for key: LineBreakingKey) {
        lineBreaking = LineBreakingResult(key: key, lines: lines)
    }

    @inlinable
    mutating func rekeyLineBreaking(to key: LineBreakingKey) {
        lineBreaking?.key = key
    }
}

/// A view to manually insert breaks into flow layout, allowing precise control over line breaking.
public struct LineBreak: View {
    /// Initializes a new line break view
    public init() {}

    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .layoutValue(key: IsLineBreakLayoutValueKey.self, value: true)
    }
}

extension View {
    /// Allows flow layout elements to be started on new lines, allowing precise control over line breaking.
    public func startInNewLine(_ enabled: Bool = true) -> some View {
        layoutValue(key: ShouldStartInNewLineLayoutValueKey.self, value: enabled)
    }

    /// Allows modifying the flexibility behavior of views so that flow can layout them accordingly.
    /// This modifier can be placed outside of flow layout too, and propagate to all flow layouts inside that view tree (using environment).
    /// The default flexibility of each item in a flow is `.natural`.
    public func flexibility(_ behavior: FlexibilityBehavior) -> some View {
        layoutValue(key: FlexibilityLayoutValueKey.self, value: behavior)
            .environment(\.flexibility, behavior)
    }
}

@usableFromInline
struct ShouldStartInNewLineLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct IsLineBreakLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct FlexibilityLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

@usableFromInline
struct IsOverflowLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct OverflowReporterKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: (@Sendable (Int) -> Void)? = nil
}

@usableFromInline
struct FlexibilityEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

@usableFromInline
struct MaxLinesEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: Int? = nil
}

extension EnvironmentValues {
    @usableFromInline
    var flexibility: FlexibilityBehavior {
        get { self[FlexibilityEnvironmentKey.self] }
        set { self[FlexibilityEnvironmentKey.self] = newValue }
    }

    @usableFromInline
    var maxLines: Int? {
        get { self[MaxLinesEnvironmentKey.self] }
        set { self[MaxLinesEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Caps the nearest enclosing ``HFlow`` or ``VFlow`` to `limit` lines.
    ///
    /// Items beyond the limit are hidden from view but still participate in
    /// line-breaking so the layout remains consistent.  Pass `nil` to remove
    /// any previously set limit.
    ///
    /// - Parameter limit: Maximum number of lines (rows for `HFlow`, columns
    ///   for `VFlow`). `nil` keeps every line.
    @inlinable
    public func maxLines(_ limit: Int?) -> some View {
        environment(\.maxLines, limit)
    }
}
