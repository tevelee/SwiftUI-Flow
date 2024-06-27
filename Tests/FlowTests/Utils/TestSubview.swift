import SwiftUI
import XCTest
@testable import Flow

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
final class TestSubview: Subview, CustomStringConvertible {
    var spacing = ViewSpacing()
    var priority: Double = 1
    var placement: (position: CGPoint, size: CGSize)?
    var minSize: CGSize
    var idealSize: CGSize
    var maxSize: CGSize

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

    func dimensions(_ proposal: ProposedViewSize) -> Dimensions {
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
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension [TestSubview]: Subviews {}

typealias LayoutDescription = (subviews: [TestSubview], reportedSize: CGSize)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
func render(_ layout: LayoutDescription, border: Bool = true) -> String {
    struct Point: Hashable {
        let x, y: Int
    }

    var positions: Set<Point> = []
    for view in layout.subviews {
        if let placement = view.placement {
            let point = placement.position
            for y in Int(point.y) ..< Int(point.y + placement.size.height) {
                for x in Int(point.x) ..< Int(point.x + placement.size.width) {
                    let result = positions.insert(Point(x: x, y: y))
                    precondition(result.inserted, "Boxes should not overlap")
                }
            }
        } else {
            fatalError("Should be placed")
        }
    }
    let width = Int(layout.reportedSize.width)
    let height = Int(layout.reportedSize.height)
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
