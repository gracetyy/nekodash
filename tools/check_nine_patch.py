from PIL import Image

def analyze_image(path, name, expected_size, nine_patch):
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
        width, height = img.size
        print(f"\n--- {name} ---")
        print(f"File: {path}")
        print(f"Actual Size: {width}x{height} (Expected: {expected_size})")
        
        # Check margins if nine_patch provided
        if nine_patch:
            # typical format: L, T, R, B
            L, T, R, B = nine_patch
            
            print(f"Nine-Patch Spec: Left={L}, Top={T}, Right={R}, Bottom={B}")
            stretch_w = width - L - R
            stretch_h = height - T - B
            print(f"Stretchable Center Region: Width={stretch_w}, Height={stretch_h}")
            
            if stretch_w < 1 or stretch_h < 1:
                print("WARNING: Stretch region is <= 0!")
            else:
                c_pix = img.getpixel((L, T))
                print(f"Sample pixel at Top-Left of stretch region ({L}, {T}): {c_pix}")
                
                # Check horizontal consistency in the stretch region
                if stretch_w > 1:
                    row_colors = [img.getpixel((L + i, T)) for i in range(stretch_w)]
                    same_color = len(set(row_colors)) == 1
                    print(f"Is stretchable top row uniform color? {same_color}")

                if stretch_h > 1:
                    col_colors = [img.getpixel((L, T + i)) for i in range(stretch_h)]
                    same_color = len(set(col_colors)) == 1
                    print(f"Is stretchable left column uniform color? {same_color}")
                
    except Exception as e:
        print(f"Error reading {path}: {e}")

analyze_image("assets/art/ui/panels/panel_modal_normal.png", "Panel Modal Normal", "128x128", (44, 44, 54, 54))
analyze_image("assets/art/ui/panels/panel_tooltip_bubble.png", "Panel Tooltip Bubble", "59x73", (15, 15, 18, 26))
analyze_image("assets/art/ui/world_map/level_card_unlocked.png", "Level Card Unlocked", "72x90", (26, 26, 26, 44))
analyze_image("assets/art/ui/buttons/pill_bases/pill_primary_normal.png", "Pill Primary Normal", "220x60", (56, 0, 56, 0))
