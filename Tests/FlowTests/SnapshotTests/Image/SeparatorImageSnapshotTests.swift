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
