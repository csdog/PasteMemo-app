import Foundation
import AppKit
import Testing
@testable import PasteMemo

@Suite("Quick panel preview font size")
struct QuickPanelPreviewFontSizeTests {

    @Test("default is the pre-existing 13pt")
    func defaultMatchesLegacyHardcodedSize() {
        #expect(QuickPanelPreviewFontSize.defaultPoints == 13)
        #expect(QuickPanelPreviewFontSize.resolved(13) == 13)
    }

    @Test("any size at or above the minimum is kept; below is clamped")
    func resolvesAnySizeAtOrAboveMinimum() {
        #expect(QuickPanelPreviewFontSize.minimumPoints == 1)
        #expect(QuickPanelPreviewFontSize.resolved(17) == 17)
        #expect(QuickPanelPreviewFontSize.resolved(1) == 1)
        #expect(QuickPanelPreviewFontSize.resolved(9) == 9)
        #expect(QuickPanelPreviewFontSize.resolved(36) == 36)
        #expect(QuickPanelPreviewFontSize.resolved(100) == 100)
        #expect(QuickPanelPreviewFontSize.resolved(0) == 1)
        #expect(QuickPanelPreviewFontSize.resolved(-3) == 1)
        #expect(QuickPanelPreviewFontSize.resolvedPoints(20) == 20)
    }

    @Test("scaled sizes track body points from the 13pt design baseline")
    func scaledTracksBody() {
        #expect(QuickPanelPreviewFontSize.scaled(13, bodyPoints: 13) == 13)
        #expect(QuickPanelPreviewFontSize.scaled(11, bodyPoints: 13) == 11)
        #expect(QuickPanelPreviewFontSize.scaled(13, bodyPoints: 26) == 26)
        #expect(QuickPanelPreviewFontSize.scaled(11, bodyPoints: 26) == 22)
        #expect(QuickPanelPreviewFontSize.scaled(10, bodyPoints: 1) == 1)
    }

    @Test("rich text body font scales to the configured size while keeping relative headings")
    @MainActor
    func applyingBodyFontSizeScalesRichText() {
        let body = NSAttributedString(
            string: "body ",
            attributes: [.font: NSFont.systemFont(ofSize: 12)]
        )
        let heading = NSAttributedString(
            string: "H",
            attributes: [.font: NSFont.systemFont(ofSize: 18, weight: .bold)]
        )
        let source = NSMutableAttributedString()
        source.append(body)
        source.append(heading)

        let scaled = NativeTextView.applyingBodyFontSize(source, bodyPoints: 24)
        let bodyFont = scaled.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        let headingFont = scaled.attribute(.font, at: 5, effectiveRange: nil) as? NSFont
        #expect(abs((bodyFont?.pointSize ?? 0) - 24) < 0.2)
        #expect(abs((headingFont?.pointSize ?? 0) - 36) < 0.2)
    }
}
