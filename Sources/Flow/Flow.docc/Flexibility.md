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
- ``FlexibilityBehavior/grow(_:)`` — grow proportionally to a numeric weight relative
  to other growing items on the same line.

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

## Proportional grow weights

Use `.grow(_:)` when items on the same line should share leftover space in a
specific ratio. For example, one item that should take twice the extra space
of another:

```swift
HFlow {
    RoundedRectangle(cornerRadius: 8).fill(.orange)
        .frame(minWidth: 40, maxWidth: .infinity, minHeight: 44, maxHeight: 44)
        .flexibility(.grow(2))  // takes 2/3 of leftover space

    RoundedRectangle(cornerRadius: 8).fill(.teal)
        .frame(minWidth: 40, maxWidth: .infinity, minHeight: 44, maxHeight: 44)
        .flexibility(.grow(1))  // takes 1/3 of leftover space
}
```

`.natural` is equivalent to `.grow(1)` and `.minimum` is equivalent to `.grow(0)`.
When all growing items have equal weights the behavior is identical to the plain
`.natural` case.

> Tip: `flexibility(_:)` can be applied outside a flow too — it propagates through
> the environment to every flow layout in that subtree.
