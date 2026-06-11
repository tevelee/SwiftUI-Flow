import SwiftUI

// MARK: - State holder

/// Holds the hidden-item count reported back from the layout engine.
/// Using a class (ObservableObject) so the @State reference survives body re-evaluations.
@MainActor
private final class OverflowState: ObservableObject {
    @Published var hiddenCount: Int = 0
}

// MARK: - Overflow wrapper

/// Wraps a flow layout to support `.maxLines(_:overflow:)` with a live hidden-item count.
/// - Note: Do not use this type directly. Use ``HFlow/maxLines(_:overflow:)`` or ``VFlow/maxLines(_:overflow:)`` instead.
public struct _FlowWithOverflow<Content: View, Overflow: View>: View {  // swiftlint:disable:this type_name
    @usableFromInline
    let layout: AnyLayout
    @usableFromInline
    let content: Content
    @usableFromInline
    let overflowBuilder: (Int) -> Overflow

    @StateObject private var state = OverflowState()

    @inlinable
    init(layout: AnyLayout, content: Content, overflowBuilder: @escaping (Int) -> Overflow) {
        self.layout = layout
        self.content = content
        self.overflowBuilder = overflowBuilder
    }

    public var body: some View {
        let stateRef = state
        layout {
            content.environment(\.maxLines, nil)
            overflowBuilder(state.hiddenCount)
                .layoutValue(key: IsOverflowLayoutValueKey.self, value: true)
                .layoutValue(
                    key: OverflowReporterKey.self,
                    value: { count in
                        Task { @MainActor in
                            if stateRef.hiddenCount != count { stateRef.hiddenCount = count }
                        }
                    }
                )
        }
    }
}

// MARK: - Public modifier overloads

extension HFlow {
    /// Caps the flow to `limit` rows and appends the overflow view at the end of the last row,
    /// showing how many items were hidden.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of rows to show. Must be ≥ 1.
    ///   - overflow: A view builder that receives the number of hidden items and returns a view
    ///     to show at the end of the last visible row (e.g. `"+\(count) more"`).
    @MainActor
    @inlinable
    public func maxLines<O: View>(
        _ limit: Int,
        @ViewBuilder overflow: @escaping (Int) -> O
    ) -> _FlowWithOverflow<Content, O> {
        _FlowWithOverflow(
            layout: AnyLayout(layout.withMaxLines(limit)),
            content: content,
            overflowBuilder: overflow
        )
    }
}

extension VFlow {
    /// Caps the flow to `limit` columns and appends the overflow view at the end of the last column,
    /// showing how many items were hidden.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of columns to show. Must be ≥ 1.
    ///   - overflow: A view builder that receives the number of hidden items and returns a view
    ///     to show at the end of the last visible column (e.g. `"+\(count) more"`).
    @MainActor
    @inlinable
    public func maxLines<O: View>(
        _ limit: Int,
        @ViewBuilder overflow: @escaping (Int) -> O
    ) -> _FlowWithOverflow<Content, O> {
        _FlowWithOverflow(
            layout: AnyLayout(layout.withMaxLines(limit)),
            content: content,
            overflowBuilder: overflow
        )
    }
}
