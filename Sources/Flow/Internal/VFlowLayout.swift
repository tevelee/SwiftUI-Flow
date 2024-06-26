import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct VFlowLayout {
    private let layout: FlowLayout

    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justification: Justification? = nil
    ) {
        layout = .vertical(
            alignment: alignment,
            itemSpacing: itemSpacing,
            lineSpacing: columnSpacing,
            justification: justification
        )
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VFlowLayout: Layout {
    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    public func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: .vertical)
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}
