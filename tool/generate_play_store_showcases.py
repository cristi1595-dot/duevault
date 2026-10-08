import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE_DIR = r"d:\Aplicatii\DueVault_app"
ASSETS_DIR = os.path.join(BASE_DIR, "play_store_assets")
FONT_BOLD = os.path.join(BASE_DIR, "google_fonts", "Inter-Bold.ttf")
FONT_REGULAR = os.path.join(BASE_DIR, "google_fonts", "Inter-Medium.ttf")
APP_ICON_PATH = os.path.join(BASE_DIR, "assets", "images", "app icon.png")

def create_showcase(screenshot_path, output_path, title, subtitle):
    # Canvas: 1080 x 2400 (aspect ratio 9:20 - standard Google Play phone)
    W, H = 1080, 2400
    img = Image.new("RGBA", (W, H), (11, 15, 23, 255))
    draw = ImageDraw.Draw(img)

    # 1. Subtle radial/glow background
    # Gradient overlay: dark navy to deep slate
    for y in range(H):
        ratio = y / H
        r = int(11 * (1 - ratio) + 15 * ratio)
        g = int(15 * (1 - ratio) + 23 * ratio)
        b = int(23 * (1 - ratio) + 38 * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Decorative neon glow circle near top-center
    glow_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    glow_draw.ellipse([W//2 - 350, 150, W//2 + 350, 750], fill=(16, 185, 129, 30))
    glow_draw.ellipse([W//2 - 250, 250, W//2 + 250, 650], fill=(59, 130, 246, 25))
    glow_overlay = glow_overlay.filter(ImageFilter.GaussianBlur(100))
    img.paste(glow_overlay, (0, 0), glow_overlay)

    # 2. Typography
    font_title = ImageFont.truetype(FONT_BOLD, 54)
    font_sub = ImageFont.truetype(FONT_REGULAR, 30)

    # Measure text
    title_bbox = draw.textbbox((0, 0), title, font=font_title)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((W - title_w) // 2, 140), title, font=font_title, fill=(255, 255, 255, 255))

    sub_bbox = draw.textbbox((0, 0), subtitle, font=font_sub)
    sub_w = sub_bbox[2] - sub_bbox[0]
    draw.text(((W - sub_w) // 2, 220), subtitle, font=font_sub, fill=(148, 163, 184, 255))

    # 3. Phone device mockup frame
    # Screenshot aspect ratio is 1344 x 2992
    screen = Image.open(screenshot_path).convert("RGBA")
    
    # Target phone screen dimensions on canvas
    target_sw = 860
    target_sh = int(target_sw * (2992 / 1344)) # approx 1914
    screen_resized = screen.resize((target_sw, target_sh), Image.Resampling.LANCZOS)

    # Phone Bezel / Frame
    bezel_padding = 16
    frame_w = target_sw + bezel_padding * 2
    frame_h = target_sh + bezel_padding * 2
    frame_x = (W - frame_w) // 2
    frame_y = 330

    # Phone Shadow
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [frame_x - 10, frame_y + 10, frame_x + frame_w + 10, frame_y + frame_h + 30],
        radius=56,
        fill=(0, 0, 0, 160)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    img.paste(shadow, (0, 0), shadow)

    # Phone Outer Titanium Bezel
    bezel_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bezel_draw = ImageDraw.Draw(bezel_layer)
    bezel_draw.rounded_rectangle(
        [frame_x, frame_y, frame_x + frame_w, frame_y + frame_h],
        radius=52,
        fill=(30, 41, 59, 255),
        outline=(71, 85, 105, 255),
        width=3
    )
    img.paste(bezel_layer, (0, 0), bezel_layer)

    # Screen with rounded corners
    mask = Image.new("L", (target_sw, target_sh), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, target_sw, target_sh], radius=40, fill=255)

    screen_x = frame_x + bezel_padding
    screen_y = frame_y + bezel_padding
    img.paste(screen_resized, (screen_x, screen_y), mask)

    # Save output
    img.convert("RGB").save(output_path, "JPEG", quality=95)
    print(f"Created showcase: {output_path}")

def create_feature_graphic(screenshot_path, output_path):
    # 1024 x 500 px banner
    W, H = 1024, 500
    img = Image.new("RGBA", (W, H), (11, 15, 23, 255))
    draw = ImageDraw.Draw(img)

    # Gradient background
    for x in range(W):
        ratio = x / W
        r = int(11 * (1 - ratio) + 19 * ratio)
        g = int(15 * (1 - ratio) + 26 * ratio)
        b = int(26 * (1 - ratio) + 43 * ratio)
        draw.line([(x, 0), (x, H)], fill=(r, g, b))

    # Glows
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([80, 50, 400, 370], fill=(16, 185, 129, 35))
    gdraw.ellipse([600, 100, 1000, 500], fill=(59, 130, 246, 30))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    img.paste(glow, (0, 0), glow)

    # Left Column: App Icon + Branding + Tagline
    icon = Image.open(APP_ICON_PATH).convert("RGBA")
    icon_size = 96
    icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    icon_mask = Image.new("L", (icon_size, icon_size), 0)
    ImageDraw.Draw(icon_mask).rounded_rectangle([0, 0, icon_size, icon_size], radius=24, fill=255)
    img.paste(icon, (80, 80), icon_mask)

    font_title = ImageFont.truetype(FONT_BOLD, 46)
    font_sub = ImageFont.truetype(FONT_REGULAR, 20)
    font_tagline = ImageFont.truetype(FONT_BOLD, 26)
    font_badge = ImageFont.truetype(FONT_BOLD, 14)

    draw.text((195, 92), "DueVault", font=font_title, fill=(255, 255, 255))
    draw.text((195, 150), "Smart Financial & Document Vault", font=font_sub, fill=(148, 163, 184))

    draw.text((80, 220), "Never Miss a Bill or Expiry Date.", font=font_tagline, fill=(241, 245, 249))

    # Badges
    badges = ["100% Private", "Smart Alerts", "Google Drive Sync"]
    bx = 80
    by = 285
    for b in badges:
        bw = draw.textlength(b, font=font_badge) + 24
        draw.rounded_rectangle([bx, by, bx + bw, by + 34], radius=17, fill=(30, 41, 59, 220), outline=(51, 65, 85))
        draw.text((bx + 12, by + 8), b, font=font_badge, fill=(226, 232, 240))
        bx += bw + 12

    # Right Column: Real Phone Screen Showcase (Tilted/Sleek crop)
    screen = Image.open(screenshot_path).convert("RGBA")
    sw, sh = 420, int(420 * (2992 / 1344))
    screen = screen.resize((sw, sh), Image.Resampling.LANCZOS)

    screen_mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(screen_mask).rounded_rectangle([0, 0, sw, sh], radius=32, fill=255)

    # Place phone mockup on right side
    px, py = 590, 60
    # Shadow
    pshadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(pshadow).rounded_rectangle([px - 10, py, px + sw + 10, py + sh], radius=36, fill=(0, 0, 0, 180))
    pshadow = pshadow.filter(ImageFilter.GaussianBlur(30))
    img.paste(pshadow, (0, 0), pshadow)

    # Frame
    pframe = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(pframe).rounded_rectangle([px - 8, py - 8, px + sw + 8, py + sh + 8], radius=38, fill=(30, 41, 59), outline=(71, 85, 105), width=2)
    img.paste(pframe, (0, 0), pframe)

    img.paste(screen, (px, py), screen_mask)

    img.convert("RGB").save(output_path, "JPEG", quality=95)
    print(f"Created feature graphic: {output_path}")

if __name__ == "__main__":
    home_screen = os.path.join(ASSETS_DIR, "real_1_home.png")
    bills_screen = os.path.join(ASSETS_DIR, "real_2_bills.png")
    docs_screen = os.path.join(ASSETS_DIR, "real_3_documents.png")
    settings_screen = os.path.join(ASSETS_DIR, "real_4_settings.png")

    # 1. Feature Graphic (1024x500)
    create_feature_graphic(home_screen, os.path.join(ASSETS_DIR, "2_feature_graphic_1024x500.jpg"))

    # 2. Promotional Showcase Screenshots (1080x2400)
    create_showcase(
        home_screen,
        os.path.join(ASSETS_DIR, "3_showcase_1_dashboard.jpg"),
        "SMART VAULT OVERVIEW",
        "Track bills & documents in a unified Bento grid"
    )

    create_showcase(
        bills_screen,
        os.path.join(ASSETS_DIR, "4_showcase_2_bills.jpg"),
        "NEVER MISS A BILL",
        "Urgency alerts, due dates & auto-pay tracking"
    )

    create_showcase(
        docs_screen,
        os.path.join(ASSETS_DIR, "5_showcase_3_documents.jpg"),
        "SECURE DOCUMENT SAFE",
        "IDs, passports & contracts with expiry alerts"
    )

    create_showcase(
        settings_screen,
        os.path.join(ASSETS_DIR, "6_showcase_4_security.jpg"),
        "100% PRIVATE & SECURE",
        "Biometric lock with encrypted Google Drive backup"
    )
