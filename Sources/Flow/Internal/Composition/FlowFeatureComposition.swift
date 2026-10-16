import SwiftUI

// MARK: - Feature composition

/// (Internal.) Composes flow content with feature-generated subviews that must be siblings in one layout pass.
/// Created by `HFlow.body` / `VFlow.body` when separator injection is configured.
///
/// Item separators live in content gaps. Line separators use a pool keyed by visual boundary,
/// so a divider keeps its state when resizing moves that boundary to another content gap.
/// Enumeration uses `Group(subviews:)` where available
/// and falls back to `_VariadicView` on earlier systems. If line capping also supplies an overflow
/// indicator, it is appended here so the layout can measure and place all generated children together.
@usableFromInline
struct _FlowFeatureComposition<Content: View>: View {  // swiftlint:disable:this type_name
    @usableFromInline
    let layout: AnyLayout
    @usableFromInline
    let content: Content

    @Environment(\.flexibility) private var flexibility
    @Environment(\._flowItemSeparator) private var itemSeparator
    @Environment(\._flowLineSeparator) private var lineSeparator
    @Environment(\._flowOverflowBuilder) private var overflowBuilder
    @StateObject private var report = LayoutReportState(FlowLayoutReport())

    @usableFromInline
    init(layout: AnyLayout, content: Content) {
        self.layout = layout
        self.content = content
    }

    @usableFromInline
    var body: some View {
        report.flowLayout(layout) { value in
            interleaved()
            if let overflowBuilder {
                overflowBuilder(value.overflowCount)
                    .overflowIndicator()
            }
        }
    }

    @ViewBuilder
    private func interleaved() -> some View {
        // Capture env values into locals so they're stable for the view-update scope and can be
        // referenced safely inside @ViewBuilder and Group(subviews:) closures.
        let itemSep = itemSeparator
        let lineSep = lineSeparator
        let tagged =
            content
            .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
            ._trait(FlexibilityLayoutValueKey.self, flexibility)
            .environment(\.maxLines, nil)
            .environment(\._flowItemSeparator, nil)
            .environment(\._flowLineSeparator, nil)
            .environment(\._flowOverflowBuilder, nil)
        if itemSep != nil || lineSep != nil {
            // `Group(subviews:)` ships in the Xcode 16 SDK (Swift 6+); earlier toolchains fall back to the
            // `_VariadicView` SPI, which behaves the same back to the minimum deployment targets.
            #if swift(>=6.0)
                if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                    Group(subviews: tagged) { subviews in
                        interleavedContent(
                            subviews,
                            itemSeparator: itemSep,
                            lineSeparator: lineSep
                        )
                    }
                } else {
                    variadicInterleaved(tagged, itemSeparator: itemSep, lineSeparator: lineSep)
                }
            #else
                variadicInterleaved(tagged, itemSeparator: itemSep, lineSeparator: lineSep)
            #endif
        } else {
            tagged
        }
    }

    private func variadicInterleaved(
        _ tagged: some View,
        itemSeparator: (() -> AnyView)?,
        lineSeparator: (() -> AnyView)?
    ) -> some View {
        _VariadicView.Tree(
            SeparatorInterleaver(itemSeparator: itemSeparator, lineSeparator: lineSeparator)
        ) {
            tagged
        }
    }
}

// MARK: - Separator injection

/// The shared body of both interleaving paths (``Group(subviews:)`` and the ``_VariadicView``
/// fallback): emit each element followed by the separators for the gap after it, except after the last.
/// Item separators belong to source pairs; the separate line-separator pool belongs to visual boundaries.
@ViewBuilder
private func interleavedContent<Elements: RandomAccessCollection>(
    _ elements: Elements,
    itemSeparator: (() -> AnyView)?,
    lineSeparator: (() -> AnyView)?,
    subviewRole: ((Elements.Element) -> FlowSubviewRole)? = nil
) -> some View where Elements.Element: View & Identifiable {
    let last = elements.count - 1
    ForEach(Array(elements.enumerated()), id: \.element.id) { item in
        if let subviewRole {
            // Legacy subview proxies preserve traits but need their layout role restored.
            item.element.layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: subviewRole(item.element))
        } else {
            item.element
        }
        if item.offset < last, let itemSeparator {
            // The parent ForEach keeps this gap with its preceding content item.
            itemSeparator()
                .layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: .itemSeparator)
                ._trait(FlowSubviewRoleLayoutValueKey.self, .itemSeparator)
        }
    }
    // Reserve enough slots for any wrapping without creating new separators on resize.
    if let lineSeparator {
        ForEach(0 ..< max(0, last), id: \.self) { boundary in
            lineSeparator()
                .layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: .pooledLineSeparator(boundary))
                ._trait(FlowSubviewRoleLayoutValueKey.self, .pooledLineSeparator(boundary))
        }
    }
}

/// `_VariadicView` fallback used before `Group(subviews:)` is available.
struct SeparatorInterleaver: _VariadicView.MultiViewRoot {
    var itemSeparator: (() -> AnyView)?
    var lineSeparator: (() -> AnyView)?

    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        interleavedContent(
            children,
            itemSeparator: itemSeparator,
            lineSeparator: lineSeparator,
            subviewRole: { $0[FlowSubviewRoleLayoutValueKey.self] }
        )
    }
}
