import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";
import WORDS_JSON from "./words.json";

// Caption LAB: the same 11.6 s of Max (vibe-coders video, "Every week someone is selling a new AI app … only 10% of the job.")
// captioned in 20 different styles, for Max to score 1-10. 1080x1920, 30 fps, with his voice.
// Words: { w, s, e } in seconds from the clip start, already spelled like the script ("99%", "Claude", "10%").
export type Word = { w: string; s: number; e: number };
export const WORDS: Word[] = WORDS_JSON as Word[];
export const CLIP_DUR = 11.65;
// sentence ends in the clip (for grouping)
export const SENTENCES = [
  { from: 0.0, to: 5.0, text: "Every week someone is selling a new AI app and 99% of them are just trash." },
  { from: 5.71, to: 9.2, text: "Getting Claude to build an app takes literally one prompt now." },
  { from: 9.45, to: 11.6, text: "But coding is only 10% of the job." },
];
// key words for highlight treatments
export const KEY = new Set(["99%", "trash.", "Claude", "one", "prompt", "10%", "job."]);
export const isKey = (w: Word) => KEY.has(w.w) && !(w.w === "one" && w.s < 7);

/** Max on camera with his voice. layer "person" = his cut-out only (transparent), to stack captions BEHIND him. */
export const Clip: React.FC<{ zoom?: number; muted?: boolean }> = ({ zoom = 1.03, muted = false }) => (
  <AbsoluteFill style={{ transform: `scale(${zoom})`, background: "#000" }}>
    <OffthreadVideo src={staticFile("lib/capclip.mp4")} muted={muted} style={{ width: 1080, height: 1920 }} />
  </AbsoluteFill>
);
export const Person: React.FC<{ zoom?: number }> = ({ zoom = 1.03 }) => (
  <AbsoluteFill style={{ transform: `scale(${zoom})` }}>
    <OffthreadVideo src={staticFile("lib/capclip_person.webm")} transparent muted style={{ width: 1080, height: 1920 }} />
  </AbsoluteFill>
);

/** group words into chunks: max `n` words, break on punctuation and pauses > gap */
export const chunk = (words: Word[], n = 3, gap = 0.3) => {
  const out: Word[][] = []; let cur: Word[] = [];
  for (const w of words) {
    if (cur.length && (cur.length >= n || w.s - cur[cur.length - 1].e > gap)) { out.push(cur); cur = []; }
    cur.push(w);
    if (/[.?!,]$/.test(w.w)) { out.push(cur); cur = []; }
  }
  if (cur.length) out.push(cur);
  return out.map((c, i) => ({ words: c, from: c[0].s - 0.05, to: i + 1 < out.length ? Math.min(out[i + 1][0].s - 0.05, c[c.length - 1].e + 0.8) : c[c.length - 1].e + 0.8 }));
};

export type CapItem = {
  id: string;            // e.g. "c1-04"
  title: string;
  note: string;          // one line: the idea / reference
  C: React.FC;           // draws Clip (+ Person if needed) + its captions
};
