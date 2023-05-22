#if os(macOS)
import ArgumentParser
import Flow
import SwiftUI

@main
@available(macOS 13, *)
struct Render: ParsableCommand {
    @Option(name: .long, help: "Axis")
    var axis: Axis = .horizontal

    @Option(name: .long, help: "Layout direction")
    var layoutDirection: LayoutDirection = .leftToRight

    @Option(name: .long, help: "Alignment")
    var alignment: String = "center"

    @Option(name: .long, help: "Item spacing")
    var itemSpacing: Int?

    @Option(name: .long, help: "Line spacing")
    var lineSpacing: Int?

    @Option(name: .long, help: "Width")
    var width: Int?

    @Option(name: .long, help: "Height")
    var height: Int?

    @Flag(name: .long, help: "Fixed Width")
    var fixedWidth: Bool = false

    @Flag(name: .long, help: "Fixed Height")
    var fixedHeight: Bool = false

    @MainActor
    mutating func run() throws {
        try validateInputs()
        let view = try createView()
        let data = try render(view: view)
        try writeToStandardOutput(data)
    }

    private func createView() throws -> some View {
        let layout: AnyLayout
        switch axis {
        case .horizontal:
            guard let alignment = VerticalAlignment(rawValue: alignment)?.alignment else {
                throw "Invalid alignment \(alignment)"
            }
            layout = AnyLayout(HFlow(alignment: alignment,
                                     itemSpacing: itemSpacing.map(CGFloat.init),
                                     rowSpacing: lineSpacing.map(CGFloat.init)))
        case .vertical:
            guard let alignment = HorizontalAlignment(rawValue: alignment)?.alignment else {
                throw "Invalid alignment \(alignment)"
            }
            layout = AnyLayout(VFlow(alignment: alignment,
                                     itemSpacing: itemSpacing.map(CGFloat.init),
                                     columnSpacing: lineSpacing.map(CGFloat.init)))
        }
        return Colors(layout: layout, fixedWidth: fixedWidth, fixedHeight: fixedHeight)
            .frame(
                width: width.map(CGFloat.init),
                height: height.map(CGFloat.init)
            )
            .environment(\.layoutDirection, layoutDirection)
    }

    @MainActor
    private func render(view: some View) throws -> Data {
        let image = ImageRenderer(content: view)
        image.proposedSize.width = width.map(CGFloat.init)
        image.proposedSize.height = height.map(CGFloat.init)

        guard let data = image.nsImage?.png else {
            throw "Failed to render view"
        }
        return data
    }

    private func writeToStandardOutput(_ data: Data) throws {
        try FileHandle.standardOutput.write(contentsOf: data)
    }

    private func validateInputs() throws {
        if axis == .horizontal && VerticalAlignment(rawValue: alignment) == nil {
            let values = VerticalAlignment.allCases.map(\.rawValue)
            let formattedValues = ListFormatter().string(from: values) ?? String(describing: values)
            throw "Available alignment values are \(formattedValues)"
        }
        if axis == .vertical && HorizontalAlignment(rawValue: alignment) == nil {
            let values = HorizontalAlignment.allCases.map(\.rawValue)
            let formattedValues = ListFormatter().string(from: values) ?? String(describing: values)
            throw "Available alignment values are \(formattedValues)"
        }
    }
}

extension String: Error {}

private extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
private extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
private extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }
}

extension Axis: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "vertical":
            self = .vertical
        default:
            self = .horizontal
        }
    }
}

extension LayoutDirection: RawRepresentable, ExpressibleByArgument {
    public var rawValue: String {
        switch self {
        case .leftToRight: return "left-to-right"
        case .rightToLeft: return "right-to-left"
        @unknown default: return "left-to-right"
        }
    }
    public init?(rawValue: String) {
        for value in LayoutDirection.allCases where value.rawValue == rawValue {
            self = value
            return
        }
        return nil
    }
}

enum HorizontalAlignment: String, CaseIterable {
    case leading
    case center
    case trailing

    var alignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

enum VerticalAlignment: String, CaseIterable {
    case top
    case center
    case bottom
    case firstTextBaseline
    case lastTextBaseline

    var alignment: SwiftUI.VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        case .firstTextBaseline: return .firstTextBaseline
        case .lastTextBaseline: return .lastTextBaseline
        }
    }
}

@available(macOS 13, *)
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

    let layout: AnyLayout
    let fixedWidth: Bool
    let fixedHeight: Bool

    var body: some View {
        layout {
            ForEach(colors + colors, id: \.description) { color in
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.gradient)
                    .frame(width: Double.random(in: 40...60), height: 50)
                    .frame(
                        width: fixedWidth ? 50 : Double(String(describing: color).count * 10),
                        height: fixedHeight ? 50 : Double(String(describing: color).count * 10)
                    )
            }
        }
    }
}
#else
@main
struct Render {
    static func main() {
        fatalError("Unsupported Platform")
    }
}
#endif
