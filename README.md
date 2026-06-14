# 📋 历史粘贴板

macOS 菜单栏剪贴板历史管理工具，自动记录文字和图片复制内容。

## 功能

- **自动记录**：后台监听剪贴板，文字和图片自动保存
- **快速粘贴**：点击历史记录即可复制，Cmd+V 粘贴到任意位置
- **关键词搜索**：输入关键词快速定位历史内容
- **置顶**：重要内容置顶，不受过期清理影响
- **保留时长**：1/3/5 天自动清理，节省空间
- **菜单栏运行**：安静驻留在菜单栏，无 Dock 图标，低打扰

## 系统要求

- macOS 14.0+
- Apple Silicon (M 系列芯片)

## 安装

```bash
# 1. 克隆仓库
git clone https://github.com/daniel30n44/-.git
cd 历史粘贴板

# 2. Xcode 打开项目
open 历史粘贴板.xcodeproj

# 3. Cmd+R 编译运行
```

> 首次运行会在菜单栏出现 📋 图标。关闭 Xcode 后如需继续使用，需将编译的 .app 复制到 `~/Applications/` 并设置开机自启。

## 技术栈

| 项目 | 技术 |
|------|------|
| 语言 | Swift 6 |
| UI | SwiftUI |
| 数据存储 | JSON + 本地文件 |
| 图片格式 | PNG |
| 最低系统 | macOS 14.0 |

## 项目结构

```
历史粘贴板/
├── Models/           # 数据模型
│   └── ClipboardItem.swift
├── Services/         # 业务逻辑
│   ├── ClipboardMonitor.swift   # 剪贴板监听
│   ├── DataStore.swift          # 数据持久化
│   └── PasteService.swift       # 粘贴服务
├── Views/            # 界面
│   ├── MenuBar/      # 菜单栏面板
│   ├── MainWindow/   # 主窗口
│   └── Settings/     # 设置
├── Utils/            # 工具扩展
│   ├── Color+Hex.swift
│   └── DateFormatter+Extensions.swift
└── docs/             # 项目文档
```

## 许可证

MIT License
