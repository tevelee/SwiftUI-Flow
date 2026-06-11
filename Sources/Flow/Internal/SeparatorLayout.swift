import CoreFoundation
import SwiftUI

/// Encapsulates the separator feature for ``FlowLayout`` — much like ``LineCap`` encapsulates line
/// limits. The core layout stays separator-agnostic and only asks this type, at a few well-defined
/// seams, how much space a gap needs, which separator (if any) fills it, where the content landed, and
/// which separators went unused. Created only when a subview carries a non-`content` ``SeparatorRole``.
struct SeparatorLayout {
    /// An item separator to draw in-line between two items on the same line.
    struct ItemSeparator {
        var index: Int
        var breadth: CGFloat
        var depth: CGFloat
        var leadingSpace: CGFloat
    }

    private let plan: SeparatorPlan
    private let axis: Axis
    private let itemSpacing: CGFloat?
    private let cache: FlowLayoutCache

    init?(cache: FlowLayoutCache, axis: Axis, itemSpacing: CGFloat?) {
        guard cache.hasSeparators else { return nil }
        plan = SeparatorPlan(
            roles: cache.subviewsCache.map(\.separatorRole),
            isLineBreak: cache.subviewsCache.map { $0.layoutValues.isLineBreak }
        )
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.cache = cache
    }

    /// The subview indices of the content items, in order.
    var contentIndices: [Int] { plan.contentIndices }

    /// Translates the breaker's positional indices (into its content-only input) back to subview indices
    /// so every downstream step can address subviews and the cache directly.
    func resolved(_ lines: LineBreakingOutput) -> LineBreakingOutput {
        lines.map { line in
            line.map { LineItemOutput(index: plan.contentIndices[$0.index], size: $0.size, leadingSpace: $0.leadingSpace) }
        }
    }

    /// Leading space the breaker reserves before the content item at `position`: the normal spacing,
    /// plus the item separator's breadth and its own spacing when an eligible gap carries one. The
    /// breaker drops it automatically where a line breaks (first-on-line items get zero leading space),
    /// which is exactly where the item separator yields to a line separator.
    func breakerSpacing(beforeContentPosition position: Int) -> CGFloat {
        guard position > 0 else { return 0 }
        let current = plan.contentIndices[position]
        let previous = plan.contentIndices[position - 1]
        if let separator = itemSeparator(before: current) {
            return spacing(from: previous, to: separator.index) + separator.breadth + spacing(from: separator.index, to: current)
        }
        return spacing(from: previous, to: current)
    }

    /// The eligible item separator drawn before content item `contentIndex`, or `nil` when its gap
    /// carries no in-line separator.
    func itemSeparator(before contentIndex: Int) -> ItemSeparator? {
        guard let position = plan.position(ofContentIndex: contentIndex),
            let gap = plan.gap(before: position),
            gap.isEligible,
            let separator = gap.itemSeparator
        else { return nil }
        return ItemSeparator(
            index: separator,
            breadth: cache.subviewsCache[separator].ideal.breadth,
            depth: cache.subviewsCache[separator].ideal.depth,
            leadingSpace: spacing(from: plan.contentIndices[position - 1], to: separator)
        )
    }

    /// The eligible line separator for the boundary before the line that begins with `contentIndex`.
    func lineSeparator(startingLineAt contentIndex: Int) -> Int? {
        guard let position = plan.position(ofContentIndex: contentIndex),
            let gap = plan.gap(before: position),
            gap.isEligible
        else { return nil }
        return gap.lineSeparator
    }

    /// The ideal depth of an item separator (so a line is tall enough to contain it).
    func depth(ofSeparator index: Int) -> CGFloat {
        cache.subviewsCache[index].ideal.depth
    }

    /// The line index of every content item, in content order, derived from the content-only wrapping.
    /// Reported back to the view layer so line separators can be identified by their visual position.
    /// Hidden items (capped by maxLines) are assigned `hiddenLineSentinel` so the view layer can
    /// distinguish them from visible items on line 0 and avoid injecting spurious separators.
    func lineStructure(of visible: LineBreakingOutput) -> [Int] {
        var lineOf = [Int](repeating: SeparatorLayout.hiddenLineSentinel, count: plan.contentIndices.count)
        for lineIndex in visible.indices {
            for item in visible[lineIndex] {
                if let position = plan.position(ofContentIndex: item.index) {
                    lineOf[position] = lineIndex
                }
            }
        }
        return lineOf
    }

    /// Sentinel stored in `lineStructure` for content items absent from the visible output (capped by
    /// maxLines). The value is negative so the view layer can check `>= 0` for visibility.
    static let hiddenLineSentinel = -1

    /// Separators left unused — orphaned at an edge, mid-line, or in a truncated/ineligible gap. They
    /// must still be placed once and collapsed off-screen, like truncated content.
    func unusedSeparators(placed: Set<Int>) -> [Int] {
        plan.separatorIndices.filter { !placed.contains($0) }
    }

    private func spacing(from previous: Int, to current: Int) -> CGFloat {
        cache.spacing(from: previous, to: current, itemSpacing: itemSpacing, axis: axis)
    }
}
