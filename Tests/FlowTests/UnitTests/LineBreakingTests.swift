import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct LineBreakingTests {
    @Suite("GreedyLineBreaker")
    struct GreedyLineBreakerTests {

        @Test func basic() {
            let sut = GreedyLineBreaker()
            let breakpoints = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(10), spacing: 10),
                    .init(size: .rigid(20), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                    .init(size: .rigid(40), spacing: 10),
                    .init(size: .rigid(20), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                ],
                in: 80
            )
            #expect(
                breakpoints == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
                    [.init(index: 3, size: 40, leadingSpace: 0), .init(index: 4, size: 20, leadingSpace: 10)],
                    [.init(index: 5, size: 30, leadingSpace: 0)],
                ]
            )
        }

        @Test func emptyInput() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(items: [], in: 100)
            #expect(result.isEmpty)
        }

        @Test func singleItem() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(50), spacing: 0)
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 50, leadingSpace: 0)]
                ]
            )
        }

        @Test func allFitOnOneLine() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(30), spacing: 10),
                    .init(size: .rigid(20), spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0), .init(index: 1, size: 30, leadingSpace: 10), .init(index: 2, size: 20, leadingSpace: 10)]
                ]
            )
        }

        @Test func eachItemOwnLine() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(100), spacing: 0),
                    .init(size: .rigid(100), spacing: 10),
                    .init(size: .rigid(100), spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 100, leadingSpace: 0)],
                    [.init(index: 1, size: 100, leadingSpace: 0)],
                    [.init(index: 2, size: 100, leadingSpace: 0)],
                ]
            )
        }

        @Test func flexibleItem_expands() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: 20 ... 60, spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 30, leadingSpace: 0), .init(index: 1, size: 60, leadingSpace: 10)]
                ]
            )
        }

        @Test func lineBreakView() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(0), spacing: 0, isLineBreakView: true),
                    .init(size: .rigid(20), spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0)],
                    [.init(index: 1, size: 0, leadingSpace: 0), .init(index: 2, size: 20, leadingSpace: 0)],
                ]
            )
        }

        @Test func lineBreakAtStart_clearsFollowingSpacing() {
            assertLineBreakAtStartClearsFollowingSpacing(GreedyLineBreaker())
        }

        @Test func shouldStartInNewLine() {
            let sut = GreedyLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(20), spacing: 10),
                    .init(size: .rigid(20), spacing: 10, shouldStartInNewLine: true),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10)],
                    [.init(index: 2, size: 20, leadingSpace: 0)],
                ]
            )
        }

        @Test func shouldStartInNewLineAtFirstItem_allowsFollowingItemsOnSameLine() {
            assertShouldStartInNewLineAtFirstItemAllowsFollowingItemsOnSameLine(GreedyLineBreaker())
        }

        @Test func negativeSpacing_keepsOverlappingRigidItemsOnOneLine() {
            assertNegativeSpacingKeepsOverlappingRigidItemsOnOneLine(GreedyLineBreaker())
        }

        @Test func zeroSizedItem_staysOnLineAndKeepsSpacing() {
            assertZeroSizedItemStaysOnLineAndKeepsSpacing(GreedyLineBreaker())
        }

        @Test func negativeAvailableSpace_fallsBackToOneItemPerLine() {
            assertNegativeAvailableSpaceFallsBackToOneItemPerLine(GreedyLineBreaker())
        }

        @Test func maximumFlexItem_movesToOwnLineWhenFullGrowthDoesNotFit() {
            assertMaximumFlexItemMovesToOwnLineWhenFullGrowthDoesNotFit(GreedyLineBreaker())
        }

        @Test func oversizedItem_placedAlone() {
            let sut = GreedyLineBreaker()
            // Item (150) wider than the container (100) must still appear on its own line.
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(150), spacing: 0)
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 150, leadingSpace: 0)]
                ]
            )
        }

        @Test func oversizedItem_doesNotDropNeighbours() {
            let sut = GreedyLineBreaker()
            // [A=30, B=150(overflow), C=30, D=30] in container 100.
            // A on its own line, B on its own (overflow), C+D on their own line.
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: .rigid(150), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                ],
                in: 100
            )
            #expect(result.count == 3)
            #expect(result[0] == [.init(index: 0, size: 30, leadingSpace: 0)])
            #expect(result[1] == [.init(index: 1, size: 150, leadingSpace: 0)])
            #expect(result[2] == [.init(index: 2, size: 30, leadingSpace: 0), .init(index: 3, size: 30, leadingSpace: 10)])
        }
    }

    @Suite("KnuthPlassLineBreaker")
    struct KnuthPlassLineBreakerTests {

        @Test func basic() {
            let sut = KnuthPlassLineBreaker()
            let breakpoints = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(10), spacing: 10),
                    .init(size: .rigid(20), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                    .init(size: .rigid(40), spacing: 10),
                    .init(size: .rigid(20), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                ],
                in: 80
            )
            #expect(
                breakpoints == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
                    [.init(index: 3, size: 40, leadingSpace: 0)],
                    [.init(index: 4, size: 20, leadingSpace: 0), .init(index: 5, size: 30, leadingSpace: 10)],
                ]
            )
        }

        @Test func equalRigidItems_rebalancesTrailingSingleItem() {
            let items: [MeasuredItem] = [
                .init(size: .rigid(10), spacing: 0),
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(10), spacing: 10),
            ]

            let greedy = GreedyLineBreaker().wrapItemsToLines(items: items, in: 50)
            let balanced = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: 50)

            #expect(
                greedy == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 10, leadingSpace: 10), .init(index: 2, size: 10, leadingSpace: 10)],
                    [.init(index: 3, size: 10, leadingSpace: 0)],
                ]
            )
            #expect(
                balanced == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 10, leadingSpace: 10)],
                    [.init(index: 2, size: 10, leadingSpace: 0), .init(index: 3, size: 10, leadingSpace: 10)],
                ]
            )
        }

        @Test func asymmetricRigidItems_rebalancesTrailingSingleItemWithoutReordering() {
            let items: [MeasuredItem] = [
                .init(size: .rigid(10), spacing: 0),
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(20), spacing: 10),
            ]

            let greedy = GreedyLineBreaker().wrapItemsToLines(items: items, in: 50)
            let balanced = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: 50)

            #expect(
                greedy == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 10, leadingSpace: 10), .init(index: 2, size: 10, leadingSpace: 10)],
                    [.init(index: 3, size: 20, leadingSpace: 0)],
                ]
            )
            #expect(
                balanced == [
                    [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 10, leadingSpace: 10)],
                    [.init(index: 2, size: 10, leadingSpace: 0), .init(index: 3, size: 20, leadingSpace: 10)],
                ]
            )
        }

        @Test func emptyInput() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(items: [], in: 100)
            #expect(result.isEmpty)
        }

        @Test func singleItem() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(50), spacing: 0)
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 50, leadingSpace: 0)]
                ]
            )
        }

        @Test func flexibleItems_stretchPenalty() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: 20 ... 60, spacing: 10),
                ],
                in: 80
            )
            #expect(
                result == [
                    [.init(index: 0, size: 30, leadingSpace: 0), .init(index: 1, size: 40, leadingSpace: 10)]
                ]
            )
        }

        @Test func lineBreakView() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(0), spacing: 0, isLineBreakView: true),
                    .init(size: .rigid(20), spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0)],
                    [.init(index: 1, size: 0, leadingSpace: 0), .init(index: 2, size: 20, leadingSpace: 0)],
                ]
            )
        }

        @Test func lineBreakAtStart_clearsFollowingSpacing() {
            assertLineBreakAtStartClearsFollowingSpacing(KnuthPlassLineBreaker())
        }

        @Test func shouldStartInNewLine() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(20), spacing: 10, shouldStartInNewLine: true),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0)],
                    [.init(index: 1, size: 20, leadingSpace: 0)],
                ]
            )
        }

        @Test func shouldStartInNewLineAtFirstItem_allowsFollowingItemsOnSameLine() {
            assertShouldStartInNewLineAtFirstItemAllowsFollowingItemsOnSameLine(KnuthPlassLineBreaker())
        }

        @Test func negativeSpacing_keepsOverlappingRigidItemsOnOneLine() {
            assertNegativeSpacingKeepsOverlappingRigidItemsOnOneLine(KnuthPlassLineBreaker())
        }

        @Test func zeroSizedItem_staysOnLineAndKeepsSpacing() {
            assertZeroSizedItemStaysOnLineAndKeepsSpacing(KnuthPlassLineBreaker())
        }

        @Test func negativeAvailableSpace_fallsBackToOneItemPerLine() {
            assertNegativeAvailableSpaceFallsBackToOneItemPerLine(KnuthPlassLineBreaker())
        }

        @Test func maximumFlexItem_movesToOwnLineWhenFullGrowthDoesNotFit() {
            assertMaximumFlexItemMovesToOwnLineWhenFullGrowthDoesNotFit(KnuthPlassLineBreaker())
        }

        @Test func vsFlow_balancedLines() {
            let items: [MeasuredItem] = [
                .init(size: .rigid(30), spacing: 0),
                .init(size: .rigid(30), spacing: 10),
                .init(size: .rigid(30), spacing: 10),
                .init(size: .rigid(30), spacing: 10),
                .init(size: .rigid(30), spacing: 10),
            ]

            let flow = GreedyLineBreaker().wrapItemsToLines(items: items, in: 80)
            let knuth = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: 80)

            // Both should produce valid line breaks
            #expect(!flow.isEmpty)
            #expect(!knuth.isEmpty)

            // Knuth-Plass should produce more balanced lines
            func lineWidth(_ line: [WrappedItem]) -> CGFloat {
                line.reduce(CGFloat(0)) { $0 + $1.size + $1.leadingSpace }
            }
            let flowWidths = flow.map(lineWidth)
            let knuthWidths = knuth.map(lineWidth)

            let flowImbalance = (flowWidths.max() ?? 0) - (flowWidths.min() ?? 0)
            let knuthImbalance = (knuthWidths.max() ?? 0) - (knuthWidths.min() ?? 0)

            #expect(knuthImbalance <= flowImbalance, "Knuth-Plass should produce more balanced or equal lines")
        }

        @Test func oversizedItem_placedAlone() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(150), spacing: 0)
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 150, leadingSpace: 0)]
                ]
            )
        }

        @Test func oversizedItem_doesNotDropNeighbours() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: .rigid(150), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 30, leadingSpace: 0)],
                    [.init(index: 1, size: 150, leadingSpace: 0)],
                    [.init(index: 2, size: 30, leadingSpace: 0), .init(index: 3, size: 30, leadingSpace: 10)],
                ]
            )
        }

        @Test func multipleFlexItems() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: 20 ... 40, spacing: 0),
                    .init(size: 20 ... 40, spacing: 10),
                    .init(size: 20 ... 40, spacing: 10),
                ],
                in: 80
            )
            #expect(
                result == [
                    [.init(index: 0, size: 20, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 20, leadingSpace: 10)]
                ],
                "All flexible items fit exactly on one line at their minimum sizes"
            )
        }

        @Test func newLine_withFlex() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: 20 ... 60, spacing: 10, shouldStartInNewLine: true),
                ],
                in: 100
            )
            #expect(
                result == [
                    [.init(index: 0, size: 30, leadingSpace: 0)],
                    [.init(index: 1, size: 60, leadingSpace: 0)],
                ],
                "shouldStartInNewLine should force a new line and clear the leading spacing"
            )
        }

        @Test func knuth_plass_infiniteSpace_keepsAllItemsOnOneLine() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: 10 ... 50, spacing: 0),
                    .init(size: 10 ... 50, spacing: 10),
                    .init(size: .rigid(30), spacing: 10),
                ],
                in: .infinity
            )
            #expect(result.count == 1, "Unbounded space should keep everything on one line")
            #expect(result.flatMap { $0 }.map(\.index) == [0, 1, 2])
        }

        @Test func negativeSpacing_keepsItemsTogetherWhenWiderRangeFitsButInnerRangeOverflows() {
            // A=60, B=60 (spacing -90), C=60 (spacing 0) in width 100.
            // The inner range [B, C] overflows (min 120 > 100), but the full range
            // [A, B, C] fits (min 180 - 90 = 90 <= 100) because of B's negative spacing.
            // The solver must not stop scanning at the overflowing inner range, otherwise
            // it splits the items across lines instead of keeping them together.
            let items: [MeasuredItem] = [
                .init(size: .rigid(60), spacing: 0),
                .init(size: .rigid(60), spacing: -90),
                .init(size: .rigid(60), spacing: 0),
            ]
            let result = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: 100)
            #expect(
                result == [
                    [
                        .init(index: 0, size: 60, leadingSpace: 0),
                        .init(index: 1, size: 60, leadingSpace: -90),
                        .init(index: 2, size: 60, leadingSpace: 0),
                    ]
                ],
                "Negative spacing can let a wider range fit; the solver must keep these items on one line"
            )
            // Both breakers must agree on this layout.
            #expect(result == GreedyLineBreaker().wrapItemsToLines(items: items, in: 100))
        }

        @Test func knuth_plass_infiniteSpace_honorsManualBreaks() {
            let sut = KnuthPlassLineBreaker()
            let result = sut.wrapItemsToLines(
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(20), spacing: 10, shouldStartInNewLine: true),
                ],
                in: .infinity
            )
            #expect(result.count == 2, "Manual breaks must still split lines under unbounded space")
            #expect(result.flatMap { $0 }.map(\.index) == [0, 1])
        }
    }

    @Suite("Parity")
    struct ParityTests {
        struct Scenario: CustomTestStringConvertible, Sendable {
            let testDescription: String
            let items: [MeasuredItem]
            let available: CGFloat
        }

        @Test(arguments: [
            Scenario(testDescription: "empty input", items: [], available: 100),
            Scenario(
                testDescription: "single item",
                items: [
                    .init(size: .rigid(50), spacing: 0)
                ],
                available: 100
            ),
            Scenario(
                testDescription: "all items fit on one line",
                items: [
                    .init(size: .rigid(20), spacing: 0),
                    .init(size: .rigid(20), spacing: 5),
                    .init(size: .rigid(20), spacing: 5),
                ],
                available: 100
            ),
            Scenario(
                testDescription: "all items oversized — each forced to own line",
                items: [
                    .init(size: .rigid(60), spacing: 0),
                    .init(size: .rigid(60), spacing: 10),
                    .init(size: .rigid(60), spacing: 10),
                ],
                available: 50
            ),
            Scenario(
                testDescription: "line-break views fully determine structure",
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: .rigid(0), spacing: 0, isLineBreakView: true),
                    .init(size: .rigid(30), spacing: 0),
                ],
                available: 100
            ),
            Scenario(
                testDescription: "shouldStartInNewLine fully determines structure",
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: .rigid(30), spacing: 5, shouldStartInNewLine: true),
                    .init(size: .rigid(30), spacing: 5),
                ],
                available: 100
            ),
            Scenario(
                testDescription: "negative spacing — overlapping items fit on one line",
                items: [
                    .init(size: .rigid(60), spacing: 0),
                    .init(size: .rigid(60), spacing: -30),
                ],
                available: 100
            ),
            Scenario(
                testDescription: "zero-size items mixed with normal — all fit on one line",
                items: [
                    .init(size: .rigid(30), spacing: 0),
                    .init(size: .rigid(0), spacing: 5),
                    .init(size: .rigid(30), spacing: 5),
                ],
                available: 100
            ),
            Scenario(
                testDescription: "negative available space — fallback to one item per line",
                items: [
                    .init(size: .rigid(10), spacing: 0),
                    .init(size: .rigid(10), spacing: 5),
                ],
                available: -10
            ),
            Scenario(
                testDescription: "negative spacing — wider range fits though inner range overflows",
                items: [
                    .init(size: .rigid(60), spacing: 0),
                    .init(size: .rigid(60), spacing: -90),
                    .init(size: .rigid(60), spacing: 0),
                ],
                available: 100
            ),
        ])
        func bothBreakersAgree(scenario: Scenario) {
            let flow = GreedyLineBreaker().wrapItemsToLines(items: scenario.items, in: scenario.available)
            let knuth = KnuthPlassLineBreaker().wrapItemsToLines(items: scenario.items, in: scenario.available)
            #expect(flow == knuth)
        }
    }
}

private func assertLineBreakAtStartClearsFollowingSpacing(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(0), spacing: 12, isLineBreakView: true),
            .init(size: .rigid(20), spacing: 99),
            .init(size: .rigid(20), spacing: 10),
        ],
        in: 100
    )
    #expect(
        result == [
            [
                .init(index: 0, size: 0, leadingSpace: 0),
                .init(index: 1, size: 20, leadingSpace: 0),
                .init(index: 2, size: 20, leadingSpace: 10),
            ]
        ]
    )
}

private func assertShouldStartInNewLineAtFirstItemAllowsFollowingItemsOnSameLine(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(20), spacing: 99, shouldStartInNewLine: true),
            .init(size: .rigid(20), spacing: 10),
        ],
        in: 100
    )
    #expect(
        result == [
            [
                .init(index: 0, size: 20, leadingSpace: 0),
                .init(index: 1, size: 20, leadingSpace: 10),
            ]
        ]
    )
}

private func assertNegativeSpacingKeepsOverlappingRigidItemsOnOneLine(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(60), spacing: 0),
            .init(size: .rigid(60), spacing: -30),
        ],
        in: 100
    )
    #expect(
        result == [
            [
                .init(index: 0, size: 60, leadingSpace: 0),
                .init(index: 1, size: 60, leadingSpace: -30),
            ]
        ]
    )
}

private func assertZeroSizedItemStaysOnLineAndKeepsSpacing(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(0), spacing: 5),
            .init(size: .rigid(20), spacing: 5),
        ],
        in: 100
    )
    #expect(
        result == [
            [
                .init(index: 0, size: 20, leadingSpace: 0),
                .init(index: 1, size: 0, leadingSpace: 5),
                .init(index: 2, size: 20, leadingSpace: 5),
            ]
        ]
    )
}

private func assertNegativeAvailableSpaceFallsBackToOneItemPerLine(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(1), spacing: 0),
            .init(size: .rigid(1), spacing: 0),
        ],
        in: -1
    )
    #expect(
        result == [
            [.init(index: 0, size: 1, leadingSpace: 0)],
            [.init(index: 1, size: 1, leadingSpace: 0)],
        ]
    )
}

private func assertMaximumFlexItemMovesToOwnLineWhenFullGrowthDoesNotFit(_ sut: some LineBreaking) {
    let result = sut.wrapItemsToLines(
        items: [
            .init(size: .rigid(60), spacing: 0),
            .init(size: 20 ... 100, spacing: 10, flexibility: .maximum),
            .init(size: .rigid(10), spacing: 10),
        ],
        in: 100
    )
    #expect(
        result == [
            [.init(index: 0, size: 60, leadingSpace: 0)],
            [.init(index: 1, size: 100, leadingSpace: 0)],
            [.init(index: 2, size: 10, leadingSpace: 0)],
        ]
    )
}

extension ClosedRange {
    fileprivate static func rigid(_ value: Bound) -> Self {
        value ... value
    }
}
