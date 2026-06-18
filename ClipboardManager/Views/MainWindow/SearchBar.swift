import SwiftUI

// MARK: - 搜索栏 · Search Bar (Liquid Glass)

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索历史记录..."
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary.opacity(isFocused ? 0.7 : 0.45))
                .font(.system(size: 14, weight: .light))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // Liquid Glass 搜索框 — 浅色模式更白更亮，深色模式半透明暗色
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(isFocused ? 0.15 : 0.08)
                    : Color.white.opacity(isFocused ? 0.8 : 0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(isFocused ? 0.2 : 0.08)
                        : (isFocused
                            ? Color.white.opacity(0.8)
                            : Color.white.opacity(0.35)),
                    lineWidth: isFocused ? 1.2 : 0.8
                )
        )
        .shadow(
            color: colorScheme == .dark
                ? Color.clear
                : (isFocused
                    ? Color.black.opacity(0.05)
                    : Color.black.opacity(0.02)),
            radius: isFocused ? 6 : 3,
            y: isFocused ? 2 : 1
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
