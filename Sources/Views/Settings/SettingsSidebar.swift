import SwiftUI
import AppKit

// MARK: - 自绘设置侧边栏
//
// 不用 NavigationSplitView：它在「隐藏标题 + fullSizeContentView」的 AppKit 窗口里
// 会把 List 分组渲染成深浅条纹，选中态又是系统蓝，和参考的 Raycast 设置差得远。
// 这里自己画：统一的 sidebar 材质、彩色图标块、灰色圆角选中态。

struct SettingsSidebar: View {
    @Binding var selection: SettingsCategory
    let groups: [[SettingsCategory]]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                VStack(spacing: 2) {
                    ForEach(group) { category in
                        SettingsSidebarRow(category: category, isSelected: selection == category) {
                            selection = category
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        // 顶部给红绿灯留位：安全区已经让出标题栏高度（28pt），这里只补到 Raycast 的
        // 起始位置；材质本身 ignoresSafeArea 通顶，红绿灯浮在材质上
        .padding(.top, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SidebarMaterial().ignoresSafeArea())
    }
}

private struct SettingsSidebarRow: View {
    let category: SettingsCategory
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(category.tileColor.gradient)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                Text(L10n.tr(category.titleKey))
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.10 : (isHovering ? 0.05 : 0)))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

/// 系统 sidebar 材质（behindWindow 模糊），和 NavigationSplitView 侧边栏同一种底。
private struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension SettingsCategory {
    /// 侧边栏图标块底色。
    var tileColor: Color {
        switch self {
        case .general: return .gray
        case .appearance: return .pink
        case .shortcuts: return .indigo
        case .quickPanel: return .blue
        case .preview: return .teal
        case .aiAgents: return .orange
        case .automation: return .purple
        case .privacy: return .blue
        case .data: return .green
        case .sponsor: return .red
        case .about: return .gray
        }
    }
}
