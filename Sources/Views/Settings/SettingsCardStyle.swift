import SwiftUI

// MARK: - 设置页卡片样式
//
// 目标观感（参考 Raycast 设置）：详情区白底、分组是浅灰圆角卡片、分区标题留在卡片外。
// 系统 `Form(.grouped)` 默认是反过来的（灰底 + 白卡片），整页偏灰。这里只换配色，
// 布局、行高、分隔线仍然是系统的——不自己画行，2600 行设置代码不用重写。

/// 替代 `Section` 使用：把每一行的背景换成浅灰卡片色。`listRowBackground` 挂在
/// content 上会逐行生效（SwiftUI 对 ViewBuilder 组里的每个 row 分别应用）。
struct SettingsSection<Content: View, Header: View, Footer: View>: View {
    private let content: Content
    private let header: Header
    private let footer: Footer

    init(@ViewBuilder content: () -> Content,
         @ViewBuilder header: () -> Header,
         @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        Section {
            content.listRowBackground(SettingsCard.rowBackground)
        } header: {
            header
        } footer: {
            footer
        }
    }
}

extension SettingsSection where Header == EmptyView, Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, header: { EmptyView() }, footer: { EmptyView() })
    }
}

extension SettingsSection where Header == Text, Footer == EmptyView {
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content, header: { Text(title) }, footer: { EmptyView() })
    }
}

extension SettingsSection where Footer == EmptyView {
    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(content: content, header: header, footer: { EmptyView() })
    }
}

extension SettingsSection where Header == EmptyView {
    init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(content: content, header: { EmptyView() }, footer: footer)
    }
}

enum SettingsCard {
    /// 卡片色：浅色外观下白底上的 #F4F4F4 一档，深色外观下相应提亮。
    static let rowBackground = Color.primary.opacity(0.045)
}

private struct SettingsFormStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .formStyle(.grouped)
            // 去掉系统的灰底，换成和卡片拉开对比的纯底色（浅色白 / 深色近黑）
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
    }
}

extension View {
    /// 设置页统一的 Form 样式，替代裸 `.formStyle(.grouped)`。
    func settingsFormStyle() -> some View {
        modifier(SettingsFormStyle())
    }
}
