"""Run from the folder holding cand/. Edit PICKS, then run. Convert the owner's Round 6+7 picks to assets/sfx/<slot>_<n>.ogg: trim silence, cap length, peak -3 dB."""
import os, re, subprocess
SFX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../assets/sfx")
# slot: [(file, max seconds)]
PICKS = {"level_up": [("r10/level_up/878615", 3.0)], "dig_rock": [("r10/level_up/760567", 1.0)]}
def run(*a): return subprocess.run(a, capture_output=True, text=True)
for slot, files in PICKS.items():
    for old in [f for f in os.listdir(SFX) if re.fullmatch(slot + r"_\d+\.ogg(\.import)?", f)]:
        if old.endswith(".ogg"): os.remove(os.path.join(SFX, old))  # spider_death: replaced by the owner's pick
    for n, (src, cap) in enumerate(files):
        src = f"cand/{src}.mp3"; tmp = f"/tmp/t_{slot}{n}.wav"
        trim = ("silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
                "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
                f"atrim=0:{cap},afade=t=out:st={max(cap-0.15,0)}:d=0.15")
        p0 = float(re.search(r"max_volume: (-?[\d.]+)", run("ffmpeg", "-i", src, "-af", "volumedetect", "-f", "null", "-").stderr).group(1))
        run("ffmpeg", "-y", "-v", "error", "-i", src, "-vn", "-ac", "1", "-af", f"volume={-p0}dB," + trim.replace("-45dB", "-50dB"), tmp)
        peak = float(re.search(r"max_volume: (-?[\d.]+)", run("ffmpeg", "-i", tmp, "-af", "volumedetect", "-f", "null", "-").stderr).group(1))
        out = os.path.join(SFX, f"{slot}_{n}.ogg")
        r = run("ffmpeg", "-y", "-v", "error", "-i", tmp, "-af", f"volume={-3 - peak}dB", "-ar", "44100", "-c:a", "vorbis", "-strict", "-2", "-ac", "2", out)
        d = run("ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out).stdout.strip()
        print(slot, n, d, r.stderr[:80])
