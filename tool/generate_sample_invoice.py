import os
from PIL import Image, ImageDraw, ImageFont

def generate_invoice(output_path):
    W, H = 800, 1100
    img = Image.new("RGB", (W, H), (248, 250, 252))
    draw = ImageDraw.Draw(img)

    # Fonts
    font_dir = r"d:\Aplicatii\DueVault_app\google_fonts"
    font_bold_path = os.path.join(font_dir, "Inter-Bold.ttf")
    font_reg_path = os.path.join(font_dir, "Inter-Medium.ttf")
    
    font_h1 = ImageFont.truetype(font_bold_path, 32)
    font_h2 = ImageFont.truetype(font_bold_path, 22)
    font_body = ImageFont.truetype(font_reg_path, 18)
    font_body_bold = ImageFont.truetype(font_bold_path, 18)
    font_sm = ImageFont.truetype(font_reg_path, 14)
    font_total = ImageFont.truetype(font_bold_path, 34)

    # Document border / sheet margin
    draw.rounded_rectangle([20, 20, W - 20, H - 20], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)

    # Header Banner
    draw.rounded_rectangle([40, 40, W - 40, 140], radius=12, fill=(15, 23, 42)) # Slate 900
    # Emerald accent bar
    draw.rounded_rectangle([40, 40, 56, 140], radius=6, fill=(16, 185, 129))

    draw.text((75, 58), "NATIONAL GRID", font=font_h1, fill=(255, 255, 255))
    draw.text((75, 98), "ELECTRIC SERVICE STATEMENT • MONTHLY BILL", font=font_sm, fill=(148, 163, 184))

    # Statement Details Box
    draw.text((50, 170), "Statement Date: Oct 02, 2026", font=font_body, fill=(71, 85, 105))
    draw.text((50, 200), "Account Number: 8492-3011-948", font=font_body_bold, fill=(15, 23, 42))
    draw.text((50, 230), "Address: 742 Evergreen Terr.", font=font_body, fill=(71, 85, 105))

    # Due date badge on the right
    draw.rounded_rectangle([W - 320, 170, W - 50, 260], radius=10, fill=(254, 242, 242), outline=(254, 202, 202), width=1)
    draw.text((W - 300, 185), "DUE DATE", font=font_sm, fill=(220, 38, 38))
    draw.text((W - 300, 210), "October 12, 2026", font=font_h2, fill=(185, 28, 28))

    # Divider
    draw.line([(50, 280), (W - 50, 280)], fill=(226, 232, 240), width=2)

    # Charges Breakdown Table Header
    draw.rounded_rectangle([50, 300, W - 50, 345], radius=8, fill=(241, 245, 249))
    draw.text((70, 312), "DESCRIPTION", font=font_body_bold, fill=(71, 85, 105))
    draw.text((W - 170, 312), "AMOUNT", font=font_body_bold, fill=(71, 85, 105))

    # Table Rows
    rows = [
        ("Base Delivery Service (Electric Grid Maintenance)", "$38.50"),
        ("Energy Distribution Rate (Meter #99402)", "$15.70"),
        ("Electric Supply Charges (412 kWh @ $0.1483)", "$61.10"),
        ("Clean Energy Transition Surcharge", "$4.20"),
        ("State & Local Regulatory Taxes", "$5.90"),
    ]

    y = 370
    for desc, amt in rows:
        draw.text((70, y), desc, font=font_body, fill=(51, 65, 85))
        amt_w = draw.textlength(amt, font=font_body_bold)
        draw.text((W - 70 - amt_w, y), amt, font=font_body_bold, fill=(15, 23, 42))
        y += 50
        draw.line([(70, y - 10), (W - 70, y - 10)], fill=(241, 245, 249), width=1)

    # Total Box
    draw.rounded_rectangle([50, 640, W - 50, 750], radius=12, fill=(248, 250, 252), outline=(203, 213, 225), width=2)
    draw.text((80, 665), "TOTAL AMOUNT DUE", font=font_h2, fill=(100, 116, 139))
    draw.text((80, 700), "Payable to National Grid LLC", font=font_sm, fill=(148, 163, 184))

    total_str = "$125.40"
    total_w = draw.textlength(total_str, font=font_total)
    draw.text((W - 80 - total_w, 672), total_str, font=font_total, fill=(16, 185, 129))

    # Notes section
    draw.rounded_rectangle([50, 780, W - 50, 890], radius=10, fill=(248, 250, 252))
    draw.text((70, 795), "PAYMENT INSTRUCTIONS & REMARKS", font=font_sm, fill=(100, 116, 139))
    draw.text((70, 825), "Auto-pay is not scheduled. Please process payment before Oct 12.", font=font_body, fill=(51, 65, 85))
    draw.text((70, 855), "Online: nationalgrid.com/pay • Phone: 1-800-322-3223", font=font_body, fill=(71, 85, 105))

    # Mock Barcode at bottom
    bx = 100
    by = 940
    import random
    rng = random.Random(42)
    while bx < W - 100:
        bar_w = rng.choice([2, 3, 5, 7])
        gap = rng.choice([2, 4, 6])
        draw.rectangle([bx, by, bx + bar_w, by + 65], fill=(30, 41, 59))
        bx += bar_w + gap

    draw.text((W // 2 - 120, 1020), "* 8 4 9 2 3 0 1 1 9 4 8 0 1 2 5 4 0 *", font=font_sm, fill=(148, 163, 184))

    img.save(output_path, "JPEG", quality=95)
    print(f"Generated sample invoice: {output_path}")

if __name__ == "__main__":
    out = os.path.join(r"d:\Aplicatii\DueVault_app\play_store_assets", "sample_invoice.jpg")
    generate_invoice(out)
