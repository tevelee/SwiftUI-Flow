import PropertyBased
import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements, .invariant))
struct FlowInvariantRequirementTests {
    @Suite("Geometry")
    struct Geometry {
        @Test func finiteScenarios_placeEverySubviewWithFiniteNonNegativeGeometry() {
            for scenario in invariantCases() {
                assertPlacesEverySubviewWithFiniteNonNegativeGeometry(scenario)
            }
        }

        @Test func generatedCommonScenarios_placeEverySubviewWithFiniteNonNegativeGeometry() async {
            await propertyCheck(count: generatedCommonInvariantCheckCount, input: generatedCommonInvariantCase) { generated in
                assertPlacesEverySubviewWithFiniteNonNegativeGeometry(generated.makeCase())
            }
        }

        @Test func generatedEdgeScenarios_placeEverySubviewWithFiniteNonNegativeGeometry() async {
            await propertyCheck(count: generatedEdgeInvariantCheckCount, input: generatedEdgeInvariantCase) { generated in
                assertPlacesEverySubviewWithFiniteNonNegativeGeometry(generated.makeCase())
            }
        }

        @Test func finiteScenarios_keepVisiblePlacementsInsideReportedSize() {
            for scenario in invariantCases() {
                assertKeepsVisiblePlacementsInsideReportedSize(scenario)
            }
        }

        @Test func generatedCommonScenarios_keepVisiblePlacementsInsideReportedSize() async {
            await propertyCheck(count: generatedCommonInvariantCheckCount, input: generatedCommonInvariantCase) { generated in
                assertKeepsVisiblePlacementsInsideReportedSize(generated.makeCase())
            }
        }

        @Test func generatedEdgeScenarios_keepVisiblePlacementsInsideReportedSize() async {
            await propertyCheck(count: generatedEdgeInvariantCheckCount, input: generatedEdgeInvariantCase) { generated in
                assertKeepsVisiblePlacementsInsideReportedSize(generated.makeCase())
            }
        }
    }

    @Suite("Ordering")
    struct Ordering {
        @Test func finiteScenarios_preserveVisibleTraversalOrder() {
            for scenario in invariantCases() {
                assertPreservesVisibleTraversalOrder(scenario)
            }
        }

        @Test func generatedCommonScenarios_preserveVisibleTraversalOrder() async {
            await propertyCheck(count: generatedCommonInvariantCheckCount, input: generatedCommonInvariantCase) { generated in
                assertPreservesVisibleTraversalOrder(generated.makeCase())
            }
        }

        @Test func generatedEdgeScenarios_preserveVisibleTraversalOrder() async {
            await propertyCheck(count: generatedEdgeInvariantCheckCount, input: generatedEdgeInvariantCase) { generated in
                assertPreservesVisibleTraversalOrder(generated.makeCase())
            }
        }
    }

    @Suite("Spacing")
    struct Spacing {
        @Test func generatedZeroSubviewSpacing_matchesExplicitZeroSpacing() async {
            await propertyCheck(count: generatedSpacingFallbackCheckCount, input: generatedSpacingFallbackCase) { generated in
                assertNilSpacingMatchesExplicitZeroSpacing(generated.makeCase())
            }
        }
    }

    @Suite("EdgeCases")
    struct EdgeCases {
        @Test func generatedCommonScenarios_keepVisibleFramesDisjointWhenSpacingIsNonNegative() async {
            await propertyCheck(count: generatedCommonInvariantCheckCount, input: generatedCommonInvariantCase) { generated in
                assertVisibleFramesDoNotOverlapWhenSpacingIsNonNegative(generated.makeCase())
            }
        }

        @Test func generatedFractionalScenarios_placeEverySubviewWithFiniteNonNegativeGeometry() async {
            await propertyCheck(count: generatedFractionalCheckCount, input: generatedFractionalInvariantCase) { generated in
                assertPlacesEverySubviewWithFiniteNonNegativeGeometry(generated.makeCase())
            }
        }

        @Test func generatedFractionalScenarios_keepVisiblePlacementsInsideReportedSize() async {
            await propertyCheck(count: generatedFractionalCheckCount, input: generatedFractionalInvariantCase) { generated in
                assertKeepsVisiblePlacementsInsideReportedSize(generated.makeCase())
            }
        }
    }

    @Suite("Metamorphic")
    struct Metamorphic {
        @Test func transposedScenarios_matchAcrossOrientations() {
            for scenario in transposeCases() {
                assertMatchesAcrossOrientations(scenario)
            }
        }

        @Test func generatedTransposedScenarios_matchAcrossOrientations() async {
            await propertyCheck(count: generatedTransposeCheckCount, input: generatedTransposeCase) { generated in
                assertMatchesAcrossOrientations(generated.makeCase())
            }
        }

        @Test func generatedScenarios_increasingAvailableBreadthDoesNotDecreaseReportedBreadth() async {
            await propertyCheck(count: generatedMonotonicCheckCount, input: generatedMonotonicCase) { generated in
                assertIncreasingAvailableBreadthDoesNotDecreaseReportedBreadth(generated.makeCase())
            }
        }
    }
}

private let tolerance: CGFloat = 0.000_001
private let generatedCommonInvariantCheckCount = 150
private let generatedEdgeInvariantCheckCount = 100
private let generatedFractionalCheckCount = 100
private let generatedSpacingFallbackCheckCount = 80
private let generatedTransposeCheckCount = 80
private let generatedMonotonicCheckCount = 80

private enum FlowInvariantOrientation: CaseIterable, Sendable, CustomStringConvertible {
    case horizontal
    case vertical

    func size(breadth: CGFloat, depth: CGFloat) -> CGSize {
        switch self {
            case .horizontal:
                CGSize(width: breadth, height: depth)
            case .vertical:
                CGSize(width: depth, height: breadth)
        }
    }

    func proposal(breadth: CGFloat, depth: CGFloat) -> ProposedViewSize {
        switch self {
            case .horizontal:
                ProposedViewSize(width: breadth, height: depth)
            case .vertical:
                ProposedViewSize(width: depth, height: breadth)
        }
    }

    func depth(of size: CGSize) -> CGFloat {
        switch self {
            case .horizontal: size.height
            case .vertical: size.width
        }
    }

    func breadth(of size: CGSize) -> CGFloat {
        switch self {
            case .horizontal: size.width
            case .vertical: size.height
        }
    }

    var description: String {
        switch self {
            case .horizontal: "HFlow"
            case .vertical: "VFlow"
        }
    }
}

private enum GeneratedScenarioCategory: String, Sendable, CustomStringConvertible {
    case common
    case edge
    case transpose
    case monotonic
    case spacingFallback

    var description: String { rawValue }
}

private struct FlowInvariantCase {
    let name: String
    let orientation: FlowInvariantOrientation
    let layout: FlowLayout
    let subviews: [TestSubview]
    let proposal: ProposedViewSize
    let bounds: CGRect?

    init(
        name: String,
        orientation: FlowInvariantOrientation,
        layout: FlowLayout,
        subviews: [TestSubview],
        proposal: ProposedViewSize,
        bounds: CGRect? = nil
    ) {
        self.name = name
        self.orientation = orientation
        self.layout = layout
        self.subviews = subviews
        self.proposal = proposal
        self.bounds = bounds
    }

    func layoutThatFits() -> LayoutDescription {
        FlowLayoutScenario(layout: layout, subviews: subviews, proposal: proposal, bounds: bounds)
            .layoutThatFits()
    }
}

private struct IndexedPlacement {
    let index: Int
    let placement: (position: CGPoint, size: CGSize)
}

private struct TransposeCase {
    let name: String
    let horizontal: FlowInvariantCase
    let vertical: FlowInvariantCase
}

private struct MonotonicProposalCase {
    let name: String
    let orientation: FlowInvariantOrientation
    let smaller: FlowInvariantCase
    let larger: FlowInvariantCase
}

private struct SpacingFallbackCase {
    let name: String
    let nilSpacing: FlowInvariantCase
    let explicitZeroSpacing: FlowInvariantCase
}

private func assertPlacesEverySubviewWithFiniteNonNegativeGeometry(_ scenario: FlowInvariantCase) {
    let result = scenario.layoutThatFits()

    #expect(result.subviews.count == scenario.subviews.count, "\(scenario.name) should preserve subview count")

    for (index, subview) in result.subviews.enumerated() {
        guard scenario.subviews.indices.contains(index) else {
            continue
        }
        #expect(subview === scenario.subviews[index], "\(scenario.name) should preserve subview \(index) identity")
        #expect(subview.placement != nil, "\(scenario.name) should place subview \(index)")
        guard let placement = subview.placement else {
            continue
        }

        expectFinite(placement.position.x, "\(scenario.name) subview \(index) x")
        expectFinite(placement.position.y, "\(scenario.name) subview \(index) y")
        expectFinite(placement.size.width, "\(scenario.name) subview \(index) width")
        expectFinite(placement.size.height, "\(scenario.name) subview \(index) height")
        #expect(placement.size.width >= 0, "\(scenario.name) subview \(index) width should be non-negative")
        #expect(placement.size.height >= 0, "\(scenario.name) subview \(index) height should be non-negative")
    }
}

private func assertKeepsVisiblePlacementsInsideReportedSize(_ scenario: FlowInvariantCase) {
    let result = scenario.layoutThatFits()
    expectFinite(result.reportedSize.width, "\(scenario.name) reported width")
    expectFinite(result.reportedSize.height, "\(scenario.name) reported height")
    #expect(result.reportedSize.width >= 0, "\(scenario.name) reported width should be non-negative")
    #expect(result.reportedSize.height >= 0, "\(scenario.name) reported height should be non-negative")
    let placementBoundsSize = scenario.bounds?.size ?? result.reportedSize

    for (index, subview) in result.subviews.enumerated() {
        guard let placement = subview.placement else {
            continue
        }
        let frame = CGRect(origin: placement.position, size: placement.size)
        #expect(frame.minX >= -tolerance, "\(scenario.name) subview \(index) should not be left of placement bounds")
        #expect(frame.minY >= -tolerance, "\(scenario.name) subview \(index) should not be above placement bounds")
        #expect(
            frame.maxX <= placementBoundsSize.width + tolerance,
            "\(scenario.name) subview \(index) should not exceed placement bounds width"
        )
        #expect(
            frame.maxY <= placementBoundsSize.height + tolerance,
            "\(scenario.name) subview \(index) should not exceed placement bounds height"
        )
    }
}

private func assertPreservesVisibleTraversalOrder(_ scenario: FlowInvariantCase) {
    let result = scenario.layoutThatFits()
    let visiblePlacements = result.subviews.enumerated().compactMap { index, subview in
        subview.placement.flatMap { placement in
            placement.size.width > 0 && placement.size.height > 0
                ? IndexedPlacement(index: index, placement: placement)
                : nil
        }
    }

    for (previous, next) in zip(visiblePlacements, visiblePlacements.dropFirst()) {
        switch scenario.orientation {
            case .horizontal:
                let sameOrLaterInRow = next.placement.position.x + tolerance >= previous.placement.position.x
                let laterRow = next.placement.position.y + tolerance >= previous.placement.position.y
                #expect(
                    sameOrLaterInRow || laterRow,
                    "\(scenario.name) visible subview \(next.index) should not move before subview \(previous.index)"
                )
            case .vertical:
                let sameOrLaterInColumn = next.placement.position.y + tolerance >= previous.placement.position.y
                let laterColumn = next.placement.position.x + tolerance >= previous.placement.position.x
                #expect(
                    sameOrLaterInColumn || laterColumn,
                    "\(scenario.name) visible subview \(next.index) should not move before subview \(previous.index)"
                )
        }
    }
}

private func assertMatchesAcrossOrientations(_ scenario: TransposeCase) {
    let horizontal = scenario.horizontal.layoutThatFits()
    let vertical = scenario.vertical.layoutThatFits()

    expectApproximatelyEqual(
        vertical.reportedSize,
        transpose(horizontal.reportedSize),
        "\(scenario.name) reported size"
    )
    #expect(horizontal.subviews.count == vertical.subviews.count, "\(scenario.name) should preserve subview count")

    for index in 0 ..< min(horizontal.subviews.count, vertical.subviews.count) {
        #expect(horizontal.subviews[index].placement != nil, "\(scenario.name) should place horizontal subview \(index)")
        guard let horizontalPlacement = horizontal.subviews[index].placement else {
            continue
        }
        #expect(vertical.subviews[index].placement != nil, "\(scenario.name) should place vertical subview \(index)")
        guard let verticalPlacement = vertical.subviews[index].placement else {
            continue
        }

        expectApproximatelyEqual(
            verticalPlacement.position,
            transpose(horizontalPlacement.position),
            "\(scenario.name) subview \(index) origin"
        )
        expectApproximatelyEqual(
            verticalPlacement.size,
            transpose(horizontalPlacement.size),
            "\(scenario.name) subview \(index) size"
        )
    }
}

private func assertIncreasingAvailableBreadthDoesNotDecreaseReportedBreadth(_ scenario: MonotonicProposalCase) {
    let smaller = scenario.smaller.layoutThatFits()
    let larger = scenario.larger.layoutThatFits()
    let smallerBreadth = scenario.orientation.breadth(of: smaller.reportedSize)
    let largerBreadth = scenario.orientation.breadth(of: larger.reportedSize)

    #expect(
        largerBreadth + tolerance >= smallerBreadth,
        "\(scenario.name) larger proposal breadth \(largerBreadth) should not be less than smaller proposal breadth \(smallerBreadth)"
    )
}

private func assertNilSpacingMatchesExplicitZeroSpacing(_ scenario: SpacingFallbackCase) {
    let nilSpacing = scenario.nilSpacing.layoutThatFits()
    let explicitZeroSpacing = scenario.explicitZeroSpacing.layoutThatFits()

    expectApproximatelyEqual(nilSpacing.reportedSize, explicitZeroSpacing.reportedSize, "\(scenario.name) reported size")
    #expect(
        nilSpacing.subviews.count == explicitZeroSpacing.subviews.count,
        "\(scenario.name) should preserve subview count"
    )

    for index in 0 ..< min(nilSpacing.subviews.count, explicitZeroSpacing.subviews.count) {
        guard let nilPlacement = nilSpacing.subviews[index].placement else {
            #expect(Bool(false), "\(scenario.name) nil-spacing subview \(index) should be placed")
            continue
        }
        guard let explicitPlacement = explicitZeroSpacing.subviews[index].placement else {
            #expect(Bool(false), "\(scenario.name) explicit-zero subview \(index) should be placed")
            continue
        }
        expectApproximatelyEqual(
            nilPlacement.position,
            explicitPlacement.position,
            "\(scenario.name) subview \(index) origin"
        )
        expectApproximatelyEqual(
            nilPlacement.size,
            explicitPlacement.size,
            "\(scenario.name) subview \(index) size"
        )
    }
}

private func assertVisibleFramesDoNotOverlapWhenSpacingIsNonNegative(_ scenario: FlowInvariantCase) {
    let result = scenario.layoutThatFits()
    let visibleFrames = result.subviews.enumerated().compactMap { index, subview -> (index: Int, frame: CGRect)? in
        guard let placement = subview.placement else {
            return nil
        }
        let frame = CGRect(origin: placement.position, size: placement.size)
        return frame.width > 0 && frame.height > 0 ? (index, frame) : nil
    }

    for (previousIndex, previous) in visibleFrames.enumerated() {
        for next in visibleFrames.dropFirst(previousIndex + 1) {
            let overlapWidth = min(previous.frame.maxX, next.frame.maxX) - max(previous.frame.minX, next.frame.minX)
            let overlapHeight = min(previous.frame.maxY, next.frame.maxY) - max(previous.frame.minY, next.frame.minY)
            #expect(
                overlapWidth <= tolerance || overlapHeight <= tolerance,
                "\(scenario.name) visible subviews \(previous.index) and \(next.index) should not overlap with non-negative spacing"
            )
        }
    }
}

private enum GeneratedAxisAlignment: CaseIterable, Sendable, CustomStringConvertible {
    case start
    case center
    case end

    var horizontal: HorizontalAlignment {
        switch self {
            case .start: .leading
            case .center: .center
            case .end: .trailing
        }
    }

    var vertical: VerticalAlignment {
        switch self {
            case .start: .top
            case .center: .center
            case .end: .bottom
        }
    }

    var description: String {
        switch self {
            case .start: "start"
            case .center: "center"
            case .end: "end"
        }
    }
}

private enum GeneratedFlexibility: CaseIterable, Sendable, CustomStringConvertible {
    case minimum
    case natural
    case maximum

    var behavior: FlexibilityBehavior {
        switch self {
            case .minimum: .minimum
            case .natural: .natural
            case .maximum: .maximum
        }
    }

    var description: String {
        switch self {
            case .minimum: "minimum"
            case .natural: "natural"
            case .maximum: "maximum"
        }
    }
}

private enum GeneratedSubviewControl: Sendable, CustomStringConvertible {
    case normal
    case lineBreak
    case startsNewLine

    var description: String {
        switch self {
            case .normal: "normal"
            case .lineBreak: "lineBreak"
            case .startsNewLine: "startsNewLine"
        }
    }
}

private enum GeneratedSubviewSpacing: Sendable, CustomStringConvertible {
    case `default`
    case zero

    func apply(to subview: TestSubview) {
        switch self {
            case .default:
                break
            case .zero:
                subview.spacing = .zero
        }
    }

    var description: String {
        switch self {
            case .default: "default"
            case .zero: "zero"
        }
    }
}

private struct GeneratedLayoutSpec: Sendable, CustomStringConvertible {
    let breadthAlignment: GeneratedAxisAlignment
    let depthAlignment: GeneratedAxisAlignment
    let itemSpacing: Int
    let lineSpacing: Int
    let justified: Bool
    let distributeItemsEvenly: Bool

    func layout(orientation: FlowInvariantOrientation) -> FlowLayout {
        switch orientation {
            case .horizontal:
                .horizontal(
                    horizontalAlignment: breadthAlignment.horizontal,
                    verticalAlignment: depthAlignment.vertical,
                    horizontalSpacing: CGFloat(itemSpacing),
                    verticalSpacing: CGFloat(lineSpacing),
                    justified: justified,
                    distributeItemsEvenly: distributeItemsEvenly
                )
            case .vertical:
                .vertical(
                    horizontalAlignment: depthAlignment.horizontal,
                    verticalAlignment: breadthAlignment.vertical,
                    horizontalSpacing: CGFloat(lineSpacing),
                    verticalSpacing: CGFloat(itemSpacing),
                    justified: justified,
                    distributeItemsEvenly: distributeItemsEvenly
                )
        }
    }

    var description: String {
        "align:\(breadthAlignment)/\(depthAlignment) spacing:\(itemSpacing)/\(lineSpacing) mode:\(modeDescription)"
    }

    private var modeDescription: String {
        switch (justified, distributeItemsEvenly) {
            case (false, false): "default"
            case (true, false): "justified"
            case (false, true): "distributed"
            case (true, true): "justified+distributed"
        }
    }
}

private struct GeneratedSubviewSpec: Sendable, CustomStringConvertible {
    let minBreadth: Int
    let idealBreadth: Int
    let maxBreadth: Int
    let minDepth: Int
    let idealDepth: Int
    let maxDepth: Int
    let priority: Int
    let flexibility: GeneratedFlexibility
    let control: GeneratedSubviewControl
    var spacing: GeneratedSubviewSpacing = .default

    func makeSubview(orientation: FlowInvariantOrientation) -> TestSubview {
        guard control != .lineBreak else {
            return testLineBreakSubview()
        }

        let subview = TestSubview(
            minSize: orientation.size(breadth: CGFloat(minBreadth), depth: CGFloat(minDepth)),
            idealSize: orientation.size(breadth: CGFloat(idealBreadth), depth: CGFloat(idealDepth)),
            maxSize: orientation.size(breadth: CGFloat(maxBreadth), depth: CGFloat(maxDepth))
        )
        subview.priority = Double(priority)
        subview[FlexibilityLayoutValueKey.self] = flexibility.behavior
        if control == .startsNewLine {
            subview[ShouldStartInNewLineLayoutValueKey.self] = true
        }
        spacing.apply(to: subview)
        return subview
    }

    var description: String {
        "\(control) b:\(minBreadth)-\(idealBreadth)-\(maxBreadth) d:\(minDepth)-\(idealDepth)-\(maxDepth) p:\(priority) flex:\(flexibility) spacing:\(spacing)"
    }
}

private struct GeneratedInvariantSpec: Sendable, CustomStringConvertible {
    let category: GeneratedScenarioCategory
    let orientation: FlowInvariantOrientation
    let layout: GeneratedLayoutSpec
    let subviews: [GeneratedSubviewSpec]
    let proposalBreadth: Int
    let proposalDepth: Int

    func makeCase() -> FlowInvariantCase {
        FlowInvariantCase(
            name: "generated \(category) \(description)",
            orientation: orientation,
            layout: layout.layout(orientation: orientation),
            subviews: subviews.map { $0.makeSubview(orientation: orientation) },
            proposal: orientation.proposal(breadth: CGFloat(proposalBreadth), depth: CGFloat(proposalDepth))
        )
    }

    var description: String {
        "\(orientation) proposal:\(proposalBreadth)×\(proposalDepth) \(layout) subviews:\(subviews)"
    }
}

private struct GeneratedTransposeSpec: Sendable, CustomStringConvertible {
    let layout: GeneratedLayoutSpec
    let subviews: [GeneratedSubviewSpec]
    let proposalBreadth: Int
    let proposalDepth: Int

    func makeCase() -> TransposeCase {
        TransposeCase(
            name: "generated \(GeneratedScenarioCategory.transpose) \(description)",
            horizontal: FlowInvariantCase(
                name: "generated \(GeneratedScenarioCategory.transpose) HFlow \(description)",
                orientation: .horizontal,
                layout: layout.layout(orientation: .horizontal),
                subviews: subviews.map { $0.makeSubview(orientation: .horizontal) },
                proposal: FlowInvariantOrientation.horizontal.proposal(
                    breadth: CGFloat(proposalBreadth),
                    depth: CGFloat(proposalDepth)
                )
            ),
            vertical: FlowInvariantCase(
                name: "generated \(GeneratedScenarioCategory.transpose) VFlow \(description)",
                orientation: .vertical,
                layout: layout.layout(orientation: .vertical),
                subviews: subviews.map { $0.makeSubview(orientation: .vertical) },
                proposal: FlowInvariantOrientation.vertical.proposal(
                    breadth: CGFloat(proposalBreadth),
                    depth: CGFloat(proposalDepth)
                )
            )
        )
    }

    var description: String {
        "proposal:\(proposalBreadth)×\(proposalDepth) \(layout) subviews:\(subviews)"
    }
}

private struct GeneratedMonotonicSpec: Sendable, CustomStringConvertible {
    let orientation: FlowInvariantOrientation
    let breadthAlignment: GeneratedAxisAlignment
    let depthAlignment: GeneratedAxisAlignment
    let itemSpacing: Int
    let lineSpacing: Int
    let subviews: [GeneratedSubviewSpec]
    let smallerProposalBreadth: Int
    let largerProposalBreadthExtra: Int
    let proposalDepth: Int

    func makeCase() -> MonotonicProposalCase {
        let largerProposalBreadth = smallerProposalBreadth + largerProposalBreadthExtra
        return MonotonicProposalCase(
            name: "generated \(GeneratedScenarioCategory.monotonic) \(description)",
            orientation: orientation,
            smaller: makeCase(proposalBreadth: smallerProposalBreadth),
            larger: makeCase(proposalBreadth: largerProposalBreadth)
        )
    }

    private func makeCase(proposalBreadth: Int) -> FlowInvariantCase {
        FlowInvariantCase(
            name: "generated \(GeneratedScenarioCategory.monotonic) \(orientation) proposal:\(proposalBreadth)×\(proposalDepth)",
            orientation: orientation,
            layout: layout,
            subviews: subviews.map { $0.makeSubview(orientation: orientation) },
            proposal: orientation.proposal(breadth: CGFloat(proposalBreadth), depth: CGFloat(proposalDepth))
        )
    }

    private var layout: FlowLayout {
        switch orientation {
            case .horizontal:
                .horizontal(
                    horizontalAlignment: breadthAlignment.horizontal,
                    verticalAlignment: depthAlignment.vertical,
                    horizontalSpacing: CGFloat(itemSpacing),
                    verticalSpacing: CGFloat(lineSpacing)
                )
            case .vertical:
                .vertical(
                    horizontalAlignment: depthAlignment.horizontal,
                    verticalAlignment: breadthAlignment.vertical,
                    horizontalSpacing: CGFloat(lineSpacing),
                    verticalSpacing: CGFloat(itemSpacing)
                )
        }
    }

    var description: String {
        "\(orientation) proposal:\(smallerProposalBreadth)-\(smallerProposalBreadth + largerProposalBreadthExtra)×\(proposalDepth) align:\(breadthAlignment)/\(depthAlignment) spacing:\(itemSpacing)/\(lineSpacing) subviews:\(subviews)"
    }
}

private struct GeneratedFractionalSubviewSpec: Sendable, CustomStringConvertible {
    let breadth: CGFloat
    let depth: CGFloat

    func makeSubview(orientation: FlowInvariantOrientation) -> TestSubview {
        TestSubview(size: orientation.size(breadth: breadth, depth: depth))
    }

    var description: String {
        "rigid b:\(breadth) d:\(depth)"
    }
}

private struct GeneratedFractionalSpec: Sendable, CustomStringConvertible {
    let orientation: FlowInvariantOrientation
    let breadthAlignment: GeneratedAxisAlignment
    let depthAlignment: GeneratedAxisAlignment
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat
    let subviews: [GeneratedFractionalSubviewSpec]
    let proposalBreadth: CGFloat
    let proposalDepth: CGFloat

    func makeCase() -> FlowInvariantCase {
        FlowInvariantCase(
            name: "generated edge fractional \(description)",
            orientation: orientation,
            layout: layout,
            subviews: subviews.map { $0.makeSubview(orientation: orientation) },
            proposal: orientation.proposal(breadth: proposalBreadth, depth: proposalDepth)
        )
    }

    private var layout: FlowLayout {
        switch orientation {
            case .horizontal:
                .horizontal(
                    horizontalAlignment: breadthAlignment.horizontal,
                    verticalAlignment: depthAlignment.vertical,
                    horizontalSpacing: itemSpacing,
                    verticalSpacing: lineSpacing
                )
            case .vertical:
                .vertical(
                    horizontalAlignment: depthAlignment.horizontal,
                    verticalAlignment: breadthAlignment.vertical,
                    horizontalSpacing: lineSpacing,
                    verticalSpacing: itemSpacing
                )
        }
    }

    var description: String {
        "\(orientation) proposal:\(proposalBreadth)×\(proposalDepth) align:\(breadthAlignment)/\(depthAlignment) spacing:\(itemSpacing)/\(lineSpacing) subviews:\(subviews)"
    }
}

private struct GeneratedSpacingFallbackSpec: Sendable, CustomStringConvertible {
    let orientation: FlowInvariantOrientation
    let breadthAlignment: GeneratedAxisAlignment
    let depthAlignment: GeneratedAxisAlignment
    let subviews: [GeneratedSubviewSpec]
    let proposalBreadth: Int
    let proposalDepth: Int

    func makeCase() -> SpacingFallbackCase {
        SpacingFallbackCase(
            name: "generated \(GeneratedScenarioCategory.spacingFallback) \(description)",
            nilSpacing: makeCase(itemSpacing: nil, lineSpacing: nil),
            explicitZeroSpacing: makeCase(itemSpacing: 0, lineSpacing: 0)
        )
    }

    private func makeCase(itemSpacing: CGFloat?, lineSpacing: CGFloat?) -> FlowInvariantCase {
        FlowInvariantCase(
            name: "generated \(GeneratedScenarioCategory.spacingFallback) \(orientation)",
            orientation: orientation,
            layout: layout(itemSpacing: itemSpacing, lineSpacing: lineSpacing),
            subviews: subviews.map { $0.makeSubview(orientation: orientation) },
            proposal: orientation.proposal(breadth: CGFloat(proposalBreadth), depth: CGFloat(proposalDepth))
        )
    }

    private func layout(itemSpacing: CGFloat?, lineSpacing: CGFloat?) -> FlowLayout {
        switch orientation {
            case .horizontal:
                .horizontal(
                    horizontalAlignment: breadthAlignment.horizontal,
                    verticalAlignment: depthAlignment.vertical,
                    horizontalSpacing: itemSpacing,
                    verticalSpacing: lineSpacing
                )
            case .vertical:
                .vertical(
                    horizontalAlignment: depthAlignment.horizontal,
                    verticalAlignment: breadthAlignment.vertical,
                    horizontalSpacing: lineSpacing,
                    verticalSpacing: itemSpacing
                )
        }
    }

    var description: String {
        "\(orientation) proposal:\(proposalBreadth)×\(proposalDepth) align:\(breadthAlignment)/\(depthAlignment) subviews:\(subviews)"
    }
}

private let generatedAxisAlignment = Gen<GeneratedAxisAlignment>.case
private let generatedFlexibility = Gen<GeneratedFlexibility>.case
private let generatedSubviewControl = Gen.int(in: 0 ..< 10)
    .map { i -> GeneratedSubviewControl in
        switch i {
            case 8: .lineBreak
            case 9: .startsNewLine
            default: .normal
        }
    }

private let generatedLayoutSpec = zip(
    generatedAxisAlignment,
    generatedAxisAlignment,
    Gen.int(in: -1 ... 4),
    Gen.int(in: 0 ... 4),
    Gen.bool(0.25),
    Gen.bool(0.25)
)
.map { input in
    let (breadthAlignment, depthAlignment, itemSpacing, lineSpacing, justified, distributeItemsEvenly) = input
    return GeneratedLayoutSpec(
        breadthAlignment: breadthAlignment,
        depthAlignment: depthAlignment,
        itemSpacing: itemSpacing,
        lineSpacing: lineSpacing,
        justified: justified,
        distributeItemsEvenly: distributeItemsEvenly
    )
}

private let generatedCommonLayoutSpec = zip(
    generatedAxisAlignment,
    generatedAxisAlignment,
    Gen.int(in: 0 ... 4),
    Gen.int(in: 0 ... 4)
)
.map { input in
    let (breadthAlignment, depthAlignment, itemSpacing, lineSpacing) = input
    return GeneratedLayoutSpec(
        breadthAlignment: breadthAlignment,
        depthAlignment: depthAlignment,
        itemSpacing: itemSpacing,
        lineSpacing: lineSpacing,
        justified: false,
        distributeItemsEvenly: false
    )
}

private let generatedSubviewSpec = zip(
    Gen.int(in: 1 ... 8),
    Gen.int(in: 0 ... 4),
    Gen.int(in: 0 ... 6),
    Gen.int(in: 1 ... 6),
    Gen.int(in: 0 ... 3),
    Gen.int(in: 0 ... 3),
    Gen.int(in: 0 ... 2),
    generatedFlexibility,
    generatedSubviewControl
)
.map { input in
    let (
        minBreadth,
        idealBreadthExtra,
        maxBreadthExtra,
        minDepth,
        idealDepthExtra,
        maxDepthExtra,
        priority,
        flexibility,
        control
    ) = input

    let idealBreadth = minBreadth + idealBreadthExtra
    let idealDepth = minDepth + idealDepthExtra
    return GeneratedSubviewSpec(
        minBreadth: minBreadth,
        idealBreadth: idealBreadth,
        maxBreadth: idealBreadth + maxBreadthExtra,
        minDepth: minDepth,
        idealDepth: idealDepth,
        maxDepth: idealDepth + maxDepthExtra,
        priority: priority,
        flexibility: flexibility,
        control: control
    )
}

private let generatedCommonSubviewSpec = zip(
    Gen.int(in: 1 ... 8),
    Gen.int(in: 0 ... 4),
    Gen.int(in: 0 ... 4),
    Gen.int(in: 1 ... 6),
    Gen.int(in: 0 ... 3),
    Gen.int(in: 0 ... 3)
)
.map { input in
    let (
        minBreadth,
        idealBreadthExtra,
        maxBreadthExtra,
        minDepth,
        idealDepthExtra,
        maxDepthExtra
    ) = input

    let idealBreadth = minBreadth + idealBreadthExtra
    let idealDepth = minDepth + idealDepthExtra
    return GeneratedSubviewSpec(
        minBreadth: minBreadth,
        idealBreadth: idealBreadth,
        maxBreadth: idealBreadth + maxBreadthExtra,
        minDepth: minDepth,
        idealDepth: idealDepth,
        maxDepth: idealDepth + maxDepthExtra,
        priority: 0,
        flexibility: .natural,
        control: .normal
    )
}

private let generatedRigidSubviewSpec = zip(
    Gen.int(in: 1 ... 8),
    Gen.int(in: 1 ... 6)
)
.map { input in
    let (breadth, depth) = input
    return GeneratedSubviewSpec(
        minBreadth: breadth,
        idealBreadth: breadth,
        maxBreadth: breadth,
        minDepth: depth,
        idealDepth: depth,
        maxDepth: depth,
        priority: 0,
        flexibility: .natural,
        control: .normal
    )
}

private let generatedZeroSpacedSubviewSpec = zip(
    Gen.int(in: 1 ... 8),
    Gen.int(in: 1 ... 6)
)
.map { input in
    let (breadth, depth) = input
    return GeneratedSubviewSpec(
        minBreadth: breadth,
        idealBreadth: breadth,
        maxBreadth: breadth,
        minDepth: depth,
        idealDepth: depth,
        maxDepth: depth,
        priority: 0,
        flexibility: .natural,
        control: .normal,
        spacing: .zero
    )
}

private let generatedQuarterStep = Gen.int(in: 1 ... 32).map { CGFloat($0) / 4 }
private let generatedFractionalSpacing = Gen.int(in: 0 ... 8).map { CGFloat($0) / 4 }

private let generatedFractionalSubviewSpec = zip(
    generatedQuarterStep,
    generatedQuarterStep
)
.map { input in
    let (breadth, depth) = input
    return GeneratedFractionalSubviewSpec(breadth: breadth, depth: depth)
}

private let generatedCommonInvariantCase = zip(
    Gen<FlowInvariantOrientation>.case,
    generatedCommonLayoutSpec,
    generatedCommonSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 12 ... 30),
    Gen.int(in: 4 ... 24)
)
.map { input in
    let (orientation, layout, subviews, proposalBreadth, proposalDepth) = input
    return GeneratedInvariantSpec(
        category: .common,
        orientation: orientation,
        layout: layout,
        subviews: subviews,
        proposalBreadth: proposalBreadth,
        proposalDepth: proposalDepth
    )
}

private let generatedEdgeInvariantCase = zip(
    Gen<FlowInvariantOrientation>.case,
    generatedLayoutSpec,
    generatedSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 12 ... 30),
    Gen.int(in: 4 ... 24)
)
.map { input in
    let (orientation, layout, subviews, proposalBreadth, proposalDepth) = input
    return GeneratedInvariantSpec(
        category: .edge,
        orientation: orientation,
        layout: layout,
        subviews: subviews,
        proposalBreadth: proposalBreadth,
        proposalDepth: proposalDepth
    )
}

private let generatedFractionalInvariantCase = zip(
    Gen<FlowInvariantOrientation>.case,
    generatedAxisAlignment,
    generatedAxisAlignment,
    generatedFractionalSpacing,
    generatedFractionalSpacing,
    generatedFractionalSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 16 ... 120),
    Gen.int(in: 16 ... 96)
)
.map { input in
    let (
        orientation,
        breadthAlignment,
        depthAlignment,
        itemSpacing,
        lineSpacing,
        subviews,
        proposalBreadthUnits,
        proposalDepthUnits
    ) = input
    return GeneratedFractionalSpec(
        orientation: orientation,
        breadthAlignment: breadthAlignment,
        depthAlignment: depthAlignment,
        itemSpacing: itemSpacing,
        lineSpacing: lineSpacing,
        subviews: subviews,
        proposalBreadth: CGFloat(proposalBreadthUnits) / 4,
        proposalDepth: CGFloat(proposalDepthUnits) / 4
    )
}

private let generatedSpacingFallbackCase = zip(
    Gen<FlowInvariantOrientation>.case,
    generatedAxisAlignment,
    generatedAxisAlignment,
    generatedZeroSpacedSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 12 ... 30),
    Gen.int(in: 4 ... 24)
)
.map { input in
    let (orientation, breadthAlignment, depthAlignment, subviews, proposalBreadth, proposalDepth) = input
    return GeneratedSpacingFallbackSpec(
        orientation: orientation,
        breadthAlignment: breadthAlignment,
        depthAlignment: depthAlignment,
        subviews: subviews,
        proposalBreadth: proposalBreadth,
        proposalDepth: proposalDepth
    )
}

private let generatedTransposeCase = zip(
    generatedLayoutSpec,
    generatedSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 12 ... 30),
    Gen.int(in: 4 ... 24)
)
.map { input in
    let (layout, subviews, proposalBreadth, proposalDepth) = input
    return GeneratedTransposeSpec(
        layout: layout,
        subviews: subviews,
        proposalBreadth: proposalBreadth,
        proposalDepth: proposalDepth
    )
}

private let generatedMonotonicCase = zip(
    Gen<FlowInvariantOrientation>.case,
    generatedAxisAlignment,
    generatedAxisAlignment,
    Gen.int(in: 0 ... 4),
    Gen.int(in: 0 ... 4),
    generatedRigidSubviewSpec.array(of: 1 ... 8),
    Gen.int(in: 6 ... 20),
    Gen.int(in: 1 ... 12),
    Gen.int(in: 4 ... 24)
)
.map { input in
    let (
        orientation,
        breadthAlignment,
        depthAlignment,
        itemSpacing,
        lineSpacing,
        subviews,
        smallerProposalBreadth,
        largerProposalBreadthExtra,
        proposalDepth
    ) = input
    return GeneratedMonotonicSpec(
        orientation: orientation,
        breadthAlignment: breadthAlignment,
        depthAlignment: depthAlignment,
        itemSpacing: itemSpacing,
        lineSpacing: lineSpacing,
        subviews: subviews,
        smallerProposalBreadth: smallerProposalBreadth,
        largerProposalBreadthExtra: largerProposalBreadthExtra,
        proposalDepth: proposalDepth
    )
}

private func invariantCases() -> [FlowInvariantCase] {
    [
        FlowInvariantCase(
            name: "HFlow basic wrap",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 2),
            subviews: [2 × 1, 3 × 2, 1 × 1, 4 × 1],
            proposal: 6 × 10
        ),
        FlowInvariantCase(
            name: "VFlow basic wrap",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 2, verticalSpacing: 1),
            subviews: [1 × 2, 2 × 3, 1 × 1, 1 × 4],
            proposal: 10 × 6
        ),
        FlowInvariantCase(
            name: "HFlow aligned final row",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .center, verticalAlignment: .bottom, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 3, 1 × 1, 2 × 2, 1 × 1],
            proposal: 5 × 10
        ),
        FlowInvariantCase(
            name: "VFlow aligned final column",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .trailing, verticalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 3, 1 × 1, 2 × 2, 1 × 1],
            proposal: 10 × 5
        ),
        FlowInvariantCase(
            name: "HFlow justified",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [2 × 1, 2 × 1, 2 × 1, 3 × 1],
            proposal: 8 × 3
        ),
        FlowInvariantCase(
            name: "VFlow justified",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: [1 × 2, 1 × 2, 1 × 2, 1 × 3],
            proposal: 3 × 8
        ),
        FlowInvariantCase(
            name: "HFlow distributed",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: repeated(1 × 1, times: 9),
            proposal: 7 × 4
        ),
        FlowInvariantCase(
            name: "VFlow distributed",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true),
            subviews: repeated(1 × 1, times: 9),
            proposal: 4 × 7
        ),
        FlowInvariantCase(
            name: "HFlow flexible",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [2 × 1, 1 × 1 ... 4 × 1, 2 × 1, (1 × 1 ... 5 × 1).flexibility(.maximum)],
            proposal: 8 × 4
        ),
        FlowInvariantCase(
            name: "VFlow flexible",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 2, 1 × 1 ... 1 × 4, 1 × 2, (1 × 1 ... 1 × 5).flexibility(.maximum)],
            proposal: 4 × 8
        ),
        FlowInvariantCase(
            name: "HFlow line break marker",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, testLineBreakSubview(), 3 × 1, 1 × 1],
            proposal: 6 × 4
        ),
        FlowInvariantCase(
            name: "VFlow line break marker",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 3, testLineBreakSubview(), 1 × 3, 1 × 1],
            proposal: 4 × 6
        ),
        FlowInvariantCase(
            name: "HFlow negative spacing",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: -2, verticalSpacing: 0),
            subviews: [5 × 3, 5 × 3, 5 × 3],
            proposal: 100 × 100
        ),
        FlowInvariantCase(
            name: "VFlow negative spacing",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: -2),
            subviews: [3 × 5, 3 × 5, 3 × 5],
            proposal: 100 × 100
        ),
        FlowInvariantCase(
            name: "HFlow oversized item",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 1, 12 × 2, 3 × 1],
            proposal: 10 × 10
        ),
        FlowInvariantCase(
            name: "VFlow oversized item",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [1 × 3, 2 × 12, 1 × 3],
            proposal: 10 × 10
        ),
        FlowInvariantCase(
            name: "HFlow mixed zero-size subview",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, TestSubview(size: .zero), 3 × 1],
            proposal: 10 × 2
        ),
        FlowInvariantCase(
            name: "HFlow unbounded proposal with finite bounds",
            orientation: .horizontal,
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [4 × 1, 4 × 1, 4 × 1],
            proposal: ProposedViewSize(width: nil, height: 2),
            bounds: CGRect(origin: .zero, size: 8 × 2)
        ),
        FlowInvariantCase(
            name: "VFlow unbounded proposal with finite bounds",
            orientation: .vertical,
            layout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 4, 1 × 4, 1 × 4],
            proposal: ProposedViewSize(width: 2, height: nil),
            bounds: CGRect(origin: .zero, size: 2 × 8)
        ),
    ]
}

private func transposeCases() -> [TransposeCase] {
    [
        transposeCase(
            name: "basic wrap",
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 2),
            transposedLayout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 2, verticalSpacing: 1),
            subviews: [2 × 1, 3 × 2, 1 × 1, 4 × 1],
            proposal: 6 × 10
        ),
        transposeCase(
            name: "line break marker",
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 2),
            transposedLayout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 2, verticalSpacing: 1),
            subviews: [2 × 1, testLineBreakSubview(), 3 × 1, 1 × 1],
            proposal: 5 × 6
        ),
        transposeCase(
            name: "justified rigid line",
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            transposedLayout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 8 × 3
        ),
        transposeCase(
            name: "distributed items",
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            transposedLayout: .vertical(
                horizontalAlignment: .leading,
                verticalAlignment: .top,
                horizontalSpacing: 0,
                verticalSpacing: 1,
                distributeItemsEvenly: true
            ),
            subviews: repeated(1 × 1, times: 7),
            proposal: 5 × 3
        ),
        transposeCase(
            name: "natural flexibility",
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0),
            transposedLayout: .vertical(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [2 × 1, 1 × 1 ... 4 × 1, 2 × 1],
            proposal: 8 × 3
        ),
    ]
}

private func transposeCase(
    name: String,
    layout: FlowLayout,
    transposedLayout: FlowLayout,
    subviews: [TestSubview],
    proposal: ProposedViewSize
) -> TransposeCase {
    TransposeCase(
        name: name,
        horizontal: FlowInvariantCase(
            name: "HFlow transpose \(name)",
            orientation: .horizontal,
            layout: layout,
            subviews: subviews,
            proposal: proposal
        ),
        vertical: FlowInvariantCase(
            name: "VFlow transpose \(name)",
            orientation: .vertical,
            layout: transposedLayout,
            subviews: subviews.map(transposedSubview),
            proposal: transpose(proposal)
        )
    )
}

private func transposedSubview(_ subview: TestSubview) -> TestSubview {
    let transposed = TestSubview(
        minSize: transpose(subview.minSize),
        idealSize: transpose(subview.idealSize),
        maxSize: transpose(subview.maxSize)
    )
    transposed.priority = subview.priority
    transposed.spacing = subview.spacing
    transposed[FlexibilityLayoutValueKey.self] = subview[FlexibilityLayoutValueKey.self]
    transposed[IsLineBreakLayoutValueKey.self] = subview[IsLineBreakLayoutValueKey.self]
    transposed[ShouldStartInNewLineLayoutValueKey.self] = subview[ShouldStartInNewLineLayoutValueKey.self]
    return transposed
}

private func transpose(_ proposal: ProposedViewSize) -> ProposedViewSize {
    ProposedViewSize(width: proposal.height, height: proposal.width)
}

private func transpose(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.y, y: point.x)
}

private func transpose(_ size: CGSize) -> CGSize {
    CGSize(width: size.height, height: size.width)
}

private func expectFinite(_ value: CGFloat, _ message: String) {
    #expect(value.isFinite, "\(message) should be finite")
}

private func expectApproximatelyEqual(_ actual: CGPoint, _ expected: CGPoint, _ message: String) {
    expectApproximatelyEqual(actual.x, expected.x, "\(message) x")
    expectApproximatelyEqual(actual.y, expected.y, "\(message) y")
}

private func expectApproximatelyEqual(_ actual: CGSize, _ expected: CGSize, _ message: String) {
    expectApproximatelyEqual(actual.width, expected.width, "\(message) width")
    expectApproximatelyEqual(actual.height, expected.height, "\(message) height")
}

private func expectApproximatelyEqual(_ actual: CGFloat, _ expected: CGFloat, _ message: String) {
    #expect(abs(actual - expected) <= tolerance, "\(message): expected \(expected), got \(actual)")
}
