#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    /// Exercises SwiftUI's intrinsic sizing and alignment probes, not just one engine invocation.
    @Suite(.serialized, .tags(.requirements))
    @MainActor
    struct FlowReportingRegressionTests {
        @Test(.tags(.regression), arguments: [false, true])
        func combinedReporters_updateWhenAllItemsFit(vertical: Bool) async throws {
            _ = NSApplication.shared
            let activity = Activity()
            let input = OverflowInput()
            input.boundary = .inherited
            input.breadth = 107
            input.count = 7
            let host = NSHostingView(rootView: CombinedOverflowScene(vertical: vertical, activity: activity, input: input))
            let window = NSWindow(contentRect: rect(breadth: 300, vertical: vertical), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }
            host.layoutSubtreeIfNeeded()
            try await waitForLayout(activity, vertical: vertical, hidden: 4, depth: 22)
            try #require(activity.countFromView == 4)
            input.count = 2
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(200))
            window.setContentSize(rect(breadth: input.breadth, vertical: vertical).size)
            host.layoutSubtreeIfNeeded()
            try await waitForLayout(activity, vertical: vertical, hidden: 0, depth: 10)
            try await Task.sleep(for: .milliseconds(150))
            #expect((vertical ? activity.size?.width : activity.size?.height) == 10)
            #expect(activity.countFromView == 0)
            #expect(activity.outerCountFromView == 0)
        }

        @Test(.tags(.regression), arguments: [false, true])
        func combinedReporters_settleAfterOverflowOverrideChanges(vertical: Bool) async throws {
            _ = NSApplication.shared
            let activity = Activity()
            let input = OverflowInput()
            let host = NSHostingView(rootView: CombinedOverflowScene(vertical: vertical, activity: activity, input: input))
            let window = NSWindow(contentRect: rect(breadth: 300, vertical: vertical), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }

            let cases: [OverflowScenario] = [
                .init(boundary: .empty, breadth: 100, items: 5, hidden: 1, depth: 22),
                .init(boundary: .inherited, breadth: 100, items: 5, hidden: 2, depth: 22),
                .init(boundary: .inherited, breadth: 100, items: 7, hidden: 4, depth: 22),
                .init(boundary: .inherited, breadth: 100, items: 5, hidden: 2, depth: 22),
                .init(boundary: .custom, breadth: 107, items: 5, hidden: 1, depth: 22),
                .init(boundary: .empty, breadth: 70, items: 5, hidden: 3, depth: 22),
                .init(boundary: .empty, breadth: 300, items: 5, hidden: 0, depth: 10),
                .init(boundary: .custom, breadth: 107, items: 7, hidden: 3, depth: 22),
                .init(boundary: .custom, breadth: 107, items: 2, hidden: 0, depth: 10),
                .init(boundary: .custom, breadth: 107, items: 0, hidden: 0, depth: 0),
                .init(boundary: .empty, breadth: 100, items: 5, hidden: 1, depth: 22),
            ]
            for scenario in cases {
                input.boundary = scenario.boundary
                input.breadth = scenario.breadth
                input.count = scenario.items
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(200))
                window.setContentSize(rect(breadth: scenario.breadth, vertical: vertical).size)
                host.layoutSubtreeIfNeeded()
                try await waitForLayout(activity, vertical: vertical, hidden: scenario.hidden, depth: scenario.depth)
                let before = activity.builds
                try await Task.sleep(for: .milliseconds(150))
                #expect(activity.hidden == scenario.hidden, "The overflow builder must receive the final hidden count")
                #expect(activity.countFromView == scenario.hidden, "The overflow view must contain the final reported count")
                #expect(activity.outerCountFromView == 0, "Nested layouts must keep their reports independent")
                #expect((vertical ? activity.size?.width : activity.size?.height) == scenario.depth, "Line separators must match the visible rows")
                #expect(activity.builds - before <= 2, "Combined reporters and nested alignment must settle")
            }
        }

        @Test(.tags(.regression), arguments: [false, true], [false, true])
        func combinedReporters_reusedAlignmentPlacement_updatesHiddenCount(vertical: Bool, viewportChange: Bool) async throws {
            _ = NSApplication.shared
            let activity = Activity()
            let input = OverflowInput()
            input.breadth = viewportChange ? 70 : 100
            let host = NSHostingView(rootView: CombinedOverflowScene(vertical: vertical, activity: activity, input: input))
            let window = NSWindow(contentRect: rect(breadth: 300, vertical: vertical), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }
            host.layoutSubtreeIfNeeded()
            try await waitForLayout(activity, vertical: vertical, hidden: viewportChange ? 3 : 1, depth: 22)
            try #require(activity.hidden == (viewportChange ? 3 : 1), "The initial layout must deliver a final placement report")

            if viewportChange {
                input.breadth = 300
            } else {
                input.boundary = .inherited
            }
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(200))
            window.setContentSize(rect(breadth: input.breadth, vertical: vertical).size)
            host.layoutSubtreeIfNeeded()
            try await waitForLayout(activity, vertical: vertical, hidden: viewportChange ? 0 : 2, depth: viewportChange ? 10 : 22)
            try await Task.sleep(for: .milliseconds(150))
            #expect((vertical ? activity.size?.width : activity.size?.height) == (viewportChange ? 10 : 22))
            #expect(activity.hidden == (viewportChange ? 0 : 2))
            #expect(activity.countFromView == (viewportChange ? 0 : 2))
        }

        @Test(arguments: [false, true], [Feature.overflow, .separators, .combined])
        func intrinsicSizing_settlesAfterResizing(vertical: Bool, feature: Feature) async throws {
            _ = NSApplication.shared
            let activity = Activity()
            let input = Input()
            let host = LayoutHostingView(rootView: AnyView(Scene(vertical: vertical, feature: feature, activity: activity, input: input)))
            host.didLayout = { activity.viewport = $0 }
            let window = NSWindow(
                contentRect: rect(breadth: 180, vertical: vertical),
                styleMask: .borderless,
                backing: .buffered,
                defer: true
            )
            window.contentView = host
            defer { window.contentView = nil }

            for breadth: CGFloat in [180, 300, 100, 180] {
                window.setContentSize(rect(breadth: breadth, vertical: vertical).size)
                host.layoutSubtreeIfNeeded()
                let expected = breadth == 300 ? 0 : (breadth == 100 ? 2 : 1)
                try await waitForScene(activity, input: input, host: host, hidden: feature == .separators ? nil : expected)
                try await expectSettled(activity, message: "Static layout must stop rebuilding after sizing settles")
                if feature != .separators {
                    #expect(activity.scene?.hidden == expected, "Overflow must describe the displayed geometry")
                }
            }
            for (sizes, hidden) in [([50.0, 100.0, 100.0], 2), ([50.0], 0), ([50.0, 100.0], 1)] {
                input.sizes = sizes
                try await Task.sleep(for: .milliseconds(200))
                // A single item reduces NSHostingView's maximum window size. Let that constraint
                // update before requesting the original viewport again when content grows.
                window.setContentSize(rect(breadth: 180, vertical: vertical).size)
                host.layoutSubtreeIfNeeded()
                try await waitForScene(activity, input: input, host: host, hidden: feature == .separators ? nil : hidden)
                try await expectSettled(activity, message: "Content changes must settle without a feedback loop")
                if feature != .separators { #expect(activity.scene?.hidden == hidden) }
            }
            input.nested = true
            host.layoutSubtreeIfNeeded()
            try await waitForScene(activity, input: input, host: host, hidden: feature == .separators ? nil : 1)
            try await expectSettled(activity, message: "Nested flow alignment must not publish speculative structure")
            if feature != .separators { #expect(activity.scene?.hidden == 1) }
        }

        enum Feature: Sendable {
            case overflow, separators, combined
        }

        @MainActor
        private final class Activity {
            let changes = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
            var builds = 0
            var hidden: Int?
            var size: CGSize? { didSet { changes.continuation.yield() } }
            var scene: SceneObservation? { didSet { changes.continuation.yield() } }
            var viewport: CGSize? { didSet { changes.continuation.yield() } }
            var countFromView: Int? { didSet { changes.continuation.yield() } }
            var outerCountFromView: Int? { didSet { changes.continuation.yield() } }
        }

        private enum LayoutWaitError: Error {
            case timedOut
            case unmatchedLayout(String)
        }

        private func waitForLayout(_ activity: Activity, vertical: Bool, hidden: Int, depth: CGFloat) async throws {
            do {
                try await waitForActivity(activity) {
                    activity.countFromView == hidden
                        && activity.outerCountFromView == 0
                        && (vertical ? activity.size?.width : activity.size?.height) == depth
                }
            } catch LayoutWaitError.timedOut {
                throw LayoutWaitError.unmatchedLayout(
                    "Expected hidden=\(hidden), depth=\(depth); received builder=\(String(describing: activity.hidden)), "
                        + "preference=\(String(describing: activity.countFromView)), outer=\(String(describing: activity.outerCountFromView)), "
                        + "size=\(String(describing: activity.size))"
                )
            }
        }

        private func waitForScene(_ activity: Activity, input: Input, host: LayoutHostingView, hidden: Int?) async throws {
            let expectedInput = InputSnapshot(sizes: input.sizes, nested: input.nested)
            try await waitForActivity(activity) {
                // AppKit may clamp the requested window size to the content's intrinsic bounds.
                activity.scene?.input == expectedInput && activity.scene?.size != nil
                    && activity.viewport == host.bounds.size
                    && (hidden == nil || activity.scene?.hidden == hidden)
            }
        }

        private func expectSettled(_ activity: Activity, message: String) async throws {
            let deadline = ContinuousClock.now.advanced(by: .seconds(10))
            repeat {
                let before = activity.builds
                // Observe a quiet interval after correct results, allowing initial updates to finish.
                try await Task.sleep(for: .milliseconds(150))
                if activity.builds - before <= 2 { return }
            } while ContinuousClock.now < deadline
            Issue.record("\(message)")
        }

        private final class LayoutHostingView: NSHostingView<AnyView> {
            var didLayout: (@MainActor (CGSize) -> Void)?

            override func layout() {
                super.layout()
                didLayout?(bounds.size)
            }
        }

        private func waitForActivity(_ activity: Activity, matches: @escaping @MainActor @Sendable () -> Bool) async throws {
            guard !matches() else { return }
            let changes = activity.changes.stream
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in changes {
                        try Task.checkCancellation()
                        if await matches() { return }
                    }
                    throw CancellationError()
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(10))
                    throw LayoutWaitError.timedOut
                }
                defer { group.cancelAll() }
                try await group.next()
            }
        }

        private enum OverflowBoundary {
            case inherited
            case empty
            case custom
        }

        private struct OverflowScenario {
            let boundary: OverflowBoundary
            let breadth: CGFloat
            let items: Int
            let hidden: Int
            let depth: CGFloat
        }

        private final class OverflowInput: ObservableObject {
            @Published var boundary = OverflowBoundary.empty
            @Published var breadth: CGFloat = 100
            @Published var count = 5
        }

        private struct OverflowCountKey: PreferenceKey {
            static let defaultValue: Int? = nil

            static func reduce(value: inout Int?, nextValue: () -> Int?) {
                value = nextValue() ?? value
            }
        }

        private struct FlowSizeKey: PreferenceKey {
            static let defaultValue: CGSize? = nil

            static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
                value = nextValue() ?? value
            }
        }

        private struct OuterOverflowCountKey: PreferenceKey {
            static let defaultValue: Int? = nil

            static func reduce(value: inout Int?, nextValue: () -> Int?) {
                value = nextValue() ?? value
            }
        }

        private struct CombinedOverflowScene: View {
            let vertical: Bool
            let activity: Activity
            @ObservedObject var input: OverflowInput

            @ViewBuilder private var content: some View {
                ForEach(0 ..< input.count, id: \.self) { _ in
                    Color.red.frame(width: vertical ? 10 : 30, height: vertical ? 30 : 10)
                }
                ItemSeparator { Color.black.frame(width: vertical ? 10 : 50, height: vertical ? 50 : 10) }
            }

            @ViewBuilder private var flow: some View {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }

            private func overflow(_ count: Int) -> some View {
                activity.builds += 1
                activity.hidden = count
                return Group {
                    switch input.boundary {
                        case .inherited: EmptyView()
                        case .empty: ItemSeparator { EmptyView() }
                        case .custom: ItemSeparator { Color.purple.frame(width: vertical ? 10 : 2, height: vertical ? 2 : 10) }
                    }
                    Color.green.frame(width: vertical ? 10 : 20, height: vertical ? 20 : 10)
                        .preference(key: OverflowCountKey.self, value: count)
                }
            }

            private var decorated: some View {
                let itemSeparator = { [activity, vertical] in
                    activity.builds += 1
                    return Color.blue.frame(width: vertical ? 10 : 5, height: vertical ? 5 : 10)
                }
                let lineSeparator = { [activity, vertical] in
                    activity.builds += 1
                    return Color.gray.frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
                }
                return flow.itemSeparator(itemSeparator).lineSeparator(lineSeparator).maxLines(2, overflow: overflow)
            }

            @ViewBuilder private var nested: some View {
                if vertical {
                    VFlow(itemSpacing: 0, columnSpacing: 0) { decorated }
                } else {
                    HFlow(itemSpacing: 0, rowSpacing: 0) { decorated }
                }
            }

            var body: some View {
                nested
                    .lineSeparator { Color.clear.frame(width: 1, height: 1) }
                    .maxLines(1) { count in
                        Color.clear.frame(width: 0, height: 0)
                            .preference(key: OuterOverflowCountKey.self, value: count)
                    }
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(key: FlowSizeKey.self, value: proxy.size)
                        }
                    }
                    .frame(width: vertical ? 80 : input.breadth, height: vertical ? input.breadth : 80, alignment: .topLeading)
                    .onPreferenceChange(FlowSizeKey.self) { size in
                        Task { @MainActor in activity.size = size }
                    }
                    .onPreferenceChange(OverflowCountKey.self) { count in
                        Task { @MainActor in activity.countFromView = count }
                    }
                    .onPreferenceChange(OuterOverflowCountKey.self) { count in
                        Task { @MainActor in activity.outerCountFromView = count }
                    }
            }
        }

        private struct InputSnapshot: Equatable, Sendable {
            let sizes: [Double]
            let nested: Bool
        }

        private struct SceneObservation: Equatable, Sendable {
            var input: InputSnapshot?
            var hidden: Int?
            var size: CGSize?
        }

        private struct SceneObservationKey: PreferenceKey {
            static let defaultValue = SceneObservation()

            static func reduce(value: inout SceneObservation, nextValue: () -> SceneObservation) {
                let next = nextValue()
                value.input = next.input ?? value.input
                value.hidden = next.hidden ?? value.hidden
                value.size = next.size ?? value.size
            }
        }

        private final class Input: ObservableObject {
            @Published var sizes = [50.0, 100.0]
            @Published var nested = false
        }

        private struct Scene: View {
            let vertical: Bool
            let feature: Feature
            let activity: Activity
            @ObservedObject var input: Input

            @ViewBuilder var flow: some View {
                if vertical {
                    decorate(
                        VFlow {
                            ForEach(input.sizes.indices, id: \.self) { index in
                                if feature == .combined, index > 0 {
                                    ItemSeparator { Color.gray.frame(width: 1, height: 1) }
                                }
                                Color.red.frame(width: 20, height: input.sizes[index])
                            }
                        }
                    )
                } else {
                    decorate(
                        HFlow {
                            ForEach(input.sizes.indices, id: \.self) { index in
                                if feature == .combined, index > 0 {
                                    ItemSeparator { Color.gray.frame(width: 1, height: 1) }
                                }
                                Color.red.frame(width: input.sizes[index], height: 20)
                            }
                        }
                    )
                }
            }

            @ViewBuilder var nestedFlow: some View {
                if input.nested {
                    if vertical {
                        VFlow(itemSpacing: 0, columnSpacing: 0) { flow }
                    } else {
                        HFlow(itemSpacing: 0, rowSpacing: 0) { flow }
                    }
                } else {
                    flow
                }
            }

            @ViewBuilder func decorate(_ content: some View) -> some View {
                // Capture the recorder, not the entire view in an environment-carried builder.
                let badge = { [activity] (count: Int) in
                    activity.builds += 1
                    activity.hidden = count
                    return Text("+\(count)").preference(key: SceneObservationKey.self, value: SceneObservation(hidden: count))
                }
                let separator = { [activity] in
                    activity.builds += 1
                    return Rectangle().frame(width: 1, height: 1)
                }
                switch feature {
                    case .overflow:
                        content.maxLines(1, overflow: badge)
                    case .separators:
                        content.lineSeparator(separator)
                    case .combined:
                        content.maxLines(1, overflow: badge).itemSeparator(separator).lineSeparator(separator)
                }
            }

            private var measuredFlow: some View {
                nestedFlow.background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: SceneObservationKey.self, value: SceneObservation(size: proxy.size))
                    }
                }
            }

            var body: some View {
                Group {
                    if vertical {
                        VStack {
                            Circle().frame(width: 50, height: 50)
                            measuredFlow
                        }
                    } else {
                        HStack {
                            Circle().frame(width: 50, height: 50)
                            measuredFlow
                        }
                    }
                }
                .transformPreference(SceneObservationKey.self) { observation in
                    observation.input = InputSnapshot(sizes: input.sizes, nested: input.nested)
                }
                .onPreferenceChange(SceneObservationKey.self) { observation in
                    Task { @MainActor in activity.scene = observation }
                }
            }
        }

        private func rect(breadth: CGFloat, vertical: Bool) -> NSRect {
            NSRect(x: 0, y: 0, width: vertical ? 80 : breadth, height: vertical ? breadth : 80)
        }

    }
#endif
