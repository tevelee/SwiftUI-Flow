#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SnapshotTesting
@testable import Flow

// MARK: - macOS SwiftUI Image Strategy

extension Snapshotting where Value: SwiftUI.View, Format == NSImage {
    @MainActor
    static func image(precision: Float = 1, size: CGSize) -> Snapshotting {
        Snapshotting<NSView, NSImage>.image(precision: precision, size: size).pullback { view in
            let hosting = NSHostingView(rootView: view)
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

// MARK: - HFlow Image Snapshots

@Suite
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

// MARK: - VFlow Image Snapshots

@Suite
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

@Suite
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

@Suite
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

@Suite
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

@Suite
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
#endif
