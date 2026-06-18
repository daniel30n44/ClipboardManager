import AppKit
import Combine

@MainActor
class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastTextContent: String?
    private var lastImageDataHash: Int?

    let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        lastChangeCount = NSPasteboard.general.changeCount
    }

    /// 开始监听剪贴板（每 0.5 秒轮询）
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkPasteboard()
            }
        }
        // 确保 timer 在 RunLoop 中运行
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// 停止监听
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// 检查剪贴板变化
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // changeCount 没变，没有新复制
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // 优先检查文字
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // 去重：与上一条文字相同则忽略
            if text == lastTextContent { return }
            lastTextContent = text
            lastImageDataHash = nil
            dataStore.addText(text)
            dataStore.sortItems()
            return
        }

        // 检查图片
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            // 去重：比较图片数据哈希
            let imageHash = hashOfImage(image)
            if imageHash == lastImageDataHash { return }
            lastImageDataHash = imageHash
            lastTextContent = nil
            dataStore.addImage(image)
            dataStore.sortItems()
            return
        }
    }

    /// 计算图片简单哈希用于去重
    private func hashOfImage(_ image: NSImage) -> Int? {
        guard let tiff = image.tiffRepresentation else { return nil }
        var hasher = Hasher()
        // 只取前 8KB 做哈希，足够去重且性能好
        let sampleSize = min(tiff.count, 8192)
        tiff.prefix(sampleSize).forEach { hasher.combine($0) }
        return hasher.finalize()
    }
}
