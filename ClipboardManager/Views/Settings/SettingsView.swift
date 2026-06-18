import SwiftUI

// MARK: - 设置窗口 · Settings (Liquid Glass)

struct SettingsView: View {
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDays: Int
    @State private var launchAtLogin: Bool

    private static let launchAgentURL = URL(
        fileURLWithPath: NSHomeDirectory()
    ).appendingPathComponent("Library/LaunchAgents/com.historyclipboard.plist")

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        _selectedDays = State(initialValue: dataStore.retentionDays)
        _launchAtLogin = State(initialValue: FileManager.default.fileExists(atPath: Self.launchAgentURL.path))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 4, y: 2)
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "5BA4C9"))
                }
                Text(localization.loc("settings.title"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            glassDivider

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
                                                .fill(pillBackgroundColor(isSelected: selectedDays == days))
                                                .shadow(
                                                    color: pillShadowColor(isSelected: selectedDays == days),
                                                    radius: selectedDays == days ? 6 : 3,
                                                    y: 2
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    pillStrokeColor(isSelected: selectedDays == days),
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
                    settingsSection(
                        icon: "info.circle",
                        title: localization.loc("settings.storage.title"),
                        description: nil
                    ) {
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
            }
        }
        .frame(width: 420, height: 520)
        .background(
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [Color(hex: "2C2C30"), Color(hex: "26262A"), Color(hex: "28282C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [Color(hex: "F8FBFD"), Color(hex: "F0F6FA"), Color(hex: "F4F8FB")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                Rectangle().fill(.regularMaterial)
            }
        )
    }

    private func pillBackgroundColor(isSelected: Bool) -> Color {
        if isSelected {
            return Color(hex: "5BA4C9").opacity(0.85)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.55)
    }

    private func pillShadowColor(isSelected: Bool) -> Color {
        if isSelected {
            return Color(hex: "5BA4C9").opacity(0.2)
        }
        return Color.black.opacity(colorScheme == .dark ? 0 : 0.02)
    }

    private func pillStrokeColor(isSelected: Bool) -> Color {
        if isSelected {
            return Color.white.opacity(0.4)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.5)
    }

    // MARK: - 分割线

    private var glassDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.35))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }

    // MARK: - 设置区块

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
            .padding(.horizontal, 20)

            if let description = description {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 20)
            }

            content()
                .padding(.horizontal, 20)
        }
    }

    // MARK: - 开机自启

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
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

// MARK: - 信息行 · Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.7))
        }
    }
}
