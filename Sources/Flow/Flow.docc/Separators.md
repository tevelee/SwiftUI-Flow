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

### Explicit item separators

Place ``ItemSeparator`` between children to customize a specific boundary while keeping the
flow-wide default for other gaps:

```swift
HFlow(itemSpacing: 6) {
    Text("Alpha")
    ItemSeparator { Text("|") }
    Text("Beta")
    Text("Gamma")
}
.itemSeparator { Text("•") }
```

This draws a pipe between Alpha and Beta and a dot between Beta and Gamma when the items share
a line. Explicit separators also work without `.itemSeparator`. Their size affects wrapping,
with `itemSpacing` on both sides. They disappear at line boundaries and at the flow's edges,
and do not count as hidden items for `.maxLines`.

Use `ItemSeparator { EmptyView() }` to omit the separator at a boundary while keeping one
ordinary item-spacing gap. If several explicit separators occur between two items, the last
one wins. Explicit separators do not replace line separators.

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

### Line limits and overflow

With `.maxLines(_:overflow:)`, the overflow chip inherits the item separator following the
last retained item. Its size and spacing are included when making room for the chip.

To override that separator, place `ItemSeparator` immediately before the chip
in the overflow builder:

```swift
HFlow(itemSpacing: 6) {
	ForEach(tags, id: \.self) { Text($0) }
}
.itemSeparator { Text("•") }
.maxLines(1) { count in
	ItemSeparator { EmptyView() }
	Text("+\(count)")
}
```

The empty separator keeps one ordinary item-spacing gap before the chip. A custom separator
reserves its own size and item spacing on both sides when the layout makes room for the chip.

An `ItemSeparator` at the end of the main content remains an ignored edge marker. Only a
separator inside the overflow builder can override the chip's inherited separator.

If the chip is alone on the last line, no item separator appears. Line separators are drawn
only between retained content lines and never after the final visible line.
