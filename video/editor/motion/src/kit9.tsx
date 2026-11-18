import React from "react";
import { Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";
import { loadFont as loadHand } from "@remotion/google-fonts/Caveat";
import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";

// Kit 9 "editorial" (Max's favourite reference, @justyn.ai, 2026-10-16): ONE design system for every graphic.
// Cream paper cards with forest-green ink, gold + burgundy accents, a condensed editorial serif for big words,
// mono caps kickers, an italic serif accent word, a handwritten note. Giant serif words sit BEHIND his head
// (rendered in Edit.tsx's behind layer, under the person cut-out). Cards are small, in the top third, and act out
// the sentence (a pen strikes, a counter rolls, a comment types). Springs, not CSS ease. Fixed layouts only.
const { fontFamily: SERIF } = loadSerif("normal", { subsets: ["latin"] });
const { fontFamily: SERIF_I } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });
const { fontFamily: HAND } = loadHand("normal", { weights: ["600", "700"], subsets: ["latin"] });
const { fontFamily: ANTON } = loadAnton();

export const ED = { cream: "#F3EEE4", paper: "#FBF8F2", forest: "#1F4032", gold: "#B08A3E", burg: "#6B2027", ink: "#1E2A24",
  line: "rgba(31,64,50,0.16)", red: "#B3261E" };

type Word = { w: string; s: number; e: number; em?: boolean };
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const r = (t: number, a: number, b: number, e = Easing.bezier(0.22, 1, 0.36, 1)) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
// spring that starts at time `at` (seconds); 0 → 1 with a little overshoot
const useSpring = () => {
  const f = useCurrentFrame(); const { fps } = useVideoConfig();
  return (at: number, damping = 14, stiffness = 140) => spring({ frame: f - Math.round(at * fps), fps, config: { damping, stiffness, mass: 0.8 } });
};
const typed = (text: string, t: number, at: number, cps = 0.04) => Array.from(text).slice(0, Math.max(0, Math.floor((t - at) / cps))).join("");
const kicker: React.CSSProperties = { fontFamily: MONO, fontWeight: 700, letterSpacing: 5, textTransform: "uppercase" };

// ---------------- behind the head ----------------
export type EdBig = { from: number; to: number; at: number; text: string; y: number; size: number; color?: string;
  italic?: boolean; kicker?: { text: string; at: number }[]; count?: { n0: number; n1: number; dur: number }; type?: "letters" | "rise" | "slam"; font?: "serif" | "anton"; stroke?: number; strikeAt?: number };   // anton + stroke = big bold outlined words (Max 2026-10-18)
export const EdBehind: React.FC<{ items: EdBig[] }> = ({ items }) => {
  const t = useT(); const sp = useSpring();
  return <>{items.filter((b) => t >= b.from - 0.05 && t < b.to + 0.4).map((b, i) => {
    const out = r(t, b.to, b.to + 0.3);
    let text = b.text;
    if (b.count) {
      const k = r(t, b.at, b.at + b.count.dur, Easing.bezier(0.16, 1, 0.3, 1));
      text = String(Math.round(b.count.n0 + (b.count.n1 - b.count.n0) * k));
    }
    const letters = Array.from(text);
    const kick = (b.kicker ?? []).filter((k) => t >= k.at - 0.02).map((k) => k.text).join(" ");
    const slam = b.type === "slam" ? sp(b.at, 12, 260) : 1;   // the whole word lands from 2.2x, like a stamp
    return (
      <div key={i} style={{ position: "absolute", left: 0, right: 0, top: b.y, display: "flex", flexDirection: "column", alignItems: "center",
        opacity: (1 - out) * (b.type === "slam" ? Math.min(1, slam * 2) : 1), transform: b.type === "slam" ? `scale(${2.2 - 1.2 * slam}) rotate(-4deg)` : undefined }}>
        {b.kicker && <div style={{ ...kicker, fontSize: 30, color: b.color ?? ED.cream, height: 40, opacity: 0.9, textShadow: "0 2px 12px rgba(0,0,0,0.25)" }}>{kick}</div>}
        <div style={{ display: "flex", fontFamily: b.font === "anton" ? ANTON : b.italic ? SERIF_I : SERIF, fontSize: b.size, lineHeight: b.font === "anton" ? 1.0 : 0.92,
          color: b.color ?? ED.cream, letterSpacing: b.font === "anton" ? 1 : -2, fontVariantNumeric: "tabular-nums",
          ...(b.stroke ? { WebkitTextStroke: `${b.stroke}px #111`, paintOrder: "stroke fill", textShadow: "0 8px 0 rgba(0,0,0,0.22)" } : { textShadow: "0 4px 24px rgba(0,0,0,0.38)" }) }}>
          {letters.map((ch, j) => {
            const k = b.type === "slam" ? 1 : b.type === "rise" || b.count ? sp(b.at, 16) : sp(b.at + j * 0.07, 15);
            return <span key={j} style={{ display: "inline-block", opacity: Math.min(1, k * 1.4), transform: `translateY(${(1 - k) * 60}px)` }}>{ch === " " ? " " : ch}</span>;
          })}
        </div>
        {b.strikeAt !== undefined && t >= b.strikeAt - 0.02 && (() => {   // a thick red strike slams across the word
          const k = sp(b.strikeAt!, 12, 260);
          return <div style={{ position: "absolute", left: "8%", right: "8%", top: (b.kicker ? 40 : 0) + b.size * 0.42, height: b.size * 0.13, borderRadius: b.size * 0.07,
            background: "#FF3B30", border: "6px solid #111", transformOrigin: "0% 50%", transform: `rotate(-6deg) scaleX(${k})` }} />;
        })()}
      </div>
    );
  })}</>;
};

// ---------------- cards (front, top third, never over the face) ----------------
type Row = { text: string; at: number; strikeAt?: number };
export type EdCard = { from: number; to: number; x: number; y: number; w: number; h: number } & (
  | { kind: "strike"; title: string; rows: Row[]; stamp?: { text: string; at: number } }
  | { kind: "either"; left: { icon: string; title: string; at: number }; right: { icon: string; title: string; at: number }; orAt: number }
  | { kind: "angles"; at: number; moveAt: number; labels: [string, string] }
  | { kind: "timer"; at: number; value: string; label: string; crossAt: number }
  | { kind: "comment"; at: number; handle: string; text: string }
  | { kind: "rec"; at: number; talkAt: number }
  | { kind: "follow"; at: number; tapAt: number; name: string; tagline: string }
);
const Paper: React.FC<{ c: EdCard; children: React.ReactNode }> = ({ c, children }) => {
  const t = useT(); const sp = useSpring();
  const k = sp(c.from, 13); const out = r(t, c.to - 0.25, c.to, Easing.bezier(0.55, 0, 1, 0.45));
  return <div style={{ position: "absolute", left: c.x - c.w / 2, top: c.y, width: c.w, height: c.h, borderRadius: 22, background: ED.paper,
    border: `1.5px solid ${ED.line}`, boxShadow: "0 18px 40px rgba(20,30,25,0.28), 0 2px 6px rgba(20,30,25,0.15)", overflow: "hidden",
    opacity: Math.min(1, k * 1.5) * (1 - out), transform: `translateY(${(1 - k) * -30 - out * 20}px) scale(${0.94 + 0.06 * k})`, transformOrigin: "50% 0%" }}>
    {children}</div>;
};
const Pen: React.FC<{ k: number; w: number; y: number; x?: number }> = ({ k, w, y, x = 0 }) => (
  <svg width={w} height={30} style={{ position: "absolute", left: x, top: y - 15, overflow: "visible" }}>
    <path d={`M4 18 C ${w * 0.3} 10, ${w * 0.6} 22, ${w - 4} 12`} fill="none" stroke={ED.red} strokeWidth={6} strokeLinecap="round"
      pathLength={1} strokeDasharray={1} strokeDashoffset={1 - k} />
  </svg>
);
export const EdCards: React.FC<{ cards: EdCard[] }> = ({ cards }) => {
  const t = useT(); const sp = useSpring();
  return <>{cards.filter((c) => t >= c.from - 0.05 && t < c.to + 0.05).map((c, i) => {
    const P = 30;
    switch (c.kind) {
      case "strike": {
        const st = c.stamp ? sp(c.stamp.at, 11, 200) : 0;
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 24, ...kicker, fontSize: 28, color: ED.gold }}>{c.title}</div>
          {c.rows.map((rw, j) => {
            if (t < rw.at - 0.02) return null;
            const a = sp(rw.at, 15); const y = 74 + j * 66;
            const tw = rw.text.length * 17 + 12;
            return <div key={j} style={{ position: "absolute", left: P, top: y, height: 58, display: "flex", alignItems: "center", opacity: Math.min(1, a * 1.5),
              transform: `translateX(${(1 - a) * -24}px)` }}>
              <span style={{ fontFamily: SERIF, fontSize: 48, color: ED.ink, whiteSpace: "nowrap" }}>{rw.text}</span>
              {rw.strikeAt !== undefined && <Pen k={r(t, rw.strikeAt, rw.strikeAt + 0.3)} w={tw} y={31} />}
            </div>;
          })}
          {c.stamp && t >= c.stamp.at - 0.02 && <div style={{ position: "absolute", right: P, bottom: 26, padding: "8px 18px", border: `4px solid ${ED.burg}`, borderRadius: 10,
            ...kicker, fontSize: 30, color: ED.burg, transform: `rotate(-7deg) scale(${1.45 - 0.45 * st})`, opacity: Math.min(1, st * 1.4) }}>{c.stamp.text}</div>}
        </Paper>;
      }
      case "either": {
        const tile = (s: { icon: string; title: string; at: number }, bg: string, x: number) => {
          if (t < s.at - 0.02) return null;
          const a = sp(s.at, 14);
          return <div style={{ position: "absolute", left: x, top: 28, width: (c.w - P * 2 - 110) / 2, height: c.h - 56, borderRadius: 18, background: bg, display: "flex",
            flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10, opacity: Math.min(1, a * 1.5), transform: `scale(${0.85 + 0.15 * a})` }}>
            <span style={{ fontSize: 64 }}>{s.icon}</span>
            <span style={{ fontFamily: SERIF, fontSize: 46, color: ED.cream, textAlign: "center", lineHeight: 1.0, padding: "0 14px" }}>{s.title}</span>
          </div>;
        };
        const tw = (c.w - P * 2 - 110) / 2;
        const o = sp(c.orAt, 14);
        return <Paper key={i} c={c}>
          {tile(c.left, ED.forest, P)}
          {t >= c.orAt - 0.02 && <div style={{ position: "absolute", left: P + tw, width: 110, top: 0, height: c.h, display: "flex", alignItems: "center", justifyContent: "center",
            fontFamily: SERIF_I, fontSize: 52, color: ED.gold, opacity: Math.min(1, o * 1.5) }}>or</div>}
          {tile(c.right, ED.burg, P + tw + 110)}
        </Paper>;
      }
      case "angles": {
        // a top-down "desk" strip: two spots, the phone slides from spot 1 to spot 2 on "other side"
        const m = r(t, c.moveAt, c.moveAt + 0.6, Easing.bezier(0.65, 0, 0.35, 1));
        const x1 = 110, x2 = c.w - 110, y = 120;
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 22, ...kicker, fontSize: 28, color: ED.gold }}>MY CAMERA SETUP</div>
          <svg width={c.w} height={c.h} style={{ position: "absolute", inset: 0 }}>
            <line x1={x1} x2={x2} y1={y} y2={y} stroke={ED.forest} strokeWidth={3} strokeDasharray="10 10" opacity={0.45} />
            {[x1, x2].map((x, j) => <circle key={j} cx={x} cy={y} r={14} fill="none" stroke={ED.forest} strokeWidth={3} opacity={0.5} />)}
          </svg>
          <div style={{ position: "absolute", left: x1 + (x2 - x1) * m - 32, top: y - 46, width: 64, height: 92, borderRadius: 14, background: ED.forest,
            border: `4px solid ${ED.ink}`, boxShadow: "0 8px 18px rgba(0,0,0,0.25)", transform: `rotate(${Math.sin(m * Math.PI) * -8}deg) translateY(${-Math.sin(m * Math.PI) * 18}px)` }}>
            <div style={{ position: "absolute", left: 22, top: 8, width: 12, height: 12, borderRadius: 6, background: ED.gold }} /></div>
          {c.labels.map((lb, j) => <div key={j} style={{ position: "absolute", left: (j ? x2 : x1) - 120, width: 240, top: y + 62, textAlign: "center", fontFamily: SERIF,
            fontSize: 40, color: j === (m > 0.5 ? 1 : 0) ? ED.ink : "rgba(30,42,36,0.35)" }}>{lb}</div>)}
        </Paper>;
      }
      case "timer": {
        const a = sp(c.at, 14), x = sp(c.crossAt, 11, 200);
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 0, height: c.h, display: "flex", alignItems: "center", gap: 22, opacity: Math.min(1, a * 1.5) }}>
            <span style={{ fontSize: 70 }}>⏱️</span>
            <div>
              <div style={{ fontFamily: SERIF, fontSize: 84, color: ED.ink, lineHeight: 0.95 }}>{c.value}</div>
              <div style={{ ...kicker, fontSize: 24, color: ED.gold }}>{c.label}</div>
            </div>
          </div>
          {t >= c.crossAt - 0.02 && <div style={{ position: "absolute", right: P + 10, top: (c.h - 120) / 2, width: 120, height: 120, borderRadius: 60, border: `6px solid ${ED.red}`,
            display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 72, color: ED.red,
            transform: `rotate(-10deg) scale(${2 - x})`, opacity: Math.min(1, x * 1.5) }}>✗</div>}
        </Paper>;
      }
      case "comment": {
        const txt = typed(c.text, t, c.at + 0.25, 0.035);
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 26, display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 58, height: 58, borderRadius: 29, background: ED.burg, color: ED.cream, display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: SERIF, fontSize: 36 }}>{c.handle[1]?.toUpperCase()}</div>
            <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 30, color: ED.ink }}>{c.handle}</div>
            <div style={{ fontFamily: UI, fontWeight: 500, fontSize: 26, color: "rgba(30,42,36,0.5)" }}>just now</div>
          </div>
          <div style={{ position: "absolute", left: P, right: P, top: 104, fontFamily: UI, fontWeight: 500, fontSize: 40, lineHeight: 1.22, color: ED.ink }}>
            {txt}{txt.length < c.text.length && Math.floor(t * 2.5) % 2 === 0 && <span style={{ color: ED.gold }}>|</span>}</div>
        </Paper>;
      }
      case "rec": {
        const a = sp(c.at, 14); const live = t >= c.at + 0.15;
        const secs = Math.max(0, t - c.at);
        const talk = t >= c.talkAt ? sp(c.talkAt, 14) : 0;
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 0, height: c.h, display: "flex", alignItems: "center", gap: 24, opacity: Math.min(1, a * 1.5) }}>
            <div style={{ width: 96, height: 96, borderRadius: 48, border: `5px solid ${ED.ink}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ width: live ? 44 : 70, height: live ? 44 : 70, borderRadius: live ? 10 : 35, background: ED.red }} /></div>
            <div>
              <div style={{ ...kicker, fontSize: 28, color: ED.red }}>● REC</div>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 46, color: ED.ink, fontVariantNumeric: "tabular-nums" }}>
                00:{String(Math.floor(secs)).padStart(2, "0")}</div>
            </div>
          </div>
          {talk > 0 && <div style={{ position: "absolute", right: P, top: (c.h - 70) / 2, height: 70, padding: "0 26px", borderRadius: 35, background: ED.forest, color: ED.cream,
            display: "flex", alignItems: "center", fontFamily: SERIF_I, fontSize: 44, opacity: Math.min(1, talk * 1.5), transform: `scale(${0.8 + 0.2 * talk})` }}>just talks</div>}
        </Paper>;
      }
      case "follow": {
        const on = t >= c.tapAt; const tp = sp(c.tapAt, 12, 220);
        return <Paper key={i} c={c}>
          <div style={{ position: "absolute", left: P, top: 0, height: c.h, display: "flex", alignItems: "center", gap: 20 }}>
            <div style={{ width: 92, height: 92, borderRadius: 46, background: ED.forest, color: ED.cream, display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: SERIF, fontSize: 60 }}>M</div>
            <div>
              <div style={{ fontFamily: SERIF, fontSize: 54, color: ED.ink, lineHeight: 1 }}>{c.name}</div>
              <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 28, color: "rgba(30,42,36,0.6)", marginTop: 6 }}>{c.tagline}</div>
            </div>
          </div>
          <div style={{ position: "absolute", right: P, top: (c.h - 76) / 2, width: 250, height: 76, borderRadius: 38, background: on ? ED.gold : ED.forest, color: ED.cream,
            display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 32,
            transform: `scale(${on ? 1 + (1 - tp) * 0.12 : 1})` }}>{on ? "Following ✓" : "Follow"}</div>
        </Paper>;
      }
    }
    return null;
  })}</>;
};

// ---------------- colour-bar wipe (section transition) ----------------
export const EdWipe: React.FC<{ at: number[] }> = ({ at }) => {
  const t = useT();
  const w = at.find((a) => t >= a - 0.05 && t < a + 0.6);
  if (w === undefined) return null;
  const cols = [ED.forest, ED.gold, ED.burg];
  return <>{cols.map((c, i) => {
    const k = r(t, w + i * 0.05, w + 0.45 + i * 0.05, Easing.bezier(0.65, 0, 0.35, 1));
    return <div key={i} style={{ position: "absolute", top: 0, height: 1920, width: 260, left: -280 + k * 1660, background: c }} />;
  })}</>;
};

// ---------------- captions: serif words on a forest-green bar ----------------
// The bar is sized for the WHOLE line from the start (unsaid words are laid out but invisible), so nothing jitters
// and no faint preview words show (Max's rule). Key words are gold italic. Low on the chest (bottom ≈ 1630).
export type EdLine = { from: number; to: number; words: Word[] };
export const EdCaptions: React.FC<{ lines: EdLine[]; bottom: number; size?: number }> = ({ lines, bottom, size = 56 }) => {
  const t = useT(); const sp = useSpring();
  const l = lines.find((x) => t >= x.from && t < x.to);
  if (!l) return null;
  const k = sp(l.from, 16, 220);
  // the bar is laid out for the whole line (fixed position: text never moves) but clipped so it only covers the words
  // said so far, growing to the right with each new word. Unsaid words are invisible (no faint preview).
  const len = (w: Word) => w.w.length + 1;
  const total = l.words.reduce((a, w) => a + len(w), 0);
  const shown = l.words.reduce((a, w) => a + len(w) * r(t, w.s - 0.05, w.s + 0.1), 0);
  const frac = Math.min(1, Math.max(len(l.words[0]) / total, shown / total));
  return <div style={{ position: "absolute", left: 0, right: 0, bottom: 1920 - bottom, display: "flex", justifyContent: "center" }}>
    <div style={{ display: "flex", gap: 14, alignItems: "baseline", padding: "6px 22px 10px", background: ED.forest, borderRadius: 8, maxWidth: 820,
      boxShadow: "0 8px 22px rgba(0,0,0,0.25)", opacity: Math.min(1, k * 1.6), transform: `translateY(${(1 - k) * 14}px)`,
      clipPath: `inset(0 ${(1 - frac) * 100}% 0 0 round 8px)` }}>
      {l.words.map((w, i) => {
        const said = t >= w.s - 0.03; const a = r(t, w.s - 0.03, w.s + 0.12);
        return <span key={i} style={{ fontFamily: w.em ? SERIF_I : SERIF, fontSize: w.em ? size * 1.1 : size, color: w.em ? "#E9C77B" : ED.cream,
          lineHeight: 1.1, whiteSpace: "nowrap", opacity: said ? a : 0, transform: `translateY(${(1 - a) * 8}px)`, display: "inline-block" }}>{w.w}</span>;
      })}
    </div>
  </div>;
};

export type EdDef = { behind: EdBig[]; bigFront?: boolean; cards: EdCard[]; wipes: number[]; caps: { lines: EdLine[]; bottom: number; size?: number } };
export { HAND };
