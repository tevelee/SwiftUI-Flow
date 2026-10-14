import CoreFoundation

/// The input seam's value: the line-breaker input together with the map from each item's *position*
/// (the index the breaker reports back) to its real subview index.
///
/// Plain content uses an implicit identity mapping, including when a trailing overflow indicator
/// is excluded. Separator preparation measures only content items and supplies their cached subview
/// indices, so ``resolve(_:)`` can translate the breaker's positional output when needed.
struct BreakerInput {
    /// What the breaker sees, in positional order.
    var items: [MeasuredItem]
    /// `subviewIndices[position]` is the real subview index, or `nil` when positions are already
    /// subview indices. The common path allocates no mapping and returns the breaker's lines directly.
    var subviewIndices: [Int]?

    /// Translates the breaker's positional ``WrappedItem`` indices into subview indices.
    func resolve(_ wrapped: WrappedLines) -> WrappedLines {
        guard let subviewIndices else { return wrapped }
        return wrapped.map { line in
            line.map { WrappedItem(index: subviewIndices[$0.index], size: $0.size, leadingSpace: $0.leadingSpace) }
        }
    }
}
