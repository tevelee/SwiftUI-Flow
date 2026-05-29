# Spacing

Control the space between items and between lines independently.

## Overview

Pass a single `spacing:` value to set both, or set `itemSpacing` and
`rowSpacing` (for ``HFlow``) / `columnSpacing` (for ``VFlow``) separately. When
omitted, Flow uses each view's preferred spacing, just like `HStack` and
`VStack`.

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

![A horizontal flow with tight item spacing and loose row spacing](spacing)
