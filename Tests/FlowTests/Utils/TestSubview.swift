import SwiftUI
import Testing

@testable import Flow

#if FLOW_SNAPSHOT_TESTING
    import InlineSnapshotTesting
#endif

class TestSubview: FlowSubview, CustomStringConvertible {
    var spacing = ViewSpacing()
    var priority: Double = 1
    var placement: (position: CGPoint, size: CGSize)?
    var minSize: CGSize
    var idealSize: CGSize
    var maxSize: CGSize
    var firstBaseline: CGFloat?
    var lastBaseline: CGFloat?
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

    subscript<Key: LayoutValueKey>(key: Key.Type) -> Key.Value {
        get { layoutValues[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue }
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
        let size =
            switch proposal {
                case .zero: minSize
                case .unspecified: idealSize
                case .infinity: maxSize
                default: sizeThatFits(proposal)
            }
        return TestDimensions(width: size.width, height: size.height, firstBaseline: firstBaseline, lastBaseline: lastBaseline)
    }

    func place(at position: CGPoint, anchor _: UnitPoint, proposal: ProposedViewSize) {
        let size = sizeThatFits(proposal)
        placement = (position, size)
    }

    var description: String {
        let x = (placement?.position.x).map { "\($0)" } ?? "nil"
        let y = (placement?.position.y).map { "\($0)" } ?? "nil"
        return "origin: \(x)×\(y), size: \(idealSize.width)×\(idealSize.height)"
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

extension [TestSubview]: FlowSubviews {}

typealias LayoutDescription = (subviews: [TestSubview], reportedSize: CGSize)

struct ExpectedPlacement: Equatable, CustomStringConvertible {
    let position: CGPoint
    let size: CGSize

    init(position: (CGFloat, CGFloat), size: CGSize) {
        self.position = CGPoint(x: position.0, y: position.1)
        self.size = size
    }

    var description: String {
        "origin: \(position.x)×\(position.y), size: \(size.width)×\(size.height)"
    }
}

struct FlowLayoutScenario {
    let layout: FlowLayout
    let subviews: [TestSubview]
    let proposal: ProposedViewSize
    let bounds: CGRect?

    init(
        layout: FlowLayout,
        subviews: [TestSubview],
        proposal: ProposedViewSize,
        bounds: CGRect? = nil
    ) {
        self.layout = layout
        self.subviews = subviews
        self.proposal = proposal
        self.bounds = bounds
    }

    @discardableResult
    func layoutThatFits() -> LayoutDescription {
        layout.layoutThatFits(subviews, proposal: proposal, in: bounds)
    }

    @discardableResult
    func assertExpectedLayout(
        size expectedSize: CGSize,
        placements expectedPlacements: [ExpectedPlacement]
    ) -> LayoutDescription {
        let result = layoutThatFits()
        expectLayout(result, size: expectedSize)
        expectPlacements(result.subviews, expectedPlacements)
        return result
    }

    @discardableResult
    func assertExpectedSize(_ expectedSize: CGSize) -> LayoutDescription {
        let result = layoutThatFits()
        expectLayout(result, size: expectedSize)
        return result
    }
}

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

    func layoutThatFits(
        _ subviews: [TestSubview],
        proposal: ProposedViewSize,
        in bounds: CGRect? = nil
    ) -> LayoutDescription {
        var cache = makeCache(subviews)
        let reportedSize = sizeThatFits(
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
        placeSubviews(
            in: bounds ?? CGRect(origin: .zero, size: reportedSize),
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
        return (subviews, reportedSize)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: [TestSubview]) -> CGSize {
        var cache = makeCache(subviews)
        return sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }
}

func expectPlacements(
    _ subviews: [TestSubview],
    _ expected: [ExpectedPlacement]
) {
    #expect(subviews.count == expected.count, "Expected \(expected.count) placements, got \(subviews.count)")
    guard subviews.count == expected.count else {
        return
    }
    for index in subviews.indices {
        let actual = subviews[index].placement
        let expected = expected[index]
        #expect(
            actual?.position == expected.position,
            "Subview \(index) position: expected \(expected.position), got \(String(describing: actual?.position))"
        )
        #expect(
            actual?.size == expected.size,
            "Subview \(index) size: expected \(expected.size), got \(String(describing: actual?.size))"
        )
    }
}

func expectLayout(
    _ layout: LayoutDescription,
    size expectedSize: CGSize
) {
    #expect(layout.reportedSize == expectedSize)
}

// Inline-snapshot assertions require swift-snapshot-testing. The transcript suites that
// call these helpers are excluded from the test target unless FLOW_SNAPSHOT_TESTING is set
// (see Package.swift), so these definitions are gated on the same condition.
#if FLOW_SNAPSHOT_TESTING
    func labeledRender(_ layout: LayoutDescription) -> String {
        let width = Int(layout.reportedSize.width)
        let height = Int(layout.reportedSize.height)
        guard width > 0 && height > 0 else { return "(empty)" }

        var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)

        for (i, view) in layout.subviews.enumerated() {
            guard let placement = view.placement else {
                fatalError("Should be placed")
            }
            let label = layoutLabel(forSubviewAt: i)
            let x0 = Int(placement.position.x)
            let y0 = Int(placement.position.y)
            let w = Int(placement.size.width)
            let h = Int(placement.size.height)
            for y in y0 ..< (y0 + h) {
                for x in x0 ..< (x0 + w) {
                    guard y >= 0 && y < height && x >= 0 && x < width else {
                        continue
                    }
                    grid[y][x] = grid[y][x] == " " ? label : "*"
                }
            }
        }

        var result = "+" + String(repeating: "-", count: width) + "+\n"
        for y in 0 ..< height {
            result += "|" + String(grid[y]) + "|\n"
        }
        result += "+" + String(repeating: "-", count: width) + "+"
        return result
    }

    func layoutTranscript(_ layout: LayoutDescription) -> String {
        var lines = [
            "reportedSize: \(format(layout.reportedSize))",
            "placements:",
        ]

        for (index, view) in layout.subviews.enumerated() {
            let label = layoutLabel(forSubviewAt: index)
            let placement =
                view.placement.map {
                    "origin: \(format($0.position)), size: \(format($0.size))"
                } ?? "unplaced"
            lines.append("\(label)[\(index)]: \(placement)")
        }

        return lines.joined(separator: "\n")
    }

    private func layoutLabel(forSubviewAt index: Int) -> Character {
        layoutLabels[index % layoutLabels.count]
    }

    private func format(_ point: CGPoint) -> String {
        "\(format(point.x))×\(format(point.y))"
    }

    private func format(_ size: CGSize) -> String {
        "\(format(size.width))×\(format(size.height))"
    }

    private func format(_ value: CGFloat) -> String {
        if value == .infinity { return "inf" }
        if value == -.infinity { return "-inf" }
        let rounded = value.rounded()
        if abs(value - rounded) < 0.000_001 { return "\(Int(rounded))" }
        return "\(value)"
    }

    func assertLayoutRendering(
        _ layout: LayoutDescription,
        matches expected: (() -> String)? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertInlineSnapshot(
            of: labeledRender(layout),
            as: .lines,
            matches: expected,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
    }

    func assertLayoutTranscript(
        _ layout: LayoutDescription,
        matches expected: (() -> String)? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertInlineSnapshot(
            of: layoutTranscript(layout),
            as: .lines,
            matches: expected,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
    }
#endif

func testLineBreakSubview() -> TestSubview {
    let subview = TestSubview(size: .zero)
    subview[IsLineBreakLayoutValueKey.self] = true
    return subview
}

func testNewLineSubview(_ size: CGSize) -> TestSubview {
    let subview = TestSubview(size: size)
    subview[ShouldStartInNewLineLayoutValueKey.self] = true
    return subview
}

private let layoutLabels: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

private struct TestDimensions: Dimensions {
    let width, height: CGFloat
    var firstBaseline: CGFloat?
    var lastBaseline: CGFloat?

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
            case .firstTextBaseline: firstBaseline ?? 0
            case .lastTextBaseline: lastBaseline ?? height
            default: 0
        }
    }
}
