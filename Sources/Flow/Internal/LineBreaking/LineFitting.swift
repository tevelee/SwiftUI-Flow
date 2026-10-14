import CoreFoundation

/// Incremental feasibility for a candidate line. Natural/minimum items take constant work per
/// append; `.maximum` demands are checked in order against the candidate's remaining space.
/// Shared by streaming greedy wrapping and full candidate sizing so their fit rules cannot drift.
@usableFromInline
struct LineFitter {
    private let availableSpace: CGFloat
    // Keep sizes and spacing separate to preserve the batch sizer's floating-point addition order.
    private var minimumSize: CGFloat = 0
    private var spacing: CGFloat = 0
    private var count = 0
    private var startsWithBreak = false
    private var hasStructuralViolation = false
    private var maximumGrowth: [CGFloat] = []

    @usableFromInline
    init(availableSpace: CGFloat) {
        self.availableSpace = availableSpace
    }

    @usableFromInline
    mutating func append(_ item: MeasuredItem) {
        if count == 0 {
            startsWithBreak = item.isLineBreakView
        } else {
            hasStructuralViolation = hasStructuralViolation || item.isLineBreakView || item.shouldStartInNewLine
            spacing += startsWithBreak && count == 1 ? 0 : item.spacing
        }
        minimumSize += item.size.lowerBound
        if item.flexibility == .maximum {
            let size = max(item.size.lowerBound, min(availableSpace, item.size.upperBound))
            maximumGrowth.append(size - item.size.lowerBound)
        }
        count += 1
    }

    /// The undistributed space when the candidate fits, or `nil` for an empty/invalid candidate.
    @usableFromInline
    var remainingSpace: CGFloat? {
        guard count > 0, !hasStructuralViolation else { return nil }
        let totalMinimumSize = minimumSize + spacing
        let tolerance = max(totalMinimumSize.magnitude, availableSpace.magnitude, 1) * CGFloat.ulpOfOne
        guard totalMinimumSize <= availableSpace + tolerance else { return nil }

        let remaining = max(0, availableSpace - totalMinimumSize)
        var remainingForMaximumItems = remaining
        // Subtract in encounter order rather than summing demands: that preserves fit decisions
        // at floating-point boundaries, including cumulative `.maximum` growth.
        for growth in maximumGrowth {
            if growth > remainingForMaximumItems { return nil }
            remainingForMaximumItems -= growth
        }
        return remaining
    }
}
