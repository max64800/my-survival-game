import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";
import { loadFont as loadScript } from "@remotion/google-fonts/GreatVibes";
import { loadFont as loadBook } from "@remotion/google-fonts/EBGaramond";
import {
  LibItem, useT, r, lerp, clamp, env, typed, float, rand, mix, C, EASE, EASE_IN, EASE_IO, POP, LIQUID,
  Backdrop, BackPerson, Sounds, Label, Odo, GooDefs, DemoCaption, UI, SERIF, MONO, DISPLAY,
} from "./common";

// Family m4 — Kinetic typography & transitions. Typography is the hero visual; every demo also shows one craft
// transition (behind-the-head word, light-leak wipe, whip, collapse-to-line, particles re-forming, colour-block wipes …).
const { fontFamily: SCRIPT } = loadScript("normal", { subsets: ["latin"] });
const { fontFamily: BOOK } = loadBook("normal", { weights: ["500", "600"], subsets: ["latin"] });
const FAM = "Kinetic typography & transitions";
const INK = "#141416";
const SHADOW = "0 3px 10px rgba(0,0,0,0.55), 0 0 2px rgba(0,0,0,0.35)";

// directional (1-axis) motion blur as an SVG filter: <DirBlur id=".." x={..} y={..}/> then style={{ filter: `url(#id)` }}
const DirBlur: React.FC<{ id: string; x?: number; y?: number }> = ({ id, x = 0, y = 0 }) => (
  <svg width="0" height="0" style={{ position: "absolute" }}>
    <defs>
      <filter id={id} x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation={`${Math.max(0, x)} ${Math.max(0, y)}`} />
      </filter>
    </defs>
  </svg>
);
const blurIf = (id: string, amt: number) => (amt > 0.3 ? `url(#${id})` : "none");

// =====================================================================================================
// m4-01  Hero word behind his head: OFF-PLAN slams down letter by letter (vertical motion blur), then the
// letters roll out and the next word drops in. Lead-in line in front (mono), payoff word behind (Anton).
// =====================================================================================================
const HERO_WORDS = [
  { w: "OFF-PLAN", lead: "everyone keeps asking about", at: 0.25, color: INK, size: 250 },
  { w: "60 / 40", lead: "the payment plan is usually", at: 4.2, color: C.eqt, size: 270 },
  { w: "WORTH IT?", lead: "so the real question:", at: 8.2, color: C.red, size: 230 },
];
const M401: React.FC = () => {
  const t = useT();
  return (
    <AbsoluteFill>
      <Backdrop />
      {HERO_WORDS.map((h, wi) => {
        const next = HERO_WORDS[wi + 1]?.at ?? 99;
        const outAt = next - 0.45;
        if (t < h.at - 0.1 || t > outAt + 0.8) return null;
        const chars = Array.from(h.w);
        // whole-word slow push-in while it holds
        const hold = r(t, h.at + 0.6, outAt, EASE_IO);
        return (
          <div key={wi} style={{ position: "absolute", left: 0, right: 0, top: 296, display: "flex", justifyContent: "center",
            transform: `scale(${1 + hold * 0.04})` }}>
            {chars.map((ch, i) => {
              const a = h.at + i * 0.07;
              const k = r(t, a, a + 0.32, EASE);
              const o = r(t, outAt + i * 0.04, outAt + 0.3 + i * 0.04, EASE_IN);
              const vel = Math.max(1 - k, o);
              const id = `m4-01-b${wi}-${i}`;
              return (
                <span key={i} style={{ position: "relative", display: "inline-block", whiteSpace: "pre" }}>
                  <DirBlur id={id} y={vel * 26} />
                  <span style={{ display: "inline-block", fontFamily: DISPLAY, fontSize: h.size, lineHeight: 1, color: h.color, letterSpacing: 2,
                    transform: `translateY(${(1 - k) * -260 + o * -320}px) scaleY(${1 + vel * 0.25})`, opacity: Math.min(1, k * 3) * (1 - o),
                    filter: blurIf(id, vel * 26) }}>{ch}</span>
                </span>
              );
            })}
          </div>
        );
      })}
      <BackPerson />
      {/* lead-in line in front of everything, small mono, sits above the hero word */}
      {HERO_WORDS.map((h, wi) => {
        const next = HERO_WORDS[wi + 1]?.at ?? 99;
        const k = env(t, h.at - 0.15, Math.min(next - 0.3, 11.8), 0.3, 0.25);
        if (k <= 0) return null;
        const txt = typed(h.lead, t, h.at - 0.15, 0.03);
        return (
          <div key={wi} style={{ position: "absolute", left: 0, right: 0, top: 262, display: "flex", justifyContent: "center", opacity: k }}>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 32, letterSpacing: 1, color: "#fff", background: "rgba(20,20,22,0.88)",
              padding: "8px 18px", borderRadius: 12, whiteSpace: "nowrap" }}>{txt}</div>
          </div>
        );
      })}
      <DemoCaption text="Is off-plan actually worth it?" from={9.2} to={11.8} />
      <Sounds list={[[0.2, "type", 0.18], [0.3, "impact", 0.38], [0.8, "tick", 0.2], [3.75, "whoosh", 0.3], [4.2, "impact", 0.4], [7.75, "whoosh", 0.3],
        [8.2, "impact", 0.42], [4.15, "type", 0.15], [8.15, "type", 0.15]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-02  Light-leak wipe between colour scenes: RENT (cream) → BUY (navy) → RENT OR BUY? (burnt orange).
// A warm crisp-edged light band sweeps diagonally and carries the next scene in behind it.
// =====================================================================================================
const LeakBand: React.FC<{ k: number }> = ({ k }) => {
  if (k <= 0 || k >= 1) return null;
  const x = lerp(-1700, 1700, k);
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <div style={{ position: "absolute", left: 540 + x - 900, top: -600, width: 1800, height: 3100, transform: "rotate(18deg)",
        background: "linear-gradient(90deg, rgba(255,159,10,0) 0%, rgba(255,159,10,0.55) 22%, rgba(255,214,10,0.85) 38%, rgba(255,250,235,1) 50%, rgba(255,214,10,0.85) 62%, rgba(255,120,40,0.5) 80%, rgba(255,120,40,0) 100%)" }} />
    </AbsoluteFill>
  );
};
const M402: React.FC = () => {
  const t = useT();
  const L1 = 3.9, L2 = 8.0;
  const k1 = r(t, L1 - 0.45, L1 + 0.45, EASE_IO), k2 = r(t, L2 - 0.45, L2 + 0.45, EASE_IO);
  const scene = t < L1 ? 0 : t < L2 ? 1 : 2;
  const bg = ["#F4F1EA", "#0E1A33", "#C2501E"][scene];
  const fg = ["#1C1C1E", "#FFFFFF", "#FFF4E6"][scene];
  const s0 = 0.15, s1 = L1 + 0.1, s2 = L2 + 0.1;
  const st = [s0, s1, s2][scene];
  const k = r(t, st, st + 0.6);
  const drift = (t - st) * 6;
  return (
    <AbsoluteFill style={{ background: bg }}>
      {scene < 2 && (
        <div style={{ position: "absolute", left: 90, top: 520, right: 90, color: fg }}>
          <Label color={scene === 0 ? "rgba(28,28,30,0.55)" : "rgba(255,255,255,0.6)"} size={32}>{scene === 0 ? "OPTION A" : "OPTION B"}</Label>
          <div style={{ fontFamily: SERIF, fontSize: 380, lineHeight: 0.95, letterSpacing: -8, marginTop: 10, opacity: k,
            transform: `translateX(${(1 - k) * -80 + drift}px)`, filter: `blur(${(1 - k) * 14}px)` }}>{scene === 0 ? "Rent" : "Buy"}</div>
          <div style={{ marginTop: 40, display: "flex", alignItems: "baseline", gap: 18, opacity: r(t, st + 0.4, st + 0.8) }}>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 56 }}>AED</span>
            {scene === 0
              ? <><Odo value={lerp(0, 120, r(t, st + 0.5, st + 2.2, EASE_IO))} size={150} color={fg} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 120 }}>K</span></>
              : <><Odo value={lerp(0, 2, r(t, st + 0.5, st + 2.0, EASE_IO))} size={150} color={fg} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 120 }}>M</span></>}
          </div>
          <div style={{ fontFamily: SERIF, fontSize: 64, marginTop: 10, opacity: r(t, st + 1.4, st + 1.9) }}>
            {scene === 0 ? "every year, gone." : "once, and it's yours."}
          </div>
          <div style={{ marginTop: 40, display: "flex", gap: 14, opacity: r(t, st + 2.0, st + 2.4) }}>
            {(scene === 0 ? ["flexible", "no deposit", "no equity"] : ["deposit", "mortgage", "equity"]).map((c, i) => {
              const a = r(t, st + 2.0 + i * 0.15, st + 2.35 + i * 0.15, POP);
              return <div key={i} style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, padding: "10px 22px", borderRadius: 30,
                border: `2.5px solid ${scene === 0 ? "rgba(28,28,30,0.25)" : "rgba(255,255,255,0.3)"}`, transform: `scale(${a})` }}>{c}</div>;
            })}
          </div>
        </div>
      )}
      {scene === 2 && (
        <div style={{ position: "absolute", left: 90, right: 90, top: 470, color: fg }}>
          {["RENT", "OR", "BUY?"].map((w, i) => {
            const a = r(t, s2 + i * 0.22, s2 + i * 0.22 + 0.45, POP);
            return <div key={i} style={{ fontFamily: i === 1 ? SERIF : DISPLAY, fontSize: i === 1 ? 200 : 300, lineHeight: i === 1 ? 0.8 : 0.95,
              marginLeft: i === 1 ? 260 : i === 2 ? 120 : 0, transform: `translateY(${(1 - a) * 60}px) translateX(${Math.sin(t * 0.9 + i) * 6}px)`,
              opacity: Math.min(1, a * 2), color: i === 2 ? "#FFD60A" : fg }}>{w}</div>;
          })}
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 34, letterSpacing: 2, marginTop: 50, opacity: r(t, s2 + 1.2, s2 + 1.6) }}>
            {typed("THE MATHS IN 60 SECONDS", t, s2 + 1.2, 0.04)}
          </div>
        </div>
      )}
      <LeakBand k={k1} />
      <LeakBand k={k2} />
      <Sounds list={[[0.15, "swish", 0.25], [0.7, "tick", 0.15], [2.2, "pop", 0.2], [L1 - 0.5, "riser", 0.25], [L1, "whoosh", 0.4], [L1 + 0.7, "tick", 0.15],
        [L1 + 2.1, "pop", 0.2], [L2 - 0.5, "riser", 0.25], [L2, "whoosh", 0.4], [s2 + 0.05, "impact", 0.35], [s2 + 0.27, "pop", 0.25], [s2 + 0.5, "impact", 0.38], [s2 + 1.2, "type", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-03  Motion-blurred word whips inside ONE fitted pill above his head (liquid resize per word).
// =====================================================================================================
const WHIPS = [
  { w: "LOCATION", c: C.eqt, at: 0.3, wd: 560 },
  { w: "PRICE", c: C.green, at: 2.4, wd: 400 },
  { w: "TIMING", c: C.orange, at: 4.5, wd: 460 },
  { w: "EXIT PLAN", c: C.pink, at: 6.6, wd: 620 },
];
const M403: React.FC = () => {
  const t = useT();
  const cur = WHIPS.reduce((a, w, i) => (t >= w.at - 0.15 ? i : a), 0);
  const prev = WHIPS[cur - 1];
  const pw = prev ? lerp(prev.wd, WHIPS[cur].wd, r(t, WHIPS[cur].at - 0.15, WHIPS[cur].at + 0.4, LIQUID)) : WHIPS[0].wd * r(t, 0, 0.45, LIQUID);
  const list = r(t, 8.9, 9.5, EASE);      // final beat: the pill grows into a 4-line list
  const h = lerp(190, 470, list);
  const W = lerp(pw + 40, 760, list);
  return (
    <AbsoluteFill>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - W / 2, top: 270, width: W, height: h, borderRadius: 40, background: "rgba(22,22,24,0.92)",
        border: "1.5px solid rgba(255,255,255,0.14)", overflow: "hidden", transform: float(t, 1, 3) }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 22, display: "flex", justifyContent: "center", gap: 12 }}>
          <Label size={28}>WHAT ACTUALLY MATTERS</Label>
          <Label size={28} color={WHIPS[cur].c}>{list > 0.5 ? "4/4" : `${cur + 1}/4`}</Label>
        </div>
        {list < 1 && WHIPS.map((w, i) => {
          const inK = r(t, w.at, w.at + 0.32, EASE);
          const nxt = WHIPS[i + 1]?.at ?? 8.9;
          const outK = r(t, nxt - 0.15, nxt + 0.12, EASE_IN);
          if (t < w.at - 0.05 || outK >= 1) return null;
          const v = Math.max(1 - inK, outK);
          const id = `m4-03-w${i}`;
          return (
            <div key={i} style={{ position: "absolute", left: 0, right: 0, top: 66, display: "flex", justifyContent: "center", opacity: 1 - list }}>
              <DirBlur id={id} x={v * 40} />
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 104, color: w.c, letterSpacing: -2, whiteSpace: "nowrap",
                transform: `translateX(${(1 - inK) * 700 - outK * 700}px) skewX(${-v * 14}deg)`, filter: blurIf(id, v * 40) }}>{w.w}</div>
            </div>
          );
        })}
        {list > 0 && WHIPS.map((w, i) => {
          const a = r(t, 9.2 + i * 0.12, 9.5 + i * 0.12, EASE);
          const tick = r(t, 9.9 + i * 0.35, 10.15 + i * 0.35, POP);
          const id = `m4-03-l${i}`;
          return (
            <div key={i} style={{ position: "absolute", left: 50, top: 82 + i * 92, display: "flex", alignItems: "center", gap: 22 }}>
              <DirBlur id={id} x={(1 - a) * 30} />
              <div style={{ width: 54, height: 54, borderRadius: 27, background: tick > 0 ? w.c : "rgba(255,255,255,0.12)", color: "#fff", fontFamily: UI, fontWeight: 900,
                fontSize: 32, display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${0.8 + 0.2 * Math.max(a, tick)})` }}>{tick > 0.3 ? "✓" : i + 1}</div>
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 64, color: "#fff", transform: `translateX(${(1 - a) * 300}px)`, opacity: a,
                filter: blurIf(id, (1 - a) * 30), whiteSpace: "nowrap" }}>{w.w}</div>
            </div>
          );
        })}
      </div>
      <DemoCaption text="Four things decide your return" from={0.4} to={4.3} />
      <DemoCaption text="and most buyers only check one." from={4.5} to={8.7} />
      <DemoCaption text="Check all four." from={9.6} to={12.8} />
      <Sounds list={[[0.2, "whoosh", 0.32], [2.25, "whoosh", 0.32], [4.35, "whoosh", 0.32], [6.45, "whoosh", 0.32], [8.85, "swish", 0.3],
        ...[0, 1, 2, 3].map((i) => [9.9 + i * 0.35, "ding", 0.18] as [number, "ding", number])]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-04  Collapse-to-line → expand: each colour-block scene squashes into a thin line that opens into the next.
// =====================================================================================================
const LINES = [
  { bg: INK, fg: "#fff", acc: "#D4FF3A", at: 0, n: "", title: ["3 THINGS", "NOBODY", "TELLS YOU"], sub: "before you buy in Dubai" },
  { bg: "#D4FF3A", fg: INK, acc: INK, at: 2.9, n: "01", title: ["SERVICE", "CHARGES"], sub: "you pay them every single year" },
  { bg: C.blue, fg: "#fff", acc: "#D4FF3A", at: 5.9, n: "02", title: ["TRANSFER", "FEES"], sub: "budget them on top of the price" },
  { bg: C.red, fg: "#fff", acc: "#FFD60A", at: 8.9, n: "03", title: ["EXIT", "TIMING"], sub: "plan the sale before you buy" },
];
const M404: React.FC = () => {
  const t = useT();
  const idx = LINES.reduce((a, s, i) => (t >= s.at ? i : a), 0);
  const s = LINES[idx];
  const nx = LINES[idx + 1];
  const collapse = nx ? r(t, nx.at - 0.45, nx.at - 0.05, EASE_IN) : r(t, 12.0, 12.4, EASE_IN);
  // the incoming line grows from the collapsed text, then opens vertically into the next scene
  const open = r(t, s.at, s.at + 0.55, EASE);
  const prevBg = idx > 0 ? LINES[idx - 1].bg : s.bg;
  const H = idx === 0 ? 1920 : lerp(8, 1920, open);
  const contentK = idx === 0 ? r(t, 0.1, 0.6) : r(t, s.at + 0.3, s.at + 0.8);
  const lineW = idx === 0 ? 900 : lerp(900, 1080, open);
  return (
    <AbsoluteFill style={{ background: prevBg }}>
      <div style={{ position: "absolute", left: 540 - lineW / 2, top: 960 - H / 2, width: lineW, height: H, background: s.bg, borderRadius: H < 40 ? 4 : 0 }} />
      <div style={{ position: "absolute", left: 90, right: 90, top: 560, color: s.fg, transformOrigin: "50% 400px",
        transform: `scaleY(${(0.3 + 0.7 * contentK) * (1 - collapse * 0.995)})`, opacity: Math.min(contentK * 2, 1) * (1 - r(t, (nx?.at ?? 12.4) - 0.15, (nx?.at ?? 12.4) - 0.05)) }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 20, height: 60 }}>
          {s.n && <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 44, color: s.acc }}>{s.n}</div>}
          <div style={{ height: 6, width: lerp(0, 200, contentK), background: s.acc, borderRadius: 3, alignSelf: "center" }} />
        </div>
        {s.title.map((l, i) => {
          const a = idx === 0 ? r(t, 0.1 + i * 0.18, 0.5 + i * 0.18, EASE) : r(t, s.at + 0.35 + i * 0.12, s.at + 0.75 + i * 0.12, EASE);
          return <div key={i} style={{ fontFamily: DISPLAY, fontSize: 230, lineHeight: 0.98, transform: `translateY(${(1 - a) * 80}px)`, opacity: a,
            color: idx === 0 && i === 1 ? s.acc : s.fg }}>{l}</div>;
        })}
        <div style={{ fontFamily: SERIF, fontSize: 70, marginTop: 30, opacity: idx === 0 ? r(t, 0.9, 1.3) : r(t, s.at + 0.9, s.at + 1.3),
          transform: `translateX(${Math.sin(t) * 6}px)` }}>{s.sub}</div>
      </div>
      {/* collapsing: the line the text squashes into (accent colour of the NEXT scene) */}
      {collapse > 0 && (
        <div style={{ position: "absolute", left: 540 - 450 * (nx ? 1 : 1 - r(t, 12.3, 12.5)), top: 956, width: 900 * (nx ? 1 : 1 - r(t, 12.3, 12.5)), height: 8,
          borderRadius: 4, background: nx ? nx.bg : s.acc, opacity: collapse }} />
      )}
      <Sounds list={[[0.1, "impact", 0.35], [0.9, "tick", 0.15], ...LINES.slice(1).flatMap((l) => [[l.at - 0.45, "swish", 0.3], [l.at, "whoosh", 0.35], [l.at + 0.4, "pop", 0.22]] as [number, "swish" | "whoosh" | "pop", number][]),
        [12.0, "swish", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-05  Particles re-forming into words: drifting dust → RENT → burst → OWN → burst → WHEN? (5x7 dot font)
// =====================================================================================================
const GLYPH: Record<string, string[]> = {
  R: ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
  E: ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
  N: ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
  T: ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
  O: ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
  W: ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
  H: ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
  "?": ["01110", "10001", "00001", "00110", "00100", "00000", "00100"],
};
const dotsFor = (word: string, cell: number, cy: number) => {
  const chars = Array.from(word);
  const wCols = chars.length * 6 - 1;
  const x0 = 540 - (wCols * cell) / 2 + cell / 2;
  const pts: [number, number][] = [];
  chars.forEach((ch, ci) => GLYPH[ch].forEach((row, ry) => Array.from(row).forEach((b, rx) => {
    if (b === "1") pts.push([x0 + (ci * 6 + rx) * cell, cy - 3.5 * cell + ry * cell + cell / 2]);
  })));
  return pts;
};
const PWORDS = [
  { w: "RENT", at: 1.2, cell: 40, col: "#FFFFFF", sub: "renting forever?" },
  { w: "OWN", at: 5.0, cell: 46, col: C.gold, sub: "or owning your place?" },
  { w: "WHEN?", at: 8.8, cell: 32, col: C.teal, sub: "the real question is timing" },
];

// =====================================================================================================
// m4-06  Colour-block scene wipes under ONE staying object: each beat is a bold colour field (title top-left +
// italic serif subtitle); a diagonal field wipes in underneath the white shape, which morphs per beat.
// =====================================================================================================
const BLOCKS = [
  { bg: C.blue, fg: "#fff", title: "LOCATION", sub: "where you buy matters most", icon: "📍", rad: 50, rot: 0, at: 0 },
  { bg: C.red, fg: "#fff", title: "TIMING", sub: "when you buy matters too", icon: "⏱️", rad: 22, rot: 0, at: 2.8 },
  { bg: "#D4FF3A", fg: INK, title: "EXIT", sub: "who buys it from you later", icon: "🔑", rad: 8, rot: 45, at: 5.6 },
  { bg: INK, fg: "#fff", title: "ALL THREE", sub: "or don't buy at all", icon: "✓", rad: 50, rot: 90, at: 8.4 },
];
const M406: React.FC = () => {
  const t = useT();
  const idx = BLOCKS.reduce((a, b, i) => (t >= b.at ? i : a), 0);
  const b = BLOCKS[idx];
  const prev = BLOCKS[idx - 1];
  const wipe = idx === 0 ? 1 : r(t, b.at - 0.1, b.at + 0.45, EASE_IO);
  // diagonal band: a huge rotated field sweeping from bottom-right to cover the screen
  const off = lerp(2600, 0, wipe);
  const m = idx === 0 ? 1 : r(t, b.at, b.at + 0.6, LIQUID);
  const rad = prev ? lerp(prev.rad, b.rad, m) : b.rad;
  const rot = prev ? lerp(prev.rot, b.rot, m) : b.rot;
  const size = 380 * (idx === 0 ? r(t, 0, 0.6, LIQUID) : 1) * (1 + Math.sin(Math.PI * clamp((t - b.at) / 0.5)) * (idx ? 0.08 : 0));
  const shapeFg = idx === 3 ? C.green : "#fff";
  const tk = idx === 0 ? r(t, 0.15, 0.6) : r(t, b.at + 0.15, b.at + 0.6);
  const end = r(t, 11.3, 11.8, EASE_IN);
  return (
    <AbsoluteFill style={{ background: prev ? prev.bg : b.bg, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: -900 + off, top: -900 + off, width: 3000, height: 3000, background: b.bg, transform: "rotate(-30deg)", transformOrigin: "50% 50%" }} />
      <div style={{ position: "absolute", left: 80, top: 380, color: b.fg }}>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 32, letterSpacing: 3, opacity: 0.7 }}>{`0${idx + 1} / 04`}</div>
        <div style={{ fontFamily: DISPLAY, fontSize: 190, lineHeight: 1, marginTop: 10, transform: `translateX(${(1 - tk) * -120}px)`, opacity: tk }}>{b.title}</div>
        <div style={{ fontFamily: SERIF, fontSize: 72, lineHeight: 1.05, marginTop: 6, opacity: r(t, (idx ? b.at : 0) + 0.4, (idx ? b.at : 0) + 0.8),
          transform: `translateY(${Math.sin(t * 1.1) * 4}px)` }}>{b.sub}</div>
      </div>
      <div style={{ position: "absolute", left: 540 - size / 2, top: 1110 - size / 2, width: size, height: size, borderRadius: `${rad}%`,
        background: shapeFg, transform: `rotate(${rot}deg) scale(${1 - end}) ${float(t, 2, 6)}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: idx === 3 ? 200 : 170, fontFamily: UI, fontWeight: 900, color: "#fff", transform: `rotate(${-rot}deg) scale(${idx === 0 ? m : r(t, b.at + 0.2, b.at + 0.55, POP)})` }}>{b.icon}</div>
      </div>
      <div style={{ position: "absolute", left: 80, right: 80, top: 1390, display: "flex", gap: 12 }}>
        {BLOCKS.map((x, i) => <div key={i} style={{ flex: 1, height: 10, borderRadius: 5, background: i <= idx ? b.fg : "rgba(128,128,128,0.35)", opacity: i <= idx ? 1 : 0.6 }} />)}
      </div>
      <Sounds list={[[0.1, "pop", 0.3], [0.3, "swish", 0.2], ...BLOCKS.slice(1).flatMap((x) => [[x.at - 0.1, "whoosh", 0.38], [x.at + 0.25, "pop", 0.25]] as [number, "whoosh" | "pop", number][]),
        [9.0, "ding", 0.25], [11.3, "swish", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-07  Split-flap board above his head (fitted dark plate): yields board flips to a punchline.
// =====================================================================================================
const FLAP_SET = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%.-?";
const FLAP_PAGES = [
  { at: 0.4, rows: ["MARINA   6%", "JVC      8%", "DOWNTOWN 5%"] },
  { at: 4.4, rows: ["HIGH YIELD", "CAN MEAN", "HIGH FEES"] },
  { at: 8.4, rows: ["CHECK THE", "NET YIELD", "NOT GROSS"] },
];
const FlapCell: React.FC<{ t: number; col: number; row: number; w: number; h: number; hl?: boolean }> = ({ t, col, row, w, h, hl }) => {
  // which page are we on for this cell (staggered per column)?
  const delay = col * 0.05 + row * 0.12;
  let page = -1;
  FLAP_PAGES.forEach((p, i) => { if (t >= p.at + delay) page = i; });
  const target = page < 0 ? " " : (FLAP_PAGES[page].rows[row].padEnd(11, " ")[col] ?? " ");
  const prevCh = page <= 0 ? " " : (FLAP_PAGES[page - 1].rows[row].padEnd(11, " ")[col] ?? " ");
  const start = page < 0 ? 0 : FLAP_PAGES[page].at + delay;
  const steps = 4 + Math.floor(rand(col * 7 + row * 13 + page) * 5);
  const el = (t - start) / 0.055;
  let ch = target, frac = 1;
  if (page >= 0 && el < steps && !(target === " " && prevCh === " ")) {
    const s = Math.floor(el);
    ch = FLAP_SET[(FLAP_SET.indexOf(prevCh) + s * 7 + col) % FLAP_SET.length];
    frac = el - s;
  }
  const half: React.CSSProperties = { position: "absolute", left: 0, width: w, height: h / 2, overflow: "hidden", background: hl ? "#2B2B10" : "#232326" };
  const glyph: React.CSSProperties = { position: "absolute", left: 0, width: w, height: h, lineHeight: `${h}px`, textAlign: "center", fontFamily: MONO, fontWeight: 700,
    fontSize: h * 0.72, color: hl ? C.gold : "#F2F2F2" };
  return (
    <div style={{ position: "relative", width: w, height: h, borderRadius: 8, overflow: "hidden" }}>
      <div style={{ ...half, top: 0, transformOrigin: "50% 100%", transform: `scaleY(${frac < 1 ? Math.max(0.05, Math.abs(Math.cos(frac * Math.PI))) : 1})` }}>
        <div style={{ ...glyph, top: 0 }}>{ch}</div>
      </div>
      <div style={{ ...half, top: h / 2, borderTop: "2px solid #111" }}>
        <div style={{ ...glyph, top: -h / 2 }}>{ch}</div>
      </div>
    </div>
  );
};
const M407: React.FC = () => {
  const t = useT();
  const k = r(t, 0, 0.45, LIQUID);
  const cw = 64, chh = 92, g = 6;
  const W = 11 * cw + 10 * g + 60;
  const page = FLAP_PAGES.reduce((a, p, i) => (t >= p.at ? i : a), 0);
  return (
    <AbsoluteFill>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - W / 2, top: 262, width: W, padding: "20px 30px 26px", boxSizing: "border-box", borderRadius: 30,
        background: "rgba(14,14,16,0.94)", border: "1.5px solid rgba(255,255,255,0.12)", transform: `scale(${0.85 + 0.15 * k}) ${float(t, 3, 2)}`, opacity: clamp(k * 1.5),
        transformOrigin: "50% 0%" }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 14 }}>
          <Label size={28} color={C.gold}>{["YIELDS IN DUBAI", "HOLD ON", "THE RULE"][page]}</Label>
          <Label size={28}>{["GROSS", "!", "NET"][page]}</Label>
        </div>
        {[0, 1, 2].map((row) => (
          <div key={row} style={{ display: "flex", gap: g, marginBottom: row < 2 ? 8 : 0 }}>
            {Array.from({ length: 11 }, (_, col) => <FlapCell key={col} t={t} col={col} row={row} w={cw} h={chh} hl={page === 2 && row === 1} />)}
          </div>
        ))}
      </div>
      <DemoCaption text="Everyone quotes the gross yield" from={0.6} to={4.2} />
      <DemoCaption text="but the fees eat it." from={4.5} to={8.2} />
      <DemoCaption text="Always ask for the net." from={8.6} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.25], ...FLAP_PAGES.flatMap((p) => [0, 0.15, 0.3, 0.45, 0.6, 0.75].map((d) => [p.at + d, "tick", 0.22] as [number, "tick", number])),
        [8.4 + 1.1, "ding", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-08  Marquee ribbons: two tilted ribbons scroll behind his head (cut-out in front), a third crosses his chest.
// =====================================================================================================
const Ribbon: React.FC<{ y: number; rot: number; text: string; bg: string; fg: string; font: string; size: number; speed: number; t: number; inK: number; outK: number; fromLeft: boolean; italic?: boolean }> =
  ({ y, rot, text, bg, fg, font, size, speed, t, inK, outK, fromLeft }) => {
    const unit = `${text}  ✦  `;
    const strip = unit.repeat(10);
    const shift = ((t * speed) % 1200) - 1200;
    const clipL = fromLeft ? 0 : (1 - inK) * 100;
    const clipR = fromLeft ? (1 - inK) * 100 : 0;
    return (
      <div style={{ position: "absolute", left: -200, width: 1480, top: y, height: size * 1.45, background: bg, transform: `rotate(${rot}deg) translateY(${outK * (rot > 0 ? 700 : -700)}px)`,
        clipPath: `inset(0 ${clipR}% 0 ${clipL}%)`, overflow: "hidden", display: "flex", alignItems: "center" }}>
        <div style={{ whiteSpace: "pre", fontFamily: font, fontSize: size, color: fg, transform: `translateX(${speed > 0 ? shift : -1200 - shift}px)`, lineHeight: 1 }}>{strip}</div>
      </div>
    );
  };
const M408: React.FC = () => {
  const t = useT();
  const swap = t >= 6.2;
  const out = r(t, 11.2, 11.7, EASE_IN);
  return (
    <AbsoluteFill>
      <Backdrop />
      <Ribbon t={t} y={300} rot={-7} text={swap ? "OFF-PLAN OR READY?" : "RENT OR BUY?"} bg={C.gold} fg={INK} font={DISPLAY} size={110} speed={160}
        inK={swap ? r(t, 6.2, 6.7, EASE) : r(t, 0.2, 0.75, EASE) * (1 - r(t, 5.75, 6.15, EASE_IN))} outK={out} fromLeft={!swap || t > 6.2} />
      <Ribbon t={t} y={470} rot={5} text={swap ? "depends on your timeline" : "the honest answer"} bg={INK} fg="#fff" font={SERIF} size={84} speed={-130}
        inK={swap ? r(t, 6.35, 6.85, EASE) : r(t, 0.6, 1.15, EASE) * (1 - r(t, 5.8, 6.15, EASE_IN))} outK={out} fromLeft={false} />
      <BackPerson />
      <Ribbon t={t} y={1290} rot={-3} text="LINK IN BIO FOR THE NUMBERS" bg={C.eqt} fg="#fff" font={UI} size={58} speed={200}
        inK={r(t, 8.6, 9.1, EASE)} outK={out} fromLeft />
      <Sounds list={[[0.2, "whoosh", 0.35], [0.6, "whoosh", 0.3], [5.75, "swish", 0.35], [6.2, "whoosh", 0.35], [6.35, "whoosh", 0.25], [8.6, "whoosh", 0.32], [11.2, "swish", 0.3], [2.5, "tick", 0.1], [4.0, "tick", 0.1]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-09  Serif + script title stacks (karan spec): book serif lines + ONE connected-script payoff, zig-zag,
// blur-in word by word, lines dim to grey and vanish in reading order. Warm chocolate / burnt orange on the wall.
// =====================================================================================================
type SW = { w: string; s: number; script?: boolean };
type SL = { words: SW[]; x: number; y: number; align: "left" | "center" | "right"; outAt: number; size?: number };
const STACKS: { from: number; to: number; lines: SL[] }[] = [
  { from: 0.2, to: 3.9, lines: [
    { words: [{ w: "three", s: 0.3 }, { w: "things", s: 0.5 }], x: 110, y: 268, align: "left", outAt: 3.1 },
    { words: [{ w: "nobody", s: 0.85, script: true }], x: 560, y: 330, align: "center", outAt: 3.5 },
    { words: [{ w: "tells", s: 1.5 }, { w: "you", s: 1.7 }], x: 990, y: 488, align: "right", outAt: 3.3 },
  ] },
  { from: 4.0, to: 7.8, lines: [
    { words: [{ w: "off-plan", s: 4.1 }, { w: "rewards", s: 4.4 }], x: 980, y: 268, align: "right", outAt: 7.0 },
    { words: [{ w: "patience,", s: 4.8, script: true }], x: 520, y: 330, align: "center", outAt: 7.4 },
    { words: [{ w: "not", s: 5.5 }, { w: "speed", s: 5.7 }], x: 100, y: 488, align: "left", outAt: 7.2 },
  ] },
  { from: 7.9, to: 11.9, lines: [
    { words: [{ w: "buy", s: 8.0 }, { w: "the", s: 8.15 }], x: 120, y: 268, align: "left", outAt: 11.0 },
    { words: [{ w: "area,", s: 8.5, script: true }], x: 540, y: 330, align: "center", outAt: 11.5 },
    { words: [{ w: "not", s: 9.2 }, { w: "the", s: 9.35 }, { w: "view", s: 9.5 }], x: 980, y: 488, align: "right", outAt: 11.2 },
  ] },
];
const STK_INK = "#3A2215", STK_SCRIPT = "#C2501E";
const StackWordEl: React.FC<{ w: SW; t: number; size: number }> = ({ w, t, size }) => {
  const dur = w.script ? 0.26 : 0.18;
  const k = r(t, w.s - 0.02, w.s - 0.02 + dur);
  const fs = w.script ? size * 1.9 : size;
  if (t < w.s - 0.02) return <span style={{ display: "inline-block", opacity: 0, fontSize: fs, fontFamily: w.script ? SCRIPT : BOOK }}>{w.w}</span>;
  return (
    <span style={{ display: "inline-block", fontFamily: w.script ? SCRIPT : BOOK, fontWeight: w.script ? 400 : 600, fontSize: fs, lineHeight: w.script ? 0.95 : 1,
      color: w.script ? STK_SCRIPT : STK_INK, opacity: k, transform: `scale(${1.06 - 0.06 * k})`, filter: `blur(${(1 - k) * (w.script ? 18 : 12)}px)`,
      textShadow: "0 2px 10px rgba(255,248,235,0.6)" }}>{w.w}</span>
  );
};

// =====================================================================================================
// m4-10  Text-mask reveal over video: his video plays INSIDE huge letters on black (multiply blend), the word
// swaps, then the camera zooms through the counter of the "0" and the video fills the frame.
// =====================================================================================================
const M410: React.FC = () => {
  const t = useT();
  const word = t < 3.6 ? "DUBAI" : "2026";
  const size = word === "DUBAI" ? 330 : 420;
  const cw = size * 0.5;                   // fixed-width cells so we know where each letter sits
  const chars = Array.from(word);
  const wIn = word === "DUBAI" ? r(t, 0.2, 0.9, EASE) : r(t, 3.6, 4.2, EASE);
  const wOut = word === "DUBAI" ? r(t, 3.25, 3.6, EASE_IN) : 0;
  const zoom = r(t, 6.3, 7.5, EASE_IN);
  const fadeBlack = r(t, 6.95, 7.35);
  const ox = 540 - cw * 0.5 - size * 0.16, oy = 960;   // on the left stroke of the "0" (2nd char of 2026): zooming into the stroke fills the frame with video
  const sc = 1 + zoom * zoom * 40;
  const after = r(t, 7.8, 8.3, POP);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Backdrop />
      <AbsoluteFill style={{ background: "#000", mixBlendMode: "multiply", opacity: 1 - fadeBlack }}>
        <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: 1920, transform: `scale(${sc})`, transformOrigin: `${ox}px ${oy}px` }}>
          <div style={{ position: "absolute", left: 540 - chars.reduce((a, ch) => a + (ch === "I" ? size * 0.26 : cw), 0) / 2, top: oy - size / 2, display: "flex" }}>
            {chars.map((ch, i) => {
              const a = clamp(wIn * 1.6 - i * 0.15);
              return <div key={i} style={{ width: ch === "I" ? size * 0.26 : cw, height: size, lineHeight: `${size}px`, textAlign: "center", fontFamily: DISPLAY, fontSize: size, color: "#fff",
                transform: `translateY(${(1 - a) * 160 - wOut * 200}px)`, opacity: a * (1 - wOut) }}>{ch}</div>;
            })}
          </div>
        </div>
      </AbsoluteFill>
      {/* normal-blend labels on the black */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 640, textAlign: "center", opacity: env(t, 0.6, 6.2, 0.4, 0.3) }}>
        <Label size={32} color="rgba(255,255,255,0.7)">{t < 3.6 ? "REAL ESTATE" : "WHY THIS YEAR IS DIFFERENT"}</Label>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1210, textAlign: "center", fontFamily: SERIF, fontSize: 80, color: "#fff", opacity: env(t, 1.0, 6.2, 0.4, 0.3) * (t < 3.25 || t > 4.0 ? 1 : 0) }}>
        {t < 3.6 ? "what nobody explains" : "supply is catching up"}
      </div>
      {after > 0 && (
        <div style={{ position: "absolute", left: 0, right: 0, top: 290, display: "flex", justifyContent: "center", transform: float(t, 4, 3) }}>
          <div style={{ background: "rgba(14,14,16,0.92)", borderRadius: 28, padding: "20px 34px", textAlign: "center", transform: `scale(${after})`, transformOrigin: "50% 0%" }}>
            <Label size={28} color={C.gold}>2026</Label>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 54, color: "#fff", whiteSpace: "nowrap" }}>{typed("More supply, smarter buyers", t, 8.0, 0.04)}</div>
          </div>
        </div>
      )}
      <DemoCaption text="So here's how to play it." from={9.6} to={12.8} />
      <Sounds list={[[0.2, "impact", 0.35], [1.0, "tick", 0.15], [3.25, "swish", 0.3], [3.6, "impact", 0.38], [4.0, "tick", 0.15], [6.2, "riser", 0.3], [7.1, "whoosh", 0.42],
        [7.8, "pop", 0.3], [8.0, "type", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-11  Typewriter terminal above his head: the window grows line by line (liquid), numbers count up, verdict.
// =====================================================================================================
const TERM = [
  { at: 0.5, kind: "cmd", text: "rent_vs_buy --years 5" },
  { at: 2.0, kind: "out", text: "rent paid", val: 600000, col: C.red },
  { at: 3.3, kind: "out", text: "equity built", val: 410000, col: C.green },
  { at: 5.0, kind: "cmd", text: "verdict --stay 5+" },
  { at: 6.6, kind: "res", text: "BUY  (if you stay 5+ years)" },
  { at: 8.6, kind: "cmd", text: "verdict --stay 2" },
  { at: 10.1, kind: "res2", text: "RENT (stay flexible)" },
] as const;
const M411: React.FC = () => {
  const t = useT();
  const shown = TERM.filter((l) => t >= l.at - 0.05);
  const LH = 50;
  const maxRows = 5;
  const rows = shown.length;
  // scroll: once there are more than maxRows lines, the oldest slides up out of the window
  const scrollRows = Math.max(0, rows - maxRows);
  const lastAt = shown[shown.length - 1]?.at ?? 0;
  const scroll = rows > maxRows ? lerp(scrollRows - 1, scrollRows, r(t, lastAt - 0.05, lastAt + 0.25, EASE)) : 0;
  const visRows = Math.min(rows, maxRows);
  const hTarget = 76 + Math.max(1, visRows) * LH + 24;
  const prevH = 76 + Math.max(1, Math.min(rows - 1, maxRows)) * LH + 24;
  const H = rows <= maxRows ? lerp(prevH, hTarget, r(t, lastAt - 0.05, lastAt + 0.35, LIQUID)) : hTarget;
  const k = r(t, 0, 0.4, LIQUID);
  const cursorOn = Math.floor(t * 2.4) % 2 === 0;
  return (
    <AbsoluteFill>
      <Backdrop />
      <div style={{ position: "absolute", left: 100, width: 880, top: 262, height: H * k, borderRadius: 24, background: "rgba(12,12,14,0.95)",
        border: "1.5px solid rgba(255,255,255,0.14)", overflow: "hidden", transform: float(t, 5, 2) }}>
        <div style={{ height: 56, display: "flex", alignItems: "center", gap: 10, padding: "0 22px", borderBottom: "1.5px solid rgba(255,255,255,0.08)" }}>
          {["#FF5F57", "#FEBC2E", "#28C840"].map((c, i) => <div key={i} style={{ width: 18, height: 18, borderRadius: 9, background: c }} />)}
          <div style={{ flex: 1, textAlign: "center", fontFamily: MONO, fontWeight: 500, fontSize: 26, color: "rgba(255,255,255,0.5)", marginRight: 60 }}>eqt — calculator</div>
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, top: 58, bottom: 0, overflow: "hidden" }}><div style={{ position: "absolute", left: 28, right: 28, top: 12, transform: `translateY(${-scroll * LH}px)` }}>
          {shown.map((l, i) => {
            const isLast = i === shown.length - 1;
            const base: React.CSSProperties = { height: LH, display: "flex", alignItems: "center", fontFamily: MONO, fontWeight: 700, fontSize: 34, whiteSpace: "nowrap" };
            if (l.kind === "cmd") {
              const txt = typed(l.text, t, l.at, 0.05);
              const typing = txt.length < l.text.length;
              return <div key={i} style={base}><span style={{ color: C.green }}>❯&nbsp;</span><span style={{ color: "#fff" }}>{txt}</span>
                {(typing || isLast) && cursorOn && <span style={{ display: "inline-block", width: 18, height: 36, background: "#fff", marginLeft: 4 }} />}</div>;
            }
            if (l.kind === "out") {
              const v = Math.round(lerp(0, l.val, r(t, l.at + 0.1, l.at + 1.0, EASE_IO)) / 1000) * 1000;
              return <div key={i} style={{ ...base, justifyContent: "space-between", color: "rgba(255,255,255,0.6)", opacity: r(t, l.at, l.at + 0.15) }}>
                <span>{`  ${l.text}`} <span style={{ color: "rgba(255,255,255,0.25)" }}>{"........"}</span></span>
                <span style={{ color: l.col }}>AED {v.toLocaleString("en-US")}</span></div>;
            }
            const res = l.kind === "res";
            const txt = typed(l.text, t, l.at, 0.035);
            const hl = r(t, l.at + 0.9, l.at + 1.2, EASE);
            return <div key={i} style={base}>
              <span style={{ position: "relative", color: res ? C.green : C.gold, fontWeight: 700 }}>
                <span style={{ position: "absolute", left: -8, right: -8, top: 4, bottom: 4, background: res ? "rgba(48,209,88,0.18)" : "rgba(255,214,10,0.16)",
                  transformOrigin: "left", transform: `scaleX(${hl})`, borderRadius: 6 }} />
                <span style={{ position: "relative" }}>{`→ ${txt}`}</span>
              </span></div>;
          })}
        </div></div>
      </div>
      <DemoCaption text="Let's run the numbers." from={0.4} to={4.8} />
      <DemoCaption text="Staying five years? Buy." from={6.6} to={8.5} />
      <DemoCaption text="Two years? Rent." from={10.1} to={12.8} />
      <Sounds list={[[0.05, "pop", 0.25], [0.5, "type", 0.25], [2.0, "tick", 0.2], [2.1, "riser", 0.15], [3.3, "tick", 0.2], [5.0, "type", 0.25], [6.6, "type", 0.2],
        [7.5, "ding", 0.3], [8.6, "type", 0.25], [10.1, "type", 0.2], [11.0, "ding", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-12  Word ladder: small mono lines and HUGE bold words alternate, the ladder scrolls up like a camera follow.
// =====================================================================================================
const LADDER = [
  { w: "you don't need", big: false, at: 0.2 }, { w: "MILLIONS", big: true, at: 0.7 },
  { w: "to start in dubai", big: false, at: 1.9 }, { w: "YOU NEED", big: true, at: 2.5 },
  { w: "a clear", big: false, at: 3.8 }, { w: "PLAN", big: true, at: 4.3, acc: true },
  { w: "the right", big: false, at: 5.7 }, { w: "TIMING", big: true, at: 6.2 },
  { w: "and one honest", big: false, at: 7.6 }, { w: "ADVISOR", big: true, at: 8.1, acc: true },
];
const M412: React.FC = () => {
  const t = useT();
  const BIG = 230, SMALL = 46, GAP = 10;
  let y = 0;
  const pos = LADDER.map((l) => { const top = y; y += (l.big ? BIG * 0.95 : SMALL * 1.5) + GAP; return top; });
  // camera: keep the newest row near y 1050
  const cur = LADDER.reduce((a, l, i) => (t >= l.at ? i : a), 0);
  const camFor = (i: number) => Math.max(0, pos[i] + (LADDER[i].big ? BIG * 0.95 : SMALL * 1.5) - 640);
  const prevCam = camFor(Math.max(0, cur - 1));
  const cam = lerp(prevCam, camFor(cur), r(t, LADDER[cur].at - 0.1, LADDER[cur].at + 0.5, EASE));
  const outro = r(t, 9.8, 10.6, EASE_IO);
  return (
    <AbsoluteFill style={{ background: "#F2EEE6", overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: lerp(620, 300, outro), transform: `translateY(${-cam * (1 - outro)}px) scale(${1 - outro * 0.38})`, transformOrigin: "50% 0%" }}>
        {LADDER.map((l, i) => {
          if (t < l.at - 0.02) return null;
          const k = r(t, l.at, l.at + (l.big ? 0.35 : 0.25), EASE);
          const left = i % 4 < 2;
          const id = `m4-12-b${i}`;
          const txt = l.big ? l.w : typed(l.w, t, l.at, 0.035);
          const fade = i < cur - 3 ? 0.35 : 1;
          return (
            <div key={i} style={{ position: "absolute", top: pos[i], left: 80, right: 80, display: "flex", justifyContent: left ? "flex-start" : "flex-end", opacity: fade }}>
              {l.big && <DirBlur id={id} y={(1 - k) * 20} />}
              <div style={{ fontFamily: l.big ? DISPLAY : MONO, fontWeight: l.big ? 400 : 500, fontSize: l.big ? BIG : SMALL, lineHeight: l.big ? 0.95 : 1.5,
                color: l.acc ? "#E2541B" : INK, letterSpacing: l.big ? 1 : 0, whiteSpace: "nowrap",
                transform: l.big ? `scale(${1.25 - 0.25 * k})` : "none", transformOrigin: left ? "0% 50%" : "100% 50%", opacity: l.big ? k : 1,
                filter: l.big ? blurIf(id, (1 - k) * 20) : "none" }}>{txt}</div>
            </div>
          );
        })}
      </div>
      {/* a thin rail on the left tracks progress down the ladder */}
      <div style={{ position: "absolute", left: 40, top: 300, width: 6, height: 1100, borderRadius: 3, background: "rgba(20,20,22,0.1)" }}>
        <div style={{ width: 6, borderRadius: 3, background: "#E2541B", height: 1100 * lerp(cur / (LADDER.length - 1), (cur + 1) / (LADDER.length - 1), 0) }} />
      </div>
      <Sounds list={LADDER.map((l) => [l.at, l.big ? "impact" : "type", l.big ? 0.32 : 0.16] as [number, "impact" | "type", number]).concat([[9.8, "swish", 0.25] as [number, "swish", number]])} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-13  Circular text badge: a dot grows into a gold disc, ring text writes on around it and turns slowly;
// the centre rolls 60/40 → 2028, then the badge rolls left and a plate unfolds from it.
// =====================================================================================================
const M413: React.FC = () => {
  const t = useT();
  const R = 118;
  const swap = t >= 5.2;
  const ringTxt = swap ? "HANDOVER • KEYS • HANDOVER • KEYS • " : "OFF-PLAN • PAYMENT PLAN • OFF-PLAN • ";
  const born = r(t, 0.15, 0.6, LIQUID);
  const write = swap ? r(t, 5.3, 6.2, EASE) : r(t, 0.5, 1.6, EASE);
  const unwrite = swap ? 0 : r(t, 4.7, 5.15, EASE_IN);
  const spin = t * 22 + r(t, 4.6, 5.6, EASE_IO) * 360;
  const roll = r(t, 8.4, 9.3, EASE_IO);
  const cx = lerp(770, 250, roll), cy = 420;
  const disc = 105 * born;
  const plate = r(t, 9.0, 9.6, LIQUID);
  const n1 = r(t, 0.9, 1.9, EASE_IO);
  const centreSwap = r(t, 5.0, 5.5, EASE_IO);
  const circ = 2 * Math.PI * R;
  const nChars = Math.round(ringTxt.length * (write - unwrite));
  const blurAmt = Math.abs(Math.sin(r(t, 4.6, 5.6, EASE_IO) * Math.PI)) * 4 + roll * (1 - roll) * 12;
  return (
    <AbsoluteFill>
      <Backdrop />
      {/* plate unfolding to the right of the badge */}
      {plate > 0 && (
        <div style={{ position: "absolute", left: 250, top: 330, height: 180, width: lerp(0, 680, plate), borderRadius: 90, background: "rgba(20,20,22,0.92)",
          overflow: "hidden", display: "flex", alignItems: "center" }}>
          <div style={{ marginLeft: 175, whiteSpace: "nowrap", opacity: r(t, 9.4, 9.8) }}>
            <Label size={28} color={C.gold}>THE CATCH</Label>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 56, color: "#fff" }}>{typed("40% due on keys", t, 9.5, 0.04)}</div>
          </div>
        </div>
      )}
      <div style={{ position: "absolute", left: cx - 160, top: cy - 160, width: 320, height: 320, transform: `rotate(${roll * -360}deg)` }}>
        <svg width="320" height="320" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs><path id="m4-13-ring" d={`M ${160 - R},160 a ${R},${R} 0 1,1 ${2 * R},0 a ${R},${R} 0 1,1 ${-2 * R},0`} /></defs>
          <circle cx="160" cy="160" r={(R + 34) * born} fill="rgba(20,20,22,0.92)" />
          <circle cx="160" cy="160" r={disc} fill={swap ? C.eqt : C.gold} />
          <g transform={`rotate(${spin} 160 160)`} style={{ filter: blurAmt > 0.5 ? `blur(${blurAmt * 0.3}px)` : "none" }}>
            <text fontFamily={UI} fontWeight={800} fontSize={30} fill="#fff" letterSpacing={2}>
              <textPath href="#m4-13-ring" textLength={circ - 6} lengthAdjust="spacing">{ringTxt.slice(0, Math.max(0, nChars)).padEnd(ringTxt.length, " ")}</textPath>
            </text>
          </g>
        </svg>
        <div style={{ position: "absolute", left: 0, right: 0, top: 0, bottom: 0, display: "flex", alignItems: "center", justifyContent: "center",
          transform: `rotate(${roll * 360}deg)`, overflow: "hidden", borderRadius: 160 }}>
          <div style={{ position: "relative", height: 120, width: 220, overflow: "hidden" }}>
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", transform: `translateY(${-centreSwap * 120}px)`,
              fontFamily: DISPLAY, fontSize: 84, color: INK, opacity: born }}>
              {`${Math.round(lerp(0, 60, n1))}/${Math.round(lerp(0, 40, n1))}`}
            </div>
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", transform: `translateY(${(1 - centreSwap) * 120}px)`,
              fontFamily: DISPLAY, fontSize: 84, color: "#fff" }}>2028</div>
          </div>
        </div>
      </div>
      <DemoCaption text="60 now, 40 when you get the keys" from={1.0} to={4.8} />
      <DemoCaption text="and handover might be 2028." from={5.4} to={8.4} />
      <Sounds list={[[0.15, "pop", 0.3], [0.5, "type", 0.18], [0.9, "tick", 0.18], [1.9, "ding", 0.2], [4.6, "whoosh", 0.3], [5.0, "swish", 0.25], [5.3, "type", 0.18],
        [8.4, "whoosh", 0.32], [9.0, "pop", 0.25], [9.5, "type", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-14  Zoom-through letters: the camera dives through the "O" (a porthole) into the next scene, twice,
// the second time landing in his video.
// =====================================================================================================
const Porthole: React.FC<{ w: number; h: number; ring: number; col: string }> = ({ w, h, ring, col }) => (
  <div style={{ width: w, height: h, borderRadius: w / 2, border: `${ring}px solid ${col}`, boxSizing: "border-box", flexShrink: 0 }} />
);
const ZoomWord: React.FC<{ pre: string; post: string; size: number; col: string; holeCol: string; k: number; zoom: number; bg: string; sub: string; subK: number; label: string }> =
  ({ pre, post, size, col, k, zoom, bg, sub, subK, label }) => {
    const ow = size * 0.5, oh = size * 0.74, ring = size * 0.14;
    const cy = 900;
    // the screen-sized plate with a hole where the porthole's counter is
    const sc = 1 + Math.pow(zoom, 3) * 70;
    const preW = pre.length * size * 0.47, postW = post.length * size * 0.47;
    const total = preW + ow + postW + size * 0.06;
    const ox = 540 - total / 2 + preW + size * 0.03 + ow / 2;
    const hw = ow - 2 * ring, hh = oh - 2 * ring;
    return (
      <AbsoluteFill style={{ transform: `scale(${sc})`, transformOrigin: `${ox}px ${cy}px` }}>
        <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
          <path fillRule="evenodd" fill={bg} d={`M-2000,-2000 H3080 V3920 H-2000 Z M${ox - hw / 2},${cy - hh / 2 + hw / 2} a${hw / 2},${hw / 2} 0 0,1 ${hw},0 V${cy + hh / 2 - hw / 2} a${hw / 2},${hw / 2} 0 0,1 ${-hw},0 Z`} />
        </svg>
        <div style={{ position: "absolute", left: 540 - total / 2, top: cy - oh / 2, height: oh, display: "flex", alignItems: "center", gap: size * 0.03,
          opacity: clamp(k * 2), transform: `translateY(${(1 - k) * 60}px)` }}>
          <div style={{ width: preW, textAlign: "right", fontFamily: DISPLAY, fontSize: size, lineHeight: `${oh}px`, height: oh, color: col, display: "flex", justifyContent: "flex-end", alignItems: "center" }}>
            <span style={{ transform: `translateY(${size * 0.035}px)` }}>{pre}</span></div>
          <Porthole w={ow} h={oh} ring={ring} col={col} />
          <div style={{ width: postW, fontFamily: DISPLAY, fontSize: size, lineHeight: `${oh}px`, height: oh, color: col, display: "flex", alignItems: "center" }}>
            <span style={{ transform: `translateY(${size * 0.035}px)` }}>{post}</span></div>
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, top: cy - oh / 2 - 90, textAlign: "center", opacity: subK }}><Label size={32} color={col}>{label}</Label></div>
        <div style={{ position: "absolute", left: 0, right: 0, top: cy + oh / 2 + 40, textAlign: "center", fontFamily: SERIF, fontSize: 76, color: col, opacity: subK }}>{sub}</div>
      </AbsoluteFill>
    );
  };
const M414: React.FC = () => {
  const t = useT();
  const z1 = r(t, 3.4, 4.4, EASE_IN), z2 = r(t, 7.6, 8.6, EASE_IN);
  const plate = r(t, 8.9, 9.4, LIQUID);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Backdrop />
      {z2 < 1 && (
        <ZoomWord pre="G" post="AL?" size={330} col="#fff" holeCol="" bg={C.blue} k={r(t, 4.2, 4.8, EASE)} zoom={z2} sub="yield, or growth?" subK={r(t, 4.8, 5.3) * (1 - z2 * 3)}
          label="WHAT'S YOUR" />
      )}
      {z1 < 1 && (
        <ZoomWord pre="R" post="I" size={460} col={INK} holeCol="" bg="#F2EEE6" k={r(t, 0.2, 0.8, EASE)} zoom={z1} sub="everyone asks about it" subK={r(t, 0.8, 1.3) * (1 - z1 * 3)}
          label="THE WORD OF THE YEAR" />
      )}
      {plate > 0 && (
        <div style={{ position: "absolute", left: 0, right: 0, top: 290, display: "flex", justifyContent: "center", transform: float(t, 6, 3) }}>
          <div style={{ background: "rgba(20,20,22,0.92)", borderRadius: 30, padding: "22px 36px", transform: `scale(${plate})`, transformOrigin: "50% 0%", display: "flex", gap: 18 }}>
            {["YIELD", "GROWTH"].map((w, i) => {
              const a = r(t, 9.3 + i * 0.25, 9.6 + i * 0.25, POP);
              return <div key={i} style={{ fontFamily: UI, fontWeight: 900, fontSize: 60, padding: "8px 26px", borderRadius: 22, color: i ? INK : "#fff",
                background: i ? C.gold : C.blue, transform: `scale(${a})` }}>{w}</div>;
            })}
          </div>
        </div>
      )}
      <DemoCaption text="Pick one. You rarely get both." from={9.7} to={12.8} />
      <Sounds list={[[0.2, "impact", 0.35], [0.8, "tick", 0.15], [3.3, "riser", 0.3], [4.15, "whoosh", 0.42], [4.3, "impact", 0.3], [4.8, "tick", 0.15],
        [7.5, "riser", 0.3], [8.35, "whoosh", 0.42], [8.9, "pop", 0.3], [9.3, "pop", 0.22], [9.55, "pop", 0.22]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-15  Ink-blot reveal: ink spreads across cream paper (goo-merged blots) and the hidden cream words appear
// on it; then an orange blot blooms inside the ink and reveals the answer in script.
// =====================================================================================================
const BLOTS = [
  [330, 760, 230, 0.4], [700, 720, 260, 0.6], [520, 900, 300, 0.75], [250, 1000, 190, 0.95], [820, 960, 220, 1.05],
  [540, 1120, 240, 1.25], [180, 820, 140, 1.35], [920, 800, 150, 1.45], [420, 600, 160, 1.6], [760, 1180, 170, 1.7],
] as const;
const BLOTS2 = [[540, 960, 300, 4.4], [360, 1020, 190, 4.65], [740, 900, 200, 4.8], [520, 1150, 160, 5.0], [420, 830, 150, 5.1], [690, 1100, 150, 5.2]] as const;
const M415: React.FC = () => {
  const t = useT();
  const drain = r(t, 10.6, 11.6, EASE_IN);
  const blot = (b: readonly [number, number, number, number], i: number, grow: number) => {
    const k = r(t, b[3], b[3] + 0.9, EASE) * grow;
    return <circle key={i} cx={b[0] + Math.sin(t * 0.8 + i) * 6} cy={b[1] + Math.cos(t * 0.7 + i) * 6} r={b[2] * k * (1 - drain)} />;
  };
  const drops = Array.from({ length: 10 }, (_, i) => {
    const at = 0.3 + i * 0.12;
    const k = r(t, at, at + 0.5, EASE);
    return <circle key={`d${i}`} cx={120 + rand(i + 3) * 840} cy={560 + rand(i + 8) * 760} r={(18 + rand(i) * 30) * k * (1 - drain)} />;
  });
  const text = (s: string, y: number, font: string, size: number, col: string, op: number) => (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, textAlign: "center", fontFamily: font, fontSize: size, color: col, lineHeight: 1, opacity: op }}>{s}</div>
  );
  return (
    <AbsoluteFill style={{ background: C.paper }}>
      {/* paper grain lines so the cream never sits empty */}
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, opacity: 0.6 }}>
        {Array.from({ length: 28 }, (_, i) => <line key={i} x1="0" y1={i * 70} x2="1080" y2={i * 70} stroke="#ECE6D8" strokeWidth="2" />)}
      </svg>
      <div style={{ position: "absolute", left: 0, right: 0, top: 330, textAlign: "center" }}><Label size={30} color="rgba(28,28,30,0.6)">{typed("THE ONLY TIMING RULE", t, 0.1, 0.04)}</Label></div>
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
        <GooDefs id="m4-15-goo" blur={16} />
        <g filter="url(#m4-15-goo)" fill={INK}>{BLOTS.map((b, i) => blot(b, i, 1))}{drops}</g>
        <g filter="url(#m4-15-goo)" fill="#E2541B">{BLOTS2.map((b, i) => blot(b, i + 20, 1))}</g>
      </svg>
      {/* words in the paper colour: invisible on paper, appear as the ink arrives under them */}
      {text("Don't time", 760, BOOK, 150, C.paper, 1 - r(t, 4.3, 4.7))}
      {text("the market.", 920, BOOK, 150, C.paper, 1 - r(t, 4.3, 4.7))}
      {text("Time in", 770, SCRIPT, 230, INK, r(t, 5.0, 5.6) * (1 - drain))}
      {text("the market.", 990, BOOK, 130, INK, r(t, 5.5, 6.1) * (1 - drain))}
      {text("— hold 5+ years", 1160, SERIF, 64, C.paper, r(t, 7.0, 7.5) * (1 - drain))}
      <Sounds list={[[0.1, "type", 0.18], [0.4, "swish", 0.3], [0.9, "pop", 0.2], [1.4, "pop", 0.18], [4.3, "whoosh", 0.32], [4.8, "pop", 0.25], [5.1, "swish", 0.3], [7.0, "tick", 0.2],
        [10.6, "swish", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-16  Torn-paper reveal: a poster tears across and the halves fly apart revealing the next sheet; the second
// tear (vertical) reveals his video with a torn paper strip label above his head.
// =====================================================================================================
const jag = (n: number, seed: number, amp: number) => Array.from({ length: n + 1 }, (_, i) => (rand(i * 3.1 + seed) - 0.5) * amp + (i % 2 ? amp * 0.25 : -amp * 0.25));
const TornHalves: React.FC<{ k: number; dir: "h" | "v"; at: number; seed: number; children: React.ReactNode; paper: string }> = ({ k, dir, at, seed, children, paper }) => {
  const n = 36;
  const J = jag(n, seed, 46);
  const pts = (off: number) => J.map((j, i) => dir === "h" ? `${(i / n) * 1080}px ${at + j + off}px` : `${at + j + off}px ${(i / n) * 1920}px`);
  const A = (off: number) => dir === "h" ? `polygon(0px 0px, 1080px 0px, ${pts(off).reverse().join(", ")})` : `polygon(0px 0px, ${pts(off).join(", ")}, 0px 1920px)`;
  const B = (off: number) => dir === "h" ? `polygon(${pts(off).join(", ")}, 1080px 1920px, 0px 1920px)` : `polygon(${pts(off).join(", ")}, 1080px 1920px, 1080px 0px)`;
  const mvA = dir === "h" ? `translate(${-k * 60}px, ${-k * 1300}px) rotate(${-k * 8}deg)` : `translate(${-k * 1300}px, ${k * 80}px) rotate(${-k * 7}deg)`;
  const mvB = dir === "h" ? `translate(${k * 50}px, ${k * 1300}px) rotate(${k * 6}deg)` : `translate(${k * 1300}px, ${-k * 60}px) rotate(${k * 6}deg)`;
  const half = (clip: string, fibre: string, mv: string) => (
    <AbsoluteFill style={{ transform: mv, transformOrigin: "50% 50%" }}>
      <AbsoluteFill style={{ background: "#FFFFFF", clipPath: fibre, filter: "drop-shadow(0 10px 18px rgba(0,0,0,0.25))" }} />
      <AbsoluteFill style={{ clipPath: clip, background: paper }}>{children}</AbsoluteFill>
    </AbsoluteFill>
  );
  return <>{half(A(0), A(k > 0 ? 9 : 0), mvA)}{half(B(0), B(k > 0 ? -9 : 0), mvB)}</>;
};
const M416: React.FC = () => {
  const t = useT();
  const tear1 = r(t, 3.6, 4.6, EASE_IN), tear2 = r(t, 7.8, 8.8, EASE_IN);
  // the tear starts with a small "rip" wobble before the halves fly
  const rip1 = Math.sin(r(t, 3.3, 3.6) * Math.PI) * 6, rip2 = Math.sin(r(t, 7.5, 7.8) * Math.PI) * 6;
  const strip = r(t, 9.0, 9.4, POP);
  return (
    <AbsoluteFill>
      <Backdrop />
      {strip > 0 && (
        <div style={{ position: "absolute", left: 0, right: 0, top: 300, display: "flex", justifyContent: "center", transform: float(t, 2, 3) }}>
          <div style={{ background: "#F3EBDD", padding: "22px 50px", transform: `rotate(-2.5deg) scale(${strip})`, color: INK, textAlign: "center",
            clipPath: `polygon(${jag(10, 4, 14).map((j, i) => `${i * 10}% ${Math.abs(j)}px`).join(", ")}, ${jag(10, 9, 14).map((j, i) => `${100 - i * 10}% calc(100% - ${Math.abs(j)}px)`).join(", ")})` }}>
            <Label size={28} color="#9A6B3C">RULE OF THUMB</Label>
            <div style={{ fontFamily: DISPLAY, fontSize: 92, lineHeight: 1.05, whiteSpace: "nowrap" }}>OFFER 5–10% BELOW</div>
          </div>
        </div>
      )}
      {tear2 < 1 && (
        <TornHalves k={tear2} dir="v" at={540} seed={7} paper="#E2541B">
          <div style={{ position: "absolute", left: 80, right: 80, top: 560, color: "#FFF4E6", transform: `translateX(${rip2}px)` }}>
            <Label size={32} color="rgba(255,244,230,0.75)">TRUTH #1</Label>
            {["THE LISTING", "PRICE IS NOT", "THE PRICE"].map((l, i) => {
              const a = r(t, 4.0 + i * 0.18, 4.4 + i * 0.18, EASE);
              return <div key={i} style={{ fontFamily: DISPLAY, fontSize: 168, lineHeight: 1, opacity: a, transform: `translateY(${(1 - a) * 50}px)`, color: i === 1 ? INK : "#FFF4E6" }}>{l}</div>;
            })}
            <div style={{ fontFamily: SERIF, fontSize: 70, marginTop: 24, opacity: r(t, 5.0, 5.5) }}>it's where talks begin.</div>
          </div>
        </TornHalves>
      )}
      {tear1 < 1 && (
        <TornHalves k={tear1} dir="h" at={1010} seed={2} paper="#F3EBDD">
          <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, opacity: 0.5 }}>
            {Array.from({ length: 30 }, (_, i) => <line key={i} x1="0" y1={i * 66} x2="1080" y2={i * 66} stroke="#E4D8C4" strokeWidth="2" />)}
          </svg>
          <div style={{ position: "absolute", left: 80, right: 80, top: 560, color: INK, transform: `translateY(${rip1}px)` }}>
            <Label size={32} color="#9A6B3C">{typed("WHAT AGENTS DON'T SAY", t, 0.2, 0.04)}</Label>
            {["WHAT", "AGENTS", "WON'T", "TELL YOU"].map((l, i) => {
              const a = r(t, 0.4 + i * 0.2, 0.8 + i * 0.2, EASE);
              return <div key={i} style={{ fontFamily: DISPLAY, fontSize: 170, lineHeight: 0.98, opacity: a, transform: `translateX(${(1 - a) * -60}px)`, color: i === 2 ? "#E2541B" : INK }}>{l}</div>;
            })}
          </div>
        </TornHalves>
      )}
      <DemoCaption text="So always make an offer." from={9.3} to={11.8} />
      <Sounds list={[[0.2, "type", 0.18], [0.4, "impact", 0.3], [1.0, "tick", 0.15], [3.3, "swish", 0.25], [3.6, "whoosh", 0.4], [4.0, "impact", 0.3], [5.0, "tick", 0.15],
        [7.5, "swish", 0.25], [7.8, "whoosh", 0.4], [9.0, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-17  Tape label slams: strips of tape with bold words slam onto the room above his head (tiny shake),
// then peel away and the last strip slams alone.
// =====================================================================================================
const TAPES = [
  { text: "NO AGENT FEES?", bg: C.gold, fg: INK, y: 262, rot: -4, x: 500, at: 0.4, out: 8.6 },
  { text: "READ THE CONTRACT", bg: "#F5F5F0", fg: INK, y: 395, rot: 1.5, x: 580, at: 2.4, out: 8.8 },
  { text: "CHECK SERVICE FEES", bg: C.red, fg: "#fff", y: 528, rot: -1.5, x: 520, at: 4.6, out: 9.0 },
  { text: "SAVE THIS", bg: INK, fg: C.gold, y: 330, rot: -3, x: 540, at: 9.6, out: 99 },
];
const Tape: React.FC<{ tp: typeof TAPES[number]; t: number }> = ({ tp, t }) => {
  const k = r(t, tp.at, tp.at + 0.22, EASE_IN);
  const peel = r(t, tp.out, tp.out + 0.45, EASE_IN);
  if (t < tp.at) return null;
  const sc = lerp(1.7, 1, k);
  const ends = jag(6, tp.at * 10, 18).map((j, i) => `${Math.abs(j)}px ${(i / 6) * 100}%`);
  const ends2 = jag(6, tp.at * 13, 18).map((j, i) => `calc(100% - ${Math.abs(j)}px) ${100 - (i / 6) * 100}%`);
  return (
    <div style={{ position: "absolute", left: tp.x, top: tp.y, transform: `translateX(-50%) rotate(${tp.rot + peel * 25}deg) translateY(${-peel * 500}px) scale(${sc})`,
      opacity: Math.min(1, k * 2) * (1 - peel), transformOrigin: "0% 50%" }}>
      <div style={{ background: tp.bg, color: tp.fg, fontFamily: DISPLAY, fontSize: 78, lineHeight: 1, padding: "12px 52px 10px", whiteSpace: "nowrap", letterSpacing: 2,
        clipPath: `polygon(${ends.join(", ")}, ${ends2.join(", ")})`, boxShadow: "0 8px 20px rgba(0,0,0,0.2)", opacity: 0.97,
        backgroundImage: "repeating-linear-gradient(90deg, rgba(255,255,255,0.07) 0px, rgba(255,255,255,0.07) 2px, rgba(0,0,0,0) 2px, rgba(0,0,0,0) 9px)" }}>{tp.text}</div>
    </div>
  );
};
const M417: React.FC = () => {
  const t = useT();
  const shake = TAPES.reduce((a, tp) => a + Math.sin((t - tp.at - 0.22) * 70) * 8 * (1 - r(t, tp.at + 0.22, tp.at + 0.5)) * (t > tp.at + 0.22 ? 1 : 0), 0);
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ transform: `translate(${shake * 0.6}px, ${shake}px)` }}>
        <Backdrop zoom={1.06} />
        {TAPES.map((tp, i) => <Tape key={i} tp={tp} t={t} />)}
      </AbsoluteFill>
      <DemoCaption text="Before you sign anything" from={0.5} to={4.4} />
      <DemoCaption text="check these three." from={4.6} to={8.5} />
      <DemoCaption text="You'll need this later." from={9.7} to={11.8} />
      <Sounds list={[...TAPES.flatMap((tp) => [[tp.at - 0.05, "swish", 0.2], [tp.at + 0.2, "impact", 0.42]] as [number, "swish" | "impact", number][]),
        [8.6, "whoosh", 0.25], [8.8, "whoosh", 0.22], [9.0, "whoosh", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-18  Highlighter swipe across a sentence on a paper card above his head (+ a hand-drawn circle), then
// the card flips its text to the next sentence with a new swipe.
// =====================================================================================================
const SENTS = [
  { at: 0.3, pre: "The price is ", circ: "just the start.", mid: " Budget ", hl: "7% on top", post: " for fees." },
  { at: 6.2, pre: "Service charges come ", circ: "every year.", mid: " Ask for the ", hl: "last 3 invoices", post: "." },
];
const M418: React.FC = () => {
  const t = useT();
  const k = r(t, 0, 0.4, LIQUID);
  return (
    <AbsoluteFill>
      <Backdrop />
      <div style={{ position: "absolute", left: 90, width: 900, top: 262, height: 270, borderRadius: 26, background: "#FBF8F1", boxShadow: "0 18px 40px rgba(0,0,0,0.25)",
        overflow: "hidden", transform: `scale(${0.85 + 0.15 * k}) ${float(t, 7, 2)}`, opacity: clamp(k * 1.5), transformOrigin: "50% 0%" }}>
        <svg width="900" height="300" style={{ position: "absolute", inset: 0 }}>
          {Array.from({ length: 6 }, (_, i) => <line key={i} x1="0" y1={78 + i * 64} x2="900" y2={78 + i * 64} stroke="#EFE8DA" strokeWidth="2" />)}
          <line x1="70" y1="0" x2="70" y2="300" stroke="rgba(255,69,58,0.25)" strokeWidth="2" />
        </svg>
        {SENTS.map((s, si) => {
          const next = SENTS[si + 1]?.at ?? 99;
          const inK = r(t, s.at, s.at + 0.45, EASE), outK = r(t, next - 0.5, next - 0.1, EASE_IN);
          if (t < s.at - 0.05 || outK >= 1) return null;
          const hl = r(t, s.at + 2.2, s.at + 2.75, EASE_IO);
          const circ = r(t, s.at + 0.9, s.at + 1.5, EASE_IO);
          const ul = r(t, s.at + 3.4, s.at + 3.9, EASE_IO);
          return (
            <div key={si} style={{ position: "absolute", left: 100, right: 40, top: 34, fontFamily: BOOK, fontWeight: 500, fontSize: 68, lineHeight: "70px", color: INK,
              opacity: inK * (1 - outK), transform: `translateY(${(1 - inK) * 30 - outK * 40}px)`, filter: `blur(${(1 - inK) * 8 + outK * 8}px)` }}>
              {s.pre}
              <span style={{ position: "relative", whiteSpace: "nowrap" }}>
                <span style={{ position: "absolute", left: -16, right: -16, top: -4, bottom: -8, borderRadius: "50%", border: `3.5px solid ${C.red}`, transform: "rotate(-3deg)",
                  WebkitMaskImage: `conic-gradient(from 200deg, #000 ${circ * 360}deg, transparent ${circ * 360}deg)`, maskImage: `conic-gradient(from 200deg, #000 ${circ * 360}deg, transparent ${circ * 360}deg)` }} />
                {s.circ}
              </span>
              {s.mid}
              <span style={{ position: "relative", whiteSpace: "nowrap" }}>
                <span style={{ position: "absolute", left: -6, right: -6, top: 10, bottom: 2, background: "#FFE14D", transformOrigin: "left", transform: `scaleX(${hl}) skewX(-6deg)`,
                  borderRadius: "4px 10px 6px 12px", mixBlendMode: "multiply" }} />
                <span style={{ position: "relative" }}>{s.hl}</span>
                <span style={{ position: "absolute", left: 0, bottom: -4, height: 5, width: "100%", background: INK, transformOrigin: "left", transform: `scaleX(${ul})`, borderRadius: 3 }} />
              </span>
              {s.post}
            </div>
          );
        })}
      </div>
      <DemoCaption text="Nobody budgets for this part." from={2.5} to={5.8} />
      <DemoCaption text="Ask before you buy." from={8.4} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.25], ...SENTS.flatMap((s) => [[s.at, "swish", 0.2], [s.at + 0.9, "swish", 0.25], [s.at + 2.2, "swish", 0.32], [s.at + 3.4, "tick", 0.2]] as [number, "swish" | "tick", number][]),
        [5.7, "whoosh", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-19  3D flip cards: MYTH cards flip over (in depth, perspective) to FACT one by one, then all three slide
// away and one card flips in with the takeaway.
// =====================================================================================================
const MYTHS = [
  { m: "You need all the cash upfront", f: "Payment plans from 10%", at: 2.0 },
  { m: "Off-plan money just disappears", f: "It sits in escrow", at: 3.8 },
  { m: "Dubai is only for the rich", f: "Studios from AED 600K", at: 5.6 },
];
const FlipCard: React.FC<{ front: React.ReactNode; back: React.ReactNode; flip: number; w: number; h: number; frontBg: string; backBg: string; style?: React.CSSProperties }> =
  ({ front, back, flip, w, h, frontBg, backBg, style }) => {
    const face: React.CSSProperties = { position: "absolute", inset: 0, borderRadius: 30, backfaceVisibility: "hidden", WebkitBackfaceVisibility: "hidden",
      display: "flex", alignItems: "center", padding: "0 40px", boxSizing: "border-box" };
    return (
      <div style={{ width: w, height: h, perspective: 1800, ...style }}>
        <div style={{ position: "relative", width: w, height: h, transformStyle: "preserve-3d", transform: `rotateX(${flip * 180}deg) translateZ(${Math.sin(flip * Math.PI) * 80}px)` }}>
          <div style={{ ...face, background: frontBg }}>{front}</div>
          <div style={{ ...face, background: backBg, transform: "rotateX(180deg)" }}>{back}</div>
        </div>
      </div>
    );
  };
const M419: React.FC = () => {
  const t = useT();
  const away = (i: number) => r(t, 8.0 + i * 0.12, 8.6 + i * 0.12, EASE_IN);
  const fin = r(t, 8.9, 9.8, EASE);
  const tag = (txt: string, bg: string, fg: string) => <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 28, letterSpacing: 2, padding: "6px 14px", borderRadius: 10,
    background: bg, color: fg, marginRight: 24, flexShrink: 0 }}>{txt}</div>;
  return (
    <AbsoluteFill style={{ background: "#10221B" }}>
      <div style={{ position: "absolute", left: 90, top: 300, color: "#fff" }}>
        <div style={{ fontFamily: DISPLAY, fontSize: 150, lineHeight: 1, opacity: r(t, 0.1, 0.5), transform: `translateY(${(1 - r(t, 0.1, 0.5)) * 40}px)` }}>
          MYTH <span style={{ fontFamily: SERIF, fontSize: 110, color: "rgba(255,255,255,0.6)" }}>vs</span> <span style={{ color: C.green }}>FACT</span>
        </div>
        <div style={{ fontFamily: SERIF, fontSize: 60, color: "rgba(255,255,255,0.75)", opacity: r(t, 0.5, 0.9) }}>buying in Dubai</div>
      </div>
      {MYTHS.map((m, i) => {
        const inK = r(t, 0.5 + i * 0.2, 1.0 + i * 0.2, EASE);
        const flip = r(t, m.at, m.at + 0.75, EASE_IO);
        const a = away(i);
        return (
          <div key={i} style={{ position: "absolute", left: 90, top: 640 + i * 250, opacity: inK * (1 - a),
            transform: `translateX(${(1 - inK) * 300 - a * 1200}px) ${float(t, i, 3)}` }}>
            <FlipCard w={900} h={210} flip={flip} frontBg="#1E3A2F" backBg="#F4F1EA"
              front={<>{tag("MYTH", "rgba(255,69,58,0.2)", C.red)}<div style={{ fontFamily: UI, fontWeight: 800, fontSize: 48, color: "#fff", lineHeight: 1.1 }}>{m.m}</div></>}
              back={<>{tag("FACT", C.green, "#08331C")}<div style={{ fontFamily: UI, fontWeight: 900, fontSize: 52, color: INK, lineHeight: 1.1 }}>{m.f}</div></>} />
          </div>
        );
      })}
      {fin > 0 && (
        <div style={{ position: "absolute", left: 90, top: 760 }}>
          <FlipCard w={900} h={420} flip={1 - fin} frontBg={C.green} backBg="#1E3A2F"
            front={<div style={{ width: "100%", textAlign: "center" }}>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 3, color: "#08331C" }}>THE TAKEAWAY</div>
              <div style={{ fontFamily: DISPLAY, fontSize: 130, lineHeight: 1, color: "#08331C" }}>RUN THE</div>
              <div style={{ fontFamily: SERIF, fontSize: 120, lineHeight: 1, color: "#fff" }}>real numbers</div></div>}
            back={<div />} />
        </div>
      )}
      <Sounds list={[[0.1, "impact", 0.3], [0.5, "swish", 0.2], [0.7, "swish", 0.2], [0.9, "swish", 0.2], ...MYTHS.flatMap((m) => [[m.at, "whoosh", 0.3], [m.at + 0.6, "ding", 0.22]] as [number, "whoosh" | "ding", number][]),
        [8.0, "whoosh", 0.35], [8.9, "swish", 0.3], [9.6, "impact", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m4-20  Strike-and-replace word swap on a fitted plate above his head: a thin strike crosses the word, it drops
// away blurred and the replacement rolls up; the plate resizes like liquid to each word.
// =====================================================================================================
const SWAPS = [
  { w: "EXPENSIVE", col: "#fff", at: 0.3, wd: 560 },
  { w: "OVERHYPED", col: "#fff", at: 3.6, wd: 590 },
  { w: "NEGOTIABLE", col: C.gold, at: 6.9, wd: 620 },
];
const M420: React.FC = () => {
  const t = useT();
  const cur = SWAPS.reduce((a, s, i) => (t >= s.at ? i : a), 0);
  const prev = SWAPS[cur - 1];
  const W = (prev ? lerp(prev.wd, SWAPS[cur].wd, r(t, SWAPS[cur].at, SWAPS[cur].at + 0.5, LIQUID)) : SWAPS[0].wd * r(t, 0, 0.45, LIQUID)) + 120;
  const tail = r(t, 8.4, 8.9, LIQUID);
  const H = lerp(250, 330, tail);
  return (
    <AbsoluteFill>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - W / 2, top: 262, width: W, height: H, borderRadius: 34, background: "rgba(20,20,22,0.93)", border: "1.5px solid rgba(255,255,255,0.14)",
        overflow: "hidden", transform: float(t, 9, 2) }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 22, textAlign: "center", fontFamily: SERIF, fontSize: 56, color: "rgba(255,255,255,0.85)", whiteSpace: "nowrap" }}>Dubai property is</div>
        {SWAPS.map((s, i) => {
          const nx = SWAPS[i + 1]?.at;
          const inK = i === 0 ? r(t, 0.3, 0.7, EASE) : r(t, s.at, s.at + 0.45, EASE);
          const strike = nx ? r(t, nx - 1.1, nx - 0.6, EASE_IO) : 0;
          const drop = nx ? r(t, nx - 0.35, nx + 0.15, EASE_IN) : 0;
          if (t < s.at || drop >= 1) return null;
          const id = `m4-20-w${i}`;
          const v = Math.max(1 - inK, drop);
          return (
            <div key={i} style={{ position: "absolute", left: 0, right: 0, top: 94, display: "flex", justifyContent: "center" }}>
              <DirBlur id={id} y={v * 18} />
              <div style={{ position: "relative", fontFamily: DISPLAY, fontSize: 132, lineHeight: 1.05, color: s.col, whiteSpace: "nowrap", letterSpacing: 2,
                transform: `translateY(${(1 - inK) * 120 + drop * 160}px) rotate(${drop * 6}deg)`, opacity: Math.min(1, inK * 2) * (1 - drop) * (1 - strike * 0.45), filter: blurIf(id, v * 18) }}>
                {s.w}
                <div style={{ position: "absolute", left: -10, right: -10, top: "52%", height: 6, borderRadius: 3, background: "#fff", transformOrigin: "left", transform: `scaleX(${strike})` }} />
              </div>
            </div>
          );
        })}
        <div style={{ position: "absolute", left: 0, right: 0, top: 250, textAlign: "center", opacity: tail, fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 2, color: C.gold, whiteSpace: "nowrap" }}>
          {typed("IF YOU KNOW THE NUMBERS", t, 8.6, 0.04)}
        </div>
      </div>
      <DemoCaption text="People say Dubai is expensive." from={0.4} to={3.4} />
      <DemoCaption text="Or overhyped." from={3.7} to={6.7} />
      <DemoCaption text="It's negotiable." from={7.0} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.25], [0.3, "swish", 0.3], ...SWAPS.slice(1).flatMap((s) => [[s.at - 1.1, "swish", 0.28], [s.at - 0.35, "whoosh", 0.3], [s.at, "pop", 0.3]] as [number, "swish" | "whoosh" | "pop", number][]),
        [7.1, "ding", 0.25], [8.6, "type", 0.2]]} />
    </AbsoluteFill>
  );
};

export const M4: LibItem[] = [
  { id: "m4-01", title: "Hero word behind head", family: FAM, dur: 12, C: M401,
    note: "Huge Anton word slams down letter by letter BEHIND his head, rolls to the next word; mono lead-in in front. Hooks / topic reveals." },
  { id: "m4-02", title: "Light-leak scene wipe", family: FAM, dur: 12, C: M402,
    note: "Full-screen colour scenes (Rent / Buy / Rent or Buy?) swapped by a warm light-leak sweep, with counters. Comparisons, A vs B." },
  { id: "m4-03", title: "Motion-blur word whips", family: FAM, dur: 13, C: M403,
    note: "One fitted pill above his head; words whip in/out with directional motion blur, then it grows into a ticked list. Listing factors." },
  { id: "m4-04", title: "Collapse to line, expand", family: FAM, dur: 12.6, C: M404,
    note: "Each colour-block scene squashes into a line that opens into the next (3 things nobody tells you). List videos, cutaways." },
  { id: "m4-06", title: "Colour-block scene wipes", family: FAM, dur: 12, C: M406,
    note: "Bold colour field per beat (title top-left + serif sub) wiping diagonally under one white shape that morphs. Full-screen list cutaways." },
  { id: "m4-07", title: "Split-flap board", family: FAM, dur: 12, C: M407,
    note: "Airport split-flap board above his head flipping from a yields table to the punchline. Stats, myth-busting, reveals." },
  { id: "m4-08", title: "Marquee ribbons behind head", family: FAM, dur: 12, C: M408,
    note: "Two tilted scrolling ribbons pass BEHIND his head, swap text, then a CTA ribbon crosses his chest. Hooks, CTAs, energy moments." },
  { id: "m4-10", title: "Text-mask video reveal", family: FAM, dur: 13, C: M410,
    note: "His video plays inside huge letters on black (DUBAI → 2026), then zooms through the 0 into full video. Openers, year/market intros." },
  { id: "m4-11", title: "Typewriter terminal", family: FAM, dur: 13, C: M411,
    note: "A terminal window above his head types commands, counts AED results and prints a highlighted verdict; grows line by line. Calculations, 'let's run the numbers'." },
  { id: "m4-12", title: "Word ladder", family: FAM, dur: 11, C: M412,
    note: "Cream full-screen ladder: small mono lines and huge Anton words alternate left/right while the camera climbs down. Punchy manifesto lines." },
  { id: "m4-13", title: "Circular text badge", family: FAM, dur: 13, C: M413,
    note: "Gold badge with ring text writing on and turning, centre rolls 60/40 → 2028, then it rolls left and a plate unfolds. Payment plans, key dates." },
  { id: "m4-14", title: "Zoom through the O", family: FAM, dur: 13, C: M414,
    note: "Camera dives through the O of ROI into a blue scene, then through the O of GOAL into his video, landing on choice chips. Scene changes in openers." },
  { id: "m4-15", title: "Ink-blot reveal", family: FAM, dur: 12, C: M415,
    note: "Ink blots spread over cream paper revealing hidden words, an orange blot blooms with the script answer. Quotable rules, mindset lines." },
  { id: "m4-16", title: "Torn-paper reveal", family: FAM, dur: 12, C: M416,
    note: "Cream poster tears across and flies apart to an orange sheet, which tears vertically into his video + a torn paper label. Truth-bomb reveals." },
  { id: "m4-17", title: "Tape label slams", family: FAM, dur: 12, C: M417,
    note: "Bold tape strips slam onto the room above his head with a tiny shake, peel away, last one slams alone. Checklists, warnings, 'save this'." },
  { id: "m4-18", title: "Highlighter swipe", family: FAM, dur: 12, C: M418,
    note: "Lined paper card above his head: a red marker circles one phrase, a yellow highlighter swipes the key numbers, underline. Advice sentences." },
  { id: "m4-19", title: "3D myth/fact flip cards", family: FAM, dur: 12, C: M419,
    note: "Deep-green scene with three MYTH cards that flip over in depth to FACT one by one, then a takeaway card flips in. Myth-busting videos." },
  { id: "m4-20", title: "Strike-and-replace swap", family: FAM, dur: 12, C: M420,
    note: "Fitted plate 'Dubai property is …': thin strike crosses the word, it drops away and the next rolls up (EXPENSIVE → OVERHYPED → NEGOTIABLE). Reframes." },
];
