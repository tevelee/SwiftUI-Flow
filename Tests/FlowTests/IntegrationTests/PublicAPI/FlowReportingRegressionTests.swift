#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    /// Exercises SwiftUI's intrinsic sizing and alignment probes, not just one engine invocation.
    @Suite(.serialized, .tags(.requirements))
    @MainActor
    struct FlowReportingRegressionTests {
        @Test(arguments: [false, true], [Feature.overflow, .separators, .combined])
        func intrinsicSizing_settlesAfterResizing(vertical: Bool, feature: Feature) async throws {
            _ = NSApplication.shared
            let activity = Activity()
            let input = Input()
            let host = NSHostingView(rootView: AnyView(Scene(vertical: vertical, feature: feature, activity: activity, input: input)))
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
                try await Task.sleep(for: .milliseconds(200))
                let before = activity.builds
                try await Task.sleep(for: .milliseconds(150))
                #expect(activity.builds - before <= 2, "Static layout must stop rebuilding after sizing settles")
                if feature != .separators {
                    let expected = breadth == 300 ? 0 : (breadth == 100 ? 2 : 1)
                    #expect(activity.hidden == expected, "Overflow must describe the displayed geometry")
                }
            }
            for (sizes, hidden) in [([50.0, 100.0, 100.0], 2), ([50.0], 0), ([50.0, 100.0], 1)] {
                input.sizes = sizes
                try await Task.sleep(for: .milliseconds(200))
                // A single item reduces NSHostingView's maximum window size. Let that constraint
                // update before requesting the original viewport again when content grows.
                window.setContentSize(rect(breadth: 180, vertical: vertical).size)
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
                let before = activity.builds
                try await Task.sleep(for: .milliseconds(150))
                #expect(activity.builds - before <= 2, "Content changes must settle without a feedback loop")
                if feature != .separators { #expect(activity.hidden == hidden) }
            }
            input.nested = true
            try await Task.sleep(for: .milliseconds(200))
            let before = activity.builds
            try await Task.sleep(for: .milliseconds(150))
            #expect(activity.builds - before <= 2, "Nested flow alignment must not publish speculative structure")
            if feature != .separators { #expect(activity.hidden == 1) }
        }

        enum Feature: Sendable {
            case overflow, separators, combined
        }

        private final class Activity {
            var builds = 0
            var hidden: Int?
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
                                Color.red.frame(width: 20, height: input.sizes[index])
                            }
                        }
                    )
                } else {
                    decorate(
                        HFlow {
                            ForEach(input.sizes.indices, id: \.self) { index in
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
                    return Text("+\(count)")
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
                        content.maxLines(1, overflow: badge).lineSeparator(separator)
                }
            }

            @ViewBuilder var body: some View {
                if vertical {
                    VStack {
                        Circle().frame(width: 50, height: 50)
                        nestedFlow
                    }
                } else {
                    HStack {
                        Circle().frame(width: 50, height: 50)
                        nestedFlow
                    }
                }
            }
        }

        private func rect(breadth: CGFloat, vertical: Bool) -> NSRect {
            NSRect(x: 0, y: 0, width: vertical ? 80 : breadth, height: vertical ? breadth : 80)
        }

    }
#endif
