#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.tags(.requirements))
    @MainActor
    struct FlowLayoutDirectionRequirementTests {
        @Test func HFlow_leftToRightLeadingAlignment_placesFinalRowAtLeadingEdge() {
            let frames = framesInRenderedView(
                size: 7 × 3,
                layoutDirection: .leftToRight
            ) {
                HFlow(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1) {
                    FrameProbe(id: 0, size: 3 × 1)
                    FrameProbe(id: 1, size: 3 × 1)
                    FrameProbe(id: 2, size: 3 × 1)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 3, height: 1))
            #expect(frames[1] == CGRect(x: 4, y: 0, width: 3, height: 1))
            #expect(frames[2] == CGRect(x: 0, y: 2, width: 3, height: 1))
        }

        @Test func HFlow_rightToLeftLeadingAlignment_mirrorsRowsAndPlacesFinalRowAtTrailingEdge() {
            let frames = framesInRenderedView(
                size: 7 × 3,
                layoutDirection: .rightToLeft
            ) {
                HFlow(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1) {
                    FrameProbe(id: 0, size: 3 × 1)
                    FrameProbe(id: 1, size: 3 × 1)
                    FrameProbe(id: 2, size: 3 × 1)
                }
            }

            #expect(frames[0] == CGRect(x: 4, y: 0, width: 3, height: 1))
            #expect(frames[1] == CGRect(x: 0, y: 0, width: 3, height: 1))
            #expect(frames[2] == CGRect(x: 4, y: 2, width: 3, height: 1))
        }

        @Test func VFlow_placesItemsInColumnsTopToBottom() {
            let frames = framesInRenderedView(
                size: 3 × 7,
                layoutDirection: .leftToRight
            ) {
                VFlow(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1) {
                    FrameProbe(id: 0, size: 1 × 3)
                    FrameProbe(id: 1, size: 1 × 3)
                    FrameProbe(id: 2, size: 1 × 3)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 1, height: 3))
            #expect(frames[1] == CGRect(x: 0, y: 4, width: 1, height: 3))
            #expect(frames[2] == CGRect(x: 2, y: 0, width: 1, height: 3))
        }

        // MARK: - View spacing-shortcut initializers

        @Test func HFlow_viewSpacingShortcutInit_placesItemsInRows() {
            let frames = framesInRenderedView(
                size: 7 × 3,
                layoutDirection: .leftToRight
            ) {
                HFlow(alignment: .top, spacing: 1) {
                    FrameProbe(id: 0, size: 3 × 1)
                    FrameProbe(id: 1, size: 3 × 1)
                    FrameProbe(id: 2, size: 3 × 1)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 3, height: 1))
            #expect(frames[1] == CGRect(x: 4, y: 0, width: 3, height: 1))
            #expect(frames[2] == CGRect(x: 0, y: 2, width: 3, height: 1))
        }

        @Test func HFlow_viewItemRowSpacingInit_appliesSeparateSpacings() {
            let frames = framesInRenderedView(
                size: 7 × 4,
                layoutDirection: .leftToRight
            ) {
                HFlow(alignment: .top, itemSpacing: 1, rowSpacing: 2) {
                    FrameProbe(id: 0, size: 3 × 1)
                    FrameProbe(id: 1, size: 3 × 1)
                    FrameProbe(id: 2, size: 3 × 1)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 3, height: 1))
            #expect(frames[1] == CGRect(x: 4, y: 0, width: 3, height: 1))
            #expect(frames[2] == CGRect(x: 0, y: 3, width: 3, height: 1))
        }

        @Test func VFlow_viewSpacingShortcutInit_placesItemsInColumns() {
            let frames = framesInRenderedView(
                size: 3 × 7,
                layoutDirection: .leftToRight
            ) {
                VFlow(alignment: .leading, spacing: 1) {
                    FrameProbe(id: 0, size: 1 × 3)
                    FrameProbe(id: 1, size: 1 × 3)
                    FrameProbe(id: 2, size: 1 × 3)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 1, height: 3))
            #expect(frames[1] == CGRect(x: 0, y: 4, width: 1, height: 3))
            #expect(frames[2] == CGRect(x: 2, y: 0, width: 1, height: 3))
        }

        @Test func VFlow_viewItemColumnSpacingInit_appliesSeparateSpacings() {
            let frames = framesInRenderedView(
                size: 4 × 7,
                layoutDirection: .leftToRight
            ) {
                VFlow(alignment: .leading, itemSpacing: 1, columnSpacing: 2) {
                    FrameProbe(id: 0, size: 1 × 3)
                    FrameProbe(id: 1, size: 1 × 3)
                    FrameProbe(id: 2, size: 1 × 3)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 1, height: 3))
            #expect(frames[1] == CGRect(x: 0, y: 4, width: 1, height: 3))
            #expect(frames[2] == CGRect(x: 3, y: 0, width: 1, height: 3))
        }

        // MARK: - Layout conformance methods (HFlow/VFlow as EmptyView Layout containers)

        @Test func HFlow_asLayoutContainer_exercisesLayoutConformanceMethods() {
            let frames = framesInRenderedView(
                size: 7 × 3,
                layoutDirection: .leftToRight
            ) {
                HFlow<EmptyView>(alignment: .top, itemSpacing: 1, rowSpacing: 1) {
                    FrameProbe(id: 0, size: 3 × 1)
                    FrameProbe(id: 1, size: 3 × 1)
                    FrameProbe(id: 2, size: 3 × 1)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 3, height: 1))
            #expect(frames[1] == CGRect(x: 4, y: 0, width: 3, height: 1))
            #expect(frames[2] == CGRect(x: 0, y: 2, width: 3, height: 1))
        }

        @Test func VFlow_asLayoutContainer_exercisesLayoutConformanceMethods() {
            let frames = framesInRenderedView(
                size: 3 × 7,
                layoutDirection: .leftToRight
            ) {
                VFlow<EmptyView>(alignment: .leading, itemSpacing: 1, columnSpacing: 1) {
                    FrameProbe(id: 0, size: 1 × 3)
                    FrameProbe(id: 1, size: 1 × 3)
                    FrameProbe(id: 2, size: 1 × 3)
                }
            }

            #expect(frames[0] == CGRect(x: 0, y: 0, width: 1, height: 3))
            #expect(frames[1] == CGRect(x: 0, y: 4, width: 1, height: 3))
            #expect(frames[2] == CGRect(x: 2, y: 0, width: 1, height: 3))
        }
    }

    private let frameProbeCoordinateSpace = "FlowFrameProbeCoordinateSpace"

    private final class FrameProbeRecorder {
        var frames: [Int: CGRect] = [:]
    }

    private struct FrameProbe: View {
        let id: Int
        let size: CGSize

        var body: some View {
            Color.clear
                .frame(width: size.width, height: size.height)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: FrameProbePreferenceKey.self,
                            value: [id: proxy.frame(in: .named(frameProbeCoordinateSpace))]
                        )
                    }
                }
        }
    }

    private struct FrameProbePreferenceKey: PreferenceKey {
        static let defaultValue: [Int: CGRect] = [:]

        static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }

    @MainActor
    private func framesInRenderedView<Content: View>(
        size: CGSize,
        layoutDirection: LayoutDirection,
        @ViewBuilder content: () -> Content
    ) -> [Int: CGRect] {
        let recorder = FrameProbeRecorder()
        let root = content()
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .coordinateSpace(name: frameProbeCoordinateSpace)
            .environment(\.layoutDirection, layoutDirection)
            .onPreferenceChange(FrameProbePreferenceKey.self) { frames in
                recorder.frames = frames
            }

        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: size)
        hosting.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        hosting.layoutSubtreeIfNeeded()
        return recorder.frames
    }
#endif
