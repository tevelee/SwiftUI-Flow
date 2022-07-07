import SwiftUI

struct HFlowLayout {
    let layout: FlowLayout

    init(alignment: VerticalAlignment,
         itemSpacing: CGFloat?,
         rowSpacing: CGFloat?) {
        let isRTL = Environment(\.layoutDirection).wrappedValue == .rightToLeft
        layout = FlowLayout(axis: .horizontal,
                            itemSpacing: itemSpacing,
                            lineSpacing: rowSpacing,
                            reversedBreadth: isRTL) {
            $0[alignment]
        }
    }
}

extension HFlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}
