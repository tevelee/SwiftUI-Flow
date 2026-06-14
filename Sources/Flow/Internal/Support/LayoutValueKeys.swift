import SwiftUI

// The `LayoutValueKey`/`EnvironmentKey` plumbing behind the core modifiers in `LayoutModifiers.swift`.
// Feature-specific keys (line limits, separators, overflow, the auxiliary marker) live with their
// feature targets (`FlowLineLimit`, `FlowSeparators`).

struct ShouldStartInNewLineLayoutValueKey: LayoutValueKey {
    static let defaultValue = false
}

struct IsLineBreakLayoutValueKey: LayoutValueKey {
    static let defaultValue = false
}

struct FlexibilityLayoutValueKey: LayoutValueKey {
    static let defaultValue: FlexibilityBehavior = .natural
}

struct FlexibilityEnvironmentKey: EnvironmentKey {
    static let defaultValue: FlexibilityBehavior = .natural
}

extension EnvironmentValues {
    var flexibility: FlexibilityBehavior {
        get { self[FlexibilityEnvironmentKey.self] }
        set { self[FlexibilityEnvironmentKey.self] = newValue }
    }
}
