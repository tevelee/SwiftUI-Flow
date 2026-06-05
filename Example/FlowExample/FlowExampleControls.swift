import SwiftUI

struct SegmentedEnumPicker<Value>: View
where Value: CaseIterable & CustomStringConvertible & Hashable {
    let title: String
    @Binding var selection: Value

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(Array(Value.allCases), id: \.self) { value in
                Text(value.description).tag(value)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct PointControl: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...900
    var step: Double = 1

    var body: some View {
        GridRow {
            Text(title)
            SingleTrackSlider(value: boundedValue, range: range, step: step)
                .frame(minWidth: 160)
            TextField(title, value: boundedValue, format: .number)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .frame(width: 72)
            Stepper(title, value: boundedValue, in: range, step: step)
                .labelsHidden()
        }
    }

    private var boundedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

struct SingleTrackSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let percent = percent(for: value)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.28))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, width * percent), height: 4)
                Circle()
                    .fill(.background)
                    .frame(width: 15, height: 15)
                    .overlay {
                        Circle()
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.14), radius: 2, y: 1)
                    .offset(x: max(0, min(width - 15, width * percent - 7.5)))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        value = steppedValue(for: drag.location.x, width: width)
                    }
            )
        }
        .frame(height: 22)
        .accessibilityLabel("Value")
        .accessibilityValue("\(Int(value))")
        .accessibilityAdjustableAction { direction in
            switch direction {
                case .increment:
                    value = min(range.upperBound, value + step)
                case .decrement:
                    value = max(range.lowerBound, value - step)
                @unknown default:
                    break
            }
        }
    }

    private func percent(for value: Double) -> Double {
        guard range.upperBound > range.lowerBound else {
            return 0
        }
        return min(max((value - range.lowerBound) / (range.upperBound - range.lowerBound), 0), 1)
    }

    private func steppedValue(for x: Double, width: Double) -> Double {
        guard width > 0 else {
            return value
        }

        let unclamped = range.lowerBound + (range.upperBound - range.lowerBound) * min(max(x / width, 0), 1)
        return (unclamped / step).rounded() * step
    }
}

struct OptionalPointControl: View {
    let title: String
    @Binding var value: Double?
    var defaultValue: Double = 8
    var range: ClosedRange<Double> = 0...160

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: isEnabled)
            if value != nil {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                    PointControl(title: "Value", value: unwrappedValue, range: range)
                }
                .padding(.leading, 8)
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
            set: { value = $0 }
        )
    }
}

struct AxisSizingEditor: View {
    let title: String
    @Binding var sizing: AxisSizing

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SegmentedEnumPicker(title: title, selection: $sizing.mode)

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                switch sizing.mode {
                    case .intrinsic:
                        EmptyView()
                    case .fixed:
                        PointControl(title: "Fixed", value: $sizing.fixed, range: 0...900)
                    case .flexible:
                        PointControl(title: "Minimum", value: $sizing.minimum, range: 0...900)
                    case .range:
                        PointControl(title: "Minimum", value: $sizing.minimum, range: 0...900)
                        PointControl(title: "Ideal", value: $sizing.ideal, range: 0...900)
                        GridRow {
                            Toggle("Infinite max", isOn: $sizing.maximumIsInfinite)
                            EmptyView()
                            EmptyView()
                            EmptyView()
                        }
                        if !sizing.maximumIsInfinite {
                            PointControl(title: "Maximum", value: $sizing.maximum, range: 0...900)
                        }
                }
            }
        }
    }
}

struct CompactValueButton: View {
    let title: String
    let value: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                HStack(spacing: 4) {
                    Text(title)
                    Text(value)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
    }
}
