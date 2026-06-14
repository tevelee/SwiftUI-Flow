import Flow
import SwiftUI

// MARK: - Composer

/// The ``FlowComposer`` the `.maxLines` modifiers register into the composition chain. It reads the
/// line-limit environment, contributes a ``LineCap`` feature to the engine, and — when an overflow
/// builder is set — appends the overflow indicator as a sibling of the content so the layout can
/// measure and place it alongside everything else.
///
/// Runs at a lower ``priority`` than separators (``FlowSeparators``), so ``LineCap`` runs *first* in the
/// engine (truncating lines before separators are materialized) and its overflow indicator is appended
/// *outside* any separator interleaving — landing as the last subview, where ``LineCap`` expects it.
struct LineLimitComposer: FlowComposer {
    var priority: Int { 0 }

    @MainActor
    func makeBody(
        content: AnyView,
        next: @escaping @MainActor ([any FlowLayoutFeature], AnyView) -> AnyView
    ) -> AnyView {
        AnyView(LineLimitComposition(content: content, next: next))
    }
}

/// Appends the overflow indicator (if any) as a sibling of the capped content. The indicator is tagged
/// so ``LineCap`` keeps it out of line breaking and places it on the last visible line, reporting how
/// many items the cap hid back through the `@StateObject` reporter held here.
private struct LineLimitComposition: View {
    let content: AnyView
    let next: @MainActor ([any FlowLayoutFeature], AnyView) -> AnyView

    @Environment(\.maxLines) private var maxLines
    @Environment(\._flowOverflowBuilder) private var overflowBuilder
    @StateObject private var overflowCount = Reported(0)

    var body: some View {
        let features: [any FlowLayoutFeature] = maxLines.map { [LineCap(maxLines: $0)] } ?? []
        return next(features, AnyView(composed))
    }

    @ViewBuilder
    private var composed: some View {
        // Reset the composition chain (and this feature's environment) so nested flows don't inherit it.
        let tagged =
            content
            .environment(\.flowComposers, [])
            .environment(\.maxLines, nil)
            .environment(\._flowOverflowBuilder, nil)
        if let overflowBuilder {
            tagged
            overflowBuilder(overflowCount.value)
                .overflowIndicator(reporter: overflowCount.reporter())
        } else {
            tagged
        }
    }
}
