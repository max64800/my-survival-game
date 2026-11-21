"""The dwarf's hurt sound (F551, owner Nov 21: "I hate the sound when you take damage"). Old-world only: a heavy
leather body-thump, his clothes and belt gear shaking, from Kenney's CC0 "RPG Audio" recordings
(mirror: https://opengameart.org/content/50-rpg-sound-effects). Four slightly different takes so it never repeats.

Usage:  python tools/art/make_hurt_sound.py <folder with the RPG pack .ogg files>
Writes: assets/sfx/hurt_<0..3>.ogg
"""
import os
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
OUT = os.path.join(ROOT, "assets", "sfx")

# (thump pitch, cloth file, gear file, gear delay ms, gear volume)
TAKES = [
    (0.78, "cloth1", "beltHandle1", 40, 0.35),
    (0.72, "cloth2", "beltHandle2", 55, 0.30),
    (0.84, "cloth3", "handleSmallLeather", 30, 0.40),
    (0.75, "cloth4", "clothBelt", 45, 0.35),
]


def main(pack: str) -> None:
    for i, (pitch, cloth, gear, delay, gear_vol) in enumerate(TAKES):
        src = lambda n: os.path.join(pack, n + ".ogg")
        rate = int(44100 * pitch)
        graph = (
            # the body-thump: dropped leather, pitched down (a heavier body), a little low boost, cut short
            f"[0:a]aformat=channel_layouts=mono,asetrate={rate},aresample=44100,"
            f"equalizer=f=140:t=q:w=1:g=5,lowpass=f=5000,atrim=0:0.45,volume=1.3[t];"
            # his clothes snapping with the hit
            f"[1:a]aformat=channel_layouts=mono,atrim=0:0.35,volume=0.55[c];"
            # belt gear rattling just after
            f"[2:a]aformat=channel_layouts=mono,atrim=0:0.4,adelay={delay},volume={gear_vol}[g];"
            "[t][c][g]amix=inputs=3:normalize=0,afade=t=out:st=0.4:d=0.15,atrim=0:0.55,"
            "alimiter=limit=0.9[out]"
        )
        path = os.path.join(OUT, f"hurt_{i}.ogg")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src("dropLeather"), "-i", src(cloth),
                        "-i", src(gear), "-filter_complex", graph, "-map", "[out]", "-ac", "1",
                        "-c:a", "libvorbis", "-q:a", "5", path], check=True)
        print("wrote", path)


if __name__ == "__main__":
    main(sys.argv[1])
