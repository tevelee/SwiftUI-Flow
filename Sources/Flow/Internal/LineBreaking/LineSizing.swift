import CoreFoundation
import Foundation

/// Sizes a single candidate line for a fixed available breadth.
///
/// Given the items considered for one line, it decides whether they fit (honoring minimum widths and
/// the structural rules around line breaks) and, if so, resolves each item's breadth — distributing
/// any leftover space by layout priority and flexibility. Both ``GreedyLineBreaker`` and
/// ``KnuthPlassLineBreaker`` size every candidate line through this one type.
struct LineSizer {
    let availableSpace: CGFloat

    /// The fitted line for `items`, or `nil` when they cannot fit — their minimum widths exceed the
    /// available space, or a structural rule forbids them sharing a line (a line break or a
    /// `shouldStartInNewLine` item anywhere but first).
    func sizes(of items: IndexedMeasuredItems) -> SizedLine? {
        guard let items = normalizedItemsForSizing(items) else {
            return nil
        }

        let totalMinimumSize = totalMinimumSize(of: items)
        guard totalMinimumSize <= availableSpace + roundingTolerance(for: totalMinimumSize) else {
            return nil
        }

        var remainingSpace = max(0, availableSpace - totalMinimumSize)
        guard maximumFlexItemsFit(items, remainingSpace: remainingSpace) else {
            return nil
        }

        let result = distributeRemainingSpace(in: items, remainingSpace: &remainingSpace)
        return SizedLine(items: result, remainingSpace: remainingSpace)
    }

    /// The fitted line when `items` fit, otherwise the minimum-size fallback — always returns a line.
    func resolvedLine(_ items: IndexedMeasuredItems) -> WrappedLine {
        sizes(of: items)?.items ?? fallbackLine(items)
    }

    /// Places items at their minimum sizes when the normal sizing constraints cannot be satisfied
    /// (e.g. an item wider than the available space).
    func fallbackLine(_ items: IndexedMeasuredItems) -> WrappedLine {
        items.enumerated().map { i, item in
            WrappedItem(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
        }
    }

    func normalizedItemsForSizing(_ items: IndexedMeasuredItems) -> IndexedMeasuredItems? {
        guard !items.isEmpty else {
            return nil
        }

        let positionOfLineBreak = items.lastIndex(where: \.element.isLineBreakView)
        if let positionOfLineBreak, positionOfLineBreak > 0 {
            return nil
        }

        if items.dropFirst().contains(where: \.element.shouldStartInNewLine) {
            return nil
        }

        var normalized = items
        if let positionOfLineBreak {
            let afterLineBreak = normalized.index(after: positionOfLineBreak)
            if afterLineBreak < normalized.endIndex {
                normalized[afterLineBreak].element.spacing = 0
            }
        }
        return normalized
    }

    func totalMinimumSize(of items: IndexedMeasuredItems) -> CGFloat {
        items.sum(of: \.element.size.lowerBound) + items.dropFirst().sum(of: \.element.spacing)
    }

    func roundingTolerance(for totalMinimumSize: CGFloat) -> CGFloat {
        max(totalMinimumSize.magnitude, availableSpace.magnitude, 1) * CGFloat.ulpOfOne
    }

    func maximumFlexItemsFit(_ items: IndexedMeasuredItems, remainingSpace: CGFloat) -> Bool {
        // Each `.maximum` item wants to grow toward filling the line; account for their
        // growth cumulatively so several of them on one segment cannot each claim the
        // same remaining space independently.
        var remainingForMaximumItems = remainingSpace
        for item in items where item.element.flexibility == .maximum {
            let size = max(item.element.size.lowerBound, min(availableSpace, item.element.size.upperBound))
            let growth = size - item.element.size.lowerBound
            if growth > remainingForMaximumItems {
                return false
            }
            remainingForMaximumItems -= growth
        }
        return true
    }

    func distributeRemainingSpace(
        in items: IndexedMeasuredItems,
        remainingSpace: inout CGFloat
    ) -> WrappedLine {
        // Layout according to priorities and proportionally distribute remaining space
        // between flexible views.
        var result = items.enumerated().map { i, item in
            WrappedItem(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
        }

        let itemsInPriorityOrder = Dictionary(grouping: items.enumerated(), by: \.element.element.priority)
        let priorities = itemsInPriorityOrder.keys.sorted(by: >)
        for priority in priorities where remainingSpace > 0 {
            let items = itemsInPriorityOrder[priority] ?? []
            let itemsInFlexibilityOrder = items.sorted(using: KeyPathComparator(\.element.element.growingPotential))
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
typealias SizedLine = (items: WrappedLine, remainingSpace: CGFloat)
