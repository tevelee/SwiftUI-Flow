# SwiftUI Flow Layout

Introduces `HFlow` and `VFlow` similar to `HStack` and `VStack`. 
Arranges views in lines and cuts new lines accordingly (if elements don't fit the bounding space).

- [x] Spacing (separate item spacing and line spacing)
- [x] Alignment
- [x] Conforms to `Layout` protocol
- [x] Supports Right-to-Left layout direction
- [x] Sample SwiftUI View to tweak parameters

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
            ForEach(colors + colors, id: \.description) { color in
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.gradient)
                    .frame(width: Double.random(in: 40...60), height: 50)
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
            .frame(width: 50, height: Double.random(in: 40...60))
    }
}
.frame(maxHeight: 300)
```

![VFlow](Resources/vflow.png)

## Alignment

```swift
HFlow(alignment: .top) {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: 50, height: Double.random(in: 40...60))
    }
}
.frame(maxWidth: 300)
```

![VFlow](Resources/hflow-top.png)

## Spacing

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

![VFlow](Resources/hflow-spacing.png)

## RTL

```swift
HFlow {
    ForEach(colors, id: \.description) { color in
        RoundedRectangle(cornerRadius: 10)
            .fill(color.gradient)
            .frame(width: Double.random(in: 40...60), height: 50)
    }
}
.frame(maxWidth: 300)
.environment(\.layoutDirection, .rightToLeft)
```

![VFlow](Resources/hflow-rtl.png)