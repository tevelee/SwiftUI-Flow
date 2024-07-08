import SwiftUI

struct ContentView: View {
    @State private var axis: Axis = .horizontal
    @State private var contents: Contents = .boxes
    @State private var width: CGFloat = 400
    @State private var height: CGFloat = 400
    @State private var itemSpacing: CGFloat? = nil
    @State private var lineSpacing: CGFloat? = nil
    @State private var justified: Justified = .none
    @State private var horizontalAlignment: HAlignment = .center
    @State private var verticalAlignment: VAlignment = .center
    @State private var distributeItemsEvenly: Bool = false
    private let texts = "This is a long text that wraps nicely in flow layout".components(separatedBy: " ").map { string in
        AnyView(Text(string))
    }
    private let colors = [Color.red, .orange, .yellow, .mint, .green, .teal, .blue, .purple, .indigo].map { color in
        AnyView(color.frame(height: 30).frame(minWidth: 30))
    }

    enum HAlignment: String, Hashable, CaseIterable, CustomStringConvertible {
        case leading, center, trailing
        var description: String { rawValue }
        var value: HorizontalAlignment {
            switch self {
                case .leading: .leading
                case .center: .center
                case .trailing: .trailing
            }
        }
    }

    enum VAlignment: String, Hashable, CaseIterable, CustomStringConvertible {
        case top, baseline, center, bottom
        var description: String { rawValue }
        var value: VerticalAlignment {
            switch self {
                case .top: .top
                case .baseline: .firstTextBaseline
                case .center: .center
                case .bottom: .bottom
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                Section(header: Text("Content")) {
                    picker($contents)
                }
                Section(header: Text("Layout")) {
                    picker($axis)
                }
                Section(header: Text("Size")) {
                    Grid {
                        GridRow {
                            Text("Width").gridColumnAlignment(.leading)
                            Slider(value: $width.animation(), in: 0...400)
                                .padding(.horizontal)
                        }
                        GridRow {
                            Text("Height")
                            Slider(value: $height.animation(), in: 0...400)
                                .padding(.horizontal)
                        }
                    }
                }
                Section(header: Text("Alignment")) {
                    switch axis {
                        case .horizontal: picker($verticalAlignment)
                        case .vertical: picker($horizontalAlignment)
                    }
                }
                Section(header: Text("Spacing")) {
                    stepper("Item", $itemSpacing)
                    stepper("Line", $lineSpacing)
                }
                Section(header: Text("Extras")) {
                    picker($justified, style: .radioGroup)
                    Toggle("Distibute evenly", isOn: $distributeItemsEvenly.animation())
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 250)
            .navigationTitle("Flow Layout")
            .padding()
        } detail: {
            layout {
                let views: [AnyView] = switch contents {
                    case .texts: texts
                    case .boxes: colors
                }
                ForEach(Array(views.enumerated()), id: \.offset) { $0.element.border(.blue) }
            }
            .border(.red.opacity(0.2))
            .frame(maxWidth: width, maxHeight: height)
            .border(.red)
        }
        .frame(minWidth: 600, minHeight: 600)
    }

    private func stepper(_ title: String, _ selection: Binding<CGFloat?>) -> some View {
        HStack {
            Toggle(isOn: Binding(
                get: { selection.wrappedValue != nil },
                set: { selection.wrappedValue = $0 ? 8 : nil }).animation()
            ) {
                Text(title)
            }
            if let value = selection.wrappedValue {
                Text("\(value.formatted())")
                Stepper("", value: Binding(
                    get: { value },
                    set: { selection.wrappedValue = $0 }
                ).animation(), step: 4)
            }
        }.fixedSize()
    }

    private func picker<Value>(_ selection: Binding<Value>, style: some PickerStyle = .segmented) -> some View where Value: Hashable & CaseIterable & CustomStringConvertible, Value.AllCases: RandomAccessCollection {
        Picker("", selection: selection.animation()) {
            ForEach(Value.allCases, id: \.self) { value in
                Text(value.description).tag(value)
            }
        }
        .pickerStyle(style)
    }

    private var layout: AnyLayout {
        switch axis {
            case .horizontal:
            return AnyLayout(
                HFlow(
                    alignment: verticalAlignment.value,
                    itemSpacing: itemSpacing,
                    rowSpacing: lineSpacing,
                    justification: justified.justification,
                    distributeItemsEvenly: distributeItemsEvenly
                )
            )
            case .vertical:
            return AnyLayout(
                VFlow(
                    alignment: horizontalAlignment.value,
                    itemSpacing: itemSpacing,
                    columnSpacing: lineSpacing,
                    justification: justified.justification,
                    distributeItemsEvenly: distributeItemsEvenly
                )
            )
        }
    }
}

enum Contents: String, CustomStringConvertible, CaseIterable {
    case texts
    case boxes

    var description: String { rawValue }
}

enum Justified: String, CustomStringConvertible, CaseIterable {
    case none = "no justification"
    case stretchItems = "stretch items"
    case stretchSpaces = "stretch spaces"
    case stretchItemsAndSpaces = "stretch both"

    var description: String { rawValue }

    var justification: Justification? {
        switch self {
            case .none: nil
            case .stretchItems: .stretchItems
            case .stretchSpaces: .stretchSpaces
            case .stretchItemsAndSpaces: .stretchItemsAndSpaces
        }
    }
}

#Preview {
    ContentView()
}
