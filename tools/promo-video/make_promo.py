#!/usr/bin/env python3
"""RPG Todo の紹介動画（縦 1080x1920・約44秒・SNS 用）を、アプリの素材だけで作る。

    python3 tools/promo-video/make_promo.py [出力先.mp4] [--preview 秒 ...]

- 素材: art/sprites（キャラ）, art/backgrounds（昼・夜）, art/icon（アイコン）。
- 絵は Pillow で1コマずつ描き、音（オーケストラ風の自作BGM）は numpy で作って、ffmpeg でまとめる。
- 画面は実機のスクリーンショットではなく、アプリの見た目を再現したもの。
"""
import math
import random
import subprocess
import sys
import wave
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
W, H, FPS = 1080, 1920, 30
DURATION = 44.0
N_FRAMES = int(DURATION * FPS)

FONT_UI = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
FONT_PIXEL = "/usr/share/fonts/opentype/unifont/unifont_jp.otf"

BLUE = (30, 120, 255)
GOLD = (255, 214, 64)
INK = (20, 24, 60)

# ---------------------------------------------------------------- 台本（時刻は秒）

HERO = "warrior_m"
LINEUP = ["mage_f", "slime", "knight_m", "archer_f", "priest_f"]
COMPLETE_AT = [6.8, 8.7, 10.6, 12.5, 14.4]  # クエストを完了する時刻（20% ずつ。最後が 100%）
BANNER_AT, SCENE_DEMO_END = 15.0, 19.0
SCENE_RANDOM = (19.0, 27.0)
SCENE_WIDGET = (27.0, 31.5)
SCENE_BOOK = (31.5, 36.0)
SCENE_END = (36.0, 44.0)
TAP_AT = 29.3

TASKS = [("朝のランニング", "7:00"), ("メールの返信", "9:00"), ("企画書を書く", "13:00"),
         ("買い物", "18:00"), ("読書 30分", "21:00")]

RANDOM_LINEUPS = [
    ["swordsman_f", "golem", "ninja_m", "summoner_f", "thief_m"],
    ["dragon", "priest_m", "archer_m", "ghost", "mage_m"],
    ["demonlord_f", "knight_f", "slime", "ninja_f", "swordsman_m"],
    ["superstar", "demonlord_m", "mage_f", "golem", "priest_f"],
]
RANDOM_STEP = 2.0
RANDOM_PARTY_SIZE = 270  # 「仲間は、毎日ちがう」の場面のキャラの大きさ

BOOK = [  # (id, ジョブ名, 最初から見つかっているか)
    ("warrior_m", "戦士", True), ("mage_f", "魔法使い", True), ("slime", "スライム", True),
    ("dragon", "", False), ("knight_m", "騎士", True), ("superstar", "スーパースター", False),
    ("ninja_f", "忍者", True), ("demonlord_f", "", False), ("priest_f", "僧侶", True),
    ("golem", "", False), ("thief_m", "", False), ("ghost", "", False),
]
SUPERSTAR_FOUND_AT = 34.6

# ---------------------------------------------------------------- 素材

_assets: dict = {}


def load_assets():
    def bg(name):
        return Image.open(ROOT / "art/backgrounds" / name).convert("RGB").resize((W, H), Image.LANCZOS)

    _assets["day"] = bg("home_day.png")
    _assets["night"] = bg("home_night.png")
    _assets["widget_day"] = Image.open(ROOT / "art/backgrounds/widget_day.png").convert("RGB")
    _assets["sprites"] = {
        p.stem: Image.open(p).convert("RGBA") for p in (ROOT / "art/sprites").glob("*.png")
    }
    icon = Image.open(ROOT / "art/icon/app_icon_1024.png").convert("RGBA")
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *icon.size), radius=int(icon.width * 0.2237), fill=255)
    icon.putalpha(mask)
    _assets["icon"] = icon


_cache: dict = {}


def sprite(cid, size, silhouette=False):
    key = ("s", cid, size, silhouette)
    if key not in _cache:
        img = _assets["sprites"][cid].resize((size, size), Image.LANCZOS)
        if silhouette:
            alpha = img.getchannel("A").point(lambda v: int(v * 0.85))
            img = Image.new("RGBA", img.size, (38, 42, 72, 0))
            img.putalpha(alpha)
        _cache[key] = img
    return _cache[key]


def ui_font(size):
    key = ("f", size)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(FONT_UI, size)
    return _cache[key]


def pixel_text(text, scale, fill, outline=INK):
    """ドット絵風の見出し（Unifont を整数倍に拡大して縁どり）。"""
    key = ("p", text, scale, fill, outline)
    if key in _cache:
        return _cache[key]
    font = ImageFont.truetype(FONT_PIXEL, 16)
    left, _, right, _ = font.getbbox(text)
    mask = Image.new("L", (right - left + 6, 24), 0)
    ImageDraw.Draw(mask).text((3 - left, 3), text, font=font, fill=255)
    mask = mask.point(lambda v: 255 if v > 110 else 0)
    mask = ImageChops.lighter(mask, ImageChops.offset(mask, 1, 0))  # 1ドット線を2ドットに太らせる
    big = mask.resize((mask.width * scale, mask.height * scale), Image.NEAREST)
    edge = big.filter(ImageFilter.MaxFilter(2 * scale + 1))
    shadow = Image.new("RGBA", big.size, (0, 0, 0, 0))
    out = Image.new("RGBA", (big.width + scale * 2, big.height + scale * 2), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", big.size, (0, 0, 0, 110)), (scale * 2, scale * 2), edge)
    out.paste(Image.new("RGBA", big.size, outline + (255,)), (0, 0), edge)
    out.paste(Image.new("RGBA", big.size, fill + (255,)), (0, 0), big)
    del shadow
    _cache[key] = out
    return out


# ---------------------------------------------------------------- 描画の道具

def clamp01(x):
    return max(0.0, min(1.0, x))


def ease_out_cubic(x):
    return 1 - (1 - clamp01(x)) ** 3


def ease_out_back(x):
    x = clamp01(x)
    c1 = 1.70158
    return 1 + (c1 + 1) * (x - 1) ** 3 + c1 * (x - 1) ** 2


def ease_out_bounce(x):
    x = clamp01(x)
    if x < 1 / 2.75:
        return 7.5625 * x * x
    if x < 2 / 2.75:
        x -= 1.5 / 2.75
        return 7.5625 * x * x + 0.75
    if x < 2.5 / 2.75:
        x -= 2.25 / 2.75
        return 7.5625 * x * x + 0.9375
    x -= 2.625 / 2.75
    return 7.5625 * x * x + 0.984375


def blit(cv, img, x, y, opacity=1.0):
    x, y = int(round(x)), int(round(y))
    if opacity <= 0:
        return
    if opacity < 1:
        img = img.copy()
        img.putalpha(img.getchannel("A").point(lambda v: int(v * opacity)))
    x0, y0, x1, y1 = max(x, 0), max(y, 0), min(x + img.width, W), min(y + img.height, H)
    if x0 >= x1 or y0 >= y1:
        return
    cv.alpha_composite(img.crop((x0 - x, y0 - y, x1 - x, y1 - y)), (x0, y0))


def blit_center(cv, img, cx, cy, opacity=1.0, scale=1.0):
    if scale != 1.0:
        img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.LANCZOS)
    blit(cv, img, cx - img.width / 2, cy - img.height / 2, opacity)


def background(kind, zoom=1.0):
    img = _assets[kind]
    if zoom == 1.0:
        return img.convert("RGBA")
    w, h = W / zoom, H / zoom
    box = ((W - w) / 2, H - h, (W + w) / 2, H)
    return img.resize((W, H), Image.BILINEAR, box=box).convert("RGBA")


def layer():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img, "RGBA")


def text_shadow(d, xy, s, size, fill=(255, 255, 255), anchor="la", alpha=255):
    font = ui_font(size)
    d.text((xy[0] + 3, xy[1] + 4), s, font=font, fill=(0, 0, 0, int(150 * alpha / 255)), anchor=anchor)
    d.text(xy, s, font=font, fill=fill + (alpha,), anchor=anchor)


def fade(t, start, end, fade_in=0.4, fade_out=0.4):
    return clamp01((t - start) / fade_in) * clamp01((end - t) / fade_out)


def star_shower(cv, t, t0, t1, count=46):
    if not (t0 <= t <= t1):
        return
    lay, d = layer()
    rnd = random.Random(7)
    for _ in range(count):
        x0 = rnd.uniform(0, W)
        speed = rnd.uniform(380, 760)
        phase = rnd.uniform(0, 1.2)
        size = rnd.uniform(14, 34)
        y = (t - t0 - phase) * speed - 80
        if y < -60 or y > H + 60:
            continue
        x = x0 + math.sin((t - t0) * 2 + x0) * 24
        a = int(255 * min(1, (t1 - t) / 0.6))
        pts = []
        for i in range(8):
            r = size if i % 2 == 0 else size * 0.36
            ang = math.pi / 4 * i - math.pi / 2
            pts.append((x + r * math.cos(ang), y + r * math.sin(ang)))
        d.polygon(pts, fill=GOLD + (a,), outline=(255, 255, 255, a))
    cv.alpha_composite(lay)


def sparkle(cv, cx, cy, p, color=(255, 255, 255)):
    """加入のきらめき。p は 0〜1。"""
    if not (0 < p < 1):
        return
    lay, d = layer()
    a = int(255 * (1 - p))
    for i in range(8):
        ang = math.pi / 4 * i + p
        r1, r2 = 60 + 90 * p, 90 + 120 * p
        d.line((cx + r1 * math.cos(ang), cy + r1 * math.sin(ang),
                cx + r2 * math.cos(ang), cy + r2 * math.sin(ang)), fill=color + (a,), width=8)
    cv.alpha_composite(lay)


# ---------------------------------------------------------------- パーティ

PARTY_SIZE = 230
PARTY_BASE = 1880  # キャラの足元


def party_x(i, size=PARTY_SIZE):
    spacing = (W - 8 - 6 * size) / 5
    return 4 + i * (size + spacing)


def draw_party(cv, t, members, join_times, hop_from=None, size=PARTY_SIZE):
    """勇者を先頭に、仲間を横一列に描く。join_times[i] 以降に上から弾んで現れる。"""
    blit(cv, sprite(HERO, size), party_x(0, size), PARTY_BASE - size)
    for i, cid in enumerate(members):
        jt = join_times[i]
        if t < jt:
            continue
        p = (t - jt) / 0.6
        drop = (1 - ease_out_bounce(p)) * 520 if p < 1 else 0
        hop = 0
        if hop_from is not None and t > hop_from:
            hop = -abs(math.sin((t - hop_from) * 6 + i)) * 26
        x = party_x(i + 1, size)
        blit(cv, sprite(cid, size), x, PARTY_BASE - size - drop + hop, opacity=clamp01(p * 4))
        sparkle(cv, x + size / 2, PARTY_BASE - size / 2, (t - jt - 0.35) / 0.6)
    if hop_from is not None and t > hop_from:
        pass


# ---------------------------------------------------------------- シーン

def scene_title(t):
    """0〜5秒: 夜空にコピー。終わりに朝へ。"""
    night = background("night", 1.0 + 0.015 * t)
    dawn = clamp01((t - 4.0) / 1.0)
    cv = Image.blend(night, background("day"), dawn) if dawn > 0 else night
    rnd = random.Random(3)
    lay, d = layer()
    for _ in range(26):
        x, y = rnd.uniform(40, W - 40), rnd.uniform(40, 760)
        tw = 0.5 + 0.5 * math.sin(t * 3 + rnd.uniform(0, 6))
        r = 7 + 9 * tw
        a = int(220 * tw * (1 - dawn))
        d.line((x - r, y, x + r, y), fill=(255, 255, 255, a), width=3)
        d.line((x, y - r, x, y + r), fill=(255, 255, 255, a), width=3)
    cv.alpha_composite(lay)
    a1 = fade(t, 0.6, 4.6, 0.6, 0.6)
    a2 = fade(t, 1.8, 4.6, 0.6, 0.6)
    for s, sc, y, a in (("Todoを", 7, 840, a1), ("クエストに変える。", 7, 990, a2)):
        img = pixel_text(s, sc, (255, 255, 255))
        blit(cv, img, (W - img.width) / 2, y + (1 - ease_out_cubic((t - 0.6) / 0.8)) * 30, a)
    return cv


def ring(d, cx, cy, r, frac, text, width=26, text_size=66):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(10, 20, 50, 150))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 70), width=width)
    if frac > 0:
        d.arc((cx - r, cy - r, cx + r, cy + r), start=-90, end=-90 + 360 * frac, fill=BLUE + (255,), width=width)
    d.text((cx, cy), text, font=ui_font(text_size), fill=(255, 255, 255, 255), anchor="mm")


def check_mark(d, cx, cy, s, p, color=(255, 255, 255), width=10):
    pts = [(cx - 0.45 * s, cy + 0.02 * s), (cx - 0.12 * s, cy + 0.36 * s), (cx + 0.5 * s, cy - 0.34 * s)]
    if p < 0.5:
        q = p / 0.5
        pts = [pts[0], (pts[0][0] + (pts[1][0] - pts[0][0]) * q, pts[0][1] + (pts[1][1] - pts[0][1]) * q)]
    else:
        q = (p - 0.5) / 0.5
        pts = [pts[0], pts[1], (pts[1][0] + (pts[2][0] - pts[1][0]) * q, pts[1][1] + (pts[2][1] - pts[1][1]) * q)]
    d.line(pts, fill=color + (255,), width=width, joint="curve")


def done_count(t):
    return sum(1 for c in COMPLETE_AT if t >= c)


def scene_demo(t):
    """5〜19秒: クエストを完了すると仲間が増える。100% で「全員集合！」。"""
    cv = background("day", 1.0)
    dim = clamp01((t - BANNER_AT) / 0.6) * clamp01((SCENE_DEMO_END - t) / 0.4) * 0.25
    k = done_count(t)

    lay, d = layer()
    text_shadow(d, (70, 100), "今日の冒険", 76)
    text_shadow(d, (74, 200), "10月14日(水)", 38)
    # 達成率のゲージ（なめらかに動かす）
    shown = 0.0
    for i, c in enumerate(COMPLETE_AT):
        shown = max(shown, 0.2 * i + 0.2 * ease_out_cubic((t - c) / 0.5)) if t >= c else shown
    ring(d, 880, 210, 120, shown, f"{int(round(shown * 100))}%")
    text_shadow(d, (74, 270), f"5件中 {k}件 完了", 40)

    # クエストカード
    d.rounded_rectangle((60, 400, 1020, 1090), radius=44, fill=(255, 255, 255, 238))
    d.text((110, 450), "今日のクエスト", font=ui_font(46), fill=(30, 40, 70, 255))
    for i, (title, time_) in enumerate(TASKS):
        y = 560 + i * 100
        cx, cy = 128, y + 34
        p = clamp01((t - COMPLETE_AT[i]) / 0.35)
        if p > 0:
            r = 34 * (0.85 + 0.15 * ease_out_back(p))
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=BLUE + (255,))
            check_mark(d, cx, cy, 34, clamp01(p * 1.4))
        else:
            d.ellipse((cx - 34, cy - 34, cx + 34, cy + 34), outline=(150, 156, 175, 255), width=5)
        done = t >= COMPLETE_AT[i]
        d.text((200, cy), title, font=ui_font(46), fill=(140, 146, 165, 255) if done else (30, 40, 70, 255), anchor="lm")
        d.text((990, cy), time_, font=ui_font(36), fill=(140, 146, 165, 255), anchor="rm")
        if i < len(TASKS) - 1:
            d.line((110, y + 84, 990, y + 84), fill=(225, 228, 238, 255), width=2)
    bp = clamp01((t - BANNER_AT) / 0.5)
    if bp > 0:
        lay.putalpha(lay.getchannel("A").point(lambda v: int(v * (1 - 0.8 * bp))))
    cv.alpha_composite(lay)

    if dim > 0:
        cv.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 20, int(255 * dim))))

    # 説明
    a = fade(t, 5.3, BANNER_AT - 0.3, 0.5, 0.4)
    if a > 0:
        lay, d = layer()
        d.rounded_rectangle((90, 1150, 990, 1270), radius=60, fill=(10, 20, 50, int(170 * a)))
        d.text((540, 1210), "クエストを終えるたび、仲間が増える", font=ui_font(48), fill=(255, 255, 255, int(255 * a)), anchor="mm")
        cv.alpha_composite(lay)

    draw_party(cv, t, LINEUP, COMPLETE_AT, hop_from=BANNER_AT)

    if t >= BANNER_AT:
        p = (t - BANNER_AT) / 0.55
        a = clamp01(p * 3) * clamp01((SCENE_DEMO_END - t) / 0.4)
        img = pixel_text("全員集合！", 12, GOLD)
        blit_center(cv, img, W / 2, 700, a, scale=0.4 + 0.6 * ease_out_back(p))
        lay, d = layer()
        text_shadow(d, (W / 2, 860), "達成率 100%", 64, anchor="mm", alpha=int(255 * a))
        cv.alpha_composite(lay)
        star_shower(cv, t, BANNER_AT, SCENE_DEMO_END)
    return cv


def scene_random(t):
    """19〜27秒: 仲間は毎日ちがう。"""
    cv = background("day", 1.0)
    lt = t - SCENE_RANDOM[0]
    idx = min(int(lt / RANDOM_STEP), len(RANDOM_LINEUPS) - 1)
    local = lt - idx * RANDOM_STEP
    lay, d = layer()
    d.rounded_rectangle((70, 262, 1010, 398), radius=68, fill=(10, 20, 50, int(150 * clamp01(lt / 0.4))))
    text_shadow(d, (W / 2, 330), "仲間は、毎日ちがう", 84, anchor="mm", alpha=int(255 * clamp01(lt / 0.4)))
    text_shadow(d, (W / 2, 450), "全25キャラが、日替わりで集合", 46, anchor="mm", alpha=int(255 * clamp01(lt / 0.6)))
    rare = idx == len(RANDOM_LINEUPS) - 1
    day_no = idx + 1
    d.rounded_rectangle((330, 540, 750, 630), radius=45, fill=(10, 20, 50, 160))
    d.text((540, 585), f"{day_no}日目", font=ui_font(52), fill=(255, 255, 255, 255), anchor="mm")
    if rare and local > 0.9:
        ra = clamp01((local - 0.9) / 0.3)
        d.rounded_rectangle((90, 700, 990, 820), radius=60, fill=(10, 20, 50, int(190 * ra)))
        d.text((W / 2, 760), "まれに…スーパースターも！", font=ui_font(60), fill=(255, 205, 230, int(255 * ra)), anchor="mm")
    cv.alpha_composite(lay)
    joins = [SCENE_RANDOM[0] + idx * RANDOM_STEP + 0.1 + 0.18 * i for i in range(5)]
    draw_party(cv, t, RANDOM_LINEUPS[idx], joins, size=RANDOM_PARTY_SIZE)
    if rare:
        star_shower(cv, t, joins[0] + 0.2, SCENE_RANDOM[1])
    return cv


def widget_mock(cv, t, x, y, w, h):
    """ホーム画面ウィジェット（中サイズ）の再現。タップで完了が切り替わる。"""
    r = int(h * 0.12)
    bg = _assets["widget_day"].resize((w, int(w * _assets["widget_day"].height / _assets["widget_day"].width)), Image.LANCZOS)
    bg = bg.crop((0, bg.height - h, w, bg.height)).convert("RGBA")
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=r, fill=255)
    bg.putalpha(mask)
    blit(cv, bg, x, y)

    tapped = t >= TAP_AT
    done = 3 + (1 if tapped else 0)
    lay, d = layer()
    d.rounded_rectangle((x + 8, y + 8, x + w - 8, y + h - 8), radius=r - 8, outline=(255, 255, 255, 60), width=2)
    text_shadow(d, (x + 36, y + 30), "10月14日(水)", 26)
    text_shadow(d, (x + 36, y + 62), "今日の冒険", 54)
    ring(d, x + 120, y + 250, 74, done / 5, f"{done * 20}%", width=16, text_size=40)
    text_shadow(d, (x + 215, y + 215), f"{done}/5 完了", 30)
    text_shadow(d, (x + 215, y + 255), f"仲間 {done}/5", 30)
    # クエストカード
    cx0, cy0 = x + 470, y + 26
    d.rounded_rectangle((cx0, cy0, x + w - 26, y + h - 26), radius=30, fill=(255, 255, 255, 232))
    d.text((cx0 + 28, cy0 + 24), "今日のクエスト", font=ui_font(28), fill=(30, 40, 70, 255))
    rows = [("朝のランニング", True), ("メールの返信", True), ("企画書を書く", True), ("買い物", tapped)]
    for i, (title, ok) in enumerate(rows):
        ry = cy0 + 94 + i * 68
        cxx = cx0 + 52
        pr = clamp01((t - TAP_AT - 0.15) / 0.3) if (i == 3 and tapped) else (1.0 if ok else 0.0)
        if pr > 0:
            d.ellipse((cxx - 22, ry - 22, cxx + 22, ry + 22), fill=BLUE + (255,))
            check_mark(d, cxx, ry, 22, pr, width=6)
        else:
            d.ellipse((cxx - 22, ry - 22, cxx + 22, ry + 22), outline=(150, 156, 175, 255), width=4)
        d.text((cxx + 44, ry), title, font=ui_font(30), fill=(140, 146, 165, 255) if pr > 0 else (30, 40, 70, 255), anchor="lm")
    cv.alpha_composite(lay)

    # 指のタップ
    tp = (t - (TAP_AT - 0.5)) / 0.9
    if 0 < tp < 1:
        fx, fy = cx0 + 52, cy0 + 94 + 3 * 68
        lay, d = layer()
        a = int(200 * math.sin(math.pi * tp))
        rr = 30 + 40 * clamp01((tp - 0.4) / 0.4)
        d.ellipse((fx - rr, fy - rr, fx + rr, fy + rr), fill=(255, 255, 255, a // 2), outline=(255, 255, 255, a), width=5)
        cv.alpha_composite(lay)
    # 仲間
    size = 110
    mem = [HERO] + LINEUP[: done - 0 if done <= 5 else 5]
    for i, cid in enumerate(mem[: 1 + done]):
        blit(cv, sprite(cid, size), x + 28 + i * 66, y + h - size - 6)


def small_widget(cv, x, y, size):
    """小サイズのウィジェットの再現（達成率とパーティ）。"""
    bg = _assets["widget_day"].resize((size, int(size * _assets["widget_day"].height / _assets["widget_day"].width)), Image.LANCZOS)
    bg = bg.crop((0, bg.height - size, size, bg.height)).convert("RGBA")
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size, size), radius=int(size * 0.2), fill=255)
    bg.putalpha(mask)
    blit(cv, bg, x, y)
    lay, d = layer()
    text_shadow(d, (x + size / 2, y + 50), "今日の冒険", 40, anchor="mm")
    ring(d, x + size / 2, y + 170, 70, 0.8, "80%", width=15, text_size=36)
    text_shadow(d, (x + size / 2, y + 268), "4/5 完了 ・ 仲間 4/5", 25, anchor="mm")
    cv.alpha_composite(lay)
    for i, cid in enumerate([HERO] + LINEUP[:4]):
        blit(cv, sprite(cid, 96), x + 20 + i * 70, y + size - 100)


def scene_widget(t):
    cv = background("night", 1.0)
    cv.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 20, 70)))
    lt = t - SCENE_WIDGET[0]
    lay, d = layer()
    text_shadow(d, (W / 2, 260), "ウィジェットで、サッと完了", 70, anchor="mm", alpha=int(255 * clamp01(lt / 0.4)))
    cv.alpha_composite(lay)
    p = ease_out_back(lt / 0.6)
    tmp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    widget_mock(tmp, t, 60, 400, 960, 452)
    small_widget(tmp, 60, 1010, 440)
    cv.alpha_composite(tmp)
    del p
    lay, d = layer()
    text_shadow(d, (W / 2, 930), "ホーム画面から、ワンタップ", 54, anchor="mm", alpha=int(255 * clamp01((lt - 0.6) / 0.5)))
    a = int(255 * clamp01((lt - 1.2) / 0.5))
    text_shadow(d, (540, 1110), "小・中・大の", 52, alpha=a)
    text_shadow(d, (540, 1180), "3サイズ", 52, alpha=a)
    text_shadow(d, (540, 1290), "ダークモードにも", 44, alpha=a)
    text_shadow(d, (540, 1350), "ぴったり対応", 44, alpha=a)
    cv.alpha_composite(lay)
    return cv


def scene_book(t):
    cv = background("night", 1.0)
    cv.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 20, 110)))
    lt = t - SCENE_BOOK[0]
    found_at = {i: 0.5 + 0.16 * n for n, i in enumerate(i for i, b in enumerate(BOOK) if b[2])}
    n_found = sum(1 for i in found_at if lt >= found_at[i]) + (1 if t >= SUPERSTAR_FOUND_AT else 0)
    lay, d = layer()
    text_shadow(d, (W / 2, 190), "図鑑を、うめよう", 80, anchor="mm", alpha=int(255 * clamp01(lt / 0.4)))
    text_shadow(d, (W / 2, 300), f"発見 {n_found} / 23", 52, fill=GOLD, anchor="mm")
    cv.alpha_composite(lay)
    for i, (cid, name, found) in enumerate(BOOK):
        col, row = i % 3, i // 3
        x, y = 60 + col * 330, 380 + row * 330
        is_found = found or (cid == "superstar" and t >= SUPERSTAR_FOUND_AT)
        appear = clamp01((lt - 0.1 - 0.05 * i) / 0.3)
        if appear <= 0:
            continue
        card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(card, "RGBA")
        dd.rounded_rectangle((x, y, x + 300, y + 300), radius=34, fill=(255, 255, 255, 235))
        pop = 1.0
        if found:
            pop = 1 + 0.12 * math.sin(math.pi * clamp01((lt - found_at[i]) / 0.35))
        if cid == "superstar" and is_found:
            pop = 1 + 0.2 * math.sin(math.pi * clamp01((t - SUPERSTAR_FOUND_AT) / 0.5))
        blit_center(card, sprite(cid, 210, silhouette=not is_found), x + 150, y + 125, 1.0, scale=pop)
        label = ("スーパースター" if cid == "superstar" else name) if is_found else "？？？"
        dd.text((x + 150, y + 262), label, font=ui_font(38), fill=(30, 40, 70, 255) if is_found else (110, 116, 140, 255), anchor="mm")
        if appear < 1:
            card.putalpha(card.getchannel("A").point(lambda v: int(v * appear)))
        cv.alpha_composite(card)
        if cid == "superstar":
            sparkle(cv, x + 150, y + 125, (t - SUPERSTAR_FOUND_AT) / 0.7, color=GOLD)
    return cv


def scene_end(t):
    lt = t - SCENE_END[0]
    night = background("night", 1.05 - 0.03 * lt / 8)
    cv = night
    rnd = random.Random(11)
    lay, d = layer()
    for _ in range(30):
        x, y = rnd.uniform(40, W - 40), rnd.uniform(40, 900)
        tw = 0.5 + 0.5 * math.sin(t * 3 + rnd.uniform(0, 6))
        r = 6 + 9 * tw
        d.line((x - r, y, x + r, y), fill=(255, 255, 255, int(230 * tw)), width=3)
        d.line((x, y - r, x, y + r), fill=(255, 255, 255, int(230 * tw)), width=3)
    cv.alpha_composite(lay)
    grad = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for yy in range(800, 1500):
        a = int(170 * math.sin(math.pi * (yy - 800) / 700))
        gd.line((0, yy, W, yy), fill=(6, 12, 40, a))
    cv.alpha_composite(grad)
    p = (lt - 0.3) / 0.7
    blit_center(cv, _assets["icon"], W / 2, 560, clamp01(p * 3), scale=0.46 * (0.4 + 0.6 * ease_out_back(p)))
    img = pixel_text("RPG Todo", 12, (255, 255, 255))
    blit(cv, img, (W - img.width) / 2, 850 + (1 - ease_out_cubic((lt - 1.0) / 0.6)) * 30, clamp01((lt - 1.0) / 0.5))
    lay, d = layer()
    text_shadow(d, (W / 2, 1240), "Todoをクエストに変える。", 56, anchor="mm", alpha=int(255 * clamp01((lt - 1.8) / 0.6)))
    text_shadow(d, (W / 2, 1340), "iPhone アプリ", 40, anchor="mm", alpha=int(210 * clamp01((lt - 2.4) / 0.6)))
    cv.alpha_composite(lay)
    party = [HERO] + LINEUP
    for i, cid in enumerate(party):
        a = clamp01((lt - 3.0 - 0.12 * i) / 0.4)
        hop = -abs(math.sin((lt - 3.5) * 5 + i * 0.7)) * 18 if lt > 3.5 else 0
        blit(cv, sprite(cid, 170), 34 + i * 165, 1740 - 170 + hop, a)
    out = clamp01((t - (DURATION - 1.0)) / 1.0)
    if out > 0:
        cv.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, int(255 * out))))
    return cv


def render(t):
    if t < 5.0:
        cv = scene_title(t)
    elif t < SCENE_DEMO_END:
        cv = scene_demo(t)
    elif t < SCENE_RANDOM[1]:
        cv = scene_random(t)
    elif t < SCENE_WIDGET[1]:
        cv = scene_widget(t)
    elif t < SCENE_BOOK[1]:
        cv = scene_book(t)
    else:
        cv = scene_end(t)
    # 場面の切り替えは短いフェードでつなぐ
    for edge in (5.0, SCENE_DEMO_END, SCENE_RANDOM[1], SCENE_WIDGET[1], SCENE_BOOK[1]):
        pass
    return cv


# 場面の境目で、前の場面の最後の絵とクロスフェードする
CUTS = [5.0, SCENE_DEMO_END, SCENE_RANDOM[1], SCENE_WIDGET[1], SCENE_BOOK[1]]
CROSS = 0.35


def render_frame(i):
    t = i / FPS
    cv = render(t)
    for cut in CUTS:
        if cut <= t < cut + CROSS and cut > 5.0:
            prev = render(cut - 1e-3)
            cv = Image.blend(prev, cv, (t - cut) / CROSS)
    return cv.convert("RGB").tobytes()


# ---------------------------------------------------------------- 音（オーケストラ風・オリジナル）
# 弦・金管・ハープ・ティンパニ・シンバルを、加算合成とノイズで作る（サンプル音源は使わない）。

SR = 44100
BPM = 120
BEAT = 60 / BPM
BAR = BEAT * 4


def midi_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def _env(n, attack, release):
    x = np.arange(n) / SR
    dur = n / SR
    return np.minimum(1.0, x / max(attack, 1e-4)) * np.clip((dur - x) / max(release, 1e-4), 0, 1)


def horn(freq, dur, vol, harm=10, attack=0.04, release=0.12, vibrato=0.0, detune=0.0):
    """弦・金管のような、倍音の多い持続音。"""
    n = int(SR * dur)
    x = np.arange(n) / SR
    out = np.zeros(n)
    for d in ((-detune, detune) if detune else (0.0,)):
        vib = 1 + vibrato * np.sin(2 * np.pi * 5.2 * x) * np.minimum(1, x / 0.35)
        ph = 2 * np.pi * np.cumsum(freq * (1 + d) * vib) / SR
        out += sum(np.sin(k * ph) / k for k in range(1, harm + 1))
    out /= (2 if detune else 1)
    return out * _env(n, attack, release) * vol


def pluck(freq, dur, vol):
    """ハープのはじく音。"""
    n = int(SR * dur)
    x = np.arange(n) / SR
    w = np.sin(2 * np.pi * freq * x) + 0.45 * np.sin(4 * np.pi * freq * x) + 0.2 * np.sin(6 * np.pi * freq * x)
    return w * np.exp(-x * 5.5) * np.minimum(1, x / 0.003) * vol


def timpani(vol, low=56):
    n = int(SR * 0.9)
    x = np.arange(n) / SR
    f = low + 40 * np.exp(-x * 18)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x * 5.0)
    thump = np.random.default_rng(2).uniform(-1, 1, n) * np.exp(-x * 60) * 0.25
    return (body + thump) * vol


def snare(vol):
    n = int(SR * 0.16)
    x = np.arange(n) / SR
    noise = np.random.default_rng(5).uniform(-1, 1, n)
    return (noise * np.exp(-x * 26) + 0.4 * np.sin(2 * np.pi * 190 * x) * np.exp(-x * 40)) * vol


def cymbal(vol, dur=2.2):
    n = int(SR * dur)
    x = np.arange(n) / SR
    noise = np.diff(np.random.default_rng(8).uniform(-1, 1, n + 1))
    return noise * np.exp(-x * 2.3) * np.minimum(1, x / 0.01) * vol


def put(buf, t, sig):
    i = int(t * SR)
    if i >= len(buf) or i < 0:
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


CHORDS = [(48, [60, 64, 67]), (43, [59, 62, 67]), (45, [60, 64, 69]), (41, [60, 65, 69])]  # C G Am F
PHRASE_A = [(64, 1), (67, 1), (72, 1), (67, 1), (62, 1), (67, 1), (71, 1), (67, 1),
            (60, 1), (64, 1), (69, 1), (64, 1), (65, 1.5), (69, .5), (72, 2)]
PHRASE_B = [(67, 1), (72, 1), (76, 1), (72, 1), (74, 1), (71, 1), (67, 1), (71, 1),
            (69, 1), (72, 1), (76, 1), (72, 1), (72, 1), (69, .5), (67, .5), (72, 2)]
MELODY_START, OUTRO, FINALE = 4.0, 36.0, 40.0


def build_audio(path):
    total = int(DURATION * SR)
    buf = np.zeros(total)

    # 弦のパッドとハープ・低音（小節ごと。最初の2小節は Am-F の導入、4秒から C で始まる）
    for bar in range(int(DURATION / BAR) + 1):
        t0 = bar * BAR
        if t0 >= FINALE:
            break
        root, notes = CHORDS[(bar - 2) % 4]
        for n in notes:
            put(buf, t0, horn(midi_hz(n - 12), BAR + 0.25, 0.050, harm=7, attack=0.22, release=0.5, vibrato=0.003, detune=0.004))
        for b in range(8):  # ハープ（8分音符のアルペジオ）
            tone_ = [notes[0], notes[1], notes[2], notes[0] + 12, notes[2], notes[1], notes[0] + 12, notes[2]][b]
            put(buf, t0 + b * BEAT / 2, pluck(midi_hz(tone_ + 12), 0.7, 0.07 if t0 >= MELODY_START else 0.05))
        if t0 >= MELODY_START:
            for b in range(4):  # コントラバス（根音と5度）
                put(buf, t0 + b * BEAT, horn(midi_hz(root + (7 if b % 2 else 0)), BEAT * 0.8, 0.12, harm=5, attack=0.02, release=0.15))
            put(buf, t0, timpani(0.30))
            put(buf, t0 + 2 * BEAT, timpani(0.22))
            for b in (1, 3):
                put(buf, t0 + b * BEAT, snare(0.10))
        else:  # 導入: ティンパニの小さなロール
            for b in range(8):
                put(buf, t0 + b * BEAT / 2, timpani(0.05 + 0.02 * (bar * 8 + b), low=62))

    # 金管のメロディ（4秒から。A・B・A・B の順）
    t = MELODY_START
    phrases = [PHRASE_A, PHRASE_B, PHRASE_A, PHRASE_B]
    for ph in phrases:
        for note, d in ph:
            put(buf, t, horn(midi_hz(note), d * BEAT * 0.95, 0.105, harm=9, attack=0.045, release=0.12, vibrato=0.004 if d > 1.2 else 0.0))
            put(buf, t, horn(midi_hz(note - 12), d * BEAT * 0.95, 0.04, harm=6, attack=0.06, release=0.12))
            t += d * BEAT
    # アウトロ（36〜40秒）と最後の和音（40秒〜）
    outro = [(64, 1), (67, 1), (72, 1), (67, 1), (62, 1), (67, 2), (71, 1)]
    t = OUTRO
    for note, d in outro:
        put(buf, t, horn(midi_hz(note), d * BEAT * 0.95, 0.12, harm=9, attack=0.045, release=0.12))
        t += d * BEAT
    for n in (60, 64, 67, 72, 76):
        put(buf, FINALE, horn(midi_hz(n), DURATION - FINALE + 0.5, 0.075, harm=9, attack=0.06, release=1.0, vibrato=0.003, detune=0.003))
    put(buf, FINALE, horn(midi_hz(36), DURATION - FINALE + 0.5, 0.16, harm=5, attack=0.05, release=1.0))
    put(buf, FINALE, timpani(0.45))
    for i in range(6):  # 100% の前の太鼓のクレッシェンド
        pass
    # 場面の切り替えのシンバルと、100% 前のスネアロール
    for ct, v in ((BANNER_AT, 0.22), (SCENE_RANDOM[0], 0.10), (SCENE_WIDGET[0], 0.10), (OUTRO, 0.16), (FINALE, 0.22)):
        put(buf, ct, cymbal(v))
    roll_t = BANNER_AT - 2 * BEAT
    for i in range(16):
        put(buf, roll_t + i * BEAT / 4 * 0.5 * 2, snare(0.05 + 0.09 * i / 16))
    put(buf, BANNER_AT, timpani(0.5, low=52))

    # 残響（広い部屋の響き）と仕上げ
    ir_n = int(SR * 1.4)
    ir = np.random.default_rng(3).normal(size=ir_n) * np.exp(-np.arange(ir_n) / SR / 0.38)
    size = 1 << (total + ir_n).bit_length()
    wet = np.fft.irfft(np.fft.rfft(buf, size) * np.fft.rfft(ir, size), size)[:total]
    wet *= np.abs(buf).max() / max(np.abs(wet).max(), 1e-9) * 0.9
    mix = buf * 0.8 + wet * 0.45
    fade_out = np.clip((DURATION - np.arange(total) / SR) / 1.6, 0, 1)
    mix *= fade_out
    mix = np.tanh(mix / np.abs(mix).max() * 1.6) * 0.88
    pcm = (mix * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


# ---------------------------------------------------------------- 実行

def main():
    args = sys.argv[1:]
    load_assets()
    if "--preview" in args:
        i = args.index("--preview")
        out = Path(args[0]) if i > 0 else Path("preview")
        out.mkdir(parents=True, exist_ok=True)
        for s in args[i + 1:]:
            t = float(s)
            img = Image.frombytes("RGB", (W, H), render_frame(int(t * FPS)))
            img.resize((540, 960), Image.LANCZOS).save(out / f"t{t:05.1f}.png")
        return

    out = Path(args[0]) if args else ROOT / "promo.mp4"
    wav = out.with_suffix(".wav")
    build_audio(wav)
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
           "-r", str(FPS), "-i", "-", "-i", str(wav), "-c:v", "libx264", "-preset", "medium", "-crf", "18",
           "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", str(out)]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    with Pool(4, initializer=load_assets) as pool:
        for n, frame in enumerate(pool.imap(render_frame, range(N_FRAMES), chunksize=6)):
            proc.stdin.write(frame)
            if n % 150 == 0:
                print(f"{n}/{N_FRAMES}", flush=True)
    proc.stdin.close()
    proc.wait()
    wav.unlink(missing_ok=True)
    print("done:", out)


if __name__ == "__main__":
    main()
