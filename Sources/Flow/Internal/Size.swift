import CoreFoundation
import SwiftUI

struct Size {
    var breadth: CGFloat
    var depth: CGFloat

    static let zero = Size(breadth: 0, depth: 0)

    func adding(_ value: CGFloat, on axis: Axis) -> Size {
        var size = self
        size[axis] += value
        return size
    }

    fileprivate subscript(axis: Axis) -> CGFloat {
        get {
            self[keyPath: keyPath(on: axis)]
        }
        set {
            self[keyPath: keyPath(on: axis)] = newValue
        }
    }

    private func keyPath(on axis: Axis) -> WritableKeyPath<Size, CGFloat> {
        switch axis {
            case .horizontal:
                return \.breadth
            case .vertical:
                return \.depth
        }
    }
}

extension Axis {
    var perpendicular: Axis {
        switch self {
            case .horizontal:
                return .vertical
            case .vertical:
                return .horizontal
        }
    }
}

// MARK: Fixed orientation -> orientation independent

protocol FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis)
    func value(on axis: Axis) -> CGFloat
}

extension FixedOrientation2DCoordinate {
    func size(on axis: Axis) -> Size {
        Size(breadth: value(on: axis), depth: value(on: axis.perpendicular))
    }
}

extension CGPoint: FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis) {
        self.init(x: size[axis], y: size[axis.perpendicular])
    }

    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return x
            case .vertical:
                return y
        }
    }
}

extension CGSize: FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return width
            case .vertical:
                return height
        }
    }
}

extension ProposedViewSize: FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return width ?? .infinity
            case .vertical:
                return height ?? .infinity
        }
    }
}
