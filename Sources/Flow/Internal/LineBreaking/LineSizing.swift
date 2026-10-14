import CoreFoundation

/// Fits and sizes a borrowed range of measured items, keeping their original indices.
/// Balanced wrapping can score uniform growth without constructing a temporary wrapped line.
@usableFromInline
struct LineSizer {
    @usableFromInline let availableSpace: CGFloat

    @inlinable init(availableSpace: CGFloat) { self.availableSpace = availableSpace }

    @inlinable func fits(_ items: ArraySlice<MeasuredItem>) -> Bool {
        remainingSpace(for: items) != nil
    }

    @inlinable func sizes(of items: ArraySlice<MeasuredItem>) -> SizedLine? {
        guard let remainingSpace = remainingSpace(for: items) else { return nil }
        return sizeFittedLine(items, remainingSpace: remainingSpace)
    }

    /// Resolves a candidate already checked by the shared incremental fitter.
    @usableFromInline
    func sizeFittedLine(_ items: ArraySlice<MeasuredItem>, remainingSpace: CGFloat) -> SizedLine {
        var remaining = remainingSpace
        let result = distributeRemainingSpace(in: items, remainingSpace: &remaining)
        return SizedLine(items: result, remainingSpace: remaining)
    }

    /// Scores the same sequential allocations used for placement, avoiding a wrapped-item buffer
    /// when equal priorities and growth limits already determine the allocation order.
    func metrics(of items: ArraySlice<MeasuredItem>, remainingSpace: CGFloat) -> (remainingSpace: CGFloat, squaredGrowth: CGFloat) {
        if remainingSpace > 0, let growth = uniformGrowth(in: items) {
            var distribution = UniformGrowth(growth: growth, count: items.count, remainingSpace: remainingSpace)
            var squaredGrowth: CGFloat = 0
            for item in items {
                let minimum = item.size.lowerBound
                let size = minimum + distribution.nextAllocation()
                let deviation = size - minimum
                squaredGrowth += deviation * deviation
            }
            return (distribution.remainingSpace, squaredGrowth)
        }
        let line = sizeFittedLine(items, remainingSpace: remainingSpace)
        let squaredGrowth: CGFloat = zip(items, line.items).sum { input, output in
            let deviation = output.size - input.size.lowerBound
            return deviation * deviation
        }
        return (line.remainingSpace, squaredGrowth)
    }

    @usableFromInline
    func resolvedLine(_ items: ArraySlice<MeasuredItem>) -> WrappedLine {
        sizes(of: items)?.items ?? fallbackLine(items)
    }

    @inlinable
    func fallbackLine(_ items: ArraySlice<MeasuredItem>) -> WrappedLine {
        items.indices.map { index in
            WrappedItem(index: index, size: items[index].size.lowerBound, leadingSpace: index == items.startIndex ? 0 : items[index].spacing)
        }
    }

    @usableFromInline
    func remainingSpace(for items: ArraySlice<MeasuredItem>) -> CGFloat? {
        var fitter = LineFitter(availableSpace: availableSpace)
        for item in items { fitter.append(item) }
        return fitter.remainingSpace
    }

    private func uniformGrowth(in items: ArraySlice<MeasuredItem>) -> CGFloat? {
        guard let first = items.first else { return nil }
        let growth = first.growingPotential
        return items.allSatisfy { $0.priority == first.priority && $0.growingPotential == growth } ? growth : nil
    }

    @usableFromInline
    func distributeRemainingSpace(in items: ArraySlice<MeasuredItem>, remainingSpace: inout CGFloat) -> WrappedLine {
        let startsWithBreak = items.first?.isLineBreakView == true
        var result = items.indices.map { index in
            let clearsSpacing = index == items.startIndex || (index == items.startIndex + 1 && startsWithBreak)
            return WrappedItem(index: index, size: items[index].size.lowerBound, leadingSpace: clearsSpacing ? 0 : items[index].spacing)
        }
        guard remainingSpace > 0, items.contains(where: { $0.growingPotential > 0 }) else { return result }
        if let growth = uniformGrowth(in: items) {
            var distribution = UniformGrowth(growth: growth, count: items.count, remainingSpace: remainingSpace)
            for index in result.indices { result[index].size += distribution.nextAllocation() }
            remainingSpace = distribution.remainingSpace
            return result
        }
        // Preserve the old grouping behavior for unordered values rather than feeding NaNs to
        // a different sorting comparator. Ordinary priorities and growth use one flat index sort.
        if items.contains(where: { $0.priority.isNaN || $0.growingPotential.isNaN }) {
            distributeUnorderedItems(items, into: &result, remainingSpace: &remainingSpace)
            return result
        }
        let order = items.indices.sorted { left, right in
            if items[left].priority == items[right].priority {
                return items[left].growingPotential < items[right].growingPotential
            }
            return items[left].priority > items[right].priority
        }
        var start = 0
        while start < order.count, remainingSpace > 0 {
            let priority = items[order[start]].priority
            var end = start + 1
            while end < order.count, items[order[end]].priority == priority { end += 1 }
            var remainingItemCount = end - start
            for position in start ..< end {
                let index = order[position]
                let allocation = min(items[index].growingPotential, remainingSpace / CGFloat(remainingItemCount))
                result[index - items.startIndex].size += allocation
                remainingSpace -= allocation
                remainingItemCount -= 1
            }
            start = end
        }
        return result
    }

    private func distributeUnorderedItems(_ items: ArraySlice<MeasuredItem>, into result: inout WrappedLine, remainingSpace: inout CGFloat) {
        let groups = Dictionary(grouping: items.indices, by: { items[$0].priority })
        for priority in groups.keys.sorted(by: >) where remainingSpace > 0 {
            let indices = groups[priority] ?? []
            let order = indices.sorted { items[$0].growingPotential < items[$1].growingPotential }
            var remainingItemCount = order.count
            for index in order {
                let allocation = min(items[index].growingPotential, remainingSpace / CGFloat(remainingItemCount))
                result[index - items.startIndex].size += allocation
                remainingSpace -= allocation
                remainingItemCount -= 1
            }
        }
    }

    /// Keep division, clamping and subtraction in encounter order in both scoring and placement.
    private struct UniformGrowth {
        let growth: CGFloat
        var count: Int
        var remainingSpace: CGFloat

        mutating func nextAllocation() -> CGFloat {
            let allocation = min(growth, remainingSpace / CGFloat(count))
            remainingSpace -= allocation
            count -= 1
            return allocation
        }
    }
}

@usableFromInline
typealias SizedLine = (items: WrappedLine, remainingSpace: CGFloat)
