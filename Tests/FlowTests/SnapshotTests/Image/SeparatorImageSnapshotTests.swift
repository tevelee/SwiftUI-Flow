#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing
    import SnapshotTesting
    @testable import Flow

    // MARK: - Separator Image Snapshots

    @Suite(.tags(.snapshot, .imageSnapshot))
    @MainActor
    struct SeparatorImageSnapshots {
        private let tags = ["Swift", "SwiftUI", "Flow", "Layout", "Stack", "Flexible", "iOS", "macOS", "SPM", "Xcode"]

        private func tag(_ text: String) -> some View {
            Text(text)
                .font(.callout)
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.blue.opacity(0.15)))
        }

        @Test func itemSeparator_dots() {
            let view = HFlow(itemSpacing: 8, rowSpacing: 10) {
                ForEach(tags, id: \.self) { tag($0) }
            }
            .itemSeparator {
                Text("•").font(.callout).foregroundStyle(.secondary)
            }
            .frame(width: 320, alignment: .leading)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 344, height: 220)))
        }

        @Test func explicitItemSeparators() {
            let view = HFlow(itemSpacing: 6, rowSpacing: 6) {
                tag("Alpha")
                ItemSeparator { Text("|").foregroundStyle(.black) }
                tag("Beta")
                tag("Gamma")
                ItemSeparator { EmptyView() }
                tag("Delta")
            }
            .itemSeparator { Text("•").foregroundStyle(.black) }
            .lineSeparator { Divider() }
            .frame(width: 260, alignment: .leading)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 284, height: 130)))
        }

        @Test func overflowBuilderSeparatorOwnership() {
            let view = VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(OverflowBoundary.allCases.enumerated()), id: \.offset) { _, boundary in
                        overflowExample(vertical: false, boundary: boundary)
                    }
                }
                HStack(alignment: .top, spacing: 20) {
                    ForEach(Array(OverflowBoundary.allCases.enumerated()), id: \.offset) { _, boundary in
                        overflowExample(vertical: true, boundary: boundary)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 131, height: 201)))
        }

        private enum OverflowBoundary: CaseIterable {
            case inherited
            case empty
            case custom
        }

        private func overflowExample(vertical: Bool, boundary: OverflowBoundary) -> some View {
            let content = Group {
                ForEach(0 ..< 3) { _ in
                    Color.red.frame(width: vertical ? 10 : 30, height: vertical ? 30 : 10)
                }
                ItemSeparator { Color.black.frame(width: vertical ? 10 : 50, height: vertical ? 50 : 10) }
            }
            return Group {
                if vertical {
                    VFlow(itemSpacing: 5, columnSpacing: 0) { content }
                } else {
                    HFlow(itemSpacing: 5, rowSpacing: 0) { content }
                }
            }
            .itemSeparator { Color.blue.frame(width: vertical ? 10 : 5, height: vertical ? 5 : 10) }
            .maxLines(1) { _ in
                switch boundary {
                    case .inherited: EmptyView()
                    case .empty: ItemSeparator { EmptyView() }
                    case .custom: ItemSeparator { Color.purple.frame(width: vertical ? 10 : 2, height: vertical ? 2 : 10) }
                }
                Color.green.frame(width: vertical ? 10 : 20, height: vertical ? 20 : 10)
            }
            .frame(width: vertical ? 10 : 107, height: vertical ? 107 : 10, alignment: .topLeading)
        }

        @Test func overflowItemSeparator() async {
            let view = HFlow(itemSpacing: 6, rowSpacing: 6) {
                ForEach(tags, id: \.self) { tag($0) }
            }
            .maxLines(1) { count in tag("+\(count)") }
            .itemSeparator { Text("•").foregroundStyle(.black) }
            .lineSeparator { Divider() }
            .frame(width: 260, alignment: .leading)
            .padding(12)
            .background(Color.white)
            await assertSnapshotSettled(view, size: CGSize(width: 284, height: 70))
        }

        @Test func lineSeparator_dividers() {
            let view = HFlow(itemSpacing: 8, rowSpacing: 10) {
                ForEach(tags, id: \.self) { tag($0) }
            }
            .lineSeparator {
                Divider()
            }
            .frame(width: 320, alignment: .leading)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 344, height: 240)))
        }

        @Test func itemAndLineSeparators_combined() {
            let view = HFlow(itemSpacing: 8, rowSpacing: 12) {
                ForEach(tags, id: \.self) { tag($0) }
            }
            .itemSeparator {
                Rectangle().fill(.secondary.opacity(0.4)).frame(width: 1, height: 16)
            }
            .lineSeparator {
                Divider()
            }
            .frame(width: 320, alignment: .leading)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 344, height: 260)))
        }

        @Test func vflow_itemSeparator() {
            let view = VFlow(itemSpacing: 8, columnSpacing: 12) {
                ForEach(tags, id: \.self) { tag($0) }
            }
            .itemSeparator {
                Divider()
            }
            .frame(height: 260, alignment: .top)
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 284)))
        }
    }
#endif
