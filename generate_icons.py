#!/usr/bin/env python3
"""纯 Python 生成 AppIcon PNG 文件 — 无需任何第三方库"""

import struct
import zlib
import os

def create_png(width, height, pixels):
    """
    生成 PNG 文件字节。
    pixels: 列表，每行一个 bytes，每个 pixel 4 字节 (R,G,B,A)
    """
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack('>I', len(data)) + c + crc

    # PNG signature
    sig = b'\x89PNG\r\n\x1a\n'

    # IHDR
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)  # 8bit RGBA

    # IDAT: raw image data with filter byte 0 per row
    raw = b''
    for row in pixels:
        raw += b'\x00' + row  # filter: None

    idat = zlib.compress(raw)

    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')


def make_icon(size):
    """生成一个简单的淡蓝色剪贴板图标"""
    # 颜色
    BG  = (0xF5, 0xF9, 0xFC, 0x00)  # 透明背景
    BODY = (0x7E, 0xC8, 0xE3, 0xFF)  # #7EC8E3 主体
    DARK = (0x3A, 0x7C, 0xA5, 0xFF)  # #3A7CA5 深色边缘
    WHITE = (0xFF, 0xFF, 0xFF, 0xFF)
    PAPER = (0xF5, 0xF9, 0xFC, 0xFF)  # 纸面颜色

    # 创建画布
    pixels = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            # 缩放到 16x16 参考坐标
            rx = x * 16 / size
            ry = y * 16 / size

            # 剪贴板主体是一个圆角矩形 (2,0) -> (14,14)
            # 顶部夹子 (6,0) -> (10,3)
            in_body = (1.5 <= rx <= 14.5 and 2.5 <= ry <= 15.5)
            in_clip = (5.5 <= rx <= 10.5 and 0 <= ry <= 3)
            in_clip_inner = (6.5 <= rx <= 9.5 and 0.5 <= ry <= 2.5)
            in_paper = (3 <= rx <= 13 and 5.5 <= ry <= 14)
            # paper lines
            line1 = (4 <= rx <= 12 and 7.5 <= ry <= 8.5)
            line2 = (4 <= rx <= 12 and 9.5 <= ry <= 10.5)
            line3 = (4 <= rx <= 9 and 11.5 <= ry <= 12.5)

            r, g, b, a = BG

            if in_body or in_clip:
                r, g, b, a = BODY
            if in_clip_inner:
                r, g, b, a = (0x5B, 0xA4, 0xC9, 0xFF)
            if in_paper:
                r, g, b, a = PAPER
            if line1 or line2 or line3:
                r, g, b, a = DARK

            row.extend([r, g, b, a])
        pixels.append(bytes(row))

    return create_png(size, size, pixels)


# 输出目录
icon_dir = os.path.join(os.path.dirname(__file__),
    "ClipboardManager", "Assets.xcassets", "AppIcon.appiconset")

# 需要的尺寸 (文件名, 实际像素)
sizes = {
    "appicon.png": 16,
    "appicon@2x.png": 32,
    "appicon-32.png": 32,
    "appicon-32@2x.png": 64,
    "appicon-128.png": 128,
    "appicon-128@2x.png": 256,
    "appicon-256.png": 256,
    "appicon-256@2x.png": 512,
    "appicon-512.png": 512,
    "appicon-512@2x.png": 1024,
}

for filename, px in sizes.items():
    path = os.path.join(icon_dir, filename)
    png_data = make_icon(px)
    with open(path, 'wb') as f:
        f.write(png_data)
    print(f"✅ {filename} ({px}x{px}) — {len(png_data)} bytes")

print(f"\n🎉 全部 AppIcon 已生成到: {icon_dir}")
