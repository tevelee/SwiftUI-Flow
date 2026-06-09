import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct JustifiedDistributedSnapshots {
    @Test func HFlow_justified_rigid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1, 2 × 1], in: 9 × 2)
        assertLayoutRendering(result) {
            """
            +---------+
            |AAA   BBB|
            |CC       |
            +---------+
            """
        }
    }

    @Test func HFlow_justified_flexible() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1 ... inf × 1, 2 × 1], in: 9 × 2)
        assertLayoutRendering(result) {
            """
            +---------+
            |AAA BBBBB|
            |CC       |
            +---------+
            """
        }
    }

    @Test func HFlow_justified_threePerLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let subviews: [TestSubview] = [2 × 1, 2 × 1, 2 × 1, 2 × 1]
        let result = sut.layout(subviews, in: 10 × 2)
        assertLayoutRendering(result) {
            """
            +----------+
            |AA  BB  CC|
            |DD        |
            +----------+
            """
        }
    }

    @Test func HFlow_distributed() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout(repeated(1 × 1, times: 13), in: 11 × 3)
        assertLayoutRendering(result) {
            """
            +-----------+
            |A B C D E  |
            |F G H I    |
            |J K L M    |
            +-----------+
            """
        }
    }
}
