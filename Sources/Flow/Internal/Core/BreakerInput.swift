import CoreFoundation

/// The input seam's value: the line-breaker input together with the map from each item's *position*
/// (the index the breaker reports back) to its real subview index.
///
/// Measurement produces an identity-mapped value (position `i` is subview `i`). The input-seam steps
/// — excluding an overflow indicator, collapsing to content-only — rewrite the items and the map in
/// lock-step, so ``resolve(_:)`` can always translate the breaker's positional output back into
/// subview-index space for everything downstream.
package struct BreakerInput {
    /// What the breaker sees, in positional order.
    package var items: [MeasuredItem]
    /// `subviewIndices[position]` is the real subview index of the item at that breaker position.
    package var subviewIndices: [Int]

    package init(items: [MeasuredItem], subviewIndices: [Int]) {
        self.items = items
        self.subviewIndices = subviewIndices
    }

    /// Translates the breaker's positional ``WrappedItem`` indices into subview indices.
    package func resolve(_ wrapped: WrappedLines) -> WrappedLines {
        wrapped.map { line in
            line.map { WrappedItem(index: subviewIndices[$0.index], size: $0.size, leadingSpace: $0.leadingSpace) }
        }
    }
}
