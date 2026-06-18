#!/bin/bash
# =========================================
# ClipboardManager — 编译并启动独立实例
# 不依赖 Xcode 调试器，关闭 Xcode 不会退出
# =========================================

set -e
cd "$(dirname "$0")"

PROJECT="ClipboardManager.xcodeproj"
SCHEME="ClipboardManager"
APP_NAME="ClipboardManager.app"
INSTALL_DIR="$HOME/Applications"

echo "🔨 编译 Release 版本..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath .build \
    build -quiet 2>&1 | tail -5

# 找到编译产物
APP_PATH=$(find .build -name "$APP_NAME" -type d 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到编译产物"
    exit 1
fi
echo "✅ 编译完成: $APP_PATH"

# 杀掉旧实例（如果有的话）
pkill -f "$APP_NAME" 2>/dev/null && echo "📴 已关闭旧实例" || true
sleep 0.5

# 复制到 ~/Applications
mkdir -p "$INSTALL_DIR"
cp -Rf "$APP_PATH" "$INSTALL_DIR/"
echo "📦 已安装到: $INSTALL_DIR/$APP_NAME"

# 启动
open "$INSTALL_DIR/$APP_NAME"
echo "🚀 已启动！现在关闭 Xcode 不会影响它。"
