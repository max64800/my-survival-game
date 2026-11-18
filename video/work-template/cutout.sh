#!/bin/bash
# 039 person cut-out (person-cutout-encoding): constant 30 fps cut -> RVM matte -> VP9 alpha with -auto-alt-ref 0
set -e
cd "$(dirname "$0")/../.."
P=editor/motion/public/v4334
ffmpeg -loglevel error -y -i out/IMG_4334_cut.mp4 -vf fps=30 -c:v libx264 -crf 14 -pix_fmt yuv420p -c:a copy $P/cut.mp4
editor/.venv/bin/python editor/matte_rvm.py $P/cut.mp4 work/IMG_4334/matte.mp4
ffmpeg -loglevel error -y -i $P/cut.mp4 -i work/IMG_4334/matte.mp4 -filter_complex "[1:v]format=gray[m];[0:v][m]alphamerge,format=yuva420p" -an -r 30 \
  -c:v libvpx-vp9 -pix_fmt yuva420p -auto-alt-ref 0 -b:v 8M -deadline good -cpu-used 4 -row-mt 1 $P/person.webm
for f in $P/cut.mp4 work/IMG_4334/matte.mp4 $P/person.webm; do echo "$f $(ffprobe -v error -count_frames -select_streams v -show_entries stream=nb_read_frames -of csv=p=0 $f)"; done
