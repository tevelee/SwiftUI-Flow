#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.tags(.requirements))
    @MainActor
    struct FlowFeatureRoutingTests {
        enum Feature: CaseIterable, Sendable {
            case plain, capped, overflow, itemSeparator, lineSeparator, combined
        }

        @Test(arguments: [false, true], Feature.allCases)
        func featureRoutes_preserveWrapping(vertical: Bool, feature: Feature) {
            let content = Group {
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                box(30, vertical: vertical)
            }
            let view = configured(flow(content, vertical: vertical), feature: feature, vertical: vertical)
            let expected: (breadth: CGFloat, depth: CGFloat)
            switch feature {
                case .plain: expected = (65, 20)
                case .capped: expected = (65, 10)
                case .overflow: expected = (55, 10)
                case .itemSeparator: expected = (30, 30)
                case .lineSeparator: expected = (65, 22)
                case .combined: expected = (65, 22)
            }
            #expect(size(view, breadth: 70, vertical: vertical) == dimensions(expected.breadth, expected.depth, vertical: vertical))
        }

        @Test(arguments: [false, true], Feature.allCases)
        func featureRoutes_scopeConfigurationToOuterFlow(vertical: Bool, feature: Feature) {
            let inner = flow(
                Group {
                    box(30, vertical: vertical)
                    box(30, vertical: vertical)
                    box(30, vertical: vertical)
                },
                vertical: vertical
            )
            .frame(width: vertical ? nil : 65, height: vertical ? 65 : nil)
            let view = configured(flow(inner, vertical: vertical), feature: feature, vertical: vertical)
            #expect(size(view, breadth: 70, vertical: vertical) == dimensions(65, 20, vertical: vertical))
        }

        @ViewBuilder
        private func configured(_ view: some View, feature: Feature, vertical: Bool) -> some View {
            switch feature {
                case .plain: view
                case .capped: view.maxLines(1)
                case .overflow: view.maxLines(1) { _ in box(20, vertical: vertical) }
                case .itemSeparator: view.itemSeparator { box(5, vertical: vertical) }
                case .lineSeparator: view.lineSeparator { separator(vertical: vertical) }
                case .combined:
                    view.maxLines(2) { _ in box(20, vertical: vertical) }
                        .itemSeparator { box(5, vertical: vertical) }
                        .lineSeparator { separator(vertical: vertical) }
            }
        }

        @ViewBuilder
        private func flow(_ content: some View, vertical: Bool) -> some View {
            if vertical {
                VFlow(itemSpacing: 5, columnSpacing: 0) { content }
            } else {
                HFlow(itemSpacing: 5, rowSpacing: 0) { content }
            }
        }

        private func separator(vertical: Bool) -> some View {
            Color.clear.frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
        }

        private func box(_ breadth: CGFloat, vertical: Bool) -> some View {
            Color.clear.frame(width: vertical ? 10 : breadth, height: vertical ? breadth : 10)
        }

        private func dimensions(_ breadth: CGFloat, _ depth: CGFloat, vertical: Bool) -> CGSize {
            CGSize(width: vertical ? depth : breadth, height: vertical ? breadth : depth)
        }

        private func size(_ view: some View, breadth: CGFloat, vertical: Bool) -> CGSize? {
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(width: vertical ? nil : breadth, height: vertical ? breadth : nil)
            return renderer.nsImage?.size
        }
    }
#endif
