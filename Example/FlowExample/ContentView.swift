import SwiftUI
import Flow

public struct ContentView: View {
    @State private var useCase: FlowUseCase = .wordCloud
    @State private var settings = FlowUseCase.wordCloud.settings
    @State private var items = FlowUseCase.wordCloud.items
    @State private var selectedItemID: FlowItem.ID?
    @State private var itemFrames: [FlowItem.ID: CGRect] = [:]
    @State private var presentedSheet: FlowSheet?
    @State private var showsInspector = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            FlowTopBar(
                useCase: useCase,
                settings: $settings,
                itemCount: items.count,
                showsInspector: $showsInspector,
                selectUseCase: loadUseCase,
                addDefaultItem: addDefaultItem,
                addAdvancedItem: addAdvancedItem,
                showItems: { presentedSheet = .items }
            )

            Divider()

            HStack(spacing: 0) {
                FlowTweaksSidebar(settings: $settings)

                Divider()

                FlowCanvas(
                    settings: $settings,
                    items: items,
                    selectedItemID: $selectedItemID,
                    itemFrames: $itemFrames,
                    editItem: { presentedSheet = .editItem($0) },
                    duplicateItem: duplicateItem,
                    deleteItem: deleteItem
                )

                if showsInspector {
                    Divider()
                    FlowInspectorPanel(
                        settings: $settings,
                        selectedItem: selectedItemBinding,
                        selectedItemFrame: selectedItemFrame,
                        clearSelection: clearSelection,
                        editSelectedItem: editSelectedItem,
                        duplicateSelectedItem: duplicateSelectedItem,
                        deleteSelectedItem: deleteSelectedItem,
                        showItems: { presentedSheet = .items }
                    )
                }
            }
        }
        .frame(minWidth: 880, minHeight: 560)
        .sheet(item: $presentedSheet, content: sheetContent)
        .onAppear(perform: selectFirstItemIfNeeded)
    }

    private var selectedItemBinding: Binding<FlowItem>? {
        guard let selectedItemID else {
            return nil
        }
        return binding(for: selectedItemID)
    }

    private var selectedItemFrame: CGRect? {
        selectedItemID.flatMap { itemFrames[$0] }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: FlowSheet) -> some View {
        switch sheet {
            case .items:
                ItemsSheet(
                    items: $items,
                    selectedItemID: $selectedItemID,
                    addItem: addAdvancedItem,
                    editItem: { presentedSheet = .editItem($0) },
                    duplicateItem: duplicateItem,
                    deleteItem: deleteItem
                )
            case let .editItem(id):
                if let item = binding(for: id) {
                    ItemEditorSheet(item: item)
                } else {
                    MissingItemSheet()
                }
        }
    }

    private func binding(for id: FlowItem.ID) -> Binding<FlowItem>? {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return Binding(
            get: { items[index] },
            set: { newValue in
                guard let currentIndex = items.firstIndex(where: { $0.id == id }) else {
                    return
                }
                items[currentIndex] = newValue
            }
        )
    }

    private func loadUseCase(_ useCase: FlowUseCase) {
        applyChange {
            self.useCase = useCase
            settings = useCase.settings
            items = useCase.items
            selectedItemID = items.first?.id
            itemFrames = [:]
        }
    }

    private func addDefaultItem() {
        addItem(useCase.defaultItemKind, opensEditor: false)
    }

    private func addAdvancedItem(_ kind: FlowItemKind) {
        addItem(kind, opensEditor: false)
        showsInspector = true
    }

    private func addItem(_ kind: FlowItemKind, opensEditor: Bool) {
        applyChange {
            let item = FlowItem.newItem(kind: kind, index: items.count + 1)
            items.append(item)
            selectedItemID = item.id
            presentedSheet = opensEditor ? .editItem(item.id) : nil
        }
    }

    private func deleteItem(_ id: FlowItem.ID) {
        applyChange {
            items.removeAll { $0.id == id }
            if selectedItemID == id {
                selectedItemID = nil
            }
            itemFrames[id] = nil
        }
    }

    private func duplicateItem(_ id: FlowItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        applyChange {
            let copy = items[index].duplicated()
            items.insert(copy, at: items.index(after: index))
            selectedItemID = copy.id
        }
    }

    private func editSelectedItem() {
        if let selectedItemID {
            presentedSheet = .editItem(selectedItemID)
        }
    }

    private func deleteSelectedItem() {
        if let selectedItemID {
            deleteItem(selectedItemID)
        }
    }

    private func duplicateSelectedItem() {
        if let selectedItemID {
            duplicateItem(selectedItemID)
        }
    }

    private func clearSelection() {
        selectedItemID = nil
    }

    private func selectFirstItemIfNeeded() {
        if selectedItemID == nil {
            selectedItemID = items.first?.id
        }
    }

    private func applyChange(_ change: () -> Void) {
        if settings.animationsEnabled {
            withAnimation(.snappy, change)
        } else {
            change()
        }
    }
}

private enum FlowSheet: Identifiable {
    case items
    case editItem(FlowItem.ID)

    var id: String {
        switch self {
            case .items:
                "items"
            case let .editItem(id):
                "edit-\(id.uuidString)"
        }
    }
}

#Preview {
    ContentView()
}

#Preview {
    HFlow {
        Box()
        Box()
        Box()
        Box()
        Box()
        Box()
        Box()
        Box()
        Box()
    }
    .maxLines(2) { count in
        Text("+\(count) more...")
    }
    .frame(minWidth: 200, minHeight: 200, alignment: .top)
}

private struct Box: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 40, height: 40)
    }
}
