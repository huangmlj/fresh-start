import AppKit
import Darwin
import SwiftUI
import UniformTypeIdentifiers

private let appBundleIdentifier = "local.reset-mac.manager"
private let accentPurple = Color(red: 0.47, green: 0.24, blue: 0.82)

@main
struct ResetMacApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Fresh Start") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1060, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("刷新应用") {
                    model.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}

private struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var columnLayout = ColumnLayout()

    var body: some View {
        VStack(spacing: 0) {
            topCommandBar
            Divider()
            appList
            Divider()
            bottomBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            model.refresh()
        }
    }

    private var topCommandBar: some View {
        HStack(alignment: .center, spacing: 28) {
            CommandButton(title: "添加应用", systemImage: "plus.square.on.square") {
                model.addApplication()
            }

            CommandButton(title: "移除应用", systemImage: "minus.square") {
                model.removeSelected()
            }
            .disabled(model.selection.isEmpty)

            VerticalRule()

            CommandButton(title: "一键关闭", systemImage: "xmark.circle.fill", tint: accentPurple, isProminent: true) {
                Task { await model.closeApps(sleepAfter: false) }
            }
            .disabled(model.closeableItems.isEmpty || model.isWorking)

            CommandButton(
                title: "低电量模式",
                systemImage: model.isLowPowerModeEnabled ? "battery.25" : "battery.100",
                tint: model.isLowPowerModeEnabled ? accentPurple : .secondary,
                isProminent: model.isLowPowerModeEnabled,
                isActive: model.isLowPowerModeEnabled
            ) {
                model.toggleLowPowerMode()
            }

            CommandButton(title: "关闭并睡眠", systemImage: "moon.fill", tint: accentPurple, isProminent: true) {
                Task { await model.closeApps(sleepAfter: true) }
            }
            .disabled(model.closeableItems.isEmpty || model.isWorking)

            VerticalRule()

            Spacer()

            CommandButton(title: "刷新", systemImage: "arrow.clockwise") {
                model.refresh()
            }
            .disabled(model.isWorking)

            CommandButton(title: "偏好设置", systemImage: "gearshape") {
                model.showPreferences()
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var appList: some View {
        VStack(spacing: 0) {
            AppListHeader(
                layout: $columnLayout,
                selectAllState: model.selectAllState,
                onToggleSelectAll: { model.toggleSelectAll() },
                sortColumn: model.sortColumn,
                sortDirection: model.sortDirection,
                onSort: { model.sort(by: $0) }
            )
            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.items) { item in
                        AppRow(
                            item: item,
                            layout: columnLayout,
                            isSelected: model.selection.contains(item.id),
                            onSelect: { model.select(item.id) },
                            onToggleClose: { model.toggleCloseTarget(item.id) },
                            onMakeDefaultExcluded: { model.addDefaultExcluded(item.id) },
                            onRemoveDefaultExcluded: { model.removeDefaultExcluded(item.id) }
                        )
                        Divider()
                            .padding(.leading, 88)
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var bottomBar: some View {
        HStack(spacing: 20) {
            Text("已选择: \(model.closeableItems.count) 个应用")
                .frame(width: 210, alignment: .leading)

            Spacer()

            Text("总内存占用: \(MemoryFormatter.string(from: model.closeableMemoryBytes))")
                .frame(minWidth: 230)

            Spacer()

            Text("已监控: \(model.items.count) 个应用")
                .frame(width: 180, alignment: .trailing)
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct CommandButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .secondary
    var isProminent = false
    var isActive = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? tint : Color.secondary.opacity(0.38))
                    .frame(width: 44, height: 34)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.45))
                    .lineLimit(1)
            }
            .frame(width: 86, height: 68)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(hoverBackground)
        .overlay(hoverBorder)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    private var isHoverActive: Bool {
        isEnabled && isHovering
    }

    private var hoverBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(commandBackground)
    }

    private var hoverBorder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(commandBorder, lineWidth: 1)
    }

    private var commandBackground: Color {
        if isActive {
            return tint.opacity(0.13)
        }
        if isHoverActive {
            return tint.opacity(isProminent ? 0.12 : 0.08)
        }
        return .clear
    }

    private var commandBorder: Color {
        if isActive {
            return tint.opacity(0.42)
        }
        if isHoverActive {
            return tint.opacity(isProminent ? 0.45 : 0.24)
        }
        return .clear
    }
}

private struct VerticalRule: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.55))
            .frame(width: 1, height: 54)
    }
}

private struct ColumnLayout {
    static let checkboxWidth: CGFloat = 78
    static let resizeHandleWidth: CGFloat = 32
    static let trailingPadding: CGFloat = 24

    static let minNameWidth: CGFloat = 220
    static let minStatusWidth: CGFloat = 130
    static let minMemoryWidth: CGFloat = 130
    static let minPIDWidth: CGFloat = 74

    var nameWidth: CGFloat = 360
    var statusWidth: CGFloat = 190
    var memoryWidth: CGFloat = 180
    var pidWidth: CGFloat = 90

    func resized(at boundary: ColumnBoundary, by delta: CGFloat, from start: ColumnLayout) -> ColumnLayout {
        var next = start
        let adjustedDelta: CGFloat

        switch boundary {
        case .nameStatus:
            adjustedDelta = delta.clamped(
                lower: Self.minNameWidth - start.nameWidth,
                upper: start.statusWidth - Self.minStatusWidth
            )
            next.nameWidth = start.nameWidth + adjustedDelta
            next.statusWidth = start.statusWidth - adjustedDelta
        case .statusMemory:
            adjustedDelta = delta.clamped(
                lower: Self.minStatusWidth - start.statusWidth,
                upper: start.memoryWidth - Self.minMemoryWidth
            )
            next.statusWidth = start.statusWidth + adjustedDelta
            next.memoryWidth = start.memoryWidth - adjustedDelta
        case .memoryPID:
            adjustedDelta = delta.clamped(
                lower: Self.minMemoryWidth - start.memoryWidth,
                upper: start.pidWidth - Self.minPIDWidth
            )
            next.memoryWidth = start.memoryWidth + adjustedDelta
            next.pidWidth = start.pidWidth - adjustedDelta
        }

        return next
    }
}

private enum ColumnBoundary {
    case nameStatus
    case statusMemory
    case memoryPID
}

private enum SortColumn {
    case name
    case status
    case memory
    case pid

    var defaultDirection: SortDirection {
        switch self {
        case .name, .status, .pid:
            return .ascending
        case .memory:
            return .descending
        }
    }
}

private enum SortDirection {
    case ascending
    case descending

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }

    var iconName: String {
        switch self {
        case .ascending:
            return "chevron.up"
        case .descending:
            return "chevron.down"
        }
    }
}

private enum SelectAllState {
    case none
    case partial
    case all

    var iconName: String {
        switch self {
        case .none:
            return "square"
        case .partial:
            return "minus.square.fill"
        case .all:
            return "checkmark.square.fill"
        }
    }

    var help: String {
        switch self {
        case .none:
            return "全选可关闭应用"
        case .partial:
            return "全选可关闭应用"
        case .all:
            return "取消全选可关闭应用"
        }
    }
}

private struct AppListHeader: View {
    @Binding var layout: ColumnLayout
    let selectAllState: SelectAllState
    let onToggleSelectAll: () -> Void
    let sortColumn: SortColumn
    let sortDirection: SortDirection
    let onSort: (SortColumn) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggleSelectAll) {
                Image(systemName: selectAllState.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selectAllState == .none ? Color.secondary.opacity(0.8) : accentPurple)
                    .frame(width: ColumnLayout.checkboxWidth)
            }
            .buttonStyle(.plain)
            .help(selectAllState.help)

            SortHeaderCell(
                title: "应用名称",
                column: .name,
                width: layout.nameWidth,
                alignment: .leading,
                sortColumn: sortColumn,
                sortDirection: sortDirection,
                onSort: onSort
            )

            ColumnResizeHandle(layout: $layout, boundary: .nameStatus)

            SortHeaderCell(
                title: "状态",
                column: .status,
                width: layout.statusWidth,
                alignment: .leading,
                sortColumn: sortColumn,
                sortDirection: sortDirection,
                onSort: onSort
            )

            ColumnResizeHandle(layout: $layout, boundary: .statusMemory)

            SortHeaderCell(
                title: "内存占用",
                column: .memory,
                width: layout.memoryWidth,
                alignment: .leading,
                sortColumn: sortColumn,
                sortDirection: sortDirection,
                onSort: onSort
            )

            ColumnResizeHandle(layout: $layout, boundary: .memoryPID)

            SortHeaderCell(
                title: "PID",
                column: .pid,
                width: layout.pidWidth,
                alignment: .trailing,
                sortColumn: sortColumn,
                sortDirection: sortDirection,
                onSort: onSort
            )
                .padding(.trailing, ColumnLayout.trailingPadding)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.primary)
        .frame(height: 58)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct SortHeaderCell: View {
    let title: String
    let column: SortColumn
    let width: CGFloat
    let alignment: Alignment
    let sortColumn: SortColumn
    let sortDirection: SortDirection
    let onSort: (SortColumn) -> Void

    @State private var isHovering = false

    private var isActive: Bool {
        sortColumn == column
    }

    var body: some View {
        Button {
            onSort(column)
        } label: {
            HStack(spacing: 6) {
                if alignment == .trailing {
                    Spacer(minLength: 0)
                }

                Text(title)
                    .lineLimit(1)

                Image(systemName: isActive ? sortDirection.iconName : "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isActive ? accentPurple : Color.clear)
                    .frame(width: 12)

                if alignment != .trailing {
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 8)
            .frame(width: width, height: 34, alignment: alignment)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? accentPurple.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isHovering ? accentPurple.opacity(0.22) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeOut(duration: 0.1), value: isHovering)
    }
}

private struct ColumnResizeHandle: View {
    @Binding var layout: ColumnLayout
    let boundary: ColumnBoundary

    @State private var startLayout: ColumnLayout?
    @State private var isHovering = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isHovering ? accentPurple.opacity(0.16) : Color.clear)
                .frame(width: 7, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Rectangle()
                .fill(isHovering ? accentPurple.opacity(0.62) : Color(nsColor: .separatorColor).opacity(0.5))
                .frame(width: 1, height: 34)
        }
        .frame(width: ColumnLayout.resizeHandleWidth, height: 58)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let base = startLayout ?? layout
                    startLayout = base
                    layout = layout.resized(at: boundary, by: value.translation.width, from: base)
                }
                .onEnded { _ in
                    startLayout = nil
                }
        )
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .animation(.easeOut(duration: 0.1), value: isHovering)
    }
}

private struct ColumnGap: View {
    var body: some View {
        Color.clear
            .frame(width: ColumnLayout.resizeHandleWidth)
    }
}

private struct AppRow: View {
    let item: AppItem
    let layout: ColumnLayout
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleClose: () -> Void
    let onMakeDefaultExcluded: () -> Void
    let onRemoveDefaultExcluded: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggleClose) {
                Image(systemName: item.isCloseTarget ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(item.isCheckboxLocked ? Color.secondary.opacity(0.35) : accentPurple)
                    .frame(width: ColumnLayout.checkboxWidth)
            }
            .buttonStyle(.plain)
            .disabled(item.isCheckboxLocked)
            .help(item.checkboxHelp)

            HStack(spacing: 14) {
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(7)

                Text(item.name)
                    .font(.system(size: 17, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? accentPurple : .primary)
            }
            .frame(width: layout.nameWidth, alignment: .leading)

            ColumnGap()

            StatusCell(status: item.status)
                .frame(width: layout.statusWidth, alignment: .leading)

            ColumnGap()

            Text(item.memoryText)
                .font(.system(size: 16, weight: .medium))
                .monospacedDigit()
                .frame(width: layout.memoryWidth, alignment: .leading)

            ColumnGap()

            Text(item.pidText)
                .font(.system(size: 16, weight: .medium))
                .monospacedDigit()
                .frame(width: layout.pidWidth, alignment: .trailing)
                .padding(.trailing, ColumnLayout.trailingPadding)
        }
        .frame(height: 58)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .contextMenu {
            if item.isProtected {
                Button("系统保留，不能修改") {}
                    .disabled(true)
            } else if item.isDefaultExcluded {
                Button {
                    onRemoveDefaultExcluded()
                } label: {
                    Label("移除默认不退出", systemImage: "checkmark.square")
                }
            } else {
                Button {
                    onMakeDefaultExcluded()
                } label: {
                    Label("添加到默认不退出", systemImage: "lock")
                }
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return accentPurple.opacity(0.12)
        }
        return Color(nsColor: .controlBackgroundColor)
    }
}

private extension CGFloat {
    func clamped(lower: CGFloat, upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, lower), upper)
    }
}

private struct StatusCell: View {
    let status: AppStatus

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 9, height: 9)

            Text(status.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(status.textColor)
        }
    }
}

@MainActor
private final class AppModel: ObservableObject {
    @Published var items: [AppItem] = []
    @Published var selection = Set<AppItem.ID>()
    @Published var message = "准备就绪"
    @Published var isWorking = false
    @Published var sortColumn: SortColumn = .name
    @Published var sortDirection: SortDirection = .ascending
    @Published var showSystemApplications: Bool
    @Published var isLowPowerModeEnabled = false

    private let userDefaults = UserDefaults.standard
    private let excludedKey = "ExcludedCloseIdentifiers"
    private let legacyExcludedKey = "ExcludedBundleIdentifiers"
    private let manualAppsKey = "ManualApplicationPaths"
    private let showSystemApplicationsKey = "ShowSystemApplications"
    private let softTermDelay: UInt64 = 2_000_000_000

    private let protectedBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "local.reset-mac.one-click"
    ]

    private let softTermBundleIdentifiers: Set<String> = [
        "com.tencent.xinWeChat"
    ]

    private var excludedCloseIdentifiers: Set<String>
    private var manualApplicationPaths: Set<String>

    var closeableItems: [AppItem] {
        items.filter { !$0.isProtected && $0.isCloseTarget }
    }

    var closeableMemoryBytes: UInt64 {
        closeableItems.reduce(0) { $0 + $1.memoryBytes }
    }

    var selectAllState: SelectAllState {
        let controllableItems = items.filter { !$0.isProtected }
        guard !controllableItems.isEmpty else {
            return .none
        }

        let selectedCount = controllableItems.filter(\.isCloseTarget).count
        if selectedCount == 0 {
            return .none
        }
        if selectedCount == controllableItems.count {
            return .all
        }
        return .partial
    }

    init() {
        let currentExcluded = userDefaults.stringArray(forKey: excludedKey) ?? []
        let legacyExcluded = userDefaults.stringArray(forKey: legacyExcludedKey) ?? []
        excludedCloseIdentifiers = Set(currentExcluded + legacyExcluded)
        manualApplicationPaths = Set(userDefaults.stringArray(forKey: manualAppsKey) ?? [])
        showSystemApplications = userDefaults.object(forKey: showSystemApplicationsKey) as? Bool ?? true
        isLowPowerModeEnabled = Self.readLowPowerMode()
        refresh()
    }

    func refresh() {
        let previousSelection = selection
        let memoryByPID = readMemoryByPID()
        var rowsByID: [AppItem.ID: AppItem] = [:]

        for application in NSWorkspace.shared.runningApplications {
            guard let item = makeRunningItem(application, memoryByPID: memoryByPID) else { continue }
            rowsByID[item.id] = item
        }

        for path in manualApplicationPaths.sorted() {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let bundleIdentifier = Bundle(url: url)?.bundleIdentifier

            if let bundleIdentifier,
               rowsByID.values.contains(where: { $0.bundleIdentifier == bundleIdentifier }) {
                continue
            }

            let item = makeManualItem(url: url)
            rowsByID[item.id] = item
        }

        items = sortedItems(Array(rowsByID.values))
        selection = previousSelection.intersection(Set(items.map(\.id)))
        message = "已扫描 \(items.count) 个应用"
    }

    func sort(by column: SortColumn) {
        if sortColumn == column {
            sortDirection.toggle()
        } else {
            sortColumn = column
            sortDirection = column.defaultDirection
        }

        sortVisibleItems()
    }

    func toggleSelectAll() {
        let shouldSelectAll = selectAllState != .all
        var changedCount = 0

        for index in items.indices {
            guard !items[index].isProtected else { continue }

            if shouldSelectAll {
                if items[index].isDefaultExcluded || !items[index].isCloseTarget {
                    applyDefaultIncluded(at: index)
                    changedCount += 1
                }
            } else {
                if applyDefaultExcluded(at: index) {
                    changedCount += 1
                }
            }
        }

        savePreferences()
        sortVisibleItems()
        message = shouldSelectAll ? "已全选 \(changedCount) 个应用" : "已取消全选 \(changedCount) 个应用"
    }

    func select(_ id: AppItem.ID) {
        if NSEvent.modifierFlags.contains(.command) {
            if selection.contains(id) {
                selection.remove(id)
            } else {
                selection.insert(id)
            }
        } else {
            selection = [id]
        }
    }

    func toggleCloseTarget(_ id: AppItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard !items[index].isProtected else {
            message = "受保护应用不会被关闭"
            return
        }
        guard !items[index].isDefaultExcluded else {
            message = "默认不退出应用需要右键移除后才能勾选"
            return
        }

        addDefaultExcluded(id)
    }

    func addApplication() {
        let panel = NSOpenPanel()
        panel.title = "添加应用"
        panel.prompt = "添加"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            manualApplicationPaths.insert(url.path)
            let exclusionID = exclusionIdentifier(bundleIdentifier: Bundle(url: url)?.bundleIdentifier, path: url.path)
            excludedCloseIdentifiers.remove(exclusionID)
        }

        savePreferences()
        refresh()
    }

    func removeSelected() {
        guard !selection.isEmpty else { return }

        var removedCount = 0

        for index in items.indices where selection.contains(items[index].id) {
            if applyDefaultExcluded(at: index) {
                removedCount += 1
            }
        }

        savePreferences()
        message = removedCount == 0 ? "没有可移除的应用" : "已设为默认不退出 \(removedCount) 个应用"
        sortVisibleItems()
    }

    func editSelected() {
        guard !selection.isEmpty else { return }

        var changedCount = 0

        for index in items.indices where selection.contains(items[index].id) {
            guard !items[index].isProtected else { continue }
            if items[index].isDefaultExcluded {
                applyDefaultIncluded(at: index)
            } else {
                applyDefaultExcluded(at: index)
            }
            changedCount += 1
        }

        message = changedCount == 0 ? "受保护应用不会被编辑" : "已更新 \(changedCount) 个应用"
        sortVisibleItems()
    }

    func toggleLowPowerMode() {
        let nextValue = !isLowPowerModeEnabled

        do {
            try Self.setLowPowerMode(nextValue)
            isLowPowerModeEnabled = Self.readLowPowerMode()
            message = isLowPowerModeEnabled ? "已开启低电量模式" : "已关闭低电量模式"
        } catch let error as AppCommandError where error.isUserCancelled {
            message = "已取消切换低电量模式"
        } catch {
            showError(title: "无法切换低电量模式", message: error.localizedDescription)
        }
    }

    func addDefaultExcluded(_ id: AppItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if applyDefaultExcluded(at: index) {
            savePreferences()
            message = "已把 \(items[index].name) 添加到默认不退出"
            sortVisibleItems()
        } else {
            message = "受保护应用已经默认不退出"
        }
    }

    func removeDefaultExcluded(_ id: AppItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard items[index].isDefaultExcluded else {
            message = "\(items[index].name) 不在默认不退出名单中"
            return
        }

        applyDefaultIncluded(at: index)
        savePreferences()
        message = "已把 \(items[index].name) 移出默认不退出"
        sortVisibleItems()
    }

    func showPreferences() {
        let alert = NSAlert()
        alert.messageText = "偏好设置"
        alert.informativeText = "选择应用列表里显示哪些类型。关闭清单和默认不退出名单会继续自动保存。"

        let titleLabel = NSTextField(labelWithString: "系统应用")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
        popUp.addItems(withTitles: ["显示系统应用", "隐藏系统应用"])
        popUp.selectItem(at: showSystemApplications ? 0 : 1)

        let stack = NSStackView(views: [titleLabel, popUp])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.frame = NSRect(x: 0, y: 0, width: 260, height: 64)
        alert.accessoryView = stack

        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        showSystemApplications = popUp.indexOfSelectedItem == 0
        userDefaults.set(showSystemApplications, forKey: showSystemApplicationsKey)
        refresh()
    }

    func closeApps(sleepAfter: Bool) async {
        guard !isWorking else { return }

        isWorking = true
        defer { isWorking = false }

        let targets = closeableItems
        guard !targets.isEmpty else {
            message = "没有需要关闭的应用"
            if sleepAfter { sleepNow() }
            return
        }

        let otherTargets = targets.filter { !isCurrentApplication($0) }
        let selfTargets = targets.filter { isCurrentApplication($0) }

        for target in otherTargets {
            updateStatus(for: target.id, status: .closing)
            await quit(target)
        }

        try? await Task.sleep(nanoseconds: 700_000_000)

        for target in otherTargets {
            if isRunning(target) {
                updateStatus(for: target.id, status: .failed)
            } else {
                updateStatus(for: target.id, status: .closed)
            }
        }

        sortVisibleItems()

        message = sleepAfter ? "清理完成，准备睡眠" : "清理完成"

        if !selfTargets.isEmpty {
            for target in selfTargets {
                updateStatus(for: target.id, status: .closing)
            }
            if sleepAfter {
                scheduleSleepAfterSelfExit()
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            terminateSelf()
            return
        }

        if sleepAfter {
            sleepNow()
            return
        }

        try? await Task.sleep(nanoseconds: 900_000_000)
        refresh()
    }

    private func makeRunningItem(_ application: NSRunningApplication, memoryByPID: [pid_t: UInt64]) -> AppItem? {
        guard let name = application.localizedName,
              shouldDisplay(application) else {
            return nil
        }

        let bundleIdentifier = application.bundleIdentifier
        let path = application.bundleURL?.path
        let exclusionID = exclusionIdentifier(bundleIdentifier: bundleIdentifier, path: path)
        let isProtected = bundleIdentifier.map { protectedBundleIdentifiers.contains($0) } ?? false
        let isDefaultExcluded = excludedCloseIdentifiers.contains(exclusionID)
        let isCloseTarget = !isProtected && !isDefaultExcluded

        return AppItem(
            id: itemID(bundleIdentifier: bundleIdentifier, pid: application.processIdentifier, path: path),
            name: name,
            bundleIdentifier: bundleIdentifier,
            pid: application.processIdentifier,
            path: path,
            icon: application.icon ?? icon(for: application.bundleURL),
            memoryBytes: memoryByPID[application.processIdentifier] ?? 0,
            status: statusForItem(isProtected: isProtected, isDefaultExcluded: isDefaultExcluded, isRunning: true),
            isProtected: isProtected,
            isCloseTarget: isCloseTarget,
            isDefaultExcluded: isDefaultExcluded,
            exclusionIdentifier: exclusionID
        )
    }

    private func makeManualItem(url: URL) -> AppItem {
        let bundle = Bundle(url: url)
        let name = displayName(for: url, bundle: bundle)
        let bundleIdentifier = bundle?.bundleIdentifier
        let exclusionID = exclusionIdentifier(bundleIdentifier: bundleIdentifier, path: url.path)
        let isProtected = bundleIdentifier.map { protectedBundleIdentifiers.contains($0) } ?? false
        let isDefaultExcluded = excludedCloseIdentifiers.contains(exclusionID)
        let isCloseTarget = !isProtected && !isDefaultExcluded

        return AppItem(
            id: itemID(bundleIdentifier: bundleIdentifier, pid: nil, path: url.path),
            name: name,
            bundleIdentifier: bundleIdentifier,
            pid: nil,
            path: url.path,
            icon: icon(for: url),
            memoryBytes: 0,
            status: statusForItem(isProtected: isProtected, isDefaultExcluded: isDefaultExcluded, isRunning: false),
            isProtected: isProtected,
            isCloseTarget: isCloseTarget,
            isDefaultExcluded: isDefaultExcluded,
            exclusionIdentifier: exclusionID
        )
    }

    private func shouldDisplay(_ application: NSRunningApplication) -> Bool {
        guard application.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return true
        }

        guard let bundleURL = application.bundleURL else {
            return false
        }

        if bundleURL.path.contains("/Contents/") {
            return false
        }

        if !showSystemApplications && isSystemApplication(application, bundleURL: bundleURL) {
            return false
        }

        switch application.activationPolicy {
        case .regular, .accessory:
            return true
        case .prohibited:
            return false
        @unknown default:
            return false
        }
    }

    private func isSystemApplication(_ application: NSRunningApplication, bundleURL: URL) -> Bool {
        let path = bundleURL.standardizedFileURL.path
        if path.hasPrefix("/System/") || path.hasPrefix("/Library/CoreServices/") {
            return true
        }

        if let bundleIdentifier = application.bundleIdentifier,
           bundleIdentifier.hasPrefix("com.apple.") {
            return true
        }

        return false
    }

    private func quit(_ item: AppItem) async {
        guard let application = runningApplication(for: item) else {
            return
        }

        _ = application.terminate()

        if let bundleIdentifier = item.bundleIdentifier,
           softTermBundleIdentifiers.contains(bundleIdentifier) {
            try? await Task.sleep(nanoseconds: softTermDelay)
            if application.isTerminated == false {
                Darwin.kill(application.processIdentifier, SIGTERM)
            }
        }
    }

    private func isCurrentApplication(_ item: AppItem) -> Bool {
        if item.pid == getpid() {
            return true
        }

        guard let bundleIdentifier = item.bundleIdentifier else {
            return false
        }

        return bundleIdentifier == Bundle.main.bundleIdentifier || bundleIdentifier == appBundleIdentifier
    }

    private func isRunning(_ item: AppItem) -> Bool {
        runningApplication(for: item)?.isTerminated == false
    }

    private func runningApplication(for item: AppItem) -> NSRunningApplication? {
        if let pid = item.pid,
           let application = NSRunningApplication(processIdentifier: pid),
           application.isTerminated == false {
            return application
        }

        if let bundleIdentifier = item.bundleIdentifier {
            return NSWorkspace.shared.runningApplications.first {
                $0.bundleIdentifier == bundleIdentifier && !$0.isTerminated
            }
        }

        return nil
    }

    private func updateStatus(for id: AppItem.ID, status: AppStatus) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].status = status
    }

    private func sortVisibleItems() {
        items = sortedItems(items)
    }

    private func sortedItems(_ source: [AppItem]) -> [AppItem] {
        source.sorted { left, right in
            compare(left, right) == .orderedAscending
        }
    }

    private func compare(_ left: AppItem, _ right: AppItem) -> ComparisonResult {
        let primary: ComparisonResult

        switch sortColumn {
        case .name:
            primary = compareNameGroup(left, right)
        case .status:
            primary = compareInts(left.status.sortRank, right.status.sortRank)
        case .memory:
            primary = compareUInts(left.memoryBytes, right.memoryBytes)
        case .pid:
            primary = compareOptionalPIDs(left.pid, right.pid)
        }

        if primary != .orderedSame {
            return directed(primary)
        }

        let nameResult = left.name.localizedStandardCompare(right.name)
        if nameResult != .orderedSame {
            return nameResult
        }

        return left.id.localizedStandardCompare(right.id)
    }

    private func compareNameGroup(_ left: AppItem, _ right: AppItem) -> ComparisonResult {
        let leftGroup = left.isCloseTarget ? 0 : 1
        let rightGroup = right.isCloseTarget ? 0 : 1
        let groupResult = compareInts(leftGroup, rightGroup)
        if groupResult != .orderedSame {
            return groupResult
        }
        return left.name.localizedStandardCompare(right.name)
    }

    private func directed(_ result: ComparisonResult) -> ComparisonResult {
        guard sortDirection == .descending else {
            return result
        }

        switch result {
        case .orderedAscending:
            return .orderedDescending
        case .orderedDescending:
            return .orderedAscending
        case .orderedSame:
            return .orderedSame
        }
    }

    private func compareInts(_ left: Int, _ right: Int) -> ComparisonResult {
        if left < right { return .orderedAscending }
        if left > right { return .orderedDescending }
        return .orderedSame
    }

    private func compareUInts(_ left: UInt64, _ right: UInt64) -> ComparisonResult {
        if left < right { return .orderedAscending }
        if left > right { return .orderedDescending }
        return .orderedSame
    }

    private func compareOptionalPIDs(_ left: pid_t?, _ right: pid_t?) -> ComparisonResult {
        switch (left, right) {
        case let (left?, right?):
            return compareInts(Int(left), Int(right))
        case (nil, nil):
            return .orderedSame
        case (nil, _?):
            return .orderedDescending
        case (_?, nil):
            return .orderedAscending
        }
    }

    @discardableResult
    private func applyDefaultExcluded(at index: Int) -> Bool {
        guard !items[index].isProtected, !items[index].isDefaultExcluded else {
            return false
        }

        items[index].isDefaultExcluded = true
        items[index].isCloseTarget = false
        items[index].status = .defaultExcluded
        excludedCloseIdentifiers.insert(items[index].exclusionIdentifier)
        return true
    }

    private func applyDefaultIncluded(at index: Int) {
        items[index].isDefaultExcluded = false
        items[index].isCloseTarget = !items[index].isProtected
        items[index].status = statusForItem(
            isProtected: items[index].isProtected,
            isDefaultExcluded: false,
            isRunning: items[index].pid != nil
        )
        excludedCloseIdentifiers.remove(items[index].exclusionIdentifier)
    }

    private func statusForItem(isProtected: Bool, isDefaultExcluded: Bool, isRunning: Bool) -> AppStatus {
        if isProtected {
            return .protected
        }
        if isDefaultExcluded {
            return .defaultExcluded
        }
        return isRunning ? .running : .added
    }

    private func savePreferences() {
        userDefaults.set(Array(excludedCloseIdentifiers).sorted(), forKey: excludedKey)
        userDefaults.set(Array(manualApplicationPaths).sorted(), forKey: manualAppsKey)
    }

    private static func readLowPowerMode() -> Bool {
        guard let output = try? runPMSet(arguments: ["-g"]) else {
            return false
        }

        for line in output.split(separator: "\n") where line.contains("lowpowermode") {
            return line.split(whereSeparator: \.isWhitespace).last == "1"
        }

        return false
    }

    private static func setLowPowerMode(_ enabled: Bool) throws {
        try runPrivilegedShellCommand("/usr/bin/pmset -a lowpowermode \(enabled ? "1" : "0")")
    }

    private static func runPMSet(arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let detail = errorOutput.isEmpty ? output : errorOutput
            throw AppCommandError(message: detail.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }

    private static func runPrivilegedShellCommand(_ command: String) throws {
        let escapedCommand = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = "do shell script \"\(escapedCommand)\" with administrator privileges"
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            let detail = errorOutput.isEmpty ? output : errorOutput
            throw AppCommandError(message: detail.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message.isEmpty ? "系统没有返回具体错误。" : message
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private func sleepNow() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["sleepnow"]
        try? process.run()
    }

    private func scheduleSleepAfterSelfExit() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 0.6; /usr/bin/pmset sleepnow"]
        try? process.run()
    }

    private func terminateSelf() {
        NSApplication.shared.terminate(nil)
    }

    private func readMemoryByPID() -> [pid_t: UInt64] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,rss="]
        process.standardOutput = pipe

        do {
            try process.run()
        } catch {
            return [:]
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return [:]
        }

        var result: [pid_t: UInt64] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard parts.count >= 2,
                  let pid = pid_t(String(parts[0])),
                  let rssKB = UInt64(parts[1]) else {
                continue
            }
            result[pid] = rssKB * 1024
        }
        return result
    }

    private func itemID(bundleIdentifier: String?, pid: pid_t?, path: String?) -> String {
        if let bundleIdentifier {
            return "bundle:\(bundleIdentifier)"
        }
        if let path {
            return "path:\(path)"
        }
        return "pid:\(pid ?? 0)"
    }

    private func exclusionIdentifier(bundleIdentifier: String?, path: String?) -> String {
        if let bundleIdentifier {
            return "bundle:\(bundleIdentifier)"
        }
        if let path {
            return "path:\(path)"
        }
        return "unknown"
    }

    private func icon(for url: URL?) -> NSImage {
        guard let url else {
            return NSWorkspace.shared.icon(for: .applicationBundle)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func displayName(for url: URL, bundle: Bundle?) -> String {
        if let localizedName = bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return localizedName
        }
        if let displayName = bundle?.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }
        if let name = bundle?.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return url.deletingPathExtension().lastPathComponent
    }
}

private struct AppItem: Identifiable {
    typealias ID = String

    let id: String
    let name: String
    let bundleIdentifier: String?
    let pid: pid_t?
    let path: String?
    let icon: NSImage
    let memoryBytes: UInt64
    var status: AppStatus
    let isProtected: Bool
    var isCloseTarget: Bool
    var isDefaultExcluded: Bool
    let exclusionIdentifier: String

    var isCheckboxLocked: Bool {
        isProtected || isDefaultExcluded
    }

    var pidText: String {
        guard let pid else { return "-" }
        return String(pid)
    }

    var memoryText: String {
        guard memoryBytes > 0 else { return "-" }
        return MemoryFormatter.string(from: memoryBytes)
    }

    var checkboxHelp: String {
        if isProtected {
            return "系统保护应用默认保留"
        }
        if isDefaultExcluded {
            return "默认不退出。右键可移除默认不退出"
        }
        return isCloseTarget ? "会在一键关闭时退出" : "已从关闭清单移除"
    }
}

private enum AppStatus {
    case running
    case added
    case protected
    case defaultExcluded
    case closing
    case closed
    case failed

    var title: String {
        switch self {
        case .running:
            return "运行中"
        case .added:
            return "已添加"
        case .protected:
            return "保留"
        case .defaultExcluded:
            return "默认不退出"
        case .closing:
            return "关闭中"
        case .closed:
            return "已关闭"
        case .failed:
            return "未响应"
        }
    }

    var dotColor: Color {
        switch self {
        case .running, .added:
            return Color(red: 0.24, green: 0.72, blue: 0.51)
        case .protected, .defaultExcluded:
            return .secondary.opacity(0.55)
        case .closing:
            return .blue
        case .closed:
            return .green
        case .failed:
            return .orange
        }
    }

    var textColor: Color {
        switch self {
        case .running, .added, .closing:
            return .primary
        case .protected, .defaultExcluded:
            return .secondary
        case .closed:
            return .green
        case .failed:
            return .orange
        }
    }

    var sortRank: Int {
        switch self {
        case .running:
            return 0
        case .added:
            return 1
        case .closing:
            return 2
        case .failed:
            return 3
        case .closed:
            return 4
        case .defaultExcluded:
            return 5
        case .protected:
            return 6
        }
    }
}

private enum MemoryFormatter {
    static func string(from bytes: UInt64) -> String {
        if bytes == 0 {
            return "-"
        }

        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }
}

private struct AppCommandError: LocalizedError {
    let message: String

    var isUserCancelled: Bool {
        message.contains("(-128)") || message.localizedCaseInsensitiveContains("用户已取消") || message.localizedCaseInsensitiveContains("User canceled")
    }

    var errorDescription: String? {
        message.isEmpty ? "命令执行失败。" : message
    }
}
