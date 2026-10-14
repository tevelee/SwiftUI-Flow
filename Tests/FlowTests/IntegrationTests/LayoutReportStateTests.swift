import Combine
import Foundation
import SwiftUI
import Testing

@testable import Flow

#if os(macOS)
    import AppKit
#endif

@Suite(.tags(.requirements, .regression))
@MainActor
struct LayoutReportStateTests {
    @Test func synchronousReports_publishOnlyTheLatestValue() async {
        let reported = LayoutReportState(0)
        let firstPublished = await firstPublication(from: reported) {
            let registration = reported.register()
            registration.confirm(CGSize(width: 75, height: 22))
            for value in 1 ... 100 {
                registration.report(value, CGSize(width: 75, height: 22))
            }
            #expect(reported.value == 0, "Reporting must defer publication out of the layout pass")
        }
        #expect(firstPublished == 100)
        #expect(reported.value == 100)
    }

    @Test func sizedReports_ignoreUnacceptedProbeGeometry() async {
        let reported = LayoutReportState(0)
        let registration = reported.register()
        let firstPublished = await firstPublication(from: reported) {
            registration.report(1, CGSize(width: 75, height: 22))
            registration.report(0, CGSize(width: 210, height: 10))
            registration.confirm(CGSize(width: 75, height: 22))
        }
        #expect(firstPublished == 1)
        #expect(reported.value == 1)
    }

    @Test func sizedReports_ignoreCallbacksFromPreviousContent() async {
        let reported = LayoutReportState(0)
        let previous = reported.register()
        let registration = reported.register()
        let firstPublished = await firstPublication(from: reported) {
            registration.report(2, CGSize(width: 75, height: 22))
            registration.confirm(CGSize(width: 75, height: 22))
            previous.report(99, CGSize(width: 75, height: 22))
            previous.confirm(CGSize(width: 210, height: 10))
        }
        #expect(firstPublished == 2)
        #expect(reported.value == 2)
    }

    @Test func sizedReports_acceptGeometryBeforeTheCandidateArrives() async {
        let reported = LayoutReportState(0)
        let registration = reported.register()
        let firstPublished = await firstPublication(from: reported) {
            registration.confirm(CGSize(width: 75, height: 22))
            registration.report(2, CGSize(width: 75, height: 22))
        }
        #expect(firstPublished == 2)
    }

    @Test(arguments: [false, true])
    func sizedReports_reuseCandidateAfterConfirmingAnotherGeometry(probeFirst: Bool) async {
        let reported = LayoutReportState(0)
        let registration = reported.register()
        let displayed = CGSize(width: 75, height: 22)
        let probe = CGSize(width: 210, height: 10)
        if probeFirst { registration.report(0, probe) }
        registration.report(2, displayed)
        if !probeFirst { registration.report(0, probe) }
        registration.confirm(probe)

        // SwiftUI can reuse the earlier alignment placement when the rendered bounds change.
        // Confirming a different size must not discard that generation's valid candidate.
        let firstPublished = await firstPublication(from: reported) {
            registration.confirm(displayed)
        }
        #expect(firstPublished == 2)
        #expect(reported.value == 2)
    }

    @Test func placement_usesCurrentRegistrationWhenLayoutCacheIsReused() async {
        let reported = LayoutReportState(0)
        let previous = reported.register()
        let layout = FlowLayout.horizontal(horizontalSpacing: 0, verticalSpacing: 0, maxLines: 1)
        let overflow: TestSubview = 1 × 1
        overflow[FlowSubviewOriginLayoutValueKey.self] = .overflowBuilder
        let subviews: [TestSubview] = [4 × 1, 4 × 1, 4 × 1, overflow]
        subviews[0][PlacementReporterKey.self] = { report, size in previous.report(report.overflowCount, size) }
        var cache = layout.makeCache(subviews)
        let proposal: ProposedViewSize = 5 × 5
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)

        // A body update replaces the registration even when SwiftUI reuses its alignment cache.
        let registration = reported.register()
        subviews[0][PlacementReporterKey.self] = { report, size in registration.report(report.overflowCount, size) }
        let firstPublished = await firstPublication(from: reported) {
            registration.confirm(size)
            layout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: proposal, subviews: subviews, cache: &cache)
        }
        #expect(firstPublished == 2)
    }

    #if os(macOS)
        @Test func geometryObserver_reconfirmsUnchangedBoundsForNewContent() async {
            _ = NSApplication.shared
            let reported = LayoutReportState(0)
            let size = CGSize(width: 75, height: 22)
            let host = NSHostingView(rootView: AnyView(EmptyView()))
            let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: .borderless, backing: .buffered, defer: true)
            window.contentView = host
            defer { window.contentView = nil }

            for count in 1 ... 3 {
                let registration = reported.register()
                registration.report(count, size)
                let published = await firstPublication(from: reported) {
                    host.rootView = AnyView(
                        Color.clear.frame(width: size.width, height: size.height)
                            .observeLayoutGeometry(using: registration)
                    )
                    host.layoutSubtreeIfNeeded()
                }
                #expect(published == count, "Unchanged bounds must confirm each new content generation")
            }
        }
    #endif

    @Test func sizedReports_requireGeometryFromCurrentContent() async {
        let reported = LayoutReportState(0)
        let previous = reported.register()
        previous.confirm(CGSize(width: 75, height: 22))
        previous.report(0, CGSize(width: 75, height: 22))

        let registration = reported.register()
        let unconfirmed = await firstPublication(from: reported, timeout: .milliseconds(100)) {
            registration.report(99, CGSize(width: 75, height: 22))
        }
        #expect(unconfirmed == nil, "Previous content's bounds must not confirm a new placement")
        let confirmed = await firstPublication(from: reported) {
            registration.report(2, CGSize(width: 100, height: 22))
            registration.confirm(CGSize(width: 100, height: 22))
        }
        #expect(confirmed == 2)
    }

    private func firstPublication(from reported: LayoutReportState<Int>, timeout: Duration = .seconds(10), perform: () -> Void) async -> Int? {
        let channel = AsyncStream<Int>.makeStream()
        let subscription = reported.$value.dropFirst().sink { channel.continuation.yield($0) }
        perform()
        let result = await withTaskGroup(of: Int?.self) { group in
            group.addTask {
                var iterator = channel.stream.makeAsyncIterator()
                return await iterator.next()
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let result: Int?
            if let next = await group.next() {
                result = next
            } else {
                result = nil
            }
            group.cancelAll()
            return result
        }
        channel.continuation.finish()
        withExtendedLifetime(subscription) {}
        return result
    }
}
