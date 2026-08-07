import os
import math
import random
from PIL import Image, ImageDraw

OUTPUT_DIR = "vfx/bombastica/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def create_explosion_core_sheet():
    # 12 frames of 64x64 -> 768x64 sheet
    fw, fh = 64, 64
    num_frames = 12
    sheet = Image.new("RGBA", (fw * num_frames, fh), (0, 0, 0, 0))
    
    # Palette
    c_white = (255, 255, 240, 255)
    c_cyan = (46, 224, 255, 255)
    c_yellow = (255, 220, 60, 255)
    c_orange = (255, 120, 20, 255)
    c_red = (210, 40, 15, 255)
    c_dark_red = (120, 20, 10, 220)
    c_charcoal = (45, 45, 50, 200)
    c_ash = (25, 25, 28, 150)
    
    for f in range(num_frames):
        img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        cx, cy = fw // 2, fh // 2
        
        t = f / float(num_frames - 1)
        
        if f == 0:
            # Frame 0: Tiny white-cyan pinprick
            draw.rectangle([cx - 2, cy - 2, cx + 2, cy + 2], fill=c_white)
            draw.rectangle([cx - 4, cy - 1, cx + 4, cy + 1], fill=c_cyan)
            draw.rectangle([cx - 1, cy - 4, cx + 1, cy + 4], fill=c_cyan)
        elif f == 1:
            # Frame 1: Explosive flash
            r = 14
            for x in range(cx - r, cx + r + 1):
                for y in range(cy - r, cy + r + 1):
                    d = math.hypot(x - cx, y - cy)
                    if d <= r:
                        if d <= r * 0.4:
                            img.putpixel((x, y), c_white)
                        elif d <= r * 0.7:
                            img.putpixel((x, y), c_yellow)
                        else:
                            img.putpixel((x, y), c_orange)
            # Rays
            for angle in [0, 45, 90, 135, 180, 225, 270, 315]:
                rad = math.radians(angle)
                rx = int(cx + math.cos(rad) * 20)
                ry = int(cy + math.sin(rad) * 20)
                draw.line([(cx, cy), (rx, ry)], fill=c_white, width=2)
        elif f in [2, 3, 4, 5]:
            # Main expansion phase with asymmetrical lobes
            progress = (f - 2) / 3.0  # 0.0 to 1.0
            base_r = 16 + progress * 12
            
            # Lobe angles and multipliers (asymmetrical)
            lobes = [(0, 1.2), (0.8, 0.9), (1.6, 1.3), (2.5, 0.85), (3.6, 1.25), (4.7, 1.05), (5.5, 1.15)]
            
            for x in range(0, fw):
                for y in range(0, fh):
                    dx = x - cx
                    dy = y - cy
                    d = math.hypot(dx, dy)
                    ang = (math.atan2(dy, dx) + math.pi * 2) % (math.pi * 2)
                    
                    # Lobe modifier
                    mod = 1.0
                    for la, lm in lobes:
                        diff = abs(ang - la)
                        if diff > math.pi:
                            diff = math.pi * 2 - diff
                        if diff < 0.6:
                            w = (1.0 - diff / 0.6)
                            mod += (lm - 1.0) * w
                    
                    target_r = base_r * mod
                    
                    if d <= target_r:
                        norm_d = d / max(1.0, target_r)
                        if norm_d < 0.25 - progress * 0.15:
                            img.putpixel((x, y), c_white if f < 4 else c_yellow)
                        elif norm_d < 0.5 - progress * 0.1:
                            img.putpixel((x, y), c_yellow if f < 4 else c_orange)
                        elif norm_d < 0.78:
                            img.putpixel((x, y), c_orange if f < 4 else c_red)
                        else:
                            # Edge noise / lobes
                            if (x + y + f) % 3 != 0:
                                img.putpixel((x, y), c_red if f < 5 else c_dark_red)
        elif f in [6, 7, 8]:
            # Fragmentation & charcoal/smoke inner phase
            progress = (f - 6) / 2.0
            base_r = 26 - progress * 4
            
            for x in range(0, fw):
                for y in range(0, fh):
                    dx = x - cx
                    dy = y - cy
                    d = math.hypot(dx, dy)
                    if d <= base_r + (x * 7 + y * 13) % 5:
                        norm_d = d / base_r
                        noise = (x * 11 + y * 17 + f * 5) % 7
                        if norm_d < 0.4:
                            # Charcoal core forming
                            img.putpixel((x, y), c_charcoal if noise > 2 else c_dark_red)
                        elif norm_d < 0.75:
                            img.putpixel((x, y), c_red if noise > 1 else c_orange)
                        else:
                            img.putpixel((x, y), c_dark_red if noise > 2 else (0, 0, 0, 0))
        elif f in [9, 10]:
            # Disintegrating embers and smoke
            progress = (f - 9) / 1.0
            for x in range(0, fw):
                for y in range(0, fh):
                    dx = x - cx
                    dy = y - cy
                    d = math.hypot(dx, dy)
                    if d <= 22 - progress * 6:
                        noise = (x * 13 + y * 19 + f * 7) % 9
                        if noise == 0:
                            img.putpixel((x, y), c_orange)
                        elif noise == 1:
                            img.putpixel((x, y), c_dark_red)
                        elif noise in [2, 3]:
                            img.putpixel((x, y), c_ash)
        # f == 11 remains transparent
        
        sheet.paste(img, (f * fw, 0))
        
    sheet.save(os.path.join(OUTPUT_DIR, "explosion_core_sheet.png"))
    print("Created explosion_core_sheet.png")

def create_smoke_flipbook_sheet():
    # 6 frames of 32x32 -> 192x32 sheet
    fw, fh = 32, 32
    num_frames = 6
    sheet = Image.new("RGBA", (fw * num_frames, fh), (0, 0, 0, 0))
    
    c_dark_gray = (50, 52, 58, 220)
    c_mid_gray = (90, 94, 102, 180)
    c_light_gray = (140, 145, 155, 130)
    c_warm_rim = (200, 100, 30, 200)
    
    for f in range(num_frames):
        img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        cx, cy = fw // 2, fh // 2
        r = 4 + f * 4
        
        for x in range(0, fw):
            for y in range(0, fh):
                dx = x - cx
                dy = y - cy
                d = math.hypot(dx, dy)
                n = (x * 7 + y * 11 + f * 13) % 5
                
                # Asymmetric smoke puff lobes
                l_mod = 1.0 + math.sin(math.atan2(dy, dx) * 3 + f) * 0.2
                tr = r * l_mod
                
                if d <= tr + n:
                    norm_d = d / max(1.0, tr)
                    if f == 0:
                        img.putpixel((x, y), c_warm_rim if norm_d > 0.6 else c_dark_gray)
                    elif f in [1, 2]:
                        if norm_d > 0.8:
                            img.putpixel((x, y), c_warm_rim if f == 1 else c_dark_gray)
                        elif norm_d > 0.4:
                            img.putpixel((x, y), c_dark_gray)
                        else:
                            img.putpixel((x, y), c_mid_gray)
                    elif f in [3, 4]:
                        alpha = max(0, int(180 - f * 35))
                        col = (c_mid_gray[0], c_mid_gray[1], c_mid_gray[2], alpha) if norm_d < 0.6 else (c_light_gray[0], c_light_gray[1], c_light_gray[2], alpha // 2)
                        if n > 0:
                            img.putpixel((x, y), col)
                    # f == 5 is almost faded out wisps
                    elif f == 5:
                        if n == 1:
                            img.putpixel((x, y), (140, 145, 155, 60))
                            
        sheet.paste(img, (f * fw, 0))
        
    sheet.save(os.path.join(OUTPUT_DIR, "smoke_flipbook_sheet.png"))
    print("Created smoke_flipbook_sheet.png")

def create_flame_mini_sheet():
    # 6 frames of 16x16 -> 96x16 sheet
    fw, fh = 16, 16
    num_frames = 6
    sheet = Image.new("RGBA", (fw * num_frames, fh), (0, 0, 0, 0))
    
    c_y = (255, 230, 80, 255)
    c_o = (255, 130, 20, 255)
    c_r = (210, 40, 15, 255)
    
    for f in range(num_frames):
        img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Flame shape dancing
        h = 8 + (f % 3) * 2
        w = 6 + (f % 2) * 2
        cx = 8
        
        draw.ellipse([cx - w//2, 14 - h, cx + w//2, 14], fill=c_r)
        draw.ellipse([cx - w//2 + 1, 14 - h + 2, cx + w//2 - 1, 13], fill=c_o)
        draw.rectangle([cx - 1, 12 - h//2, cx + 1, 13], fill=c_y)
        
        sheet.paste(img, (f * fw, 0))
        
    sheet.save(os.path.join(OUTPUT_DIR, "flame_mini_sheet.png"))
    print("Created flame_mini_sheet.png")

def create_particle_textures():
    # Spark: 4x4 px line
    spark = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(spark)
    draw.rectangle([0, 1, 3, 2], fill=(255, 255, 200, 255))
    draw.rectangle([1, 1, 2, 2], fill=(255, 255, 255, 255))
    spark.save(os.path.join(OUTPUT_DIR, "spark_texture.png"))
    
    # Ember: 4x4 px irregular fragment
    ember = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    ember.putpixel((1, 1), (255, 220, 60, 255))
    ember.putpixel((2, 1), (255, 140, 20, 255))
    ember.putpixel((1, 2), (230, 60, 15, 255))
    ember.putpixel((2, 2), (255, 180, 40, 255))
    ember.save(os.path.join(OUTPUT_DIR, "ember_texture.png"))
    
    # Debris: 6x6 px dark rock/metal fragment
    debris = Image.new("RGBA", (6, 6), (0, 0, 0, 0))
    draw = ImageDraw.Draw(debris)
    draw.rectangle([1, 1, 4, 4], fill=(40, 42, 48, 255))
    draw.rectangle([2, 2, 3, 3], fill=(70, 72, 80, 255))
    debris.putpixel((1, 1), (20, 20, 22, 255))
    debris.save(os.path.join(OUTPUT_DIR, "debris_texture.png"))
    
    # Quantum spark: 4x4 cyan fragment
    q_spark = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(q_spark)
    draw.rectangle([0, 1, 3, 2], fill=(46, 224, 255, 255))
    draw.rectangle([1, 1, 2, 2], fill=(220, 250, 255, 255))
    q_spark.save(os.path.join(OUTPUT_DIR, "quantum_spark.png"))
    
    print("Created particle textures")

def create_scorch_decals():
    # 3 variations of 48x48 scorch marks
    for idx in range(1, 4):
        img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        cx, cy = 24, 24
        
        c_core = (18, 18, 20, 230)
        c_mid = (35, 30, 28, 190)
        c_edge = (60, 25, 18, 140)
        c_soot = (25, 25, 25, 90)
        
        r_max = 18 + idx * 2
        
        for x in range(0, 48):
            for y in range(0, 48):
                dx = x - cx
                dy = y - cy
                d = math.hypot(dx, dy)
                ang = math.atan2(dy, dx)
                
                # Asymmetry per idx
                mod = 1.0 + math.sin(ang * (3 + idx) + idx * 1.5) * 0.25 + math.cos(ang * 2) * 0.15
                tr = r_max * mod
                
                noise = (x * 13 + y * 19 + idx * 29) % 7
                
                if d <= tr + noise:
                    norm_d = d / max(1.0, tr)
                    if norm_d < 0.4:
                        img.putpixel((x, y), c_core)
                    elif norm_d < 0.7:
                        img.putpixel((x, y), c_mid)
                    elif norm_d < 0.95:
                        img.putpixel((x, y), c_edge)
                    else:
                        if noise > 2:
                            img.putpixel((x, y), c_soot)
                            
        img.save(os.path.join(OUTPUT_DIR, f"scorch_0{idx}.png"))
        print(f"Created scorch_0{idx}.png")

if __name__ == "__main__":
    create_explosion_core_sheet()
    create_smoke_flipbook_sheet()
    create_flame_mini_sheet()
    create_particle_textures()
    create_scorch_decals()
