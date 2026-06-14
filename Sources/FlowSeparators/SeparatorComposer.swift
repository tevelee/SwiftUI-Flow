import Flow
import SwiftUI

// MARK: - Composer

/// The ``FlowComposer`` the separator modifiers register into the composition chain. It reads the
/// separator environment, contributes a ``SeparatorFeature`` to the engine, and interleaves separator
/// subviews into the content so the layout can measure and place them as siblings of the content.
///
/// Runs at a higher ``priority`` than line capping (``FlowLineLimit``), so capping's output-seam
/// truncation happens before separators are materialized, and so this transform sits *inside* any
/// overflow indicator — keeping that indicator the last subview the layout sees.
struct SeparatorComposer: FlowComposer {
    var priority: Int { 1 }

    @MainActor
    func makeBody(
        content: AnyView,
        next: @escaping @MainActor ([any FlowLayoutFeature], AnyView) -> AnyView
    ) -> AnyView {
        AnyView(SeparatorComposition(content: content, next: next))
    }
}

// MARK: - Separator injection

/// Composes flow content with separator subviews that must be siblings in one layout pass.
///
/// Item separators are anchored to the content pair they sit between; line separators are anchored to
/// the *visual* line boundary they fill (reported back by the layout), so a divider stays the same view
/// as content rewraps through it instead of jumping. Enumeration uses `Group(subviews:)` where available
/// and falls back to `_VariadicView` on earlier systems.
private struct SeparatorComposition: View {
    let content: AnyView
    let next: @MainActor ([any FlowLayoutFeature], AnyView) -> AnyView

    @Environment(\._flowItemSeparator) private var itemSeparator
    @Environment(\._flowLineSeparator) private var lineSeparator
    @StateObject private var lineStructure = Reported<[Int]>([])

    var body: some View {
        let features: [any FlowLayoutFeature] =
            (itemSeparator != nil || lineSeparator != nil) ? [SeparatorFeature()] : []
        // Line separators need to know the line structure; item separators do not, so only pay for the
        // reporter when line separators are configured.
        let reporter: (@Sendable ([Int]) -> Void)? = lineSeparator == nil ? nil : lineStructure.reporter()
        return next(features, AnyView(interleaved(reporter: reporter)))
    }

    @ViewBuilder
    private func interleaved(reporter: (@Sendable ([Int]) -> Void)?) -> some View {
        // Capture env values into locals so they're stable for the view-update scope and can be
        // referenced safely inside @ViewBuilder and Group(subviews:) closures.
        let itemSep = itemSeparator
        let lineSep = lineSeparator
        // Reset the composition chain (and this feature's environment) so nested flows don't inherit it.
        let tagged =
            content
            .layoutValue(key: LineStructureReporterKey.self, value: reporter)
            .environment(\.flowComposers, [])
            .environment(\._flowItemSeparator, nil)
            .environment(\._flowLineSeparator, nil)
        if itemSep != nil || lineSep != nil {
            // `Group(subviews:)` ships in the Xcode 16 SDK (Swift 6+); earlier toolchains fall back to the
            // `_VariadicView` SPI, which behaves the same back to the minimum deployment targets.
            #if swift(>=6.0)
                if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                    Group(subviews: tagged) { subviews in
                        interleavedContent(
                            subviews,
                            itemSeparator: itemSep,
                            lineSeparator: lineSep,
                            lineOf: lineStructure.value
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
            SeparatorInterleaver(itemSeparator: itemSeparator, lineSeparator: lineSeparator, lineOf: lineStructure.value)
        ) {
            tagged
        }
    }
}

/// The shared body of both interleaving paths (``Group(subviews:)`` and the ``_VariadicView``
/// fallback): emit each element followed by the separators for the gap after it, except after the last.
/// `lineOf` is the layout-reported line structure used to give each separator a stable visual identity.
@ViewBuilder
private func interleavedContent<Elements: RandomAccessCollection>(
    _ elements: Elements,
    itemSeparator: (() -> AnyView)?,
    lineSeparator: (() -> AnyView)?,
    lineOf: [Int]
) -> some View where Elements.Element: View & Identifiable {
    let last = elements.count - 1
    let positionsInLine = linePositions(for: lineOf)
    ForEach(Array(elements.enumerated()), id: \.element.id) { item in
        item.element
        if item.offset < last {
            separators(
                afterIndex: item.offset,
                itemSeparator: itemSeparator,
                lineSeparator: lineSeparator,
                lineOf: lineOf,
                positionsInLine: positionsInLine
            )
        }
    }
}

/// Emits the separators that follow the content item at `index`: item and line separators live in
/// every configured gap so the layout can decide which one is visible after line breaking.
@ViewBuilder
private func separators(
    afterIndex index: Int,
    itemSeparator: (() -> AnyView)?,
    lineSeparator: (() -> AnyView)?,
    lineOf: [Int],
    positionsInLine: [Int]
) -> some View {
    if let itemSeparator {
        // An item separator lives in every gap so its breadth always factors into line breaking, and the
        // layout shows or parks it as content rewraps. Identity is the (line, positionInLine) of the item
        // before the gap — positional, so it survives rewraps. Disabling animation makes it snap to its
        // place (or out of view) instead of sliding to/from the off-screen park position, while it still
        // tracks its row frame-to-frame during a live resize.
        itemSeparator()
            .id(itemSeparatorIdentity(afterPosition: index, lineOf: lineOf, positionsInLine: positionsInLine))
            .layoutValue(key: SeparatorRoleLayoutValueKey.self, value: .itemSeparator)
            .layoutValue(key: IsAuxiliaryLayoutValueKey.self, value: true)
    }
    if let lineSeparator {
        lineSeparator()
            .id(lineSeparatorIdentity(afterPosition: index, lineOf: lineOf))
            .layoutValue(key: SeparatorRoleLayoutValueKey.self, value: .lineSeparator)
            .layoutValue(key: IsAuxiliaryLayoutValueKey.self, value: true)
    }
}

/// Whether the content wraps onto a new line between item `index` and the next, per the reported
/// structure. Items absent from the visible output carry `SeparatorLayout.hiddenLineSentinel` (< 0);
/// they are never a boundary so that no spurious separator is injected before a hidden item.
private func isLineBoundary(after index: Int, lineOf: [Int]) -> Bool {
    guard lineOf.indices.contains(index + 1) else { return false }
    let current = lineOf[index]
    let next = lineOf[index + 1]
    return current >= 0 && next >= 0 && current != next
}

/// Pre-computes the position-within-line for every item in O(n), so identity lookups are O(1).
/// Items with a negative line (hidden sentinel) get position 0 — they're parked anyway.
private func linePositions(for lineOf: [Int]) -> [Int] {
    var result = [Int](repeating: 0, count: lineOf.count)
    var countPerLine = [Int: Int]()
    for i in lineOf.indices {
        let line = lineOf[i]
        result[i] = countPerLine[line, default: 0]
        countPerLine[line, default: 0] += 1
    }
    return result
}

/// Positional identity for the item separator after content position `index`.
/// Uses (line, positionInLine) derived from the reported line structure so the separator's SwiftUI
/// identity matches its visual slot — not the element it follows — and survives rewraps stably.
/// Falls back to (0, index) on the bootstrap frame before the layout has reported anything.
private func itemSeparatorIdentity(afterPosition index: Int, lineOf: [Int], positionsInLine: [Int]) -> ItemSeparatorIdentity {
    if lineOf.indices.contains(index), lineOf[index] >= 0 {
        return ItemSeparatorIdentity(line: lineOf[index], positionInLine: positionsInLine[index])
    }
    return ItemSeparatorIdentity(line: 0, positionInLine: index)
}

/// Positional identity for the line separator after content position `index`.
/// Visible line separators use their visual boundary once line structure is known; hidden/bootstrap
/// placeholders use the gap position so every gap contributes a distinct separator subview.
private func lineSeparatorIdentity(afterPosition index: Int, lineOf: [Int]) -> LineSeparatorIdentity {
    if isLineBoundary(after: index, lineOf: lineOf) {
        return LineSeparatorIdentity(boundary: lineOf[index + 1], gap: nil)
    }
    return LineSeparatorIdentity(boundary: nil, gap: index)
}

private struct ItemSeparatorIdentity: Hashable {
    let line: Int
    let positionInLine: Int
}

private struct LineSeparatorIdentity: Hashable {
    let boundary: Int?
    let gap: Int?
}

/// `_VariadicView` fallback used before `Group(subviews:)` is available.
struct SeparatorInterleaver: _VariadicView.MultiViewRoot {
    var itemSeparator: (() -> AnyView)?
    var lineSeparator: (() -> AnyView)?
    var lineOf: [Int]

    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        interleavedContent(children, itemSeparator: itemSeparator, lineSeparator: lineSeparator, lineOf: lineOf)
    }
}
