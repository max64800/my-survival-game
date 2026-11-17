"""Puts a zone's cave plan (from export_zone.gd) into the 3D map page, so it opens straight from disk in a browser.
   python tools/cave_map/make_map.py <zone.json> <out.html>
"""
import sys
from pathlib import Path

here = Path(__file__).parent
data = Path(sys.argv[1]).read_text(encoding="utf-8")
page = (here / "map_template.html").read_text(encoding="utf-8").replace("/*DATA*/null", data)
Path(sys.argv[2]).write_text(page, encoding="utf-8")
print("wrote", sys.argv[2])
