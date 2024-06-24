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
            case .horizontal: \.breadth
            case .vertical: \.depth
        }
    }
}

extension Axis {
    var perpendicular: Axis {
        switch self {
            case .horizontal: .vertical
            case .vertical: .horizontal
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
            case .horizontal: x
            case .vertical: y
        }
    }
}

extension CGSize: FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width
            case .vertical: height
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ProposedViewSize: FixedOrientation2DCoordinate {
    init(size: Size, axis: Axis) {
        self.init(width: size[axis], height: size[axis.perpendicular])
    }

    func value(on axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal: width ?? .infinity
            case .vertical: height ?? .infinity
        }
    }
}
