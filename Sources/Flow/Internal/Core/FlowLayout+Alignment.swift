import CoreFoundation
import SwiftUI

extension FlowLayout {
    /// Preserve SwiftUI's cached guide calculation. Probe placements only report candidates;
    /// the reporting module confirms rendered geometry before publishing them.
    @usableFromInline
    func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout FlowLayoutCache
    ) -> CGFloat? {
        return DefaultAlignmentLayout(layout: self).explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    @usableFromInline
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout FlowLayoutCache
    ) -> CGFloat? {
        return DefaultAlignmentLayout(layout: self).explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}

/// Inherits the default guide calculation without recursing into FlowLayout's overrides.
/// SwiftUI can route its placement probes through the original layout and a copy of its cache.
private struct DefaultAlignmentLayout: Layout {
    let layout: FlowLayout

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        layout.makeCache(subviews)
    }
}
