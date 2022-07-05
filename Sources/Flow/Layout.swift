import CoreFoundation
import SwiftUI

struct _FlowLayout: Layout {
    let axis: Axis
    let itemSpacing: CGFloat?
    let lineSpacing: CGFloat?
    let align: (ViewDimensions) -> CGFloat

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var spacing: CGFloat

        private init(_ item: T, size: Size, spacing: CGFloat = 0) {
            self.item = item
            self.size = size
            self.spacing = spacing
        }

        init(_ item: LayoutSubview, size: Size) where T == [ItemWithSpacing<LayoutSubview>] {
            self.init([.init(item, size: size)], size: size)
        }

        mutating func append(_ item: LayoutSubview, size: Size, spacing: CGFloat) where T == [ItemWithSpacing<LayoutSubview>] {
            self.item.append(.init(item, size: size, spacing: spacing))
            self.size = Size(breadth: self.size.breadth + spacing + size.breadth, depth: max(self.size.depth, size.depth))
        }
    }

    private typealias Line = [ItemWithSpacing<LayoutSubview>]
    private typealias Lines = [ItemWithSpacing<Line>]

    func sizeThatFits(proposal proposedSize: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let lines = calculateLayout(in: proposedSize, of: subviews)
        let spacings = lines.map(\.spacing).reduce(into: 0, +=)
        let size = lines
            .map(\.size)
            .reduce(.zero, breadth: max, depth: +)
            .adding(spacings, on: .vertical)
        return CGSize(size: size, axis: axis)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        guard !subviews.isEmpty else { return }

        var target = bounds.origin.size(on: axis)
        let originalBreadth = target.breadth
        let lines = calculateLayout(in: proposal, of: subviews)
        for line in lines {
            target.depth += line.spacing
            for item in line.item {
                target.breadth += item.spacing
                let proposal = ProposedViewSize(size: Size(breadth: item.size.breadth, depth: line.size.depth), axis: axis)
                var placement = target
                if item.size.depth > 0 {
                    placement.depth += (align(item.item.dimensions(in: proposal)) / item.size.depth) * (line.size.depth - item.size.depth)
                }
                item.item.place(at: .init(size: placement, axis: axis), proposal: proposal)
                target.breadth += item.size.breadth
            }
            target.depth += line.size.depth
            target.breadth = originalBreadth
        }
    }

    private func calculateLayout(in proposedSize: ProposedViewSize, of subviews: Subviews) -> Lines {
        var lines: Lines = []
        let proposedBreadth = proposedSize.replacingUnspecifiedDimensions().value(on: axis)
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(proposedSize).size(on: axis)
            if let lastIndex = lines.indices.last {
                let spacing = self.itemSpacing(toPrevious: index, subviews: subviews)
                let additionalBreadth = spacing + size.breadth
                if lines[lastIndex].size.breadth + additionalBreadth <= proposedBreadth {
                    lines[lastIndex].append(subview, size: size, spacing: spacing)
                    continue
                }
            }
            lines.append(.init(subview, size: size))
        }
        // adjust spacings on the perpendicular axis
        let lineSpacings = lines.map { line in
            line.item.reduce(into: ViewSpacing()) { $0.formUnion($1.item.spacing) }
        }
        for index in lines.indices.dropFirst() {
            let spacing = self.lineSpacing ?? lineSpacings[index].distance(to: lineSpacings[index.advanced(by: -1)], along: axis.perpendicular)
            lines[index].spacing = spacing
        }
        return lines
    }

    private func itemSpacing(toPrevious index: Subviews.Index, subviews: Subviews) -> CGFloat {
        guard index != subviews.startIndex else { return 0 }
        return self.itemSpacing ?? subviews[index.advanced(by: -1)].spacing.distance(to: subviews[index].spacing, along: axis)
    }
}

private extension Array where Element == Size {
    func reduce(_ initial: Size,
                breadth: (CGFloat, CGFloat) -> CGFloat,
                depth: (CGFloat, CGFloat) -> CGFloat) -> Size {
        reduce(initial) { result, size in
            Size(breadth: breadth(result.breadth, size.breadth),
                 depth: depth(result.depth,  size.depth))
        }
    }
}
