import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct LargeLayoutSnapshots {
    @Test func mixedSizes_30items() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let subviews: [TestSubview] = (0 ..< 30).map { i in
            let w = CGFloat(1 + (i % 5))
            let h = CGFloat(1 + (i % 3))
            return TestSubview(size: CGSize(width: w, height: h))
        }
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 20, height: 100),
            subviews: subviews
        )
        let result = sut.layout(subviews, in: size)
        assertLayoutRendering(result) {
            """
            +-------------------+
            |  BB CCC      EEEEE|
            |A BB CCC DDDD EEEEE|
            |     CCC           |
            |                   |
            |F    HHH IIII      |
            |F GG HHH IIII JJJJJ|
            |F        IIII      |
            |                   |
            |K LL     NNNN OOOOO|
            |K LL MMM NNNN OOOOO|
            |  LL          OOOOO|
            |                   |
            |  QQ RRR      TTTTT|
            |P QQ RRR SSSS TTTTT|
            |     RRR           |
            |                   |
            |U    WWW XXXX      |
            |U VV WWW XXXX YYYYY|
            |U        XXXX      |
            |                   |
            |Z aa     cccc ddddd|
            |Z aa bbb cccc ddddd|
            |  aa          ddddd|
            +-------------------+
            """
        }
    }
}
