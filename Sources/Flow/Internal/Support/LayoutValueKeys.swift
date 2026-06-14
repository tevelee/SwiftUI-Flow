import SwiftUI

// The internal `LayoutValueKey`/`EnvironmentKey` plumbing behind the public modifiers in
// `LayoutModifiers.swift`. Each public knob sets one of these; the cache reads them back per subview.
// (Separator keys live with the separator feature in `Internal/Features/Separators.swift`.)

@usableFromInline
struct ShouldStartInNewLineLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct IsLineBreakLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct FlexibilityLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

@usableFromInline
struct IsOverflowLayoutValueKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue = false
}

@usableFromInline
struct OverflowReporterKey: LayoutValueKey {
    @usableFromInline
    static let defaultValue: (@Sendable (Int) -> Void)? = nil
}

@usableFromInline
struct FlexibilityEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: FlexibilityBehavior = .natural
}

@usableFromInline
struct MaxLinesEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: Int? = nil
}

@usableFromInline
struct FlowItemSeparatorKey: EnvironmentKey {
    @usableFromInline
    static var defaultValue: (() -> AnyView)? { nil }
}

@usableFromInline
struct FlowLineSeparatorKey: EnvironmentKey {
    @usableFromInline
    static var defaultValue: (() -> AnyView)? { nil }
}

@usableFromInline
struct FlowOverflowBuilderKey: EnvironmentKey {
    @usableFromInline
    static var defaultValue: ((Int) -> AnyView)? { nil }
}

extension EnvironmentValues {
    @usableFromInline
    var flexibility: FlexibilityBehavior {
        get { self[FlexibilityEnvironmentKey.self] }
        set { self[FlexibilityEnvironmentKey.self] = newValue }
    }

    @usableFromInline
    var maxLines: Int? {
        get { self[MaxLinesEnvironmentKey.self] }
        set { self[MaxLinesEnvironmentKey.self] = newValue }
    }

    @usableFromInline
    var _flowItemSeparator: (() -> AnyView)? {
        get { self[FlowItemSeparatorKey.self] }
        set { self[FlowItemSeparatorKey.self] = newValue }
    }

    @usableFromInline
    var _flowLineSeparator: (() -> AnyView)? {
        get { self[FlowLineSeparatorKey.self] }
        set { self[FlowLineSeparatorKey.self] = newValue }
    }

    @usableFromInline
    var _flowOverflowBuilder: ((Int) -> AnyView)? {
        get { self[FlowOverflowBuilderKey.self] }
        set { self[FlowOverflowBuilderKey.self] = newValue }
    }
}
