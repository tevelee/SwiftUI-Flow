import SwiftUI

@usableFromInline
protocol Subviews: RandomAccessCollection where Element: FlowSubview, Index == Int {}

extension LayoutSubviews: FlowSubviews {}

@usableFromInline
protocol Subview {
    var spacing: ViewSpacing { get }
    var priority: Double { get }
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func dimensions(_ proposal: ProposedViewSize) -> any Dimensions
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
    subscript<K: LayoutValueKey>(key: K.Type) -> K.Value { get }
}

// Use the Flow-prefixed names at call sites to avoid SwiftUI's Subview name collision.
// Preserve the original protocol declarations for existing inline clients.
@usableFromInline typealias FlowSubview = Subview
@usableFromInline typealias FlowSubviews = Subviews

extension LayoutSubview: FlowSubview {
    @usableFromInline
    func dimensions(_ proposal: ProposedViewSize) -> any Dimensions {
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
    func size(on axis: Axis) -> AxisSize {
        AxisSize(
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
