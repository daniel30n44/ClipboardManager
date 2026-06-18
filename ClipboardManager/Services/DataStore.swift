import Foundation
import AppKit

class DataStore: ObservableObject {
    @Published var items: [ClipboardItem] = []

    /// 用户设定的保留天数：1 / 3 / 5
    @Published var retentionDays: Int {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: "retentionDays")
            cleanupExpired()
        }
    }

    private let storageDir: URL
    private let historyFileURL: URL
    private let imagesDir: URL

    init() {
        // 存储路径：~/Library/Application Support/HistoryClipboard/
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        storageDir = appSupport.appendingPathComponent("HistoryClipboard")
        historyFileURL = storageDir.appendingPathComponent("history.json")
        imagesDir = storageDir.appendingPathComponent("images")

        // 读取用户设置
        let saved = UserDefaults.standard.integer(forKey: "retentionDays")
        retentionDays = (saved == 1 || saved == 3 || saved == 5) ? saved : 3

        // 确保目录存在
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        // 加载历史数据
        load()

        // 启动时清理过期条目
        cleanupExpired()
    }

    // MARK: - 持久化

    private func load() {
        guard let data = try? Data(contentsOf: historyFileURL),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: historyFileURL, options: .atomic)
    }

    // MARK: - 图片存储

    func saveImage(_ image: NSImage) -> String? {
        let fileName = "\(UUID().uuidString).png"
        let fileURL = imagesDir.appendingPathComponent(fileName)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            return fileName
        } catch {
            print("保存图片失败: \(error)")
            return nil
        }
    }

    func loadImage(fileName: String) -> NSImage? {
        let fileURL = imagesDir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return NSImage(data: data)
    }

    func deleteImageFile(fileName: String) {
        let fileURL = imagesDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - 剪贴板条目操作

    /// 添加新的文字条目
    func addText(_ text: String) {
        let expiresAt = Calendar.current.date(
            byAdding: .day,
            value: retentionDays,
            to: Date()
        ) ?? Date()

        let item = ClipboardItem(
            type: .text,
            textContent: text,
            timestamp: Date(),
            expiresAt: expiresAt
        )

        items.insert(item, at: 0)
        save()
    }

    /// 添加新的图片条目
    func addImage(_ image: NSImage) {
        guard let fileName = saveImage(image) else { return }

        let expiresAt = Calendar.current.date(
            byAdding: .day,
            value: retentionDays,
            to: Date()
        ) ?? Date()

        let item = ClipboardItem(
            type: .image,
            imageFileName: fileName,
            timestamp: Date(),
            expiresAt: expiresAt
        )

        items.insert(item, at: 0)
        save()
    }

    /// 删除条目
    func delete(_ item: ClipboardItem) {
        if item.type == .image, let fileName = item.imageFileName {
            deleteImageFile(fileName: fileName)
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    /// 切换置顶状态
    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        // 置顶项不需要过期
        if items[index].isPinned {
            items[index].expiresAt = Date.distantFuture
        } else {
            items[index].expiresAt = Calendar.current.date(
                byAdding: .day,
                value: retentionDays,
                to: items[index].timestamp
            ) ?? Date()
        }
        save()
        sortItems()
    }

    /// 清理过期条目（非置顶）
    func cleanupExpired() {
        let expiredIds = items
            .filter { !$0.isPinned && $0.isExpired }
            .map { $0.id }

        for id in expiredIds {
            if let item = items.first(where: { $0.id == id }),
               item.type == .image,
               let fileName = item.imageFileName {
                deleteImageFile(fileName: fileName)
            }
        }

        items.removeAll { expiredIds.contains($0.id) }
        save()
    }

    /// 按置顶优先 + 时间降序排列
    func sortItems() {
        items.sort { a, b in
            if a.isPinned != b.isPinned {
                return a.isPinned && !b.isPinned
            }
            return a.timestamp > b.timestamp
        }
    }
}
