import CoreFoundation
import SwiftUI

struct FlowLayout {
    let axis: Axis
    var itemSpacing: CGFloat?
    var lineSpacing: CGFloat?
    var reversedBreadth: Bool = false
    var reversedDepth: Bool = false
    let align: (Dimensions) -> CGFloat

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var spacing: CGFloat

        private init(_ item: T,
                     size: Size,
                     spacing: CGFloat = 0) {
            self.item = item
            self.size = size
            self.spacing = spacing
        }

        init(_ item: some Subview, size: Size) where T == [ItemWithSpacing<Subview>] {
            self.init([.init(item, size: size)], size: size)
        }

        mutating func append(_ item: some Subview,
                             size: Size,
                             spacing: CGFloat)
        where T == [ItemWithSpacing<Subview>] {
            self.item.append(.init(item, size: size, spacing: spacing))
            self.size = Size(breadth: self.size.breadth + spacing + size.breadth, depth: max(self.size.depth, size.depth))
        }
    }

    private typealias Line = [ItemWithSpacing<Subview>]
    private typealias Lines = [ItemWithSpacing<Line>]

    func sizeThatFits(proposal proposedSize: ProposedViewSize,
                      subviews: some Subviews) -> CGSize {
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
                       subviews: some Subviews) {
        guard !subviews.isEmpty else { return }

        var bounds = bounds
        if reversedBreadth {
            bounds.reverseOrigin(along: axis)
        }
        if reversedDepth {
            bounds.reverseOrigin(along: axis.perpendicular)
        }
        var target = bounds.origin.size(on: axis)
        let originalBreadth = target.breadth
        let lines = calculateLayout(in: proposal, of: subviews)
        for line in lines {
            if reversedDepth {
                target.depth -= line.size.depth + line.spacing
            } else {
                target.depth += line.spacing
            }
            for item in line.item {
                if reversedBreadth {
                    target.breadth -= item.size.breadth + item.spacing
                } else {
                    target.breadth += item.spacing
                }
                alignAndPlace(item, in: line, at: target)
                if !reversedBreadth {
                    target.breadth += item.size.breadth
                }
            }
            if !reversedDepth {
                target.depth += line.size.depth
            }
            target.breadth = originalBreadth
        }
    }

    private func alignAndPlace(_ item: Line.Element,
                               in line: Lines.Element,
                               at placement: Size) {
        var placement = placement
        let proposedSize = ProposedViewSize(size: Size(breadth: item.size.breadth, depth: line.size.depth), axis: axis)
        let depth = item.size.depth
        if depth > 0 {
            placement.depth += (align(item.item.dimensions(proposedSize)) / depth) * (line.size.depth - depth)
        }
        item.item.place(at: .init(size: placement, axis: axis), anchor: .topLeading, proposal: proposedSize)
    }

    private func calculateLayout(in proposedSize: ProposedViewSize,
                                 of subviews: some Subviews) -> Lines {
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

    private func itemSpacing<S: Subviews>(toPrevious index: S.Index,
                                          subviews: S) -> CGFloat {
        guard index != subviews.startIndex else { return 0 }
        return self.itemSpacing ?? subviews[index.advanced(by: -1)].spacing.distance(to: subviews[index].spacing, along: axis)
    }
}

extension FlowLayout {
    static func vertical(alignment: HorizontalAlignment,
                         itemSpacing: CGFloat?,
                         lineSpacing: CGFloat?) -> FlowLayout {
        .init(axis: .vertical,
              itemSpacing: itemSpacing,
              lineSpacing: lineSpacing) {
            $0[alignment]
        }
    }

    static func horizontal(alignment: VerticalAlignment,
                           itemSpacing: CGFloat?,
                           lineSpacing: CGFloat?) -> FlowLayout {
        .init(axis: .horizontal,
              itemSpacing: itemSpacing,
              lineSpacing: lineSpacing) {
            $0[alignment]
        }
    }
}

protocol Subviews: RandomAccessCollection where Element: Subview, Index == Int {}
extension LayoutSubviews: Subviews {}

protocol Subview {
    var spacing: ViewSpacing { get }
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func dimensions(_ proposal: ProposedViewSize) -> Dimensions
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
}
extension LayoutSubview: Subview {
    func dimensions(_ proposal: ProposedViewSize) -> Dimensions {
        dimensions(in: proposal)
    }
}

protocol Dimensions {
    subscript(guide: HorizontalAlignment) -> CGFloat { get }
    subscript(guide: VerticalAlignment) -> CGFloat { get }
}
extension ViewDimensions: Dimensions {}

extension FlowLayout: Layout {
    func sizeThatFits(proposal proposedSize: ProposedViewSize,
                      subviews: LayoutSubviews,
                      cache: inout ()) -> CGSize {
        sizeThatFits(proposal: proposedSize, subviews: subviews)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: LayoutSubviews,
                       cache: inout ()) {
        placeSubviews(in: bounds, proposal: proposal, subviews: subviews)
    }
}

private extension CGRect {
    mutating func reverseOrigin(along axis: Axis) {
        switch axis {
            case .horizontal:
                origin.x = maxX
            case .vertical:
                origin.y = maxY
        }
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
