import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct LineFittingTests {
    @Test func negativeSpacing_canRecoverFromOverflow() {
        var fitter = LineFitter(availableSpace: 100)
        #expect(fitter.remainingSpace == nil)
        fitter.append(MeasuredItem(size: 60 ... 60, spacing: 0))
        #expect(fitter.remainingSpace == 40)
        fitter.append(MeasuredItem(size: 60 ... 60, spacing: 0))
        #expect(fitter.remainingSpace == nil)
        fitter.append(MeasuredItem(size: 10 ... 10, spacing: -40))
        #expect(fitter.remainingSpace == 10, "Overflow must not permanently invalidate a growing candidate")
    }

    @Test func initialBreak_clearsOnlyTheFollowingSpacing() {
        var fitter = LineFitter(availableSpace: 100)
        fitter.append(MeasuredItem(size: 0 ... 0, spacing: 99, isLineBreakView: true))
        #expect(fitter.remainingSpace == 100)
        fitter.append(MeasuredItem(size: 40 ... 40, spacing: 99))
        #expect(fitter.remainingSpace == 60)
        fitter.append(MeasuredItem(size: 30 ... 30, spacing: 10))
        #expect(fitter.remainingSpace == 20)
    }

    @Test(arguments: [false, true])
    func structuralViolation_cannotRecoverWithNegativeSpacing(marker: Bool) {
        var fitter = LineFitter(availableSpace: 100)
        fitter.append(MeasuredItem(size: 20 ... 20, spacing: 0))
        fitter.append(MeasuredItem(size: 0 ... 0, spacing: -100, isLineBreakView: marker, shouldStartInNewLine: !marker))
        #expect(fitter.remainingSpace == nil)
        fitter.append(MeasuredItem(size: 20 ... 20, spacing: -100))
        #expect(fitter.remainingSpace == nil, "Negative spacing cannot override an explicit line boundary")
    }

    @Test func separateSizeAndSpacingSums_preserveFloatingPointCancellation() {
        var fitter = LineFitter(availableSpace: 0)
        fitter.append(MeasuredItem(size: 1e16 ... 1e16, spacing: 0))
        fitter.append(MeasuredItem(size: 1 ... 1, spacing: -1e16))
        #expect(fitter.remainingSpace == 0)
        fitter.append(MeasuredItem(size: 1 ... 1, spacing: 0))
        // Summing sizes and spacing together would retain the final 1 and reject this candidate.
        // Batch sizing sums all sizes first, then adds the spacing sum, producing exactly zero.
        #expect(fitter.remainingSpace == 0)
    }

    @Test func maximumGrowth_preservesOrderedSubtraction() {
        var fitter = LineFitter(availableSpace: 1e16)
        fitter.append(MeasuredItem(size: 0 ... 1e16, spacing: 0, flexibility: .maximum))
        #expect(fitter.remainingSpace == 1e16)
        fitter.append(MeasuredItem(size: 0 ... 1, spacing: 0, flexibility: .maximum))
        // Summing demands would round 1e16 + 1 down and incorrectly accept the second item.
        #expect(fitter.remainingSpace == nil)
    }
}
