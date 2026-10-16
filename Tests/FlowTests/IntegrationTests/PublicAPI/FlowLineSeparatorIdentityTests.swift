#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    import Flow

    @Suite(.serialized, .tags(.requirements, .regression))
    @MainActor
    struct FlowLineSeparatorIdentityTests {
        @Test(arguments: [false, true])
        func firstVisualBoundary_keepsItsStateWhenContentRewraps(vertical: Bool) async throws {
            _ = NSApplication.shared
            let input = Input()
            let records = Records()
            let host = NSHostingView(rootView: Scene(vertical: vertical, input: input, records: records))
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 500, height: 500), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }

            try await settle(host, records: records, vertical: vertical, breadth: 320, boundaries: 1)
            let first = try #require(records.visible(vertical: vertical).first?.id)
            input.breadth = 180
            try await settle(host, records: records, vertical: vertical, breadth: 180, boundaries: 3)
            #expect(records.visible(vertical: vertical).first?.id == first, "The first visual boundary keeps its separator state as the gap moves")
            input.breadth = 320
            try await settle(host, records: records, vertical: vertical, breadth: 320, boundaries: 1)
            #expect(records.visible(vertical: vertical).first?.id == first)
        }

        @Test(arguments: [false, true])
        func itemGap_keepsItsStateWhenTheSameNeighborsMoveToAnotherLine(vertical: Bool) async throws {
            _ = NSApplication.shared
            let input = Input()
            let records = Records()
            let host = NSHostingView(rootView: Scene(vertical: vertical, input: input, records: records, itemSeparators: true))
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 500, height: 500), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }

            try await settle(host, records: records, vertical: vertical, breadth: 320, boundaries: 1)
            let gap = try #require(records.separator(after: 4, before: 5, vertical: vertical))
            input.breadth = 180
            try await settle(host, records: records, vertical: vertical, breadth: 180, boundaries: 3)
            #expect(records.separator(after: 4, before: 5, vertical: vertical) == gap, "The same content pair keeps its separator state on another line")
        }

        private func settle(_ host: NSView, records: Records, vertical: Bool, breadth: CGFloat, boundaries: Int) async throws {
            let deadline = ContinuousClock.now + .seconds(5)
            repeat {
                host.layoutSubtreeIfNeeded()
                if records.breadth == breadth, records.visible(vertical: vertical).count == boundaries {
                    // A geometry callback can precede the deferred report that updates separator IDs.
                    let revision = records.revision
                    try await Task.sleep(for: .milliseconds(150))
                    host.layoutSubtreeIfNeeded()
                    if records.revision == revision { return }
                }
                await Task.yield()
            } while ContinuousClock.now < deadline
            throw LayoutTimeout()
        }

        private struct LayoutTimeout: Error {}

        private final class Input: ObservableObject {
            @Published var breadth: CGFloat = 320
        }

        private final class Records {
            var breadth: CGFloat?
            var frames: [UUID: CGRect] = [:] { didSet { revision += 1 } }
            var itemFrames: [UUID: CGRect] = [:] { didSet { revision += 1 } }
            var revision = 0
            var tiles: [Int: CGRect] = [:]

            func separator(after previous: Int, before next: Int, vertical: Bool) -> UUID? {
                guard let left = tiles[previous], let right = tiles[next] else { return nil }
                return itemFrames.first { _, frame in
                    guard !frame.isEmpty else { return false }
                    if vertical {
                        return frame.midY > left.maxY && frame.midY < right.minY && frame.midX == left.midX
                    }
                    return frame.midX > left.maxX && frame.midX < right.minX && frame.midY == left.midY
                }?.key
            }

            func visible(vertical: Bool) -> [(id: UUID, frame: CGRect)] {
                frames.compactMap { id, frame in frame.isEmpty ? nil : (id, frame) }
                    .sorted { vertical ? $0.frame.minX < $1.frame.minX : $0.frame.minY < $1.frame.minY }
            }
        }

        private struct Separator: View {
            let vertical: Bool
            let records: Records
            let item: Bool
            @State private var id = UUID()

            var body: some View {
                Color.gray.frame(width: vertical ? (item ? 24 : 2) : (item ? 8 : nil), height: vertical ? (item ? 8 : nil) : (item ? 24 : 2))
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .global)
                    } action: { frame in
                        if item { records.itemFrames[id] = frame } else { records.frames[id] = frame }
                    }
                    .onDisappear {
                        records.frames[id] = nil
                        records.itemFrames[id] = nil
                    }
            }
        }

        private struct Sample: Equatable {
            var breadth: CGFloat
            var frame: CGRect
        }

        private struct Scene: View {
            let vertical: Bool
            @ObservedObject var input: Input
            let records: Records

            var itemSeparators = false

            var body: some View {
                separated.lineSeparator { Separator(vertical: vertical, records: records, item: false) }
                    .frame(width: vertical ? nil : input.breadth, height: vertical ? input.breadth : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            @ViewBuilder private var separated: some View {
                if itemSeparators {
                    flow.itemSeparator { Separator(vertical: vertical, records: records, item: true) }
                } else {
                    flow
                }
            }

            @ViewBuilder private var flow: some View {
                if vertical {
                    VFlow(spacing: 4) { cells }
                } else {
                    HFlow(spacing: 4) { cells }
                }
            }

            private var cells: some View {
                ForEach(0 ..< 8, id: \.self) { index in
                    Color.blue.frame(width: vertical ? 24 : 64, height: vertical ? 64 : 24)
                        .onGeometryChange(for: Sample.self) { [breadth = input.breadth] proxy in
                            Sample(breadth: breadth, frame: proxy.frame(in: .global))
                        } action: { sample in
                            records.tiles[index] = sample.frame
                            if index == 7 { records.breadth = sample.breadth }
                        }
                }
            }
        }
    }
#endif
