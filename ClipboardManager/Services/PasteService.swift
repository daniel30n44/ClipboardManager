import AppKit

class PasteService {
    /// 将条目内容复制到剪贴板（用户随后 Cmd+V 即可粘贴）
    static func paste(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            pasteboard.setString(item.textContent ?? "", forType: .string)

        case .image:
            if let fileName = item.imageFileName {
                let imagesDir = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first!
                .appendingPathComponent("HistoryClipboard/images")
                let fileURL = imagesDir.appendingPathComponent(fileName)

                if let image = NSImage(contentsOf: fileURL) {
                    pasteboard.writeObjects([image])
                }
            }
        }
    }

    /// 复制纯文本
    static func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
