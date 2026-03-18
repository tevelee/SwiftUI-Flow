import SwiftUI
import Testing

extension HorizontalAlignment: @retroactive CaseIterable, @retroactive CustomTestStringConvertible {
    public static var allCases: [HorizontalAlignment] { [.leading, .center, .trailing] }

    public var testDescription: String {
        switch self {
        case .leading: "leading"
        case .center: "center"
        case .trailing: "trailing"
        default: "unknown"
        }
    }
}

extension VerticalAlignment: @retroactive CaseIterable, @retroactive CustomTestStringConvertible {
    public static var allCases: [VerticalAlignment] { [.top, .center, .bottom] }

    public var testDescription: String {
        switch self {
        case .top: "top"
        case .center: "center"
        case .bottom: "bottom"
        default: "unknown"
        }
    }
}
