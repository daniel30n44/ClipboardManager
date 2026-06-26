import SwiftUI

// MARK: - 面板视图类型

enum PanelView: Equatable {
    case home
    case settings
}

// MARK: - 菜单栏下拉面板 · Menu Bar Popup（原地切换版）

struct MenuBarView: View {
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText: String = ""
    @State private var currentPanel: PanelView = .home

    /// 精确捕获当前视图所属的 NSWindow
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
            initialValue: FileManager.default.fileExists(atPath: Self.launchAgentURL.path)
        )
    }

    // MARK: - 数据

    private var threeDaysAgo: Date {
        guard let date = Calendar.current.date(byAdding: .day, value: -3, to: Date()) else {
            return Date().addingTimeInterval(-259200)
        }
        return Calendar.current.startOfDay(for: date)
    }

    /// 去空白后的搜索文本（避免多处重复 trim）
    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    /// 3 天内 + 搜索，排序：置顶优先 + 时间降序
    private var filteredItems: [ClipboardItem] {
        let recent = dataStore.items.filter { $0.timestamp >= threeDaysAgo }
        let sorted = recent.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.timestamp > b.timestamp
        }
        guard !trimmedSearchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.type == .text && ($0.textContent?.localizedCaseInsensitiveContains(trimmedSearchText) ?? false)
        }
    }

    /// 当前面板对应的窗口尺寸
    private var panelSize: (width: CGFloat, height: CGFloat) {
        switch currentPanel {
        case .home:     return (410, 500)
        case .settings: return (420, 520)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                searchBarAndDivider
                contentSwitch
                footerView
            }
            .frame(width: panelSize.width)
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(WindowCaptureView(window: $popupWindow))
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

    // MARK: - 顶部标题栏

    private var headerView: some View {
        HStack(spacing: 8) {
            // 返回按钮（设置页时显示）
            if currentPanel == .settings {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPanel = .home
                    }
                }) {
                    IconCircle(
                        systemName: "chevron.left",
                        size: 26, iconSize: 11, iconWeight: .semibold,
                        lightOpacity: 0.7, darkOpacity: 0.12,
                        shadowRadius: 3, shadowY: 1
                    )
                }
                .buttonStyle(.plain)
            }

            // 面板图标
            IconCircle(
                systemName: panelIcon,
                size: 28, iconSize: 12,
                lightOpacity: 0.75, darkOpacity: 0.12,
                shadowRadius: 4, shadowY: 2
            )

            Text(panelTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))

            if currentPanel == .home {
                Text(localization.loc("nav.recent_3days"))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Spacer()

            // 右侧按钮（仅主页显示）
            if currentPanel == .home {
                IconCircleButton(
                    systemName: "xmark",
                    size: 26, iconSize: 10, iconWeight: .semibold,
                    foregroundColor: .secondary.opacity(0.65),
                    lightOpacity: 0.6, darkOpacity: 0.1,
                    shadowRadius: 3, shadowY: 1
                ) {
                    NSApplication.shared.terminate(nil)
                }
                .help("退出应用")

                IconCircleButton(
                    systemName: "gearshape",
                    size: 26, iconSize: 11,
                    foregroundColor: .secondary.opacity(0.65),
                    lightOpacity: 0.6, darkOpacity: 0.1,
                    shadowRadius: 3, shadowY: 1
                ) {
                    selectedDays = dataStore.retentionDays
                    launchAtLogin = FileManager.default.fileExists(atPath: Self.launchAgentURL.path)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPanel = .settings
                    }
                }
                .help(localization.loc("settings.title"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var panelTitle: String {
        switch currentPanel {
        case .home:     return localization.loc("nav.home")
        case .settings: return localization.loc("settings.title")
        }
    }

    private var panelIcon: String {
        switch currentPanel {
        case .home:     return "clipboard"
        case .settings: return "gearshape"
        }
    }

    // MARK: - 搜索栏（仅主页显示）

    @ViewBuilder
    private var searchBarAndDivider: some View {
        if currentPanel != .settings {
            SearchBar(text: $searchText, placeholder: localization.loc("nav.search_placeholder"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            GlassDivider(horizontalPadding: 12)
        }
    }

    // MARK: - 内容区

    @ViewBuilder
    private var contentSwitch: some View {
        switch currentPanel {
        case .home:
            homeListView
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

    // MARK: - 主页列表

    @ViewBuilder
    private var homeListView: some View {
        if filteredItems.isEmpty {
            emptyStateView
                .frame(maxHeight: 420)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if !trimmedSearchText.isEmpty {
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
                                NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
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
            .frame(maxHeight: 420)
        }
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer()
            IconCircle(
                systemName: searchText.isEmpty ? "tray" : "magnifyingglass",
                size: 56, iconSize: 24, iconWeight: .light,
                foregroundColor: .secondary.opacity(0.45),
                lightOpacity: 0.5, darkOpacity: 0.08,
                shadowRadius: 6, shadowY: 3
            )

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
                // 语言选择
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

                GlassDivider(horizontalPadding: 12)

                // 保留天数
                settingsSection(
                    icon: "clock.arrow.circlepath",
                    title: localization.loc("settings.retention.title"),
                    description: localization.loc("settings.retention.description")
                ) {
                    HStack(spacing: 8) {
                        ForEach([1, 3, 5], id: \.self) { days in
                            PillSelectButton(
                                title: localization.loc("settings.retention.\(days)day"),
                                isSelected: selectedDays == days
                            ) {
                                selectedDays = days
                                dataStore.retentionDays = days
                            }
                        }
                    }
                }

                GlassDivider(horizontalPadding: 12)

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

                GlassDivider(horizontalPadding: 12)

                // 存储信息
                settingsSection(
                    icon: "info.circle",
                    title: localization.loc("settings.storage.title"),
                    description: nil
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow(label: localization.loc("settings.storage.total"),  value: localization.loc("settings.storage.unit", dataStore.items.count))
                        InfoRow(label: localization.loc("settings.storage.text"),   value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.type == .text }.count))
                        InfoRow(label: localization.loc("settings.storage.image"),  value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.type == .image }.count))
                        InfoRow(label: localization.loc("settings.storage.pinned"), value: localization.loc("settings.storage.unit", dataStore.items.filter { $0.isPinned }.count))
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
                Text(localization.loc("footer.total", dataStore.items.count))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.white.opacity(0.35))
        }
    }

    // MARK: - 动态调整窗口尺寸（防抖 + 中心锚点）

    private func scheduleResize(width: CGFloat, height: CGFloat) {
        pendingResize?.cancel()

        let workItem = DispatchWorkItem { [self] in
            performResize(width: width, height: height)
        }
        pendingResize = workItem

        let delay: Double = (popupWindow == nil) ? 0.15 : 0.03
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func performResize(width: CGFloat, height: CGFloat) {
        guard let window = popupWindow else { return }

        let current = window.frame
        guard abs(current.width - width) > 1.5 ||
              abs(current.height - height) > 1.5 else { return }

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
        launchAtLogin = FileManager.default.fileExists(atPath: Self.launchAgentURL.path)
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
            try plistContent.write(to: Self.launchAgentURL, atomically: true, encoding: .utf8)
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
        colorScheme == .dark ? .clear : Color.black.opacity(isHovered ? 0.06 : 0.025)
    }

    private func actionBtnBg(_ highlight: Bool = false) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(highlight ? 0.12 : 0.1)
            : Color.white.opacity(highlight ? 0.65 : 0.55)
    }

    private func actionBtnStroke(_ highlight: Bool = false) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(highlight ? 0.1 : 0.08)
            : Color.white.opacity(0.5)
    }

    private var actionBtnShadow: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.03)
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

                // 右侧操作区：固定宽度，仅透明度动画
                HStack(spacing: 4) {
                    // 置顶标记
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "5BA4C9").opacity(0.7))
                        .opacity(item.isPinned ? 1 : 0)

                    // 置顶/取消置顶按钮
                    actionButton(
                        icon: item.isPinned ? "pin.slash" : "pin",
                        highlight: true,
                        help: item.isPinned ? localization.loc("card.unpin") : localization.loc("card.pin"),
                        action: onTogglePin
                    )

                    // 删除按钮
                    actionButton(
                        icon: "trash",
                        highlight: false,
                        help: localization.loc("card.delete"),
                        action: onDelete
                    )

                    // 粘贴提示箭头
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
            .shadow(color: cardShadow, radius: isHovered ? 8 : 4, y: isHovered ? 3 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - 操作按钮（悬停时淡入）

    private func actionButton(icon: String, highlight: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.secondary.opacity(highlight ? 0.65 : 0.55))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(actionBtnBg(highlight))
                        .shadow(color: actionBtnShadow, radius: 2, y: 1)
                )
                .overlay(
                    Circle()
                        .stroke(actionBtnStroke(highlight), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .help(help)
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
        IconCircle(
            systemName: systemName,
            size: 36, iconSize: 14, iconWeight: .light,
            foregroundColor: Color(hex: "7EC8E3").opacity(0.7),
            lightOpacity: 0.55, darkOpacity: 0.08,
            shadowRadius: 2, shadowY: 1
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

// MARK: - 窗口捕获器（精准定位 MenuBarExtra 的 NSWindow）

struct WindowCaptureView: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if window == nil, let w = nsView.window {
            DispatchQueue.main.async {
                self.window = w
            }
        }
    }
}
