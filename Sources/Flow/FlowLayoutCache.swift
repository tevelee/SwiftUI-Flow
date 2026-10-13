import SwiftUI
import os

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

        /// Whether this subview belongs to the overflow builder, including its separator markers.
        @usableFromInline
        var isOverflow: Bool

        @usableFromInline
        var overflowReporter: (@Sendable (Int) -> Void)?

        /// Whether this subview is a content item, an item separator, or a line separator.
        /// Separators are injected by ``HFlow``/``VFlow`` between adjacent items and never at the edges.
        @usableFromInline
        var separatorRole: SeparatorRole

        /// Reporter the layout calls with the line structure (set on content items by the separator wrapper).
        @usableFromInline
        var lineStructureReporter: (@Sendable ([Int]) -> Void)?

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
            isOverflow = subview[IsOverflowLayoutValueKey.self]
            overflowReporter = subview[OverflowReporterKey.self]
            separatorRole = subview[SeparatorRoleLayoutValueKey.self]
            lineStructureReporter = subview[LineStructureReporterKey.self]
        }
    }

    @usableFromInline
    let subviewsCache: [SubviewCache]

    /// Index of the overflow-indicator subview (the last subview if it carries `IsOverflowLayoutValueKey`),
    /// or `nil` when no overflow indicator is present. Computed once during `makeCache`.
    @usableFromInline
    let overflowSubviewIndex: Int?

    /// Whether any subview carries a non-`content` ``SeparatorRole``. When `false` the layout skips
    /// all separator handling, so flows without separators incur no extra work and no behavior change.
    @usableFromInline
    let hasSeparators: Bool

    /// Shared across cache copies used by SwiftUI's alignment probes.
    @usableFromInline
    let alignmentDepth: OSAllocatedUnfairLock<Int>?

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
        var lines: WrappedLines

        @inlinable
        init(key: LineBreakingKey, lines: WrappedLines) {
            self.key = key
            self.lines = lines
        }
    }

    @inlinable
    init(_ subviews: some Subviews, axis: Axis) {
        let subviewsCache = subviews.map { SubviewCache($0, axis: axis) }
        self.subviewsCache = subviewsCache
        overflowSubviewIndex = subviews.indices.last.flatMap {
            subviewsCache[$0].isOverflow ? $0 : nil
        }
        hasSeparators = subviewsCache.contains { $0.separatorRole.isSeparator }
        let hasReporters = subviewsCache.contains { $0.overflowReporter != nil || $0.lineStructureReporter != nil }
        alignmentDepth = hasReporters ? OSAllocatedUnfairLock(initialState: 0) : nil
    }

    @inlinable
    func cachedLineBreaking(for key: LineBreakingKey) -> WrappedLines? {
        lineBreaking?.key == key ? lineBreaking?.lines : nil
    }

    @inlinable
    mutating func cacheLineBreaking(_ lines: WrappedLines, for key: LineBreakingKey) {
        lineBreaking = LineBreakingResult(key: key, lines: lines)
    }

    @inlinable
    mutating func rekeyLineBreaking(to key: LineBreakingKey) {
        lineBreaking?.key = key
    }

    /// Spacing between two subviews: the explicit `itemSpacing` when set, otherwise the distance
    /// between their `ViewSpacing` preferences along `axis`. Shared by ``FlowLayout`` and
    /// ``SeparatorLayout`` to avoid duplicating the same two-line fallback.
    @usableFromInline
    func spacing(from fromIndex: Int, to toIndex: Int, itemSpacing: CGFloat?, axis: Axis) -> CGFloat {
        if let itemSpacing { return itemSpacing }
        return subviewsCache[fromIndex].spacing.distance(to: subviewsCache[toIndex].spacing, along: axis)
    }
}
