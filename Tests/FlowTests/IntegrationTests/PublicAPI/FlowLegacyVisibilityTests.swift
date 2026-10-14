#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.tags(.requirements, .regression))
    @MainActor
    struct FlowLegacyVisibilityTests {
        @Test func legacyEnumeration_preservesLayoutMetadata() {
            let metadata = Metadata()
            let host = NSHostingView(
                rootView: MetadataLayout(metadata: metadata) {
                    legacyReportedFlowContent(
                        Group {
                            Color.clear.frame(width: 10, height: 10).flexibility(.maximum).startInNewLine()
                            ItemSeparator { Text("|") }
                            LineBreak()
                            Color.clear.frame(width: 5, height: 5).overflowIndicator()
                        },
                        hidden: [1]
                    )
                }
            )
            _ = host.fittingSize
            #expect(metadata.roles == [.content, .itemSeparatorOverride(isEmpty: false), .lineBreak, .content])
            #expect(metadata.overflow == [false, false, false, true])
            #expect(metadata.starts == [true, false, false, false])
            #expect(metadata.flexibility == [.maximum, .natural, .natural, .natural])
        }
    }

    private final class Metadata {
        var roles: [FlowSubviewRole] = []
        var overflow: [Bool] = []
        var starts: [Bool] = []
        var flexibility: [FlexibilityBehavior] = []
    }

    private struct MetadataLayout: Layout {
        let metadata: Metadata

        func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
            metadata.roles = subviews.map { $0[FlowSubviewRoleLayoutValueKey.self] }
            metadata.overflow = subviews.map { $0[FlowSubviewOriginLayoutValueKey.self] == .overflowBuilder }
            metadata.starts = subviews.map { $0[ShouldStartInNewLineLayoutValueKey.self] }
            metadata.flexibility = subviews.map { $0[FlexibilityLayoutValueKey.self] }
            return CGSize(width: 10, height: 10)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
            for subview in subviews { subview.place(at: .zero, proposal: .zero) }
        }
    }
#endif
