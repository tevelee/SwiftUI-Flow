import CoreFoundation
import SwiftUI

package struct Size: Sendable {
    package var breadth: CGFloat
    package var depth: CGFloat

    package init(breadth: CGFloat, depth: CGFloat) {
        self.breadth = breadth
        self.depth = depth
    }

    package static let zero = Size(breadth: 0, depth: 0)

    package subscript(axis: Axis) -> CGFloat {
        get {
            self[keyPath: keyPath(on: axis)]
        }
        set {
            self[keyPath: keyPath(on: axis)] = newValue
        }
    }

    package func keyPath(on axis: Axis) -> WritableKeyPath<Size, CGFloat> {
        switch axis {
            case .horizontal: \.breadth
            case .vertical: \.depth
        }
    }
}

extension Axis {
    package var perpendicular: Axis {
        switch self {
            case .horizontal: .vertical
            case .vertical: .horizontal
        }
    }
}

// MARK: - Axis-relative conversion

/// A concrete 2D value (point, size, proposal) that converts to and from axis-relative ``Size``
/// (breadth/depth) terms, so the axis-agnostic algorithm can read and write it without caring which
/// axis maps to x and which to y.
package protocol AxisConvertible {
    init(size: Size, axis: Axis)
    func value(on axis: Axis) -> CGFloat
}

extension AxisConvertible {
    package func size(on axis: Axis) -> Size {
        Size(breadth: value(on: axis), depth: value(on: axis.perpendicular))
    }
}

extension CGPoint: AxisConvertible {
    package init(size: Size, axis: Axis) {
        self.init(x: size[axis], y: size[axis.perpendicular])
    }

    package func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: x
            case .vertical: y
        }
    }
}

extension CGSize: AxisConvertible {
    package init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    package func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width
            case .vertical: height
        }
    }

    package static var infinity: CGSize {
        CGSize(
            width: CGFloat.infinity,
            height: CGFloat.infinity
        )
    }
}

extension ProposedViewSize: AxisConvertible {
    package init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    package func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width ?? .infinity
            case .vertical: height ?? .infinity
        }
    }
}

extension CGRect {
    package func minimumValue(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: minX
            case .vertical: minY
        }
    }
}
