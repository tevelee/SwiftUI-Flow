import CoreFoundation

/// Geometry for the rendered prefix, rather than for the estimated full scroll extent.
struct LazyFlowGeometry: Equatable, Sendable {
    var scrollMax: CGFloat
    var contentExtent: CGFloat
    var measuredCount: Int
}

/// Owns lazy reveal progress and the extent estimate across data and geometry changes.
/// Each measured prefix can reveal at most one more item before its new geometry arrives.
struct LazyRevealState {
    private var revealed = 1
    private var geometry: LazyFlowGeometry?

    func visibleCount(for total: Int) -> Int {
        max(0, min(revealed, total))
    }

    func estimatedExtent(for total: Int) -> CGFloat? {
        guard visibleCount(for: total) < total, let geometry, geometry.measuredCount > 0 else { return nil }
        return geometry.contentExtent / CGFloat(geometry.measuredCount) * CGFloat(total)
    }

    /// Data growth can need another reveal even when the rendered prefix keeps the same size.
    /// A geometry sample may advance only the prefix it measured; callbacks from an earlier prefix
    /// cannot repeatedly consume the viewport using a stale extent.
    mutating func update(total: Int, geometry: LazyFlowGeometry? = nil) {
        revealed = max(0, min(max(1, revealed), total))
        if let geometry { self.geometry = geometry }
        guard revealed < total, let geometry = self.geometry, geometry.measuredCount == revealed else { return }
        if geometry.scrollMax.isInfinite {
            revealed = total
        } else if geometry.scrollMax > geometry.contentExtent {
            revealed += 1
        }
    }
}
