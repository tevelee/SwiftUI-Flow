import SwiftUI

/// Justified layout stretches lines in a way to create a straight and even edge on both sides of the view
public enum Justification: Sendable {
    /// Flexible items are stretched proportionally in each line
    case stretchItems
    /// Spaces between items are stretched equally
    case stretchSpaces
    /// Primarily the items are being stretched as much as they allow and then spaces too if needed
    case stretchItemsAndSpaces

    @inlinable
    var isStretchingItems: Bool {
        switch self {
            case .stretchItems, .stretchItemsAndSpaces: true
            case .stretchSpaces: false
        }
    }

    @inlinable
    var isStretchingSpaces: Bool {
        switch self {
            case .stretchSpaces, .stretchItemsAndSpaces: true
            case .stretchItems: false
        }
    }
}

public enum FlexibilityBehavior: Sendable {
    case minimum
    case natural
    case maximum
}

/// Cache to store certain properties of subviews in the layout (flexibility, spacing preferences, layout priority).
/// Even though it needs to be public (because it's part of the layout protocol conformance),
/// it's considered an internal implementation detail.
public struct FlowLayoutCache {
    @usableFromInline
    struct SubviewCache {
        @usableFromInline
        var priority: Double
        @usableFromInline
        var spacing: ViewSpacing
        @usableFromInline
        var min: Size
        @usableFromInline
        var ideal: Size
        @usableFromInline
        var max: Size
        @usableFromInline
        var layoutValues: LayoutValues
        @usableFromInline
        struct LayoutValues {
            @usableFromInline
            var shouldStartInNewLine: Bool
            @usableFromInline
            var isLineBreak: Bool
            @usableFromInline
            var flexibility: FlexibilityBehavior

            @inlinable
            init(shouldStartInNewLine: Bool, isLineBreak: Bool, flexibility: FlexibilityBehavior) {
                self.shouldStartInNewLine = shouldStartInNewLine
                self.isLineBreak = isLineBreak
                self.flexibility = flexibility
            }
        }

        @inlinable
        init(_ subview: some Subview, axis: Axis) {
            priority = subview.priority
            spacing = subview.spacing
            min = subview.dimensions(.zero).size(on: axis)
            ideal = subview.dimensions(.unspecified).size(on: axis)
            max = subview.dimensions(.infinity).size(on: axis)
            layoutValues = LayoutValues(
                shouldStartInNewLine: subview[ShouldStartInNewLineLayoutValueKey.self],
                isLineBreak: subview[_IsLineBreakLayoutValueKey.self],
                flexibility: subview[FlexibilityLayoutValueKey.self]
            )
        }
    }

    @usableFromInline 
    let subviewsCache: [SubviewCache]

    @inlinable 
    init(_ subviews: some Subviews, axis: Axis) {
        subviewsCache = subviews.map {
            SubviewCache($0, axis: axis)
        }
    }
}

public struct LineBreak: View {
    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .layoutValue(key: _IsLineBreakLayoutValueKey.self, value: true)
            .startInNewLine()
    }

    public init() {}
}

@usableFromInline
struct ShouldStartInNewLineLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct _IsLineBreakLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct FlexibilityLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

@usableFromInline
struct FlexibilityEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

extension EnvironmentValues {
    @usableFromInline
    var flexibility: FlexibilityBehavior {
        get { self[FlexibilityEnvironmentKey.self] }
        set { self[FlexibilityEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func startInNewLine() -> some View {
        layoutValue(key: ShouldStartInNewLineLayoutValueKey.self, value: true)
    }

    public func flexibility(_ behavior: FlexibilityBehavior) -> some View {
        layoutValue(key: FlexibilityLayoutValueKey.self, value: behavior)
            .environment(\.flexibility, behavior)
    }
}
