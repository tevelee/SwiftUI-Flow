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

/// Cache to store certain properties of subviews in the layout (flexibility, spacing preferences, layout priority).
/// Even though it needs to be public (because it's part of the layout protocol conformance),
/// it's considered an internal implementation detail.
public struct FlowLayoutCache {
    @usableFromInline
    struct SubviewCache {
        var priority: Double
        var spacing: ViewSpacing
        var min: Size
        var ideal: Size
        var max: Size

        @usableFromInline
        init(_ subview: some Subview, axis: Axis) {
            priority = subview.priority
            spacing = subview.spacing
            min = subview.dimensions(.zero).size(on: axis)
            ideal = subview.dimensions(.unspecified).size(on: axis)
            max = subview.dimensions(.infinity).size(on: axis)
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
