import SwiftUI
import os

/// A single-value `ObservableObject` carrying a fact the layout engine reports back to the view layer.
///
/// The engine feeds structural results to the view through `@Sendable` reporter closures. Mutating
/// `@Published` state during a SwiftUI update is disallowed, so ``register()`` defers the publish
/// to the next main-actor turn, coalesces a burst of reports, and skips unchanged values. Sized
/// reports additionally require confirmation of the rendered bounds. Held as a `@StateObject`
/// so the reference survives body re-evaluations.
@MainActor
final class LayoutReportState<Value: Equatable & Sendable>: ObservableObject {
    @Published var value: Value
    private let pending = OSAllocatedUnfairLock(initialState: Pending())

    private struct Pending: Sendable {
        var value: Value?
        var isScheduled = false
        var generation = 0
        var geometry: GeometryKey?
        // SwiftUI may reuse an earlier placement when rendered bounds change. Keep every size's
        // latest candidate until content changes; geometry confirmation only selects which to publish.
        var candidates: [GeometryKey: Value] = [:]

        mutating func schedule(_ value: Value?) -> Bool {
            self.value = value
            guard value != nil, !isScheduled else { return false }
            isScheduled = true
            return true
        }
    }

    private struct GeometryKey: Hashable, Sendable {
        var width: CGFloat
        var height: CGFloat

        init(_ size: CGSize) {
            width = size.width
            height = size.height
        }
    }

    init(_ value: Value) {
        self.value = value
    }

    /// Starts one content generation and pairs its candidate reports with geometry confirmation.
    /// Callers cannot accidentally confirm a report using a different registration's generation.
    func register() -> LayoutReportRegistration<Value> {
        let pending = pending
        let generation = pending.withLock { state in
            state.generation &+= 1
            state.candidates.removeAll(keepingCapacity: true)
            state.value = nil
            state.geometry = nil
            return state.generation
        }
        let report: @Sendable (Value, CGSize) -> Void = { value, size in
            let shouldSchedule = pending.withLock { state in
                guard state.generation == generation else { return false }
                let key = GeometryKey(size)
                state.candidates[key] = value
                guard state.geometry == key else { return false }
                return state.schedule(value)
            }
            self.schedulePublication(shouldSchedule)
        }
        let confirm: @Sendable (CGSize) -> Void = { size in
            let shouldSchedule = pending.withLock { state in
                guard state.generation == generation else { return false }
                let key = GeometryKey(size)
                let candidate = state.candidates[key]
                state.geometry = key
                return state.schedule(candidate)
            }
            self.schedulePublication(shouldSchedule)
        }
        return LayoutReportRegistration(id: ObjectIdentifier(self), generation: generation, report: report, confirm: confirm)
    }

    private nonisolated func schedulePublication(_ shouldSchedule: Bool) {
        guard shouldSchedule else { return }
        Task { @MainActor in
            let latest = self.pending.withLock { state in
                let value = state.value
                state.value = nil
                state.isScheduled = false
                return value
            }
            if let latest, self.value != latest { self.value = latest }
        }
    }
}

extension LayoutReportState where Value == FlowLayoutReport {
    /// Builds one reported layout pass while keeping generation, child tags and rendered geometry together.
    /// State ownership stays with the caller; content only needs the latest confirmed report.
    func flowLayout<Content: View>(
        _ layout: AnyLayout,
        reportLineStructure: Bool = true,
        @ViewBuilder content: (FlowLayoutReport) -> Content
    ) -> some View {
        let registration = register()
        let reporter: @Sendable (FlowLayoutReport, CGSize) -> Void = { value, size in
            registration.report(
                FlowLayoutReport(
                    overflowCount: value.overflowCount,
                    lineStructure: reportLineStructure ? value.lineStructure : [],
                    hiddenSubviews: value.hiddenSubviews
                ),
                size
            )
        }
        return layout {
            // Attach after enumeration: legacy child proxies can drop source layout values.
            reportedFlowContent(content(value), hidden: Set(value.hiddenSubviews))
                .layoutValue(key: PlacementReporterKey.self, value: reporter)
        }
        .observeLayoutGeometry(using: registration)
    }
}

/// One content generation's reporting interface. Its identity and generation travel with geometry
/// preferences, so unchanged bounds confirm new content without accepting stale preferences.
struct LayoutReportRegistration<Value: Sendable>: Sendable {
    let id: ObjectIdentifier
    let generation: Int
    let report: @Sendable (Value, CGSize) -> Void
    let confirm: @Sendable (CGSize) -> Void
}

/// Overflow and line structure describe the same placement and must be published together.
@usableFromInline
struct FlowLayoutReport: Equatable, Sendable {
    var overflowCount = 0
    var lineStructure: [Int] = []
    var hiddenSubviews: [Int] = []
}

@usableFromInline
struct PlacementReporterKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: (@Sendable (FlowLayoutReport, CGSize) -> Void)? = nil
}

private struct ReportedGeometryKey: PreferenceKey {
    struct Sample: Equatable, Sendable {
        let generation: Int
        let size: CGSize
    }

    static let defaultValue: [ObjectIdentifier: Sample] = [:]

    static func reduce(value: inout [ObjectIdentifier: Sample], nextValue: () -> [ObjectIdentifier: Sample]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Confirms this layout's rendered bounds independently of nested preference propagation.
    @MainActor
    @ViewBuilder
    func observeLayoutGeometry<Value>(using registration: LayoutReportRegistration<Value>) -> some View {
        // Xcode 16 SDKs expose direct geometry observation back to the minimum deployment targets.
        #if swift(>=6.0)
            onGeometryChange(for: ReportedGeometryKey.Sample.self) { proxy in
                ReportedGeometryKey.Sample(generation: registration.generation, size: proxy.size)
            } action: { sample in
                if sample.generation == registration.generation { registration.confirm(sample.size) }
            }
        #else
            let id = registration.id
            background {
                GeometryReader { proxy in
                    Color.clear.preference(key: ReportedGeometryKey.self, value: [id: .init(generation: registration.generation, size: proxy.size)])
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .onPreferenceChange(ReportedGeometryKey.self) { sizes in
                if let sample = sizes[id], sample.generation == registration.generation { registration.confirm(sample.size) }
            }
        #endif
    }
}
