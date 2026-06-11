# Separators

Draw dividers between items and between lines, without painting over the layout.

## Overview

Use ``HFlow/itemSeparator(_:)`` and ``HFlow/lineSeparator(_:)`` (and their ``VFlow``
equivalents) to place a separator view in the gaps between items and lines. Separators
appear only *between* elements — never before the first or after the last — and a gap that
wraps onto a new line shows the line separator instead of the item separator.

Unlike decorations layered on afterwards, separators take part in the layout: an item
separator's width is considered when deciding where a line breaks, and a line separator
contributes its height to the overall size. As a result the content never overflows because
a separator was "added later".

### Item separators

An item separator is drawn between two items on the same line:

```swift
HFlow {
    ForEach(tags, id: \.self) { Text($0) }
}
.itemSeparator {
    Text("•").foregroundStyle(.secondary)
}
```

### Line separators

A line separator becomes its own line between two rows (or columns), so spacing applies on
both sides of it:

```swift
HFlow {
    ForEach(tags, id: \.self) { Text($0) }
}
.lineSeparator {
    Divider()
}
```

### Combining both

The two modifiers compose. Each gap draws exactly one separator: the item separator while
the items share a line, the line separator once the gap wraps.

```swift
HFlow {
    ForEach(tags, id: \.self) { Text($0) }
}
.itemSeparator { Text("•") }
.lineSeparator { Divider() }
```

> Tip: Provide a single view from each builder. Pick a separator whose orientation matches the
> axis — for example a `Divider()` reads naturally as a line separator in an `HFlow`.
