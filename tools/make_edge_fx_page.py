"""Builds the 3D preview page of the screen-edge looks (F799/F802) from the game's own shader.

Copies everything between "// --- shared ---" and "// --- end shared ---" in
src/ui/screen_edge_flash.gdshader into tools/edge_fx_page_template.html, so the page always matches the game.
Usage: python3 tools/make_edge_fx_page.py <output.html>
"""
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
shader = (root / "src/ui/screen_edge_flash.gdshader").read_text(encoding="utf-8")
shared = shader.split("// --- shared ---", 1)[1].split("// --- end shared ---", 1)[0]
page = (root / "tools/edge_fx_page_template.html").read_text(encoding="utf-8")
assert "/*EDGE_FX*/" in page
out = page.replace("/*EDGE_FX*/", shared.replace("`", "").replace("\\", "\\\\"))
pathlib.Path(sys.argv[1]).write_text(out, encoding="utf-8")
print("wrote", sys.argv[1])
