#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    @Suite(.tags(.requirements, .regression))
    @MainActor
    struct FlowLegacyVisibilityTests {
        @Test(arguments: [false, true], [false, true])
        func visibilityEnumeration_preservesMetadataAndSingleReportRoute(legacy: Bool, hideFirst: Bool) {
            let metadata = Metadata()
            let hidden: Set<Int> = hideFirst ? [0, 1] : [1]
            let host = NSHostingView(
                rootView: MetadataLayout(metadata: metadata) {
                    let content = Group {
                        Color.clear.frame(width: 10, height: 10).flexibility(.maximum).startInNewLine()
                        ItemSeparator { Text("|") }
                        LineBreak()
                        Color.clear.layoutValue(key: FlowSubviewRoleLayoutValueKey.self, value: .pooledLineSeparator(3))
                            ._trait(FlowSubviewRoleLayoutValueKey.self, .pooledLineSeparator(3))
                        Color.clear.frame(width: 5, height: 5).overflowIndicator()
                    }
                    if legacy {
                        legacyReportedFlowContent(content, hidden: hidden, reporter: { _, _ in })
                    } else {
                        reportedFlowContent(content, hidden: hidden, reporter: { _, _ in })
                    }
                }
            )
            _ = host.fittingSize
            #expect(metadata.reporterIndices == [0], "The route belongs to one resolved leaf, including on the legacy path")
            #expect(metadata.roles == [.content, .itemSeparatorOverride(isEmpty: false), .lineBreak, .pooledLineSeparator(3), .content])
            #expect(metadata.overflow == [false, false, false, false, true])
            #expect(metadata.starts == [true, false, false, false, false])
            #expect(metadata.flexibility == [.maximum, .natural, .natural, .natural, .natural])
        }
    }

    private final class Metadata {
        var reporterIndices: [Int] = []
        var roles: [FlowSubviewRole] = []
        var overflow: [Bool] = []
        var starts: [Bool] = []
        var flexibility: [FlexibilityBehavior] = []
    }

    private struct MetadataLayout: Layout {
        let metadata: Metadata

        func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
            metadata.reporterIndices = subviews.indices.filter { subviews[$0][PlacementReporterKey.self] != nil }
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
