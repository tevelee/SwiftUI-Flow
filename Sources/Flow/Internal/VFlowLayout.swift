import SwiftUI

struct VFlowLayout {
    private let layout: FlowLayout

    init(alignment: HorizontalAlignment,
         itemSpacing: CGFloat?,
         columnSpacing: CGFloat?) {
        layout = .vertical(alignment: alignment,
                           itemSpacing: itemSpacing,
                           lineSpacing: columnSpacing)
    }
}

extension VFlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}
