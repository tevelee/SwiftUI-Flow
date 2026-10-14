import SwiftUI

/// Geometry parks hidden siblings, but accessibility and keyboard interaction need explicit
/// visibility. Enumerate the final sibling order so content, separators and overflow agree.
@MainActor
@ViewBuilder
func reportedFlowContent(_ content: some View, hidden: Set<Int>) -> some View {
    #if swift(>=6.0)
        if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
            Group(subviews: content) { children in
                ForEach(Array(children.enumerated()), id: \.element.id) { item in
                    item.element.modifier(ReportedVisibility(isHidden: hidden.contains(item.offset)))
                }
            }
        } else {
            legacyReportedFlowContent(content, hidden: hidden)
        }
    #else
        legacyReportedFlowContent(content, hidden: hidden)
    #endif
}

@MainActor
func legacyReportedFlowContent(_ content: some View, hidden: Set<Int>) -> some View {
    _VariadicView.Tree(ReportedContentRoot(hidden: hidden)) { content }
}

private struct ReportedVisibility: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        let interactive =
            content
            .allowsHitTesting(!isHidden)
            .disabled(isHidden)
        #if swift(>=6.0)
            if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                // A disabled modifier preserves the caller's own accessibilityHidden setting.
                interactive.accessibilityHidden(true, isEnabled: isHidden)
            } else {
                legacyAccessibility(interactive)
            }
        #else
            legacyAccessibility(interactive)
        #endif
    }

    private func legacyAccessibility(_ content: some View) -> some View {
        // On older systems, a separate accessibility group hides its subtree without replacing
        // the child's own visibility or duplicating rendered content and focus bindings.
        content.accessibilityElement(children: .contain).accessibilityHidden(isHidden)
    }
}

private struct ReportedContentRoot: _VariadicView.MultiViewRoot {
    let hidden: Set<Int>

    func body(children: _VariadicView.Children) -> some View {
        ForEach(Array(children.enumerated()), id: \.element.id) { item in
            // Legacy proxies can drop source layout values when modifiers are attached.
            item.element
                .layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: item.element[FlowSubviewRoleLayoutValueKey.self])
                .layoutValue(key: FlowSubviewOriginLayoutValueKey.self, value: item.element[FlowSubviewOriginLayoutValueKey.self])
                .layoutValue(key: FlexibilityLayoutValueKey.self, value: item.element[FlexibilityLayoutValueKey.self])
                .layoutValue(key: ShouldStartInNewLineLayoutValueKey.self, value: item.element[ShouldStartInNewLineLayoutValueKey.self])
                .modifier(ReportedVisibility(isHidden: hidden.contains(item.offset)))
        }
    }
}
