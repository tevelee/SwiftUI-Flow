import SwiftUI

/// A custom separator between adjacent items in an ``HFlow`` or ``VFlow``.
///
/// Replaces the flow's automatic item separator at this boundary. The separator's size
/// affects wrapping, with item spacing on both sides, and it appears only between visible
/// items on the same line. Use `ItemSeparator { EmptyView() }` to omit a separator while
/// keeping ordinary item spacing. Consecutive separators use the last one.
///
/// Place the separator immediately before the overflow view in a `.maxLines(_:overflow:)`
/// builder to replace the inherited separator.
///
/// Explicit separators do not count as hidden items and do not replace line separators.
public struct ItemSeparator<Content: View>: View {
    private let content: Content

    /// Creates an explicit separator for this boundary.
    ///
    /// - Parameter content: The separator view. Multiple views overlap in a single layout item.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// The separator content, tagged for the flow's layout and subview enumeration.
    public var body: some View {
        let role = FlowSubviewRole.itemSeparatorOverride(isEmpty: Content.self == EmptyView.self)
        Group {
            if Content.self == EmptyView.self {
                // EmptyView contributes no layout child, so retain a zero-size boundary marker.
                Color.clear.frame(width: 0, height: 0)
            } else {
                ZStack { content }
            }
        }
        ._trait(FlowSubviewRoleLayoutValueKey.self, role)
        .layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: role)
    }
}
