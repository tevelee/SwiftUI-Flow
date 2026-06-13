import SwiftUI

/// The role a subview plays inside a flow that has separators configured.
///
/// ``HFlow`` / ``VFlow`` inject separator views between adjacent content items (never at the
/// edges) and tag them with this value. The layout reads the tag to decide which separators take
/// part in line breaking, which are drawn in-line, which are drawn between lines, and which are
/// dropped. When no subview carries a non-`content` role the entire separator pipeline is skipped,
/// so flows without separators behave exactly as before.
@usableFromInline
enum SeparatorRole: Sendable, Hashable {
    /// A regular content item supplied by the caller.
    case content
    /// A separator drawn between two items on the same line.
    case itemSeparator
    /// A separator drawn between two lines.
    case lineSeparator

    /// Whether this role is a separator (as opposed to content). Used from `@inlinable` cache code,
    /// so it avoids relying on the synthesized `Equatable` conformance there.
    @usableFromInline
    var isSeparator: Bool {
        switch self {
            case .content: false
            case .itemSeparator, .lineSeparator: true
        }
    }
}

@usableFromInline
struct SeparatorRoleLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: SeparatorRole = .content
}

/// Reporter the layout calls (once per placement pass) with the line index of every content item, so
/// the view layer can give line separators identity based on their *visual* position (which line
/// boundary they sit on) rather than the content around them. Reporting is one-directional — line
/// separators do not affect line breaking — so the feedback converges in a single pass.
@usableFromInline
struct LineStructureReporterKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: (@Sendable ([Int]) -> Void)? = nil
}

/// A pure description of how separators relate to content items, derived once per layout pass from
/// the subviews' ``SeparatorRole`` tags.
///
/// The injected subview order is always `content, [itemSep], [lineSep], content, …`, i.e. each
/// *gap* between two adjacent content items owns up to one item separator and up to one line
/// separator. At most one of the two is ever drawn for a given gap: the item separator when the two
/// items share a line, the line separator when the layout breaks between them. Edges have no gap, so
/// separators never appear before the first or after the last item.
///
/// The plan only computes structure (which subview index belongs to which gap and whether the gap is
/// eligible). ``FlowLayout`` decides — based on the actual line breaking — which side of each gap to
/// materialize, keeping all the line-dependent logic in one place.
struct SeparatorPlan {
    struct Gap: Equatable {
        var itemSeparator: Int?
        var lineSeparator: Int?
        /// A gap is eligible only between two real items. Gaps touching a manual line-break marker
        /// (``LineBreak``) are skipped so separators never collide with an explicit break.
        var isEligible: Bool
    }

    /// Subview indices of content items, in order.
    let contentIndices: [Int]
    /// Subview indices of every separator (item or line), used to hide the ones left unused.
    let separatorIndices: [Int]
    /// `gaps[p]` describes the gap *before* content position `p`. `gaps[0]` (if present) is `nil`.
    private let gaps: [Gap?]
    private let positionByContentIndex: [Int: Int]

    init(roles: [SeparatorRole], isLineBreak: [Bool]) {
        var contentIndices: [Int] = []
        var separatorIndices: [Int] = []
        for index in roles.indices {
            if roles[index] == .content {
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
                isEligible: !isLineBreak[previous] && !isLineBreak[current]
            )
            for between in (previous + 1) ..< current {
                switch roles[between] {
                    case .itemSeparator: gap.itemSeparator = gap.itemSeparator ?? between
                    case .lineSeparator: gap.lineSeparator = gap.lineSeparator ?? between
                    case .content: break
                }
            }
            gaps.append(gap.itemSeparator != nil || gap.lineSeparator != nil ? gap : nil)
        }

        self.contentIndices = contentIndices
        self.separatorIndices = separatorIndices
        self.gaps = gaps
        positionByContentIndex = Dictionary(
            uniqueKeysWithValues: contentIndices.enumerated().map { ($1, $0) }
        )
    }

    /// The content position (index into ``contentIndices``) of a given subview index, if it is content.
    func position(ofContentIndex index: Int) -> Int? {
        positionByContentIndex[index]
    }

    /// The gap immediately before content position `position`, if any.
    func gap(before position: Int) -> Gap? {
        guard gaps.indices.contains(position) else { return nil }
        return gaps[position]
    }
}
