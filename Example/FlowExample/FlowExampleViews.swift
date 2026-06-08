import Flow
import SwiftUI

struct FlowTopBar: View {
    let useCase: FlowUseCase
    @Binding var settings: FlowLabSettings
    let itemCount: Int
    @Binding var showsInspector: Bool
    let selectUseCase: (FlowUseCase) -> Void
    let addDefaultItem: () -> Void
    let addAdvancedItem: (FlowItemKind) -> Void
    let showItems: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(FlowUseCase.allCases) { useCase in
                    Button {
                        selectUseCase(useCase)
                    } label: {
                        Label(useCase.title, systemImage: useCase.systemImage)
                    }
                }
            } label: {
                Label(useCase.title, systemImage: useCase.systemImage)
            }

            SegmentedEnumPicker(title: "Layout", selection: $settings.mode)
                .frame(maxWidth: 360)

            Spacer(minLength: 12)

            QuickAddControl(
                title: useCase.quickAddTitle,
                addDefaultItem: addDefaultItem,
                addAdvancedItem: addAdvancedItem
            )

            Button(action: showItems) {
                Label("\(itemCount)", systemImage: "list.bullet")
            }

            Button {
                withAnimation(.snappy) {
                    showsInspector.toggle()
                }
            } label: {
                Label("Inspector", systemImage: "sidebar.trailing")
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: 44)
    }
}

private struct QuickAddControl: View {
    let title: String
    let addDefaultItem: () -> Void
    let addAdvancedItem: (FlowItemKind) -> Void

    var body: some View {
        HStack(spacing: 3) {
            Button(action: addDefaultItem) {
                Label(title, systemImage: "plus")
            }

            Menu {
                Section("Advanced Add") {
                    ForEach(FlowItemKind.allCases) { kind in
                        Button {
                            addAdvancedItem(kind)
                        } label: {
                            Label(kind.description, systemImage: kind.systemImage)
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption.weight(.semibold))
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .help("Advanced add")
        }
    }
}

struct FlowTweaksSidebar: View {
    @Binding var settings: FlowLabSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                SidebarGroup("Canvas", systemImage: "rectangle.dashed") {
                    Picker("Frame", selection: $settings.canvasFrameMode) {
                        ForEach(CanvasFrameMode.allCases) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    SidebarPointControl(title: "Width", value: $settings.canvasWidth, range: 0...900)
                    SidebarPointControl(title: "Height", value: $settings.canvasHeight, range: 0...900)
                    SidebarScaleControl(title: "Zoom", value: $settings.canvasZoom)

                    HStack {
                        Text(settings.frameSummary)
                            .monospacedDigit()
                        Spacer()
                        Text(settings.canvasFrameMode == .fixed ? "exact" : "content cap")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                SidebarGroup("Alignment", systemImage: "align.horizontal.left") {
                    if settings.mode.usesHorizontalAlignment {
                        SidebarSegmentedPickerRow("Horizontal", selection: $settings.horizontalAlignment)
                    }
                    if settings.mode.usesVerticalAlignment {
                        SidebarSegmentedPickerRow("Vertical", selection: $settings.verticalAlignment)
                    }
                    SidebarSegmentedPickerRow("Direction", selection: $settings.layoutDirection)

                    if let note = settings.mode.alignmentNote {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SidebarGroup("Spacing", systemImage: "arrow.left.and.right") {
                    SidebarOptionalPointControl(title: "Item spacing", value: $settings.itemSpacing)
                    SidebarOptionalPointControl(title: "Line spacing", value: $settings.lineSpacing)
                }

                SidebarGroup("Flow", systemImage: "point.3.connected.trianglepath.dotted") {
                    SidebarToggleGrid {
                        SidebarToggleChip("Justify", systemImage: "text.alignjustify", isOn: $settings.justified)
                        SidebarToggleChip("Even", systemImage: "rectangle.split.3x1", isOn: $settings.distributeItemsEvenly)
                    }
                }


                SidebarGroup("Guides", systemImage: "eye") {
                    SidebarToggleGrid {
                        SidebarToggleChip("Animate", systemImage: "sparkles", isOn: $settings.animationsEnabled)
                        SidebarToggleChip("Border", systemImage: "rectangle", isOn: $settings.showsCanvasBorder)
                        SidebarToggleChip("Outlines", systemImage: "square.dashed", isOn: $settings.showsItemOutlines)
                        SidebarToggleChip("Indexes", systemImage: "number", isOn: $settings.showsItemIndexes)
                        SidebarToggleChip("Breaks", systemImage: "arrow.turn.down.right", isOn: $settings.showsBreakMarkers)
                        SidebarToggleChip("Flex", systemImage: "arrow.left.and.right", isOn: $settings.showsFlexHints)
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 300)
        .background(Color.secondary.opacity(0.035))
    }
}

private struct SidebarGroup<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            content
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SidebarScaleControl: View {
    let title: String
    @Binding var value: Double

    private let range = 0.5...2.0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") {
                    value = 1
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .disabled(abs(value - 1) < 0.001)
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }

            SingleTrackSlider(value: boundedValue, range: range, step: 0.05)
        }
    }

    private var boundedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

private struct SidebarPointControl: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField(title, value: boundedValue, format: .number)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                    .frame(width: 68)
                Stepper(title, value: boundedValue, in: range, step: 1)
                    .labelsHidden()
            }

            SingleTrackSlider(value: boundedValue, range: range, step: 1)
        }
    }

    private var boundedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

private struct SidebarOptionalPointControl: View {
    let title: String
    @Binding var value: Double?
    var defaultValue: Double = 8
    var range: ClosedRange<Double> = 0...160

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                isEnabled.wrappedValue.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: value == nil ? "circle" : "checkmark.circle.fill")
                    Text(title)
                    Spacer()
                    Text(value.map { "\(Int($0))" } ?? "Auto")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            if value != nil {
                SingleTrackSlider(value: unwrappedValue, range: range, step: 1)
            }
        }
    }

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { value != nil },
            set: { value = $0 ? (value ?? defaultValue) : nil }
        )
    }

    private var unwrappedValue: Binding<Double> {
        Binding(
            get: { value ?? defaultValue },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

private struct SidebarSegmentedPickerRow<Value>: View
where Value: CaseIterable & CustomStringConvertible & Hashable {
    let title: String
    @Binding var selection: Value

    init(_ title: String, selection: Binding<Value>) {
        self.title = title
        _selection = selection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("", selection: $selection) {
                ForEach(Array(Value.allCases), id: \.self) { value in
                    Text(value.description).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct SidebarPickerRow<Value>: View
where Value: CaseIterable & CustomStringConvertible & Hashable {
    let title: String
    @Binding var selection: Value

    init(_ title: String, selection: Binding<Value>) {
        self.title = title
        _selection = selection
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(Array(Value.allCases), id: \.self) { value in
                    Text(value.description).tag(value)
                }
            }
            .labelsHidden()
            .frame(width: 122)
        }
    }
}

private struct SidebarToggleGrid<Content: View>: View {
    @ViewBuilder let content: Content

    private let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 7) {
            content
        }
    }
}

private struct SidebarToggleChip: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    init(_ title: String, systemImage: String, isOn: Binding<Bool>) {
        self.title = title
        self.systemImage = systemImage
        _isOn = isOn
    }

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Label(title, systemImage: isOn ? "checkmark.circle.fill" : systemImage)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(background, in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isOn ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.10)
    }
}


struct FlowCanvas: View {
    @Binding var settings: FlowLabSettings
    let items: [FlowItem]
    @Binding var selectedItemID: FlowItem.ID?
    @Binding var itemFrames: [FlowItem.ID: CGRect]
    let editItem: (FlowItem.ID) -> Void
    let duplicateItem: (FlowItem.ID) -> Void
    let deleteItem: (FlowItem.ID) -> Void
    @State private var resizeStart: CGSize?

    private var selectedItem: FlowItem? {
        guard let selectedItemID else {
            return nil
        }
        return items.first { $0.id == selectedItemID }
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasScrollView
            if let selectedItem {
                Divider()
                SelectionActionBar(
                    item: selectedItem,
                    clear: { selectedItemID = nil },
                    edit: { editItem(selectedItem.id) },
                    duplicate: { duplicateItem(selectedItem.id) },
                    delete: { deleteItem(selectedItem.id) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(settings.animationsEnabled ? .snappy : nil, value: settings)
        .animation(settings.animationsEnabled ? .snappy : nil, value: items)
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            itemFrames = frames
        }
    }

    private var canvasScrollView: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItemID = nil
                    }

                scaledCanvas
            }
            .padding(52)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(Color.secondary.opacity(0.04))
    }

    private var scaledCanvas: some View {
        canvasContent
            .scaleEffect(settings.canvasZoom, anchor: .topLeading)
            .frame(
                width: max(44, CGFloat(settings.canvasWidth * settings.canvasZoom)),
                height: max(44, CGFloat(settings.canvasHeight * settings.canvasZoom)),
                alignment: .topLeading
            )
    }

    private var canvasContent: some View {
        preview
            .environment(\.layoutDirection, settings.layoutDirection.value)
            .constrained(to: settings)
            .coordinateSpace(name: ItemFrameReporter.coordinateSpaceName)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            }
            .overlay {
                if settings.showsCanvasBorder {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.red.opacity(0.6), lineWidth: 1)
                }
            }
            .overlay(alignment: .topLeading) {
                if settings.mode.isLazy {
                    LazyLayoutBadge(mode: settings.mode)
                        .padding(8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                CanvasResizeHandle()
                    .padding(6)
                    .gesture(resizeGesture)
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if resizeStart == nil {
                    resizeStart = CGSize(width: settings.canvasWidth, height: settings.canvasHeight)
                }
                guard let resizeStart else {
                    return
                }

                let zoom = max(settings.canvasZoom, 0.1)
                settings.canvasFrameMode = .fixed
                settings.canvasWidth = min(max(resizeStart.width + drag.translation.width / zoom, 40), 900)
                settings.canvasHeight = min(max(resizeStart.height + drag.translation.height / zoom, 40), 900)
            }
            .onEnded { _ in
                resizeStart = nil
            }
    }

    @ViewBuilder
    private var preview: some View {
        if settings.mode.isLazy, #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            lazyPreview
        } else {
            eagerLayout {
                ForEach(items) { item in
                    renderedItem(item)
                }
            }
        }
    }

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    @ViewBuilder
    private var lazyPreview: some View {
        if settings.mode == .lazyHorizontal {
            ScrollView {
                LazyHFlow(
                    data: items,
                    alignment: settings.verticalAlignment.value,
                    itemSpacing: settings.itemSpacingValue,
                    rowSpacing: settings.lineSpacingValue,
                    justified: settings.justified,
                    distributeItemsEvenly: settings.distributeItemsEvenly
                ) { item in
                    renderedItem(item, lineBreaksAffectLayout: false)
                }
            }
        } else {
            ScrollView(.horizontal) {
                LazyVFlow(
                    data: items,
                    alignment: settings.horizontalAlignment.value,
                    itemSpacing: settings.itemSpacingValue,
                    columnSpacing: settings.lineSpacingValue,
                    justified: settings.justified,
                    distributeItemsEvenly: settings.distributeItemsEvenly
                ) { item in
                    renderedItem(item, lineBreaksAffectLayout: false)
                }
            }
        }
    }

    private func renderedItem(_ item: FlowItem, lineBreaksAffectLayout: Bool = true) -> some View {
        FlowRenderedItem(
            item: item,
            index: itemIndex(item),
            isSelected: selectedItemID == item.id,
            lineBreaksAffectLayout: lineBreaksAffectLayout,
            showsItemOutlines: settings.showsItemOutlines,
            showsItemIndexes: settings.showsItemIndexes,
            showsBreakMarkers: settings.showsBreakMarkers,
            showsFlexHints: settings.showsFlexHints
        )
        .onTapGesture {
            selectedItemID = item.id
        }
        .contextMenu {
            Button {
                editItem(item.id)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                duplicateItem(item.id)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive) {
                deleteItem(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var eagerLayout: AnyLayout {
        switch settings.mode {
            case .horizontal, .lazyHorizontal:
                AnyLayout(
                    HFlow(
                        horizontalAlignment: settings.horizontalAlignment.value,
                        verticalAlignment: settings.verticalAlignment.value,
                        horizontalSpacing: settings.itemSpacingValue,
                        verticalSpacing: settings.lineSpacingValue,
                        justified: settings.justified,
                        distributeItemsEvenly: settings.distributeItemsEvenly
                    )
                )
            case .vertical, .lazyVertical:
                AnyLayout(
                    VFlow(
                        horizontalAlignment: settings.horizontalAlignment.value,
                        verticalAlignment: settings.verticalAlignment.value,
                        horizontalSpacing: settings.lineSpacingValue,
                        verticalSpacing: settings.itemSpacingValue,
                        justified: settings.justified,
                        distributeItemsEvenly: settings.distributeItemsEvenly
                    )
                )
        }
    }

    private func itemIndex(_ item: FlowItem) -> Int {
        items.firstIndex(where: { $0.id == item.id }).map { $0 + 1 } ?? 0
    }
}

private struct SelectionActionBar: View {
    let item: FlowItem
    let clear: () -> Void
    let edit: () -> Void
    let duplicate: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label(item.menuTitle, systemImage: item.kind.systemImage)
                .lineLimit(1)
                .frame(maxWidth: 260, alignment: .leading)
            Spacer(minLength: 12)
            Divider()
                .frame(height: 18)
            Button(action: edit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(action: duplicate) {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive, action: delete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: clear) {
                Label("Unselect", systemImage: "xmark.circle")
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
    }
}

struct FlowInspectorPanel: View {
    @Binding var settings: FlowLabSettings
    let selectedItem: Binding<FlowItem>?
    let selectedItemFrame: CGRect?
    let clearSelection: () -> Void
    let editSelectedItem: () -> Void
    let duplicateSelectedItem: () -> Void
    let deleteSelectedItem: () -> Void
    let showItems: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Inspector", systemImage: "sidebar.trailing")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    if selectedItem != nil {
                        Button(action: clearSelection) {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Clear selection")
                    }
                }

                if let selectedItem {
                    SelectionInspector(
                        item: selectedItem,
                        frame: selectedItemFrame,
                        edit: editSelectedItem,
                        duplicate: duplicateSelectedItem,
                        delete: deleteSelectedItem
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No selection")
                            .font(.headline)
                        Text("Select an item on the canvas to edit its content and layout.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
        }
        .frame(width: 360)
        .background(Color.secondary.opacity(0.05))
    }
}

private struct SelectionInspector: View {
    @Binding var item: FlowItem
    let frame: CGRect?
    let edit: () -> Void
    let duplicate: () -> Void
    let delete: () -> Void

    init(
        item: Binding<FlowItem>,
        frame: CGRect?,
        edit: @escaping () -> Void,
        duplicate: @escaping () -> Void,
        delete: @escaping () -> Void
    ) {
        _item = item
        self.frame = frame
        self.edit = edit
        self.duplicate = duplicate
        self.delete = delete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectionHeader

            PositionSummary(frame: frame)

            InspectorGroup("Content") {
                contentControls
            }

            if !item.isLineBreak {
                InspectorGroup("Layout") {
                    layoutControls
                }
            }

            actionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(item.color.value.opacity(item.isLineBreak ? 0.10 : 0.18))
                Image(systemName: item.kind.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(item.color.value)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.menuTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.detailSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }

    private var contentControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            EditorRow("Kind") {
                Picker("Kind", selection: $item.kind) {
                    ForEach(FlowItemKind.allCases) { kind in
                        Label(kind.description, systemImage: kind.systemImage).tag(kind)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 164, alignment: .leading)
            }

            if item.isLineBreak {
                Text("Manual break marker")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                EditorRow("Title") {
                    TextField("Title", text: $item.title)
                        .textFieldStyle(.roundedBorder)
                }

                if item.kind == .card {
                    EditorRow("Subtitle") {
                        TextField("Subtitle", text: $item.subtitle)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                EditorRow("Color") {
                    ColorMenu(selection: $item.color)
                }
            }
        }
    }

    private var layoutControls: some View {
        VStack(alignment: .leading, spacing: 11) {
            Toggle("Start in new line", isOn: $item.startsNewLine)
                .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 6) {
                Text("Flexibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Flexibility", selection: $item.flexibility) {
                    ForEach(ItemFlexibility.allCases) { flexibility in
                        Text(flexibility.description).tag(flexibility)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
            }

            CompactPointControl(title: "Priority", value: $item.layoutPriority, range: -10...10)

            SizeEditorSummary(width: item.width, height: item.height)
            CompactAxisSizingEditor(title: "Width", sizing: $item.width)
            CompactAxisSizingEditor(title: "Height", sizing: $item.height)

            if item.hasFlexHint {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.and.right")
                    Text(item.flexSummary)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(item.color.value)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(item.color.value.opacity(0.12), in: Capsule())
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            Button(action: edit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(action: duplicate) {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive, action: delete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .buttonStyle(.borderless)
        .padding(.top, 2)
    }
}

private struct InspectorGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content
        }
    }
}

private struct PositionSummary: View {
    let frame: CGRect?

    var body: some View {
        if let frame {
            HStack(spacing: 6) {
                metric("x", frame.minX)
                metric("y", frame.minY)
                metric("w", frame.width)
                metric("h", frame.height)
            }
        } else {
            Text("Position will appear after the next layout pass.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metric(_ label: String, _ value: CGFloat) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text("\(Int(value.rounded()))")
                .monospacedDigit()
        }
        .font(.caption)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.07), in: Capsule())
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ItemsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [FlowItem]
    @Binding var selectedItemID: FlowItem.ID?
    let addItem: (FlowItemKind) -> Void
    let editItem: (FlowItem.ID) -> Void
    let duplicateItem: (FlowItem.ID) -> Void
    let deleteItem: (FlowItem.ID) -> Void

    var body: some View {
        NavigationStack {
            List(selection: $selectedItemID) {
                ForEach(items) { item in
                    ItemManagementRow(
                        item: item,
                        edit: { editItem(item.id) },
                        duplicate: { duplicateItem(item.id) },
                        delete: { deleteItem(item.id) }
                    )
                    .tag(item.id)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        ForEach(FlowItemKind.allCases) { kind in
                            Button {
                                addItem(kind)
                            } label: {
                                Label(kind.description, systemImage: kind.systemImage)
                            }
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 520)
    }

    private func deleteItems(_ offsets: IndexSet) {
        let removedIDs = Set(offsets.map { items[$0].id })
        items.remove(atOffsets: offsets)
        if let selectedItemID, removedIDs.contains(selectedItemID) {
            self.selectedItemID = nil
        }
    }

    private func moveItems(_ offsets: IndexSet, _ destination: Int) {
        items.move(fromOffsets: offsets, toOffset: destination)
    }
}

private struct ItemManagementRow: View {
    let item: FlowItem
    let edit: () -> Void
    let duplicate: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind.systemImage)
                .foregroundStyle(item.color.value)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.menuTitle)
                Text(item.detailSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button(action: edit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(action: duplicate) {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Button(role: .destructive, action: delete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
    }
}

struct ItemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: FlowItem

    init(item: Binding<FlowItem>) {
        _item = item
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                EditorPanel("Content") {
                    EditorRow("Kind") {
                        Picker("Kind", selection: $item.kind) {
                            ForEach(FlowItemKind.allCases) { kind in
                                Label(kind.description, systemImage: kind.systemImage).tag(kind)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 168, alignment: .leading)
                    }

                    if !item.isLineBreak {
                        EditorRow("Title") {
                            TextField("Title", text: $item.title)
                                .textFieldStyle(.roundedBorder)
                        }

                        if item.kind == .card {
                            EditorRow("Subtitle") {
                                TextField("Subtitle", text: $item.subtitle)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        EditorRow("Color") {
                            ColorMenu(selection: $item.color)
                        }
                    }
                }

                if !item.isLineBreak {
                    EditorPanel("Layout") {
                        Toggle("Start in new line", isOn: $item.startsNewLine)
                            .toggleStyle(.checkbox)

                        EditorRow("Flexibility") {
                            Picker("Flexibility", selection: $item.flexibility) {
                                ForEach(ItemFlexibility.allCases) { flexibility in
                                    Text(flexibility.description).tag(flexibility)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        CompactPointControl(
                            title: "Priority",
                            value: $item.layoutPriority,
                            range: -10...10
                        )

                        SizeEditorSummary(width: item.width, height: item.height)
                        CompactAxisSizingEditor(title: "Width", sizing: $item.width)
                        CompactAxisSizingEditor(title: "Height", sizing: $item.height)
                    }
                }
            }
            .padding(16)

            Divider()

            HStack(spacing: 10) {
                Text(item.detailSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .padding(.top, -2)
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var editorHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.color.value.opacity(item.isLineBreak ? 0.10 : 0.18))
                Image(systemName: item.kind.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(item.color.value)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.menuTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text(item.kind.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.secondary.opacity(0.045))
    }

}

private struct EditorPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 9) {
                content
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EditorRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ColorMenu: View {
    @Binding var selection: FlowItemColor

    var body: some View {
        Menu {
            ForEach(FlowItemColor.allCases) { color in
                Button {
                    selection = color
                } label: {
                    Label(color.description, systemImage: color == selection ? "checkmark" : "circle.fill")
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(selection.value)
                    .frame(width: 11, height: 11)
                Text(selection.description)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .frame(width: 154)
    }
}

private struct CompactPointControl: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField(title, value: boundedValue, format: .number)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                    .frame(width: 64)
                Stepper(title, value: boundedValue, in: range, step: step)
                    .labelsHidden()
            }

            SingleTrackSlider(value: boundedValue, range: range, step: step)
        }
    }

    private var boundedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

private struct SizeEditorSummary: View {
    let width: AxisSizing
    let height: AxisSizing

    var body: some View {
        HStack(spacing: 8) {
            Label("Size", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.caption.weight(.semibold))
            Spacer()
            Text("\(width.summary) x \(height.summary)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.top, 2)
    }
}

private struct CompactAxisSizingEditor: View {
    let title: String
    @Binding var sizing: AxisSizing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(title, selection: $sizing.mode) {
                ForEach(AxisSizing.Mode.allCases) { mode in
                    Text(shortTitle(for: mode)).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)

            switch sizing.mode {
                case .intrinsic:
                    EmptyView()
                case .fixed:
                    CompactPointControl(title: "Fixed", value: $sizing.fixed, range: 0...900)
                case .flexible:
                    CompactPointControl(title: "Minimum", value: $sizing.minimum, range: 0...900)
                case .range:
                    CompactPointControl(title: "Minimum", value: $sizing.minimum, range: 0...900)
                    CompactPointControl(title: "Ideal", value: $sizing.ideal, range: 0...900)
                    Toggle("Infinite max", isOn: $sizing.maximumIsInfinite)
                        .toggleStyle(.checkbox)
                    if !sizing.maximumIsInfinite {
                        CompactPointControl(title: "Maximum", value: $sizing.maximum, range: 0...900)
                    }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
    }

    private func shortTitle(for mode: AxisSizing.Mode) -> String {
        switch mode {
            case .intrinsic:
                "Auto"
            case .fixed:
                "Fixed"
            case .flexible:
                "Flex"
            case .range:
                "Range"
        }
    }
}

struct MissingItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Item no longer exists.")
                .foregroundStyle(.secondary)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .frame(minWidth: 320, minHeight: 180)
    }
}

private struct FlowRenderedItem: View {
    let item: FlowItem
    let index: Int
    let isSelected: Bool
    let lineBreaksAffectLayout: Bool
    let showsItemOutlines: Bool
    let showsItemIndexes: Bool
    let showsBreakMarkers: Bool
    let showsFlexHints: Bool

    var body: some View {
        renderedBody
            .background(ItemFrameReporter(id: item.id))
    }

    @ViewBuilder
    private var renderedBody: some View {
        if item.isLineBreak {
            lineBreakView
        } else {
            itemContent
                .compositingGroup()
                .frame(width: item.width.fixedFrame, height: item.height.fixedFrame)
                .frame(
                    minWidth: item.width.minimumFrame,
                    idealWidth: item.width.idealFrame,
                    maxWidth: item.width.maximumFrame,
                    minHeight: item.height.minimumFrame,
                    idealHeight: item.height.idealFrame,
                    maxHeight: item.height.maximumFrame
                )
                .layoutPriority(item.layoutPriority)
                .flexibility(item.flexibility.value)
                .startInNewLine(item.startsNewLine)
                .contentShape(Rectangle())
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        if showsItemIndexes {
                            Text("\(index)")
                                .font(.caption2)
                                .monospacedDigit()
                                .padding(3)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 3))
                                .offset(x: -6, y: -6)
                        }

                        if showsBreakMarkers, item.startsNewLine {
                            NewLineMarker()
                                .fixedSize()
                                .offset(x: -9)
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if showsFlexHints, item.hasFlexHint {
                        FlexHintPill(item: item)
                            .padding(5)
                    }
                }
                .overlay {
                    if showsItemOutlines {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.blue.opacity(0.5), lineWidth: 1)
                    }
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
        }
    }

    @ViewBuilder
    private var itemContent: some View {
        switch item.kind {
            case .word:
                Text(item.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(nil)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.color.value.opacity(0.14), in: Capsule())
                    .foregroundStyle(item.color.value)
            case .button:
                Text(item.title)
                    .font(.callout)
                    .lineLimit(1)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(item.color.value.opacity(0.45), lineWidth: 1)
                    }
            case .card:
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(12)
                .background(item.color.value.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.color.value.opacity(0.35), lineWidth: 1)
                }
            case .swatch:
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(item.color.value.gradient)
                    Text(item.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                        .padding(4)
                }
            case .spacer:
                SpacerPreview(item: item)
            case .lineBreak:
                EmptyView()
        }
    }

    @ViewBuilder
    private var lineBreakView: some View {
        if lineBreaksAffectLayout {
            LineBreak()
                .overlay(alignment: .topLeading) {
                    if showsBreakMarkers {
                        ManualBreakMarker()
                            .fixedSize()
                            .offset(x: 2, y: 2)
                    }
                }
        } else if showsBreakMarkers {
            ManualBreakMarker()
        }
    }
}

private struct SpacerPreview: View {
    let item: FlowItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(item.color.value.opacity(0.08))
            RoundedRectangle(cornerRadius: 6)
                .stroke(item.color.value.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            HStack(spacing: 5) {
                Image(systemName: "arrow.left.and.right")
                Text(item.title)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(item.color.value)
            .padding(.horizontal, 6)
        }
        .frame(minWidth: 36, minHeight: 16)
    }
}

private struct FlexHintPill: View {
    let item: FlowItem

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.thinMaterial, in: Capsule())
        .help(item.flexSummary)
    }

    private var label: String {
        switch item.flexibility {
            case .minimum:
                "min"
            case .natural:
                item.width.mode == .flexible || item.height.mode == .flexible ? "flex" : "range"
            case .maximum:
                "grow"
        }
    }

    private var color: Color {
        switch item.flexibility {
            case .minimum:
                .orange
            case .natural:
                .teal
            case .maximum:
                .green
        }
    }
}

private struct ManualBreakMarker: View {
    var body: some View {
        Capsule()
            .fill(.red.opacity(0.75))
            .frame(width: 3, height: 24)
            .help("Manual line break")
    }
}

private struct NewLineMarker: View {
    var body: some View {
        Capsule()
            .fill(Color.accentColor.opacity(0.65))
            .frame(width: 3, height: 20)
            .help("Starts in new line")
    }
}

private struct CanvasResizeHandle: View {
    var body: some View {
        Image(systemName: "arrow.down.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.tertiary)
            .frame(width: 18, height: 18)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .help("Drag to resize canvas")
    }
}

private struct LazyLayoutBadge: View {
    let mode: FlowLayoutMode

    var body: some View {
        Label(mode.isHorizontal ? "LazyHFlow" : "LazyVFlow", systemImage: "square.grid.2x2")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .foregroundStyle(.secondary)
    }
}

private struct ItemFrameReporter: View {
    static let coordinateSpaceName = "FlowExampleCanvas"

    let id: FlowItem.ID

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ItemFramePreferenceKey.self,
                value: [id: proxy.frame(in: .named(Self.coordinateSpaceName))]
            )
        }
    }
}

private struct ItemFramePreferenceKey: PreferenceKey {
    static let defaultValue: [FlowItem.ID: CGRect] = [:]

    static func reduce(value: inout [FlowItem.ID: CGRect], nextValue: () -> [FlowItem.ID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension View {
    @ViewBuilder
    func constrained(to settings: FlowLabSettings) -> some View {
        switch settings.canvasFrameMode {
            case .fixed:
                frame(
                    width: CGFloat(settings.canvasWidth),
                    height: CGFloat(settings.canvasHeight),
                    alignment: .topLeading
                )
            case .maximum:
                frame(
                    maxWidth: CGFloat(settings.canvasWidth),
                    maxHeight: CGFloat(settings.canvasHeight),
                    alignment: .topLeading
                )
        }
    }
}
