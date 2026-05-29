# Distribution

Spread items evenly across lines, or stretch each line to fill the available space.

## Overview

### Distribute items evenly

By default a flow greedily fills each line before wrapping, which can leave the
last line sparse. Set `distributeItemsEvenly` to balance items across lines by
minimizing the empty space left in each one. This uses the Knuth–Plass line
breaking algorithm — the same dynamic-programming approach used to justify
paragraphs in typesetting.

```swift
HFlow(distributeItemsEvenly: true) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 65, height: 50)
    }
}
.frame(width: 300, alignment: .leading)
```

![A horizontal flow with items balanced evenly across rows](distribute-evenly)

### Justified lines

Set `justified` to stretch the spacing within each line so the line fills the
full available width (or height), aligning both edges.

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

![A horizontal flow whose rows are justified to both edges](justified)

> Tip: `distributeItemsEvenly` and `justified` are independent. Combine them to
> balance items across lines *and* stretch each line to the edges.
