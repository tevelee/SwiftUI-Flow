import CoreFoundation
import SwiftUI

// Pipeline phase — space distribution.
//
// Three passes run in sequence over the built geometry, each accumulating into the lines' / items'
// `leadingSpace`: justification stretches the gaps within a line, line spacing sets the gap before
// each line, and cross-axis alignment shifts each line as a whole. Order matters — alignment reads the
// per-line breadths that justification has already adjusted.

extension FlowLayout {
    func distributeJustifiedSpace(in lines: inout [LayoutLine], proposal: ProposedViewSize) {
        let availableSpace = proposal.value(on: axis)
        // Distributing leftover space is only meaningful when it's finite.
        guard justified, availableSpace.isFinite else { return }
        for (lineIndex, line) in lines.enumerated() {
            let items = line.items
            // Zero-size line-break markers get no share; justify across visible items.
            let visibleIndices = items.indices.filter { !items[$0].cache.layoutValues.isLineBreak }
            guard visibleIndices.count > 1 else { continue }
            let usedSpace = items.sum { $0.size.breadth + $0.leadingSpace }
            // Justification only ever stretches the gaps to fill leftover room. When a line's
            // measured content already meets or exceeds the available space (e.g. a subview
            // reports a larger size than it was proposed), there is nothing to distribute —
            // clamp at zero so we never pull items together into an overlap.
            let distributedSpace = max(0, (availableSpace - usedSpace) / Double(visibleIndices.count - 1))
            for itemIndex in visibleIndices.dropFirst() {
                lines[lineIndex].items[itemIndex].leadingSpace += distributedSpace
            }
        }
    }

    func applyLineSpacing(in lines: inout [LayoutLine]) {
        if let lineSpacing {
            for index in lines.indices.dropFirst() where !isLineBreakLine(lines[index]) {
                lines[index].leadingSpace = lineSpacing
            }
        } else {
            let lineSpacings = lines.map { line in
                line.items.reduce(into: ViewSpacing()) { $0.formUnion($1.cache.spacing) }
            }
            for (previous, index) in lines.indices.adjacentPairs() where !isLineBreakLine(lines[index]) {
                let spacing = lineSpacings[index].distance(to: lineSpacings[previous], along: axis.perpendicular)
                lines[index].leadingSpace = spacing
            }
        }
    }

    private func isLineBreakLine(_ line: LayoutLine) -> Bool {
        line.items.count == 1 && line.items[0].cache.layoutValues.isLineBreak
    }

    func applyCrossAxisAlignment(in lines: inout [LayoutLine]) {
        let lineBreadths = lines.map { $0.items.sum { $0.leadingSpace + $0.size.breadth } }
        let breadth = lineBreadths.max() ?? 0
        for index in lines.indices where !lines[index].items.isEmpty {
            lines[index].items[0].leadingSpace += leadingSpaceForAlignment(in: lines[index], lineSize: lineBreadths[index], breadth: breadth)
        }
    }

    private func leadingSpaceForAlignment(in line: LayoutLine, lineSize: CGFloat, breadth: CGFloat) -> CGFloat {
        guard let item = line.items.first(where: { $0.cache.ideal.breadth > 0 }) else { return 0 }
        let value = alignmentOnBreadth(item.subview.dimensions(.unspecified)) / item.cache.ideal.breadth
        let remainingSpace = breadth - lineSize
        let leadingSpace = value * remainingSpace
        // Skip a non-finite offset (e.g. unbounded item breadth).
        return leadingSpace.isFinite ? leadingSpace : 0
    }
}
