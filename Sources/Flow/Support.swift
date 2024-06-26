import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public enum Justification {
    case stretchItems
    case stretchSpaces
    case stretchItemsAndSpaces
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct FlowLayoutCache {
    struct SubviewCache {
        var priority: Double
        var spacing: ViewSpacing
        var min: Double
        var ideal: Double
        var max: Double

        init(_ subview: some Subview, axis: Axis) {
            priority = subview.priority
            spacing = subview.spacing
            min = subview.dimensions(.zero).value(on: axis)
            ideal = subview.dimensions(.unspecified).value(on: axis)
            max = subview.dimensions(.infinity).value(on: axis)
        }
    }

    let subviewsCache: [SubviewCache]

    init(_ subviews: some Subviews, axis: Axis) {
        subviewsCache = subviews.map {
            SubviewCache($0, axis: axis)
        }
    }
}
