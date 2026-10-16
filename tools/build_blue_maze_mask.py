"""Bake the marked walkable area from the Act 2 layout into grid cells."""

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
IMAGE = ROOT / "Reference photos" / "tube maze top down layout.png"
OUTPUT = ROOT / "scripts" / "maze_blue_cells.json"
ENDPOINTS = ROOT / "scripts" / "maze_yellow_endpoints.json"
GRID = 0.4
MIN_X, MIN_Z = -42.0, -31.2
ORIGIN_X, ORIGIN_Y = 830.0, 408.0
PIXELS_PER_METRE = 13.0


def is_blue(pixel: tuple[int, int, int]) -> bool:
    red, green, blue = pixel
    return red <= 175 and 55 <= green <= 210 and blue >= 130 and blue - red >= 35 and blue - green >= 20


def main() -> None:
    image = Image.open(IMAGE).convert("RGB")
    cells: list[list[int]] = []
    for x in range(210):
        for z in range(160):
            world_x = MIN_X + x * GRID
            world_z = MIN_Z + z * GRID
            px = round(ORIGIN_X + world_x * PIXELS_PER_METRE)
            py = round(ORIGIN_Y + world_z * PIXELS_PER_METRE)
            if 0 <= px < image.width and 0 <= py < image.height and is_blue(image.getpixel((px, py))):
                cells.append([x, z])
    OUTPUT.write_text(json.dumps({"cells": cells}, separators=(",", ":")), encoding="utf-8")
    remaining = {tuple(cell) for cell in cells}
    regions: list[set[tuple[int, int]]] = []
    while remaining:
        stack = [remaining.pop()]
        region = {stack[0]}
        while stack:
            x, z = stack.pop()
            for adjacent in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
                if adjacent in remaining:
                    remaining.remove(adjacent)
                    region.add(adjacent)
                    stack.append(adjacent)
        if len(region) >= 400:
            regions.append(region)
    result = Image.new("RGB", (840, 640), "white")
    draw = ImageDraw.Draw(result)
    colors = [(235, 70, 60), (75, 155, 215), (70, 185, 95), (240, 185, 55), (165, 90, 210)]
    for index, region in enumerate(regions):
        for x, z in region:
            draw.rectangle((x * 4, z * 4, x * 4 + 3, z * 4 + 3), fill=colors[index % len(colors)])
        center_x = round(sum(x for x, _ in region) / len(region)) * 4
        center_z = round(sum(z for _, z in region) / len(region)) * 4
        draw.text((center_x, center_z), str(index), fill="black", stroke_width=2, stroke_fill="white")
    result.save(ROOT / "reviews" / "blue-zones.png")
    yellow: set[tuple[int, int]] = set()
    for py in range(image.height):
        for px in range(image.width):
            red, green, blue = image.getpixel((px, py))
            if red >= 225 and green >= 185 and blue <= 195 and red - blue >= 35:
                yellow.add((px, py))
    endpoints: list[list[float]] = []
    while yellow:
        stack = [yellow.pop()]
        region = [stack[0]]
        while stack:
            px, py = stack.pop()
            for adjacent in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                if adjacent in yellow:
                    yellow.remove(adjacent)
                    region.append(adjacent)
                    stack.append(adjacent)
        if len(region) < 70:
            continue
        center_x = sum(px for px, _ in region) / len(region)
        center_y = sum(py for _, py in region) / len(region)
        endpoints.append([round((center_x - ORIGIN_X) / PIXELS_PER_METRE, 2), round((center_y - ORIGIN_Y) / PIXELS_PER_METRE, 2)])
    ENDPOINTS.write_text(json.dumps({"points": endpoints}, separators=(",", ":")), encoding="utf-8")
    print(f"Found {len(endpoints)} yellow endpoint marks")
    print(f"Wrote {len(cells)} blue corridor cells to {OUTPUT}")


if __name__ == "__main__":
    main()
