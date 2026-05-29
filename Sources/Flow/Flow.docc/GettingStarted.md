# Getting Started

Add the package, create your first flow, and choose between horizontal and vertical layouts.

## Overview

### Installation

Add SwiftUI Flow as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/tevelee/SwiftUI-Flow", from: "1.0.0")
```

Then add `"Flow"` to your target's dependencies. In an Xcode project, use
**File ▸ Add Package Dependencies…** and enter the same URL.

Import the module wherever you use it:

```swift
import Flow
```

### A horizontal flow

``HFlow`` arranges its children from leading to trailing, wrapping to a new row
when the current row fills up:

```swift
HFlow {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: .random(in: 40...60), height: 50)
    }
}
.frame(maxWidth: 300)
```

![A horizontal flow wrapping rounded rectangles across rows](hflow)

### A vertical flow

``VFlow`` arranges its children from top to bottom, wrapping to a new column
when the current column fills up:

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

![A vertical flow wrapping rounded rectangles across columns](vflow)

### Adapting to layout direction

Flow respects the environment's layout direction automatically. In a
right-to-left environment, items flow from the trailing edge:

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

![A horizontal flow laid out right to left](rtl)

### Next steps

- <doc:Alignment> — align items and lines on either axis.
- <doc:Spacing> — control item and line spacing independently.
- <doc:Distribution> — distribute items evenly or justify lines.
- <doc:Flexibility> — let items grow to fill extra space.
- <doc:LineBreaks> — force breaks for precise control.
