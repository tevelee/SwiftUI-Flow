import CoreFoundation
import SwiftUI

// Pipeline phase — measurement.
//
// Turns the subviews into one ``MeasuredItem`` each (a breadth range, spacing, priority, flags), the
// raw material the line breaker consumes. Produces a ``BreakerInput`` with an identity index map; the
// input-seam feature steps may then rewrite it.

extension FlowLayout {
    /// One breaker item per subview, in order, with an identity index map. The input-seam steps may
    /// then filter or rewrite this (excluding an overflow indicator, breaking only over content items).
    func measuredItems(
        of subviews: some Subviews,
        in proposal: ProposedViewSize,
        cache: FlowLayoutCache
    ) -> BreakerInput {
        let items = subviews.indices.map { offset in
            breakerItem(
                for: subviews[offset],
                at: offset,
                leadingSpace: spacing(before: offset, cache: cache),
                in: proposal,
                cache: cache
            )
        }
        return BreakerInput(items: items, subviewIndices: Array(subviews.indices))
    }

    private func breakerItem(
        for subview: some Subview,
        at offset: Int,
        leadingSpace: CGFloat,
        in proposal: ProposedViewSize,
        cache: FlowLayoutCache
    ) -> MeasuredItem {
        let subviewCache = cache.subviewsCache[offset]
        let minimumBreadth = minimumBreadth(for: subview, cache: subviewCache, in: proposal)
        let maximumBreadth = subviewCache.max.breadth
        return MeasuredItem(
            size: min(minimumBreadth, maximumBreadth) ... max(minimumBreadth, maximumBreadth),
            spacing: leadingSpace,
            priority: subviewCache.priority,
            flexibility: subviewCache.layoutValues.flexibility,
            isLineBreakView: subviewCache.layoutValues.isLineBreak,
            shouldStartInNewLine: subviewCache.layoutValues.shouldStartInNewLine
        )
    }

    private func minimumBreadth(
        for subview: some Subview,
        cache subviewCache: FlowLayoutCache.SubviewCache,
        in proposal: ProposedViewSize
    ) -> CGFloat {
        if subviewCache.ideal.breadth <= proposal.value(on: axis) {
            return subviewCache.ideal.breadth
        }
        return subview.sizeThatFits(proposal).value(on: axis)
    }

    /// Spacing before the subview at `offset`: the explicit `itemSpacing` if set, otherwise the
    /// subviews' combined `ViewSpacing` preferences. Zero before the first subview.
    func spacing(before offset: Int, cache: FlowLayoutCache) -> CGFloat {
        guard offset > cache.subviewsCache.startIndex else { return 0 }
        return cache.spacing(from: offset - 1, to: offset, itemSpacing: itemSpacing, axis: axis)
    }

    /// The breadth the breaker may fill: the proposed breadth, or `.infinity` when it is unspecified.
    func availableLineBreakingSpace(in proposal: ProposedViewSize) -> CGFloat {
        proposal.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
    }
}
