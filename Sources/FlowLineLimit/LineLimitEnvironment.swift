import SwiftUI

// The environment plumbing private to the line-limit feature. The core engine never reads any of these —
// the `.maxLines` modifiers set them, and ``LineLimitComposer`` reads them back.

struct MaxLinesEnvironmentKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}

struct FlowOverflowBuilderKey: EnvironmentKey {
    static var defaultValue: ((Int) -> AnyView)? { nil }
}

extension EnvironmentValues {
    var maxLines: Int? {
        get { self[MaxLinesEnvironmentKey.self] }
        set { self[MaxLinesEnvironmentKey.self] = newValue }
    }

    var _flowOverflowBuilder: ((Int) -> AnyView)? {
        get { self[FlowOverflowBuilderKey.self] }
        set { self[FlowOverflowBuilderKey.self] = newValue }
    }
}
