import SwiftUI

struct VFlowLayout {
    let layout: FlowLayout

    init(alignment: HorizontalAlignment,
         itemSpacing: CGFloat?,
         columnSpacing: CGFloat?) {
        layout = FlowLayout(axis: .vertical,
                            itemSpacing: itemSpacing,
                            lineSpacing: columnSpacing) {
            $0[alignment]
        }
    }
}

extension VFlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}
