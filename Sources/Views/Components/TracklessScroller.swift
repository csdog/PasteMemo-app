import AppKit
import SwiftUI

/// 只画滑块、不画槽轨。给快捷面板这种薄浮层用，避免一条灰轨道贴在玻璃边上。
final class KnobOnlyScroller: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool { true }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {}
}

enum TracklessScroller {
    @MainActor
    static func install(on scrollView: NSScrollView) {
        if !(scrollView.verticalScroller is KnobOnlyScroller) {
            let scroller = KnobOnlyScroller()
            scroller.scrollerStyle = .overlay
            scrollView.verticalScroller = scroller
        }
        if scrollView.hasHorizontalScroller, !(scrollView.horizontalScroller is KnobOnlyScroller) {
            let scroller = KnobOnlyScroller()
            scroller.scrollerStyle = .overlay
            scrollView.horizontalScroller = scroller
        }
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
    }
}

/// 挂到 SwiftUI `ScrollView` 上，找到外包的 `NSScrollView` 后去掉轨道。
struct TracklessScrollerInstaller: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        InstallerView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? InstallerView)?.installSoon()
    }

    private final class InstallerView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            installSoon()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            installSoon()
        }

        func installSoon() {
            DispatchQueue.main.async { [weak self] in
                self?.install()
            }
        }

        private func install() {
            var current: NSView? = self
            while let view = current {
                if let scrollView = view as? NSScrollView {
                    TracklessScroller.install(on: scrollView)
                    return
                }
                current = view.superview
            }
        }
    }
}

extension View {
    func hideScrollerTrack() -> some View {
        background(TracklessScrollerInstaller())
    }
}
