"""
Generate 5 App Store screenshots (1290x2796) for SportsMeal iOS app.
Dark luxury theme with gold accents.
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# --- Constants ---
W, H = 1290, 2796
FONT_DIR = os.path.expanduser("~/.claude/skills/canvas-design/canvas-fonts")
OUT_DIR = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

# Brand colors
BG = (18, 18, 21)
SURFACE = (27, 27, 31)
SURFACE_LIGHT = (35, 35, 40)
GOLD = (217, 184, 114)
GOLD_LIGHT = (235, 205, 148)
GREEN = (102, 199, 148)
RED = (220, 90, 90)
WHITE92 = (235, 235, 235)
WHITE55 = (140, 140, 140)
WHITE30 = (77, 77, 77)

# --- Font loaders ---
def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)

def italiana(size):
    return font("Italiana-Regular.ttf", size)

def jura_light(size):
    return font("Jura-Light.ttf", size)

def jura_med(size):
    return font("Jura-Medium.ttf", size)

def geist(size):
    return font("GeistMono-Regular.ttf", size)


# --- Drawing helpers ---

def new_canvas():
    """Create base canvas with subtle vertical gradient."""
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    # subtle gradient overlay — slightly lighter at top
    for y in range(H):
        alpha = int(12 * (1 - y / H))
        draw.line([(0, y), (W, y)], fill=(BG[0] + alpha, BG[1] + alpha, BG[2] + alpha))
    return img, draw


def draw_rounded_rect(draw, bbox, radius, fill, outline=None):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = bbox
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline)


def draw_arc_ring(draw, center, radius, width, start_deg, end_deg, color):
    """Draw a thick arc (ring segment)."""
    cx, cy = center
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.arc(bbox, start=start_deg - 90, end=end_deg - 90, fill=color, width=width)


def text_center(draw, text, y, fnt, fill):
    """Draw text centered horizontally."""
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2, y), text, font=fnt, fill=fill)


def text_right(draw, text, x_right, y, fnt, fill):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    draw.text((x_right - tw, y), text, font=fnt, fill=fill)


def draw_header(draw, headline, subtitle):
    """Draw headline + subtitle at top of screenshot."""
    text_center(draw, headline, 160, italiana(88), GOLD)
    text_center(draw, subtitle, 280, jura_light(42), WHITE92)


def draw_wordmark(draw):
    """Draw SportsMeal wordmark at bottom."""
    text_center(draw, "SportsMeal", H - 160, italiana(56), GOLD)


def draw_phone_frame(draw, top=420, bottom=2580, margin=80, radius=48):
    """Draw simulated phone screen area and return its inner bbox."""
    x0, y0, x1, y1 = margin, top, W - margin, bottom
    draw_rounded_rect(draw, (x0, y0, x1, y1), radius, SURFACE, outline=WHITE30)
    pad = 32
    return (x0 + pad, y0 + pad, x1 - pad, y1 - pad)


def draw_small_ring(draw, center, radius, width, fraction, color, bg_color=WHITE30):
    """Draw a small progress ring."""
    cx, cy = center
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.arc(bbox, start=-90, end=270, fill=bg_color, width=width)
    end_angle = -90 + fraction * 360
    draw.arc(bbox, start=-90, end=end_angle, fill=color, width=width)


def draw_divider(draw, y, x0, x1):
    draw.line([(x0, y), (x1, y)], fill=WHITE30, width=2)


# ===================== SCREENSHOT 1 =====================
def screenshot_1():
    img, draw = new_canvas()
    draw_header(draw, "Track Every Calorie with AI", "Precision nutrition at a glance")
    inner = draw_phone_frame(draw)
    ix0, iy0, ix1, iy1 = inner
    cx = W // 2

    # Main calorie ring
    ring_cy = iy0 + 380
    ring_r = 240
    # Background ring
    draw_small_ring(draw, (cx, ring_cy), ring_r, 28, 1.0, WHITE30, WHITE30)
    # Gold filled ring (75%)
    draw_small_ring(draw, (cx, ring_cy), ring_r, 28, 0.75, GOLD, WHITE30)

    # Center text
    text_center(draw, "1,847", ring_cy - 60, italiana(96), WHITE92)
    text_center(draw, "kcal remaining", ring_cy + 50, jura_light(36), WHITE55)

    # Daily target label
    text_center(draw, "Daily Target: 2,450 kcal", ring_cy + 120, geist(28), WHITE55)

    # Macro rings row
    macro_y = ring_cy + 340
    macros = [
        ("Protein", 0.68, "132g / 195g", GOLD_LIGHT),
        ("Carbs", 0.55, "180g / 325g", GREEN),
        ("Fat", 0.72, "52g / 72g", GOLD),
    ]
    spacing = (ix1 - ix0) // 3
    for i, (label, frac, detail, color) in enumerate(macros):
        mcx = ix0 + spacing // 2 + i * spacing
        draw_small_ring(draw, (mcx, macro_y), 80, 14, frac, color, WHITE30)
        pct = f"{int(frac*100)}%"
        text_center_at(draw, pct, mcx, macro_y - 14, geist(30), color)
        text_center_at(draw, label, mcx, macro_y + 100, jura_med(30), WHITE92)
        text_center_at(draw, detail, mcx, macro_y + 145, geist(24), WHITE55)

    # Meal summary at bottom of phone
    meal_y = macro_y + 260
    draw_divider(draw, meal_y, ix0, ix1)
    meals = [("Breakfast", "420 kcal"), ("Lunch", "647 kcal"), ("Snack", "183 kcal")]
    for i, (meal, kcal) in enumerate(meals):
        my = meal_y + 40 + i * 80
        draw.text((ix0 + 20, my), meal, font=jura_med(32), fill=WHITE92)
        text_right(draw, kcal, ix1 - 20, my, geist(30), GOLD_LIGHT)

    draw_wordmark(draw)
    img.save(os.path.join(OUT_DIR, "screenshot_1.png"))
    print("  Saved screenshot_1.png")


def text_center_at(draw, text, cx, y, fnt, fill):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    draw.text((cx - tw // 2, y), text, font=fnt, fill=fill)


# ===================== SCREENSHOT 2 =====================
def screenshot_2():
    img, draw = new_canvas()
    draw_header(draw, "Photograph. Analyze. Done.", "AI-powered meal recognition")
    inner = draw_phone_frame(draw)
    ix0, iy0, ix1, iy1 = inner

    # Photo placeholder
    photo_h = 420
    photo_bbox = (ix0 + 20, iy0 + 20, ix1 - 20, iy0 + 20 + photo_h)
    draw_rounded_rect(draw, photo_bbox, 24, SURFACE_LIGHT, outline=WHITE30)
    # Camera icon placeholder
    pcx = (photo_bbox[0] + photo_bbox[2]) // 2
    pcy = (photo_bbox[1] + photo_bbox[3]) // 2
    # simple camera icon: rectangle + circle
    draw_rounded_rect(draw, (pcx - 60, pcy - 40, pcx + 60, pcy + 40), 12, None, outline=WHITE55)
    draw.ellipse((pcx - 22, pcy - 22, pcx + 22, pcy + 22), outline=WHITE55, width=3)
    text_center_at(draw, "Tap to photograph meal", pcx, pcy + 55, jura_light(28), WHITE55)

    # Result section
    result_y = photo_bbox[3] + 50
    draw.text((ix0 + 30, result_y), "Estimated Calories", font=jura_med(36), fill=WHITE92)
    text_right(draw, "647 kcal", ix1 - 30, result_y, italiana(44), GOLD)

    # Macro summary bar
    bar_y = result_y + 80
    bar_items = [("P: 42g", GOLD_LIGHT), ("C: 58g", GREEN), ("F: 18g", GOLD)]
    bx = ix0 + 30
    for label, color in bar_items:
        draw_rounded_rect(draw, (bx, bar_y, bx + 200, bar_y + 52), 12, (color[0]//6, color[1]//6, color[2]//6), outline=color)
        text_center_at(draw, label, bx + 100, bar_y + 10, geist(28), color)
        bx += 230

    # Food items list
    list_y = bar_y + 90
    draw_divider(draw, list_y, ix0 + 20, ix1 - 20)

    items = [
        ("Grilled Chicken Breast", "280 kcal", "P 38g  C 2g  F 12g"),
        ("Steamed White Rice", "210 kcal", "P 4g  C 46g  F 0.5g"),
        ("Mixed Green Salad", "87 kcal", "P 3g  C 8g  F 5g"),
        ("Vinaigrette Dressing", "70 kcal", "P 0g  C 2g  F 7g"),
    ]
    for i, (name, kcal, macros) in enumerate(items):
        iy = list_y + 30 + i * 140
        # Item dot
        draw.ellipse((ix0 + 40, iy + 10, ix0 + 56, iy + 26), fill=GOLD)
        draw.text((ix0 + 76, iy), name, font=jura_med(32), fill=WHITE92)
        text_right(draw, kcal, ix1 - 30, iy, geist(30), GOLD_LIGHT)
        draw.text((ix0 + 76, iy + 50, ), macros, font=geist(26), fill=WHITE55)
        if i < len(items) - 1:
            draw.line([(ix0 + 76, iy + 110), (ix1 - 30, iy + 110)], fill=WHITE30, width=1)

    # Confidence badge
    badge_y = list_y + 30 + len(items) * 140 + 20
    badge_w = 340
    badge_x = (W - badge_w) // 2
    draw_rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + 56), 28, (GREEN[0]//8, GREEN[1]//8, GREEN[2]//8), outline=GREEN)
    text_center_at(draw, "Confidence: 94%", W // 2, badge_y + 12, geist(28), GREEN)

    draw_wordmark(draw)
    img.save(os.path.join(OUT_DIR, "screenshot_2.png"))
    print("  Saved screenshot_2.png")


# ===================== SCREENSHOT 3 =====================
def screenshot_3():
    img, draw = new_canvas()
    draw_header(draw, "Smart Pantry & Recipes", "From ingredients to meals, effortlessly")
    inner = draw_phone_frame(draw)
    ix0, iy0, ix1, iy1 = inner

    # Pantry section
    section_y = iy0 + 20
    draw.text((ix0 + 30, section_y), "My Pantry", font=italiana(48), fill=GOLD)

    categories = [
        ("Vegetables", ["Broccoli", "Spinach", "Bell Peppers", "Carrots"]),
        ("Protein", ["Chicken Breast", "Eggs", "Salmon"]),
        ("Dairy", ["Greek Yogurt", "Cheddar Cheese"]),
    ]

    cy = section_y + 80
    for cat_name, items in categories:
        draw.text((ix0 + 30, cy), cat_name, font=jura_med(32), fill=GOLD_LIGHT)
        cy += 50
        # Items as chips
        chip_x = ix0 + 30
        for item in items:
            tbbox = draw.textbbox((0, 0), item, font=geist(24))
            tw = tbbox[2] - tbbox[0]
            chip_w = tw + 36
            if chip_x + chip_w > ix1 - 30:
                cy += 58
                chip_x = ix0 + 30
            draw_rounded_rect(draw, (chip_x, cy, chip_x + chip_w, cy + 46), 23, SURFACE_LIGHT, outline=WHITE30)
            draw.text((chip_x + 18, cy + 10), item, font=geist(24), fill=WHITE92)
            chip_x += chip_w + 14
        cy += 76

    # Divider
    draw_divider(draw, cy, ix0 + 20, ix1 - 20)
    cy += 30

    # Suggested recipe card
    draw.text((ix0 + 30, cy), "Suggested Recipe", font=italiana(48), fill=GOLD)
    cy += 80

    card_bbox = (ix0 + 20, cy, ix1 - 20, cy + 420)
    draw_rounded_rect(draw, card_bbox, 24, SURFACE_LIGHT, outline=WHITE30)

    # Recipe image placeholder
    img_bbox = (card_bbox[0] + 16, card_bbox[1] + 16, card_bbox[0] + 220, card_bbox[1] + 200)
    draw_rounded_rect(draw, img_bbox, 16, (45, 42, 35), outline=GOLD)
    # Fork+knife icon (simplified)
    icx = (img_bbox[0] + img_bbox[2]) // 2
    icy = (img_bbox[1] + img_bbox[3]) // 2
    draw.line([(icx - 15, icy - 40), (icx - 15, icy + 40)], fill=GOLD, width=4)
    draw.line([(icx + 15, icy - 40), (icx + 15, icy + 40)], fill=GOLD, width=4)
    draw.arc((icx + 5, icy - 40, icx + 25, icy - 10), start=180, end=0, fill=GOLD, width=4)

    # Recipe details
    rx = card_bbox[0] + 250
    ry = card_bbox[1] + 30
    draw.text((rx, ry), "Chicken Stir-Fry", font=jura_med(40), fill=WHITE92)
    ry += 60
    draw.text((rx, ry), "with Broccoli & Bell Peppers", font=jura_light(28), fill=WHITE55)

    # Stats row
    ry += 60
    stats = [("450 kcal", GOLD_LIGHT), ("20 min", GREEN), ("Easy", WHITE92)]
    sx = rx
    for stat_text, color in stats:
        tbbox = draw.textbbox((0, 0), stat_text, font=geist(26))
        tw = tbbox[2] - tbbox[0]
        pill_w = tw + 32
        draw_rounded_rect(draw, (sx, ry, sx + pill_w, ry + 44), 22, (color[0]//8, color[1]//8, color[2]//8), outline=color)
        draw.text((sx + 16, ry + 8), stat_text, font=geist(26), fill=color)
        sx += pill_w + 16

    # Macros
    ry += 80
    draw.text((card_bbox[0] + 40, ry), "Protein 38g", font=geist(26), fill=GOLD_LIGHT)
    draw.text((card_bbox[0] + 260, ry), "Carbs 42g", font=geist(26), fill=GREEN)
    draw.text((card_bbox[0] + 460, ry), "Fat 14g", font=geist(26), fill=GOLD)

    # Ingredients match
    ry += 60
    draw_rounded_rect(draw, (card_bbox[0] + 40, ry, card_bbox[0] + 400, ry + 48), 24, (GREEN[0]//8, GREEN[1]//8, GREEN[2]//8), outline=GREEN)
    draw.text((card_bbox[0] + 60, ry + 10), "3/4 ingredients in pantry", font=geist(24), fill=GREEN)

    draw_wordmark(draw)
    img.save(os.path.join(OUT_DIR, "screenshot_3.png"))
    print("  Saved screenshot_3.png")


# ===================== SCREENSHOT 4 =====================
def screenshot_4():
    img, draw = new_canvas()
    draw_header(draw, "Scan Any Menu", "Make informed choices when dining out")
    inner = draw_phone_frame(draw)
    ix0, iy0, ix1, iy1 = inner

    # Menu scanner header
    sy = iy0 + 30
    draw.text((ix0 + 30, sy), "Menu Analysis", font=italiana(48), fill=GOLD)
    sy += 70
    draw.text((ix0 + 30, sy), "The Golden Fork  \u2014  Italian Restaurant", font=jura_light(30), fill=WHITE55)
    sy += 60

    draw_divider(draw, sy, ix0 + 20, ix1 - 20)
    sy += 20

    # Budget indicator
    sy += 10
    draw_rounded_rect(draw, (ix0 + 30, sy, ix1 - 30, sy + 70), 16, SURFACE_LIGHT)
    draw.text((ix0 + 50, sy + 18), "Remaining budget:", font=jura_light(30), fill=WHITE55)
    text_right(draw, "1,847 kcal", ix1 - 50, sy + 16, geist(32), GOLD)
    sy += 100

    # Dishes
    dishes = [
        ("Grilled Salmon\nwith Asparagus & Lemon Butter", "520 kcal", "P 42g  C 12g  F 32g", True, "Fits"),
        ("Truffle Mushroom\nRisotto", "780 kcal", "P 18g  C 86g  F 38g", True, "Fits"),
        ("Tiramisu\nClassic Italian Dessert", "1,420 kcal", "P 12g  C 148g  F 62g", False, "Over"),
    ]

    for i, (name, kcal, macros, fits, badge_text) in enumerate(dishes):
        card_y = sy + i * 340
        card_bbox = (ix0 + 20, card_y, ix1 - 20, card_y + 310)
        border_color = GREEN if fits else RED
        draw_rounded_rect(draw, card_bbox, 20, SURFACE_LIGHT, outline=border_color)

        # Badge
        badge_w = 120
        badge_color = GREEN if fits else RED
        badge_x = card_bbox[2] - badge_w - 20
        badge_y = card_bbox[1] + 20
        draw_rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + 48), 24,
                          (badge_color[0]//6, badge_color[1]//6, badge_color[2]//6), outline=badge_color)
        text_center_at(draw, badge_text, badge_x + badge_w // 2, badge_y + 10, geist(26), badge_color)

        # Dish name
        lines = name.split("\n")
        draw.text((card_bbox[0] + 30, card_bbox[1] + 24), lines[0], font=jura_med(36), fill=WHITE92)
        if len(lines) > 1:
            draw.text((card_bbox[0] + 30, card_bbox[1] + 72), lines[1], font=jura_light(28), fill=WHITE55)

        # Calories
        cal_y = card_bbox[1] + 130
        draw.text((card_bbox[0] + 30, cal_y), kcal, font=italiana(52), fill=GOLD_LIGHT)

        # Macros
        draw.text((card_bbox[0] + 30, cal_y + 75), macros, font=geist(26), fill=WHITE55)

        # Progress bar showing how much of budget this uses
        bar_y = cal_y + 130
        bar_x0 = card_bbox[0] + 30
        bar_x1 = card_bbox[2] - 30
        bar_w = bar_x1 - bar_x0
        draw_rounded_rect(draw, (bar_x0, bar_y, bar_x1, bar_y + 12), 6, WHITE30)
        cal_num = int(kcal.replace(",", "").split()[0])
        fill_frac = min(cal_num / 1847, 1.0)
        fill_w = int(bar_w * fill_frac)
        if fill_w > 0:
            draw_rounded_rect(draw, (bar_x0, bar_y, bar_x0 + fill_w, bar_y + 12), 6, badge_color)

    draw_wordmark(draw)
    img.save(os.path.join(OUT_DIR, "screenshot_4.png"))
    print("  Saved screenshot_4.png")


# ===================== SCREENSHOT 5 =====================
def screenshot_5():
    img, draw = new_canvas()
    draw_header(draw, "Your Health, Connected", "A complete picture of your wellness")
    inner = draw_phone_frame(draw)
    ix0, iy0, ix1, iy1 = inner

    sy = iy0 + 30
    draw.text((ix0 + 30, sy), "Health Overview", font=italiana(48), fill=GOLD)
    sy += 80

    # Stats cards row
    stats = [
        ("BMI", "22.4", "Normal"),
        ("BMR", "1,680", "kcal/day"),
        ("TDEE", "2,520", "kcal/day"),
    ]
    card_w = (ix1 - ix0 - 60) // 3
    for i, (label, value, unit) in enumerate(stats):
        cx0 = ix0 + 20 + i * (card_w + 10)
        cx1 = cx0 + card_w
        draw_rounded_rect(draw, (cx0, sy, cx1, sy + 220), 20, SURFACE_LIGHT, outline=WHITE30)
        # Label
        text_center_at(draw, label, (cx0 + cx1) // 2, sy + 20, geist(28), WHITE55)
        # Value
        text_center_at(draw, value, (cx0 + cx1) // 2, sy + 70, italiana(64), GOLD)
        # Unit
        text_center_at(draw, unit, (cx0 + cx1) // 2, sy + 155, jura_light(24), WHITE55)

    sy += 260

    # Streak section
    draw_divider(draw, sy, ix0 + 20, ix1 - 20)
    sy += 30

    streak_bbox = (ix0 + 20, sy, ix1 - 20, sy + 200)
    draw_rounded_rect(draw, streak_bbox, 20, SURFACE_LIGHT, outline=GOLD)

    # Flame icon (triangle-ish shape)
    flame_cx = ix0 + 140
    flame_cy = sy + 100
    flame_points = [
        (flame_cx, flame_cy - 55),
        (flame_cx + 35, flame_cy + 30),
        (flame_cx + 20, flame_cy + 45),
        (flame_cx - 20, flame_cy + 45),
        (flame_cx - 35, flame_cy + 30),
    ]
    draw.polygon(flame_points, fill=GOLD)
    # Inner flame
    inner_points = [
        (flame_cx, flame_cy - 20),
        (flame_cx + 15, flame_cy + 25),
        (flame_cx - 15, flame_cy + 25),
    ]
    draw.polygon(inner_points, fill=GOLD_LIGHT)

    draw.text((ix0 + 210, sy + 40), "12 Day Streak", font=italiana(56), fill=GOLD)
    draw.text((ix0 + 210, sy + 115), "Keep logging to maintain your streak!", font=jura_light(28), fill=WHITE55)

    sy += 240

    # Weekly activity dots
    draw.text((ix0 + 30, sy), "This Week", font=jura_med(32), fill=WHITE92)
    sy += 55
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    active = [True, True, True, True, True, True, False]  # 6 of 7 active
    dot_spacing = (ix1 - ix0 - 60) // 7
    for i, (day, act) in enumerate(zip(days, active)):
        dx = ix0 + 50 + i * dot_spacing
        color = GOLD if act else WHITE30
        draw.ellipse((dx - 18, sy, dx + 18, sy + 36), fill=color)
        text_center_at(draw, day, dx, sy + 50, geist(22), WHITE55)

    sy += 120

    # Divider
    draw_divider(draw, sy, ix0 + 20, ix1 - 20)
    sy += 30

    # Apple Health sync card
    health_bbox = (ix0 + 20, sy, ix1 - 20, sy + 260)
    draw_rounded_rect(draw, health_bbox, 20, SURFACE_LIGHT, outline=WHITE30)

    draw.text((ix0 + 50, sy + 25), "Apple Health", font=jura_med(38), fill=WHITE92)

    # Sync status badge
    sync_w = 180
    sync_x = ix1 - 50 - sync_w
    draw_rounded_rect(draw, (sync_x, sy + 22, sync_x + sync_w, sy + 68), 23,
                      (GREEN[0]//8, GREEN[1]//8, GREEN[2]//8), outline=GREEN)
    text_center_at(draw, "Synced", sync_x + sync_w // 2, sy + 30, geist(28), GREEN)

    # Health data items
    health_items = [
        ("Active Energy", "487 kcal"),
        ("Steps Today", "8,234"),
        ("Resting Heart Rate", "62 bpm"),
    ]
    hy = sy + 90
    for label, value in health_items:
        draw.text((ix0 + 50, hy), label, font=jura_light(28), fill=WHITE55)
        text_right(draw, value, ix1 - 50, hy, geist(28), WHITE92)
        hy += 52

    draw_wordmark(draw)
    img.save(os.path.join(OUT_DIR, "screenshot_5.png"))
    print("  Saved screenshot_5.png")


# ===================== MAIN =====================
if __name__ == "__main__":
    print("Generating SportsMeal App Store screenshots...")
    screenshot_1()
    screenshot_2()
    screenshot_3()
    screenshot_4()
    screenshot_5()
    print(f"Done! Files saved to {OUT_DIR}")
