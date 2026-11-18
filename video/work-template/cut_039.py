"""Run editor/cut.py on IMG_4334 with one change: the raw is stored landscape with no rotation tag, so turn it
upright (90 deg clockwise, transpose=1) after the HDR -> SDR grade. Everything else (voice chain, quality check) is cut.py as is.
Usage: python cut_039.py --from-edl [--force]"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "editor"))
import cut
cut.GRADE += ",transpose=1"
sys.argv = ["cut.py", "../../raw/IMG_XXXX.MOV", "--no-zoom", *sys.argv[1:]]
sys.exit(cut.main())
