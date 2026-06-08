#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing
    import SnapshotTesting
    @testable import Flow

    // MARK: - macOS SwiftUI Image Strategy

    extension Snapshotting where Value: SwiftUI.View, Format == NSImage {
        @MainActor
        static func image(precision: Float = 1, perceptualPrecision: Float = 1, size: CGSize) -> Snapshotting {
            Snapshotting<NSView, NSImage>.image(precision: precision, perceptualPrecision: perceptualPrecision, size: size).pullback { view in
                let hosting = NSHostingView(rootView: view.environment(\.colorScheme, .light))
                hosting.frame.size = size
                return hosting
            }
        }
    }

    // MARK: - Reusable View Components

    private let tagColors: [Color] = [.blue, .orange, .green, .yellow, .brown, .mint, .indigo, .cyan, .gray, .pink]
    private let tagWidths: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]
    private let tagHeights: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]

    private struct ColorBoxes: View {
        let widths: [CGFloat]
        let height: CGFloat

        var body: some View {
            ForEach(Array(zip(tagColors, widths).enumerated()), id: \.offset) { _, pair in
                RoundedRectangle(cornerRadius: 10)
                    .fill(pair.0.gradient)
                    .frame(width: pair.1, height: height)
            }
        }
    }

    private struct VariableHeightBoxes: View {
        let width: CGFloat
        let heights: [CGFloat]

        var body: some View {
            ForEach(Array(zip(tagColors, heights).enumerated()), id: \.offset) { _, pair in
                RoundedRectangle(cornerRadius: 10)
                    .fill(pair.0.gradient)
                    .frame(width: width, height: pair.1)
            }
        }
    }

    private struct TagCloud: View {
        let tags = ["Swift", "SwiftUI", "Flow", "Layout", "HStack", "VStack", "Flexible", "iOS", "macOS", "Open Source", "SPM", "Xcode"]

        var body: some View {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue.opacity(0.15)))
            }
        }
    }

    private struct TextBaselinePill: View {
        let text: String
        let font: Font
        let tint: Color

        var body: some View {
            Text(text)
                .font(font)
                .foregroundStyle(.black)
                .lineLimit(nil)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(tint, lineWidth: 1))
        }
    }

    // MARK: - HFlow Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct HFlowImageSnapshots {
        @Test func hflow_colorBoxes() {
            let view = HFlow(spacing: 8) {
                ColorBoxes(widths: tagWidths, height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func tagCloud() {
            let view = HFlow(spacing: 8) {
                TagCloud()
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test(arguments: VerticalAlignment.allCases)
        func verticalAlignment(_ alignment: VerticalAlignment) {
            let view = HFlow(alignment: alignment, spacing: 8) {
                VariableHeightBoxes(width: 50, heights: tagHeights)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(
                of: view,
                as: .image(size: CGSize(width: 320, height: 300)),
                named: alignment.testDescription
            )
        }

        @Test func centerAligned_tagCloud() {
            let view = HFlow(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 8, verticalSpacing: 8) {
                TagCloud()
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }
    }

    // MARK: - Text Baseline Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot, .regression))
    @MainActor
    struct TextBaselineImageSnapshots {
        @Test func firstTextBaseline_textPills() {
            let view = HFlow(alignment: .firstTextBaseline, itemSpacing: 8, rowSpacing: 12) {
                TextBaselinePill(text: "Large", font: .system(size: 34, weight: .bold), tint: .blue)
                TextBaselinePill(text: "small", font: .system(size: 14), tint: .orange)
                TextBaselinePill(text: "Title", font: .title2, tint: .green)
                TextBaselinePill(text: "caption", font: .caption, tint: .pink)
                TextBaselinePill(text: "Body", font: .body, tint: .purple)
            }
            .frame(width: 300, alignment: .leading)
            .padding(12)
            .background(Color.white)

            assertSnapshot(of: view, as: .image(size: CGSize(width: 340, height: 140)))
        }

        @Test func lastTextBaseline_multilineText() {
            let view = HFlow(alignment: .lastTextBaseline, itemSpacing: 8, rowSpacing: 12) {
                TextBaselinePill(text: "Tall", font: .system(size: 32, weight: .semibold), tint: .blue)
                TextBaselinePill(text: "Two\nLines", font: .system(size: 16), tint: .orange)
                TextBaselinePill(text: "Small", font: .caption, tint: .green)
                TextBaselinePill(text: "Last\nBaseline", font: .title3, tint: .purple)
            }
            .frame(width: 300, alignment: .leading)
            .padding(12)
            .background(Color.white)

            assertSnapshot(of: view, as: .image(size: CGSize(width: 340, height: 170)))
        }

        @Test func firstTextBaseline_textPills_accessibilityLarge() {
            let view = HFlow(alignment: .firstTextBaseline, itemSpacing: 8, rowSpacing: 12) {
                TextBaselinePill(text: "Large", font: .system(size: 34, weight: .bold), tint: .blue)
                TextBaselinePill(text: "small", font: .system(size: 14), tint: .orange)
                TextBaselinePill(text: "Title", font: .title2, tint: .green)
                TextBaselinePill(text: "caption", font: .caption, tint: .pink)
                TextBaselinePill(text: "Body", font: .body, tint: .purple)
            }
            .frame(width: 300, alignment: .leading)
            .padding(12)
            .background(Color.white)
            .environment(\.dynamicTypeSize, .accessibility3)

            assertSnapshot(of: view, as: .image(size: CGSize(width: 340, height: 260)))
        }

        @Test func lastTextBaseline_multilineText_accessibilityLarge() {
            let view = HFlow(alignment: .lastTextBaseline, itemSpacing: 8, rowSpacing: 12) {
                TextBaselinePill(text: "Tall", font: .system(size: 32, weight: .semibold), tint: .blue)
                TextBaselinePill(text: "Two\nLines", font: .system(size: 16), tint: .orange)
                TextBaselinePill(text: "Small", font: .caption, tint: .green)
                TextBaselinePill(text: "Last\nBaseline", font: .title3, tint: .purple)
            }
            .frame(width: 300, alignment: .leading)
            .padding(12)
            .background(Color.white)
            .environment(\.dynamicTypeSize, .accessibility3)

            assertSnapshot(of: view, as: .image(size: CGSize(width: 340, height: 300)))
        }
    }

    // MARK: - VFlow Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct VFlowImageSnapshots {
        @Test func vflow_colorBoxes() {
            let view = VFlow(spacing: 8) {
                VariableHeightBoxes(width: 50, heights: tagHeights)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 300, height: 320)))
        }
    }

    // MARK: - Spacing Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct SpacingImageSnapshots {
        @Test func compact() {
            let view = HFlow(itemSpacing: 4, rowSpacing: 4) {
                ColorBoxes(widths: tagWidths, height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func spacious() {
            let view = HFlow(itemSpacing: 4, rowSpacing: 20) {
                ColorBoxes(widths: tagWidths, height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }
    }

    // MARK: - Justified & Distributed Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct JustifiedDistributedImageSnapshots {
        @Test func justified() {
            let view = HFlow(spacing: 8, justified: true) {
                ColorBoxes(widths: Array(repeating: 50, count: 10), height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }

        @Test func distributed() {
            let view = HFlow(spacing: 8, distributeItemsEvenly: true) {
                ColorBoxes(widths: Array(repeating: 65, count: 10), height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }
    }

    // MARK: - Flexibility Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct FlexibilityImageSnapshots {
        @Test func mixedFlexibility() {
            let view = HFlow(spacing: 8) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.gradient)
                    .frame(minWidth: 50, maxWidth: .infinity)
                    .frame(height: 50)
                    .flexibility(.minimum)
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.gradient)
                    .frame(minWidth: 50, maxWidth: .infinity)
                    .frame(height: 50)
                    .flexibility(.natural)
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue.gradient)
                    .frame(minWidth: 50, maxWidth: .infinity)
                    .frame(height: 50)
                    .flexibility(.natural)
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.gradient)
                    .frame(minWidth: 50, maxWidth: .infinity)
                    .frame(height: 50)
                    .flexibility(.maximum)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 140)))
        }
    }

    // MARK: - Line Break Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct LineBreakImageSnapshots {
        @Test func lineBreak() {
            let view = HFlow(spacing: 8) {
                RoundedRectangle(cornerRadius: 10).fill(.red.gradient).frame(width: 50, height: 50)
                RoundedRectangle(cornerRadius: 10).fill(.green.gradient).frame(width: 50, height: 50)
                RoundedRectangle(cornerRadius: 10).fill(.blue.gradient).frame(width: 50, height: 50)
                LineBreak()
                RoundedRectangle(cornerRadius: 10).fill(.yellow.gradient).frame(width: 50, height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 150)))
        }

        @Test func startInNewLine() {
            let view = HFlow(spacing: 8) {
                RoundedRectangle(cornerRadius: 10).fill(.red.gradient).frame(width: 50, height: 50)
                RoundedRectangle(cornerRadius: 10).fill(.green.gradient).frame(width: 50, height: 50)
                    .startInNewLine()
                RoundedRectangle(cornerRadius: 10).fill(.blue.gradient).frame(width: 50, height: 50)
                RoundedRectangle(cornerRadius: 10).fill(.yellow.gradient).frame(width: 50, height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 150)))
        }
    }

    // MARK: - Issue #36: maxWidth: .infinity in VFlow

    @Suite(.tags(.snapshot, .imageSnapshot, .regression))
    @MainActor
    struct Issue36ImageSnapshots {
        @Test func vflow_maxWidthHeader() {
            let items: [(CGFloat, Color)] = [
                (120, .red), (80, .orange), (160, .yellow),
                (100, .green), (140, .blue), (90, .purple),
            ]
            let view = VFlow(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, pair in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Header")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(4)
                            .background(Color.black.opacity(0.12))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(pair.1)
                            .frame(width: 80, height: pair.0)
                    }
                    .padding(6)
                    .background(pair.1.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .frame(maxHeight: 320)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 420, height: 360)))
        }
    }
#endif
