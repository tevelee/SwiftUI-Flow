import SwiftUI

@usableFromInline
protocol Subviews: RandomAccessCollection where Element: Subview, Index == Int {}

extension LayoutSubviews: Subviews {}

@usableFromInline
protocol Subview {
    var spacing: ViewSpacing { get }
    var priority: Double { get }
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func dimensions(_ proposal: ProposedViewSize) -> Dimensions
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
}

extension LayoutSubview: Subview {
    @usableFromInline
    func dimensions(_ proposal: ProposedViewSize) -> Dimensions {
        dimensions(in: proposal)
    }
}

@usableFromInline
protocol Dimensions {
    var width: CGFloat { get }
    var height: CGFloat { get }

    subscript(guide: HorizontalAlignment) -> CGFloat { get }
    subscript(guide: VerticalAlignment) -> CGFloat { get }
}
extension ViewDimensions: Dimensions {}

extension Dimensions {
    @usableFromInline
    func size(on axis: Axis) -> Size {
        Size(
            breadth: value(on: axis),
            depth: value(on: axis.perpendicular)
        )
    }

    @usableFromInline
    func value(on axis: Axis) -> CGFloat {
        switch axis {
        case .horizontal: width
        case .vertical: height
        }
    }
}
