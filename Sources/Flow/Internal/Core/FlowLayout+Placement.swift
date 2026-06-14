import CoreFoundation
import SwiftUI

// Pipeline phase — placement.
//
// Walks the finished geometry and hands every subview to SwiftUI via `place(at:anchor:proposal:)`,
// advancing the cursor by each block's leading space and size. Truncated subviews are parked
// off-screen. Feeding structural facts back to the view layer (overflow count, line structure) is the
// job of the optional features themselves, via ``FlowFeatureSession/report(_:)``.

extension FlowLayout {
    /// Advances `target` along `axis` for one ``Spaced`` block: add its leading space, run `body` at
    /// the block's origin, then add its size. Used for both lines (along depth) and items (along breadth).
    func advance(
        _ target: inout Size,
        _ axis: WritableKeyPath<Size, CGFloat>,
        for element: some Spaced,
        body: (inout Size) -> Void
    ) {
        target[keyPath: axis] += element.leadingSpace
        body(&target)
        target[keyPath: axis] += element.size[keyPath: axis]
    }

    func alignAndPlace(
        _ item: PlacedItem,
        in line: LayoutLine,
        at target: Size
    ) {
        var position = target
        let size = Size(breadth: item.size.breadth, depth: line.size.depth)
        let proposedSize = ProposedViewSize(size: size, axis: axis)
        // Align the item's guide (e.g. its baseline) onto the line's common guide.
        let offset = line.depthGuide - item.depthGuide
        // Skip a non-finite offset (e.g. unbounded item/line depth).
        if offset.isFinite {
            position.depth += offset
        }
        // Never hand a non-finite coordinate to CoreGraphics.
        let point = CGPoint(size: position, axis: axis).finite(or: 0)
        item.subview.place(at: point, anchor: .topLeading, proposal: proposedSize)
    }

    func effectiveProposal(for proposal: ProposedViewSize, in bounds: CGRect) -> ProposedViewSize {
        // .frame(maxHeight:) passes the parent's nil proposal through unchanged but clips
        // our reported size to maxHeight, so use bounds when the proposal is unbounded.
        guard !proposal.value(on: axis).isFinite else {
            return proposal
        }
        return ProposedViewSize(
            size: Size(
                breadth: bounds.size.value(on: axis),
                depth: proposal.value(on: axis.perpendicular)
            ),
            axis: axis
        )
    }

    /// Places truncated subviews. SwiftUI requires every subview be placed exactly once, so collapse
    /// them with a zero proposal and park them well outside the visible bounds where they won't draw.
    func placeHiddenSubviews(_ indices: [Int], of subviews: some Subviews, in bounds: CGRect) {
        guard !indices.isEmpty else { return }
        let sentinel = CGPoint(x: bounds.minX, y: bounds.maxY + hiddenSubviewOffset).finite(or: 0)
        for index in indices {
            subviews[index].place(at: sentinel, anchor: .topLeading, proposal: .zero)
        }
    }
}

/// Far enough outside any realistic layout that truncated (hidden) subviews never draw.
private let hiddenSubviewOffset: CGFloat = 1_000_000

extension CGFloat {
    /// The value if finite, else the fallback — keeps NaN/±∞ out of CoreGraphics.
    func finite(or fallback: CGFloat) -> CGFloat {
        isFinite ? self : fallback
    }
}

extension CGPoint {
    func finite(or fallback: CGFloat) -> CGPoint {
        CGPoint(x: x.finite(or: fallback), y: y.finite(or: fallback))
    }
}
