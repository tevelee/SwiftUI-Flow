#if os(macOS)
    import AppKit
    import SnapshotTesting
    import SwiftUI
    import Testing

    @testable import Flow

    // MARK: - Shared fixtures

    private struct ColorItem: Identifiable {
        let id: Int
        let color: Color
        let width: CGFloat
    }

    private let lazyColors: [Color] = [.blue, .orange, .green, .yellow, .brown, .mint, .indigo, .cyan, .gray, .pink]
    private let itemWidths: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]
    private let itemHeights: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]

    private let hFlowItems: [ColorItem] = zip(lazyColors, itemWidths)
        .enumerated()
        .map { ColorItem(id: $0.offset, color: $0.element.0, width: $0.element.1) }

    private struct HeightItem: Identifiable {
        let id: Int
        let color: Color
        let height: CGFloat
    }

    private let vFlowItems: [HeightItem] = zip(lazyColors, itemHeights)
        .enumerated()
        .map { HeightItem(id: $0.offset, color: $0.element.0, height: $0.element.1) }

    private struct TagItem: Identifiable {
        let id: Int
        let text: String
    }

    // MARK: - LazyHFlow Snapshot Tests

    @Suite(.tags(.snapshot, .imageSnapshot, .lazyLayout))
    @MainActor
    struct LazyHFlowImageSnapshots {
        @Test func lazyHFlow_default() {
            let view = LazyHFlow(data: hFlowItems) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: 44)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func lazyHFlow_alignmentTop() {
            let view = LazyHFlow(data: hFlowItems, alignment: .top) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: item.width)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_alignmentBottom() {
            let view = LazyHFlow(data: hFlowItems, alignment: .bottom) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: item.width)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_compactSpacing() {
            let view = LazyHFlow(data: hFlowItems, spacing: 2) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: 44)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func lazyHFlow_spaciousSpacing() {
            let view = LazyHFlow(data: hFlowItems, spacing: 20) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: 44)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_justified() {
            let view = LazyHFlow(data: hFlowItems, justified: true) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: 44)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func lazyHFlow_distributeItemsEvenly() {
            let view = LazyHFlow(data: hFlowItems, spacing: 8, distributeItemsEvenly: true) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.width, height: 44)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }

        @Test func lazyHFlow_tagCloud() {
            let tags: [TagItem] = [
                "Swift", "SwiftUI", "Flow", "Layout",
                "Lazy", "Grid", "iOS", "macOS",
                "Performance", "Open Source",
            ]
            .enumerated()
            .map { TagItem(id: $0.offset, text: $0.element) }
            let view = LazyHFlow(data: tags, spacing: 8) { tag in
                Text(tag.text)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue.opacity(0.15)))
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 320, height: 200)))
        }
    }

    // MARK: - LazyVFlow Snapshot Tests

    @Suite(.tags(.snapshot, .imageSnapshot, .lazyLayout))
    @MainActor
    struct LazyVFlowImageSnapshots {
        @Test func lazyVFlow_default() {
            let view = LazyVFlow(data: vFlowItems) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: 44, height: item.height)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_alignmentLeading() {
            let view = LazyVFlow(data: vFlowItems, alignment: .leading) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.height, height: item.height)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_alignmentTrailing() {
            let view = LazyVFlow(data: vFlowItems, alignment: .trailing) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: item.height, height: item.height)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_compactSpacing() {
            let view = LazyVFlow(data: vFlowItems, spacing: 2) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: 44, height: item.height)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_spaciousSpacing() {
            let view = LazyVFlow(data: vFlowItems, spacing: 20) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color)
                    .frame(width: 44, height: item.height)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(size: CGSize(width: 250, height: 320)))
        }
    }
#endif
