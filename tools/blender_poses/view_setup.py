"""Opens the pose file in Blender WITH its window (run once after make_pose_file.py): sets the view the owner starts
with (from behind him, like the game camera, textures on), takes the guide's pictures, saves the file and quits.
  blender --window-geometry 0 0 1600 900 <made.blend> --python tools/blender_poses/view_setup.py -- <pictures dir> <out.blend>
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import bpy
import math
import sys
from mathutils import Euler

args = sys.argv[sys.argv.index("--") + 1:]
PICS, OUT = args[0], args[1]
FRAMES = [1, 11, 21, 31, 41]


def view3d():
    for area in bpy.context.window.screen.areas:
        if area.type == "VIEW_3D":
            return area
    return None


def setup():
    area = view3d()
    sp = area.spaces.active
    sp.shading.type = "MATERIAL"
    sp.overlay.show_relationship_lines = False
    sp.overlay.show_floor = True
    sp.show_gizmo_navigate = True
    r = sp.region_3d
    r.view_perspective = "PERSP"
    r.view_location = (0.0, 0.0, 0.62)
    r.view_distance = 2.9
    r.view_rotation = Euler((math.radians(72), 0, math.radians(160))).to_quaternion()  # (behind him, a bit to his right)
    for a in bpy.context.window.screen.areas:
        if a.type == "DOPESHEET_EDITOR":
            a.spaces.active.dopesheet.show_only_selected = False  # (the arrow keys jump to the poses, whatever is picked)
            for reg in a.regions:
                if reg.type == "WINDOW":
                    with bpy.context.temp_override(area=a, region=reg):
                        bpy.ops.action.view_all()  # (the timeline shows just the 41 frames)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = None
    bpy.context.scene.frame_set(1)


steps = []


def shot(name, frame, pick=None, view=None):
    def run():
        sc = bpy.context.scene
        sc.frame_set(frame)
        for o in bpy.context.view_layer.objects:
            o.select_set(False)
        if pick:
            o = bpy.data.objects[pick]
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
        if view:
            r = view3d().spaces.active.region_3d
            r.view_rotation = Euler(view).to_quaternion()
        return name
    steps.append(run)


setup_done = [False]
for i, f in enumerate(FRAMES):
    shot("pose%d" % (i + 1), f)
shot("pick_right_hand", 1, "RIGHT HAND")
shot("pick_axe", 1, "AXE")
shot("front", 1, None, (math.radians(80), 0, math.radians(0)))
state = {"i": -1, "name": None}


def tick():
    bpy.context.preferences.view.show_splash = False
    if not setup_done[0]:
        setup()
        setup_done[0] = True
        return 1.0
    if state["name"]:  # (take the picture one tick after the change, once the window has redrawn)
        bpy.ops.screen.screenshot(filepath="%s/%s.png" % (PICS, state["name"]))
        state["name"] = None
    state["i"] += 1
    if state["i"] < len(steps):
        state["name"] = steps[state["i"]]()
        return 1.0
    setup()  # (the view the owner starts with: the axe picked, so the arrow keys jump between the poses at once)
    bpy.data.objects["AXE"].select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects["AXE"]
    bpy.ops.wm.save_as_mainfile(filepath=OUT, compress=True)
    print("SAVED", OUT)
    bpy.ops.wm.quit_blender()
    return None


bpy.context.preferences.view.show_splash = False
bpy.app.timers.register(tick, first_interval=3.0)
