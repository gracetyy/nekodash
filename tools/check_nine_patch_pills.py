from PIL import Image
import os
import glob

def analyze_pill(path, L, R):
    try:
        img = Image.open(path).convert("RGBA")
        width, height = img.size
        
        stretch_w = width - L - R
        if stretch_w < 1:
            print(f"FAIL: {path} - invalid stretch width. Size={width}x{height}, L={L}, R={R}")
            return
            
        # check middle row (height//2) for horizontal consistency
        y = height // 2
        colors = [img.getpixel((L + i, y)) for i in range(stretch_w)]
        is_uniform = len(set(colors)) == 1
        
        status = "PASS" if is_uniform else "FAIL"
        print(f"[{status}] {os.path.basename(path):<30} | Size: {width}x{height:<3} | L={L:<3}, R={R:<3} | Stretch Width: {stretch_w:<3} | Uniform: {is_uniform}")
    except Exception as e:
        print(f"Error reading {path}: {e}")

pill_dir = "assets/art/ui/buttons/pill_bases/"
files = sorted(glob.glob(os.path.join(pill_dir, "*.png")))
for file in files:
    if "@2x" in file:
        analyze_pill(file, 112, 112)
    else:
        analyze_pill(file, 56, 56)
