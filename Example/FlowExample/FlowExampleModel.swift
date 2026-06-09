import Flow
import Foundation
import SwiftUI

enum FlowLayoutMode: String, CaseIterable, CustomStringConvertible, Identifiable {
    case horizontal
    case vertical
    case lazyHorizontal
    case lazyVertical

    var id: Self { self }

    var description: String {
        switch self {
            case .horizontal: "HFlow"
            case .vertical: "VFlow"
            case .lazyHorizontal: "LazyHFlow"
            case .lazyVertical: "LazyVFlow"
        }
    }

    var isLazy: Bool {
        self == .lazyHorizontal || self == .lazyVertical
    }

    var isHorizontal: Bool {
        self == .horizontal || self == .lazyHorizontal
    }

    /// Whether the horizontal alignment control affects this layout.
    ///
    /// Eager flows honor both axes. Lazy flows only support the cross-axis
    /// alignment, which is horizontal for `LazyVFlow` (items within a column).
    var usesHorizontalAlignment: Bool {
        switch self {
            case .horizontal, .vertical, .lazyVertical: true
            case .lazyHorizontal: false
        }
    }

    /// Whether the vertical alignment control affects this layout.
    ///
    /// The cross-axis of `LazyHFlow` is vertical (items within a row); eager
    /// flows honor both axes.
    var usesVerticalAlignment: Bool {
        switch self {
            case .horizontal, .vertical, .lazyHorizontal: true
            case .lazyVertical: false
        }
    }

    /// A short explanation of how alignment applies to lazy layouts.
    var alignmentNote: String? {
        switch self {
            case .lazyHorizontal: "LazyHFlow aligns items vertically within each row."
            case .lazyVertical: "LazyVFlow aligns items horizontally within each column."
            case .horizontal, .vertical: nil
        }
    }
}

enum CanvasFrameMode: String, CaseIterable, CustomStringConvertible, Identifiable {
    case fixed
    case maximum

    var id: Self { self }

    var description: String {
        switch self {
            case .fixed: "Fixed"
            case .maximum: "Cap"
        }
    }
}

enum ExampleHorizontalAlignment: String, CaseIterable, CustomStringConvertible, Identifiable {
    case leading
    case center
    case trailing

    var id: Self { self }
    var description: String { rawValue.capitalized }

    var value: HorizontalAlignment {
        switch self {
            case .leading: .leading
            case .center: .center
            case .trailing: .trailing
        }
    }
}

enum ExampleVerticalAlignment: String, CaseIterable, CustomStringConvertible, Identifiable {
    case top
    case baseline
    case center
    case bottom

    var id: Self { self }
    var description: String { rawValue.capitalized }

    var value: VerticalAlignment {
        switch self {
            case .top: .top
            case .baseline: .firstTextBaseline
            case .center: .center
            case .bottom: .bottom
        }
    }
}

enum ExampleLayoutDirection: String, CaseIterable, CustomStringConvertible, Identifiable {
    case leftToRight
    case rightToLeft

    var id: Self { self }

    var description: String {
        switch self {
            case .leftToRight: "LTR"
            case .rightToLeft: "RTL"
        }
    }

    var value: LayoutDirection {
        switch self {
            case .leftToRight: .leftToRight
            case .rightToLeft: .rightToLeft
        }
    }
}

enum ItemFlexibility: String, CaseIterable, CustomStringConvertible, Identifiable {
    case minimum
    case natural
    case maximum

    var id: Self { self }
    var description: String { rawValue.capitalized }

    var value: FlexibilityBehavior {
        switch self {
            case .minimum: .minimum
            case .natural: .natural
            case .maximum: .maximum
        }
    }
}

enum FlowItemKind: String, CaseIterable, CustomStringConvertible, Identifiable {
    case word
    case button
    case card
    case swatch
    case spacer
    case lineBreak

    var id: Self { self }

    var description: String {
        switch self {
            case .word: "Word"
            case .button: "Button"
            case .card: "Card"
            case .swatch: "Box"
            case .spacer: "Spacer"
            case .lineBreak: "Line break"
        }
    }

    var systemImage: String {
        switch self {
            case .word: "textformat"
            case .button: "button.programmable"
            case .card: "rectangle.stack"
            case .swatch: "square"
            case .spacer: "arrow.left.and.right.square"
            case .lineBreak: "arrow.turn.down.right"
        }
    }
}

enum FlowItemColor: String, CaseIterable, CustomStringConvertible, Identifiable {
    case blue
    case teal
    case green
    case mint
    case orange
    case red
    case pink
    case purple
    case indigo
    case gray

    var id: Self { self }
    var description: String { rawValue.capitalized }

    var value: Color {
        switch self {
            case .blue: .blue
            case .teal: .teal
            case .green: .green
            case .mint: .mint
            case .orange: .orange
            case .red: .red
            case .pink: .pink
            case .purple: .purple
            case .indigo: .indigo
            case .gray: .gray
        }
    }
}

struct AxisSizing: Equatable {
    enum Mode: String, CaseIterable, CustomStringConvertible, Identifiable {
        case intrinsic
        case fixed
        case flexible
        case range

        var id: Self { self }

        var description: String {
            switch self {
                case .intrinsic: "Intrinsic"
                case .fixed: "Fixed"
                case .flexible: "Flexible"
                case .range: "Range"
            }
        }
    }

    var mode: Mode = .intrinsic
    var fixed: Double = 64
    var minimum: Double = 44
    var ideal: Double = 120
    var maximum: Double = 240
    var maximumIsInfinite = false

    var fixedFrame: CGFloat? {
        mode == .fixed ? CGFloat(fixed) : nil
    }

    var minimumFrame: CGFloat? {
        switch mode {
            case .flexible, .range: CGFloat(minimum)
            case .intrinsic, .fixed: nil
        }
    }

    var idealFrame: CGFloat? {
        mode == .range ? CGFloat(ideal) : nil
    }

    var maximumFrame: CGFloat? {
        switch mode {
            case .flexible:
                .infinity
            case .range:
                maximumIsInfinite ? .infinity : CGFloat(maximum)
            case .intrinsic, .fixed:
                nil
        }
    }

    var summary: String {
        switch mode {
            case .intrinsic:
                "intrinsic"
            case .fixed:
                "\(Int(fixed))"
            case .flexible:
                "\(Int(minimum))+"
            case .range:
                maximumIsInfinite ? "\(Int(minimum))...inf" : "\(Int(minimum))...\(Int(maximum))"
        }
    }

    static let intrinsic = AxisSizing()

    static func fixed(_ value: Double) -> AxisSizing {
        AxisSizing(mode: .fixed, fixed: value, minimum: value, ideal: value, maximum: value)
    }

    static func flexible(minimum: Double) -> AxisSizing {
        AxisSizing(
            mode: .flexible,
            fixed: minimum,
            minimum: minimum,
            ideal: minimum,
            maximum: minimum,
            maximumIsInfinite: true
        )
    }

    static func range(minimum: Double, ideal: Double, maximum: Double, maximumIsInfinite: Bool = false) -> AxisSizing {
        AxisSizing(
            mode: .range,
            fixed: ideal,
            minimum: minimum,
            ideal: ideal,
            maximum: maximum,
            maximumIsInfinite: maximumIsInfinite
        )
    }
}

struct FlowLabSettings: Equatable {
    var mode: FlowLayoutMode = .horizontal
    var canvasWidth: Double = 460
    var canvasHeight: Double = 250
    var canvasZoom: Double = 1
    var canvasFrameMode: CanvasFrameMode = .fixed
    var itemSpacing: Double? = nil
    var lineSpacing: Double? = nil
    var justified = false
    var distributeItemsEvenly = false
    var horizontalAlignment: ExampleHorizontalAlignment = .leading
    var verticalAlignment: ExampleVerticalAlignment = .center
    var layoutDirection: ExampleLayoutDirection = .leftToRight
    var showsCanvasBorder = false
    var showsItemOutlines = false
    var showsItemIndexes = false
    var showsBreakMarkers = true
    var showsFlexHints = true
    var animationsEnabled = true
    var maxLines: Int? = nil

    var itemSpacingValue: CGFloat? {
        itemSpacing.map { CGFloat($0) }
    }

    var lineSpacingValue: CGFloat? {
        lineSpacing.map { CGFloat($0) }
    }

    var frameSummary: String {
        "\(Int(canvasWidth)) x \(Int(canvasHeight))"
    }
}

struct FlowItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var subtitle = ""
    var kind: FlowItemKind = .word
    var color: FlowItemColor = .blue
    var width = AxisSizing.intrinsic
    var height = AxisSizing.intrinsic
    var flexibility: ItemFlexibility = .natural
    var layoutPriority: Double = 0
    var startsNewLine = false

    var isLineBreak: Bool {
        kind == .lineBreak
    }

    var isSpacer: Bool {
        kind == .spacer
    }

    var menuTitle: String {
        isLineBreak ? "Line break" : title
    }

    var detailSummary: String {
        if isLineBreak {
            return "Manual break"
        }

        var parts = [kind.description]
        if startsNewLine {
            parts.append("new line")
        }
        if flexibility != .natural {
            parts.append(flexibility.description)
        }
        if width.mode != .intrinsic || height.mode != .intrinsic {
            parts.append("\(width.summary) x \(height.summary)")
        }
        return parts.joined(separator: ", ")
    }

    var hasFlexHint: Bool {
        flexibility != .natural
            || width.mode == .flexible
            || width.mode == .range
            || height.mode == .flexible
            || height.mode == .range
    }

    var flexSummary: String {
        var parts = [flexibility.description]
        if width.mode != .intrinsic {
            parts.append("W \(width.summary)")
        }
        if height.mode != .intrinsic {
            parts.append("H \(height.summary)")
        }
        return parts.joined(separator: " · ")
    }

    func duplicated() -> FlowItem {
        var copy = self
        copy.id = UUID()
        if !copy.isLineBreak {
            copy.title += " copy"
        }
        return copy
    }

    static func newItem(kind: FlowItemKind, index: Int) -> FlowItem {
        switch kind {
            case .word:
                FlowItem(title: "New tag", kind: .word, color: .blue)
            case .button:
                FlowItem(title: "New button", kind: .button, color: .teal)
            case .card:
                FlowItem(
                    title: "Card \(index)",
                    subtitle: "Flexible card",
                    kind: .card,
                    color: .indigo,
                    width: .range(minimum: 130, ideal: 180, maximum: 320, maximumIsInfinite: true),
                    height: .fixed(74)
                )
            case .swatch:
                FlowItem(title: "\(index)", kind: .swatch, color: .purple, width: .fixed(56), height: .fixed(44))
            case .spacer:
                FlowItem(
                    title: "Spacer",
                    kind: .spacer,
                    color: .gray,
                    width: .flexible(minimum: 24),
                    height: .fixed(18),
                    flexibility: .maximum
                )
            case .lineBreak:
                FlowItem(title: "Line break", kind: .lineBreak, color: .gray, width: .fixed(0), height: .fixed(0))
        }
    }
}

enum FlowUseCase: String, CaseIterable, Identifiable {
    case wordCloud
    case buttonCloud
    case flexibleCards
    case manualBreaks
    case lazyGallery
    case edgeCases

    var id: Self { self }

    var title: String {
        switch self {
            case .wordCloud: "Word Cloud"
            case .buttonCloud: "Button Cloud"
            case .flexibleCards: "Flexible Cards"
            case .manualBreaks: "Manual Breaks"
            case .lazyGallery: "Lazy Gallery"
            case .edgeCases: "Edge Cases"
        }
    }

    var systemImage: String {
        switch self {
            case .wordCloud: "textformat.size"
            case .buttonCloud: "rectangle.grid.2x2"
            case .flexibleCards: "rectangle.split.3x1"
            case .manualBreaks: "arrow.turn.down.right"
            case .lazyGallery: "photo.on.rectangle"
            case .edgeCases: "wrench.and.screwdriver"
        }
    }

    var defaultItemKind: FlowItemKind {
        switch self {
            case .wordCloud:
                .word
            case .buttonCloud:
                .button
            case .flexibleCards, .lazyGallery:
                .card
            case .manualBreaks:
                .lineBreak
            case .edgeCases:
                .swatch
        }
    }

    var quickAddTitle: String {
        switch defaultItemKind {
            case .word:
                "Add Tag"
            case .button:
                "Add Button"
            case .card:
                "Add Card"
            case .swatch:
                "Add Box"
            case .spacer:
                "Add Spacer"
            case .lineBreak:
                "Add Break"
        }
    }

    var settings: FlowLabSettings {
        switch self {
            case .wordCloud:
                return FlowLabSettings(canvasWidth: 460, canvasHeight: 230, verticalAlignment: .baseline)
            case .buttonCloud:
                return FlowLabSettings(canvasWidth: 520, canvasHeight: 170, itemSpacing: 8, lineSpacing: 10)
            case .flexibleCards:
                return FlowLabSettings(
                    canvasWidth: 560,
                    canvasHeight: 280,
                    itemSpacing: 10,
                    lineSpacing: 10,
                    justified: true,
                    verticalAlignment: .top
                )
            case .manualBreaks:
                return FlowLabSettings(
                    canvasWidth: 420,
                    canvasHeight: 220,
                    itemSpacing: 8,
                    lineSpacing: 14,
                    showsBreakMarkers: true
                )
            case .lazyGallery:
                return FlowLabSettings(
                    mode: .lazyHorizontal,
                    canvasWidth: 560,
                    canvasHeight: 300,
                    canvasFrameMode: .fixed,
                    itemSpacing: 12,
                    lineSpacing: 12
                )
            case .edgeCases:
                return FlowLabSettings(
                    canvasWidth: 320,
                    canvasHeight: 260,
                    itemSpacing: 4,
                    lineSpacing: 8,
                    showsCanvasBorder: true,
                    showsItemOutlines: true,
                    showsItemIndexes: true,
                    showsBreakMarkers: true,
                    animationsEnabled: false
                )
        }
    }

    var items: [FlowItem] {
        switch self {
            case .wordCloud:
                return [
                    FlowItem(title: "SwiftUI", kind: .word, color: .blue),
                    FlowItem(title: "Accessibility", kind: .word, color: .green),
                    FlowItem(title: "Layout", kind: .word, color: .teal),
                    FlowItem(title: "Animation", kind: .word, color: .orange),
                    FlowItem(title: "Preview", kind: .word, color: .purple),
                    FlowItem(title: "Navigation", kind: .word, color: .indigo),
                    FlowItem(title: "Forms", kind: .word, color: .pink),
                    FlowItem(title: "Localization", kind: .word, color: .mint),
                    FlowItem(title: "Dynamic Type", kind: .word, color: .red),
                    FlowItem(title: "Toolbars", kind: .word, color: .blue),
                    FlowItem(title: "Lists", kind: .word, color: .green),
                    FlowItem(title: "Buttons", kind: .word, color: .teal)
                ]
            case .buttonCloud:
                return [
                    FlowItem(title: "All", kind: .button, color: .blue),
                    FlowItem(title: "Unread", kind: .button, color: .teal),
                    FlowItem(title: "Favorites", kind: .button, color: .pink),
                    FlowItem(title: "Archived", kind: .button, color: .gray),
                    FlowItem(title: "Sort", kind: .button, color: .indigo),
                    FlowItem(title: "Filter", kind: .button, color: .purple),
                    FlowItem(title: "Share", kind: .button, color: .green),
                    FlowItem(title: "Export", kind: .button, color: .orange),
                    FlowItem(title: "New Folder", kind: .button, color: .blue),
                    FlowItem(title: "Sync Now", kind: .button, color: .mint)
                ]
            case .flexibleCards:
                return [
                    FlowItem(title: "Inbox", subtitle: "24 open", kind: .card, color: .blue, width: .range(minimum: 130, ideal: 170, maximum: 280, maximumIsInfinite: true), height: .fixed(72), flexibility: .natural),
                    FlowItem(title: "Today", subtitle: "7 due", kind: .card, color: .orange, width: .range(minimum: 110, ideal: 150, maximum: 260, maximumIsInfinite: true), height: .fixed(72), flexibility: .minimum),
                    FlowItem(title: "Roadmap", subtitle: "Next 6 weeks", kind: .card, color: .indigo, width: .range(minimum: 160, ideal: 220, maximum: 360, maximumIsInfinite: true), height: .fixed(72), layoutPriority: 1),
                    FlowItem.newItem(kind: .spacer, index: 4),
                    FlowItem(title: "Backlog", subtitle: "41 ideas", kind: .card, color: .purple, width: .range(minimum: 120, ideal: 160, maximum: 260, maximumIsInfinite: true), height: .fixed(72)),
                    FlowItem(title: "Shipped", subtitle: "18 done", kind: .card, color: .green, width: .flexible(minimum: 120), height: .fixed(72), flexibility: .maximum)
                ]
            case .manualBreaks:
                return [
                    FlowItem(title: "Primary", kind: .button, color: .blue),
                    FlowItem(title: "Secondary", kind: .button, color: .gray),
                    FlowItem.newItem(kind: .lineBreak, index: 3),
                    FlowItem(title: "Danger Zone", kind: .word, color: .red),
                    FlowItem(title: "Delete", kind: .button, color: .red),
                    FlowItem(title: "Archive", kind: .button, color: .orange),
                    FlowItem(title: "Footer starts here", kind: .word, color: .indigo, startsNewLine: true),
                    FlowItem(title: "Done", kind: .button, color: .green)
                ]
            case .lazyGallery:
                return (1...42).map { index in
                    FlowItem(
                        title: "Item \(index)",
                        subtitle: index.isMultiple(of: 3) ? "Featured" : "Gallery",
                        kind: .card,
                        color: FlowItemColor.allCases[index % FlowItemColor.allCases.count],
                        height: .fixed(Double(70 + (index % 3) * 12))
                    )
                }
            case .edgeCases:
                return [
                    FlowItem(title: "too wide", kind: .button, color: .red, width: .fixed(420), height: .fixed(38)),
                    FlowItem(title: "1 pt", kind: .swatch, color: .mint, width: .fixed(1), height: .fixed(28)),
                    FlowItem(title: "zero width", kind: .button, color: .orange, width: .fixed(0), height: .fixed(34)),
                    FlowItem.newItem(kind: .lineBreak, index: 4),
                    FlowItem.newItem(kind: .spacer, index: 5),
                    FlowItem(title: "tall", kind: .swatch, color: .indigo, width: .fixed(44), height: .fixed(160)),
                    FlowItem(title: "range infinity", kind: .button, color: .teal, width: .range(minimum: 20, ideal: 120, maximum: 200, maximumIsInfinite: true), height: .fixed(34)),
                    FlowItem(title: "new line", kind: .button, color: .purple, startsNewLine: true)
                ]
        }
    }
}
