# CLAUDE.md — ClipboardManager 项目开发指引

## 项目简介

这是一个运行在 macOS (14.0+) 上的剪贴板历史管理应用，使用 Swift + SwiftUI 开发。自动记录用户的剪贴板历史（文字和图片），支持查看、搜索、粘贴、置顶和设置保留时长。

---

## 文档导航

所有项目标准文档位于 `docs/` 目录：

| 文档 | 路径 | 说明 |
|------|------|------|
| 需求文档 | [docs/requirements.md](docs/requirements.md) | 完整功能和非功能需求 |
| 技术规范 | [docs/tech-spec.md](docs/tech-spec.md) | 技术栈、项目结构、数据流 |
| 设计规范 | [docs/design-spec.md](docs/design-spec.md) | 色彩、排版、组件规范 |
| 架构设计 | [docs/architecture.md](docs/architecture.md) | 模块架构和职责 |
| 执行计划 | [docs/execution-plan.md](docs/execution-plan.md) | 分阶段执行步骤和进度 |

**开发前必读**：
1. 先读 `requirements.md` 了解要做什么
2. 再读 `tech-spec.md` 了解技术方案
3. UI 相关改动前读 `design-spec.md`
4. 大型改动前读 `architecture.md`

---

## 开发日志

每天的开发记录放在 `dev-logs/` 目录，文件命名格式：`YYYY-MM-DD.md`。

每次开发会话结束后，更新当天日志：
- ✅ 完成事项
- 🔧 进行中
- ⏳ 待办事项
- 🐛 遇到的问题

---

## 项目结构速览

```
ClipboardManager/
├── CLAUDE.md                        ← 你在这里
├── docs/                            ← 项目文档（不可修改）
│   ├── requirements.md
│   ├── tech-spec.md
│   ├── design-spec.md
│   ├── architecture.md
│   └── execution-plan.md
├── dev-logs/                         ← 每日记录
├── ClipboardManager.xcodeproj/             ← Xcode 项目
└── ClipboardManager/                       ← 源代码
    ├── HistoryClipboardApp.swift
    ├── Info.plist
    ├── ClipboardManager.entitlements
    ├── Assets.xcassets/
    ├── Models/
    ├── Services/
    ├── Views/
    └── Utils/
```

## 编译和运行

```bash
# 编译
xcodebuild -project "ClipboardManager.xcodeproj" -scheme "ClipboardManager" build

# 运行（从命令行）
open "ClipboardManager.xcodeproj"
# 然后在 Xcode 中 Cmd+R

# 或直接运行编译产物
open build/Release/ClipboardManager.app
```

## 代码规范

- **语言**: Swift 6
- **UI**: SwiftUI，不混用 UIKit
- **命名**: 驼峰命名，类型大写开头，变量小写开头
- **注释**: 中文注释，用 `// MARK: -` 分隔代码段
- **颜色**: 使用 `Color(hex: "...")` 扩展，禁止硬编码
- **数据流**: `@Published` + `@ObservedObject` 模式
- **文件组织**: 每个类/结构体一个文件

## 注意事项

- 剪贴板监听使用 Timer 轮询（0.5s），不要用 RunLoop observer（不可靠）
- 图片存储为 PNG，不要用 HEIC（兼容性）
- 粘贴功能需要辅助功能权限，首次使用需引导用户授权
- 数据实时写入磁盘，不要只在 deinit 时保存
- 过期清理在启动时和记录新条目时触发
- `LSUIElement = true` 确保应用不出现在 Dock（仅菜单栏）
