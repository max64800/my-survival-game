"""Builds the Crafting Wiki page (one HTML file, pictures inside) from dump.gd's JSON.

    python tools/craft_wiki/build.py <wiki.json> <out.html>
"""
import base64
import io
import json
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ICONS = HERE.parent.parent / "assets" / "icons"


def icon_data(item_id):
    p = ICONS / f"{item_id}.png"
    if not p.exists():
        return None
    im = Image.open(p).convert("RGBA").resize((72, 72), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "WEBP", quality=82, method=6)
    return "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()


def main():
    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    icons = {}
    for item_id in data["items"]:
        d = icon_data(item_id)
        if d:
            icons[item_id] = d
    data["icons"] = icons
    template = (HERE / "page.html").read_text(encoding="utf-8")
    blob = json.dumps(data, separators=(",", ":"), ensure_ascii=False).replace("</", "<\\/")
    Path(sys.argv[2]).write_text(template.replace("/*__DATA__*/null", blob), encoding="utf-8")
    print(f"wrote {sys.argv[2]}: {len(data['recipes'])} recipes, {len(icons)} pictures, "
          f"{Path(sys.argv[2]).stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
