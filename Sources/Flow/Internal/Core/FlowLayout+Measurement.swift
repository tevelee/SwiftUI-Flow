import CoreFoundation
import SwiftUI

// Pipeline phase — measurement.
//
// Measures the content selected for line breaking (breadth range, spacing, priority, flags).
// Plain content uses direct indices; separator preparation selects content and reserves gap breadth.
// Overflow indicators and separators retain their cached measurements for the output feature steps.

extension FlowLayout {
    /// Prepares only the items that enter line breaking. With no separators, their positions already
    /// match subview indices, even when a cap excludes the trailing overflow indicator.
    func measuredItems(
        of subviews: some Subviews,
        in proposal: ProposedViewSize,
        cache: FlowLayoutCache,
        separators: SeparatorLayout?
    ) -> BreakerInput {
        let overflowIndex = lineCap == nil ? nil : cache.overflowSubviewIndex
        if let separators {
            return separators.prepareInput(excluding: overflowIndex) { offset, leadingSpace in
                breakerItem(
                    for: subviews[offset],
                    at: offset,
                    leadingSpace: leadingSpace,
                    in: proposal,
                    cache: cache
                )
            }
        }
        let indices = subviews.indices.dropLast(overflowIndex == nil ? 0 : 1)
        let items = indices.map { offset in
            breakerItem(
                for: subviews[offset],
                at: offset,
                leadingSpace: spacing(before: offset, cache: cache),
                in: proposal,
                cache: cache
            )
        }
        return BreakerInput(items: items)
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
            isLineBreakView: subviewCache.role == .lineBreak,
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
