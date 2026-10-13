#!/usr/bin/env python3
"""GPT などで生成した「ドット絵風」画像を、アプリで使えるスプライトに自動整形する。

手作業（ドット絵エディタ）なしで、次の処理をまとめて行う。

1. 背景の除去（画像の外周から背景色を塗りつぶし判定。キャラ内部の白は残す）
2. キャラごとの切り出し（1枚に複数キャラが並んでいても自動で分割）
3. 元画像の「1ドットの大きさ」を自動検出し、本来のドット数に戻して減色（既定 16 色）、48x48 のキャンバスに配置
4. 濃色1色の輪郭線の付与（小さく表示しても背景から浮かせる）
5. 歩行アニメーション 4 フレームの自動生成（上下の揺れ＋足の踏み出し）
   ※ 歩行4ポーズを描いた画像なら --walk-frames でそのまま使う
6. 確認用のプレビュー（拡大 PNG と歩行 GIF）

使い方:
    python3 build_sprites.py INPUT.png --names hero,swordsman,mage --out OUT_DIR
    python3 build_sprites.py WALK.png --names superstar --walk-frames --out OUT_DIR

必要ライブラリ: Pillow, numpy
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

TRANSPARENT = (0, 0, 0, 0)


def estimate_background(rgb: np.ndarray) -> np.ndarray:
    """外周のピクセルの中央値を背景色とみなす。"""
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    return np.median(border, axis=0)


def background_mask(rgb: np.ndarray, tolerance: float) -> np.ndarray:
    """外周から連結している「背景に近い色」の領域を True で返す。"""
    h, w, _ = rgb.shape
    bg = estimate_background(rgb)
    near_bg = np.linalg.norm(rgb.astype(float) - bg, axis=2) < tolerance
    mask = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(w):
        queue.extend([(0, x), (h - 1, x)])
    for y in range(h):
        queue.extend([(y, 0), (y, w - 1)])
    while queue:
        y, x = queue.popleft()
        if mask[y, x] or not near_bg[y, x]:
            continue
        mask[y, x] = True
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and not mask[ny, nx]:
                queue.append((ny, nx))
    return mask


def find_characters(foreground: np.ndarray, min_area: int) -> list[tuple[int, int, int, int]]:
    """前景の連結成分を探し、左から順にバウンディングボックス (x0, y0, x1, y1) を返す。"""
    h, w = foreground.shape
    seen = np.zeros_like(foreground)
    boxes = []
    for sy in range(h):
        for sx in range(w):
            if not foreground[sy, sx] or seen[sy, sx]:
                continue
            queue = deque([(sy, sx)])
            seen[sy, sx] = True
            ys, xs = [], []
            while queue:
                y, x = queue.popleft()
                ys.append(y)
                xs.append(x)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w and foreground[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((ny, nx))
            if len(ys) >= min_area:
                boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    boxes.sort(key=lambda b: b[0])
    return merge_overlapping_columns(boxes)


def merge_overlapping_columns(boxes: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    """横方向に重なる成分（帽子の飾りや武器などの離れたパーツ）を1体にまとめる。"""
    merged: list[list[int]] = []
    for x0, y0, x1, y1 in boxes:
        if merged and x0 <= merged[-1][2]:
            m = merged[-1]
            m[0], m[1], m[2], m[3] = min(m[0], x0), min(m[1], y0), max(m[2], x1), max(m[3], y1)
        else:
            merged.append([x0, y0, x1, y1])
    return [tuple(m) for m in merged]


def downscale(images: list[Image.Image], scale: float, colors: int) -> list[np.ndarray]:
    """複数の画像を共通パレットで減色してから、ブロックごとの最頻色で縮小する。

    平均で縮小すると輪郭の黒と服の色が混ざって濁るため、先に元解像度で減色し、
    縮小後の各ピクセルには対応するブロック内で最も多い色をそのまま採用する。
    パレットは全画像で共通にし、フレーム間で色がちらつかないようにする。
    """
    # 背景が色枠を奪わないよう、前景のピクセルだけでパレットを作る
    fg_pixels = np.concatenate([np.array(im)[np.array(im)[:, :, 3] >= 128][:, :3] for im in images])
    sample = Image.fromarray(fg_pixels.reshape(1, -1, 3).astype(np.uint8))
    palette_image = sample.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    palette = np.array(palette_image.getpalette()[: colors * 3], dtype=np.uint8).reshape(-1, 3)

    results = []
    for im in images:
        arr = np.array(im)
        h, w = arr.shape[:2]
        alpha = arr[:, :, 3] >= 128
        indices = np.array(im.convert("RGB").quantize(palette=palette_image, dither=Image.Dither.NONE)).astype(int)
        indices[~alpha] = -1
        tw, th = max(1, round(w * scale)), max(1, round(h * scale))
        out = np.zeros((th, tw, 4), dtype=np.uint8)
        ys = np.linspace(0, h, th + 1).astype(int)
        xs = np.linspace(0, w, tw + 1).astype(int)
        for ty in range(th):
            for tx in range(tw):
                y0, y1, x0, x1 = ys[ty], ys[ty + 1], xs[tx], xs[tx + 1]
                block = indices[y0:y1, x0:x1].ravel()
                filled = block[block >= 0]
                if filled.size * 2 < block.size:
                    continue  # 半分以上が透明なら透明
                # 色はブロック中心付近で判定する（隣のドットとの境目のにじみを拾わない）
                my, mx = (y1 - y0) // 4, (x1 - x0) // 4
                core = indices[y0 + my : y1 - my, x0 + mx : x1 - mx].ravel()
                core = core[core >= 0]
                color = np.bincount(core if core.size else filled, minlength=len(palette)).argmax()
                out[ty, tx, :3] = palette[color]
                out[ty, tx, 3] = 255
        results.append(out)
    return results


def detect_cell_size(images: list[Image.Image], low: float = 3.0, high: float = 24.0) -> float:
    """「ドット絵風」画像の 1ドットが何ピクセル四方で描かれているかを推定する。

    色の変わり目（縦横の差分）が周期的に並ぶ間隔を、周期ごとの位相のそろい具合で評価する。
    """
    signal = []
    for im in images:
        arr = np.array(im.convert("RGB")).astype(float)
        signal.append(np.abs(np.diff(arr, axis=1)).sum(axis=(0, 2)))
        signal.append(np.abs(np.diff(arr, axis=0)).sum(axis=(1, 2)))
    best_score, best_cell = -1.0, low
    for cell in np.arange(low, high, 0.05):
        score = 0.0
        for sig in signal:
            phase = np.exp(2j * np.pi * np.arange(len(sig)) / cell)
            score += abs((sig * phase).sum()) / max(sig.sum(), 1e-9)
        if score > best_score:
            best_score, best_cell = score, cell
    return float(best_cell)


def choose_scale(crops: list[Image.Image], size: int, body: int, mode: str) -> float:
    """縮小率を決める。grid: 元画像のドットを1ピクセルに戻す / fit: 最大 body ピクセルに収める。"""
    longest = max(max(c.size) for c in crops)
    fit = body / longest
    if mode == "fit":
        return fit
    cell = detect_cell_size(crops)
    scale = 1 / cell
    if longest * scale > size - 2:
        print(f"  1ドット≒{cell:.2f}px と検出。元のドット数ではキャンバスに収まらないため縮小します（fit）")
        return fit
    if longest * scale < size / 2:
        # 元画像が小さすぎる・ドットの格子が読み取れない場合は、検出結果を信用しない
        print(f"  ドットの格子を検出できませんでした（推定 {cell:.2f}px）。縮小して取り込みます（fit）")
        return fit
    print(f"  1ドット≒{cell:.2f}px と検出。元のドット数のまま取り込みます（grid）")
    return scale


def place(pixels: np.ndarray, size: int) -> Image.Image:
    """キャンバス中央・足元を下端から 1px 上（輪郭線のぶん）に配置し、輪郭を付ける。"""
    canvas = Image.new("RGBA", (size, size), TRANSPARENT)
    sh, sw = pixels.shape[:2]
    canvas.paste(Image.fromarray(pixels), ((size - sw) // 2, size - sh - 1))
    return add_outline(canvas)


def to_sprite(rgba: Image.Image, size: int, body: int, colors: int, mode: str) -> Image.Image:
    """切り出したキャラを size x size のキャンバスに配置したスプライトにする。"""
    return place(downscale([rgba], choose_scale([rgba], size, body, mode), colors - 1)[0], size)


def to_walk_sprites(
    cleaned: Image.Image, boxes: list[tuple[int, int, int, int]], size: int, body: int, colors: int, mode: str
) -> list[Image.Image]:
    """1体のキャラの歩行ポーズが横に並んだ画像から、フレームごとのスプライトを作る。

    全フレームで縮小率・パレット・縦の切り出し範囲を共通にし、
    フレーム間でキャラの大きさや足元の高さ（上下の揺れ）が保たれるようにする。
    """
    top = min(b[1] for b in boxes)
    bottom = max(b[3] for b in boxes)
    crops = [cleaned.crop((x0, top, x1, bottom)) for x0, _, x1, _ in boxes]
    return [place(px, size) for px in downscale(crops, choose_scale(crops, size, body, mode), colors - 1)]


def add_outline(sprite: Image.Image) -> Image.Image:
    """キャラの外側 1px に輪郭を付ける。輪郭は1色（キャラ内で最も暗い色をさらに暗くした色）。"""
    arr = np.array(sprite)
    opaque = arr[:, :, 3] > 0
    colors = arr[opaque][:, :3].astype(int)
    darkest = colors[colors.sum(axis=1).argmin()]
    outline = (darkest * 0.6).astype(np.uint8)

    grown = opaque.copy()
    grown[1:] |= opaque[:-1]
    grown[:-1] |= opaque[1:]
    grown[:, 1:] |= opaque[:, :-1]
    grown[:, :-1] |= opaque[:, 1:]
    ring = grown & ~opaque
    out = arr.copy()
    out[ring, :3] = outline
    out[ring, 3] = 255
    return Image.fromarray(out)


def walk_frames(sprite: Image.Image, leg_ratio: float = 0.22) -> list[Image.Image]:
    """直立スプライトから歩行 4 フレーム（直立 / 右足前 / 直立 / 左足前）を作る。

    下から leg_ratio の範囲を「足」とみなし、前側／後ろ側の足を交互に 1px 踏み出す。
    足を踏み出すフレームでは上半身を 1px 持ち上げて、歩く揺れを出す。
    """
    arr = np.array(sprite)
    h, w, _ = arr.shape
    rows = np.where(arr[:, :, 3].any(axis=1))[0]
    top, bottom = rows.min(), rows.max() + 1
    leg_top = bottom - max(2, round((bottom - top) * leg_ratio))
    cols = np.where(arr[leg_top:bottom, :, 3].any(axis=0))[0]
    mid = (cols.min() + cols.max() + 1) // 2

    def shift(block: np.ndarray, dx: int) -> np.ndarray:
        out = np.zeros_like(block)
        if dx > 0:
            out[:, dx:] = block[:, :-dx]
        elif dx < 0:
            out[:, :dx] = block[:, -dx:]
        else:
            out[:] = block
        return out

    def stride(direction: int) -> Image.Image:
        frame = np.zeros_like(arr)
        frame[: leg_top - 1] = arr[1:leg_top]  # 上半身を 1px 上へ
        frame[leg_top - 1] = arr[leg_top - 1]
        # 片足だけを進行方向（または逆）へ 1px ずらし、元の足の上に重ねる（隙間を作らない）
        legs = arr[leg_top:bottom]
        moving = legs.copy()
        if direction > 0:
            moving[:, :mid] = 0
        else:
            moving[:, mid:] = 0
        moving = shift(moving, direction)
        frame[leg_top:bottom] = np.where(moving[:, :, 3:4] > 0, moving, legs)
        return Image.fromarray(frame)

    return [sprite, stride(1), sprite, stride(-1)]


def preview(frames_by_name: dict[str, list[Image.Image]], out_dir: Path, scale: int) -> None:
    names = list(frames_by_name)
    size = frames_by_name[names[0]][0].size[0]
    cell = size * scale

    sheet = Image.new("RGBA", (cell * 4, cell * len(names)), (238, 244, 252, 255))
    for row, name in enumerate(names):
        for col, frame in enumerate(frames_by_name[name]):
            big = frame.resize((cell, cell), Image.NEAREST)
            sheet.alpha_composite(big, (col * cell, row * cell))
    sheet.save(out_dir / "preview_sheet.png")

    # 隊列で歩く様子の GIF（アプリのホーム画面下部のイメージ）
    gif_frames = []
    for i in range(4):
        strip = Image.new("RGBA", (cell * len(names), cell), (196, 228, 160, 255))
        for col, name in enumerate(names):
            frame = frames_by_name[name][(i + col) % 4]
            strip.alpha_composite(frame.resize((cell, cell), Image.NEAREST), (col * cell, 0))
        gif_frames.append(strip.convert("RGB"))
    gif_frames[0].save(
        out_dir / "preview_walk.gif", save_all=True, append_images=gif_frames[1:], duration=150, loop=0
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("--names", required=True, help="左から順のキャラID（カンマ区切り）")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--crop", help="入力画像の一部だけを使う場合の範囲 x0,y0,x1,y1（キャラ一覧シートからの切り出し用）")
    parser.add_argument("--size", type=int, default=48, help="スプライトのキャンバスサイズ")
    parser.add_argument(
        "--scale-mode",
        choices=["grid", "fit"],
        default="grid",
        help="grid: 元画像の1ドットを自動検出してそのままの解像度で取り込む（既定） / fit: --body に収まるよう縮小",
    )
    parser.add_argument("--body", type=int, default=46, help="fit のときのキャラ本体の最大の縦横ピクセル数")
    parser.add_argument("--colors", type=int, default=16, help="輪郭色を含む色数の上限")
    parser.add_argument("--tolerance", type=float, default=100.0, help="背景色とみなす色の距離（縁のにじみが残る場合は上げる）")
    parser.add_argument("--min-area", type=int, default=200, help="これより小さい成分はノイズとして無視")
    parser.add_argument(
        "--walk-frames",
        action="store_true",
        help="入力が1体のキャラの歩行4ポーズの並びである場合に指定（歩行フレームを自動生成せず、そのまま使う）",
    )
    parser.add_argument("--preview-scale", type=int, default=6)
    args = parser.parse_args()

    names = [n.strip() for n in args.names.split(",") if n.strip()]
    image = Image.open(args.input).convert("RGBA")
    if args.crop:
        image = image.crop(tuple(int(v) for v in args.crop.split(",")))
    rgb = np.array(image)[:, :, :3]
    fg = ~background_mask(rgb, args.tolerance)

    boxes = find_characters(fg, args.min_area)
    if args.walk_frames:
        if len(names) != 1:
            raise SystemExit("--walk-frames では --names にキャラIDを1つだけ指定してください")
        if len(boxes) != 4:
            raise SystemExit(f"歩行ポーズを {len(boxes)} 個検出しました（4個が必要です）: {boxes}")
    elif len(boxes) != len(names):
        raise SystemExit(f"キャラを {len(boxes)} 体検出しましたが、--names は {len(names)} 件です: {boxes}")

    args.out.mkdir(parents=True, exist_ok=True)
    rgba = np.array(image)
    rgba[~fg] = TRANSPARENT
    cleaned = Image.fromarray(rgba)

    frames_by_name = {}
    if args.walk_frames:
        name = names[0]
        frames = to_walk_sprites(cleaned, boxes, args.size, args.body, args.colors, args.scale_mode)
        for i, frame in enumerate(frames):
            frame.save(args.out / f"{name}_right_{i}.png")
        frames_by_name[name] = frames
        print(f"{name}: {len(frames)} frames from {boxes} -> {args.out}/{name}_right_0..{len(frames) - 1}.png")
    else:
        for name, box in zip(names, boxes):
            sprite = to_sprite(cleaned.crop(box), args.size, args.body, args.colors, args.scale_mode)
            frames = walk_frames(sprite)
            for i, frame in enumerate(frames):
                frame.save(args.out / f"{name}_right_{i}.png")
            frames_by_name[name] = frames
            print(f"{name}: box={box} -> {args.out}/{name}_right_0..3.png")

    preview(frames_by_name, args.out, args.preview_scale)
    print(f"preview: {args.out}/preview_sheet.png, {args.out}/preview_walk.gif")


if __name__ == "__main__":
    main()
