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

        private func guides(in layout: AnyLayout, direction: LayoutDirection) -> [CGFloat?] {
            let capture = Capture()
            let host = NSHostingView(
                rootView: GuideReader(capture: capture) {
                    layout {
                        Color.red.frame(width: 40, height: 20)
                            .layoutValue(key: LineStructureReporterKey.self, value: { _ in })
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
