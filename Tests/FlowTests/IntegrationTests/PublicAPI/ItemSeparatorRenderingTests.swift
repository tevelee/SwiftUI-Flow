#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.tags(.requirements))
    @MainActor
    struct ItemSeparatorRenderingTests {
        @Test(.tags(.regression), arguments: [false, true], [false, true])
        func trailingContentSeparator_doesNotOverrideOverflow(vertical: Bool, empty: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                if empty {
                    ItemSeparator { EmptyView() }
                } else {
                    ItemSeparator { box(50, vertical: vertical) }
                }
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            .itemSeparator { box(5, vertical: vertical) }
            .maxLines(1) { _ in box(20, vertical: vertical) }

            #expect(size(view, breadth: 100, vertical: vertical) == dimensions(65, 10, vertical: vertical))
        }

        @Test(.tags(.regression), arguments: [false, true])
        func trailingContentSeparator_withoutDefault_isIgnored(vertical: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                ItemSeparator { box(50, vertical: vertical) }
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            .maxLines(1) { _ in box(20, vertical: vertical) }

            #expect(size(view, breadth: 70, vertical: vertical) == dimensions(55, 10, vertical: vertical))
        }

        @Test(.tags(.regression), arguments: [false, true], [false, true])
        func legacyOverflowBuilder_preservesSeparatorOwnership(vertical: Bool, inOverflowBuilder: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                if !inOverflowBuilder {
                    ItemSeparator { box(2, vertical: vertical) }
                }
            }
            let interleaved = _VariadicView.Tree(
                SeparatorInterleaver(
                    itemSeparator: { AnyView(box(5, vertical: vertical)) },
                    lineSeparator: nil
                )
            ) { content }
            let layout =
                vertical
                ? AnyLayout(VFlowLayout(itemSpacing: 5, columnSpacing: 0).withMaxLines(1))
                : AnyLayout(HFlowLayout(itemSpacing: 5, rowSpacing: 0).withMaxLines(1))
            let view = _FlowWithOverflow(layout: layout, content: interleaved) { _ in
                Group {
                    if inOverflowBuilder {
                        ItemSeparator { box(2, vertical: vertical) }
                    }
                    box(20, vertical: vertical)
                }
            }

            #expect(size(view, breadth: 107, vertical: vertical) == dimensions(inOverflowBuilder ? 107 : 65, 10, vertical: vertical))
        }

        @Test(arguments: [false, true], [0, 1, 2, 3])
        func overflowBuilder_separator_controlsFitting(vertical: Bool, mode: Int) {
            let content = Group {
                box(30, vertical: vertical)
                box(30, vertical: vertical)
                box(30, vertical: vertical)
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            .itemSeparator { box(5, vertical: vertical) }
            .maxLines(1) { _ in
                if mode == 1 {
                    ItemSeparator { EmptyView() }
                } else if mode == 2 {
                    ItemSeparator { box(2, vertical: vertical) }
                } else if mode == 3 {
                    ItemSeparator { box(50, vertical: vertical) }
                    ItemSeparator { EmptyView() }
                }
                box(20, vertical: vertical)
            }
            if mode == 0 {
                #expect(size(view, breadth: 100, vertical: vertical) == dimensions(65, 10, vertical: vertical))
            } else if mode == 2 {
                #expect(size(view, breadth: 107, vertical: vertical) == dimensions(107, 10, vertical: vertical))
                #expect(size(view, breadth: 106, vertical: vertical) == dimensions(62, 10, vertical: vertical))
            } else {
                #expect(size(view, breadth: 100, vertical: vertical) == dimensions(100, 10, vertical: vertical))
                #expect(size(view, breadth: 99, vertical: vertical) == dimensions(55, 10, vertical: vertical))
            }
        }

        @Test(arguments: [false, true])
        func overflowBuilder_customSeparator_withoutDefault(vertical: Bool) {
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) {
                        box(30, vertical: true)
                        box(30, vertical: true)
                        box(30, vertical: true)
                    }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) {
                        box(30, vertical: false)
                        box(30, vertical: false)
                        box(30, vertical: false)
                    }
                }
            }
            .maxLines(1) { _ in
                ItemSeparator { box(2, vertical: vertical) }
                box(20, vertical: vertical)
            }
            #expect(size(view, breadth: 97, vertical: vertical) == dimensions(97, 10, vertical: vertical))
            #expect(size(view, breadth: 96, vertical: vertical) == dimensions(62, 10, vertical: vertical))
            #expect(size(view, breadth: 20, vertical: vertical) == dimensions(20, 10, vertical: vertical))
            #expect(size(view, breadth: 100, vertical: vertical) == dimensions(100, 10, vertical: vertical))
        }

        @Test(arguments: [false, true])
        func nilSpacing_usesSubviewPreferences(vertical: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                ItemSeparator { box(20, vertical: vertical) }
                box(30, vertical: vertical)
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: nil, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: nil, rowSpacing: 0) { content }
                }
            }
            #expect(size(view, breadth: 96, vertical: vertical) == dimensions(96, 10, vertical: vertical))
            #expect(size(view, breadth: 95, vertical: vertical) == dimensions(30, 20, vertical: vertical))
        }
        @Test(arguments: [false, true], [false, true])
        func explicitSeparator_replacesDefault_andReservesSpacing(vertical: Bool, legacy: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                ItemSeparator { box(20, vertical: vertical) }
                box(30, vertical: vertical)
                box(30, vertical: vertical)
            }
            let view = flow(vertical: vertical, legacy: legacy, content: content)
            #expect(size(view, breadth: 135, vertical: vertical) == dimensions(135, 10, vertical: vertical))
            #expect(size(view, breadth: 89, vertical: vertical) == dimensions(75, 20, vertical: vertical))
        }

        @Test(arguments: [false, true], [false, true])
        func emptySeparator_keepsSingleOrdinaryGap(vertical: Bool, legacy: Bool) {
            let view = flow(
                vertical: vertical,
                legacy: legacy,
                content: Group {
                    box(30, vertical: vertical)
                    ItemSeparator { EmptyView() }
                    box(30, vertical: vertical)
                }
            )
            #expect(size(view, breadth: 65, vertical: vertical) == dimensions(65, 10, vertical: vertical))
            #expect(size(view, breadth: 64, vertical: vertical) == dimensions(30, 20, vertical: vertical))
        }

        @Test(arguments: [false, true])
        func explicitSeparator_worksWithoutDefault_andIgnoresEdges(vertical: Bool) {
            let content = Group {
                ItemSeparator { box(100, vertical: vertical) }
                box(30, vertical: vertical)
                ItemSeparator { box(20, vertical: vertical) }
                box(30, vertical: vertical)
                ItemSeparator { box(100, vertical: vertical) }
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            #expect(size(view, breadth: 90, vertical: vertical) == dimensions(90, 10, vertical: vertical))
            #expect(size(view, breadth: 89, vertical: vertical) == dimensions(30, 20, vertical: vertical))
        }

        @Test func builderGroupsMultipleViewsIntoOneSeparator() {
            let view = HFlow(itemSpacing: 5, rowSpacing: 0) {
                box(30, vertical: false)
                ItemSeparator {
                    box(20, vertical: false)
                    box(10, vertical: false)
                }
                box(30, vertical: false)
            }
            #expect(size(view, breadth: 90, vertical: false) == CGSize(width: 90, height: 10))
        }

        @Test(arguments: [false, true], [false, true])
        func lineBreak_survivesSeparatorEnumeration(vertical: Bool, legacy: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                LineBreak()
                box(30, vertical: vertical)
            }
            let view = flow(vertical: vertical, legacy: legacy, content: content)
            #expect(size(view, breadth: 200, vertical: vertical) == dimensions(30, 20, vertical: vertical))
        }

        @Test(arguments: [false, true], [false, true])
        func forcedContentStart_keepsLineSeparatorUnlikeBreakMarker(vertical: Bool, marker: Bool) {
            let content = Group {
                box(30, vertical: vertical)
                if marker { LineBreak() }
                box(30, vertical: vertical).startInNewLine(!marker)
            }
            let view = Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            .itemSeparator { box(5, vertical: vertical) }
            .lineSeparator { Color.clear.frame(width: vertical ? 2 : nil, height: vertical ? nil : 2) }
            #expect(size(view, breadth: 200, vertical: vertical) == dimensions(30, marker ? 20 : 22, vertical: vertical))
        }

        @ViewBuilder
        private func flow(vertical: Bool, legacy: Bool, content: some View) -> some View {
            if legacy {
                let layout = vertical ? AnyLayout(VFlowLayout(itemSpacing: 5, columnSpacing: 0)) : AnyLayout(HFlowLayout(itemSpacing: 5, rowSpacing: 0))
                layout {
                    _VariadicView.Tree(
                        SeparatorInterleaver(
                            itemSeparator: { AnyView(box(5, vertical: vertical)) },
                            lineSeparator: nil
                        )
                    ) { content }
                }
            } else if vertical {
                VFlow(itemSpacing: 5, columnSpacing: 0) { content }.itemSeparator { box(5, vertical: vertical) }
            } else {
                HFlow(itemSpacing: 5, rowSpacing: 0) { content }.itemSeparator { box(5, vertical: vertical) }
            }
        }

        private func box(_ breadth: CGFloat, vertical: Bool) -> some View {
            Color.red.frame(width: vertical ? 10 : breadth, height: vertical ? breadth : 10)
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
