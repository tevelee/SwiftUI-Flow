#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.serialized, .tags(.requirements))
    @MainActor
    struct FlowExplicitAlignmentTests {
        @Test(arguments: [false, true], [false, true])
        func guides_matchSwiftUIDefaultMerging(vertical: Bool, legacyWrapper: Bool) {
            let engine: FlowLayout =
                vertical
                ? .vertical(horizontalSpacing: 3, verticalSpacing: 5)
                : .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 5, verticalSpacing: 3)
            let actualLayout: AnyLayout
            if vertical {
                actualLayout =
                    legacyWrapper
                    ? AnyLayout(VFlow(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 3, verticalSpacing: 5))
                    : AnyLayout(VFlowLayout(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 3, verticalSpacing: 5))
            } else {
                actualLayout =
                    legacyWrapper
                    ? AnyLayout(HFlow(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline, horizontalSpacing: 5, verticalSpacing: 3))
                    : AnyLayout(HFlowLayout(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline, horizontalSpacing: 5, verticalSpacing: 3))
            }
            for direction: LayoutDirection in [.leftToRight, .rightToLeft] {
                let expected = guides(in: AnyLayout(DefaultAlignmentLayout(engine: engine)), direction: direction)
                let actual = guides(in: actualLayout, direction: direction)
                #expect(actual.count == expected.count)
                for (index, pair) in zip(actual, expected).enumerated() {
                    let (value, reference) = pair
                    if let value, let reference {
                        #expect(abs(value - reference) < 0.000_001, "Guide \(index), direction \(direction)")
                    } else {
                        #expect(value == reference)
                    }
                }
                #expect(actual.compactMap { $0 }.count >= 4, "Must exercise explicit custom guides and text baselines")
            }
        }

        enum LayoutAdapter: CaseIterable, Sendable {
            case layout, view, engine
        }

        @Test(arguments: [false, true], LayoutAdapter.allCases)
        func reusedLayout_refreshesCacheAfterContentChanges(vertical: Bool, adapter: LayoutAdapter) {
            let engine: FlowLayout =
                vertical
                ? .vertical(horizontalSpacing: 0, verticalSpacing: 5)
                : .horizontal(horizontalSpacing: 5, verticalSpacing: 0)
            let layout: AnyLayout
            switch adapter {
                case .engine: layout = AnyLayout(engine)
                case .layout:
                    layout =
                        vertical
                        ? AnyLayout(VFlowLayout(itemSpacing: 5, columnSpacing: 0))
                        : AnyLayout(HFlowLayout(itemSpacing: 5, rowSpacing: 0))
                case .view:
                    layout =
                        vertical
                        ? AnyLayout(VFlow(itemSpacing: 5, columnSpacing: 0))
                        : AnyLayout(HFlow(itemSpacing: 5, rowSpacing: 0))
            }
            let host = NSHostingView(rootView: CacheRefreshScene(layout: layout, vertical: vertical, sizes: []))
            host.frame = CGRect(x: 0, y: 0, width: vertical ? 100 : 70, height: vertical ? 70 : 100)
            let cases: [(sizes: [CGFloat], depth: CGFloat)] = [
                ([30, 30], 10), ([50, 50], 20), ([20], 10), ([30, 30, 30], 20), ([], 0), ([30, 30], 10),
            ]
            for scenario in cases {
                host.rootView = CacheRefreshScene(layout: layout, vertical: vertical, sizes: scenario.sizes)
                host.layoutSubtreeIfNeeded()
                let expected = CGSize(width: vertical ? scenario.depth : 70, height: vertical ? 70 : scenario.depth)
                #expect(host.fittingSize == expected, "Updated dimensions and child identities must replace the previous cache")
            }
        }

        private struct CacheRefreshScene: View {
            let layout: AnyLayout
            let vertical: Bool
            let sizes: [CGFloat]

            var body: some View {
                layout {
                    ForEach(Array(sizes.enumerated()), id: \.offset) { item in
                        Color.clear.frame(width: vertical ? 10 : item.element, height: vertical ? item.element : 10)
                    }
                }
                .frame(width: vertical ? nil : 70, height: vertical ? 70 : nil)
            }
        }

        private func guides(in layout: AnyLayout, direction: LayoutDirection) -> [CGFloat?] {
            let capture = Capture()
            let host = NSHostingView(
                rootView: GuideReader(capture: capture) {
                    layout {
                        Color.red.frame(width: 40, height: 20)
                            .layoutValue(key: PlacementReporterKey.self, value: { _, _ in })
                            .alignmentGuide(.flowTestHorizontal) { $0.width / 3 }
                            .alignmentGuide(.flowTestVertical) { $0.height / 4 }
                        Text("A\nB").font(.system(size: 16)).frame(width: 50)
                        Color.blue.frame(width: 20, height: 10)
                            .alignmentGuide(.flowTestHorizontal) { $0.width / 2 }
                            .alignmentGuide(.flowTestVertical) { $0.height / 2 }
                    }
                }.environment(\.layoutDirection, direction)
            )
            host.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            host.layoutSubtreeIfNeeded()
            _ = host.fittingSize
            return capture.values
        }

        private final class Capture: @unchecked Sendable {
            private let lock = NSLock()
            private var storedValues: [CGFloat?] = []

            var values: [CGFloat?] {
                get {
                    lock.lock()
                    defer { lock.unlock() }
                    return storedValues
                }
                set {
                    lock.lock()
                    defer { lock.unlock() }
                    storedValues = newValue
                }
            }
        }

        private struct GuideReader: Layout {
            let capture: Capture

            func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
                let dimensions = subviews[0].dimensions(in: ProposedViewSize(width: 80, height: 80))
                capture.values = [
                    dimensions[explicit: .leading], dimensions[explicit: .center as HorizontalAlignment], dimensions[explicit: .trailing],
                    dimensions[explicit: .flowTestHorizontal],
                    dimensions[explicit: .top], dimensions[explicit: .center as VerticalAlignment], dimensions[explicit: .bottom],
                    dimensions[explicit: .firstTextBaseline], dimensions[explicit: .lastTextBaseline], dimensions[explicit: .flowTestVertical],
                ]
                return CGSize(width: dimensions.width, height: dimensions.height)
            }

            func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
                subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: 80, height: 80))
            }
        }

        /// Intentionally inherits SwiftUI's default explicitAlignment implementation as the reference.
        private struct DefaultAlignmentLayout: Layout {
            let engine: FlowLayout

            func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) -> CGSize {
                engine.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
            }

            func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) {
                engine.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
            }

            func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
                FlowLayoutCache(subviews, axis: engine.axis)
            }
        }
    }

    private enum FlowTestHorizontal: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.width / 2 }
    }

    private enum FlowTestVertical: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height / 2 }
    }

    extension HorizontalAlignment {
        fileprivate static let flowTestHorizontal = HorizontalAlignment(FlowTestHorizontal.self)
    }

    extension VerticalAlignment {
        fileprivate static let flowTestVertical = VerticalAlignment(FlowTestVertical.self)
    }
#endif
