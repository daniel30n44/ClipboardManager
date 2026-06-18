import SwiftUI

// MARK: - 面板视图类型

enum PanelView: Equatable {
    case home          // 主页：3 天内 + 搜索
    case fullHistory   // 全历史记录
    case settings      // 设置
}

// MARK: - 菜单栏下拉面板 · Menu Bar Popup（原地切换版）

struct MenuBarView: View {
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText: String = ""
    @State private var currentPanel: PanelView = .home

    /// 精确捕获当前视图所属的 NSWindow（不再靠 className 猜测）
    @State private var popupWindow: NSWindow? = nil
    /// 防抖：避免动画期间重复 resize
    @State private var pendingResize: DispatchWorkItem? = nil

    // 设置页的临时状态
    @State private var selectedDays: Int
    @State private var launchAtLogin: Bool

    private static let launchAgentURL = URL(
        fileURLWithPath: NSHomeDirectory()
    ).appendingPathComponent("Library/LaunchAgents/com.historyclipboard.plist")

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        _selectedDays = State(initialValue: dataStore.retentionDays)
        _launchAtLogin = State(
            initialValue: FileManager.default.fileExists(
                atPath: Self.launchAgentURL.path
            )
        )
    }

    // MARK: - 数据

    private var threeDaysAgo: Date {
        guard let date = Calendar.current.date(byAdding: .day, value: -3, to: Date()) else {
            return Date().addingTimeInterval(-259200)
        }
        return Calendar.current.startOfDay(for: date)
    }

    private var filteredItems: [ClipboardItem] {
        let base = currentPanel == .fullHistory
            ? dataStore.items
            : dataStore.items.filter { $0.timestamp >= threeDaysAgo }

        let sorted = base.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.timestamp > b.timestamp
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return sorted }

        return sorted.filter {
            $0.type == .text && ($0.textContent?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    /// 当前面板对应的窗口尺寸
    private var panelSize: (width: CGFloat, height: CGFloat) {
        switch currentPanel {
        case .home:        return (410, 500)
        case .fullHistory: return (410, 500)
        case .settings:    return (420, 520)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                headerView
                searchBarAndDivider
                contentSwitch
                footerView
            }
            .frame(width: panelSize.width)
        }
        .frame(width: panelSize.width, height: panelSize.height)
        // 精准捕获 NSWindow（不再靠 className 猜）
        .background(
            WindowCaptureView(window: $popupWindow)
        )
        .onChange(of: currentPanel) { _, _ in
            scheduleResize(width: panelSize.width, height: panelSize.height)
        }
        .onAppear {
            scheduleResize(width: panelSize.width, height: panelSize.height)
        }
        // 每次打开面板时，强制回到首页
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            guard let window = notification.object as? NSWindow,
                  window == popupWindow else { return }
            if currentPanel != .home {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentPanel = .home
                }
            }
            searchText = ""
        }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            if colorScheme == .dark {
                // 深色模式：深邃半透明炭灰 + 强模糊，匹配 Apple Control Center 风格
                LinearGradient(
                    colors: [
                        Color(hex: "2C2C30"),
                        Color(hex: "26262A"),
                        Color(hex: "28282C")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Rectangle()
                    .fill(.regularMaterial)
            } else {
                // 浅色模式：更白更亮的活力渐变 + 强模糊
                LinearGradient(
                    colors: [
                        Color(hex: "F8FBFD"),
                        Color(hex: "F0F6FA"),
                        Color(hex: "F4F8FB")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Rectangle()
                    .fill(.regularMaterial)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 顶部标题栏（根据当前面板切换）

    private var headerView: some View {
        HStack(spacing: 8) {
            // 返回按钮（非主页时显示）
            if currentPanel != .home {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPanel = .home
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.12)
                                : Color.white.opacity(0.7))
                            .frame(width: 26, height: 26)
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 3, y: 1)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "5BA4C9"))
                    }
                }
                .buttonStyle(.plain)
            }

            // 图标
            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 4, y: 2)

                Image(systemName: panelIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "5BA4C9"))
            }

            Text(panelTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))

            if currentPanel == .home {
                Text(localization.loc("nav.recent_3days"))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Spacer()

            // 右侧按钮：主页显示齿轮
            if currentPanel == .home {
                Button(action: {
                    selectedDays = dataStore.retentionDays
                    launchAtLogin = FileManager.default.fileExists(
                        atPath: Self.launchAgentURL.path
                    )
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPanel = .settings
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.white.opacity(0.6))
                            .frame(width: 26, height: 26)
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 3, y: 1)
                        Image(systemName: "gearshape")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.65))
                    }
                }
                .buttonStyle(.plain)
                .help(localization.loc("settings.title"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var panelTitle: String {
        switch currentPanel {
        case .home:        return localization.loc("nav.home")
        case .fullHistory: return localization.loc("nav.all_records")
        case .settings:    return localization.loc("settings.title")
        }
    }

    private var panelIcon: String {
        switch currentPanel {
        case .home:        return "clipboard"
        case .fullHistory: return "clock.arrow.circlepath"
        case .settings:    return "gearshape"
        }
    }

    // MARK: - 搜索栏（仅主页 + 全历史显示）

    @ViewBuilder
    private var searchBarAndDivider: some View {
        if currentPanel != .settings {
            SearchBar(text: $searchText, placeholder: localization.loc("nav.search_placeholder"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            glassDivider
        }
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.4))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    // MARK: - 内容区（根据面板切换）

    private func pillBgColor(_ isSelected: Bool) -> Color {
        if isSelected { return Color(hex: "5BA4C9").opacity(0.85) }
        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.55)
    }

    private func pillShadowColor(_ isSelected: Bool) -> Color {
        if isSelected { return Color(hex: "5BA4C9").opacity(0.2) }
        return colorScheme == .dark ? .clear : Color.black.opacity(0.02)
    }

    private func pillStrokeColor(_ isSelected: Bool) -> Color {
        if isSelected { return Color.white.opacity(0.4) }
        return colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.5)
    }

    @ViewBuilder
    private var contentSwitch: some View {
        switch currentPanel {
        case .home:
            itemListView(maxHeight: 420)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .fullHistory:
            itemListView(maxHeight: 420)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .settings:
            settingsContentView
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }

    // MARK: - 列表视图（主页 / 全历史共用）

    @ViewBuilder
    private func itemListView(maxHeight: CGFloat) -> some View {
        if filteredItems.isEmpty {
            emptyStateView
                .frame(maxHeight: maxHeight)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack {
                            Text(localization.loc("main.search_results", filteredItems.count))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }

                    ForEach(filteredItems) { item in
                        MenuBarItemRow(
                            item: item,
                            onPaste: {
                                PasteService.paste(item)
                                NSApp.sendAction(
                                    #selector(NSMenu.cancelTracking),
                                    to: nil, from: nil
                                )
                            },
                            onTogglePin: {
                                withAnimation { dataStore.togglePin(item) }
                            },
                            onDelete: {
                                withAnimation { dataStore.delete(item) }
                            }
                        )
                        .environmentObject(localization)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .frame(maxHeight: maxHeight)
        }
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer()
            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.5))
                    .frame(width: 56, height: 56)
                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.secondary.opacity(0.45))
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 6, y: 3)

            Text(searchText.isEmpty
                ? localization.loc("empty.no_records")
                : localization.loc("empty.no_matches"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 6)

            Text(searchText.isEmpty
                ? localization.loc("empty.hint")
                : localization.loc("empty.try_other"))
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - 设置内容视图（内嵌版）

    private var settingsContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 语言选择（Picker 形式，支持任意数量语言）
                settingsSection(
                    icon: "globe",
                    title: localization.loc("settings.language.title"),
                    description: localization.loc("settings.language.description")
                ) {
                    Picker("", selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                glassDivider

                // 保留天数
                settingsSection(
                    icon: "clock.arrow.circlepath",
                    title: localization.loc("settings.retention.title"),
                    description: localization.loc("settings.retention.description")
                ) {
                    HStack(spacing: 8) {
                        ForEach([1, 3, 5], id: \.self) { days in
                            Button(action: {
                                selectedDays = days
                                dataStore.retentionDays = days
                            }) {
                                Text(localization.loc("settings.retention.\(days)day"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(
                                        selectedDays == days
                                            ? .white.opacity(0.95)
                                            : Color(hex: "5BA4C9").opacity(0.8)
                                    )
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(pillBgColor(selectedDays == days))
                                            .shadow(
                                                color: pillShadowColor(selectedDays == days),
                                                radius: selectedDays == days ? 6 : 3,
                                                y: 2
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                pillStrokeColor(selectedDays == days),
                                                lineWidth: 0.8
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                glassDivider

                // 开机自启
                settingsSection(
                    icon: "power",
                    title: localization.loc("settings.launch.title"),
                    description: localization.loc("settings.launch.description")
                ) {
                    HStack {
                        Text(launchAtLogin
                            ? localization.loc("settings.launch.enabled")
                            : localization.loc("settings.launch.disabled"))
                            .font(.system(size: 13))
                            .foregroundColor(
                                launchAtLogin
                                    ? Color(hex: "4CAF50").opacity(0.85)
                                    : .secondary.opacity(0.6)
                            )
                        Spacer()
                        Toggle(isOn: $launchAtLogin) {}
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { _, newValue in
                                toggleLaunchAtLogin(newValue)
                            }
                    }
                    .padding(.horizontal, 4)
                }

                glassDivider

                // 存储信息
                settingsSection(icon: "info.circle", title: localization.loc("settings.storage.title"), description: nil) {
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow(
                            label: localization.loc("settings.storage.total"),
                            value: localization.loc("settings.storage.unit", dataStore.items.count)
                        )
                        InfoRow(
                            label: localization.loc("settings.storage.text"),
                            value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.type == .text }.count)
                        )
                        InfoRow(
                            label: localization.loc("settings.storage.image"),
                            value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.type == .image }.count)
                        )
                        InfoRow(
                            label: localization.loc("settings.storage.pinned"),
                            value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.isPinned }.count)
                        )
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }

    private func settingsSection<Content: View>(
        icon: String,
        title: String,
        description: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "5BA4C9").opacity(0.7))
                    .font(.system(size: 14, weight: .light))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.8))
            }

            if let desc = description {
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            content()
        }
    }

    // MARK: - 底部状态栏

    @ViewBuilder
    private var footerView: some View {
        if currentPanel != .settings {
            HStack(spacing: 0) {
                Text(localization.loc("footer.retention", dataStore.retentionDays))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))

                Spacer()

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(localization.loc("footer.total", dataStore.items.count))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentPanel = currentPanel == .fullHistory
                                ? .home
                                : .fullHistory
                        }
                    }) {
                        Text(currentPanel == .fullHistory
                            ? localization.loc("nav.back_home")
                            : localization.loc("nav.view_all"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "5BA4C9").opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Spacer().frame(width: 8)

                    Text(localization.loc("footer.total", dataStore.items.count))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.white.opacity(0.35))
        }
    }

    // MARK: - 动态调整窗口尺寸（防抖 + 中心锚点）

    /// 以窗口顶部中心为锚点调整尺寸（MenuBarExtra 的 popover 居中于菜单栏图标下方），
    /// 避免在屏幕边缘时窗口跳到另一侧。
    private func scheduleResize(width: CGFloat, height: CGFloat) {
        // 取消上一次待执行的 resize，防止动画堆积
        pendingResize?.cancel()

        let workItem = DispatchWorkItem { [self] in
            performResize(width: width, height: height)
        }
        pendingResize = workItem

        // 首次 onAppear 要给窗口布局留够时间
        let delay: Double = (popupWindow == nil) ? 0.15 : 0.03
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func performResize(width: CGFloat, height: CGFloat) {
        guard let window = popupWindow else { return }

        let current = window.frame

        // 尺寸没变就跳过，避免无谓的动画抖动
        guard abs(current.width - width) > 1.5 ||
              abs(current.height - height) > 1.5 else { return }

        // 锚点：窗口顶部中心固定（菜单栏图标在正上方），仅向下/两侧扩展
        let centerX = current.midX
        let topY = current.maxY

        let newFrame = NSRect(
            x: centerX - width / 2,
            y: topY - height,
            width: width,
            height: height
        )

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            ctx.allowsImplicitAnimation = true
            window.animator().setFrame(newFrame, display: true)
        }
    }

    // MARK: - 开机自启控制

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            createLaunchAgent()
        } else {
            removeLaunchAgent()
        }
        launchAtLogin = FileManager.default.fileExists(
            atPath: Self.launchAgentURL.path
        )
    }

    private func createLaunchAgent() {
        let appPath = Bundle.main.bundlePath
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.historyclipboard</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>\(appPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        do {
            try plistContent.write(
                to: Self.launchAgentURL,
                atomically: true,
                encoding: .utf8
            )
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", Self.launchAgentURL.path]
            try task.run()
            task.waitUntilExit()
        } catch {
            print("创建开机自启失败: \(error.localizedDescription)")
        }
    }

    private func removeLaunchAgent() {
        let unloadTask = Process()
        unloadTask.launchPath = "/bin/launchctl"
        unloadTask.arguments = ["unload", Self.launchAgentURL.path]
        try? unloadTask.run()
        unloadTask.waitUntilExit()
        try? FileManager.default.removeItem(at: Self.launchAgentURL)
    }
}

// MARK: - 单条记录行 · Menu Bar Item Row

struct MenuBarItemRow: View {
    let item: ClipboardItem
    let onPaste: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    // MARK: - 辅助颜色

    private var cardBg: Color {
        colorScheme == .dark
            ? Color.white.opacity(isHovered ? 0.14 : 0.08)
            : Color.white.opacity(isHovered ? 0.8 : 0.55)
    }

    private var cardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(isHovered ? 0.18 : 0.08)
            : Color.white.opacity(isHovered ? 0.9 : 0.4)
    }

    private var cardShadow: Color {
        colorScheme == .dark
            ? Color.clear
            : Color.black.opacity(isHovered ? 0.06 : 0.025)
    }

    private func btnBg(_ highlight: Bool = false) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(highlight ? 0.12 : 0.1)
            : Color.white.opacity(highlight ? 0.65 : 0.55)
    }

    private func btnStroke(_ highlight: Bool = false) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(highlight ? 0.1 : 0.08)
            : Color.white.opacity(0.5)
    }

    private var btnShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.03)
    }

    private var placeholderBg: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.55)
    }

    var body: some View {
        Button(action: onPaste) {
            HStack(spacing: 10) {
                typeIconView
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.previewText)
                        .font(.system(size: 12.5))
                        .lineLimit(2)
                        .foregroundColor(.primary.opacity(0.85))
                        .multilineTextAlignment(.leading)

                    Text(item.timestamp.relativeDescription)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer(minLength: 0)

                // 右侧操作区：固定宽度，仅透明度动画，避免文字换行
                HStack(spacing: 4) {
                    // 置顶标记（始终占位）
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "5BA4C9").opacity(0.7))
                        .opacity(item.isPinned ? 1 : 0)

                    // 置顶按钮（始终占位，仅淡入淡出）
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary.opacity(0.65))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(btnBg(true))
                                    .shadow(color: btnShadow, radius: 2, y: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(btnStroke(true), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                    .help(item.isPinned
                        ? localization.loc("card.unpin")
                        : localization.loc("card.pin"))

                    // 删除按钮（始终占位，仅淡入淡出）
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary.opacity(0.55))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(btnBg(false))
                                    .shadow(color: btnShadow, radius: 2, y: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(btnStroke(false), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                    .help(localization.loc("card.delete"))

                    // 粘贴提示箭头（始终占位）
                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.55))
                        .opacity(isHovered ? 1 : 0)
                }
                .frame(width: 84, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(cardStroke, lineWidth: isHovered ? 1.2 : 0.8)
            )
            .shadow(
                color: cardShadow,
                radius: isHovered ? 8 : 4,
                y: isHovered ? 3 : 1
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - 类型图标

    @ViewBuilder
    private var typeIconView: some View {
        if item.type == .image, let fileName = item.imageFileName {
            let imagesDir = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            .appendingPathComponent("HistoryClipboard/images")
            let fileURL = imagesDir.appendingPathComponent(fileName)

            if let nsImage = NSImage(contentsOf: fileURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            } else {
                iconPlaceholder(systemName: "photo")
            }
        } else {
            iconPlaceholder(systemName: item.type == .image ? "photo" : "doc.text")
        }
    }

    private func iconPlaceholder(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(placeholderBg)
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "7EC8E3").opacity(0.7))
            )
            .shadow(color: btnShadow, radius: 2, y: 1)
    }
}

// MARK: - 窗口捕获器（精准定位 MenuBarExtra 的 NSWindow）

/// 通过 NSViewRepresentable 从视图层级中精准拿到所在窗口，
/// 不再靠 `NSApp.windows` + className 硬编码猜测。
struct WindowCaptureView: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // 视图加入 window 后回调
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // 窗口没变就不更新
        if window == nil, let w = nsView.window {
            DispatchQueue.main.async {
                self.window = w
            }
        }
    }
}
