# 技术规范 — ClipboardManager

## 技术栈

| 项目 | 选型 |
|------|------|
| 编程语言 | Swift 6.3 |
| UI 框架 | SwiftUI |
| AppKit 集成 | NSApplication, NSPasteboard, NSImage |
| 最低系统 | macOS 14.0 (Sonoma) |
| 开发工具 | Xcode 26.5 |
| 数据存储 | JSON 文件 + 文件系统 (PNG) |
| 开机自启 | SMAppService |

## 项目结构

```
ClipboardManager/
├── CLAUDE.md                           # AI 开发指引
├── docs/                               # 项目文档
│   ├── requirements.md                 # 需求文档
│   ├── tech-spec.md                    # 本文档
│   ├── design-spec.md                  # 设计规范
│   ├── architecture.md                 # 架构设计
│   └── execution-plan.md               # 执行计划
├── dev-logs/                            # 每日开发记录
├── ClipboardManager.xcodeproj/                # Xcode 项目
└── ClipboardManager/                          # 源代码
    ├── HistoryClipboardApp.swift        # App 入口
    ├── Info.plist
    ├── ClipboardManager.entitlements
    ├── Assets.xcassets/
    ├── Models/
    │   └── ClipboardItem.swift          # 数据模型
    ├── Services/
    │   ├── ClipboardMonitor.swift       # 剪贴板监听
    │   ├── DataStore.swift              # 数据持久化
    │   └── PasteService.swift           # 粘贴执行
    ├── Views/
    │   ├── MenuBar/MenuBarView.swift    # 菜单栏面板
    │   ├── MainWindow/
    │   │   ├── MainWindowView.swift     # 主窗口
    │   │   ├── ClipboardCard.swift      # 记录卡片
    │   │   └── SearchBar.swift          # 搜索栏
    │   └── Settings/SettingsView.swift  # 设置界面
    └── Utils/
        ├── Color+Hex.swift              # 颜色扩展
        └── DateFormatter+Extensions.swift
```

## 数据流

```
系统剪贴板变化
    │
    ▼
ClipboardMonitor (0.5s 轮询)
    │
    ├── 文字 → DataStore.addText()
    └── 图片 → DataStore.addImage() → 保存 PNG
                    │
                    ▼
              DataStore.items (已排序)
                    │
                    ▼
              SwiftUI View 刷新
```

## 粘贴流程

```
用户点击条目
    │
    ▼
PasteService.paste(item)
    │
    ├── NSPasteboard.general.clearContents()
    ├── NSPasteboard.general.setString() / writeObjects()
    │
    ▼
延迟 0.1s → 模拟 Cmd+V (CGEvent)
```

## 存储方案

- **路径**: `~/Library/Application Support/HistoryClipboard/`
- **元数据**: `history.json` (ClipboardItem 数组的 JSON)
- **图片**: `images/<UUID>.png`
- **配置**: `UserDefaults` 存储 `retentionDays`

## 权限

- 无需沙盒（`com.apple.security.app-sandbox = false`）
- 模拟粘贴需要**辅助功能权限**（用户手动授权）

## 编译目标

- Deployment Target: macOS 14.0
- Architecture: arm64 (Apple Silicon)
- Swift Language Version: 6.0
