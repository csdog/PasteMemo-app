import AppKit
import SwiftUI
import ApplicationServices

enum QuickPanelPositionMode: String, CaseIterable {
    case remembered
    case cursor
    case menuBarIcon
    case windowCenter
    case screenCenter

    var titleKey: String {
        switch self {
        case .remembered: "settings.quickPanelPosition.remembered"
        case .cursor: "settings.quickPanelPosition.cursor"
        case .menuBarIcon: "settings.quickPanelPosition.menuBarIcon"
        case .windowCenter: "settings.quickPanelPosition.windowCenter"
        case .screenCenter: "settings.quickPanelPosition.screenCenter"
        }
    }
}

enum QuickPanelScreenTarget: String, CaseIterable {
    case active
    case specified

    var titleKey: String {
        switch self {
        case .active: "settings.quickPanelTargetScreen.active"
        case .specified: "settings.quickPanelTargetScreen.specified"
        }
    }
}

enum QuickPanelPositionSettings {
    static let modeKey = "quickPanelPositionMode"
    static let screenTargetKey = "quickPanelScreenTarget"
    static let specifiedScreenIDKey = "quickPanelSpecifiedScreenID"
}

enum QuickPanelSettings {
    static let launchAnimationEnabledKey = "quickPanelLaunchAnimationEnabled"
    static let secondaryRowKey = "quickPanelSecondaryRow"
    /// 开关：重新打开快捷面板时是否恢复上次的 tab 主筛选（默认关闭）
    static let rememberLastFilterKey = "quickPanelRememberLastFilter"
    /// 序列化后的上次 tab 主筛选，供恢复用
    static let lastFilterKey = "quickPanelLastFilter"
    /// 「图片」筛选下的展示方式：列表 / 瀑布流网格（默认列表，行为不变）
    static let imageLayoutKey = "quickPanelImageLayout"
    /// 瀑布流密度（疏 / 中 / 密 → 目标列宽），默认中
    static let imageGridDensityKey = "quickPanelImageGridDensity"
    /// 在快捷面板标签栏里隐藏的项（逗号分隔的 id：`pinned` 或内容类型 rawValue）。
    ///
    /// 刻意不复用 `typeOrder`：那个键是主窗口侧边栏的类型排序。快捷面板的顺序和
    /// 显隐都只作用于标签栏，主窗口侧边栏保持全量。
    static let hiddenTabTypesKey = "quickPanelHiddenTabTypes"
    /// 快捷面板标签栏顺序（逗号分隔的 id，含 `pinned` / `all` / 内容类型）。
    static let tabOrderKey = "quickPanelTabOrder"
    static let pinnedTabID = "pinned"
    static let allTabID = "all"

    /// 被隐藏的类型集合
    static func hiddenTabTypes() -> Set<ClipContentType> {
        let raw = UserDefaults.standard.string(forKey: hiddenTabTypesKey) ?? ""
        return Set(raw.split(separator: ",").compactMap { ClipContentType(rawValue: String($0)) })
    }

    static var defaultTabOrderIDs: [String] {
        [pinnedTabID, allTabID] + ClipContentType.visibleCases.map(\.rawValue)
    }

    static func resolvedTabOrderIDs(from raw: String) -> [String] {
        let fallback = defaultTabOrderIDs
        let saved = raw.split(separator: ",").map(String.init).filter { !$0.isEmpty }
        guard !saved.isEmpty else { return fallback }
        let known = Set(fallback)
        var seen = Set<String>()
        var result: [String] = []
        for id in saved where known.contains(id) && seen.insert(id).inserted {
            result.append(id)
        }
        for id in fallback where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func resolvedTabItems(from raw: String) -> [QuickPanelTabItem] {
        resolvedTabOrderIDs(from: raw).compactMap(QuickPanelTabItem.parse)
    }

    static func hiddenTabIDs(from raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }
}

/// 快捷面板设置里「标签栏显示的分类」的一项，含置顶 / 全部 / 内容类型。
enum QuickPanelTabItem: Hashable, Identifiable {
    case pinned
    case all
    case type(ClipContentType)

    var id: String { storageID }

    var storageID: String {
        switch self {
        case .pinned: return QuickPanelSettings.pinnedTabID
        case .all: return QuickPanelSettings.allTabID
        case .type(let type): return type.rawValue
        }
    }

    static func parse(_ raw: String) -> QuickPanelTabItem? {
        switch raw {
        case QuickPanelSettings.pinnedTabID: return .pinned
        case QuickPanelSettings.allTabID: return .all
        default:
            guard let type = ClipContentType(rawValue: raw),
                  ClipContentType.defaultVisibleCases.contains(type) else { return nil }
            return .type(type)
        }
    }

    var canHide: Bool { true }

    var icon: String {
        switch self {
        case .pinned: return "pin"
        case .all: return "tray.full"
        case .type(let type): return type.icon
        }
    }

    @MainActor
    var label: String {
        switch self {
        case .pinned: return L10n.tr("filter.pinned")
        case .all: return L10n.tr("filter.all")
        case .type(let type): return type.label
        }
    }
}

/// 选中「图片」类型时的展示方式。仅作用于图片筛选，其它类型始终用列表。
enum QuickPanelImageLayout: String, CaseIterable {
    case list
    case grid

    var titleKey: String {
        switch self {
        case .list: "settings.imageLayout.list"
        case .grid: "settings.imageLayout.grid"
        }
    }
}

/// 瀑布流密度——决定「目标列宽」，面板宽度按它换算出列数（宽度变化列数自适应）。
enum QuickPanelImageGridDensity: String, CaseIterable {
    case sparse
    case medium
    case dense

    /// 目标列宽（pt）。实际列宽会在此基础上拉伸撑满整宽，不留右侧空隙。
    var targetColumnWidth: CGFloat {
        switch self {
        case .sparse: 210
        case .medium: 165
        case .dense: 125
        }
    }

    var titleKey: String {
        switch self {
        case .sparse: "settings.imageGridDensity.sparse"
        case .medium: "settings.imageGridDensity.medium"
        case .dense: "settings.imageGridDensity.dense"
        }
    }
}

enum QuickPanelSecondaryRow: String, CaseIterable {
    case types
    case groups

    var titleKey: String {
        switch self {
        case .types: "settings.quickPanelSecondaryRow.types"
        case .groups: "settings.quickPanelSecondaryRow.groups"
        }
    }
}

struct ScreenOption: Identifiable, Hashable {
    let id: String
    let name: String
}

enum ScreenLocator {
    static func identifier(for screen: NSScreen) -> String? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return number.stringValue
    }

    static func options() -> [ScreenOption] {
        let screens = NSScreen.screens
        let grouped = Dictionary(grouping: screens, by: \.localizedName)

        return screens.compactMap { screen in
            guard let id = identifier(for: screen) else { return nil }
            let isDuplicated = (grouped[screen.localizedName]?.count ?? 0) > 1
            let name = isDuplicated ? "\(screen.localizedName) (\(id))" : screen.localizedName
            return ScreenOption(id: id, name: name)
        }
    }

    static func screen(for identifier: String?) -> NSScreen? {
        guard let identifier else { return nil }
        return NSScreen.screens.first { self.identifier(for: $0) == identifier }
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    static func screen(for frame: CGRect) -> NSScreen? {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        if let screen = screen(containing: center) {
            return screen
        }

        return NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        }
    }
}

enum ActiveWindowLocator {
    @MainActor
    static func focusedWindowFrame() -> CGRect? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let windowRef,
              CFGetTypeID(windowRef) == AXUIElementGetTypeID()
        else {
            return nil
        }
        let window = windowRef as! AXUIElement

        // Reject non-standard windows (e.g. Finder desktop pseudo-window, which spans all displays).
        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef)
        let subrole = subroleRef as? String
        if subrole != kAXStandardWindowSubrole as String,
           subrole != kAXDialogSubrole as String,
           subrole != kAXFloatingWindowSubrole as String {
            return nil
        }

        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let positionRef,
              let sizeRef,
              CFGetTypeID(positionRef) == AXValueGetTypeID(),
              CFGetTypeID(sizeRef) == AXValueGetTypeID()
        else {
            return nil
        }
        let positionValue = positionRef as! AXValue
        let sizeValue = sizeRef as! AXValue

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size)
        else {
            return nil
        }

        return Self.axRectToCocoa(CGRect(origin: position, size: size))
    }

    /// Convert a rect from AX global coords (origin = top-left of primary screen, Y down)
    /// to Cocoa screen coords (origin = bottom-left of primary screen, Y up).
    @MainActor
    static func axRectToCocoa(_ rect: CGRect) -> CGRect? {
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                ?? NSScreen.main
        else { return nil }
        let flippedY = primary.frame.height - rect.origin.y - rect.size.height
        return CGRect(x: rect.origin.x, y: flippedY, width: rect.size.width, height: rect.size.height)
    }

    @MainActor
    static func activeScreen() -> NSScreen? {
        if let frame = focusedWindowFrame(), let screen = ScreenLocator.screen(for: frame) {
            return screen
        }
        return NSScreen.screenWithMouse ?? NSScreen.main ?? NSScreen.screens.first
    }
}

enum MenuBarIconLocator {
    @MainActor
    static func iconFrame() -> (frame: CGRect, screen: NSScreen)? {
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            guard className.contains("StatusBar") else { continue }
            let frame = window.frame
            guard frame.width > 0, frame.height > 0 else { continue }
            let screen = window.screen
                ?? ScreenLocator.screen(containing: CGPoint(x: frame.midX, y: frame.midY))
            guard let screen else { continue }
            return (frame, screen)
        }
        return nil
    }
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
