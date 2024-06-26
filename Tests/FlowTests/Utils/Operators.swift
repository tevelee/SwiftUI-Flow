import SwiftUI
import Foundation

infix operator ×: MultiplicationPrecedence

func × (lhs: CGFloat, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs, height: rhs)
}

func × (lhs: CGFloat, rhs: CGFloat) -> TestSubview {
    .init(size: .init(width: lhs, height: rhs))
}

func × (lhs: CGFloat, rhs: CGFloat) -> ProposedViewSize {
    .init(width: lhs, height: rhs)
}

infix operator ...: RangeFormationPrecedence

func ... (lhs: CGSize, rhs: CGSize) -> TestSubview {
    TestSubview(minSize: lhs, idealSize: lhs, maxSize: rhs)
}

let inf: CGFloat = .infinity

func repeated<T>(_ factory: @autoclosure () -> T, times: Int) -> [T] {
    (1...times).map { _ in factory() }
}
