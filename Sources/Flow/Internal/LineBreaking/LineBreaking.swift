import CoreFoundation

// Pipeline phase — line breaking: the contract and its vocabulary.
//
// A breaker turns measured items into wrapped lines. Two implementations exist — the greedy
// ``GreedyLineBreaker`` (the default) in `GreedyLineBreaker.swift` and the optimal
// ``KnuthPlassLineBreaker`` (for `distributeItemsEvenly`) in `KnuthPlassLineBreaker.swift` — and both resolve
// each candidate line's item breadths through the shared ``LineSizer`` in `LineSizing.swift`.
//
// The vocabulary names the two sides apart: a `MeasuredItem` goes *in*, a `WrappedItem` (on a
// `WrappedLine`) comes *out*. Downstream, geometry turns those into `PlacedItem`/`LayoutLine`, so a
// value's type always says whether you are in breaker space or geometry space.

/// One item as the breaker sees it: a breadth range it may occupy, the spacing before it, and the
/// layout flags that constrain where it can go.
package struct MeasuredItem: Sendable {
    package var size: ClosedRange<CGFloat>
    package var spacing: CGFloat
    package var priority: Double = 0
    package var flexibility: FlexibilityBehavior = .natural
    package var isLineBreakView: Bool = false
    package var shouldStartInNewLine: Bool = false
    /// How much breadth the item can still gain beyond its minimum (zero when it must stay minimal).
    var growingPotential: Double {
        guard flexibility == .minimum else {
            return size.upperBound - size.lowerBound
        }
        return 0
    }
}

/// One item placed on a wrapped line: which subview it is, its resolved breadth, and the space before it.
package struct WrappedItem: Equatable {
    package let index: Int
    package var size: CGFloat
    package var leadingSpace: CGFloat

    package init(index: Int, size: CGFloat, leadingSpace: CGFloat) {
        self.index = index
        self.size = size
        self.leadingSpace = leadingSpace
    }
}

/// One wrapped line.
package typealias WrappedLine = [WrappedItem]

/// All the wrapped lines a breaker produces.
package typealias WrappedLines = [WrappedLine]

/// Measured items carrying their original positions, used while sizing a candidate line.
typealias IndexedMeasuredItems = [(offset: Int, element: MeasuredItem)]

/// Wraps a flat run of measured items into lines that each fit `availableSpace`.
protocol LineBreaking {
    func wrapItemsToLines(items: [MeasuredItem], in availableSpace: CGFloat) -> WrappedLines
}
