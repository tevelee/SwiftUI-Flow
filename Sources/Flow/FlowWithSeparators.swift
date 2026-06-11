import SwiftUI

// MARK: - Separator wrapper

/// Wraps a flow layout to draw separators between items and/or lines.
///
/// - Note: Do not use this type directly. Use ``HFlow/itemSeparator(_:)`` / ``HFlow/lineSeparator(_:)``
///   (or the ``VFlow`` equivalents) instead.
///
/// The wrapper enumerates the content's subviews and injects a separator into each gap, tagging it with
/// a ``SeparatorRole`` so the layout can fold item-separator breadth into line breaking and turn line
/// separators into their own lines — separators take part in sizing rather than being painted on top.
///
/// Item separators are anchored to the content pair they sit between; line separators are anchored to
/// the *visual* line boundary they fill (reported back by the layout), so a divider stays the same view
/// as content rewraps through it instead of jumping. Enumeration uses `Group(subviews:)` where available
/// and falls back to `_VariadicView` on earlier systems.
public struct _FlowWithSeparators<Content: View>: View {  // swiftlint:disable:this type_name
    let makeLayout: (Int?) -> AnyLayout
    let content: Content
    var itemSeparator: (() -> AnyView)?
    var lineSeparator: (() -> AnyView)?

    @Environment(\.flexibility) private var flexibility
    @Environment(\.maxLines) private var maxLines
    @StateObject private var state = SeparatorLineStructure()

    public var body: some View {
        let layout = makeLayout(maxLines)
        // Line separators need to know the line structure; item separators do not, so only pay for the
        // reporter when line separators are configured.
        let reporter: (@Sendable ([Int]) -> Void)? = lineSeparator == nil ? nil : lineStructureReporter(for: state)
        return layout {
            interleaved(reporter: reporter)
        }
    }

    @ViewBuilder
    private func interleaved(reporter: (@Sendable ([Int]) -> Void)?) -> some View {
        let tagged =
            content
            .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
            .layoutValue(key: LineStructureReporterKey.self, value: reporter)
            .environment(\.maxLines, nil)
        // `Group(subviews:)` ships in the Xcode 16 SDK (Swift 6+); earlier toolchains fall back to the
        // `_VariadicView` SPI, which behaves the same back to the minimum deployment targets.
        #if swift(>=6.0)
            if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                Group(subviews: tagged) { subviews in
                    let last = subviews.count - 1
                    let lineOf = state.lineOf
                    let positionsInLine = linePositions(for: lineOf)
                    ForEach(Array(subviews.enumerated()), id: \.element.id) { item in
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
            } else {
                variadicInterleaved(tagged)
            }
        #else
            variadicInterleaved(tagged)
        #endif
    }

    private func variadicInterleaved(_ tagged: some View) -> some View {
        _VariadicView.Tree(
            SeparatorInterleaver(itemSeparator: itemSeparator, lineSeparator: lineSeparator, lineOf: state.lineOf)
        ) {
            tagged
        }
    }

    func setting(itemSeparator: (() -> AnyView)?) -> Self {
        var copy = self
        copy.itemSeparator = itemSeparator
        return copy
    }

    func setting(lineSeparator: (() -> AnyView)?) -> Self {
        var copy = self
        copy.lineSeparator = lineSeparator
        return copy
    }
}

// MARK: - Reported line structure

/// Holds the line index of every content item, reported by the layout, so the view layer can identify
/// line separators by their visual position. A class so the `@StateObject` reference survives re-evaluations.
@MainActor
private final class SeparatorLineStructure: ObservableObject {
    @Published var lineOf: [Int] = []
}

/// Builds the reporter the layout calls with the line structure. The publish is deferred out of the
/// layout pass (mutating `@Published` during a view update is disallowed) and guarded so the one-shot
/// feedback settles instead of re-triggering. Mirrors the reporter pattern used by the overflow indicator.
private func lineStructureReporter(for state: SeparatorLineStructure) -> @Sendable ([Int]) -> Void {
    { lineOf in
        Task { @MainActor in
            if state.lineOf != lineOf { state.lineOf = lineOf }
        }
    }
}

// MARK: - Separator injection

/// Emits the separators that follow the content item at `index`: an item separator in every gap, plus a
/// line separator only where the layout reported a line break. Both are identified by their position in
/// the reported line structure so identity stays stable as items rewrap across lines.
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
    }
    if let lineSeparator, isLineBoundary(after: index, lineOf: lineOf) {
        lineSeparator()
            .id(LineSeparatorIdentity(boundary: lineOf[index + 1]))
            .layoutValue(key: SeparatorRoleLayoutValueKey.self, value: .lineSeparator)
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

private struct ItemSeparatorIdentity: Hashable {
    let line: Int
    let positionInLine: Int
}

private struct LineSeparatorIdentity: Hashable {
    let boundary: Int
}

/// `_VariadicView` fallback used before `Group(subviews:)` is available.
struct SeparatorInterleaver: _VariadicView.MultiViewRoot {
    var itemSeparator: (() -> AnyView)?
    var lineSeparator: (() -> AnyView)?
    var lineOf: [Int]

    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let last = children.count - 1
        let positionsInLine = linePositions(for: lineOf)
        ForEach(Array(children.enumerated()), id: \.element.id) { item in
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
}

// MARK: - Public modifiers

extension HFlow {
    /// Draws `separator` between adjacent items on the same row.
    ///
    /// The separator participates in layout: its width is taken into account when breaking rows, and
    /// its height contributes to the row's height. Separators appear only *between* items, never at the
    /// leading or trailing edge, and a gap that wraps onto a new row shows a line separator (if any)
    /// instead. Combine with ``lineSeparator(_:)`` to control both.
    ///
    /// ```swift
    /// HFlow {
    ///     ForEach(tags) { Text($0) }
    /// }
    /// .itemSeparator { Text("•").foregroundStyle(.secondary) }
    /// ```
    ///
    /// - Parameter separator: A view builder producing a single separator view.
    public func itemSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators<Content> {
        _FlowWithSeparators(
            makeLayout: { AnyLayout(layout.withMaxLines($0)) },
            content: content,
            itemSeparator: { AnyView(separator()) },
            lineSeparator: nil
        )
    }

    /// Draws `separator` between adjacent rows.
    ///
    /// The separator becomes its own line in the layout, so its height contributes to the overall
    /// height and the row spacing applies on both sides of it. Separators appear only *between* rows,
    /// never above the first or below the last. Combine with ``itemSeparator(_:)`` to control both.
    ///
    /// ```swift
    /// HFlow {
    ///     ForEach(tags) { Text($0) }
    /// }
    /// .lineSeparator { Divider() }
    /// ```
    ///
    /// - Parameter separator: A view builder producing a single separator view.
    public func lineSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators<Content> {
        _FlowWithSeparators(
            makeLayout: { AnyLayout(layout.withMaxLines($0)) },
            content: content,
            itemSeparator: nil,
            lineSeparator: { AnyView(separator()) }
        )
    }
}

extension VFlow {
    /// Draws `separator` between adjacent items in the same column.
    ///
    /// The separator participates in layout: its height is taken into account when breaking columns,
    /// and its width contributes to the column's width. Separators appear only *between* items, never
    /// at the top or bottom edge. Combine with ``lineSeparator(_:)`` to control both.
    ///
    /// - Parameter separator: A view builder producing a single separator view.
    public func itemSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators<Content> {
        _FlowWithSeparators(
            makeLayout: { AnyLayout(layout.withMaxLines($0)) },
            content: content,
            itemSeparator: { AnyView(separator()) },
            lineSeparator: nil
        )
    }

    /// Draws `separator` between adjacent columns.
    ///
    /// The separator becomes its own line in the layout, so its width contributes to the overall width
    /// and the column spacing applies on both sides of it. Separators appear only *between* columns,
    /// never before the first or after the last. Combine with ``itemSeparator(_:)`` to control both.
    ///
    /// - Parameter separator: A view builder producing a single separator view.
    public func lineSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators<Content> {
        _FlowWithSeparators(
            makeLayout: { AnyLayout(layout.withMaxLines($0)) },
            content: content,
            itemSeparator: nil,
            lineSeparator: { AnyView(separator()) }
        )
    }
}

extension _FlowWithSeparators {
    /// Adds (or replaces) the item separator drawn between adjacent items on the same line.
    /// See ``HFlow/itemSeparator(_:)``.
    public func itemSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators {
        setting(itemSeparator: { AnyView(separator()) })
    }

    /// Adds (or replaces) the line separator drawn between adjacent lines.
    /// See ``HFlow/lineSeparator(_:)``.
    public func lineSeparator<Separator: View>(
        @ViewBuilder _ separator: @escaping () -> Separator
    ) -> _FlowWithSeparators {
        setting(lineSeparator: { AnyView(separator()) })
    }
}
