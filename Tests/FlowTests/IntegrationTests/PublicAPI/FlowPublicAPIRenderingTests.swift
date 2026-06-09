#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    /// Tests for public SwiftUI view modifiers (`LineBreak`, `.startInNewLine()`, `.flexibility()`)
    /// using real HFlow rendering to ensure the modifiers are correctly wired to the layout engine.
    @Suite(.tags(.requirements))
    @MainActor
    struct FlowPublicAPIRenderingTests {

        @Test func lineBreak_forcesNewRow() {
            // 3 items × 50pt = 150pt fits in 200pt → 1 row without a break (height 50).
            // LineBreak() between item 1 and items 2–3 splits them: row1=50pt, row2=100pt → height 100.
            // Exercises LineBreak.init() and LineBreak.body.
            let withoutBreak = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(width: 50, height: 50)
                },
                width: 200
            )
            let withBreak = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    LineBreak()
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(width: 50, height: 50)
                },
                width: 200
            )
            #expect(withoutBreak == 50)
            #expect(withBreak == 100)
        }

        @Test func startInNewLine_forcesNewRow() {
            // 2 items × 50pt = 100pt fits in 200pt → 1 row without the modifier (height 50).
            // .startInNewLine() on the second item forces it to a new row → height 100.
            // Exercises View.startInNewLine(_:).
            let withoutModifier = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(width: 50, height: 50)
                },
                width: 200
            )
            let withModifier = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(width: 50, height: 50).startInNewLine()
                },
                width: 200
            )
            #expect(withoutModifier == 50)
            #expect(withModifier == 100)
        }

        @Test func flexibilityMaximum_forcesOwnRow() {
            // A .maximum flexible item that can expand to fill a row gets forced onto its own row.
            // Without .flexibility(.maximum): 3 items fit on one row → height 50.
            // With .flexibility(.maximum) on middle item: it fills its own row → 3 rows → height 150.
            // Exercises View.flexibility(_:) and EnvironmentValues.flexibility.setter.
            let withoutModifier = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(minWidth: 50, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    Color.clear.frame(width: 50, height: 50)
                },
                width: 200
            )
            let withModifier = measuredHeight(
                of: HFlow(itemSpacing: 0, rowSpacing: 0) {
                    Color.clear.frame(width: 50, height: 50)
                    Color.clear.frame(minWidth: 50, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                        .flexibility(.maximum)
                    Color.clear.frame(width: 50, height: 50)
                },
                width: 200
            )
            #expect(withoutModifier == 50)
            #expect(withModifier == 150)
        }
    }

    @MainActor
    private func measuredHeight(of view: some View, width: CGFloat) -> CGFloat {
        let host = NSHostingView(rootView: AnyView(view.frame(width: width)))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 800),
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        window.contentView = host
        var prev = host.fittingSize.height
        for _ in 0 ..< 10 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            let next = host.fittingSize.height
            if next == prev { break }
            prev = next
        }
        return host.fittingSize.height
    }
#endif
