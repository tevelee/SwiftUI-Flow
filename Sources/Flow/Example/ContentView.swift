import SwiftUI

struct ContentView: View {
    @State private var mode: LayoutMode = .horizontal
    @State private var contents: Contents = .boxes
    @State private var width: CGFloat = 400
    @State private var height: CGFloat = 400
    @State private var itemSpacing: CGFloat?
    @State private var lineSpacing: CGFloat?
    @State private var justified: Bool = false
    @State private var horizontalAlignment: HAlignment = .leading
    @State private var verticalAlignment: VAlignment = .top
    @State private var distributeItemsEvenly: Bool = false
    @State private var minimumItemSize: CGFloat = 80
    @State private var lazySpacing: CGFloat = 8

    private let texts = "This is a long text that wraps nicely in flow layout".components(separatedBy: " ").map { string in
        AnyView(Text(string))
    }
    private let colors = [Color.red, .orange, .yellow, .mint, .green, .teal, .blue, .purple, .indigo].map { color in
        AnyView(color.frame(height: 30).frame(minWidth: 30))
    }

    enum LayoutMode: String, Hashable, CaseIterable, CustomStringConvertible {
        case horizontal, vertical, lazyHorizontal, lazyVertical

        var description: String {
            switch self {
                case .horizontal: "H Flow"
                case .vertical: "V Flow"
                case .lazyHorizontal: "Lazy H"
                case .lazyVertical: "Lazy V"
            }
        }

        var isLazy: Bool { self == .lazyHorizontal || self == .lazyVertical }
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

    private struct IdentifiableView: Identifiable {
        let id: Int
        let view: AnyView
    }

    private var currentViews: [AnyView] {
        switch contents {
            case .texts: texts
            case .boxes: colors
        }
    }

    private var identifiableViews: [IdentifiableView] {
        currentViews.enumerated().map { IdentifiableView(id: $0.offset, view: $0.element) }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                Section(header: Text("Content")) {
                    picker($contents)
                }
                Section(header: Text("Layout")) {
                    picker($mode)
                }
                Section(header: Text("Size")) {
                    Grid {
                        GridRow {
                            Text("Width").gridColumnAlignment(.leading)
                            Slider(value: $width.animation(.snappy), in: 0 ... 400)
                                .padding(.horizontal)
                            Text("\(Int(width))")
                                .monospacedDigit()
                                .frame(minWidth: 30, alignment: .trailing)
                        }
                        GridRow {
                            Text("Height")
                            Slider(value: $height.animation(.snappy), in: 0 ... 400)
                                .padding(.horizontal)
                            Text("\(Int(height))")
                                .monospacedDigit()
                                .frame(minWidth: 30, alignment: .trailing)
                        }
                    }
                }
                if mode.isLazy {
                    Section(header: Text("Grid Config")) {
                        Grid {
                            GridRow {
                                Text(mode == .lazyHorizontal ? "Min width" : "Min height")
                                    .gridColumnAlignment(.leading)
                                Slider(value: $minimumItemSize.animation(.snappy), in: 20 ... 200)
                                    .padding(.horizontal)
                                Text("\(Int(minimumItemSize))")
                                    .monospacedDigit()
                                    .frame(minWidth: 30, alignment: .trailing)
                            }
                            GridRow {
                                Text("Spacing")
                                Slider(value: $lazySpacing.animation(.snappy), in: 0 ... 40)
                                    .padding(.horizontal)
                                Text("\(Int(lazySpacing))")
                                    .monospacedDigit()
                                    .frame(minWidth: 30, alignment: .trailing)
                            }
                        }
                        Text("Grid-based: no per-item sizing or animation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                } else {
                    Section(header: Text("Alignment")) {
                        picker($horizontalAlignment)
                        picker($verticalAlignment)
                    }
                    Section(header: Text("Spacing")) {
                        stepper("Item", $itemSpacing)
                        stepper("Line", $lineSpacing)
                    }
                    Section(header: Text("Extras")) {
                        Toggle("Justified", isOn: $justified)
                        Toggle("Distribute evenly", isOn: $distributeItemsEvenly.animation())
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 250)
            .navigationTitle("Flow Layout")
            .padding()
        } detail: {
            VStack(spacing: 6) {
                Group {
                    if mode.isLazy {
                        lazyContent
                    } else {
                        eagerLayout {
                            ForEach(Array(currentViews.enumerated()), id: \.offset) { $0.element.border(.blue) }
                        }
                    }
                }
                .border(.red.opacity(0.2))
                .frame(maxWidth: width, maxHeight: height)
                .border(.red)

                Text("\(Int(width)) × \(Int(height)) pt")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }

    @ViewBuilder
    private var lazyContent: some View {
        if mode == .lazyHorizontal {
            ScrollView {
                LazyHFlow(
                    data: identifiableViews,
                    minimumItemWidth: minimumItemSize,
                    spacing: lazySpacing
                ) { item in
                    item.view.border(.blue)
                }
            }
        } else {
            ScrollView(.horizontal) {
                LazyVFlow(
                    data: identifiableViews,
                    minimumItemHeight: minimumItemSize,
                    spacing: lazySpacing
                ) { item in
                    item.view.border(.blue)
                }
            }
        }
    }

    private func stepper(_ title: String, _ selection: Binding<CGFloat?>) -> some View {
        HStack {
            Toggle(
                isOn: Binding(
                    get: { selection.wrappedValue != nil },
                    set: { selection.wrappedValue = $0 ? 8 : nil }
                ).animation()
            ) {
                Text(title)
            }
            if let value = selection.wrappedValue {
                Text("\(value.formatted())")
                Stepper(
                    "",
                    value: Binding(
                        get: { value },
                        set: { selection.wrappedValue = $0 }
                    ).animation(),
                    step: 4
                )
            }
        }.fixedSize()
    }

    private func picker<Value>(_ selection: Binding<Value>, style: some PickerStyle = .segmented) -> some View
    where Value: Hashable & CaseIterable & CustomStringConvertible, Value.AllCases: RandomAccessCollection {
        Picker("", selection: selection.animation()) {
            ForEach(Value.allCases, id: \.self) { value in
                Text(value.description).tag(value)
            }
        }
        .pickerStyle(style)
    }

    private var eagerLayout: AnyLayout {
        switch mode {
            case .horizontal, .lazyHorizontal:
                AnyLayout(
                    HFlow(
                        horizontalAlignment: horizontalAlignment.value,
                        verticalAlignment: verticalAlignment.value,
                        horizontalSpacing: itemSpacing,
                        verticalSpacing: lineSpacing,
                        justified: justified,
                        distributeItemsEvenly: distributeItemsEvenly
                    )
                )
            case .vertical, .lazyVertical:
                AnyLayout(
                    VFlow(
                        horizontalAlignment: horizontalAlignment.value,
                        verticalAlignment: verticalAlignment.value,
                        horizontalSpacing: lineSpacing,
                        verticalSpacing: itemSpacing,
                        justified: justified,
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

#Preview {
    ContentView()
}
