import React from "react";
import { AbsoluteFill, Audio, Easing, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";
import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";

// Shared kit for the motion-graphics LIBRARY (one 10-15 s demo per graphic, rendered for Max to score 1-10).
// Every demo is 1080x1920, 30 fps. Graphics sit over a looping clip of Max (Backdrop) unless they are full-screen.
export const { fontFamily: UI } = loadInter("normal", { weights: ["400", "500", "700", "800", "900"], subsets: ["latin"] });
export const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
export const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });
export const { fontFamily: DISPLAY } = loadAnton("normal", { subsets: ["latin"] });

// iOS system colours (crisp, flat: Max rejects glowing/blurry "PowerPoint" shapes)
export const C = {
  blue: "#0A84FF", green: "#30D158", red: "#FF453A", gold: "#FFD60A", orange: "#FF9F0A", purple: "#BF5AF2",
  teal: "#64D2FF", pink: "#FF375F", indigo: "#5E5CE6", grey: "#8E8E93", ink: "#1C1C1E", tile: "#2C2C2E",
  cream: "#F4F1EA", paper: "#FBF8F1", white: "#FFFFFF", eqt: "#1E9BFF",
};
// platform UI no-go zones on 1080x1920: keep key text inside (top 250, bottom 1420, right rail x>900 for y 700-1420)
export const SAFE = { top: 250, bottom: 1420, left: 60, right: 900, railTop: 700 };

export const EASE = Easing.bezier(0.22, 1, 0.36, 1);
export const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
export const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
export const POP = Easing.bezier(0.3, 1.5, 0.5, 1);
export const LIQUID = Easing.bezier(0.34, 1.32, 0.64, 1);

export const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
/** 0 -> 1 between seconds a and b (clamped, eased) */
export const r = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
export const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
export const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));
/** in/out envelope: rises over `inD` after `from`, falls over `outD` before `to` */
export const env = (t: number, from: number, to: number, inD = 0.4, outD = 0.3) =>
  Math.min(r(t, from, from + inD), 1 - r(t, to - outD, to, EASE_IN));
export const typed = (text: string, t: number, at: number, cps = 0.045) =>
  Array.from(text).slice(0, Math.max(0, Math.floor((t - at) / cps))).join("");
/** gentle idle float so nothing ever sits frozen */
export const float = (t: number, seed = 0, amp = 5) =>
  `translate(${Math.sin(t * 1.2 + seed) * amp * 0.6}px, ${Math.sin(t * 1.6 + seed * 2) * amp}px)`;
/** deterministic pseudo-random 0..1 */
export const rand = (i: number) => { const x = Math.sin(i * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };
export const mix = (c1: string, c2: string, k: number) => {
  const p = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
  const a = p(c1), b = p(c2);
  return `rgb(${a.map((v, i) => Math.round(lerp(v, b[i], clamp(k)))).join(",")})`;
};

/** Max at his desk (muted loop), slightly scaled so no frame edges show. Use as the base layer for overlay graphics. */
export const Backdrop: React.FC<{ dim?: number; zoom?: number }> = ({ dim = 0, zoom = 1.04 }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <AbsoluteFill style={{ transform: `scale(${zoom})` }}>
      <OffthreadVideo src={staticFile("lib/backdrop.mp4")} muted style={{ width: 1080, height: 1920 }} />
    </AbsoluteFill>
    {dim > 0 && <AbsoluteFill style={{ background: `rgba(0,0,0,${dim})` }} />}
  </AbsoluteFill>
);

/** Max's cut-out only (transparent), same timing/zoom as Backdrop: draw it AFTER a layer to put that layer BEHIND his head. */
export const BackPerson: React.FC<{ zoom?: number }> = ({ zoom = 1.04 }) => (
  <AbsoluteFill style={{ transform: `scale(${zoom})` }}>
    <OffthreadVideo src={staticFile("lib/backdrop_person.webm")} transparent muted style={{ width: 1080, height: 1920 }} />
  </AbsoluteFill>
);

// Sound kit (editor/sfx.py, all synthesised). Max 2026-10-12: SFX were "pretty much the same" in every video, so pick by ROLE
// and vary: _b/_c are pitch variants of the busiest roles; don't put the same sound on every event type.
export type SfxName =
  | "whoosh" | "whoosh_b" | "whoosh_c" | "swish" | "swish_b" | "swish_c" | "zip"          // movement, hand-offs, wipes
  | "pop" | "pop_b" | "pop_c" | "bubble" | "drop" | "click" | "thock"                      // things appearing, taps, liquid
  | "impact" | "impact_b" | "low_hit" | "stamp"                                            // slams; low_hit only on 2-3 big reveals
  | "tick" | "tick_b" | "count_roll" | "type" | "keys"                                      // counters, typing
  | "ding" | "ding_b" | "chime" | "notif" | "coin" | "shine"                                // success, money, sparkle
  | "riser" | "metal_riser" | "glitch" | "page_flip" | "crumple" | "shutter";              // build-ups, paper, camera, tech
/** sound effect at time `at` (s) */
export const Sfx: React.FC<{ at: number; s: SfxName; v?: number }> = ({ at, s, v = 0.35 }) => {
  const { fps } = useVideoConfig();
  return (
    <Sequence from={Math.max(0, Math.round(at * fps))} durationInFrames={Math.round(1.5 * fps)} layout="none">
      <Audio src={staticFile(`sfx/${s}.wav`)} volume={v} />
    </Sequence>
  );
};
/** many sounds at once: [[t, name, vol?], ...] */
export const Sounds: React.FC<{ list: [number, Parameters<typeof Sfx>[0]["s"], number?][] }> = ({ list }) => (
  <>{list.map(([at, s, v], i) => <Sfx key={i} at={at} s={s} v={v} />)}</>
);

/** crisp graphite plate (fitted to its content; Max: a plate IS needed over his hair, but no full-width dead space) */
export const Plate: React.FC<{ x: number; y: number; w: number; h: number; k?: number; radius?: number; dark?: boolean; children?: React.ReactNode; style?: React.CSSProperties }> =
  ({ x, y, w, h, k = 1, radius = 36, dark = true, children, style }) => (
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, borderRadius: radius, overflow: "hidden",
      background: dark ? "rgba(22,22,24,0.9)" : "rgba(251,248,241,0.96)", border: `1.5px solid ${dark ? "rgba(255,255,255,0.16)" : "rgba(0,0,0,0.08)"}`,
      boxShadow: "0 22px 50px rgba(0,0,0,0.3)", color: dark ? "#fff" : C.ink, fontFamily: UI,
      opacity: clamp(k * 1.4), transform: `scale(${0.85 + 0.15 * k})`, transformOrigin: "50% 0%", ...style }}>{children}</div>
  );

/** small mono label */
export const Label: React.FC<{ children: React.ReactNode; color?: string; size?: number; style?: React.CSSProperties }> = ({ children, color = "rgba(255,255,255,0.65)", size = 28, style }) => (
  <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: size, letterSpacing: 3, color, whiteSpace: "nowrap", ...style }}>{children}</div>
);

/** odometer that rests on whole numbers */
export const Odo: React.FC<{ value: number; size: number; color?: string; font?: string; weight?: number }> = ({ value, size, color = "#fff", font = UI, weight = 900 }) => {
  const v = Math.max(0, value);
  const digits = String(Math.round(v)).length;
  const cols: number[] = [];
  for (let d = digits - 1; d >= 0; d--) {
    const p = Math.pow(10, d), base = Math.floor(v / p) % 10;
    cols.push(d === 0 ? base + (v - Math.floor(v)) : base + Math.max(0, (v % p) - (p - 1)));
  }
  return (
    <div style={{ display: "flex", height: size * 1.05, overflow: "hidden", color }}>
      {cols.map((c, i) => (
        <div key={i} style={{ height: size * 1.05, overflow: "hidden" }}>
          <div style={{ transform: `translateY(${-c * size * 1.05}px)` }}>
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
              <div key={j} style={{ height: size * 1.05, fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: font, fontWeight: weight, textAlign: "center" }}>{n}</div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};

/** SVG goo filter (liquid merges with CRISP edges): put <GooDefs id="g"/> in an <svg>, then <g filter="url(#g)">. Use ONE fill colour inside the goo group or the colours smear. */
export const GooDefs: React.FC<{ id: string; blur?: number }> = ({ id, blur = 10 }) => (
  <defs>
    <filter id={id}><feGaussianBlur in="SourceGraphic" stdDeviation={blur} result="b" />
      <feColorMatrix in="b" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 24 -11" /></filter>
  </defs>
);

/** a short caption line in the house style, so overlay demos read like a real edit (optional) */
export const DemoCaption: React.FC<{ text: string; from: number; to: number; y?: number }> = ({ text, from, to, y = 1300 }) => {
  const t = useT();
  if (t < from || t > to) return null;
  const k = env(t, from, to, 0.18, 0.2);
  return (
    <div style={{ position: "absolute", left: 80, right: 180, top: y, textAlign: "center", fontFamily: UI, fontWeight: 800, fontSize: 60, color: "#fff",
      lineHeight: 1.15, opacity: k, transform: `translateY(${(1 - k) * 16}px)`, textShadow: "0 3px 2px rgba(0,0,0,0.35), 0 6px 24px rgba(0,0,0,0.55)" }}>{text}</div>
  );
};

export type LibItem = {
  id: string;            // e.g. "m1-03"
  title: string;         // short name shown in the gallery
  family: string;        // e.g. "Shape stories"
  note: string;          // one line: what it shows / when to use it in a video
  dur: number;           // seconds, 10-15
  C: React.FC;           // the demo (draws its own Backdrop/background + sounds)
};
