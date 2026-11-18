import React from "react";
import {
  AbsoluteFill, Audio, Easing, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig,
} from "remotion";
import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";
import { Big } from "./OverlayV2";
import { ART, Sticker, StickerEl } from "./Overlay3D";
import { K2, K2_FULL, renderK2, SingleCaptions } from "./kit2";
import { Dot, Flow, FlowDef, Intro, PalmDraw } from "./kit3";
import { StackCaptions, StackGroup } from "./kit5";
import { ShapeCues, ShapeStory } from "./kit6";
import { VibeDef, VibePlate } from "./kit7";
import { EdBehind, EdCaptions, EdCards, EdDef, EdWipe } from "./kit9";
import { BoldDef, BoldPlate, ColorCaps, CWord } from "./kit10";
import { Aurora, GBig, GlassBehind, GlassCard, GlassDef, GlideCaptions, GlideDef, PAL, Pal, PhoneDef, PhoneShot } from "./kit11";
import { ProofDef, ProofShot, QuietCapsDef, QuietCaptions, Receipt, ReceiptDef, Tasks, TasksDef } from "./kit12";
import { Brain, BrainDef } from "./kit12b";
import { BatchCard, BatchCardDef } from "./b1108";
import { Score, ScoreDef } from "./kit12_score";
import { SteamCard, SteamDef } from "./kit12steam";
import { TapeCaptions, TapeDef, ChatCaptions, ChatDef, PillCaptions, PillDef, StickerCaptions, StickerDef } from "./kit8";
import { BgSwap, BgSwapDef, K4, K4_TOP, LogoReveal, Morph, MorphDef, RevealDef, renderK4 } from "./kit4";

// Full edit in one pass (v3): the talking-head video itself plus everything on top of it.
// Layers, back to front: camera group [wall video (can blur) -> words behind the head -> person cut-out]
// -> soft split panel -> cards/stickers -> captions -> full-screen cards. Every visual event also
// fires a sound effect, and the camera changes (punch, drift, reframe) at least every ~1.5 s.
const { fontFamily: DISPLAY } = loadAnton();
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "700", "800", "900"], subsets: ["latin"] });
const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });

// Platform UI no-go zones on a 1080x1920 frame, the strictest of TikTok / Instagram Reels / YouTube Shorts:
// top bar (tabs, search) ~250 px on Reels; bottom stack (name, caption, audio) ~420-500 px; right action
// rail (like/comment/share) ~120-180 px wide in the lower half. Captions and key text stay inside.
export const SAFE = { top: 250, bottom: 1420, left: 60, right: 900, railTop: 700 };
const YELLOW = "#FFD600";
const RED = "#E5322D";
const INK = "#141414";
const CREAM = "#F4F1EA";
const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);

type Base = { from: number; to: number };
type Word = { w: string; s: number; e: number; em?: boolean };
export type Chunk = { from: number; to: number; words: Word[] };
export type Beat = { at: number; zoom: number; ox: number; oy: number; dur?: number; sfx?: string };
type Range = { from: number; to: number };
export type El =
  | (Base & { type: "slam"; lines: { text: string; accent?: boolean }[]; y: number })
  | (Base & { type: "big"; text: string; accent?: string; y?: number; size?: number })
  | (Base & StickerEl & { type: "sticker" })
  | (Base & { type: "chip"; x: number; y: number; text: string; emoji?: string; accent?: boolean; rot?: number; strikeAt?: number })
  | (Base & { type: "counter"; x: number; y: number; title: string; n0: number; n1: number; at: number; dur: number; suffix?: string; end?: string })
  | (Base & { type: "ring"; x: number; y: number; value: number; max: number; at: number; label: string })
  | (Base & { type: "cast"; x: number; y: number; rows: { name: string; role: string; at: number; color: string; tag?: string; tagAt?: number }[] })
  | (Base & { type: "poster"; x: number; y: number; rot: number; title: string; sub: string })
  | (Base & { type: "tape"; y: number; text: string; rot: number })
  | (Base & { type: "calendar"; x: number; y: number; days: number; at: number })
  | (Base & { type: "vox"; lines: { text: string; at: number; serif?: boolean; mark?: boolean; size?: number }[]; pip?: { ox: number; oy: number } })
  | (Base & { type: "comment"; text: string; at: number })
  | (Base & { type: "flash" })
  | (Base & { type: "toggle"; x: number; y: number; label: string; at: number })
  | (Base & { type: "list"; x: number; y: number; w?: number; title: string; rows: { text: string; emoji?: string; at: number; tone?: "good" | "bad" }[] })
  | (Base & { type: "chat"; x: number; y: number; title: string; msgs: { from: "me" | "ai"; text: string; at: number }[] })
  | (Base & { type: "rules"; x: number; y: number; stages: { at: number; n: number; title: string; tokens?: { text: string; at: number; strike?: boolean; good?: boolean }[] }[] });
export type Sfx = { t: number; s: string; v?: number };
export type EditProps = {
  duration: number;
  video: string;          // path under public/, e.g. "v3787/cut.mp4"
  person?: string;        // transparent cut-out of the speaker, same timing as `video` (only needed for words behind the head)
  chunks: Chunk[];
  beats: Beat[];
  blur: Range[];
  split: (Range & { shift: number })[];
  nocap?: Range[];
  guides?: boolean;
  kit2?: K2[];                                   // dark-glass / slate kit (src/kit2.tsx)
  captionStyle?: "chunks" | "single" | "stack" | "levels" | "chat" | "pills" | "stickers" | "tape" | "editorial" | "color" | "glide" | "quiet";
  tape?: TapeDef;                                 // kit8: highlighter-tape captions (library c2-09)
  pills?: PillDef;                                // kit8: glass-pill stepper captions (library c2-07)
  chat?: ChatDef;                                 // kit8: chat-bubble captions (library c2-04)
  stickers?: StickerDef;                          // kit8: die-cut sticker captions (library c1-09)
  levels?: LevelBlock[];                          // "levels" captions (stacked lines)
  levelsTop?: number;            // "single" = one word at a time, quiet-luxury look
  levelsBottom?: number;         // anchor "levels" captions by their bottom edge instead
  words?: Word[];                                // word list for single-word captions
  whips?: { at: number; dir?: number }[];        // whip-pan transitions: directional motion blur for ~0.3 s
  palm?: { from: number; to: number; y?: number }; // kit3: Palm outline drawn by light, collapses to a dot
  intro?: { from: number; to: number; label: string }; // kit3: three TYPE cards that collapse into the dot
  dot?: { at: number; x: number; y: number };     // kit3: the through-line dot
  flow?: FlowDef;                                 // kit3: full-screen scene sequence with hand-offs
  kit4?: K4[];                                    // kit4: frosted cards + liquid pour
  morph?: MorphDef;                               // kit4: one card that morphs beat to beat
  reveal?: RevealDef;                             // kit4: EQT logo reveal ending (Palm-video style)
  bgSwaps?: BgSwapDef[];                          // kit4: replace the room behind him with colour + huge type
  stack?: StackGroup[];                           // kit5: karan-style stacked captions (serif + one script word)
  shapes?: { from: number; to: number; cues: ShapeCues };   // kit6: shape story in the top panel
  ed?: EdDef;                                     // kit9: editorial cream/forest/gold system (giant serif behind head, paper cards, bar captions)
  vibe?: VibeDef;                                 // kit7: one fitted graphite plate that morphs beat to beat
  colorCaps?: { chunks: { from: number; to: number; words: CWord[] }[]; bottom: number; size?: number };   // kit10 colour-word captions
  glass?: GlassDef;                               // kit11: one white glass card with a gradient rim, morphing UI mockups (Max 2026-10-21)
  glassBehind?: GBig[];                           // kit11: gradient Inter words behind the head
  phone?: PhoneDef;                               // kit11 (026): the real screen recording in a phone frame, small in the card <-> big centred
  aurora?: { solid: number; fade: number };       // kit11: flowing gradient band replaces the flat soft-split panel
  pal?: Pal;                                      // kit11/12 palette for this video (default: kit11 PAL)
  proof?: ProofDef;                               // kit12: the real screenshot fills frame 1, then shrinks into the receipt
  receipt?: ReceiptDef;                           // kit12: one card that prints a row per line
  tasks?: TasksDef;                               // kit12 (027): master list -> Claude top-3 chat -> 3 vs 350 -> comment box
  score?: ScoreDef;                               // kit12 (032): home vs office scoreboard, 1 in 100, grow the company, office alone
  brain?: BrainDef;                              // kit12b (034): second-brain dashboard -> passwords found -> rules -> worth it?
  steam?: SteamDef;                               // kit12 (030): Steam store card, launch checklist fills, wishlist click
  quiet?: QuietCapsDef;
  b1108?: BatchCardDef;                           // Nov 8 batch (035-041): per-video top-level card in src/b1108/                           // kit12: plain captions, gold key words
  glide?: GlideDef;                               // kit11 captions: gradient pill glides word to word
  bold?: BoldDef;                                 // kit10: one bright colour-block plate, colour sweeps + slide hand-offs (Max 2026-10-18)
  splitUnder?: boolean;                           // draw the soft-split panel UNDER the behind-head words (so big words can sit partly behind him)
  splitColor?: string;                            // colour of the soft split panel (default cream)
  splitFade?: [number, number];                   // panel solid down to [0] px, clear at [1] px (short fade that stays above his head)
  elements: El[];
  sfx: Sfx[];
};

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const ramp = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
// 0 -> 1 -> 0 envelope for a range with eased edges
const window_ = (t: number, r: Range, inD = 0.35, outD = 0.3) =>
  Math.min(ramp(t, r.from, r.from + inD, EASE_IO), 1 - ramp(t, r.to - outD, r.to, EASE_IO));
const active = (t: number, r: Range) => t >= r.from && t <= r.to;
// everything that sits on screen keeps floating a little (never frozen)
const drift = (t: number, seed: number, amp = 9) =>
  `translate(${Math.sin(t * 1.3 + seed) * amp * 0.6}px, ${Math.sin(t * 1.7 + seed * 2.1) * amp}px) rotate(${Math.sin(t * 1.1 + seed) * 0.8}deg)`;
const inOut = (t: number, e: Base, inD = 0.4, outD = 0.25) => ({
  k: ramp(t, e.from, e.from + inD),
  out: ramp(t, e.to - outD, e.to, EASE_IN),
});

// ---------- camera ----------
const camera = (t: number, beats: Beat[]) => {
  let i = 0;
  while (i + 1 < beats.length && beats[i + 1].at <= t) i++;
  const b = beats[i];
  const p = beats[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : ramp(t, b.at, b.at + (b.dur ?? 0.2), EASE);
  const z = p.zoom + (b.zoom - p.zoom) * k;
  const live = 1 + Math.min(t - b.at, 3) * 0.012;      // slow push between punches
  return { z: z * live, ox: p.ox + (b.ox - p.ox) * k, oy: p.oy + (b.oy - p.oy) * k };
};

// ---------- captions (Inter + Instrument Serif italic for the key word) ----------
// one caption word in the house style (Inter 800 + rotating key-word looks: serif italic / marker swipe / white tag)
const capWord = (w: Word, i: number, t: number, variant: number, shadow: string) => {
        const said = t >= w.s;
  const pop = ramp(t, w.s, w.s + 0.12);
  const base: React.CSSProperties = { opacity: said ? 1 : 0,   // unsaid words keep their space but are INVISIBLE (no faint preview, Max)
    display: "inline-block", position: "relative",
    transform: `scale(${said ? 1 + (1 - pop) * 0.12 : 1})` };
  if (!w.em) {
    return <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 800, fontSize: 62, color: "#FFFFFF", lineHeight: 1.15,
      letterSpacing: -0.5, textShadow: shadow }}>{w.w}</span>;
  }
  if (variant === 1) {
    const m = ramp(t, w.s, w.s + 0.25, EASE_IO);
    return (
      <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 900, fontSize: 70, color: INK, lineHeight: 1.15, padding: "0 10px" }}>
        <span style={{ position: "absolute", left: 0, right: 0, top: "12%", bottom: "8%", background: YELLOW, borderRadius: 10,
          transformOrigin: "left", transform: `scaleX(${said ? m : 0}) rotate(-1.5deg)` }} />
        <span style={{ position: "relative", color: said && m > 0.5 ? INK : "#FFFFFF", textShadow: said && m > 0.5 ? "none" : shadow }}>{w.w}</span>
      </span>
    );
  }
  if (variant === 2) {
    return <span key={i} style={{ ...base, fontFamily: DISPLAY, fontSize: 78, color: INK, background: "#FFFFFF", padding: "2px 18px",
      borderRadius: 12, textTransform: "uppercase", lineHeight: 1.1, boxShadow: "0 10px 26px rgba(0,0,0,0.35)",
      transform: `${base.transform} rotate(-3deg)` }}>{w.w}</span>;
  }
  return <span key={i} style={{ ...base, fontFamily: SERIF, fontStyle: "italic", fontSize: 96, color: YELLOW, lineHeight: 1.0,
    letterSpacing: -1, textShadow: shadow }}>{w.w}</span>;
};

// "levels" captions (Max, 2026-10-10): each new phrase appears on a new line under the previous one, older lines stay
// (slightly dimmer), then the whole block clears together. Same font and key-word looks as the one-line captions.
export type LevelBlock = { from: number; to: number; lines: { from: number; variant: number; words: Word[] }[] };
const LevelCaptions: React.FC<{ blocks: LevelBlock[]; top: number; bottom?: number }> = ({ blocks, top, bottom }) => {
  const t = useT();
  const b = blocks.find((x) => t >= x.from && t < x.to);
  if (!b) return null;
  const out = ramp(t, b.to - 0.22, b.to, EASE_IN);
  const shadow = "0 2px 3px rgba(0,0,0,0.6), 0 4px 18px rgba(0,0,0,0.75)"   // readable over a white shirt;
  return (
    // bottom: anchor the block's last line to this y instead (keeps captions low when the face fills the frame)
    <div style={{ position: "absolute", left: 80, right: 1080 - SAFE.right + 10, ...(bottom ? { bottom: 1920 - bottom } : { top }), display: "flex", flexDirection: "column", alignItems: "center", gap: 2,
      opacity: 1 - out, transform: `translateY(${-out * 30}px)` }}>
      {b.lines.map((l, li) => {
        if (t < l.from) return null;
        const k = ramp(t, l.from, l.from + 0.16);
        const newest = li === b.lines.filter((x) => t >= x.from).length - 1;
        return (
          <div key={li} style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", alignItems: "center", columnGap: 14,
            opacity: k * (newest ? 1 : 0.92), transform: `translateY(${(1 - k) * 16}px) scale(${newest ? 1 : 0.94})` }}>
            {l.words.map((w, i) => capWord(w, i, t, l.variant, shadow))}
          </div>
        );
      })}
    </div>
  );
};

const Captions: React.FC<{ chunks: Chunk[]; hide: Range[]; shiftY: number }> = ({ chunks, hide, shiftY }) => {
  const t = useT();
  if (hide.some((h) => active(t, h))) return null;
  const ci = chunks.findIndex((x) => t >= x.from && t < x.to);
  if (ci < 0) return null;
  const c = chunks[ci];
  // key-word look rotates so the captions don't feel samey: serif italic / marker swipe / white tag
  const emIndex = chunks.slice(0, ci + 1).filter((x) => x.words.some((w) => w.em)).length;
  const variant = emIndex % 3;
  const k = ramp(t, c.from, c.from + 0.14);
  const shadow = "0 3px 2px rgba(0,0,0,0.35), 0 6px 24px rgba(0,0,0,0.55)";
  return (
    <div style={{ position: "absolute", left: 90, right: 1080 - SAFE.right + 10, bottom: 1920 - SAFE.bottom + 10 + shiftY * 0, display: "flex", flexWrap: "wrap",
      justifyContent: "center", alignItems: "center", columnGap: 16, rowGap: 0, opacity: k,
      transform: `translateY(${(1 - k) * 18}px)` }}>
      {c.words.map((w, i) => {
        const said = t >= w.s;
        const pop = ramp(t, w.s, w.s + 0.12);
        const base: React.CSSProperties = { opacity: said ? 1 : 0.42, display: "inline-block", position: "relative",
          transform: `scale(${said ? 1 + (1 - pop) * 0.12 : 1})` };
        if (!w.em) {
          return <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 800, fontSize: 62, color: "#FFFFFF", lineHeight: 1.15,
            letterSpacing: -0.5, textShadow: shadow }}>{w.w}</span>;
        }
        if (variant === 1) {
          const m = ramp(t, w.s, w.s + 0.25, EASE_IO);
          return (
            <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 900, fontSize: 70, color: INK, lineHeight: 1.15, padding: "0 10px" }}>
              <span style={{ position: "absolute", left: 0, right: 0, top: "12%", bottom: "8%", background: YELLOW, borderRadius: 10,
                transformOrigin: "left", transform: `scaleX(${said ? m : 0}) rotate(-1.5deg)` }} />
              <span style={{ position: "relative", color: said && m > 0.5 ? INK : "#FFFFFF", textShadow: said && m > 0.5 ? "none" : shadow }}>{w.w}</span>
            </span>
          );
        }
        if (variant === 2) {
          return <span key={i} style={{ ...base, fontFamily: DISPLAY, fontSize: 78, color: INK, background: "#FFFFFF", padding: "2px 18px",
            borderRadius: 12, textTransform: "uppercase", lineHeight: 1.1, boxShadow: "0 10px 26px rgba(0,0,0,0.35)",
            transform: `${base.transform} rotate(-3deg)` }}>{w.w}</span>;
        }
        return <span key={i} style={{ ...base, fontFamily: SERIF, fontStyle: "italic", fontSize: 96, color: YELLOW, lineHeight: 1.0,
          letterSpacing: -1, textShadow: shadow }}>{w.w}</span>;
      })}
    </div>
  );
};

// ---------- elements ----------
const Slam: React.FC<{ e: Extract<El, { type: "slam" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { out } = inOut(t, e);
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: e.y, textAlign: "center", perspective: 900, opacity: 1 - out }}>
      {e.lines.map((l, i) => {
        const k = ramp(t, e.from + i * 0.16, e.from + i * 0.16 + 0.32, Easing.bezier(0.2, 1.4, 0.4, 1));
        return (
          <div key={i} style={{ fontFamily: DISPLAY, fontSize: 168, lineHeight: 0.98, textTransform: "uppercase",
            color: l.accent ? YELLOW : "#FFFFFF", WebkitTextStroke: `7px ${INK}`, paintOrder: "stroke fill",
            filter: "drop-shadow(0 14px 26px rgba(0,0,0,0.35))", opacity: Math.min(1, k * 3),
            transform: `translateZ(${(1 - k) * 380}px) rotateX(${(1 - k) * -38}deg) ${drift(t, i + 3, 4)}` }}>{l.text}</div>
        );
      })}
    </div>
  );
};

const Chip: React.FC<{ e: Extract<El, { type: "chip" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e, 0.35);
  return (
    <div style={{ position: "absolute", left: e.x, top: e.y, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * k}) rotate(${e.rot ?? -3}deg) ${drift(t, e.from)}`,
      opacity: k * (1 - out), display: "flex", alignItems: "center", gap: 14, padding: "16px 28px 16px 20px", borderRadius: 26,
      background: e.accent ? YELLOW : "rgba(255,255,255,0.96)", color: INK, fontFamily: UI, fontWeight: 900, fontSize: 44,
      boxShadow: "0 18px 40px rgba(0,0,0,0.28)", whiteSpace: "nowrap" }}>
      {e.emoji && <span style={{ fontSize: 50 }}>{e.emoji}</span>}{e.text}
      {e.strikeAt !== undefined && (
        <div style={{ position: "absolute", left: 14, right: 14, top: "50%", height: 9, borderRadius: 5, background: RED,
          transformOrigin: "left", transform: `scaleX(${ramp(t, e.strikeAt, e.strikeAt + 0.3, EASE_IO)}) rotate(-4deg)` }} />
      )}
    </div>
  );
};

const Card: React.FC<{ x: number; y: number; w: number; k: number; out: number; seed: number; children: React.ReactNode; tilt?: number }> =
  ({ x, y, w, k, out, seed, children, tilt = 0 }) => {
    const t = useT();
    return (
      <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, perspective: 1200 }}>
        <div style={{ background: "#FFFFFF", borderRadius: 34, padding: "30px 34px", boxShadow: "0 30px 60px rgba(20,20,20,0.22), 0 4px 10px rgba(0,0,0,0.08)",
          opacity: Math.min(1, k * 2) * (1 - out), fontFamily: UI, color: INK,
          transform: `translateY(${(1 - k) * 90 - out * 40}px) rotateX(${(1 - k) * 28}deg) rotateZ(${(1 - k) * -4 + tilt}deg) scale(${0.9 + 0.1 * k}) ${drift(t, seed, 7)}` }}>
          {children}
        </div>
      </div>
    );
  };

const Odometer: React.FC<{ value: number; size: number }> = ({ value, size }) => {
  const digits = Math.max(1, String(Math.floor(Math.abs(value))).length);
  const cols = [];
  for (let d = digits - 1; d >= 0; d--) {
    // a digit only moves while every digit below it is rolling over (no half-shown digits at rest)
    const p = Math.pow(10, d);
    const base = Math.floor(value / p) % 10;
    cols.push(d === 0 ? base + (value - Math.floor(value)) : base + Math.max(0, (value % p) - (p - 1)));
  }
  return (
    <div style={{ display: "flex", height: size * 1.05, overflow: "hidden" }}>
      {cols.map((v, i) => {
        const roll = v;
        return (
          <div key={i} style={{ height: size * 1.05, overflow: "hidden" }}>
            <div style={{ transform: `translateY(${-roll * size * 1.05}px)` }}>
              {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
                <div key={j} style={{ height: size * 1.05, fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: DISPLAY }}>{n}</div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
};

const Counter: React.FC<{ e: Extract<El, { type: "counter" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  const p = ramp(t, e.at, e.at + e.dur, EASE_IO);
  const v = e.n0 + (e.n1 - e.n0) * p;
  const done = t > e.at + e.dur;
  const endK = e.end ? ramp(t, e.at + e.dur, e.at + e.dur + 0.25, Easing.bezier(0.2, 1.5, 0.4, 1)) : 0;
  return (
    <Card x={e.x} y={e.y} w={620} k={k} out={out} seed={e.from} tilt={-2}>
      <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 2, color: "#8A8A8A", textTransform: "uppercase" }}>{e.title}</div>
      <div style={{ display: "flex", alignItems: "center", gap: 18, marginTop: 8, color: INK }}>
        {done && e.end ? (
          <div style={{ fontFamily: DISPLAY, fontSize: 150, color: RED, transform: `scale(${0.6 + 0.4 * endK})` }}>{e.end}</div>
        ) : (
          <Odometer value={v} size={150} />
        )}
        {e.suffix && <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 70, color: "#555" }}>{e.suffix}</div>}
      </div>
    </Card>
  );
};

const Ring: React.FC<{ e: Extract<El, { type: "ring" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  const p = ramp(t, e.at, e.at + 1.1, EASE_IO);
  const R = 150, C = 2 * Math.PI * R;
  const val = Math.round(e.value * p);
  return (
    <div style={{ position: "absolute", left: e.x - 190, top: e.y - 190, width: 380, height: 380, opacity: k * (1 - out),
      transform: `scale(${0.6 + 0.4 * k}) ${drift(t, 2)}` }}>
      <svg width="380" height="380" viewBox="0 0 380 380">
        <circle cx="190" cy="190" r="178" fill="rgba(255,255,255,0.97)" />
        <circle cx="190" cy="190" r={R} fill="none" stroke="#EDEDED" strokeWidth="26" />
        <circle cx="190" cy="190" r={R} fill="none" stroke={RED} strokeWidth="26" strokeLinecap="round"
          strokeDasharray={`${C * (e.value / e.max) * p} ${C}`} transform="rotate(-90 190 190)" />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ display: "flex", alignItems: "baseline", color: INK }}>
          <span style={{ fontFamily: DISPLAY, fontSize: 150, lineHeight: 1 }}>{val}</span>
          <span style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 64, color: "#777" }}>/{e.max}</span>
        </div>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 3, color: "#8A8A8A", marginTop: 4 }}>{e.label}</div>
      </div>
    </div>
  );
};

const Cast: React.FC<{ e: Extract<El, { type: "cast" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  return (
    <Card x={e.x} y={e.y} w={700} k={k} out={out} seed={e.from} tilt={2}>
      <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, color: "#8A8A8A" }}>CAST LIST</div>
      {e.rows.map((r, i) => {
        const a = ramp(t, r.at, r.at + 0.3);
        const tagK = ramp(t, r.tagAt ?? r.at + 0.25, (r.tagAt ?? r.at + 0.25) + 0.25, Easing.bezier(0.2, 1.6, 0.4, 1));
        return (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 20, marginTop: 20, opacity: a, transform: `translateX(${(1 - a) * 40}px)` }}>
            <div style={{ width: 70, height: 70, borderRadius: 35, background: r.color, color: "#fff", fontFamily: UI, fontWeight: 900,
              fontSize: 34, display: "flex", alignItems: "center", justifyContent: "center" }}>{r.name[0]}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 800, fontSize: 40 }}>{r.name}</div>
              <div style={{ fontWeight: 500, fontSize: 28, color: "#888" }}>{r.role}</div>
            </div>
            {r.tag && (
              <div style={{ background: RED, color: "#fff", fontWeight: 900, fontSize: 28, padding: "8px 16px", borderRadius: 12,
                transform: `scale(${tagK}) rotate(-6deg)` }}>{r.tag}</div>
            )}
          </div>
        );
      })}
    </Card>
  );
};

// torn-paper poster (jagged edges drawn as a polygon clip)
const tornPath = (w: number, h: number, seed: number) => {
  const pts: string[] = [];
  const j = (i: number) => (Math.sin(i * 12.9898 + seed) * 43758.5453) % 1;
  const n = 18;
  for (let i = 0; i <= n; i++) pts.push(`${(i / n) * w}px ${Math.abs(j(i)) * 14}px`);
  for (let i = 0; i <= n; i++) pts.push(`${w - Math.abs(j(i + 40)) * 10}px ${(i / n) * h}px`);
  for (let i = n; i >= 0; i--) pts.push(`${(i / n) * w}px ${h - Math.abs(j(i + 80)) * 14}px`);
  for (let i = n; i >= 0; i--) pts.push(`${Math.abs(j(i + 120)) * 10}px ${(i / n) * h}px`);
  return `polygon(${pts.join(",")})`;
};

const Poster: React.FC<{ e: Extract<El, { type: "poster" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e, 0.35);
  const W = 440, H = 560;
  return (
    <div style={{ position: "absolute", left: e.x - W / 2, top: e.y, width: W, height: H, opacity: k * (1 - out),
      transform: `rotate(${e.rot + (1 - k) * 16}deg) scale(${1.3 - 0.3 * k}) ${drift(t, 5)}`, filter: "drop-shadow(0 18px 24px rgba(0,0,0,0.3))" }}>
      <div style={{ width: W, height: H, background: "#F3EBDD", clipPath: tornPath(W, H, 3), display: "flex", flexDirection: "column",
        alignItems: "center", paddingTop: 34, boxSizing: "border-box" }}>
        <div style={{ fontFamily: DISPLAY, fontSize: 96, color: RED, letterSpacing: 4, lineHeight: 1 }}>{e.title}</div>
        <svg viewBox="0 0 200 200" width="250" height="250" style={{ marginTop: 6 }}>{ART.mask}</svg>
        <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 48, color: INK, textAlign: "center", lineHeight: 1.0, padding: "0 30px" }}>{e.sub}</div>
      </div>
      <div style={{ position: "absolute", left: W / 2 - 60, top: -18, width: 120, height: 40, background: "rgba(255,240,170,0.85)", transform: "rotate(-4deg)" }} />
    </div>
  );
};

const Tape: React.FC<{ e: Extract<El, { type: "tape" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const k = ramp(t, e.from, e.from + 0.3);
  const out = ramp(t, e.to - 0.25, e.to, EASE_IN);
  const stripes = `repeating-linear-gradient(-45deg, ${YELLOW} 0 46px, ${INK} 46px 92px)`;
  return (
    <div style={{ position: "absolute", left: -200, width: 1480, top: e.y, height: 150, transform: `rotate(${e.rot}deg) translateX(${(1 - k) * -1500 + out * 1500}px)`,
      boxShadow: "0 16px 30px rgba(0,0,0,0.3)", background: stripes, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ background: INK, color: YELLOW, fontFamily: DISPLAY, fontSize: 82, padding: "4px 40px", letterSpacing: 6 }}>{e.text}</div>
    </div>
  );
};

const Calendar: React.FC<{ e: Extract<El, { type: "calendar" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  const p = ramp(t, e.at, e.at + 1.0, EASE_IO);
  return (
    <Card x={e.x} y={e.y} w={430} k={k} out={out} seed={1} tilt={-4}>
      <div style={{ margin: "-30px -34px 0", background: RED, borderRadius: "34px 34px 0 0", color: "#fff", fontFamily: MONO, fontWeight: 700,
        fontSize: 28, letterSpacing: 4, textAlign: "center", padding: "14px 0" }}>DAYS SINCE RELEASE</div>
      <div style={{ display: "flex", justifyContent: "center", marginTop: 14 }}>
        <Odometer value={e.days * p} size={190} />
      </div>
    </Card>
  );
};

const Comment: React.FC<{ e: Extract<El, { type: "comment" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e, 0.35, 0.2);
  const n = Math.floor(Math.max(0, t - e.at) / 0.055);
  const typed = Array.from(e.text).slice(0, n).join("");
  const sent = n > Array.from(e.text).length + 6;
  const caret = Math.floor(t * 2.5) % 2 === 0;
  return (
    <div style={{ position: "absolute", left: SAFE.left, right: 1080 - SAFE.right, top: 1180, opacity: k * (1 - out), transform: `translateY(${(1 - k) * 80}px) ${drift(t, 9, 5)}` }}>
      <div style={{ background: "#FFFFFF", borderRadius: 40, padding: "28px 30px", display: "flex", alignItems: "center", gap: 20,
        boxShadow: "0 24px 50px rgba(0,0,0,0.3)" }}>
        <div style={{ width: 76, height: 76, borderRadius: 38, background: YELLOW, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 40 }}>🕸️</div>
        <div style={{ flex: 1, fontFamily: UI, fontWeight: 700, fontSize: 44, color: typed ? INK : "#AAA" }}>
          {typed || "Add comment..."}{!sent && caret && <span style={{ color: RED }}>|</span>}
        </div>
        <div style={{ width: 76, height: 76, borderRadius: 38, background: sent ? RED : "#EEE", color: "#fff", fontSize: 40, fontWeight: 900,
          display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${sent ? 1.12 : 1})` }}>↑</div>
      </div>
    </div>
  );
};

// Vox-style cutaway: cream paper, serif + grotesk, highlighter swipe; speaker stays in a round bubble
const Vox: React.FC<{ e: Extract<El, { type: "vox" }>; video: string }> = ({ e, video }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const k = ramp(t, e.from, e.from + 0.32);
  const out = ramp(t, e.to - 0.28, e.to, EASE_IN);
  const pipK = ramp(t, e.from + 0.15, e.from + 0.5, Easing.bezier(0.2, 1.4, 0.4, 1));
  return (
    <AbsoluteFill style={{ transform: `translateY(${(1 - k) * 1920 - out * 1920}px) rotate(${(1 - k) * 4 - out * 3}deg)`,
      boxShadow: "0 -30px 60px rgba(0,0,0,0.25)" }}>
      <AbsoluteFill style={{ background: CREAM }}>
        <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, opacity: 0.5 }}>
          {Array.from({ length: 30 }, (_, i) => <line key={i} x1="0" y1={i * 66} x2="1080" y2={i * 66} stroke="#E4DED2" strokeWidth="2" />)}
        </svg>
        <div style={{ position: "absolute", left: 80, right: 80, top: 360, display: "flex", flexDirection: "column", gap: 6 }}>
          {e.lines.map((l, i) => {
            const a = ramp(t, l.at, l.at + 0.3);
            const m = ramp(t, l.at + 0.2, l.at + 0.6, EASE_IO);
            return (
              <div key={i} style={{ position: "relative", alignSelf: "flex-start", opacity: a, transform: `translateY(${(1 - a) * 30}px) ${drift(t, i, 3)}` }}>
                {l.mark && <div style={{ position: "absolute", left: -12, right: -12, top: "38%", height: "52%", background: YELLOW, transformOrigin: "left",
                  transform: `scaleX(${m}) rotate(-1deg)`, borderRadius: 6 }} />}
                <div style={{ position: "relative", fontFamily: l.serif ? SERIF : UI, fontStyle: l.serif ? "italic" : "normal", fontWeight: l.serif ? 400 : 900,
                  fontSize: l.size ?? (l.serif ? 250 : 118), lineHeight: 1.0, color: INK, letterSpacing: l.serif ? -3 : -2 }}>{l.text}</div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
      {e.pip && (
        <div style={{ position: "absolute", right: 60, bottom: 230, width: 440, height: 440, borderRadius: 220, overflow: "hidden",
          border: `10px solid ${INK}`, boxShadow: "0 24px 50px rgba(0,0,0,0.3)", transform: `scale(${pipK}) ${drift(t, 4, 5)}` }}>
          <div style={{ position: "absolute", width: 1080, height: 1920, left: -(e.pip.ox * 0.45) + 210, top: -(e.pip.oy * 0.45) + 210,
            transform: "scale(0.45)", transformOrigin: "0 0" }}>
            <OffthreadVideo src={staticFile(video)} muted style={{ width: 1080, height: 1920 }} />
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};


// iOS-style switch flipping on, with a glow
const Toggle: React.FC<{ e: Extract<El, { type: "toggle" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  const on = ramp(t, e.at, e.at + 0.28, Easing.bezier(0.3, 1.4, 0.5, 1));
  const green = "#34C759";
  return (
    <Card x={e.x} y={e.y} w={600} k={k} out={out} seed={7} tilt={-2}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 3, color: "#8A8A8A" }}>SETTINGS</div>
          <div style={{ fontWeight: 900, fontSize: 56, marginTop: 4 }}>{e.label}</div>
        </div>
        <div style={{ width: 170, height: 96, borderRadius: 48, background: on > 0.5 ? green : "#E3E3E6", position: "relative",
          boxShadow: on > 0.5 ? `0 0 ${40 * on}px rgba(52,199,89,0.65)` : "inset 0 2px 6px rgba(0,0,0,0.12)" }}>
          <div style={{ position: "absolute", top: 8, left: 8 + on * 74, width: 80, height: 80, borderRadius: 40, background: "#fff",
            boxShadow: "0 4px 12px rgba(0,0,0,0.25)" }} />
        </div>
      </div>
    </Card>
  );
};

const List: React.FC<{ e: Extract<El, { type: "list" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  return (
    <Card x={e.x} y={e.y} w={e.w ?? 660} k={k} out={out} seed={e.from} tilt={1.5}>
      <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, color: "#8A8A8A" }}>{e.title}</div>
      {e.rows.map((r, i) => {
        const a = ramp(t, r.at, r.at + 0.3);
        return (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 18, marginTop: 16, opacity: a, transform: `translateX(${(1 - a) * 50}px)` }}>
            {r.emoji && <div style={{ fontSize: 52, width: 64, textAlign: "center" }}>{r.emoji}</div>}
            <div style={{ fontWeight: 900, fontSize: 48, color: r.tone === "bad" ? RED : r.tone === "good" ? "#1E9E4A" : INK }}>{r.text}</div>
          </div>
        );
      })}
    </Card>
  );
};

// chat card: my messages type out, the reply appears after a typing indicator
const Chat: React.FC<{ e: Extract<El, { type: "chat" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e);
  return (
    <Card x={e.x} y={e.y} w={720} k={k} out={out} seed={11} tilt={-1.5}>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div style={{ width: 16, height: 16, borderRadius: 8, background: "#34C759" }} />
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, color: "#8A8A8A" }}>{e.title}</div>
      </div>
      {e.msgs.map((m, i) => {
        if (t < m.at) return null;
        const a = ramp(t, m.at, m.at + 0.25);
        const me = m.from === "me";
        const chars = Array.from(m.text);
        const typed = me ? chars.slice(0, Math.floor((t - m.at) / 0.035)).join("") : m.text;
        const dots = !me && t < m.at + 0.6;
        return (
          <div key={i} style={{ display: "flex", justifyContent: me ? "flex-end" : "flex-start", marginTop: 16, opacity: a, transform: `translateY(${(1 - a) * 20}px)` }}>
            <div style={{ maxWidth: 520, padding: "16px 22px", borderRadius: 26, fontWeight: 700, fontSize: 36, lineHeight: 1.25,
              background: me ? "#141414" : "#F1F0EC", color: me ? "#fff" : INK, borderBottomRightRadius: me ? 8 : 26, borderBottomLeftRadius: me ? 26 : 8 }}>
              {dots ? <span style={{ letterSpacing: 6 }}>{".".repeat(1 + (Math.floor(t * 6) % 3))}</span> : typed}
            </div>
          </div>
        );
      })}
    </Card>
  );
};

// one card that morphs rule to rule (never leaves the screen): numeral rolls, title slides through, tokens pop
const Rules: React.FC<{ e: Extract<El, { type: "rules" }> }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const { k, out } = inOut(t, e, 0.45, 0.3);
  let si = 0;
  while (si + 1 < e.stages.length && e.stages[si + 1].at <= t) si++;
  const st = e.stages[si];
  const prev = e.stages[Math.max(0, si - 1)];
  const sw = si === 0 ? 1 : ramp(t, st.at, st.at + 0.4, EASE);
  const bump = si === 0 ? 0 : Math.sin(Math.min(1, (t - st.at) / 0.35) * Math.PI) * 0.035;
  const num = prev.n + (st.n - prev.n) * sw;
  return (
    <Card x={e.x} y={e.y} w={800} k={k} out={out} seed={3} tilt={-1}>
      <div style={{ display: "flex", gap: 30, alignItems: "center", transform: `scale(${1 + bump})` }}>
        <div style={{ width: 170, height: 170, borderRadius: 40, background: YELLOW, display: "flex", alignItems: "center", justifyContent: "center",
          color: INK, boxShadow: "inset 0 -6px 0 rgba(0,0,0,0.12)" }}>
          <Odometer value={num} size={130} />
        </div>
        <div style={{ flex: 1, position: "relative", height: 170, overflow: "hidden" }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, color: "#8A8A8A" }}>RULE {String(st.n).padStart(2, "0")}</div>
          {si > 0 && sw < 1 && (
            <div style={{ position: "absolute", top: 44, fontWeight: 900, fontSize: 54, lineHeight: 1.05, opacity: 1 - sw, transform: `translateY(${-sw * 60}px)` }}>{prev.title}</div>
          )}
          <div style={{ position: "absolute", top: 44, fontWeight: 900, fontSize: 54, lineHeight: 1.05, opacity: sw, transform: `translateY(${(1 - sw) * 60}px)` }}>{st.title}</div>
        </div>
      </div>
      <div style={{ display: "flex", gap: 14, marginTop: 22, minHeight: 66, flexWrap: "wrap" }}>
        {(st.tokens ?? []).map((tk, i) => {
          const a = ramp(t, tk.at, tk.at + 0.25, Easing.bezier(0.3, 1.5, 0.5, 1));
          const strike = tk.strike ? ramp(t, tk.at + 0.2, tk.at + 0.45, EASE_IO) : 0;
          return (
            <div key={`${si}-${i}`} style={{ position: "relative", padding: "10px 22px", borderRadius: 18, fontWeight: 900, fontSize: 38,
              background: tk.good ? "#E7F7EC" : tk.strike ? "#FDECEC" : "#F1F0EC", color: tk.good ? "#1E9E4A" : tk.strike ? RED : INK,
              opacity: t >= tk.at ? 1 : 0, transform: `scale(${t >= tk.at ? a : 0})` }}>
              {tk.text}
              {tk.strike && <div style={{ position: "absolute", left: 10, right: 10, top: "50%", height: 6, borderRadius: 3, background: RED,
                transformOrigin: "left", transform: `scaleX(${strike}) rotate(-6deg)` }} />}
            </div>
          );
        })}
      </div>
    </Card>
  );
};

const Flash: React.FC<{ e: Base }> = ({ e }) => {
  const t = useT();
  if (!active(t, e)) return null;
  const v = 1 - Math.abs((t - e.from) / (e.to - e.from) * 2 - 1);
  return <AbsoluteFill style={{ background: "radial-gradient(circle at 70% 30%, rgba(255,240,200,1), rgba(255,200,120,0.6) 50%, rgba(255,255,255,0) 80%)", opacity: v * 0.9, mixBlendMode: "screen" }} />;
};

const keepSafe = (e: El): El => {
  switch (e.type) {
    case "slam": case "big": case "counter": case "calendar": case "cast": case "poster": case "toggle": case "list": case "chat": case "rules":
      return { ...e, y: Math.max(e.y ?? SAFE.top, SAFE.top + 10) } as El;
    case "ring": return { ...e, y: Math.max(e.y, SAFE.top + 190) };
    case "chip": return { ...e, y: Math.max(e.y, SAFE.top + 50) };
    case "sticker": {
      const r = (e.size / 2) * 0.85;
      const y = Math.max(e.y, SAFE.top + r);
      const x = y + r > SAFE.railTop ? Math.min(e.x, SAFE.right - r) : e.x;
      return { ...e, x, y };
    }
    default: return e;
  }
};

// translucent red overlay of the no-go zones, for checking stills (props.guides)
const Guides: React.FC = () => (
  <AbsoluteFill style={{ pointerEvents: "none" }}>
    {[{ left: 0, top: 0, width: 1080, height: SAFE.top }, { left: 0, top: SAFE.bottom, width: 1080, height: 1920 - SAFE.bottom },
      { left: SAFE.right, top: SAFE.railTop, width: 1080 - SAFE.right, height: SAFE.bottom - SAFE.railTop },
      { left: 0, top: SAFE.top, width: SAFE.left, height: SAFE.bottom - SAFE.top }].map((r, i) => (
      <div key={i} style={{ position: "absolute", ...r, background: "rgba(255,0,0,0.28)" }} />
    ))}
  </AbsoluteFill>
);

export const Edit: React.FC<EditProps> = (p) => {
  const t = useT();
  const { fps } = useVideoConfig();
  const cam = camera(t, p.beats);
  const whip = Math.max(0, ...(p.whips ?? []).map((w) => 1 - Math.abs(t - w.at) / 0.16));
  const whipDir = (p.whips ?? []).find((w) => Math.abs(t - w.at) < 0.16)?.dir ?? 1;
  const blurAmt = Math.max(0, ...p.blur.map((b) => window_(t, b, 0.25, 0.3))) * 16;
  const sp = p.split.find((s) => t >= s.from - 0.01 && t <= s.to);
  const splitK = sp ? window_(t, sp, 0.45, 0.4) : 0;
  const shift = sp ? sp.shift * splitK : 0;
  const els = p.elements.map(keepSafe);
  const behind = els.filter((e) => e.type === "big") as Extract<El, { type: "big" }>[];
  const front = els.filter((e) => e.type !== "big" && e.type !== "vox");
  const vox = els.filter((e) => e.type === "vox") as Extract<El, { type: "vox" }>[];
  const splitPanel = splitK > 0 && p.aurora ? <Aurora k={splitK} solid={p.aurora.solid} fade={p.aurora.fade} pal={p.pal ?? PAL} /> : splitK > 0 ? (
        <AbsoluteFill style={{ background: p.splitFade
            ? `linear-gradient(180deg, ${p.splitColor ?? CREAM} 0px, ${p.splitColor ?? CREAM} ${p.splitFade[0] * splitK}px, ${(p.splitColor ?? CREAM)}00 ${p.splitFade[1] * splitK}px)`
            : `linear-gradient(180deg, ${p.splitColor ?? CREAM} 0%, ${p.splitColor ?? CREAM} ${28 + shift / 40}%, ${(p.splitColor ?? CREAM)}00 ${46 + shift / 30}%)`,
          opacity: splitK }} />
  ) : null;
  const camStyle: React.CSSProperties = {
    transformOrigin: `${cam.ox}px ${cam.oy}px`,
    transform: `translateY(${shift}px) scale(${Math.max(1.02, cam.z)})`,
  };
  return (
    <AbsoluteFill style={{ background: CREAM, filter: whip > 0.02 ? "url(#whipblur)" : undefined,
      transform: whip > 0.02 ? `translateX(${whipDir * whip * 60}px)` : undefined }}>
      <svg width="0" height="0" style={{ position: "absolute" }}>
        <filter id="whipblur" x="-10%" y="0" width="120%" height="100%"><feGaussianBlur stdDeviation={`${whip * 46} 0`} /></filter>
      </svg>
      <AbsoluteFill style={camStyle}>
        <AbsoluteFill style={{ filter: blurAmt > 0.2 ? `blur(${blurAmt}px) brightness(${1 - blurAmt / 90})` : undefined }}>
          <OffthreadVideo src={staticFile(p.video)} style={{ width: 1080, height: 1920 }} />
        </AbsoluteFill>
        {(p.bgSwaps ?? []).map((d, i) => <BgSwap key={`bg${i}`} d={d} />)}
        {/* words behind the head stay put on screen while the camera zooms (exact inverse of camStyle),
            so they never get pushed off the frame or into the platform UI zones */}
        <AbsoluteFill style={{ transformOrigin: `${cam.ox}px ${cam.oy}px`, transform: `scale(${1 / Math.max(1.02, cam.z)}) translateY(${-shift}px)` }}>
          {p.splitUnder && splitPanel}
          {behind.map((e, i) => <Big key={i} e={e as never} />)}
          {p.ed && !p.ed.bigFront && <EdBehind items={p.ed.behind} />}
          {p.glassBehind && <GlassBehind items={p.glassBehind} pal={p.pal ?? PAL} />}
          {p.stack && <StackCaptions groups={p.stack} layer="behind" />}
        </AbsoluteFill>
        {p.person && <OffthreadVideo src={staticFile(p.person)} transparent muted style={{ position: "absolute", width: 1080, height: 1920 }} />}
      </AbsoluteFill>

      {/* soft split: a cream panel that melts into the wall instead of a hard edge */}
      {!p.splitUnder && splitPanel}

      {front.map((e, i) => {
        switch (e.type) {
          case "slam": return <Slam key={i} e={e} />;
          case "sticker": return <Sticker key={i} e={e as never} />;
          case "chip": return <Chip key={i} e={e} />;
          case "counter": return <Counter key={i} e={e} />;
          case "ring": return <Ring key={i} e={e} />;
          case "cast": return <Cast key={i} e={e} />;
          case "poster": return <Poster key={i} e={e} />;
          case "tape": return <Tape key={i} e={e} />;
          case "calendar": return <Calendar key={i} e={e} />;
          case "comment": return <Comment key={i} e={e} />;
          case "flash": return <Flash key={i} e={e} />;
          case "toggle": return <Toggle key={i} e={e} />;
          case "list": return <List key={i} e={e} />;
          case "chat": return <Chat key={i} e={e} />;
          case "rules": return <Rules key={i} e={e} />;
          default: return null;
        }
      })}

      {p.palm && <PalmDraw from={p.palm.from} to={p.palm.to} y={p.palm.y} />}
      {p.intro && <Intro from={p.intro.from} to={p.intro.to} label={p.intro.label} />}
      {p.dot && <Dot at={p.dot.at} x={p.dot.x} y={p.dot.y} />}
      {p.flow && <Flow f={p.flow} />}
      {p.shapes && <ShapeStory c={p.shapes.cues} from={p.shapes.from} to={p.shapes.to} />}
      {p.morph && <Morph m={p.morph} />}
      {p.vibe && <VibePlate d={p.vibe} />}
      {p.bold && <BoldPlate d={p.bold} />}
      {p.glass && <GlassCard d={p.glass} />}
      {p.phone && <PhoneShot d={p.phone} pal={p.pal ?? PAL} />}
      {p.receipt && <Receipt d={p.receipt} pal={p.pal ?? PAL} />}
      {p.tasks && <Tasks d={p.tasks} pal={p.pal ?? PAL} />}
      {p.brain && <Brain d={p.brain} pal={p.pal ?? PAL} />}
      {p.b1108 && <BatchCard c={p.b1108} pal={p.pal ?? PAL} />}
      {p.score && <Score d={p.score} pal={p.pal ?? PAL} />}
      {p.steam && <SteamCard d={p.steam} pal={p.pal ?? PAL} />}
      {p.proof && <ProofShot d={p.proof} pal={p.pal ?? PAL} />}
      {p.ed && p.ed.bigFront && <EdBehind items={p.ed.behind} />}
      {p.ed && <EdCards cards={p.ed.cards} />}
      {(p.kit4 ?? []).filter((e) => !K4_TOP.includes(e.type)).map((e, i) => renderK4(e, i))}
      {(p.kit2 ?? []).filter((e) => !K2_FULL.includes(e.type)).map((e, i) => renderK2(e, i, p.video))}
      {p.captionStyle === "quiet" && p.quiet ? (
        <QuietCaptions d={p.quiet} pal={p.pal ?? PAL} />
      ) : p.captionStyle === "glide" && p.glide ? (
        <GlideCaptions d={p.glide} pal={p.pal ?? PAL} />
      ) : p.captionStyle === "color" && p.colorCaps ? (
        <ColorCaps chunks={p.colorCaps.chunks} bottom={p.colorCaps.bottom} size={p.colorCaps.size} />
      ) : p.captionStyle === "editorial" && p.ed ? (
        <EdCaptions lines={p.ed.caps.lines} bottom={p.ed.caps.bottom} size={p.ed.caps.size} />
      ) : p.captionStyle === "tape" && p.tape ? (
        <TapeCaptions d={p.tape} />
      ) : p.captionStyle === "stickers" && p.stickers ? (
        <StickerCaptions d={p.stickers} />
      ) : p.captionStyle === "pills" && p.pills ? (
        <PillCaptions d={p.pills} />
      ) : p.captionStyle === "chat" && p.chat ? (
        <ChatCaptions d={p.chat} />
      ) : p.captionStyle === "levels" && p.levels ? (
        <LevelCaptions blocks={p.levels} top={p.levelsTop ?? 1130} bottom={p.levelsBottom} />
      ) : p.captionStyle === "stack" && p.stack ? (
        <StackCaptions groups={p.stack} layer="front" />
      ) : p.captionStyle === "single" && p.words ? (
        <SingleCaptions words={p.words} bottom={1920 - SAFE.bottom + 10} right={1080 - SAFE.right + 10}
          hide={[...vox, ...(p.nocap ?? []), ...(p.kit2 ?? []).filter((e) => e.type === "slate")]} />
      ) : (
        <Captions chunks={p.chunks} hide={[...vox, ...(p.nocap ?? [])]} shiftY={shift * 0.5} />
      )}
      {(p.kit2 ?? []).filter((e) => K2_FULL.includes(e.type)).map((e, i) => renderK2(e, 100 + i, p.video))}
      {vox.map((e, i) => <Vox key={i} e={e} video={p.video} />)}

      {p.ed && <EdWipe at={p.ed.wipes} />}
      {p.reveal && <LogoReveal d={p.reveal} />}
      {(p.kit4 ?? []).filter((e) => K4_TOP.includes(e.type)).map((e, i) => renderK4(e, 100 + i))}
      {p.guides && <Guides />}
      {p.sfx.map((s, i) => (
        <Sequence key={i} from={Math.round(s.t * fps)} durationInFrames={Math.round(1.5 * fps)} layout="none">
          <Audio src={staticFile(`sfx/${s.s}.wav`)} volume={s.v ?? 0.4} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
