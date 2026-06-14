import SwiftUI

/// Cache to store certain properties of subviews in the layout (flexibility, spacing preferences, layout priority).
/// Even though it needs to be public (because it's part of the layout protocol conformance),
/// it's considered an internal implementation detail.
public struct FlowLayoutCache {
    package struct SubviewCache {
        package var priority: Double
        package var spacing: ViewSpacing
        package var ideal: Size
        package var max: Size
        package var layoutValues: LayoutValues
        package struct LayoutValues {
            package var shouldStartInNewLine: Bool
            package var isLineBreak: Bool
            package var flexibility: FlexibilityBehavior
        }

        // Non-inlinable: references `package` types (`Size`, `Subview`), which `@inlinable` cannot.
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
        }
    }

    package let subviewsCache: [SubviewCache]

    /// Single-entry memo of the most recent line-breaking result. `sizeThatFits`
    /// and `placeSubviews` run back-to-back with the same proposal, so caching the
    /// last result lets the second pass skip the (potentially expensive) line
    /// breaking. Keyed on the proposed breadth and depth — the only proposal inputs
    /// the line-breaking step depends on. Cleared whenever the cache is rebuilt.
    var lineBreaking: LineBreakingResult?

    struct LineBreakingKey: Equatable {
        var breadth: CGFloat
        var depth: CGFloat

        init(proposedSize: ProposedViewSize, axis: Axis) {
            breadth = proposedSize.value(on: axis)
            depth = proposedSize.value(on: axis.perpendicular)
        }
    }

    struct LineBreakingResult {
        var key: LineBreakingKey
        var lines: WrappedLines
    }

    init(_ subviews: some Subviews, axis: Axis) {
        subviewsCache = subviews.map { SubviewCache($0, axis: axis) }
    }

    func cachedLineBreaking(for key: LineBreakingKey) -> WrappedLines? {
        lineBreaking?.key == key ? lineBreaking?.lines : nil
    }

    mutating func cacheLineBreaking(_ lines: WrappedLines, for key: LineBreakingKey) {
        lineBreaking = LineBreakingResult(key: key, lines: lines)
    }

    mutating func rekeyLineBreaking(to key: LineBreakingKey) {
        lineBreaking?.key = key
    }

    /// Spacing between two subviews: the explicit `itemSpacing` when set, otherwise the distance
    /// between their `ViewSpacing` preferences along `axis`. Shared by ``FlowLayout`` and the optional
    /// features to avoid duplicating the same two-line fallback.
    package func spacing(from fromIndex: Int, to toIndex: Int, itemSpacing: CGFloat?, axis: Axis) -> CGFloat {
        if let itemSpacing { return itemSpacing }
        return subviewsCache[fromIndex].spacing.distance(to: subviewsCache[toIndex].spacing, along: axis)
    }
}
