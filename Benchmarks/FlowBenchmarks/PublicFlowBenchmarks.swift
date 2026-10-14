import AppKit
import Benchmark
import Flow
import SwiftUI

func registerPublicFlowBenchmarks() {
    for vertical in [false, true] {
        let axis = vertical ? "VFlow" : "HFlow"
        for initial in [true, false] {
            Benchmark("public/\(axis)/text-128/\(initial ? "initial-layout" : "resize")") { benchmark in
                try await measurePublicFlow(benchmark, vertical: vertical, kind: initial ? .initialText : .resizeText)
            }
        }
        Benchmark("public/\(axis)/balanced-flexible-128/resize") { benchmark in
            try await measurePublicFlow(benchmark, vertical: vertical, kind: .resizeBalanced)
        }
        Benchmark("public/\(axis)/separators-and-overflow/resize") { benchmark in
            try await measurePublicFlow(benchmark, vertical: vertical, kind: .featured)
        }
        if #available(macOS 14, *) {
            Benchmark("public/Lazy\(axis)/data-growth") { benchmark in
                try await measurePublicFlow(benchmark, vertical: vertical, kind: .lazy)
            }
        }
    }
}

@MainActor
private final class Input: ObservableObject {
    @Published var breadth: CGFloat = 320
    @Published var count = 1
}

private struct Sample: Equatable {
    let breadth: CGFloat
    let frame: CGRect
    var isPlaced: Bool { !frame.isEmpty && !frame.isInfinite && !frame.isNull }
}

private struct OverflowSample: Equatable {
    let count: Int
    let sample: Sample
}

@MainActor
private final class Activity {
    var lastItem: Sample?
    var overflow: OverflowSample?
    var lazyFrames: [Int: CGRect] = [:]
}

@MainActor
private final class Host {
    // Window creation is outside every measurement; initial-layout includes creating and attaching the hosting view.
    let window: NSWindow
    var view: NSHostingView<AnyView>?

    init() {
        _ = NSApplication.shared
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 600, height: 600), styleMask: .borderless, backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
    }

    func attach(_ root: some View) {
        let view = NSHostingView(rootView: AnyView(root))
        self.view = view
        window.contentView = view
    }

    func close() {
        window.contentView = nil
        view = nil
        window.close()
    }

    func settle(until completed: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        repeat {
            view?.layoutSubtreeIfNeeded()
            if completed() { return }
            // Let geometry observations and Flow's deferred reports execute, without a fixed sleep in the timing.
            await Task.yield()
        } while ContinuousClock.now < deadline
        throw LayoutFailure.didNotComplete
    }
}

private enum LayoutFailure: Error {
    case didNotComplete
    case unchangedPlacement
}

private enum WorkloadKind: Sendable {
    case initialText, resizeText, resizeBalanced, featured, lazy
}

// Benchmark remains in the calling task; only the UI-owned workload crosses to the main actor.
private func measurePublicFlow(_ benchmark: Benchmark, vertical: Bool, kind: WorkloadKind) async throws {
    let workload = await HostedWorkload(vertical: vertical, kind: kind)
    do {
        try await workload.prepare()
        benchmark.startMeasurement()
        try await workload.run()
        benchmark.stopMeasurement()
        await workload.close()
    } catch {
        benchmark.stopMeasurement()
        await workload.close()
        throw error
    }
}

@MainActor
private final class HostedWorkload {
    let input = Input()
    let activity = Activity()
    let host = Host()
    let vertical: Bool
    let kind: WorkloadKind
    var oldFrame: CGRect?

    init(vertical: Bool, kind: WorkloadKind) {
        self.vertical = vertical
        self.kind = kind
        if kind == .resizeBalanced { input.breadth = 960 }
    }

    func prepare() async throws {
        switch kind {
            case .initialText:
                break
            case .resizeText:
                host.attach(TextScene(vertical: vertical, input: input, activity: activity))
                try await host.settle { activity.lastItem?.breadth == input.breadth && activity.lastItem?.isPlaced == true }
                oldFrame = activity.lastItem?.frame
            case .resizeBalanced:
                host.attach(FlexibleScene(vertical: vertical, input: input, activity: activity))
                try await host.settle { activity.lastItem?.breadth == input.breadth && activity.lastItem?.isPlaced == true }
                oldFrame = activity.lastItem?.frame
            case .featured:
                host.attach(FeaturedScene(vertical: vertical, input: input, activity: activity))
                // Four cells per line at 320pt; the last slot belongs to the overflow indicator.
                try await host.settle { overflowIsPlaced(count: 121, breadth: 320) }
            case .lazy:
                guard #available(macOS 14, *) else { throw LayoutFailure.didNotComplete }
                host.attach(LazyScene(vertical: vertical, input: input, activity: activity))
                try await host.settle { activity.lazyFrames[0]?.size == CGSize(width: 48, height: 48) }
        }
    }

    func run() async throws {
        switch kind {
            case .initialText, .resizeText, .resizeBalanced:
                if kind == .initialText {
                    host.attach(TextScene(vertical: vertical, input: input, activity: activity))
                } else {
                    input.breadth = kind == .resizeBalanced ? 480 : 180
                }
                try await host.settle { activity.lastItem?.breadth == input.breadth && activity.lastItem?.isPlaced == true }
                if let oldFrame, oldFrame == activity.lastItem?.frame { throw LayoutFailure.unchangedPlacement }
                blackHole(activity.lastItem)
            case .featured:
                input.breadth = 180
                // Two cells per line now, including the overflow indicator on the second line.
                try await host.settle { overflowIsPlaced(count: 125, breadth: 180) }
                blackHole(activity.overflow)
            case .lazy:
                input.count = 128
                // The fifth cell fills the second row/column of the viewport.
                try await host.settle {
                    guard let frame = activity.lazyFrames[4] else { return false }
                    return (vertical ? frame.maxX : frame.maxY) >= 96 && activity.lazyFrames.count < 128
                }
                blackHole(activity.lazyFrames)
        }
    }

    func close() { host.close() }

    private func overflowIsPlaced(count: Int, breadth: CGFloat) -> Bool {
        activity.overflow?.count == count && activity.overflow?.sample.breadth == breadth && activity.overflow?.sample.isPlaced == true
    }
}

@MainActor
private struct TextScene: View {
    let vertical: Bool
    @ObservedObject var input: Input
    let activity: Activity

    var body: some View {
        flow.frame(width: vertical ? nil : input.breadth, height: vertical ? input.breadth : nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var flow: some View {
        if vertical {
            VFlow(alignment: .leading, spacing: 4) { cells }
        } else {
            HFlow(alignment: .top, spacing: 4) { cells }
        }
    }

    private var cells: some View {
        ForEach(0 ..< 128, id: \.self) { index in
            if index == 127 {
                cell(index).onGeometryChange(for: Sample.self) { [breadth = input.breadth] proxy in
                    Sample(breadth: breadth, frame: proxy.frame(in: .global))
                } action: {
                    activity.lastItem = $0
                }
            } else {
                cell(index)
            }
        }
    }

    private func cell(_ index: Int) -> some View {
        Text(["Swift", "Layout", "Accessibility", "A longer tag", "Flow", "Resizing", "Views"][index % 7])
            .font(.system(size: 14)).fixedSize()
            .padding(4).background(Color.blue.opacity(0.1))
    }
}

@MainActor
private struct FlexibleScene: View {
    let vertical: Bool
    @ObservedObject var input: Input
    let activity: Activity

    var body: some View {
        flow.frame(width: vertical ? nil : input.breadth, height: vertical ? input.breadth : nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var flow: some View {
        if vertical {
            VFlow(alignment: .leading, spacing: 4, distributeItemsEvenly: true) { cells }
        } else {
            HFlow(alignment: .top, spacing: 4, distributeItemsEvenly: true) { cells }
        }
    }

    private var cells: some View {
        ForEach(0 ..< 128, id: \.self) { index in
            if index == 127 {
                cell(index).onGeometryChange(for: Sample.self) { [breadth = input.breadth] proxy in
                    Sample(breadth: breadth, frame: proxy.frame(in: .global))
                } action: {
                    activity.lastItem = $0
                }
            } else {
                cell(index)
            }
        }
    }

    private func cell(_ index: Int) -> some View {
        Text(["A", "B", "C"][index % 3]).font(.system(size: 14))
            .frame(width: vertical ? 24 : nil, height: vertical ? nil : 24)
            .frame(
                minWidth: vertical ? nil : 24,
                idealWidth: vertical ? nil : 48,
                maxWidth: vertical ? nil : 96,
                minHeight: vertical ? 24 : nil,
                idealHeight: vertical ? 48 : nil,
                maxHeight: vertical ? 96 : nil
            )
    }
}

@MainActor
private struct FeaturedScene: View {
    let vertical: Bool
    @ObservedObject var input: Input
    let activity: Activity

    var body: some View {
        flow.itemSeparator { Text("·").frame(width: vertical ? 24 : 8, height: vertical ? 8 : 24) }
            .maxLines(2) { count in
                Text("+\(count)").frame(width: vertical ? 24 : 64, height: vertical ? 64 : 24)
                    .onGeometryChange(for: OverflowSample.self) { [breadth = input.breadth] proxy in
                        OverflowSample(count: count, sample: Sample(breadth: breadth, frame: proxy.frame(in: .global)))
                    } action: { sample in
                        activity.overflow = sample
                    }
            }
            .frame(width: vertical ? nil : input.breadth, height: vertical ? input.breadth : nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var flow: some View {
        if vertical {
            VFlow(spacing: 4) { cells }
        } else {
            HFlow(spacing: 4) { cells }
        }
    }

    private var cells: some View {
        ForEach(0 ..< 128, id: \.self) { index in
            Text("Tag \(index)").font(.system(size: 12)).frame(width: vertical ? 24 : 64, height: vertical ? 64 : 24)
        }
    }
}

@MainActor
@available(macOS 14, *)
private struct LazyScene: View {
    let vertical: Bool
    @ObservedObject var input: Input
    let activity: Activity

    var body: some View {
        ScrollView(vertical ? .horizontal : .vertical, showsIndicators: false) { flow }
            .coordinateSpace(name: "viewport")
            .frame(width: vertical ? 96 : 192, height: vertical ? 192 : 96)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var flow: some View {
        if vertical {
            LazyVFlow(data: items, spacing: 0, content: cell)
        } else {
            LazyHFlow(data: items, spacing: 0, content: cell)
        }
    }

    private var items: [Item] { (0 ..< input.count).map { Item(id: $0) } }
    private struct Item: Identifiable { let id: Int }

    private func cell(_ item: Item) -> some View {
        Text("\(item.id)").frame(width: 48, height: 48)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named("viewport"))
            } action: {
                activity.lazyFrames[item.id] = $0
            }
    }
}
