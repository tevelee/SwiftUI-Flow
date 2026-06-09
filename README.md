# SwiftUI Flow Layout

[![CI](https://github.com/tevelee/SwiftUI-Flow/actions/workflows/ci.yml/badge.svg)](https://github.com/tevelee/SwiftUI-Flow/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/tevelee/SwiftUI-Flow/branch/main/graph/badge.svg)](https://codecov.io/gh/tevelee/SwiftUI-Flow)
[![Swift Package Index versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftevelee%2FSwiftUI-Flow%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tevelee/SwiftUI-Flow)
[![Supported platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftevelee%2FSwiftUI-Flow%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tevelee/SwiftUI-Flow)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

Introduces `HFlow` and `VFlow` similar to `HStack` and `VStack`. 
Arranges views in lines and cuts new lines accordingly (if elements don't fit the bounding space).

## Features

- 📐 **Wrapping layout** — items flow onto new lines (or columns) when they run out of space.
- ↔️ **Two axes** — `HFlow` wraps rows, `VFlow` wraps columns.
- 🎯 **Per-axis alignment** — align items within a line and lines within the layout.
- ↕️ **Independent spacing** — set item spacing and line spacing separately.
- ⚖️ **Even distribution** — balance items across lines with the Knuth–Plass algorithm.
- ↔️ **Justified lines** — stretch lines to fill the available space.
- 🪗 **Flexibility model** — let items grow, stay rigid, or claim a whole line.
- ✂️ **Manual line breaks** — force breaks with `LineBreak()` or `.startInNewLine()`.
- 🌍 **RTL support** — adapts to the environment's layout direction.
- 🧱 **`Layout` conformance** — `HFlowLayout` / `VFlowLayout` for use anywhere a `Layout` is expected.

## Requirements

- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+
- Swift 5.9+

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/tevelee/SwiftUI-Flow", from: "3.1.1")
```

then add `"Flow"` to your target's dependencies. In Xcode, choose **File ▸ Add Package Dependencies…** and enter `https://github.com/tevelee/SwiftUI-Flow`.

## Documentation

Full API reference and guides are hosted on the [Swift Package Index](https://swiftpackageindex.com/tevelee/SwiftUI-Flow/documentation/flow).

## HFlow

```swift
import Flow

struct Colors: View {
    let colors: [Color] = [
        .blue,
        .orange,
        .green,
        .yellow,
        .brown,
        .mint,
        .indigo,
        .cyan,
        .gray,
        .pink
    ]

    var body: some View {
        HFlow {
            ForEach(colors, id: \.description) { color in
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.gradient)
                    .frame(width: .random(in: 40...60), height: 50)
            }
        }
        .frame(maxWidth: 300)
    }
}
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow.1.png)

## VFlow

```swift
VFlow {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 50, height: .random(in: 40...60))
    }
}
.frame(maxHeight: 300)
```

![VFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/vflow.1.png)

## Alignment

Supports the same alignments as HStack and VStack do.

```swift
HFlow(alignment: .top) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 50, height: .random(in: 40...60))
    }
}
.frame(maxWidth: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_top.1.png)

Additionally, alignment can be specified on both axes. Ideal for tags.

```swift
HFlow(horizontalAlignment: .center, verticalAlignment: .top) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: .random(in: 30...60), height: 30)
    }
}
.frame(maxWidth: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_tag.1.png)

## Spacing

Customize spacing between rows and items separately.

```swift
HFlow(itemSpacing: 4, rowSpacing: 20) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 50, height: 50)
    }
}
.frame(maxWidth: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_spacing.1.png)

## Distribute items

Distribute items evenly by minimizing the empty spaces left in each row. 
Implements the Knuth-Plass line breaking algorithm.

```swift
HFlow(distributeItemsEvenly: true) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 65, height: 50)
    }
}
.frame(width: 300, alignment: .leading)
.border(.gray)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_distributed_evenly.1.png)

## Justified

```swift
HFlow(justified: true) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 50, height: 50)
    }
}
.frame(width: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_justified.1.png)

## Flexibility

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
        .frame(height: 50) // takes as much space as possible
        .flexibility(.maximum)
}
.frame(width: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_flexibility.1.png)

## Line breaks

```swift
HFlow {
    RoundedRectangle(cornerRadius: 10)
        .fill(.red)
        .frame(width: 50, height: 50)
    RoundedRectangle(cornerRadius: 10)
        .fill(.green)
        .frame(width: 50, height: 50)
    RoundedRectangle(cornerRadius: 10)
        .fill(.blue)
        .frame(width: 50, height: 50)
    LineBreak() // <--
    RoundedRectangle(cornerRadius: 10)
        .fill(.yellow)
        .frame(width: 50, height: 50)
}
.frame(width: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_linebreak.1.png)

```swift
HFlow {
    RoundedRectangle(cornerRadius: 10)
        .fill(.red)
        .frame(width: 50, height: 50)
    RoundedRectangle(cornerRadius: 10)
        .fill(.green)
        .frame(width: 50, height: 50)
        .startInNewLine() // <-- 
    RoundedRectangle(cornerRadius: 10)
        .fill(.blue)
        .frame(width: 50, height: 50)
    RoundedRectangle(cornerRadius: 10)
        .fill(.yellow)
        .frame(width: 50, height: 50)
}
.frame(width: 300)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_newline.1.png)

## RTL

Adapts to left-to-right and right-to-left environments too.

```swift
HFlow {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: .random(in: 40...60), height: 50)
    }
}
.frame(maxWidth: 300)
.environment(\.layoutDirection, .rightToLeft)
```

![HFlow](Tests/FlowTests/SnapshotTests/Image/__Snapshots__/ReadmeSnapshotTests/hflow_rtl.1.png)
