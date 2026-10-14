import CoreFoundation
import SwiftUI

/// Owns the content selected for wrapping and the visible result after line limits and separators.
/// The engine measures requested subviews and breaks lines; this module keeps overflow exclusion,
/// gap reservation, cap-before-separator ordering and report counting together.
struct VisibleLineComposition {
    private let cache: FlowLayoutCache
    private let axis: Axis
    private let itemSpacing: CGFloat?
    private let lineCap: LineCap?
    private let separators: SeparatorLayout?

    init(cache: FlowLayoutCache, axis: Axis, itemSpacing: CGFloat?, lineCap: LineCap?) {
        self.cache = cache
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.lineCap = lineCap
        separators = SeparatorLayout(cache: cache, axis: axis, itemSpacing: itemSpacing)
    }

    /// Requests measurements only for breaker content, reserving the same gaps used when fitting
    /// an overflow indicator. Plain flows need neither a separator plan nor an index mapping.
    func prepareInput(measure: (Int, CGFloat) -> MeasuredItem) -> BreakerInput {
        let overflowIndex = lineCap == nil ? nil : cache.overflowSubviewIndex
        if let separators {
            return separators.prepareInput(excluding: overflowIndex, measure: measure)
        }
        let indices = cache.subviewsCache.indices.dropLast(overflowIndex == nil ? 0 : 1)
        let items = indices.map { index in
            measure(index, index == 0 ? 0 : spacing(before: index, after: index - 1))
        }
        return BreakerInput(items: items)
    }

    struct Result {
        var lines: WrappedLines
        var hidden: [Int]
        var report: FlowLayoutReport
    }

    /// Cap content lines before inserting separator lines, so separators never consume the limit.
    /// Hidden membership, overflow count and line structure all describe this same composition.
    func compose(_ wrapped: WrappedLines, in proposal: ProposedViewSize, justified: Bool) -> Result {
        let capped =
            lineCap?.truncate(
                wrapped,
                available: proposal.replacingUnspecifiedDimensions(by: .infinity).value(on: axis),
                cache: cache,
                spacingBefore: { spacing(before: $0, after: $1) }
            ) ?? LineAdaptation(lines: wrapped)
        let materialized = separators?.materialize(in: capped.lines, justified: justified, proposal: proposal)
        return Result(
            lines: materialized?.lines ?? capped.lines,
            hidden: capped.hidden + (materialized?.hidden ?? []),
            report: FlowLayoutReport(
                overflowCount: overflowCount(hidden: capped.hidden),
                lineStructure: materialized?.lineStructure ?? []
            )
        )
    }

    private func spacing(before current: Int, after previous: Int) -> CGFloat {
        separators?.spacing(before: current, after: previous)
            ?? cache.spacing(from: previous, to: current, itemSpacing: itemSpacing, axis: axis)
    }

    private func overflowCount(hidden: [Int]) -> Int {
        guard let overflowIndex = cache.overflowSubviewIndex else { return 0 }
        return hidden.reduce(0) { count, index in
            count + (index != overflowIndex && cache.subviewsCache[index].role == .content ? 1 : 0)
        }
    }
}

/// One feature's adapted lines and hidden subviews. Only separator materialization adds structure.
struct LineAdaptation {
    var lines: WrappedLines
    var hidden: [Int] = []
    var lineStructure: [Int]?
}
