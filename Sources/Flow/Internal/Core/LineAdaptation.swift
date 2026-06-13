import CoreFoundation

/// The output seam's value: the lines flowing through it, plus the side outputs accumulated along the way.
///
/// Each output-seam step is a pure function returning a `LineAdaptation` of the lines it was given
/// (``LineCap/truncate(_:available:cache:spacingBefore:)``,
/// ``SeparatorLayout/materialize(in:justified:proposal:)``). The core threads one `LineAdaptation`
/// through the seam, folding each step's result in with ``apply(_:)`` — so the same type serves as
/// both a step's return value and the running accumulator.
struct LineAdaptation {
    /// The adapted wrapped lines, in subview-index space.
    var lines: WrappedLines
    /// Subview indices to park off-screen (truncated content, unused separators, …).
    var hidden: [Int] = []
    /// Content line structure reported back to the view layer (used by line separators), or `nil`
    /// when no step has produced it.
    var lineStructure: [Int]?

    /// Folds a later step's adaptation onto this one: its lines become current, its hidden indices
    /// accumulate, and its line structure is adopted when present (a step that produces none leaves
    /// the running one intact).
    mutating func apply(_ next: LineAdaptation) {
        lines = next.lines
        hidden += next.hidden
        if let lineStructure = next.lineStructure {
            self.lineStructure = lineStructure
        }
    }
}
