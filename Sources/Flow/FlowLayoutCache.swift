import SwiftUI

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
            var flexibility: FlexibilityBehavior

            @inlinable
            init(
                shouldStartInNewLine: Bool,
                flexibility: FlexibilityBehavior
            ) {
                self.shouldStartInNewLine = shouldStartInNewLine
                self.flexibility = flexibility
            }
        }

        /// Whether this subview belongs to the overflow builder, including its separator markers.
        @usableFromInline
        var origin: FlowSubviewOrigin

        /// The subview's structural role, independent of overflow ownership and forced content starts.
        @usableFromInline
        var role: FlowSubviewRole

        @inlinable
        init(_ subview: some Subview, axis: Axis) {
            priority = subview.priority
            spacing = subview.spacing
            ideal = subview.dimensions(.unspecified).size(on: axis)
            max = subview.dimensions(.infinity).size(on: axis)
            layoutValues = LayoutValues(
                shouldStartInNewLine: subview[ShouldStartInNewLineLayoutValueKey.self],
                flexibility: subview[FlexibilityLayoutValueKey.self]
            )
            origin = subview[FlowSubviewOriginLayoutValueKey.self]
            role = subview[FlowSubviewRoleLayoutValueKey.self]
        }
    }

    @usableFromInline
    let subviewsCache: [SubviewCache]

    /// Index of the overflow-indicator subview (the last subview if owned by the overflow builder),
    /// or `nil` when no overflow indicator is present. Computed once during `makeCache`.
    @usableFromInline
    let overflowSubviewIndex: Int?

    /// Structural separator relationships, built only when a subview carries a separator role.
    /// Reused across proposals and measurement/placement passes until the subviews are refreshed.
    @usableFromInline
    let separatorPlan: SeparatorPlan?

    @usableFromInline
    var hasSeparators: Bool { separatorPlan != nil }

    /// The subview carrying the report route. Read its current callback during placement: a
    /// body update can replace the registration while SwiftUI reuses an alignment cache.
    @usableFromInline
    let placementReporterIndex: Int?

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
            switch subviewsCache[$0].origin {
                case .flowContent: nil
                case .overflowBuilder: $0
            }
        }
        separatorPlan = SeparatorPlan(cachedSubviews: subviewsCache)
        placementReporterIndex = subviews.indices.first { subviews[$0][PlacementReporterKey.self] != nil }
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
