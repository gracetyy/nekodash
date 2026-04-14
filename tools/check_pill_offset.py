from PIL import Image

def get_top_offset(path):
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    for y in range(height):
        for x in range(width):
            _, _, _, a = img.getpixel((x, y))
            if a > 0:
                return y
    return height

def get_bottom_offset(path):
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    for y in range(height-1, -1, -1):
        for x in range(width):
            _, _, _, a = img.getpixel((x, y))
            if a > 0:
                return height - 1 - y
    return height

print("Normal Top Offset:", get_top_offset("assets/art/ui/buttons/pill_bases/pill_primary_normal.png"))
print("Pressed Top Offset:", get_top_offset("assets/art/ui/buttons/pill_bases/pill_primary_pressed.png"))
print("Normal Bottom Offset:", get_bottom_offset("assets/art/ui/buttons/pill_bases/pill_primary_normal.png"))
print("Pressed Bottom Offset:", get_bottom_offset("assets/art/ui/buttons/pill_bases/pill_primary_pressed.png"))
