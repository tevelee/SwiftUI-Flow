# Line Limits

Cap a flow to a maximum number of lines, with an optional overflow indicator.

## Overview

Use the ``View/maxLines(_:)`` modifier to prevent a flow from growing beyond a
set number of rows (for ``HFlow``) or columns (for ``VFlow``). Items that don't
fit are hidden — they still participate in line breaking so the layout is
consistent — but they are placed off-screen.

```swift
HFlow {
    ForEach(tags) { tag in TagView(tag) }
}
.maxLines(2)
```

The modifier applies to the nearest enclosing flow and does **not** propagate
to nested flows.

## Overflow indicator

Use the closure overload on `HFlow` or `VFlow` to show a trailing view that
receives the count of hidden items:

```swift
HFlow {
    ForEach(tags) { tag in TagView(tag) }
}
.maxLines(2) { hidden in
    Text("+\(hidden) more")
        .foregroundStyle(.secondary)
}
```

The overflow view is always placed at the end of the last visible line. The
`hidden` count is updated after layout converges (typically one extra pass).

## Bare Layout types

When using ``HFlowLayout`` or ``VFlowLayout`` directly (e.g. with `AnyLayout`),
chain ``HFlowLayout/withMaxLines(_:)`` after the initializer:

```swift
let layout = HFlowLayout().withMaxLines(3)
AnyLayout(HFlowLayout(itemSpacing: 8).withMaxLines(2))
```

The overflow closure is not available on bare `Layout` types since they have
no view hierarchy to hold state.

## Notes

- `maxLines(nil)` is a no-op and restores unlimited lines.
- When ``distributeItemsEvenly`` is enabled the Knuth–Plass algorithm still
  optimises over all items; only the first *N* lines of that result are shown.
- The modifier name mirrors SwiftUI's `.lineLimit(_:)` and behaves analogously
  at the flow-line level.
