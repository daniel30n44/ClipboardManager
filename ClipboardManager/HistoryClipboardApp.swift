import SwiftUI
import Darwin

// MARK: - AppDelegate：保持菜单栏应用常驻后台

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableSuddenTermination()
        ProcessInfo.processInfo.disableAutomaticTermination("MenuBarExtra requires persistent process")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}

// MARK: - 调试器检测

/// 仅使用 P_TRACED（内核级标志），不用环境变量（会被子进程继承导致无限循环）
private func isRunningUnderDebugger() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    if sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0,
       (info.kp_proc.p_flag & P_TRACED) != 0 {
        return true
    }
    return false
}

// MARK: - 命令行标记

private let detachedFlag = "--detached-from-debugger"

// MARK: - PID 文件（用于自动终止旧实例）

private func pidFilePath() -> URL {
    let appSupport = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    .appendingPathComponent("HistoryClipboard")
    // 确保目录存在
    try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    return appSupport.appendingPathComponent("running.pid")
}

/// 终止所有旧实例，确保只有一个菜单栏图标
private func killOldInstanceAndSavePID() {
    let fileURL = pidFilePath()
    let myPid = ProcessInfo.processInfo.processIdentifier

    // ---- 方法 1：通过 NSRunningApplication 精确查找同 Bundle ID 的旧实例 ----
    let myBundleId = Bundle.main.bundleIdentifier ?? "com.historyclipboard.app"
    let runningApps = NSWorkspace.shared.runningApplications
    let oldInstances = runningApps.filter {
        $0.bundleIdentifier == myBundleId && $0.processIdentifier != myPid
    }

    if !oldInstances.isEmpty {
        print("⚠️ 发现 \(oldInstances.count) 个旧实例，准备终止")
        for app in oldInstances {
            print("   终止 PID: \(app.processIdentifier)")
            app.terminate()
        }
        // 等待旧实例退出
        var waited: TimeInterval = 0
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            let stillAlive = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == myBundleId && $0.processIdentifier != myPid
            }
            if stillAlive.isEmpty { break }
            usleep(200_000)
            waited += 0.2
        }
        // 超时未退出的，强制 kill
        let stubborn = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == myBundleId && $0.processIdentifier != myPid
        }
        for app in stubborn {
            print("💀 旧实例 PID \(app.processIdentifier) 未响应终止，发送 SIGKILL")
            kill(app.processIdentifier, SIGKILL)
        }
        usleep(300_000)
        print("✅ 旧实例已全部终止（耗时 \(String(format: "%.1f", waited))s）")
    }

    // ---- 方法 2：通过 PID 文件兜底（防止 Bundle ID 查不到的场景）----
    if let oldPIDStr = try? String(contentsOf: fileURL, encoding: .utf8),
       let oldPID = pid_t(oldPIDStr.trimmingCharacters(in: .whitespacesAndNewlines)),
       oldPID != myPid {
        // 确认该进程还活着且不是自己
        if kill(oldPID, 0) == 0 {
            print("💀 PID 文件中发现残留进程 \(oldPID)，发送 SIGKILL")
            kill(oldPID, SIGKILL)
            usleep(200_000)
        }
    }

    // 写入当前 PID
    try? "\(myPid)".write(to: fileURL, atomically: true, encoding: .utf8)
    print("📝 PID 已记录: \(myPid)")
}

// MARK: - App 入口

@main
struct HistoryClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var dataStore = DataStore()
    @StateObject private var clipboardMonitor: ClipboardMonitor
    @StateObject private var localizationService = LocalizationService()

    init() {
        // ⚠️ 必须在最前面：调试器脱离
        if isRunningUnderDebugger() {
            print("🔍 检测到调试器 (P_TRACED)，启动独立实例")

            let task = Process()
            task.executableURL = Bundle.main.executableURL
            task.arguments = [detachedFlag]
            do {
                try task.run()
                print("✅ 独立实例已启动 — PID: \(task.processIdentifier)")
            } catch {
                print("❌ 启动失败: \(error.localizedDescription)")
            }

            usleep(500_000)
            print("👋 调试实例退出")
            exit(0)
        }

        print("✅ 独立运行模式 (PID: \(ProcessInfo.processInfo.processIdentifier))")

        // 用 PID 文件方式终止旧实例，可靠程度远高于 NSWorkspace.terminate()
        killOldInstanceAndSavePID()

        let store = DataStore()
        _dataStore = StateObject(wrappedValue: store)
        let monitor = ClipboardMonitor(dataStore: store)
        _clipboardMonitor = StateObject(wrappedValue: monitor)
        monitor.startMonitoring()
        print("📋 历史粘贴板已启动，条目数: \(store.items.count)")
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(dataStore: dataStore)
                .environmentObject(localizationService)
        } label: {
            Image(systemName: "clipboard")
                .font(.system(size: 14, weight: .medium))
        }
        .menuBarExtraStyle(.window)

        Window("历史粘贴板", id: "main") {
            MainWindowView(dataStore: dataStore)
                .environmentObject(localizationService)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 600)

        Settings {
            SettingsView(dataStore: dataStore)
                .environmentObject(localizationService)
        }
        .windowResizability(.contentSize)
    }
}
