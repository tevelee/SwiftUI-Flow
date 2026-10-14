import CoreFoundation

/// Geometry for the rendered prefix, rather than for the estimated full scroll extent.
struct LazyFlowGeometry: Equatable, Sendable {
    /// Maximum viewport coordinate along the scroll axis; infinity means no scroll viewport.
    var viewportEnd: CGFloat
    var contentExtent: CGFloat
    var measuredItemCount: Int
}

/// Owns lazy reveal progress and the extent estimate across data and geometry changes.
/// Each measured prefix can reveal at most one more item before its new geometry arrives.
struct LazyRevealState {
    private var revealed = 1
    private var geometry: LazyFlowGeometry?

    func revealedItemCount(for total: Int) -> Int {
        max(0, min(revealed, total))
    }

    func estimatedExtent(for total: Int) -> CGFloat? {
        guard revealedItemCount(for: total) < total, let geometry, geometry.measuredItemCount > 0 else { return nil }
        return geometry.contentExtent / CGFloat(geometry.measuredItemCount) * CGFloat(total)
    }

    /// Data growth can need another reveal even when the rendered prefix keeps the same size.
    /// A geometry sample may advance only the prefix it measured; callbacks from an earlier prefix
    /// cannot repeatedly consume the viewport using a stale extent.
    mutating func update(total: Int, geometry: LazyFlowGeometry? = nil) {
        revealed = max(0, min(max(1, revealed), total))
        if let geometry { self.geometry = geometry }
        guard revealed < total, let geometry = self.geometry, geometry.measuredItemCount == revealed else { return }
        if geometry.viewportEnd.isInfinite {
            revealed = total
        } else if geometry.viewportEnd > geometry.contentExtent {
            revealed += 1
        }
    }
}
