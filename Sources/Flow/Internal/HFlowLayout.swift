import SwiftUI

struct HFlowLayout {
    private let layout: FlowLayout

    init(alignment: VerticalAlignment,
         itemSpacing: CGFloat?,
         rowSpacing: CGFloat?) {
        layout = .horizontal(alignment: alignment,
                             itemSpacing: itemSpacing,
                             lineSpacing: rowSpacing)
    }
}

extension HFlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal
        return properties
    }
}
