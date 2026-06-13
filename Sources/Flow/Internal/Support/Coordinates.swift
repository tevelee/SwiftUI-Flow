import CoreFoundation
import SwiftUI

@usableFromInline
struct Size: Sendable {
    @usableFromInline
    var breadth: CGFloat
    @usableFromInline
    var depth: CGFloat

    @usableFromInline
    init(breadth: CGFloat, depth: CGFloat) {
        self.breadth = breadth
        self.depth = depth
    }

    @usableFromInline
    static let zero = Size(breadth: 0, depth: 0)

    @usableFromInline
    subscript(axis: Axis) -> CGFloat {
        get {
            self[keyPath: keyPath(on: axis)]
        }
        set {
            self[keyPath: keyPath(on: axis)] = newValue
        }
    }

    @usableFromInline
    func keyPath(on axis: Axis) -> WritableKeyPath<Size, CGFloat> {
        switch axis {
            case .horizontal: \.breadth
            case .vertical: \.depth
        }
    }
}

extension Axis {
    @usableFromInline
    var perpendicular: Axis {
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
protocol AxisConvertible {
    init(size: Size, axis: Axis)
    func value(on axis: Axis) -> CGFloat
}

extension AxisConvertible {
    @inlinable
    func size(on axis: Axis) -> Size {
        Size(breadth: value(on: axis), depth: value(on: axis.perpendicular))
    }
}

extension CGPoint: AxisConvertible {
    @inlinable
    init(size: Size, axis: Axis) {
        self.init(x: size[axis], y: size[axis.perpendicular])
    }

    @inlinable
    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: x
            case .vertical: y
        }
    }
}

extension CGSize: AxisConvertible {
    @inlinable
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    @inlinable
    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width
            case .vertical: height
        }
    }

    @inlinable
    static var infinity: CGSize {
        CGSize(
            width: CGFloat.infinity,
            height: CGFloat.infinity
        )
    }
}

extension ProposedViewSize: AxisConvertible {
    @inlinable
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    @inlinable
    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width ?? .infinity
            case .vertical: height ?? .infinity
        }
    }
}

extension CGRect {
    @inlinable
    func minimumValue(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: minX
            case .vertical: minY
        }
    }
}
