# Flexibility

Let items grow or stay rigid when there is extra space in a line.

## Overview

When a line has leftover space and contains flexible items (for example views
with `maxWidth: .infinity`), Flow distributes the extra space among them. The
`flexibility(_:)` modifier controls how an individual view participates, using
``FlexibilityBehavior``:

- ``FlexibilityBehavior/minimum`` — take as little space as possible (rigid).
- ``FlexibilityBehavior/natural`` — expand as the view naturally would (the default).
- ``FlexibilityBehavior/maximum`` — claim as much space as possible, even pushing
  other items onto the next line.

```swift
HFlow { // distributes flexible items proportionally
    RoundedRectangle(cornerRadius: 10)
        .fill(.red)
        .frame(minWidth: 50, maxWidth: .infinity)
        .frame(height: 50)
        .flexibility(.minimum) // takes as little space as possible, rigid
    RoundedRectangle(cornerRadius: 10)
        .fill(.green)
        .frame(minWidth: 50, maxWidth: .infinity)
        .frame(height: 50)
        .flexibility(.natural) // expands
    RoundedRectangle(cornerRadius: 10)
        .fill(.blue)
        .frame(minWidth: 50, maxWidth: .infinity)
        .frame(height: 50)
        .flexibility(.natural) // expands
    RoundedRectangle(cornerRadius: 10)
        .fill(.yellow)
        .frame(minWidth: 50, maxWidth: .infinity)
        .frame(height: 50)
        .flexibility(.maximum) // takes as much space as possible
}
.frame(width: 300)
```

![A horizontal flow with items of differing flexibility filling a row](flexibility)

> Tip: `flexibility(_:)` can be applied outside a flow too — it propagates through
> the environment to every flow layout in that subtree.
