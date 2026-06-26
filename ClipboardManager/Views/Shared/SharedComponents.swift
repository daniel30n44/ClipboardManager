import SwiftUI

// MARK: - 共享 UI 组件 · Shared UI Components（多文件复用）

// MARK: 玻璃分割线

struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    var horizontalPadding: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.4))
            .frame(height: 0.5)
            .padding(.horizontal, horizontalPadding)
    }
}

// MARK: 图标圆形（带毛玻璃质感）

struct IconCircle: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemName: String
    var size: CGFloat = 28
    var iconSize: CGFloat = 13
    var iconWeight: Font.Weight = .medium
    var foregroundColor: Color = Color(hex: "5BA4C9")
    var lightOpacity: CGFloat = 0.65
    var darkOpacity: CGFloat = 0.12
    var shadowRadius: CGFloat = 4
    var shadowY: CGFloat = 2

    private var fillColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(darkOpacity)
            : Color.white.opacity(lightOpacity)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.04)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)
                .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundColor(foregroundColor)
        }
    }
}

// MARK: 小型图标按钮

struct IconCircleButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemName: String
    var size: CGFloat = 26
    var iconSize: CGFloat = 11
    var iconWeight: Font.Weight = .medium
    var foregroundColor: Color = .secondary.opacity(0.65)
    var lightOpacity: CGFloat = 0.6
    var darkOpacity: CGFloat = 0.1
    var shadowRadius: CGFloat = 3
    var shadowY: CGFloat = 1
    var action: () -> Void

    private var fillColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(darkOpacity)
            : Color.white.opacity(lightOpacity)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.03)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: size, height: size)
                    .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: iconWeight))
                    .foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: 应用渐变背景

struct AppGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var startPoint: UnitPoint = .top
    var endPoint: UnitPoint = .bottom
    var lightColors: [Color] = [Color(hex: "F8FBFD"), Color(hex: "F0F6FA"), Color(hex: "F4F8FB")]
    var darkColors: [Color] = [Color(hex: "2C2C30"), Color(hex: "26262A"), Color(hex: "28282C")]

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(colors: darkColors, startPoint: startPoint, endPoint: endPoint)
            } else {
                LinearGradient(colors: lightColors, startPoint: startPoint, endPoint: endPoint)
            }
            Rectangle()
                .fill(.regularMaterial)
        }
    }
}

// MARK: 胶囊选择按钮（保留天数等单选场景）

struct PillSelectButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let action: () -> Void

    private var bgColor: Color {
        isSelected
            ? Color(hex: "5BA4C9").opacity(0.85)
            : (colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.55))
    }

    private var shadowColor: Color {
        isSelected
            ? Color(hex: "5BA4C9").opacity(0.2)
            : (colorScheme == .dark ? .clear : Color.black.opacity(0.02))
    }

    private var strokeColor: Color {
        isSelected
            ? Color.white.opacity(0.4)
            : (colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.white.opacity(0.5))
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.95) : Color(hex: "5BA4C9").opacity(0.8))
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bgColor)
                        .shadow(color: shadowColor, radius: isSelected ? 6 : 3, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(strokeColor, lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }
}
