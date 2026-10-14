import CoreFoundation

/// Sizes a single candidate line for a fixed available breadth.
///
/// Given the items considered for one line, it decides whether they fit (honoring minimum widths and
/// the structural rules around line breaks) and, if so, resolves each item's breadth — distributing
/// any leftover space by layout priority and flexibility. ``GreedyLineBreaker`` checks feasibility
/// while filling a line and sizes only completed lines; ``KnuthPlassLineBreaker`` sizes flexible
/// candidates to score stretch and uses feasibility alone when no items can grow.
@usableFromInline
struct LineSizer {
    @usableFromInline
    let availableSpace: CGFloat

    @inlinable
    init(availableSpace: CGFloat) {
        self.availableSpace = availableSpace
    }

    /// Whether a candidate fits, without allocating wrapped items or distributing flexible space.
    @inlinable
    func fits(_ items: IndexedMeasuredItems) -> Bool {
        remainingSpace(for: items) != nil
    }

    /// The fitted line for `items`, or `nil` when they cannot fit — their minimum widths exceed the
    /// available space, or a structural rule forbids them sharing a line (a line break or a
    /// `shouldStartInNewLine` item anywhere but first).
    @inlinable
    func sizes(of items: IndexedMeasuredItems) -> SizedLine? {
        guard let fitted = fittingItems(items) else { return nil }
        var remainingSpace = fitted.remainingSpace
        let result = distributeRemainingSpace(in: fitted.items, remainingSpace: &remainingSpace)
        return SizedLine(items: result, remainingSpace: remainingSpace)
    }

    /// Shared feasibility rules keep the greedy and balanced breakers consistent, including
    /// spacing normalization after manual breaks and the collective demands of `.maximum` items.
    @usableFromInline
    func fittingItems(_ items: IndexedMeasuredItems) -> (items: IndexedMeasuredItems, remainingSpace: CGFloat)? {
        guard let remainingSpace = remainingSpace(for: items) else { return nil }
        var normalized = items
        if items.count > 1, items[0].element.isLineBreakView {
            normalized[1].element.spacing = 0
        }
        return (normalized, remainingSpace)
    }

    /// The fitted line when `items` fit, otherwise the minimum-size fallback — always returns a line.
    @usableFromInline
    func resolvedLine(_ items: IndexedMeasuredItems) -> WrappedLine {
        sizes(of: items)?.items ?? fallbackLine(items)
    }

    /// Places items at their minimum sizes when the normal sizing constraints cannot be satisfied
    /// (e.g. an item wider than the available space).
    @inlinable
    func fallbackLine(_ items: IndexedMeasuredItems) -> WrappedLine {
        items.enumerated().map { i, item in
            WrappedItem(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
        }
    }

    @usableFromInline
    func remainingSpace(for items: IndexedMeasuredItems) -> CGFloat? {
        var fitter = LineFitter(availableSpace: availableSpace)
        for item in items {
            fitter.append(item.element)
        }
        return fitter.remainingSpace
    }

    @usableFromInline
    func distributeRemainingSpace(
        in items: IndexedMeasuredItems,
        remainingSpace: inout CGFloat
    ) -> WrappedLine {
        // Layout according to priorities and proportionally distribute remaining space
        // between flexible views.
        var result = items.enumerated().map { i, item in
            WrappedItem(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
        }

        guard remainingSpace > 0, items.contains(where: { $0.element.growingPotential > 0 }) else {
            return result
        }

        let itemsInPriorityOrder = Dictionary(grouping: items.enumerated(), by: \.element.element.priority)
        let priorities = itemsInPriorityOrder.keys.sorted(by: >)
        for priority in priorities where remainingSpace > 0 {
            let items = itemsInPriorityOrder[priority] ?? []
            let itemsInFlexibilityOrder = items.sorted { $0.element.element.growingPotential < $1.element.element.growingPotential }
            var remainingItemCount = items.count
            for (index, item) in itemsInFlexibilityOrder {
                let offer = remainingSpace / CGFloat(remainingItemCount)
                let allocation = min(item.element.growingPotential, offer)
                result[index].size += allocation
                remainingSpace -= allocation
                remainingItemCount -= 1
            }
        }
        return result
    }
}

/// A fitted line: the resolved items plus the breadth left over after placing them.
@usableFromInline
typealias SizedLine = (items: WrappedLine, remainingSpace: CGFloat)
