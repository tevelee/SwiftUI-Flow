import SwiftUI

/// The structural role of a subview in a flow. Content and explicit line breaks enter line
/// breaking; separators are folded into content spacing and materialized after wrapping.
/// Overflow ownership and the `startInNewLine` modifier are independent of this role.
@usableFromInline
enum FlowSubviewRole: Sendable, Hashable {
    /// A regular content item supplied by the caller.
    case content
    /// A zero-size marker that explicitly ends the preceding line.
    case lineBreak
    /// A separator drawn between two items on the same line.
    case itemSeparator
    /// A caller-supplied boundary override. An empty override keeps ordinary item spacing.
    case itemSeparatorOverride(isEmpty: Bool)
    /// A separator drawn between two lines.
    case lineSeparator
    /// A line separator anchored to a visual boundary, independently of content gaps.
    case pooledLineSeparator(Int)

    /// Whether this role participates in separator handling. Used from `@inlinable` cache code,
    /// so it avoids relying on the synthesized `Equatable` conformance there.
    @usableFromInline
    var isSeparator: Bool {
        switch self {
            case .content, .lineBreak: false
            case .itemSeparator, .itemSeparatorOverride, .lineSeparator, .pooledLineSeparator: true
        }
    }
}

@usableFromInline
struct FlowSubviewRoleLayoutValueKey: LayoutValueKey, _ViewTraitKey {
    @usableFromInline
    static let defaultValue: FlowSubviewRole = .content
}

/// Ownership of a subview, independent of its structural role.
@usableFromInline
enum FlowSubviewOrigin: Sendable {
    case flowContent
    case overflowBuilder
}

@usableFromInline
struct FlowSubviewOriginLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: FlowSubviewOrigin = .flowContent
}
