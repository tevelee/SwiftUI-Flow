# Line Breaks

Force items onto a new line for precise control over wrapping.

## Overview

Sometimes you want to break a line yourself rather than letting the layout
decide where items wrap. Flow offers two tools for this.

### Inserting a break

Place a ``LineBreak`` view between items to end the current line so the next
item starts on a fresh one:

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

![A horizontal flow with an explicit line break before the last item](linebreak)

### Starting a view on a new line

Apply `startInNewLine()` to a view to force it to begin a new line, without
inserting a separate break view:

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

![A horizontal flow where the green item starts a new line](newline)
