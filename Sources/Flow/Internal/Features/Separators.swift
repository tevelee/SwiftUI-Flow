/// A pure description of how separators relate to content items, derived once per cache refresh from
/// the subviews' ``FlowSubviewRole`` tags.
///
/// Each gap between adjacent content items selects one item separator and one line separator.
/// An explicit ``ItemSeparator`` replaces the automatic item separator; the last override wins,
/// and an empty override selects no item separator. At most one separator is drawn: the item separator when the two
/// items share a line, the line separator when the layout breaks between them. Edges have no gap, so
/// separators never appear before the first or after the last item.
///
/// The plan owns separator selection for both ordinary gaps and the overflow gap. Fitting and
/// materialization ask the same interface, with the current retained predecessor after trimming.
@usableFromInline
struct SeparatorPlan {
    /// All structural tags for one subview share its position in the input collection.
    struct Subview {
        var role: FlowSubviewRole
        var origin: FlowSubviewOrigin = .flowContent
    }

    private struct Gap {
        var itemSeparator: Int?
        var lineSeparator: Int?
        /// A gap is eligible only between two real items. Gaps touching a manual line-break marker
        /// (``LineBreak``) are skipped so separators never collide with an explicit break.
        var isEligible: Bool
    }

    /// Subview indices of content and explicit break markers, kept in line-breaking order.
    let contentIndices: [Int]
    /// Subview indices of every separator, including explicit overrides, used to hide the ones left unused.
    let separatorIndices: [Int]
    /// `gaps[p]` describes the gap *before* content position `p`. `gaps[0]` (if present) is `nil`.
    private let gaps: [Gap?]
    private let positionByContentIndex: [Int: Int]
    private let lineBreakIndices: Set<Int>
    private let overflowIndex: Int?
    private let overflowOverride: (index: Int, isEmpty: Bool)?

    init(subviews: [Subview]) {
        var contentIndices: [Int] = []
        var separatorIndices: [Int] = []
        for index in subviews.indices {
            if !subviews[index].role.isSeparator {
                contentIndices.append(index)
            } else {
                separatorIndices.append(index)
            }
        }

        var gaps: [Gap?] = contentIndices.isEmpty ? [] : [nil]
        for position in contentIndices.indices.dropFirst() {
            let previous = contentIndices[position - 1]
            let current = contentIndices[position]
            var gap = Gap(
                itemSeparator: nil,
                lineSeparator: nil,
                isEligible: subviews[previous].role != .lineBreak && subviews[current].role != .lineBreak
            )
            var overrideIndex: Int?
            for between in (previous + 1) ..< current {
                switch subviews[between].role {
                    case .itemSeparator: gap.itemSeparator = gap.itemSeparator ?? between
                    case .itemSeparatorOverride: overrideIndex = between
                    case .lineSeparator: gap.lineSeparator = gap.lineSeparator ?? between
                    case .content, .lineBreak: break
                }
            }
            if let overrideIndex, case .itemSeparatorOverride(let isEmpty) = subviews[overrideIndex].role {
                gap.itemSeparator = isEmpty ? nil : overrideIndex
                // Anchor the line boundary after the override so the interleaver can identify it.
                gap.lineSeparator = ((overrideIndex + 1) ..< current).first { subviews[$0].role == .lineSeparator } ?? gap.lineSeparator
            }
            gaps.append(gap.itemSeparator != nil || gap.lineSeparator != nil ? gap : nil)
        }

        self.contentIndices = contentIndices
        self.separatorIndices = separatorIndices
        self.gaps = gaps
        positionByContentIndex = Dictionary(
            uniqueKeysWithValues: contentIndices.enumerated().map { ($1, $0) }
        )
        let overflowIndex = subviews.indices.last.flatMap { subviews[$0].origin == .overflowBuilder ? $0 : nil }
        self.overflowIndex = overflowIndex
        // Line-break lookup is only needed when selecting an overflow gap.
        lineBreakIndices = overflowIndex == nil ? [] : Set(subviews.indices.filter { subviews[$0].role == .lineBreak })
        var overflowOverride: (index: Int, isEmpty: Bool)?
        if let overflowIndex {
            for index in (0 ..< overflowIndex).reversed() {
                guard subviews[index].origin == .overflowBuilder else { break }
                switch subviews[index].role {
                    case .itemSeparatorOverride(let isEmpty):
                        overflowOverride = (index, isEmpty)
                    case .content, .lineBreak:
                        break
                    case .itemSeparator, .lineSeparator:
                        continue
                }
                break
            }
        }
        self.overflowOverride = overflowOverride
    }

    /// Selects one item separator for both breadth reservation and visible materialization.
    /// Only overflow-builder markers override the inherited gap after the retained content item.
    func itemSeparator(before current: Int, after previous: Int) -> Int? {
        if current == overflowIndex {
            guard !lineBreakIndices.contains(previous) else { return nil }
            if let overflowOverride {
                return overflowOverride.isEmpty ? nil : overflowOverride.index
            }
            return positionByContentIndex[previous].flatMap { gap(before: $0 + 1)?.itemSeparator }
        }
        guard let position = positionByContentIndex[current],
            let gap = gap(before: position), gap.isEligible
        else { return nil }
        return gap.itemSeparator
    }

    /// Selects the eligible line separator before the line starting with this content item.
    func lineSeparator(before contentIndex: Int) -> Int? {
        guard let position = positionByContentIndex[contentIndex],
            let gap = gap(before: position), gap.isEligible
        else { return nil }
        return gap.lineSeparator
    }

    /// The gap immediately before content position `position`, if any.
    private func gap(before position: Int) -> Gap? {
        guard gaps.indices.contains(position) else { return nil }
        return gaps[position]
    }
}
