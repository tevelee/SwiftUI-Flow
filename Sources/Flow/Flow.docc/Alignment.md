# Alignment

Align items within a line, and align lines within the layout, on either axis.

## Overview

Flow supports the same alignment guides as `HStack` and `VStack`. For an
``HFlow``, the `alignment` parameter controls how items align vertically within
each row:

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

![A horizontal flow with items aligned to the top of each row](alignment-top)

Any of the standard guides work — for example `.center` or `.bottom`:

![Items aligned to the vertical center of each row](alignment-center)

![Items aligned to the bottom of each row](alignment-bottom)

### Aligning on both axes

Alignment can be specified on both axes at once — ideal for tag clouds, where
each row is centered horizontally and items align to the top:

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

![A horizontal flow with rows centered horizontally and items aligned to the top](alignment-tag)

> Note: For a ``VFlow`` the roles swap — the single-axis `alignment` parameter is
> a `HorizontalAlignment` that positions items within each column.
