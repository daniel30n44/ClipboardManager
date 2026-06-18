import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ItemType
    var textContent: String?
    var imageFileName: String?
    let timestamp: Date
    var isPinned: Bool
    var expiresAt: Date

    enum ItemType: String, Codable {
        case text
        case image
    }

    init(id: UUID = UUID(),
         type: ItemType,
         textContent: String? = nil,
         imageFileName: String? = nil,
         timestamp: Date = Date(),
         isPinned: Bool = false,
         expiresAt: Date) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.imageFileName = imageFileName
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.expiresAt = expiresAt
    }

    /// 显示用预览文本（截断过长内容）
    var previewText: String {
        switch type {
        case .text:
            let text = textContent ?? ""
            if text.count > 150 {
                return String(text.prefix(150)) + "..."
            }
            return text
        case .image:
            return "[图片]"
        }
    }

    /// 是否已过期
    var isExpired: Bool {
        guard !isPinned else { return false }
        return Date() > expiresAt
    }
}
