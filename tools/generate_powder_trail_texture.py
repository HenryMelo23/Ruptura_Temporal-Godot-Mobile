import os
import math
import random
from PIL import Image, ImageDraw

OUTPUT_DIR = "vfx/bombastica/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def create_powder_trail_texture():
    # 64x18 px tileable pixel art powder trail texture
    w, h = 64, 18
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    
    c_dark_charcoal = (30, 32, 36, 230)
    c_soot = (20, 20, 22, 210)
    c_ash = (45, 48, 52, 180)
    c_ember = (255, 130, 20, 240)
    c_cyan = (46, 224, 255, 220)
    
    for x in range(w):
        for y in range(h):
            # Center weighting with irregular edge noise
            dy = abs(y - h // 2)
            edge_noise = (x * 13 + y * 17) % 5
            max_y = (h // 2 - 1) + edge_noise * 0.4
            
            if dy <= max_y:
                n = (x * 11 + y * 19) % 7
                if dy <= 3:
                    # Core powder stream
                    if n == 0:
                        img.putpixel((x, y), c_ember)
                    elif n == 1 and x % 16 == 0:
                        img.putpixel((x, y), c_cyan)
                    elif n in [2, 3]:
                        img.putpixel((x, y), c_soot)
                    else:
                        img.putpixel((x, y), c_dark_charcoal)
                else:
                    # Irregular edges
                    if n > 2:
                        img.putpixel((x, y), c_ash if n == 3 else c_dark_charcoal)
                        
    img.save(os.path.join(OUTPUT_DIR, "powder_trail_texture.png"))
    print("Created powder_trail_texture.png")

if __name__ == "__main__":
    create_powder_trail_texture()
