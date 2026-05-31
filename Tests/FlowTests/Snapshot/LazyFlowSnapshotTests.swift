#if os(macOS)
    import AppKit
    import SnapshotTesting
    import SwiftUI
    import Testing

    @testable import Flow

    // MARK: - Shared fixtures

    private let lazyColors: [Color] = [.blue, .orange, .green, .yellow, .brown, .mint, .indigo, .cyan, .gray, .pink]

    private struct LazyColorItem: Identifiable {
        let id: Int
        let color: Color
        let width: CGFloat
    }

    private let lazyColorItemWidths: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]

    private let lazyHFlowItems: [LazyColorItem] = zip(lazyColors, lazyColorItemWidths)
        .enumerated()
        .map { LazyColorItem(id: $0.offset, color: $0.element.0, width: $0.element.1) }

    private struct LazyHeightItem: Identifiable {
        let id: Int
        let color: Color
        let height: CGFloat
    }

    private let lazyColorItemHeights: [CGFloat] = [45, 55, 50, 40, 60, 48, 52, 58, 42, 46]

    private let lazyVFlowItems: [LazyHeightItem] = zip(lazyColors, lazyColorItemHeights)
        .enumerated()
        .map { LazyHeightItem(id: $0.offset, color: $0.element.0, height: $0.element.1) }

    private struct TagItem: Identifiable {
        let id: Int
        let text: String
    }

    // MARK: - LazyHFlow Snapshot Tests

    @Suite
    @MainActor
    struct LazyHFlowImageSnapshots {
        @Test func lazyHFlow_default() {
            let view = LazyHFlow(data: lazyHFlowItems) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_narrowMinimumWidth() {
            let view = LazyHFlow(data: lazyHFlowItems, minimumItemWidth: 40) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 200)))
        }

        @Test func lazyHFlow_wideMinimumWidth() {
            let view = LazyHFlow(data: lazyHFlowItems, minimumItemWidth: 120) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 300)))
        }

        @Test func lazyHFlow_compactSpacing() {
            let view = LazyHFlow(data: lazyHFlowItems, spacing: 2) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_spaciousSpacing() {
            let view = LazyHFlow(data: lazyHFlowItems, spacing: 20) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 300)))
        }

        @Test func lazyHFlow_cappedMaximumWidth() {
            let view = LazyHFlow(data: lazyHFlowItems, minimumItemWidth: 60, maximumItemWidth: 80) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(height: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 320, height: 250)))
        }

        @Test func lazyHFlow_tagCloud() {
            let tags: [TagItem] = [
                "Swift", "SwiftUI", "Flow", "Layout",
                "Lazy", "Grid", "iOS", "macOS",
                "Performance", "Open Source",
            ]
            .enumerated()
            .map { TagItem(id: $0.offset, text: $0.element) }
            let view = LazyHFlow(data: tags, minimumItemWidth: 60) { tag in
                Text(tag.text)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue.opacity(0.15)))
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, size: CGSize(width: 320, height: 200)))
        }
    }

    // MARK: - LazyVFlow Snapshot Tests

    @Suite
    @MainActor
    struct LazyVFlowImageSnapshots {
        @Test func lazyVFlow_default() {
            let view = LazyVFlow(data: lazyVFlowItems) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_shortMinimumHeight() {
            let view = LazyVFlow(data: lazyVFlowItems, minimumItemHeight: 20) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 200, height: 200)))
        }

        @Test func lazyVFlow_tallMinimumHeight() {
            let view = LazyVFlow(data: lazyVFlowItems, minimumItemHeight: 80) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 250, height: 320)))
        }

        @Test func lazyVFlow_cappedMaximumHeight() {
            let view = LazyVFlow(data: lazyVFlowItems, minimumItemHeight: 30, maximumItemHeight: 45) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_compactSpacing() {
            let view = LazyVFlow(data: lazyVFlowItems, spacing: 2) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 200, height: 320)))
        }

        @Test func lazyVFlow_spaciousSpacing() {
            let view = LazyVFlow(data: lazyVFlowItems, spacing: 20) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 50)
            }
            .padding(12)
            .background(Color.white)
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.95, size: CGSize(width: 250, height: 320)))
        }
    }
#endif
