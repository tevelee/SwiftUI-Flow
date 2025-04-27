import SwiftUI
import XCTest
@testable import Flow

class TestSubview: Flow.Subview, CustomStringConvertible {
    var spacing = ViewSpacing()
    var priority: Double = 1
    var placement: (position: CGPoint, size: CGSize)?
    var minSize: CGSize
    var idealSize: CGSize
    var maxSize: CGSize
    var layoutValues: [ObjectIdentifier: Any] = [:]

    init(size: CGSize) {
        minSize = size
        idealSize = size
        maxSize = size
    }

    init(minSize: CGSize, idealSize: CGSize, maxSize: CGSize) {
        self.minSize = minSize
        self.idealSize = idealSize
        self.maxSize = maxSize
    }

    subscript<K: LayoutValueKey>(key: K.Type) -> K.Value {
        get { layoutValues[ObjectIdentifier(key)] as? K.Value ?? K.defaultValue }
        set { layoutValues[ObjectIdentifier(key)] = newValue }
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        switch proposal {
        case .zero:
            minSize
        case .unspecified:
            idealSize
        case .infinity:
            maxSize
        default:
            CGSize(
                width: min(max(minSize.width, proposal.width ?? idealSize.width), maxSize.width),
                height: min(max(minSize.height, proposal.height ?? idealSize.height), maxSize.height)
            )
        }
    }

    func dimensions(_ proposal: ProposedViewSize) -> any Dimensions {
        let size = switch proposal {
        case .zero:  minSize
        case .unspecified: idealSize
        case .infinity: maxSize
        default: sizeThatFits(proposal)
        }
        return TestDimensions(width: size.width, height: size.height)
    }

    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize) {
        let size = sizeThatFits(proposal)
        placement = (position, size)
    }

    var description: String {
        "origin: \((placement?.position.x).map { "\($0)" } ?? "nil")×\((placement?.position.y).map { "\($0)" } ?? "nil"), size: \(idealSize.width)×\(idealSize.height)"
    }

    func flexibility(_ behavior: FlexibilityBehavior) -> Self {
        self[FlexibilityLayoutValueKey.self] = behavior
        return self
    }
}

final class WrappingText: TestSubview {
    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let area = idealSize.width * idealSize.height
        if let proposedWidth = proposal.width, idealSize.width > proposedWidth {
            let height = (Int(1)...).first { area <= proposedWidth * CGFloat($0) }!
            return CGSize(width: proposedWidth, height: CGFloat(height))
        }
        if let proposedHeight = proposal.height, idealSize.height > proposedHeight {
            let width = (Int(1)...).first { area <= proposedHeight * CGFloat($0) }!
            return CGSize(width: CGFloat(width), height: proposedHeight)
        }
        return super.sizeThatFits(proposal)
    }
}

extension [TestSubview]: Flow.Subviews {}

typealias LayoutDescription = (subviews: [TestSubview], reportedSize: CGSize)

extension FlowLayout {
    func layout(_ subviews: [TestSubview], in bounds: CGSize) -> LayoutDescription {
        var cache = makeCache(subviews)
        let size = sizeThatFits(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews,
            cache: &cache
        )
        placeSubviews(
            in: CGRect(origin: .zero, size: bounds),
            proposal: ProposedViewSize(
                width: min(size.width, bounds.width),
                height: min(size.height, bounds.height)
            ),
            subviews: subviews,
            cache: &cache
        )
        return (subviews, bounds)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: [TestSubview]) -> CGSize {
        var cache = makeCache(subviews)
        return sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }
}

func render(_ layout: LayoutDescription, border: Bool = true) -> String {
    struct Point: Hashable {
        let x, y: Int
    }
    let width = Int(layout.reportedSize.width)
    let height = Int(layout.reportedSize.height)

    var positions: Set<Point> = []
    for view in layout.subviews {
        if let placement = view.placement {
            let point = placement.position
            for y in Int(point.y) ..< Int(point.y + placement.size.height) {
                for x in Int(point.x) ..< Int(point.x + placement.size.width) {
                    let result = positions.insert(Point(x: x, y: y))
                    precondition(result.inserted, "Boxes should not overlap")
                    precondition(x >= 0 && x < width && y >= 0 && y < height, "Out of bounds")
                }
            }
        } else {
            fatalError("Should be placed")
        }
    }
    var result = ""
    if border {
        result += "+" + String(repeating: "-", count: width) + "+\n"
    }
    for y in 0 ... height - 1 {
        if border {
            result += "|"
        }
        for x in 0 ... width - 1 {
            result += positions.contains(Point(x: x, y: y)) ? "X" : " "
        }
        if border {
            result += "|"
        } else {
            result = result.trimmingCharacters(in: .whitespaces)
        }
        result += "\n"
    }
    if border {
        result += "+" + String(repeating: "-", count: width) + "+\n"
    }
    return result.trimmingCharacters(in: .newlines)
}

private struct TestDimensions: Dimensions {
    let width, height: CGFloat

    subscript(guide: HorizontalAlignment) -> CGFloat {
        switch guide {
            case .center: 0.5 * width
            case .trailing: width
            default: 0
        }
    }

    subscript(guide: VerticalAlignment) -> CGFloat {
        switch guide {
            case .center: 0.5 * height
            case .bottom: height
            default: 0
        }
    }
}
