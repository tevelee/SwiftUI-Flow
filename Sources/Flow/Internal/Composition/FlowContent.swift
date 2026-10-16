import SwiftUI

/// Shared feature routing for the horizontal and vertical adapters. Plain content keeps its
/// concrete layout; separators and overflow use reported compositions.
@MainActor
@usableFromInline
@ViewBuilder
func flowContent<FlowLayoutType: Layout, Content: View>(
    layout: FlowLayoutType,
    content: Content,
    flexibility: FlexibilityBehavior,
    hasSeparators: Bool,
    overflowBuilder: ((Int) -> AnyView)?
) -> some View {
    if hasSeparators {
        _FlowFeatureComposition(layout: AnyLayout(layout), content: content)
    } else if let overflowBuilder {
        _FlowWithOverflow(layout: AnyLayout(layout), content: content, overflowBuilder: overflowBuilder)
    } else {
        layout {
            content
                .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
                .environment(\.maxLines, nil)
        }
    }
}
