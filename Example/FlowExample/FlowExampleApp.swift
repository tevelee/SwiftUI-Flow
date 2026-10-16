import Flow
import SwiftUI

@main
struct FlowExampleApp: App {
    var body: some Scene {
        Window("Flow Example", id: "main") {
            if CommandLine.arguments.contains("--line-separator-accessibility-fixture") {
                FlowLineSeparatorAccessibilityFixture()
            } else if CommandLine.arguments.contains("--flow-accessibility-fixture") {
                FlowAccessibilityFixture()
            } else {
                ContentView()
            }
        }
        .defaultSize(width: 1180, height: 760)
    }
}

private struct FlowLineSeparatorAccessibilityFixture: View {
    @State private var wide = false
    @State private var lastActivation = "none"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button("Resize") { wide.toggle() }.accessibilityIdentifier("resize")
            HFlow(spacing: 4) {
                ForEach(0 ..< 8) { index in
                    Button("Tile \(index)") { lastActivation = String(index) }
                        .buttonStyle(.plain)
                        .frame(width: 64, height: 24)
                        .accessibilityIdentifier("tile-\(index)")
                }
            }
            .lineSeparator {
                Button("Boundary") { lastActivation = "boundary" }
                    .buttonStyle(.plain)
                    .frame(height: 20)
                    .accessibilityIdentifier("line-separator")
            }
            .frame(width: wide ? 320 : 140)
            Text(lastActivation).accessibilityIdentifier("last-activation")
        }
        .padding(30)
        .frame(width: 400, height: 480, alignment: .topLeading)
    }
}

/// Explicit UI-test entry point; normal example launches keep their existing content.
private struct FlowAccessibilityFixture: View {
    @State private var expanded = false
    @State private var lastActivation = "none"
    @FocusState private var focusedItem: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button("Expand") { expanded = true }.accessibilityIdentifier("expand")
            Button("Collapse") { expanded = false }.accessibilityIdentifier("collapse")
            Button("Start keyboard navigation") { focusedItem = 0 }.accessibilityIdentifier("start-focus")
            Button("Focus second item") { focusedItem = 1 }.accessibilityIdentifier("focus-second")
            configuredFlow
                .frame(width: 110, alignment: .leading)
            Text(lastActivation).accessibilityIdentifier("last-activation")
        }
        .padding(30)
        .frame(width: 360, height: 480, alignment: .topLeading)
    }

    private var buttons: some View {
        HFlow(itemSpacing: 0, rowSpacing: 0) {
            ForEach(0 ..< 4) { index in
                Button("Item \(index)") { lastActivation = String(index) }
                    .frame(width: 60, height: 30)
                    .accessibilityIdentifier("item-\(index)")
                    .accessibilityHidden(index == 3)
                    .focused($focusedItem, equals: index)
            }
        }
    }

    @ViewBuilder private var configuredFlow: some View {
        if CommandLine.arguments.contains("--cap-only") {
            buttons.maxLines(expanded ? Int.max : 1)
        } else if CommandLine.arguments.contains("--no-separators") {
            buttons.maxLines(expanded ? Int.max : 1) { _ in overflow }
        } else {
            buttons
                .itemSeparator { Text("|").frame(width: 5).accessibilityIdentifier("separator") }
                .maxLines(expanded ? Int.max : 1) { _ in overflow }
        }
    }

    private var overflow: some View {
        Button("More") { lastActivation = "overflow" }.frame(width: 40, height: 30).accessibilityIdentifier("overflow")
            .focused($focusedItem, equals: 4)
    }
}
