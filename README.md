# SwiftUI Flow Layout

Introduces `HFlow` and `VFlow` similar to `HStack` and `VStack`. 
Arranges views in lines and cuts new lines accordingly (if elements don't fit the bounding space).

## HFlow

```swift
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

![HFlow](Resources/hflow.png)

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

![VFlow](Resources/vflow.png)

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

![HFlow](Resources/hflow-top.png)

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

![HFlow](Resources/hflow-center.png)

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

![HFlow](Resources/hflow-spacing.png)

## Justified

Justify by stretching items, the spaces between them, or both.

```swift
HFlow(justification: .stretchItems) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(height: 50)
            .frame(minWidth: 35)
    }
}
.frame(width: 300)
```

![HFlow](Resources/hflow-justified.png)

---

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
```

![HFlow](Resources/hflow-distributed.png)

---

Distribute and justify for visually pleasing UI.

```swift
HFlow(justification: .stretchItems, distributeItemsEvenly: true) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(height: 50)
            .frame(minWidth: 60)
    }
}
.frame(width: 300)
```

![HFlow](Resources/hflow-justified-and-distributed.png)

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

![HFlow](Resources/hflow-rtl.png)
