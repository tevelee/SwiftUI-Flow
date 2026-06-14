import CoreFoundation
import SwiftUI

// NOTE: The pipeline seam uses `package` access so the feature targets can implement features
// against it without exposing the engine's internals as public/SPI API. `package` symbols cannot be
// referenced from `@inlinable` code, so the engine's hot path that touches these types is compiled
// non-inlinable (see the dropped `@inlinable` on the cache/measurement/line-breaking helpers).

/// The generic plugin seam that lets optional features extend ``FlowLayout`` without the engine
/// knowing what any of them does.
///
/// `FlowLayout` holds an ordered `[any FlowLayoutFeature]` and folds each one into the pipeline at the
/// same fixed points — the input seam (before line breaking), the output seam (after line breaking),
/// and reporting (after sizing/placement) — always in array order. The engine never names a concrete
/// feature: line capping and separators are two conformers that live in the feature targets,
/// depending only on this protocol and the pipeline value types it exposes.
///
/// A feature is pure, `Sendable` configuration. All per-pass work lives in the ``FlowFeatureSession``
/// it vends from ``makeSession(subviews:cache:context:)`` — which returns `nil` to opt out of a pass
/// (e.g. when no subview actually carries the feature's markers).
package protocol FlowLayoutFeature: Sendable {
    /// Builds the per-pass worker for this feature, or `nil` to sit the pass out.
    func makeSession(
        subviews: some Subviews,
        cache: FlowLayoutCache,
        context: FlowFeatureContext
    ) -> (any FlowFeatureSession)?
}

/// The per-pass worker vended by a ``FlowLayoutFeature``. Each hook defaults to a no-op so a feature
/// only implements the seams it actually uses. A session captures everything it needs at creation, so
/// the hooks take only the value flowing through their seam.
package protocol FlowFeatureSession {
    /// Input seam: adapt the breaker input before line breaking (e.g. exclude or fold injected views).
    func adaptInput(_ input: BreakerInput) -> BreakerInput
    /// Output seam: adapt the wrapped lines after line breaking (e.g. truncate, materialize siblings).
    func adaptOutput(_ lines: WrappedLines) -> LineAdaptation
    /// Reporting: feed structural facts back to the view layer after sizing/placement.
    func report(_ result: FlowLayoutResult)
}

extension FlowFeatureSession {
    package func adaptInput(_ input: BreakerInput) -> BreakerInput { input }
    package func adaptOutput(_ lines: WrappedLines) -> LineAdaptation { LineAdaptation(lines: lines) }
    package func report(_ result: FlowLayoutResult) {}
}

/// The axis-agnostic facts handed to a feature when it builds a session, so it can adapt the pipeline
/// without reaching back into ``FlowLayout``.
package struct FlowFeatureContext {
    package var axis: Axis
    package var itemSpacing: CGFloat?
    package var justified: Bool
    package var proposal: ProposedViewSize
    /// The breadth the breaker may fill for this proposal (``FlowLayout/availableLineBreakingSpace(in:)``).
    package var availableBreadth: CGFloat

    package init(
        axis: Axis,
        itemSpacing: CGFloat?,
        justified: Bool,
        proposal: ProposedViewSize,
        availableBreadth: CGFloat
    ) {
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.justified = justified
        self.proposal = proposal
        self.availableBreadth = availableBreadth
    }
}

/// Marks a subview as auxiliary: injected by a feature (a separator, an overflow indicator) rather
/// than supplied by the caller. Lets one feature target tell caller content apart from views injected
/// by another without the two depending on each other — e.g. line capping (in `FlowLineLimit`) counts
/// only non-auxiliary subviews, so separators (in `FlowSeparators`) marking themselves here are
/// excluded from the hidden total. Defined in the core so both feature targets share the contract.
package struct IsAuxiliaryLayoutValueKey: LayoutValueKey {
    package static let defaultValue = false
}

// MARK: - View-layer composition seam

/// A view-layer plugin a feature registers (via its modifier) so ``HFlow``/``VFlow`` can fold the
/// feature's engine ``FlowLayoutFeature`` list and any injected sibling subviews into a *single*
/// layout pass — without the core naming the feature. Each composer lives in its own feature target,
/// reads its own environment, and contributes to the shared pass; several compose cleanly so e.g.
/// `.maxLines` and `.itemSeparator` used together still produce one layout.
///
/// Composers are ordered by ``priority`` — see ``composeFlowBody(composers:makeLayout:content:)`` for
/// exactly how the order maps onto the engine feature list and the injected subview nesting.
package protocol FlowComposer: Sendable {
    /// Orders this composer against the others; see ``composeFlowBody(composers:makeLayout:content:)``.
    var priority: Int { get }

    /// Reads this composer's environment and hands `next` the engine features it contributes and the
    /// content it produces (transformed to inject any sibling subviews). Implemented by returning a
    /// view so it can hold the `@StateObject` reporters the engine feeds structural results back into.
    @MainActor
    func makeBody(
        content: AnyView,
        next: @escaping @MainActor ([any FlowLayoutFeature], AnyView) -> AnyView
    ) -> AnyView
}

package struct FlowComposersKey: EnvironmentKey {
    package static var defaultValue: [any FlowComposer] { [] }
}

extension EnvironmentValues {
    package var flowComposers: [any FlowComposer] {
        get { self[FlowComposersKey.self] }
        set { self[FlowComposersKey.self] = newValue }
    }
}

extension View {
    /// Registers `composer` for the nearest enclosing flow, de-duplicated by type so applying a
    /// feature's modifier more than once (e.g. both `.itemSeparator` and `.lineSeparator`) still
    /// contributes a single composer.
    package func registerFlowComposer(_ composer: any FlowComposer) -> some View {
        transformEnvironment(\.flowComposers) { composers in
            let id = ObjectIdentifier(type(of: composer))
            guard !composers.contains(where: { ObjectIdentifier(type(of: $0)) == id }) else { return }
            composers.append(composer)
        }
    }
}

/// Folds the registered ``FlowComposer``s into one composed body: a single layout whose feature list
/// and injected subviews come from every composer. `makeLayout` turns a feature list into the concrete
/// axis layout; `content` is the caller's tagged content.
///
/// Ordering follows ``FlowComposer/priority`` (ascending):
/// * the engine **feature list** runs in ascending priority, so a lower-priority feature (line
///   capping, priority 0) runs before a higher-priority one (separators, priority 1) — capping
///   truncates lines before separators are materialized into them;
/// * **content** is wrapped so each composer transforms the content of all *higher*-priority
///   composers — the lowest-priority composer is outermost, so an appended sibling (the overflow
///   indicator) lands last in the layout's subviews, where line capping expects it.
@MainActor
package func composeFlowBody(
    composers: [any FlowComposer],
    makeLayout: @escaping @MainActor ([any FlowLayoutFeature]) -> AnyLayout,
    content: AnyView
) -> AnyView {
    typealias Tagged = [(priority: Int, feature: any FlowLayoutFeature)]
    let ordered = composers.sorted { $0.priority < $1.priority }
    let base: @MainActor (Tagged, AnyView) -> AnyView = { tagged, content in
        let features = tagged.sorted { $0.priority < $1.priority }.map(\.feature)
        let layout = makeLayout(features)
        return AnyView(layout { content })
    }
    let chain = ordered.reduce(base) { next, composer in
        { tagged, content in
            composer.makeBody(content: content) { features, content in
                next(tagged + features.map { (composer.priority, $0) }, content)
            }
        }
    }
    return chain([], content)
}
