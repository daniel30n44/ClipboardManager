# 📋 历史粘贴板 · History Clipboard

macOS 菜单栏剪贴板历史管理工具，自动记录文字和图片复制内容。<br>
A macOS menu bar clipboard history manager — auto-records text and images you copy.

---

## 功能 · Features

| | 中文 | English |
|------|------|------|
| 📋 | **自动记录**：后台监听剪贴板，文字和图片自动保存 | **Auto-record**: Monitors clipboard in background, auto-saves text & images |
| 📌 | **快速粘贴**：点击历史记录即可复制，Cmd+V 粘贴到任意位置 | **Quick paste**: Click to copy, then Cmd+V to paste anywhere |
| 🔍 | **关键词搜索**：输入关键词快速定位历史内容 | **Keyword search**: Type to filter history instantly |
| 📍 | **置顶**：重要内容置顶，不受过期清理影响 | **Pin**: Important items stay forever, immune to auto-cleanup |
| ⏳ | **保留时长**：1/3/5 天自动清理，节省空间 | **Retention**: Auto-clean after 1/3/5 days to save space |
| 🍃 | **菜单栏运行**：安静驻留在菜单栏，无 Dock 图标，低打扰 | **Menu bar only**: Stays in menu bar, no Dock icon, low footprint |

## 系统要求 · Requirements

- macOS 14.0+
- Apple Silicon / Intel (Universal)

## 安装 · Installation

```bash
# 1. 克隆仓库 / Clone
git clone https://github.com/daniel30n44/ClipboardManager.git
cd 历史粘贴板

# 2. Xcode 打开项目 / Open in Xcode
open 历史粘贴板.xcodeproj

# 3. Cmd+R 编译运行 / Build & run
```

> 首次运行菜单栏会出现 📋 图标。如需独立于 Xcode 运行，将编译的 .app 复制到 `~/Applications/` 并创建 LaunchAgent 即可开机自启。<br>
> On first run, a 📋 icon appears in the menu bar. To run independently of Xcode, copy the built .app to `~/Applications/` and set up a LaunchAgent for auto-start on login.

## 技术栈 · Tech Stack

| 项目 · Item | 技术 · Tech |
|-------------|-------------|
| 语言 · Language | Swift 6 |
| UI | SwiftUI |
| 数据存储 · Storage | JSON + local file system |
| 图片格式 · Image | PNG |
| 最低系统 · Min OS | macOS 14.0 |

## 项目结构 · Project Structure

```
历史粘贴板/
├── Models/           # 数据模型 · Data models
│   └── ClipboardItem.swift
├── Services/         # 业务逻辑 · Business logic
│   ├── ClipboardMonitor.swift   # 剪贴板监听 · Clipboard polling
│   ├── DataStore.swift          # 数据持久化 · Persistence
│   └── PasteService.swift       # 粘贴服务 · Paste operations
├── Views/            # 界面 · UI
│   ├── MenuBar/      # 菜单栏面板 · Menu bar popup
│   ├── MainWindow/   # 主窗口 · Main window
│   └── Settings/     # 设置 · Settings
├── Utils/            # 工具扩展 · Utilities
│   ├── Color+Hex.swift
│   └── DateFormatter+Extensions.swift
└── docs/             # 项目文档 · Documentation
```

## 截图 · Screenshots

| 菜单栏面板 · Menu Bar | 主窗口 · Main Window |
|:---:|:---:|
| 点击菜单栏 📋 图标 · Click the 📋 icon | 搜索 + 完整列表 · Search + full list |

## 许可证 · License

MIT License
