import CoreFoundation
import SwiftUI

/// The separator feature: draws separators between items and between lines, much as ``LineCap``
/// handles line limits. ``VisibleLineComposition`` calls it at the two adaptation seams:
///
/// * ``prepareInput(excluding:measure:)`` (input seam) measures content items only, folding each
///   item separator's breadth into the following item's spacing so wrapping accounts for it while
///   the breaker stays separator-agnostic.
/// * ``materialize(in:justified:proposal:)`` (output seam) re-materializes those separators once the
///   lines are known — item separators as ordinary in-line items, line separators as their own
///   single-item lines — so the core line-construction code treats them like any other subview.
///
/// Created only when a subview carries a separator role (see ``init?(cache:axis:itemSpacing:)``).
struct SeparatorLayout {
    private let plan: SeparatorPlan
    private let axis: Axis
    private let itemSpacing: CGFloat?
    private let cache: FlowLayoutCache

    init?(cache: FlowLayoutCache, axis: Axis, itemSpacing: CGFloat?) {
        guard let plan = cache.separatorPlan else { return nil }
        self.plan = plan
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.cache = cache
    }

    // MARK: - Input seam

    /// Measures content directly in breaker order, reserving separator breadth in leading spacing.
    /// The optional overflow indicator is always the last subview; excluding it preserves positions
    /// in the cached content order. Separators use their cached ideal sizes until materialization.
    func prepareInput(
        excluding overflowIndex: Int?,
        measure: (Int, CGFloat) -> MeasuredItem
    ) -> BreakerInput {
        var indices = plan.contentIndices
        if let overflowIndex, indices.last == overflowIndex {
            indices.removeLast()
        }
        let items = indices.enumerated().map { position, index in
            measure(index, breakerSpacing(beforeContentPosition: position))
        }
        return BreakerInput(items: items, subviewIndices: indices)
    }

    /// Leading space the breaker reserves before the content item at `position`: the normal spacing,
    /// plus the item separator's breadth and its own spacing when an eligible gap carries one. The
    /// breaker drops it automatically where a line breaks (first-on-line items get zero leading space),
    /// which is exactly where the item separator yields to a line separator.
    private func breakerSpacing(beforeContentPosition position: Int) -> CGFloat {
        guard position > 0 else { return 0 }
        let current = plan.contentIndices[position]
        let previous = plan.contentIndices[position - 1]
        return spacing(before: current, after: previous)
    }

    /// Reserves the same gap for wrapping and overflow fitting. An overflow chip takes the
    /// separator following the last retained item, even when truncation changes that item.
    func spacing(before current: Int, after previous: Int) -> CGFloat {
        if let separator = itemSeparator(before: current, after: previous) {
            return spacing(from: previous, to: separator.index) + separator.size + spacing(from: separator.index, to: current)
        }
        return spacing(from: previous, to: current)
    }

    // MARK: - Output seam

    /// Re-materializes separators into the wrapped content lines: an item separator before each
    /// eligible non-first item on a line, and a line separator as its own single-item line at each
    /// break boundary. Records the content line structure and hides any separators left unused.
    func materialize(
        in lines: WrappedLines,
        justified: Bool,
        proposal: ProposedViewSize
    ) -> LineAdaptation {
        let structure = lineStructure(of: lines)
        let breadth = lineSeparatorBreadth(for: lines, justified: justified, proposal: proposal)

        var result: WrappedLines = []
        result.reserveCapacity(lines.count * 2)
        for index in lines.indices {
            if index > 0, let first = lines[index].first?.index, let separator = plan.lineSeparator(before: first) {
                // A line separator reuses all the existing line placement, spacing, and alignment
                // machinery for free by being its own single-item line.
                result.append([WrappedItem(index: separator, size: breadth, leadingSpace: 0)])
            }
            result.append(expandItemSeparators(in: lines[index]))
        }

        var placed = [Bool](repeating: false, count: cache.subviewsCache.count)
        for line in result {
            for item in line { placed[item.index] = true }
        }
        return LineAdaptation(lines: result, hidden: unusedSeparators(placed: placed), lineStructure: structure)
    }

    /// Line indices in caller subview order, including explicit separator overrides assigned the
    /// preceding content item's line. This matches the interleaver's source positions so line
    /// separators retain their visual identity when boundaries include overrides.
    /// Hidden items (capped by maxLines) are assigned `hiddenLineSentinel` so the view layer can
    /// distinguish them from visible items on line 0 and avoid injecting spurious separators.
    func lineStructure(of visible: WrappedLines) -> [Int] {
        var lineBySubview = [Int](repeating: Self.hiddenLineSentinel, count: cache.subviewsCache.count)
        for lineIndex in visible.indices {
            for item in visible[lineIndex] {
                lineBySubview[item.index] = lineIndex
            }
        }
        var lineOf: [Int] = []
        var precedingLine = Self.hiddenLineSentinel
        for index in cache.subviewsCache.indices {
            switch cache.subviewsCache[index].role {
                case .content, .lineBreak:
                    precedingLine = lineBySubview[index]
                    lineOf.append(precedingLine)
                case .itemSeparatorOverride:
                    lineOf.append(precedingLine)
                case .itemSeparator, .lineSeparator:
                    break
            }
        }
        return lineOf
    }

    /// Sentinel stored in `lineStructure` for content items absent from the visible output (capped by
    /// maxLines). The value is negative so the view layer can check `>= 0` for visibility.
    static let hiddenLineSentinel = -1

    /// The breadth proposed to line separators: the justified width when justifying, otherwise the
    /// widest content line, so a full-width separator (e.g. a `Divider`) spans the laid-out content.
    private func lineSeparatorBreadth(for lines: WrappedLines, justified: Bool, proposal: ProposedViewSize) -> CGFloat {
        if justified, proposal.value(on: axis).isFinite {
            return proposal.value(on: axis)
        }
        return lines.map { line in line.sum { $0.size + $0.leadingSpace } }.max() ?? 0
    }

    /// Splits each folded item separator back out of the following content item's leading space,
    /// inserting it as an ordinary in-line item with its own breadth and spacing.
    private func expandItemSeparators(in line: WrappedLine) -> WrappedLine {
        var items: WrappedLine = []
        items.reserveCapacity(line.count)
        for indexInLine in line.indices {
            var output = line[indexInLine]
            if indexInLine > 0, let separator = itemSeparator(before: output.index, after: line[indexInLine - 1].index) {
                items.append(separator)
                output.leadingSpace -= separator.leadingSpace + separator.size
            }
            items.append(output)
        }
        return items
    }

    /// Separators left unused — orphaned at an edge, mid-line, or in a truncated/ineligible gap. They
    /// must still be placed once and collapsed off-screen, like truncated content.
    private func unusedSeparators(placed: [Bool]) -> [Int] {
        plan.separatorIndices.filter { !placed[$0] }
    }

    // MARK: - Shared geometry

    /// The eligible item separator drawn before content item `contentIndex`, or `nil` when its gap
    /// carries no in-line separator. Used by both seams — to reserve its breadth before wrapping, and
    /// to re-insert it after.
    private func itemSeparator(before contentIndex: Int, after previous: Int) -> WrappedItem? {
        guard let separator = plan.itemSeparator(before: contentIndex, after: previous) else { return nil }
        return WrappedItem(
            index: separator,
            size: cache.subviewsCache[separator].ideal.breadth,
            leadingSpace: spacing(from: previous, to: separator)
        )
    }

    private func spacing(from previous: Int, to current: Int) -> CGFloat {
        cache.spacing(from: previous, to: current, itemSpacing: itemSpacing, axis: axis)
    }
}

extension SeparatorPlan {
    /// Cache construction is the only place that scans structural tags. Plain flows keep no plan.
    @usableFromInline
    init?(cachedSubviews: [FlowLayoutCache.SubviewCache]) {
        guard cachedSubviews.contains(where: { $0.role.isSeparator }) else { return nil }
        self.init(subviews: cachedSubviews.map { Subview(role: $0.role, origin: $0.origin) })
    }
}
