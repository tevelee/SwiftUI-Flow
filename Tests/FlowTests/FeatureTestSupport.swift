@testable import Flow
@testable import FlowLineLimit

// White-box convenience the engine no longer exposes itself: line capping now lives in `FlowLineLimit`,
// so these helpers rebuild the engine's feature list directly for tests that construct a bare
// `FlowLayout` and assert on its line cap.
extension FlowLayout {
    func withMaxLines(_ maxLines: Int?) -> FlowLayout {
        var copy = self
        copy.features.removeAll { $0 is LineCap }
        if let maxLines {
            copy.features.insert(LineCap(maxLines: maxLines), at: 0)
        }
        return copy
    }

    var lineCap: LineCap? {
        features.lazy.compactMap { $0 as? LineCap }.first
    }
}
