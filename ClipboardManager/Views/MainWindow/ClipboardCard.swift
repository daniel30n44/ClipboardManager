import SwiftUI

// MARK: - 剪贴板卡片 · Clipboard Card (Liquid Glass)

struct ClipboardCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onTap: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var localization: LocalizationService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // 左侧：内容区
                VStack(alignment: .leading, spacing: 8) {
                    // 置顶标签
                    if item.isPinned {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                            Text(localization.loc("card.pinned"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "5BA4C9").opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "5BA4C9").opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "5BA4C9").opacity(0.15), lineWidth: 0.5)
                        )
                    }

                    // 内容
                    if item.type == .image, let fileName = item.imageFileName {
                        imageThumbnail(fileName: fileName)
                    } else {
                        Text(item.previewText)
                            .font(.system(size: 13))
                            .lineLimit(5)
                            .foregroundColor(.primary.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                    }

                    // 时间戳
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(item.timestamp.relativeDescription)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary.opacity(0.6))
                }

                Spacer()

                // 右侧：操作按钮（悬停时显示）
                if isHovered {
                    VStack(spacing: 6) {
                        pinButton
                        deleteButton
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            // Liquid Glass 卡片背景（浅色模式更白更亮，深色模式半透明暗色）
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(isHovered ? 0.14 : 0.08)
                            : Color.white.opacity(isHovered ? 0.8 : 0.6))

                    // 选中时加一层蓝色光晕
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "7EC8E3").opacity(0.08))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? Color(hex: "7EC8E3").opacity(0.5)
                            : (colorScheme == .dark
                                ? Color.white.opacity(isHovered ? 0.18 : 0.08)
                                : Color.white.opacity(isHovered ? 0.7 : 0.35)),
                        lineWidth: isSelected ? 1.5 : (isHovered ? 1 : 0.6)
                    )
            )
            .shadow(
                color: isSelected
                    ? Color(hex: "7EC8E3").opacity(0.12)
                    : (colorScheme == .dark
                        ? Color.clear
                        : Color.black.opacity(isHovered ? 0.06 : 0.025)),
                radius: isSelected ? 12 : (isHovered ? 10 : 5),
                y: isSelected ? 4 : (isHovered ? 3 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - 图片缩略图

    private func imageThumbnail(fileName: String) -> some View {
        let imagesDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        .appendingPathComponent("HistoryClipboard/images")
        let fileURL = imagesDir.appendingPathComponent(fileName)

        return Group {
            if let nsImage = NSImage(contentsOf: fileURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 180, maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(localization.loc("card.image_lost"))
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .frame(height: 60)
            }
        }
    }

    // MARK: - 操作按钮

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Image(systemName: item.isPinned ? "pin.slash" : "pin")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.65))
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 2, y: 1)
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.white.opacity(0.5),
                            lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(item.isPinned ? localization.loc("card.unpin") : localization.loc("card.pin"))
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.white.opacity(0.55))
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 2, y: 1)
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.white.opacity(0.5),
                            lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(localization.loc("card.delete"))
    }
}
