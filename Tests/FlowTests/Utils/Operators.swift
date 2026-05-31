import Foundation
import SwiftUI

// Custom geometry operators (× and ...) are intentionally non-alphabetic.
// swiftlint:disable identifier_name

infix operator × : MultiplicationPrecedence

func × (lhs: CGFloat, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs, height: rhs)
}

func × (lhs: CGFloat, rhs: CGFloat) -> TestSubview {
    .init(size: .init(width: lhs, height: rhs))
}

func × (lhs: CGFloat, rhs: CGFloat) -> ProposedViewSize {
    .init(width: lhs, height: rhs)
}

infix operator ... : RangeFormationPrecedence

func ... (lhs: CGSize, rhs: CGSize) -> TestSubview {
    TestSubview(minSize: lhs, idealSize: lhs, maxSize: rhs)
}

// swiftlint:enable identifier_name

let inf: CGFloat = .infinity

func repeated<Element>(_ factory: @autoclosure () -> Element, times: Int) -> [Element] {
    (1 ... times).map { _ in factory() }
}
