"""Pictures of the pose file's key poses from the front (like the owner's video) and from behind (the game camera),
for the picture sheets (F389, chat 10). Controls and labels hidden. Doesn't change the file.
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/render_poses.py -- <out dir> <frame> [frame...]
Writes <out dir>/f<frame>_front.png and f<frame>_back.png.
"""
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
OUT, FRAMES = args[0], [int(a) for a in args[1:]]
sc = bpy.context.scene
for o in bpy.data.objects:
    if o.name.startswith("label "):
        o.animation_data_clear()  # (the labels' show/hide is keyed per frame; the controls' keys must stay!)
    if o.name in bpy.data.collections["CONTROLS"].objects or o.name.startswith("label "):
        o.hide_render = True
sc.render.engine = "BLENDER_EEVEE"
sc.render.resolution_x, sc.render.resolution_y = 520, 680
sc.render.film_transparent = False
w = sc.world or bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.80, 0.76, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sc.collection.objects.link(sun)
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(25))
# a floor grid line so the knee bend reads
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.lens = 40


def look(frm, at):
    cam.location = frm
    d = (Vector(at) - Vector(frm)).normalized()
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


for f in FRAMES:
    sc.frame_set(f)
    for view, frm, at in (("front", (0, -2.6, 0.8), (0, 0, 0.7)), ("back", (0, 2.4, 1.35), (0, 0, 0.62))):
        look(frm, at)
        sc.render.filepath = "%s/f%02d_%s.png" % (OUT, f, view)
        bpy.ops.render.render(write_still=True)
print("RENDERED", FRAMES)
