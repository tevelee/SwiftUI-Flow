# ``Flow``

A SwiftUI layout that arranges views in lines, wrapping onto new lines (or columns) when they run out of space.

@Metadata {
    @DisplayName("SwiftUI Flow")
}

## Overview

``HFlow`` and ``VFlow`` work like `HStack` and `VStack`, except they wrap their
content onto additional lines when it no longer fits the available space — much
like words wrapping in a paragraph. They are built on the SwiftUI `Layout`
protocol, so they compose naturally with alignment guides, layout priorities,
spacing preferences, and animations.

![A horizontal flow of colored rectangles wrapping across three rows](hflow)

Reach for a flow layout when you have a variable number of differently sized
items — tags, chips, filters, thumbnails — that should fill the available width
(or height) and wrap as needed.

Beyond simple wrapping, Flow supports per-axis alignment, independent item and
line spacing, even item distribution via the Knuth–Plass algorithm, justified
lines, a flexibility model for stretching items, and manual line breaks.

## Topics

### Essentials

- <doc:GettingStarted>
- ``HFlow``
- ``VFlow``

### Layout Guides

- <doc:Alignment>
- <doc:Spacing>
- <doc:Distribution>

### Advanced Control

- <doc:Flexibility>
- <doc:LineBreaks>
- <doc:LineLimits>
- ``FlexibilityBehavior``
- ``LineBreak``

### Layout Conformances

- ``HFlowLayout``
- ``VFlowLayout``

### Supporting Types

- ``FlowLayoutCache``
