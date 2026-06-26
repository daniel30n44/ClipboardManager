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

    // MARK: - 计算属性

    /// 三天前的零点
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

    /// 过滤：3 天内 + 搜索，排序：置顶优先 + 时间降序
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView
            GlassDivider()
            searchBarView
            GlassDivider()
            contentArea
        }
        .frame(minWidth: 440, minHeight: 520)
        .background(
            AppGradientBackground(
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
                lightColors: [Color(hex: "F8FBFD"), Color(hex: "F2F8FB"), Color(hex: "F5F9FC")]
            )
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
            IconCircle(systemName: "clock.arrow.circlepath", size: 32, iconSize: 14, shadowRadius: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.loc("main.title"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
                Text(localization.loc("main.subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            // 退出按钮
            IconCircleButton(
                systemName: "xmark",
                size: 28, iconSize: 12,
                foregroundColor: .secondary.opacity(0.7),
                shadowRadius: 0
            ) {
                NSApplication.shared.terminate(nil)
            }
            .help("退出应用")

            // 设置按钮
            if #available(macOS 14.0, *) {
                SettingsLink {
                    IconCircle(
                        systemName: "gearshape",
                        size: 28, iconSize: 13, iconWeight: .light,
                        foregroundColor: .secondary.opacity(0.7),
                        lightOpacity: 0.55, darkOpacity: 0.1,
                        shadowRadius: 0
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    IconCircle(
                        systemName: "gearshape",
                        size: 28, iconSize: 13, iconWeight: .light,
                        foregroundColor: .secondary.opacity(0.7),
                        lightOpacity: 0.55, darkOpacity: 0.1,
                        shadowRadius: 0
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 搜索栏

    private var searchBarView: some View {
        SearchBar(text: $searchText, placeholder: localization.loc("nav.search_placeholder"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    // MARK: - 内容区

    @ViewBuilder
    private var contentArea: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else {
            listView
        }
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            IconCircle(
                systemName: searchText.isEmpty ? "tray" : "magnifyingglass",
                size: 72, iconSize: 28, iconWeight: .light,
                foregroundColor: .secondary.opacity(0.45),
                lightOpacity: 0.5, darkOpacity: 0.08,
                shadowRadius: 8, shadowY: 4
            )

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
                // 搜索结果提示
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
