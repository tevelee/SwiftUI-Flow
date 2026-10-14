import CoreFoundation
import SwiftUI

// Pipeline phase — measurement.
//
// Measures a requested subview (breadth range, spacing, priority, flags).
// VisibleLineComposition selects content and reserves gap breadth before requesting measurements.

extension FlowLayout {
    func breakerItem(
        for subview: some FlowSubview,
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
        for subview: some FlowSubview,
        cache subviewCache: FlowLayoutCache.SubviewCache,
        in proposal: ProposedViewSize
    ) -> CGFloat {
        if subviewCache.ideal.breadth <= proposal.value(on: axis) {
            return subviewCache.ideal.breadth
        }
        return subview.sizeThatFits(proposal).value(on: axis)
    }

    /// The breadth the breaker may fill: the proposed breadth, or `.infinity` when it is unspecified.
    func availableLineBreakingSpace(in proposal: ProposedViewSize) -> CGFloat {
        proposal.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
    }
}
