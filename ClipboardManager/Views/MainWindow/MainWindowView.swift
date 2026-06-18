import SwiftUI

// MARK: - 历史记录主窗口 · History Main Window (Liquid Glass)

struct MainWindowView: View {
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""
    @State private var selectedItem: ClipboardItem?
    @State private var showDeleteAlert = false
    @State private var itemToDelete: ClipboardItem?

    /// 三天前的零点
    private var threeDaysAgo: Date {
        guard let date = Calendar.current.date(byAdding: .day, value: -3, to: Date()) else {
            return Date().addingTimeInterval(-259200)
        }
        return Calendar.current.startOfDay(for: date)
    }

    /// 过滤：3 天内 + 搜索，排序：置顶优先 + 时间降序
    private var filteredItems: [ClipboardItem] {
        // 仅保留 3 天内的记录
        let recent = dataStore.items.filter { $0.timestamp >= threeDaysAgo }

        let sorted = recent.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.timestamp > b.timestamp
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return sorted }

        return sorted.filter { item in
            if item.type == .text {
                return item.textContent?.localizedCaseInsensitiveContains(trimmed) ?? false
            }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            glassDivider
            searchBarView
            glassDivider

            if filteredItems.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        .frame(minWidth: 440, minHeight: 520)
        .background(
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [Color(hex: "2C2C30"), Color(hex: "26262A"), Color(hex: "28282C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [Color(hex: "F8FBFD"), Color(hex: "F2F8FB"), Color(hex: "F5F9FC")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                Rectangle()
                    .fill(.regularMaterial)
            }
        )
        .alert(localization.loc("main.delete_alert.title"), isPresented: $showDeleteAlert) {
            Button(localization.loc("main.delete_alert.cancel"), role: .cancel) {}
            Button(localization.loc("main.delete_alert.confirm"), role: .destructive) {
                if let item = itemToDelete {
                    withAnimation { dataStore.delete(item) }
                }
            }
        } message: {
            Text(localization.loc("main.delete_alert.message"))
        }
    }

    // MARK: - 顶部标题栏

    private var headerView: some View {
        HStack(spacing: 10) {
            // 图标
            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.65))
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 5, y: 2)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "5BA4C9"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.loc("main.title"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
                Text(localization.loc("main.subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            // 设置按钮
            if #available(macOS 14.0, *) {
                SettingsLink {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.white.opacity(0.55))
                            .frame(width: 28, height: 28)
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.white.opacity(0.55))
                            .frame(width: 28, height: 28)
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 玻璃分割线

    private var glassDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.4))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    // MARK: - 搜索栏

    private var searchBarView: some View {
        SearchBar(text: $searchText, placeholder: localization.loc("nav.search_placeholder"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.5))
                    .frame(width: 72, height: 72)
                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.secondary.opacity(0.45))
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 8, y: 4)

            Text(searchText.isEmpty
                ? localization.loc("main.empty.title")
                : localization.loc("main.empty.search_title"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))

            Text(searchText.isEmpty
                ? localization.loc("main.empty.subtitle")
                : localization.loc("main.empty.search_subtitle"))
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.4))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 列表视图

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // 结果提示
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
                    ClipboardCard(
                        item: item,
                        isSelected: selectedItem?.id == item.id,
                        onTap: {
                            selectedItem = item
                            PasteService.paste(item)
                        },
                        onTogglePin: {
                            withAnimation { dataStore.togglePin(item) }
                        },
                        onDelete: {
                            itemToDelete = item
                            showDeleteAlert = true
                        }
                    )
                    .environmentObject(localization)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
