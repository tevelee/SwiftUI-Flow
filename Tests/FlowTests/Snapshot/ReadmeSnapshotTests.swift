#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SnapshotTesting
@testable import Flow


@Suite
@MainActor
final class ReadmeSnapshotTests {
    let colors: [Color] = [.blue, .orange, .green, .yellow, .brown, .mint, .indigo, .cyan, .gray, .pink]
    fileprivate lazy var items: [Item] = (colors + colors).enumerated().map(Item.init)
    fileprivate var rng: SeededRNG
    
    init() {
        rng = SeededRNG(seed: 444)
    }

    @Test func hflow() {
        let view = HFlow {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 25...75, using: &self.rng), height: 50)
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }

    @Test func vflow() {
        let view = VFlow {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: 50, height: .random(in: 25...75, using: &self.rng))
            }
        }
        .frame(maxHeight: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 250, height: 400)))
    }

    @Test func hflow_top() {
        let view = HFlow(alignment: .top) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 50...70, using: &self.rng), height: .random(in: 25...75, using: &self.rng))
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }

    @Test func hflow_center() {
        let view = HFlow(alignment: .center) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 50...70, using: &self.rng), height: .random(in: 25...75, using: &self.rng))
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }
    
    @Test func hflow_bottom() {
        let view = HFlow(alignment: .bottom) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 50...70, using: &self.rng), height: .random(in: 25...75, using: &self.rng))
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }
    
    @Test func hflow_tag() {
        let view = HFlow(horizontalAlignment: .center, verticalAlignment: .top) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 50...70, using: &self.rng), height: 30)
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 200)))
    }

    @Test func hflow_spacing() {
        let view = HFlow(itemSpacing: 2, rowSpacing: 10) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 50...70, using: &self.rng), height: 50)
            }
        }
        .frame(maxWidth: 400)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }

    @Test func hflow_distributed_evenly() {
        let view = HFlow(alignment: .top, distributeItemsEvenly: true) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 25...75, using: &self.rng), height: 50)
            }
        }
        .frame(width: 400, alignment: .leading)
        .border(.gray)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }

    @Test func hflow_justified() {
        let view = HFlow(justified: true) {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 25...75, using: &self.rng), height: 50)
            }
        }
        .frame(width: 300)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 300, height: 300)))
    }

    @Test func hflow_flexibility() {
        let view = HFlow {
            RoundedRectangle(cornerRadius: 10)
                .fill(.red)
                .frame(minWidth: 50, maxWidth: .infinity)
                .frame(height: 50)
                .flexibility(.minimum)
            RoundedRectangle(cornerRadius: 10)
                .fill(.green)
                .frame(minWidth: 50, maxWidth: .infinity)
                .frame(height: 50)
                .flexibility(.natural)
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue)
                .frame(minWidth: 50, maxWidth: .infinity)
                .frame(height: 50)
                .flexibility(.natural)
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(minWidth: 50, maxWidth: .infinity)
                .frame(height: 50)
                .flexibility(.maximum)
        }
        .frame(width: 300)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 300, height: 108)))
    }

    @Test func hflow_linebreak() {
        let view = HFlow {
            RoundedRectangle(cornerRadius: 10)
                .fill(.red)
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 10)
                .fill(.green)
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue)
                .frame(width: 50, height: 50)
            LineBreak()
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(width: 50, height: 50)
        }
        .frame(width: 300)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 170, height: 110)))
    }

    @Test func hflow_newline() {
        let view = HFlow {
            RoundedRectangle(cornerRadius: 10)
                .fill(.red)
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 10)
                .fill(.green)
                .frame(width: 50, height: 50)
                .startInNewLine()
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue)
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(width: 50, height: 50)
        }
        .frame(width: 300)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 170, height: 110)))
    }

    @Test func hflow_rtl() {
        let view = HFlow {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.gradient)
                    .frame(width: .random(in: 25...75, using: &self.rng), height: 50)
            }
        }
        .frame(maxWidth: 400)
        .environment(\.layoutDirection, .rightToLeft)
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 300)))
    }
}

private struct Item: Identifiable, View {
    let id: Int
    let color: Color
    
    var body: some View {
        color
    }
}

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64 = 42) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        z = z ^ (z >> 31)
        return z
    }
}
#endif
