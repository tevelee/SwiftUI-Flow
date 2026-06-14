import SwiftUI

package protocol Subviews: RandomAccessCollection where Element: Subview, Index == Int {}

extension LayoutSubviews: Subviews {}

package protocol Subview {
    var spacing: ViewSpacing { get }
    var priority: Double { get }
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func dimensions(_ proposal: ProposedViewSize) -> any Dimensions
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
    subscript<K: LayoutValueKey>(key: K.Type) -> K.Value { get }
}

// SwiftUI also defines a `Subview` type starting in newer SDK versions. Tests should
// use these typealiases to avoid ambiguity when `@testable import Flow` is combined with
// `import SwiftUI`.
package typealias FlowSubview = Subview
package typealias FlowSubviews = Subviews

extension LayoutSubview: Subview {
    package func dimensions(_ proposal: ProposedViewSize) -> any Dimensions {
        dimensions(in: proposal)
    }
}

package protocol Dimensions {
    var width: CGFloat { get }
    var height: CGFloat { get }

    subscript(guide: HorizontalAlignment) -> CGFloat { get }
    subscript(guide: VerticalAlignment) -> CGFloat { get }
}

extension ViewDimensions: Dimensions {}

extension Dimensions {
    package func size(on axis: Axis) -> Size {
        Size(
            breadth: value(on: axis),
            depth: value(on: axis.perpendicular)
        )
    }

    package func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width
            case .vertical: height
        }
    }
}
