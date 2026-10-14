import CoreFoundation
import Testing

@testable import Flow

/// Lossless for nonnegative geometry on the requested grid. Reject off-grid values rather than
/// rounding them into a passing diagram. Fractional and overlapping cases use exact assertions.
func wrappedLineDiagram(_ lines: WrappedLines, unit: CGFloat = 1) -> String {
    guard unit.isFinite, unit > 0 else { return "Invalid diagram unit" }
    let labels = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    var rows: [String] = []
    var seen: Set<Int> = []
    for line in lines {
        var row = ""
        for item in line {
            let gap = item.leadingSpace / unit
            let size = item.size / unit
            guard seen.insert(item.index).inserted, labels.indices.contains(item.index), gap.isFinite, size.isFinite,
                gap >= 0, size > 0, gap == gap.rounded(), size == size.rounded(), gap + size <= 1000
            else { return "Off-grid or unsupported geometry: \(lines)" }
            row += String(repeating: " ", count: Int(gap))
            row += String(repeating: String(labels[item.index]), count: Int(size))
        }
        rows.append(row)
    }
    return rows.isEmpty ? "(empty)" : rows.joined(separator: "\n")
}

func expectWrappedLines(
    _ lines: WrappedLines,
    unit: CGFloat = 1,
    sourceLocation: SourceLocation = #_sourceLocation,
    matches expected: () -> String
) {
    #expect(wrappedLineDiagram(lines, unit: unit) == expected(), sourceLocation: sourceLocation)
}

/// Shows the selected item/line alternatives for each content gap, including an explicit absence.
func separatorPlanDiagram(_ plan: SeparatorPlan) -> String {
    func label(_ index: Int?) -> String {
        guard let index else { return "none" }
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return letters.indices.contains(index) ? String(letters[index]) : "[\(index)]"
    }
    return zip(plan.contentIndices, plan.contentIndices.dropFirst()).map { previous, current in
        "\(label(previous)) -- item:\(label(plan.itemSeparator(before: current, after: previous))) / line:\(label(plan.lineSeparator(before: current))) --> \(label(current))"
    }.joined(separator: "\n")
}
