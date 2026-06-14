import SwiftUI

// The environment plumbing private to the separator feature. The core engine never reads any of these —
// the separator modifiers set them, and ``SeparatorComposer`` reads them back.

struct FlowItemSeparatorKey: EnvironmentKey {
    static var defaultValue: (() -> AnyView)? { nil }
}

struct FlowLineSeparatorKey: EnvironmentKey {
    static var defaultValue: (() -> AnyView)? { nil }
}

extension EnvironmentValues {
    var _flowItemSeparator: (() -> AnyView)? {
        get { self[FlowItemSeparatorKey.self] }
        set { self[FlowItemSeparatorKey.self] = newValue }
    }

    var _flowLineSeparator: (() -> AnyView)? {
        get { self[FlowLineSeparatorKey.self] }
        set { self[FlowLineSeparatorKey.self] = newValue }
    }
}
