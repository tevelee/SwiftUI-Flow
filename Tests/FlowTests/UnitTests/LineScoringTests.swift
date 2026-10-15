import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements, .regression))
struct LineScoringTests {
    @Test func growingCandidates_scoreTheSizesThatWillBePlaced() throws {
        // Compare the incremental scorer with full line sizing, which independently sorts each
        // candidate. Nonzero starts, skipped prefixes, ties and late priorities exercise reuse.
        // NaN priorities use the old unordered dictionary fallback, whose order can vary per call.
        let fixtures: [[MeasuredItem]] = [
            [
                .init(size: 0.1 ... 9.1, spacing: 0, priority: 0),
                .init(size: 2 ... 5, spacing: 0.3, priority: 2),
                .init(size: 4 ... 13, spacing: -0.1, priority: 1),
                .init(size: 1 ... 8, spacing: 0.2, priority: 2),
                .init(size: 0 ... 2, spacing: 0, priority: 3),
            ],
            [
                .init(size: 1e16 ... (1e16 + 8), spacing: 0, priority: 2),
                .init(size: 0 ... 8, spacing: 0, priority: 2),
                .init(size: 1 ... 9, spacing: 0, priority: 2),
                .init(size: 2 ... 3, spacing: 0, priority: 3),
            ],
        ]
        for items in fixtures {
            for breadth: CGFloat in [17, 100, 1e16 + 20] {
                let sizer = LineSizer(availableSpace: breadth)
                for start in items.indices {
                    for step in [1, 2] {
                        var workspace = LineSizingWorkspace()
                        for end in stride(from: start + 1, through: items.count, by: step) {
                            let candidate = items[start ..< end]
                            guard let remaining = sizer.remainingSpace(for: candidate) else { continue }
                            let placed = try #require(sizer.sizes(of: candidate))
                            let expected: CGFloat = zip(candidate, placed.items).reduce(0) { total, pair in
                                let growth = pair.1.size - pair.0.size.lowerBound
                                return total + growth * growth
                            }
                            let score = sizer.metrics(of: candidate, remainingSpace: remaining, workspace: &workspace)
                            #expect(score.remainingSpace == placed.remainingSpace)
                            #expect(score.squaredGrowth == expected)
                        }
                    }
                }
            }
        }
    }
}
