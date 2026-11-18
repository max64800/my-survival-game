import React from "react";
import { AbsoluteFill } from "remotion";
import { loadFont as loadPoppins } from "@remotion/google-fonts/Poppins";
import { loadFont as loadPlayfair } from "@remotion/google-fonts/PlayfairDisplay";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadBodoni } from "@remotion/google-fonts/BodoniModa";
import { loadFont as loadComic } from "@remotion/google-fonts/ComicNeue";
import { loadFont as loadMarker } from "@remotion/google-fonts/PermanentMarker";
import { loadFont as loadGaramond } from "@remotion/google-fonts/EBGaramond";
import { loadFont as loadVibes } from "@remotion/google-fonts/GreatVibes";
import { measureText } from "@remotion/layout-utils";
import { useT, r, lerp, clamp, rand, EASE, EASE_IN, EASE_IO, UI, SERIF, DISPLAY, Sfx, Sounds } from "../lib/common";
import { CapItem, Clip, Person, WORDS, Word, isKey } from "./capcommon";

// Caption lab, batch c1: 10 caption styles on the same 11.65 s clip of Max (vibe coders).
// Clip: shot 1 0-5.77 s (wide, he leans in from ~2.6 s), shot 2 5.77-9.5 s (he sits right, wall free on the left),
// shot 3 9.5 s-end (centred). Hair top ≈ y 360-480, chin ≈ y 880-1160, so the caption zone is his chest (y ≈ 1150-1410)
// and the wall above / beside his head (behind him, via Person).

const { fontFamily: POPPINS } = loadPoppins("normal", { weights: ["300", "600", "800"], subsets: ["latin"] });
const { fontFamily: PLAYFAIR } = loadPlayfair("italic", { weights: ["900"], subsets: ["latin"] });
loadInter("normal", { weights: ["300"], subsets: ["latin"] });
const { fontFamily: BODONI } = loadBodoni("normal", { weights: ["400", "700", "900"], subsets: ["latin"] });
loadBodoni("italic", { weights: ["400", "700"], subsets: ["latin"] });
const { fontFamily: COMIC } = loadComic("normal", { weights: ["700"], subsets: ["latin"] });
const { fontFamily: MARKER } = loadMarker("normal", { subsets: ["latin"] });
const { fontFamily: GARAMOND } = loadGaramond("normal", { weights: ["500"], subsets: ["latin"] });
const { fontFamily: VIBES } = loadVibes("normal", { subsets: ["latin"] });

const W = WORDS;
const ids = (a: number, b: number) => Array.from({ length: b - a + 1 }, (_, i) => a + i);
const SHADOW = "0 3px 2px rgba(0,0,0,0.35), 0 6px 24px rgba(0,0,0,0.55)";
const SOFT = "0 2px 4px rgba(0,0,0,0.35), 0 8px 30px rgba(0,0,0,0.45)";
/** the word being spoken (or the last one, held through pauses) */
const currentWord = (t: number) => {
  let c = -1;
  for (let i = 0; i < W.length; i++) if (W[i].s - 0.02 <= t) c = i;
  return c;
};

// =====================================================================================================================
// c1-01 House levels (our current caption: Inter 800 + rotating key-word looks, lines stack then clear)
// =====================================================================================================================
const YELLOW = "#FFD600";
const INK = "#141414";
const HOUSE_EM: Record<number, number> = { 8: 1, 10: 0, 15: 2, 17: 1, 24: 0, 25: 0, 31: 2, 34: 1 };
const houseWord = (i: number, t: number) => {
  const w = W[i];
  const said = t >= w.s;
  const pop = r(t, w.s, w.s + 0.12);
  const base: React.CSSProperties = { opacity: said ? 1 : 0.42, display: "inline-block", position: "relative",
    transform: `scale(${said ? 1 + (1 - pop) * 0.12 : 1})` };
  const variant = HOUSE_EM[i];
  if (variant === undefined) {
    return <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 800, fontSize: 62, color: "#FFFFFF", lineHeight: 1.15,
      letterSpacing: -0.5, textShadow: SHADOW }}>{w.w}</span>;
  }
  if (variant === 1) {
    const m = r(t, w.s, w.s + 0.25, EASE_IO);
    return (
      <span key={i} style={{ ...base, fontFamily: UI, fontWeight: 900, fontSize: 70, color: INK, lineHeight: 1.15, padding: "0 10px" }}>
        <span style={{ position: "absolute", left: 0, right: 0, top: "12%", bottom: "8%", background: YELLOW, borderRadius: 10,
          transformOrigin: "left", transform: `scaleX(${said ? m : 0}) rotate(-1.5deg)` }} />
        <span style={{ position: "relative", color: said && m > 0.5 ? INK : "#FFFFFF", textShadow: said && m > 0.5 ? "none" : SHADOW }}>{w.w}</span>
      </span>
    );
  }
  if (variant === 2) {
    return <span key={i} style={{ ...base, fontFamily: DISPLAY, fontSize: 78, color: INK, background: "#FFFFFF", padding: "2px 18px",
      borderRadius: 12, textTransform: "uppercase", lineHeight: 1.1, boxShadow: "0 10px 26px rgba(0,0,0,0.35)",
      transform: `${base.transform} rotate(-3deg)` }}>{w.w}</span>;
  }
  return <span key={i} style={{ ...base, fontFamily: SERIF, fontStyle: "italic", fontSize: 96, color: YELLOW, lineHeight: 1.0,
    letterSpacing: -1, textShadow: SHADOW }}>{w.w}</span>;
};
type HBlock = { from: number; to: number; lines: { from: number; ids: number[] }[] };
const HOUSE: HBlock[] = [
  { from: 0.03, to: 2.95, lines: [{ from: 0.05, ids: [0, 1, 2] }, { from: 0.84, ids: [3, 4] }, { from: 1.42, ids: [5, 6, 7, 8] }] },
  { from: 2.96, to: 5.68, lines: [{ from: 2.98, ids: [9, 10] }, { from: 4.18, ids: [11, 12, 13, 14] }, { from: 5.0, ids: [15] }] },
  { from: 5.72, to: 7.19, lines: [{ from: 5.76, ids: [16, 17] }, { from: 6.41, ids: [18, 19, 20, 21] }] },
  { from: 7.19, to: 9.45, lines: [{ from: 7.21, ids: [22, 23] }, { from: 8.03, ids: [24, 25, 26] }] },
  { from: 9.46, to: 12.1, lines: [{ from: 9.49, ids: [27, 28] }, { from: 10.04, ids: [29, 30, 31] }, { from: 10.94, ids: [32, 33, 34] }] },
];
const C101: React.FC = () => {
  const t = useT();
  const b = HOUSE.find((x) => t >= x.from && t < x.to);
  let cap: React.ReactNode = null;
  if (b) {
    const out = r(t, b.to - 0.22, b.to, EASE_IN);
    const shown = b.lines.filter((x) => t >= x.from).length;
    cap = (
      <div style={{ position: "absolute", left: 80, right: 170, top: 1150, display: "flex", flexDirection: "column", alignItems: "center", gap: 2,
        opacity: 1 - out, transform: `translateY(${-out * 30}px)` }}>
        {b.lines.map((l, li) => {
          if (t < l.from) return null;
          const k = r(t, l.from, l.from + 0.16);
          const newest = li === shown - 1;
          return (
            <div key={li} style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", alignItems: "center", columnGap: 14,
              opacity: k * (newest ? 1 : 0.78), transform: `translateY(${(1 - k) * 16}px) scale(${newest ? 1 : 0.94})` }}>
              {l.ids.map((i) => houseWord(i, t))}
            </div>
          );
        })}
      </div>
    );
  }
  return (<AbsoluteFill><Clip />{cap}</AbsoluteFill>);
};

// =====================================================================================================================
// c1-02 Kelssie (@kelssie3): Layer A = one plain Poppins word under the chin (hard cuts); Layer B = headline lockups
// (thin / heavy / pink italic serif) that blur-rise in line by line, drift up, blur out; heroes behind his head.
// =====================================================================================================================
const PINK = "#F800D8";
type KV = "thin" | "heavy" | "accent";
type KLine = { ids: number[]; v: KV; dx?: number; size?: number; color?: string; caps?: boolean; vv?: Record<number, KV> };
type KStack = { from: number; to: number; x: number; y: number; behind: boolean; lines: KLine[]; allowA?: boolean };
const kStyle = (v: KV, size: number | undefined, color: string | undefined, caps?: boolean): React.CSSProperties => {
  if (v === "thin") return { fontFamily: POPPINS, fontWeight: 300, fontSize: size ?? 70, color: color ?? "#fff", lineHeight: 1.0, letterSpacing: -0.5 };
  if (v === "heavy") return { fontFamily: POPPINS, fontWeight: 800, fontSize: size ?? 128, color: color ?? "#fff", lineHeight: 0.92, letterSpacing: -3,
    textTransform: caps ? "uppercase" : undefined };
  return { fontFamily: PLAYFAIR, fontStyle: "italic", fontWeight: 900, fontSize: size ?? 150, color: color ?? PINK, lineHeight: 0.95, letterSpacing: -2 };
};
/** one Kelssie-like lockup; every word blur-rises on its own spoken time */
const KStackView: React.FC<{ s: KStack; t: number; font?: (v: KV, size?: number, color?: string, caps?: boolean) => React.CSSProperties; shadow?: string; drift?: number }> =
  ({ s, t, font = kStyle, shadow = SOFT, drift = 20 }) => {
    const out = r(t, s.to - 0.24, s.to, EASE_IN);
    return (
      <div style={{ position: "absolute", left: s.x, top: s.y, transform: `translate(-50%, ${-(t - s.from) * drift - out * 20}px)`,
        display: "flex", flexDirection: "column", alignItems: "center", opacity: 1 - out, filter: `blur(${out * 12}px)`, whiteSpace: "nowrap" }}>
        {s.lines.map((l, li) => (
          <div key={li} style={{ display: "flex", gap: 22, alignItems: "baseline", transform: `translateX(${l.dx ?? 0}px)`, marginTop: li ? -6 : 0 }}>
            {l.ids.map((i) => {
              const w = W[i];
              const v = l.vv?.[i] ?? l.v;
              const k = r(t, w.s - 0.03, w.s + 0.15, EASE);
              const fs = font(v, v === l.v ? l.size : undefined, v === l.v ? l.color : undefined, l.caps);
              const clipText = fs.textShadow === "none";
              return (
                <span key={i} style={{ ...fs, display: "inline-block", opacity: k, transform: `translateY(${(1 - k) * 50}px) scale(${0.96 + 0.04 * k})`,
                  filter: `blur(${(1 - k) * 12}px)${clipText ? " drop-shadow(0 3px 6px rgba(0,0,0,0.55))" : ""}`, textShadow: clipText ? "none" : shadow }}>{w.w}</span>
              );
            })}
          </div>
        ))}
      </div>
    );
  };
const KELSSIE: KStack[] = [
  { from: 1.39, to: 2.96, x: 300, y: 330, behind: false, lines: [
    { ids: [5, 6], v: "thin", dx: -40 }, { ids: [7], v: "heavy", dx: 30, size: 150 }, { ids: [8], v: "accent", dx: -10, size: 170 }] },
  { from: 2.95, to: 4.16, x: 470, y: 1080, behind: false, lines: [{ ids: [9], v: "thin", dx: -150 }, { ids: [10], v: "heavy", size: 230, color: PINK }] },
  { from: 4.79, to: 5.72, x: 500, y: 1110, behind: false, lines: [{ ids: [14], v: "thin", dx: -90 }, { ids: [15], v: "accent", size: 180, dx: 30 }] },
  { from: 5.73, to: 7.2, x: 300, y: 320, behind: true, lines: [
    { ids: [16], v: "thin", dx: -50 }, { ids: [17], v: "heavy", caps: true, size: 112 }, { ids: [18, 19], v: "thin", dx: 50 },
    { ids: [20, 21], v: "accent", dx: -20, vv: { 20: "thin" } }] },
  { from: 8.0, to: 9.42, x: 300, y: 360, behind: true, lines: [
    { ids: [24], v: "heavy", caps: true, size: 170, color: PINK }, { ids: [25], v: "accent", color: "#fff", dx: 40 }, { ids: [26], v: "thin", dx: -60 }] },
  { from: 9.46, to: 10.2, x: 540, y: 255, behind: true, allowA: true, lines: [{ ids: [27], v: "heavy", caps: true, size: 240 }] },
  { from: 10.21, to: 12.0, x: 500, y: 1010, behind: false, lines: [
    { ids: [30], v: "thin", dx: -70 }, { ids: [31], v: "heavy", size: 170, color: PINK }, { ids: [32, 33, 34], v: "thin", dx: 50, vv: { 34: "accent" } }] },
];
const C102: React.FC = () => {
  const t = useT();
  const act = KELSSIE.filter((s) => t >= s.from && t < s.to);
  const blockA = act.some((s) => !s.allowA);
  const ci = currentWord(t);
  const showA = !blockA && ci >= 0 && ci !== 27 && t < W[W.length - 1].e + 0.5;
  const ax = t < 5.77 ? 560 : t < 9.5 ? 640 : 540;
  return (
    <AbsoluteFill>
      <Clip />
      {act.filter((s) => s.behind).map((s, i) => <KStackView key={i} s={s} t={t} />)}
      <Person />
      {act.filter((s) => !s.behind).map((s, i) => <KStackView key={i} s={s} t={t} />)}
      {showA && (
        <div style={{ position: "absolute", left: ax, top: 1255, transform: "translateX(-50%)", fontFamily: POPPINS, fontWeight: 600, fontSize: 100,
          color: "#F8F8F8", whiteSpace: "nowrap", lineHeight: 1, textShadow: "0 2px 12px rgba(0,0,0,0.3)" }}>{W[ci].w}</div>
      )}
      <Sounds list={KELSSIE.map((s) => [s.from + 0.03, "swish", 0.14] as [number, "swish", number])} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-03 Kelssie twist "depth pull": each lockup builds in front of his chest; when the next one arrives the old one
// sinks BEHIND his body and rises out above his head as a dim echo, while the camera slowly pushes in per lockup.
// =====================================================================================================================
const GOLD_GRAD = "linear-gradient(180deg, #FFF6D0 0%, #FFDB7A 45%, #F0B24A 100%)";
const tStyle = (v: KV, size?: number, color?: string, caps?: boolean): React.CSSProperties => {
  if (v === "thin") return { fontFamily: UI, fontWeight: 300, fontSize: size ?? 64, color: color ?? "#fff", lineHeight: 1.05, letterSpacing: -0.5 };
  if (v === "heavy") return { fontFamily: UI, fontWeight: 800, fontSize: size ?? 112, color: color ?? "#fff", lineHeight: 0.95, letterSpacing: -3,
    textTransform: caps ? "uppercase" : undefined };
  return { fontFamily: SERIF, fontStyle: "italic", fontSize: size ?? 136, lineHeight: 0.95, letterSpacing: -1, color: "transparent",
    backgroundImage: GOLD_GRAD, WebkitBackgroundClip: "text", backgroundClip: "text", padding: "0 10px", textShadow: "none" };
};
const TWIST: KStack[] = [
  { from: 0.03, to: 2.97, x: 480, y: 1110, behind: false, lines: [
    { ids: [0, 1, 2], v: "thin", dx: -40 }, { ids: [3, 4], v: "heavy", dx: 30, vv: { 3: "thin" } }, { ids: [5, 6, 7, 8], v: "thin", dx: -10, vv: { 7: "accent", 8: "accent" } }] },
  { from: 2.97, to: 4.17, x: 470, y: 1150, behind: false, lines: [{ ids: [9], v: "thin", dx: -110 }, { ids: [10], v: "heavy", size: 170 }] },
  { from: 4.17, to: 5.74, x: 480, y: 1170, behind: false, lines: [{ ids: [11, 12, 13, 14], v: "thin", dx: -30 }, { ids: [15], v: "accent", size: 170, dx: 40 }] },
  { from: 5.74, to: 7.2, x: 440, y: 1120, behind: false, lines: [
    { ids: [16], v: "thin", dx: -80 }, { ids: [17], v: "heavy", caps: true }, { ids: [18, 19, 20, 21], v: "thin", dx: 40, vv: { 21: "accent" } }] },
  { from: 7.2, to: 9.46, x: 450, y: 1120, behind: false, lines: [
    { ids: [22, 23], v: "thin", dx: -40 }, { ids: [24, 25], v: "heavy", vv: { 25: "accent" } }, { ids: [26], v: "thin", dx: 90 }] },
  { from: 9.46, to: 10.92, x: 480, y: 1130, behind: false, lines: [{ ids: [27, 28, 29], v: "thin", dx: -30 }, { ids: [30, 31], v: "heavy", size: 150, vv: { 30: "thin" } }] },
  { from: 10.92, to: 12.1, x: 480, y: 1170, behind: false, lines: [{ ids: [32, 33], v: "thin", dx: -60 }, { ids: [34], v: "accent", size: 180, dx: 30 }] },
];
const C103: React.FC = () => {
  const t = useT();
  const ci = TWIST.findIndex((s) => t >= s.from && t < s.to);
  // slow push per lockup + a small punch on each new one
  const zoom = 1.03 + 0.05 * clamp(t / 12) + (ci >= 0 ? 0.02 * r(t, TWIST[ci].from, TWIST[ci].from + 0.35) - 0.02 * r(t, TWIST[ci].to - 0.35, TWIST[ci].to) : 0);
  const cur = ci >= 0 ? TWIST[ci] : null;
  const prev = ci > 0 ? TWIST[ci - 1] : null;
  // the previous lockup sinks behind him and rises above his head as a dim echo
  let ghost: React.ReactNode = null;
  if (prev && cur) {
    const k = r(t, cur.from, cur.from + 0.6, EASE);
    const fade = r(t, cur.to - 0.3, cur.to);
    const gs: KStack = { ...prev, to: 99 };
    ghost = (
      <div style={{ position: "absolute", inset: 0, opacity: lerp(1, 0.42, k) * (1 - fade),
        transform: `translateY(${lerp(0, 300 - prev.y, k)}px) scale(${lerp(1, 0.62, k)})`, transformOrigin: `${prev.x}px ${prev.y}px`,
        filter: `blur(${k * 1.5}px)` }}>
        <KStackView s={gs} t={t} font={tStyle} shadow={SOFT} drift={0} />
      </div>
    );
  }
  return (
    <AbsoluteFill>
      <Clip zoom={zoom} />
      {ghost}
      <Person zoom={zoom} />
      {cur && <KStackView s={{ ...cur, to: cur.to + 5 }} t={t} font={tStyle} shadow={SHADOW} drift={6} />}
      <Sounds list={TWIST.slice(1).map((s) => [s.from, "whoosh", 0.12] as [number, "whoosh", number])} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-04 Paper unfold: each phrase is a slightly crumpled paper note that unfolds at its crease (shaded fold, halftone
// in the crease shadow), comic lettering inked word by word, key words on a yellow halftone patch, a tail toward him.
// =====================================================================================================================
type Note = { from: number; to: number; ids: number[]; tilt: number; tail: number };
const NOTES: Note[] = [
  { from: 0.03, to: 1.4, ids: ids(0, 4), tilt: -2, tail: 640 },
  { from: 1.4, to: 2.96, ids: ids(5, 8), tilt: 1.6, tail: 640 },
  { from: 2.96, to: 5.72, ids: ids(9, 15), tilt: -1.4, tail: 560 },
  { from: 5.72, to: 7.19, ids: ids(16, 21), tilt: 1.8, tail: 720 },
  { from: 7.19, to: 9.46, ids: ids(22, 26), tilt: -1.6, tail: 720 },
  { from: 9.46, to: 12.2, ids: ids(27, 34), tilt: 1.2, tail: 560 },
];
const NOTE_FONT = 68, NOTE_LH = 76, CH = 38, SP = 20;
const noteLayout = (n: Note) => {
  const words = n.ids.map((i) => W[i].w.length * CH);
  const total = words.reduce((a, b) => a + b, 0) + SP * (words.length - 1);
  const w = Math.round(clamp((total + 130) / 820, 520 / 820, 1) * 820);
  const usable = w - 130;
  let lines = 1, cur = 0;
  for (const ww of words) { if (cur && cur + SP + ww > usable) { lines++; cur = ww; } else cur += (cur ? SP : 0) + ww; }
  return { w, h: lines * NOTE_LH + 104 };
};
const PaperDefs: React.FC = () => (
  <svg width={0} height={0} style={{ position: "absolute" }}>
    <defs>
      <filter id="c104-crumple" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency="0.022" numOctaves={4} seed={7} result="n" />
        <feDiffuseLighting in="n" lightingColor="#ffffff" surfaceScale={2.6} result="l">
          <feDistantLight azimuth={235} elevation={58} />
        </feDiffuseLighting>
      </filter>
      <pattern id="c104-dots" width={9} height={9} patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
        <circle cx={4.5} cy={4.5} r={1.9} fill="#2A2118" />
      </pattern>
      <pattern id="c104-ydots" width={11} height={11} patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
        <circle cx={5.5} cy={5.5} r={3.6} fill="#FFC928" />
      </pattern>
      <linearGradient id="c104-fadeDown" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#fff" stopOpacity={1} /><stop offset="1" stopColor="#fff" stopOpacity={0} />
      </linearGradient>
      <mask id="c104-creaseMask" maskContentUnits="objectBoundingBox"><rect width={1} height={1} fill="url(#c104-fadeDown)" /></mask>
    </defs>
  </svg>
);
const PAPER = "#FBF5E6";
/** the full face of a note (paper + texture + lettering), drawn at w x h */
const NoteFace: React.FC<{ n: Note; w: number; h: number; t: number }> = ({ n, w, h, t }) => (
  <div style={{ position: "absolute", left: 0, top: 0, width: w, height: h, background: PAPER, borderRadius: 6, overflow: "hidden" }}>
    <svg width={w} height={h} style={{ position: "absolute", inset: 0, mixBlendMode: "multiply", opacity: 0.85 }}>
      <rect width={w} height={h} filter="url(#c104-crumple)" />
    </svg>
    {/* a faint second crease (vertical) and the comic panel border */}
    <div style={{ position: "absolute", top: 0, bottom: 0, left: w * 0.66, width: 18, background: "linear-gradient(90deg, rgba(0,0,0,0.05), rgba(255,255,255,0.5) 45%, rgba(0,0,0,0.06))" }} />
    <div style={{ position: "absolute", inset: 16, border: "3.5px solid #241C14", borderRadius: 4 }} />
    <div style={{ position: "absolute", left: 52, right: 52, top: 0, bottom: 0, display: "flex", flexWrap: "wrap", justifyContent: "center", alignContent: "center",
      columnGap: SP, rowGap: 0 }}>
      {n.ids.map((i) => {
        const wd = W[i];
        const k = r(t, wd.s - 0.02, wd.s + 0.12);
        const key = isKey(wd);
        const patch = r(t, wd.s, wd.s + 0.2, EASE);
        return (
          <span key={i} style={{ position: "relative", display: "inline-block", fontFamily: COMIC, fontWeight: 700, fontSize: NOTE_FONT, lineHeight: `${NOTE_LH}px`,
            textTransform: "uppercase", letterSpacing: 0.5, color: key ? "#D3261C" : "#241C14", opacity: 0.13 + 0.87 * k, transform: `scale(${k > 0 ? 1 + (1 - k) * 0.15 : 1})` }}>
            {key && (
              <svg style={{ position: "absolute", left: -12, right: -12, top: 6, bottom: 2, width: "calc(100% + 24px)", height: "calc(100% - 8px)",
                transform: `scale(${patch}) rotate(-2deg)`, overflow: "visible" }}>
                <rect width="100%" height="100%" rx={8} fill="url(#c104-ydots)" />
              </svg>
            )}
            <span style={{ position: "relative" }}>{wd.w}</span>
          </span>
        );
      })}
    </div>
  </div>
);
const NoteView: React.FC<{ n: Note; t: number }> = ({ n, t }) => {
  const { w, h } = noteLayout(n);
  const cx = 470, bottom = 1408, top = bottom - h;
  const u = r(t, n.from, n.from + 0.45, EASE);
  const f = r(t, n.to - 0.26, n.to, EASE_IN);
  const ang = (1 - u) * 172 + f * 172;           // bottom half folded up over the top half
  const appear = r(t, n.from, n.from + 0.1);
  const leave = r(t, n.to - 0.1, n.to);
  const half = h / 2;
  const shade = Math.sin((ang * Math.PI) / 180);  // darkness of the moving half
  return (
    <div style={{ position: "absolute", left: cx - w / 2, top, width: w, height: h, perspective: 1400,
      opacity: appear * (1 - leave), transform: `rotate(${n.tilt}deg) scale(${0.94 + 0.06 * u}) translateY(${f * 30}px)`, transformOrigin: "50% 50%",
      filter: "drop-shadow(0 10px 14px rgba(0,0,0,0.28))" }}>
      {/* speech tail toward him */}
      <svg width={120} height={70} style={{ position: "absolute", left: n.tail - (cx - w / 2) - 40, top: -56, overflow: "visible" }}>
        <path d="M 0 60 L 46 60 L 76 26 Z" fill={PAPER} stroke="#241C14" strokeWidth={3.5} strokeLinejoin="round" />
        <rect x={-2} y={56} width={52} height={10} fill={PAPER} />
      </svg>
      {/* top half (fixed) */}
      <div style={{ position: "absolute", left: 0, top: 0, width: w, height: half, overflow: "hidden" }}>
        <NoteFace n={n} w={w} h={h} t={t} />
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 14, background: "linear-gradient(180deg, rgba(0,0,0,0), rgba(0,0,0,0.08))" }} />
        {/* shadow cast by the half folding over it */}
        <div style={{ position: "absolute", inset: 0, background: `rgba(40,28,10,${0.25 * shade * (ang > 90 ? 1 : 0.4)})` }} />
      </div>
      {/* bottom half, hinged at the crease */}
      <div style={{ position: "absolute", left: 0, top: half, width: w, height: half, transformOrigin: "50% 0%", transformStyle: "preserve-3d",
        transform: `rotateX(${ang}deg)` }}>
        <div style={{ position: "absolute", inset: 0, overflow: "hidden", backfaceVisibility: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: -half, width: w, height: h }}><NoteFace n={n} w={w} h={h} t={t} /></div>
          {/* crease: halftone shadow just under the fold */}
          <svg width={w} height={44} style={{ position: "absolute", left: 0, top: 0, opacity: 0.22 }}>
            <rect width={w} height={44} fill="url(#c104-dots)" mask="url(#c104-creaseMask)" />
          </svg>
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 3, background: "rgba(255,255,255,0.8)" }} />
          <div style={{ position: "absolute", inset: 0, background: `rgba(30,20,8,${0.35 * shade})` }} />
        </div>
        {/* back of the paper */}
        <div style={{ position: "absolute", inset: 0, background: "#EFE6CF", transform: "rotateX(180deg)", backfaceVisibility: "hidden", overflow: "hidden" }}>
          <svg width={w} height={half} style={{ position: "absolute", inset: 0, opacity: 0.18 }}><rect width={w} height={half} fill="url(#c104-dots)" /></svg>
          <div style={{ position: "absolute", inset: 0, background: `rgba(30,20,8,${0.2 * (1 - shade)})` }} />
        </div>
      </div>
    </div>
  );
};
const C104: React.FC = () => {
  const t = useT();
  const n = NOTES.find((x) => t >= x.from && t < x.to);
  return (
    <AbsoluteFill>
      <Clip />
      <PaperDefs />
      {n && <NoteView n={n} t={t} />}
      <Sounds list={NOTES.map((x) => [x.from, "swish", 0.22] as [number, "swish", number])} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-05 Serif + script stack (karan.mp4_): book serif words + ONE connected-script payoff word, zig-zag 2-line stacks,
// blur-in on the spoken word, dim-out in reading order. BIG (serif 92 / script 170) and held until the next stack.
// =====================================================================================================================
type SLine = { ids: number[]; script?: number[]; x: number; align: "left" | "right"; top: number; size?: number };
type SGroup = { from: number; to: number; lines: SLine[] };
const STACK: SGroup[] = [
  { from: 0.03, to: 1.41, lines: [{ ids: [0, 1, 2], x: 110, align: "left", top: 1150 }, { ids: [3, 4], script: [4], x: 880, align: "right", top: 1225 }] },
  { from: 1.41, to: 2.97, lines: [{ ids: [5, 6], x: 150, align: "left", top: 1160 }, { ids: [7, 8], script: [8], x: 860, align: "right", top: 1215 }] },
  { from: 2.97, to: 4.17, lines: [{ ids: [9], x: 170, align: "left", top: 1170 }, { ids: [10], x: 820, align: "right", top: 1165, size: 190 }] },
  { from: 4.17, to: 5.73, lines: [{ ids: [11, 12, 13, 14], x: 110, align: "left", top: 1150 }, { ids: [15], script: [15], x: 860, align: "right", top: 1215 }] },
  { from: 5.73, to: 7.2, lines: [{ ids: [16, 17], script: [17], x: 110, align: "left", top: 1120 }, { ids: [18, 19, 20, 21], x: 870, align: "right", top: 1300 }] },
  { from: 7.2, to: 9.46, lines: [{ ids: [22, 23], x: 110, align: "left", top: 1150 }, { ids: [24, 25, 26], script: [25], x: 870, align: "right", top: 1225 }] },
  { from: 9.46, to: 10.92, lines: [{ ids: [27, 28, 29], x: 110, align: "left", top: 1150 }, { ids: [30, 31], x: 870, align: "right", top: 1245, size: 120 }] },
  { from: 10.92, to: 12.2, lines: [{ ids: [32, 33], x: 170, align: "left", top: 1160 }, { ids: [34], script: [34], x: 840, align: "right", top: 1200 }] },
];
const STACK_SHADOW = "0 3px 10px rgba(0,0,0,0.6), 0 0 2px rgba(0,0,0,0.4)";
const C105: React.FC = () => {
  const t = useT();
  const g = STACK.find((x) => t >= x.from && t < x.to);
  return (
    <AbsoluteFill>
      <Clip />
      {g && g.lines.map((l, li) => {
        const outAt = g.to - 0.3 + li * 0.1;
        const dim = r(t, outAt, outAt + 0.1);
        const gone = r(t, outAt + 0.1, outAt + 0.2);
        const size = l.size ?? 92;
        return (
          <div key={li} style={{ position: "absolute", top: l.top, ...(l.align === "left" ? { left: l.x } : { right: 1080 - l.x }), display: "flex", gap: size * 0.26,
            alignItems: "baseline", whiteSpace: "nowrap", opacity: (1 - dim * 0.5) * (1 - gone), filter: `grayscale(${dim}) blur(${gone * 6}px)` }}>
            {l.ids.map((i) => {
              const w = W[i];
              const sc = l.script?.includes(i);
              const k = r(t, w.s - 0.02, w.s - 0.02 + (sc ? 0.28 : 0.2));
              return (
                <span key={i} style={{ display: "inline-block", fontFamily: sc ? VIBES : GARAMOND, fontWeight: sc ? 400 : 500, fontSize: sc ? 170 : size,
                  lineHeight: sc ? 0.9 : 1.0, letterSpacing: sc ? 0 : -0.5, color: "#fff", opacity: k, transform: `scale(${1.06 - 0.06 * k})`,
                  filter: `blur(${(1 - k) * (sc ? 18 : 12)}px) brightness(${1 + (1 - k) * 0.6})`, textShadow: STACK_SHADOW, padding: sc ? "0 14px" : 0 }}>{w.w}</span>
              );
            })}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-06 Quiet luxury one-word (@calsaistudio): one word at a time on his chest, white Inter medium, key words in white
// italic serif with a hairline underline. Soft 0.14 s blur-in, nothing else.
// =====================================================================================================================
const C106: React.FC = () => {
  const t = useT();
  const ci = currentWord(t);
  const end = W[W.length - 1].e + 0.5;
  let cap: React.ReactNode = null;
  if (ci >= 0 && t < end) {
    const w = W[ci];
    const key = isKey(w);
    const k = r(t, w.s - 0.02, w.s + 0.14);
    const out = r(t, end - 0.25, end);
    const x = t < 2.6 ? 640 : t < 5.77 ? 540 : t < 9.5 ? 620 : 540;
    const line = r(t, w.s + 0.08, w.s + 0.4, EASE);
    cap = (
      <div style={{ position: "absolute", left: x, top: key ? 1205 : 1235, transform: `translate(-50%, ${(1 - k) * 10}px)`, opacity: k * (1 - out),
        filter: `blur(${(1 - k) * 6}px)`, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <span style={{ fontFamily: key ? SERIF : UI, fontStyle: key ? "italic" : "normal", fontWeight: key ? 400 : 500, fontSize: key ? 150 : 98,
          letterSpacing: key ? -1 : -1.5, color: "#fff", whiteSpace: "nowrap", lineHeight: 1.05, textShadow: "0 2px 14px rgba(0,0,0,0.45)" }}>{w.w}</span>
        {key && <div style={{ width: `${line * 100}%`, height: 2, background: "rgba(255,255,255,0.9)", marginTop: 2, boxShadow: "0 1px 4px rgba(0,0,0,0.3)" }} />}
      </div>
    );
  }
  return (<AbsoluteFill><Clip />{cap}</AbsoluteFill>);
};

// =====================================================================================================================
// c1-07 Behind the head: the SETUP word stands huge on the wall between him and the wall (rises from behind his head),
// the running words + the PAYOFF sit in front on his chest (payoff in big yellow Anton, slammed on the word).
// =====================================================================================================================
const NAVY = "#14264A";
type BWord = { ids: number[]; from: number; to: number; x: number; size: number };
const BEHIND: BWord[] = [
  { ids: [0, 1], from: 0.03, to: 2.95, x: 560, size: 200 },
    { ids: [17], from: 6.0, to: 9.42, x: 360, size: 200 },
  { ids: [28], from: 9.66, to: 12.1, x: 540, size: 180 },
];
type FSeg = { ids: number[]; from: number; to: number; pay?: boolean; size?: number };
const FRONT: FSeg[] = [
  { ids: [2, 3, 4], from: 0.5, to: 1.41 },
  { ids: [5, 6, 7, 8], from: 1.41, to: 2.97 },
  { ids: [9], from: 2.97, to: 3.24 },
  { ids: [10], from: 3.24, to: 4.17, pay: true, size: 230 },
  { ids: [11, 12, 13, 14], from: 4.17, to: 4.98 },
  { ids: [15], from: 4.98, to: 5.73, pay: true, size: 190 },
  { ids: [16, 17], from: 5.73, to: 6.4 },
  { ids: [18, 19, 20, 21], from: 6.4, to: 7.2 },
  { ids: [22, 23], from: 7.2, to: 8.01 },
  { ids: [24, 25, 26], from: 8.01, to: 9.46, pay: true, size: 130 },
  { ids: [27, 28, 29, 30], from: 9.46, to: 10.42 },
  { ids: [31, 32, 33, 34], from: 10.42, to: 12.2, pay: true, size: 130 },
];
const C107: React.FC = () => {
  const t = useT();
  const b = BEHIND.find((x) => t >= x.from && t < x.to);
  const f = FRONT.find((x) => t >= x.from && t < x.to);
  let back: React.ReactNode = null;
  if (b) {
    const out = r(t, b.to - 0.25, b.to, EASE_IN);
    back = (
      <div style={{ position: "absolute", left: b.x, top: 250, transform: `translateX(-50%) translateY(${-out * 30}px)`, display: "flex", gap: b.size * 0.18,
        whiteSpace: "nowrap", opacity: 1 - out }}>
        {b.ids.map((i) => {
          const k = r(t, W[i].s - 0.04, W[i].s + 0.3, EASE);
          return <span key={i} style={{ display: "inline-block", fontFamily: DISPLAY, fontSize: b.size, lineHeight: 1, color: NAVY, textTransform: "uppercase",
            letterSpacing: 2, opacity: clamp(k * 2), transform: `translateY(${(1 - k) * 160}px)` }}>{W[i].w}</span>;
        })}
      </div>
    );
  }
  let front: React.ReactNode = null;
  if (f) {
    const out = r(t, f.to - 0.16, f.to, EASE_IN);
    const k0 = r(t, f.from, f.from + 0.14);
    front = (
      <div style={{ position: "absolute", left: 90, right: 170, top: f.pay ? 1150 : 1250, display: "flex", flexWrap: "wrap", justifyContent: "center",
        alignItems: "baseline", columnGap: f.pay ? 26 : 16, rowGap: 0, opacity: k0 * (1 - out), transform: `translateY(${(1 - k0) * 14}px)` }}>
        {f.ids.map((i) => {
          const w = W[i];
          const said = t >= w.s - 0.02;
          const p = r(t, w.s - 0.02, w.s + 0.12);
          if (f.pay) {
            return <span key={i} style={{ display: "inline-block", fontFamily: DISPLAY, fontSize: f.size, lineHeight: 1.0, color: YELLOW, textTransform: "uppercase",
              opacity: said ? 1 : 0, transform: `scale(${1 + (1 - p) * 0.35})`, textShadow: SHADOW }}>{w.w}</span>;
          }
          return <span key={i} style={{ display: "inline-block", fontFamily: UI, fontWeight: 800, fontSize: 72, lineHeight: 1.1, color: "#fff",
            opacity: said ? 1 : 0.4, transform: `scale(${said ? 1 + (1 - p) * 0.1 : 1})`, textShadow: SHADOW }}>{w.w}</span>;
        })}
      </div>
    );
  }
  return (
    <AbsoluteFill>
      <Clip />
      {back}
      <Person />
      {front}
      <Sounds list={[...BEHIND.map((x) => [W[x.ids[0]].s, "impact", 0.3] as [number, "impact", number]),
        ...FRONT.filter((x) => x.pay).map((x) => [W[x.ids[0]].s, "pop", 0.22] as [number, "pop", number])]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-08 Magazine editorial: a cover headline building on his chest. Bodoni (roman / italic / black) + letter-spaced
// Inter small caps, hairline rules that draw across, words revealed through a mask on the spoken word, one red accent.
// =====================================================================================================================
const RED = "#FF4D2E";
type MItem = { ids?: number[]; f?: "caps" | "ital" | "bold" | "black"; size?: number; accent?: boolean; rule?: boolean };
type MRow = { items: MItem[]; justify?: "flex-start" | "center" | "flex-end"; mt?: number };
type MBlock = { from: number; to: number; top: number; rows: MRow[] };
const MAG: MBlock[] = [
  { from: 0.03, to: 2.97, top: 1115, rows: [
    { items: [{ ids: [0, 1], f: "caps" }, { rule: true }] },
    { items: [{ ids: [2, 3, 4], f: "ital", size: 84 }], justify: "flex-start", mt: 6 },
    { items: [{ ids: [5, 6], f: "caps" }, { ids: [7, 8], f: "black", size: 124, accent: true }], justify: "flex-end", mt: -4 }] },
  { from: 2.97, to: 5.73, top: 1150, rows: [
    { items: [{ ids: [9], f: "caps" }, { ids: [10], f: "black", size: 150 }, { ids: [11, 12, 13], f: "ital", size: 64 }], justify: "center" },
    { items: [{ rule: true }, { ids: [14], f: "caps" }, { ids: [15], f: "black", size: 104, accent: true }], mt: -8 }] },
  { from: 5.73, to: 7.2, top: 1110, rows: [
    { items: [{ rule: true }, { ids: [16], f: "caps" }, { rule: true }] },
    { items: [{ ids: [17], f: "ital", size: 140, accent: true }], justify: "center", mt: -4 },
    { items: [{ ids: [18, 19, 20, 21], f: "caps" }], justify: "center", mt: 0 }] },
  { from: 7.2, to: 9.46, top: 1120, rows: [
    { items: [{ ids: [22, 23], f: "ital", size: 76 }, { rule: true }] },
    { items: [{ ids: [24], f: "black", size: 156, accent: true }, { ids: [25], f: "bold", size: 92 }, { ids: [26], f: "ital", size: 72 }], justify: "flex-start", mt: -10 }] },
  { from: 9.46, to: 12.2, top: 1120, rows: [
    { items: [{ ids: [27, 28, 29, 30], f: "caps" }, { rule: true }] },
    { items: [{ ids: [31], f: "black", size: 170, accent: true }, { ids: [32, 33, 34], f: "ital", size: 80 }], justify: "flex-start", mt: -6 }] },
];
const magFont = (it: MItem): React.CSSProperties => {
  const color = it.accent ? RED : "#fff";
  if (it.f === "caps") return { fontFamily: UI, fontWeight: 600, fontSize: 40, letterSpacing: 7, textTransform: "uppercase", color, lineHeight: 1.2 };
  if (it.f === "ital") return { fontFamily: BODONI, fontStyle: "italic", fontWeight: 400, fontSize: it.size, color, lineHeight: 1.0, letterSpacing: -1 };
  if (it.f === "bold") return { fontFamily: BODONI, fontWeight: 700, fontSize: it.size, color, lineHeight: 0.95, letterSpacing: -1 };
  return { fontFamily: BODONI, fontWeight: 900, fontSize: it.size, color, lineHeight: 0.92, letterSpacing: -3 };
};
const C108: React.FC = () => {
  const t = useT();
  const b = MAG.find((x) => t >= x.from && t < x.to);
  let cap: React.ReactNode = null;
  if (b) {
    const out = r(t, b.to - 0.22, b.to, EASE_IN);
    cap = (
      <div style={{ position: "absolute", left: 100, width: 760, top: b.top, opacity: 1 - out, transform: `translateY(${-out * 18}px)`,
        filter: `drop-shadow(0 2px 3px rgba(0,0,0,0.4)) drop-shadow(0 6px 18px rgba(0,0,0,0.35))` }}>
        {b.rows.map((row, ri) => {
          const rowStart = Math.min(...row.items.filter((x) => x.ids).map((x) => W[x.ids![0]].s));
          return (
            <div key={ri} style={{ display: "flex", alignItems: "center", justifyContent: row.justify ?? "flex-start", gap: 22, marginTop: row.mt ?? 0 }}>
              {row.items.map((it, ii) => {
                if (it.rule) {
                  const k = r(t, rowStart - 0.05, rowStart + 0.4, EASE);
                  return <div key={ii} style={{ flex: 1, minWidth: 60, height: 2, background: "rgba(255,255,255,0.9)", transform: `scaleX(${k})`,
                    transformOrigin: ii === 0 ? "right" : "left" }} />;
                }
                return (
                  <div key={ii} style={{ display: "flex", gap: it.f === "caps" ? 18 : (it.size ?? 80) * 0.22, alignItems: "baseline", whiteSpace: "nowrap" }}>
                    {it.ids!.map((i) => {
                      const k = r(t, W[i].s - 0.03, W[i].s + 0.2, EASE);
                      return (
                        <span key={i} style={{ display: "inline-block", overflow: "hidden", padding: "0 8px", margin: "0 -8px", verticalAlign: "bottom" }}>
                          <span style={{ ...magFont(it), display: "inline-block", transform: `translateY(${(1 - k) * 105}%)` }}>{W[i].w}</span>
                        </span>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
    );
  }
  return (
    <AbsoluteFill>
      <Clip />
      {cap}
      <Sounds list={MAG.map((x) => [x.from + 0.04, "tick", 0.18] as [number, "tick", number])} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-09 Die-cut stickers: every phrase is a die-cut text sticker (thick white cut line, crisp offset shadow) that
// slaps on at an angle; up to 3 pile up per sentence, key words in colour; the sticker grows word by word as he speaks (no SFX).
// =====================================================================================================================
const STICK_COL: Record<number, string> = { 7: "#0A84FF", 8: "#0A84FF", 10: "#FF2D55", 15: "#34C759", 17: "#FF7A00", 24: "#0A84FF", 25: "#0A84FF", 31: "#FF2D55", 34: "#AF52DE" };
type Sticker = { ids: number[]; pile: number };
const STICKERS: Sticker[] = [
  { ids: [0, 1], pile: 0 }, { ids: [2, 3, 4], pile: 0 }, { ids: [5, 6, 7, 8], pile: 0 },
  { ids: [9, 10], pile: 1 }, { ids: [11, 12, 13], pile: 1 }, { ids: [14, 15], pile: 1 },
  { ids: [16, 17], pile: 2 }, { ids: [18, 19, 20, 21], pile: 2 }, { ids: [22, 23], pile: 2 }, { ids: [24, 25, 26], pile: 2 },
  { ids: [27, 28], pile: 3 }, { ids: [29, 30, 31], pile: 3 }, { ids: [32, 33, 34], pile: 3 },
];
const PILE_END = [2.96, 5.72, 9.46, 12.2];
const SLOTS = [{ x: 450, y: 1150, rot: -5 }, { x: 520, y: 1250, rot: 3.5 }, { x: 460, y: 1350, rot: -2.5 }];
const C109: React.FC = () => {
  const t = useT();
  const started = STICKERS.map((s, i) => ({ s, i, at: W[s.ids[0]].s - 0.04 })).filter((x) => t >= x.at);
  const pile = started.length ? started[started.length - 1].s.pile : -1;
  const inPile = started.filter((x) => x.s.pile === pile);
  const visible = inPile.slice(-3);
  const pileOut = pile >= 0 ? r(t, PILE_END[pile] - 0.22, PILE_END[pile], EASE_IN) : 0;
  return (
    <AbsoluteFill>
      <Clip />
      {pile >= 0 && visible.map((x, vi) => {
        const shift = inPile.length > 3 ? 1 - r(t, visible[visible.length - 1].at, visible[visible.length - 1].at + 0.25, EASE) : 0;
        const s0 = SLOTS[vi], s1 = SLOTS[Math.min(2, vi + 1)];
        const slot = vi < 2 && shift > 0 ? { x: lerp(s0.x, s1.x, shift), y: lerp(s0.y, s1.y, shift), rot: lerp(s0.rot, s1.rot, shift) } : s0;
        const k = r(t, x.at, x.at + 0.14, EASE_IN);
        const settle = r(t, x.at + 0.14, x.at + 0.3, EASE);
        const scale = lerp(1.7, 1, k) * (1 - 0.03 * Math.sin(settle * Math.PI));
        const rot = slot.rot + (1 - k) * 9 * (vi % 2 ? -1 : 1);
        const older = visible.length - 1 - vi;
        // only words already said (Max: no see-through "preview" letters); the sticker grows word by word, fully opaque
        const text = x.s.ids.filter((i) => t >= W[i].s - 0.03).map((i) => ({ w: W[i].w, col: STICK_COL[i] ?? "#1C1C1E", i }));
        const font: React.CSSProperties = { fontFamily: UI, fontWeight: 900, fontSize: 70, letterSpacing: -1.5, lineHeight: 1, whiteSpace: "nowrap" };
        return (
          <div key={x.i} style={{ position: "absolute", left: slot.x, top: slot.y, transform: `translate(-50%, -50%) translateY(${pileOut * 60}px) rotate(${rot}deg) scale(${scale * (1 - older * 0.03)})`,
            opacity: clamp(k * 3) * (1 - pileOut), filter: `drop-shadow(0 ${lerp(26, 6, k)}px 0 rgba(0,0,0,${lerp(0.08, 0.22, k)}))` }}>
            <div style={{ position: "relative" }}>
              <div style={{ ...font, position: "absolute", left: 0, top: 0, WebkitTextStroke: "30px #FFFFFF", color: "#fff" }}>
                {text.map((w, j) => <span key={j}>{j ? " " : ""}{w.w}</span>)}
              </div>
              <div style={{ ...font, position: "relative" }}>
                {text.map((w, j) => <span key={j} style={{ color: w.col }}>{j ? " " : ""}{w.w}</span>)}
              </div>
            </div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// c1-10 Marker scribble: hand-lettered marker words written on left-to-right as he says them, a slight hand jitter,
// and red marker circles / underlines drawn around the key words.
// =====================================================================================================================
type Mark = "circle" | "under" | "double";
const MARKS: Record<number, Mark> = { 8: "under", 10: "circle", 15: "double", 17: "under", 24: "circle", 25: "under", 31: "circle", 34: "double" };
const MSEG: { from: number; to: number; ids: number[] }[] = [
  { from: 0.03, to: 1.41, ids: ids(0, 4) }, { from: 1.41, to: 2.97, ids: ids(5, 8) }, { from: 2.97, to: 4.17, ids: [9, 10] },
  { from: 4.17, to: 5.73, ids: ids(11, 15) }, { from: 5.73, to: 7.2, ids: ids(16, 21) }, { from: 7.2, to: 9.46, ids: ids(22, 26) },
  { from: 9.46, to: 10.92, ids: ids(27, 31) }, { from: 10.92, to: 12.2, ids: ids(32, 34) },
];
const MARK_RED = "#FF3B30";
/** scale a path written in a 100 x 100 box to px (so the stroke stays even and the dash draw-on works) */
const scalePath = (d: string, w: number, h: number) => {
  let i = 0;
  return d.replace(/-?\d+(\.\d+)?/g, (n) => String(((i++ % 2 === 0) ? (+n / 100) * w : (+n / 100) * h).toFixed(1)));
};
const MarkSvg: React.FC<{ m: Mark; k: number; text: string; size: number }> = ({ m, k, text, size }) => {
  const tw = measureText({ text, fontFamily: MARKER, fontSize: size }).width;
  const th = size * 1.12;
  const common = { fill: "none", stroke: MARK_RED, strokeWidth: 8, strokeLinecap: "round" as const, pathLength: 1, strokeDasharray: 1 };
  if (m === "circle") {
    const w = tw * 1.34, h = th * 1.2;
    return (
      <svg width={w} height={h} style={{ position: "absolute", left: (tw - w) / 2, top: (th - h) / 2, overflow: "visible" }}>
        <path d={scalePath("M 62 6 C 30 2, 2 20, 3 52 C 4 84, 40 99, 70 94 C 97 88, 101 50, 91 27 C 83 11, 55 1, 30 11", w, h)} {...common} strokeDashoffset={1 - k} />
      </svg>
    );
  }
  const w = tw * 1.06, h = 34;
  return (
    <svg width={w} height={h} style={{ position: "absolute", left: (tw - w) / 2, top: th * 0.86, overflow: "visible" }}>
      <path d={scalePath("M 2 30 C 25 15, 55 40, 98 20", w, h)} {...common} strokeDashoffset={1 - clamp(k * (m === "double" ? 1.8 : 1))} />
      {m === "double" && <path d={scalePath("M 10 85 C 35 66, 70 88, 94 70", w, h)} {...common} strokeDashoffset={1 - clamp(k * 1.8 - 0.8)} />}
    </svg>
  );
};
const C110: React.FC = () => {
  const t = useT();
  const sg = MSEG.find((x) => t >= x.from && t < x.to);
  let cap: React.ReactNode = null;
  if (sg) {
    const out = r(t, sg.to - 0.18, sg.to, EASE_IN);
    cap = (
      <div style={{ position: "absolute", left: 80, right: 160, top: 1150, display: "flex", flexWrap: "wrap", justifyContent: "center", alignItems: "baseline",
        columnGap: 26, rowGap: 6, opacity: 1 - out, transform: `rotate(-2deg) scale(${1 - out * 0.05})` }}>
        {sg.ids.map((i) => {
          const w = W[i];
          const dur = clamp(w.e - w.s, 0.12, 0.3);
          const k = r(t, w.s - 0.02, w.s - 0.02 + dur, EASE_IO);
          const mk = MARKS[i];
          const mkK = r(t, w.s + dur * 0.6, w.s + dur * 0.6 + 0.35, EASE_IO);
          const key = !!mk;
          return (
            <span key={i} style={{ position: "relative", display: "inline-block", transform: `rotate(${(rand(i) - 0.5) * 5}deg) translateY(${(rand(i + 9) - 0.5) * 10}px)` }}>
              {mk && <MarkSvg m={mk} k={mkK} text={w.w} size={key ? 104 : 86} />}
              <span style={{ position: "relative", display: "inline-block", fontFamily: MARKER, fontSize: key ? 104 : 86, lineHeight: 1.12, color: key ? YELLOW : "#fff",
                clipPath: `inset(-20% ${(1 - k) * 100}% -20% -5%)`, textShadow: "0 3px 0 rgba(0,0,0,0.35), 0 6px 18px rgba(0,0,0,0.45)" }}>{w.w}</span>
            </span>
          );
        })}
      </div>
    );
  }
  return (
    <AbsoluteFill>
      <Clip />
      {cap}
      <Sounds list={Object.keys(MARKS).map((k) => [W[+k].s + 0.15, "swish", 0.12] as [number, "swish", number])} />
    </AbsoluteFill>
  );
};

export const C1: CapItem[] = [
  { id: "c1-03", title: "Kelssie twist: depth pull", note: "Kelssie lockups (Inter light/heavy + gold serif) build on his chest; when the next arrives the old one sinks behind him and rises above his head as an echo; slow push-in per lockup.", C: C103 },
  { id: "c1-07", title: "Behind the head", note: "The setup word stands huge in navy Anton on the wall behind his head; running words and the yellow Anton payoff sit in front on his chest.", C: C107 },
  { id: "c1-08", title: "Magazine editorial", note: "A cover headline building on his chest: Bodoni roman/italic/black + spaced small caps, hairline rules drawing across, mask reveals, one red accent.", C: C108 },
  { id: "c1-09", title: "Die-cut stickers", note: "Each phrase is a die-cut text sticker slapping on at an angle (thick white cut line, crisp offset shadow); up to 3 pile up, key words in iOS colours. Max 7/10 → fixed: no per-caption SFX, no see-through preview letters.", C: C109 },
];
