import SwiftUI

/// A single-value `ObservableObject` carrying a fact the layout engine reports back to the view layer.
///
/// The engine feeds structural results to the view through `@Sendable` reporter closures. Mutating
/// `@Published` state during a SwiftUI update is disallowed, so ``reporter()`` defers the publish
/// to the next main-actor turn and skips it when the value is unchanged. Held as a `@StateObject`
/// so the reference survives body re-evaluations.
///
/// Lives in the core so each feature target (`FlowLineLimit`, `FlowSeparators`) can hold its own
/// reporter without depending on the other.
@MainActor
package final class Reported<Value: Equatable & Sendable>: ObservableObject {
    @Published package var value: Value

    package init(_ value: Value) {
        self.value = value
    }

    /// A `@Sendable` reporter the layout calls with a new value; deferred out of the layout pass and
    /// guarded against redundant publishes.
    package func reporter() -> @Sendable (Value) -> Void {
        { value in
            Task { @MainActor in
                if self.value != value { self.value = value }
            }
        }
    }
}
