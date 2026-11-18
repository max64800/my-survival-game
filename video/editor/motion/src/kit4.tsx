import React from "react";
import { AbsoluteFill, Easing, Img, OffthreadVideo, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";

// Kit 4: frosted-glass cards that hand off into each other + a liquid "pour" transition that carries one shot
// into the next. Built for the coffee video; reusable. Rendered at 60 fps for smooth motion (composition "Edit60").
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "700", "800", "900"], subsets: ["latin"] });
const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });

const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const POP = Easing.bezier(0.3, 1.5, 0.5, 1);
const CARAMEL = "#D8913F";
const CREAM = "#F6EADB";
const ESPRESSO = "#2A1810";
const RED = "#FF5A4E";
const GREEN = "#43D17A";

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const r = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const float = (t: number, seed: number, amp = 6) => `translate(${Math.sin(t * 1.2 + seed) * amp * 0.6}px, ${Math.sin(t * 1.6 + seed * 2) * amp}px)`;

// espresso-tinted frosted glass: reads on bright walls and dark rooms alike
const glass: React.CSSProperties = {
  background: "rgba(34,20,12,0.48)", backdropFilter: "blur(22px) saturate(140%)", WebkitBackdropFilter: "blur(22px) saturate(140%)",
  border: "1.5px solid rgba(255,235,210,0.28)", borderRadius: 30, color: "#fff", fontFamily: UI,
  boxShadow: "0 24px 50px rgba(0,0,0,0.35)",
};

type Base = { from: number; to: number };
export type K4 =
  | (Base & { type: "age"; x: number; y: number; label: string; n0: number; n1: number; at: number; dur: number; tag?: string; tagAt?: number })
  | (Base & { type: "eq"; y: number; items: { text: string; at: number; strikeAt?: number; swap?: { text: string; at: number } }[]; result?: { text: string; at: number } })
  | (Base & { type: "cafes"; x: number; y: number; at: number; n: number; label: string; whipAt: number; collapseAt: number })
  | (Base & { type: "ticket"; x: number; y: number; lines: { text: string; at: number; big?: boolean }[] })
  | (Base & { type: "review"; x: number; y: number; quote: string; author: string; flickAt: number })
  | (Base & { type: "strikes"; y: number; items: { text: string; at: number; strikeAt: number }[] })
  | (Base & { type: "mood"; y: number; left: string; right: string; at: number })
  | (Base & { type: "pour"; at: number; dir?: number });
export const K4_TOP = ["pour"];

// ---------- liquid pour: caramel + cream waves fall over the cut and drain away, carrying the shot change ----------
const Pour: React.FC<{ e: Extract<K4, { type: "pour" }> }> = ({ e }) => {
  const t = useT();
  const a = e.at - 0.36, b = e.at + 0.42;
  if (t < a || t > b) return null;
  const cover = r(t, a, e.at, EASE_IN);           // front edge falls from the top past the bottom
  const drain = r(t, e.at + 0.02, b, EASE);        // back edge follows it down and off
  const wave = (base: number, amp: number, ph: number, top: boolean) => {
    const pts: string[] = [];
    for (let x = -20; x <= 1100; x += 40) pts.push(`${x},${base + Math.sin(x / 140 + ph + t * 9) * amp}`);
    return top ? `M -20,-40 L ${pts.join(" L ")} L 1100,-40 Z` : `M -20,2000 L ${pts.join(" L ")} L 1100,2000 Z`;
  };
  const front = lerp(-120, 2100, cover), back = lerp(-120, 2100, drain);
  const layer = (color: string, lag: number, amp: number, ph: number) => {
    const f = lerp(-120, 2100, r(t, a + lag, e.at + lag, EASE_IN)), bk = lerp(-120, 2100, r(t, e.at + 0.02 + lag, b + lag));
    return <path d={`${wave(f, amp, ph, true)}`} fill={color} style={{ clipPath: `inset(${Math.max(0, bk)}px 0 0 0)` }} />;
  };
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
        {layer(CREAM, 0.05, 34, 1.3)}
        {layer(CARAMEL, 0, 46, 0)}
        {back > -100 && front > back && <path d={wave(back, 40, 2.1, false)} fill="transparent" />}
      </svg>
    </AbsoluteFill>
  );
};

const digitPos = (v: number, d: number) => {
  const p = Math.pow(10, d);
  const base = Math.floor(v / p) % 10;
  if (d === 0) return base + (v - Math.floor(v));
  return base + Math.max(0, (v % p) - (p - 1));
};

const Odo: React.FC<{ value: number; size: number }> = ({ value, size }) => {
  // real odometer: a digit only moves while every digit below it is rolling over (no half-shown digits at rest)
  const digits = String(Math.max(0, Math.round(value))).length;
  const cols: number[] = [];
  for (let d = digits - 1; d >= 0; d--) cols.push(digitPos(value, d));
  return (
    <div style={{ display: "flex", height: size * 1.05, overflow: "hidden" }}>
      {cols.map((v, i) => (
        <div key={i} style={{ height: size * 1.05, overflow: "hidden" }}>
          <div style={{ transform: `translateY(${-v * size * 1.05}px)` }}>
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
              <div key={j} style={{ height: size * 1.05, fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: UI, fontWeight: 900 }}>{n}</div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};

const Age: React.FC<{ e: Extract<K4, { type: "age" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = r(t, e.from, e.from + 0.4, POP);
  const out = r(t, e.to - 0.25, e.to, EASE_IN);
  const p = r(t, e.at, e.at + e.dur, EASE_IO);
  const tagK = e.tagAt ? r(t, e.tagAt, e.tagAt + 0.3, POP) : 0;
  return (
    <div style={{ position: "absolute", left: e.x, top: e.y, transform: `translate(-50%,0) scale(${k * (1 - out * 0.4)}) ${float(t, 1, 4)}`, opacity: 1 - out }}>
      <div style={{ ...glass, padding: "18px 30px", display: "flex", alignItems: "center", gap: 22 }}>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, opacity: 0.8, width: 150, lineHeight: 1.15 }}>{e.label}</div>
        <div style={{ color: CARAMEL }}><Odo value={lerp(e.n0, e.n1, p)} size={110} /></div>
        {e.tag && tagK > 0 && <div style={{ background: GREEN, color: ESPRESSO, fontWeight: 900, fontSize: 34, padding: "8px 16px", borderRadius: 16,
          transform: `scale(${tagK}) rotate(-4deg)` }}>{e.tag}</div>}
      </div>
    </div>
  );
};

// a row of chips where each new chip slides out from behind the previous one (hand-off, never popping from nowhere)
const Eq: React.FC<{ e: Extract<K4, { type: "eq" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const out = r(t, e.to - 0.3, e.to, EASE_IN);
  const shown = e.items.filter((it) => t >= it.at);
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: e.y, display: "flex", justifyContent: "center", alignItems: "center", gap: 12,
      flexWrap: "wrap", opacity: 1 - out, transform: `translateY(${-out * 40}px)` }}>
      {shown.map((it, i) => {
        const a = r(t, it.at, it.at + 0.35, EASE);
        const sw = it.swap ? r(t, it.swap.at, it.swap.at + 0.3, EASE_IO) : 0;
        const s = it.strikeAt !== undefined ? r(t, it.strikeAt, it.strikeAt + 0.25, EASE_IO) * (1 - sw) : 0;
        return (
          <React.Fragment key={i}>
            {i > 0 && <div style={{ color: "#fff", fontWeight: 900, fontSize: 52, opacity: a, textShadow: "0 3px 12px rgba(0,0,0,0.5)" }}>+</div>}
            <div style={{ ...glass, position: "relative", padding: "14px 24px", fontWeight: 800, fontSize: 44, opacity: Math.min(1, a * 1.4),
              transform: `translateX(${(1 - a) * -90}px) scale(${0.85 + 0.15 * a})`, overflow: "hidden" }}>
              <span style={{ display: "inline-block", opacity: 1 - sw, transform: `translateY(${-sw * 40}px)` }}>{it.text}</span>
              {it.swap && sw > 0 && <span style={{ position: "absolute", left: 24, top: 14, opacity: sw, transform: `translateY(${(1 - sw) * 40}px)`, color: CREAM }}>{it.swap.text}</span>}
              {s > 0 && <div style={{ position: "absolute", left: 14, right: 14, top: "50%", height: 3, borderRadius: 2, background: "rgba(255,255,255,0.92)", boxShadow: "0 0 6px rgba(255,255,255,0.6)", transformOrigin: "left", transform: `scaleX(${s})` }} />}
            </div>
          </React.Fragment>
        );
      })}
      {e.result && t >= e.result.at && (
        <>
          <div style={{ color: "#fff", fontWeight: 900, fontSize: 52, textShadow: "0 3px 12px rgba(0,0,0,0.5)" }}>=</div>
          <div style={{ background: CARAMEL, color: ESPRESSO, borderRadius: 30, padding: "12px 24px", fontFamily: UI, fontWeight: 900, fontSize: 48,
            transform: `scale(${r(t, e.result.at, e.result.at + 0.35, POP)})`, boxShadow: `0 0 40px rgba(216,145,63,0.7)` }}>{e.result.text}</div>
        </>
      )}
    </div>
  );
};

// a grid of café tiles fills up (every single corner), whips past as he walks past, and collapses into one caramel dot
const Cafes: React.FC<{ e: Extract<K4, { type: "cafes" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const cols = 6, rows = Math.ceil(e.n / cols), S = 74, G = 12;
  const W = cols * S + (cols - 1) * G, H = rows * S + (rows - 1) * G;
  const whip = r(t, e.whipAt, e.whipAt + 0.45, EASE_IN);
  const col = r(t, e.collapseAt, e.collapseAt + 0.4, EASE_IO);
  const count = Math.min(e.n, Math.floor(Math.max(0, t - e.at) / 0.05));
  const lab = r(t, e.from, e.from + 0.35, POP);
  return (
    <div style={{ position: "absolute", left: e.x - W / 2 - 28, top: e.y, width: W + 56 }}>
      <div style={{ ...glass, padding: 28, transform: `scale(${lab}) translateX(${-whip * 1400}px)`, filter: whip > 0.02 ? `blur(${whip * 10}px)` : undefined,
        opacity: 1 - col }}>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 3, opacity: 0.8, marginBottom: 14 }}>{e.label}  {count}{count >= e.n ? "+" : ""}</div>
        <div style={{ position: "relative", width: W, height: H }}>
          {Array.from({ length: e.n }, (_, i) => {
            const a = r(t, e.at + i * 0.05, e.at + i * 0.05 + 0.2, POP);
            const x = (i % cols) * (S + G), y = Math.floor(i / cols) * (S + G);
            return <div key={i} style={{ position: "absolute", left: x, top: y, width: S, height: S, borderRadius: 18, background: "rgba(255,235,210,0.14)",
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 42, transform: `scale(${a})` }}>☕</div>;
          })}
        </div>
      </div>
    </div>
  );
};

// a cream order ticket "prints" downward, lines typing in
const Ticket: React.FC<{ e: Extract<K4, { type: "ticket" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = r(t, e.from, e.from + 0.35, POP);
  const out = r(t, e.to - 0.3, e.to, EASE_IN);
  const printed = e.lines.filter((l) => t >= l.at).length;
  return (
    <div style={{ position: "absolute", left: e.x - 230, top: e.y, width: 460, transform: `scale(${k}) rotate(${-3 + Math.sin(t * 1.4) * 0.8}deg) translateY(${-out * 60}px)`,
      opacity: 1 - out, transformOrigin: "50% 0%" }}>
      <div style={{ background: CREAM, color: ESPRESSO, fontFamily: MONO, borderRadius: "18px 18px 6px 6px", padding: "24px 30px 30px",
        boxShadow: "0 24px 50px rgba(0,0,0,0.35)", overflow: "hidden", maxHeight: 90 + printed * 64, transition: "none",
        WebkitMaskImage: "linear-gradient(180deg, black 92%, transparent)" }}>
        {e.lines.map((l, i) => {
          if (t < l.at) return null;
          const n = Math.floor((t - l.at) / 0.03);
          return <div key={i} style={{ fontWeight: l.big ? 700 : 500, fontSize: l.big ? 38 : 30, lineHeight: 1.6, whiteSpace: "nowrap",
            color: l.big ? ESPRESSO : "#5A3B28" }}>{Array.from(l.text).slice(0, n).join("")}</div>;
        })}
      </div>
    </div>
  );
};

// a snobby 1-star review card, flicked off screen on "I don't care"
const Review: React.FC<{ e: Extract<K4, { type: "review" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = r(t, e.from, e.from + 0.4, POP);
  const fl = r(t, e.flickAt, e.flickAt + 0.4, EASE_IN);
  return (
    <div style={{ position: "absolute", left: e.x - 330, top: e.y, width: 660, transform: `translate(${fl * 1300}px, ${-fl * 260}px) rotate(${-2 + fl * 38}deg) scale(${k})`,
      filter: fl > 0.05 ? `blur(${fl * 8}px)` : undefined }}>
      <div style={{ ...glass, background: "rgba(250,246,240,0.92)", color: ESPRESSO, padding: "26px 34px" }}>
        <div style={{ fontSize: 44, letterSpacing: 4, color: "#E0A030" }}>★<span style={{ color: "#C9BFB2" }}>★★★★</span></div>
        <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 68, lineHeight: 1.05, marginTop: 6 }}>“{e.quote}”</div>
        <div style={{ fontFamily: MONO, fontSize: 26, marginTop: 10, opacity: 0.7 }}>{e.author}</div>
      </div>
    </div>
  );
};

const Strikes: React.FC<{ e: Extract<K4, { type: "strikes" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const out = r(t, e.to - 0.25, e.to, EASE_IN);
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: e.y, display: "flex", justifyContent: "center", gap: 16, opacity: 1 - out }}>
      {e.items.map((it, i) => {
        if (t < it.at) return null;
        const a = r(t, it.at, it.at + 0.3, POP);
        const s = r(t, it.strikeAt, it.strikeAt + 0.25, EASE_IO);
        return (
          <div key={i} style={{ ...glass, position: "relative", padding: "14px 26px", fontWeight: 800, fontSize: 44, transform: `scale(${a}) ${float(t, i, 3)}` }}>
            {it.text}
            <div style={{ position: "absolute", left: 14, right: 14, top: "50%", height: 3, borderRadius: 2, background: "rgba(255,255,255,0.92)", boxShadow: "0 0 6px rgba(255,255,255,0.6)", transformOrigin: "left", transform: `scaleX(${s})` }} />
          </div>
        );
      })}
    </div>
  );
};

// sad <-> happy toggle: the knob slides to the caramel side
const Mood: React.FC<{ e: Extract<K4, { type: "mood" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = r(t, e.from, e.from + 0.4, POP);
  const out = r(t, e.to - 0.25, e.to, EASE_IN);
  const s = r(t, e.at, e.at + 0.45, Easing.bezier(0.3, 1.3, 0.5, 1));
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: e.y, display: "flex", justifyContent: "center", opacity: 1 - out, transform: `scale(${k})` }}>
      <div style={{ ...glass, padding: 14, display: "flex", position: "relative", borderRadius: 60, width: 760 }}>
        <div style={{ position: "absolute", top: 14, left: 14 + s * 366, width: 366, height: 96, borderRadius: 50,
          background: s > 0.5 ? CARAMEL : "rgba(255,255,255,0.22)", boxShadow: s > 0.5 ? `0 0 40px rgba(216,145,63,0.8)` : "none" }} />
        {[e.left, e.right].map((lbl, i) => (
          <div key={i} style={{ position: "relative", width: 366, height: 96, display: "flex", alignItems: "center", justifyContent: "center",
            fontWeight: 900, fontSize: 42, color: i === 1 && s > 0.5 ? ESPRESSO : "#fff", opacity: i === 0 ? 1 - s * 0.5 : 0.6 + s * 0.4 }}>{lbl}</div>
        ))}
      </div>
    </div>
  );
};

export const renderK4 = (e: K4, i: number) => {
  switch (e.type) {
    case "age": return <Age key={`k4${i}`} e={e} />;
    case "eq": return <Eq key={`k4${i}`} e={e} />;
    case "cafes": return <Cafes key={`k4${i}`} e={e} />;
    case "ticket": return <Ticket key={`k4${i}`} e={e} />;
    case "review": return <Review key={`k4${i}`} e={e} />;
    case "strikes": return <Strikes key={`k4${i}`} e={e} />;
    case "mood": return <Mood key={`k4${i}`} e={e} />;
    case "pour": return <Pour key={`k4${i}`} e={e} />;
    default: return null;
  }
};

// ---------- Morph: ONE card that changes shape and content from beat to beat ("magic move") ----------
// Every beat is born from the previous one: the container's position, size, corner radius and colour glide to
// the next state while the old content fades out and the new content fades in inside it.
export type MorphContent =
  | { kind: "age"; label: string; n0: number; n1: number; at: number; dur: number; tag?: string; tagAt?: number }
  | { kind: "pill"; text: string; strikeAt?: number }
  | { kind: "eq"; items: { text: string; at: number }[]; result?: { text: string; at: number } }
  | { kind: "cafes"; label: string; n: number; at: number; whipAt: number }
  | { kind: "dot" }
  | { kind: "ticket"; lines: { text: string; at: number; big?: boolean }[] }
  | { kind: "review"; quote: string; author: string }
  | { kind: "line" }
  | { kind: "strikes"; items: { text: string; at: number; strikeAt: number }[] }
  | { kind: "mood"; left: string; right: string; at: number }
  | { kind: "tools"; items: { text: string; emoji: string; at: number }[] }
  | { kind: "team"; label: string; toxicAt: number; spreadAt: number; fireAt?: number };
export type MorphState = { at: number; x: number; y: number; w: number; h: number; radius?: number; bg?: string; rotY?: number; content: MorphContent };
export type MorphDef = { from: number; to: number; states: MorphState[]; punch?: boolean };   // punch: livelier hand-offs (overshoot, tilt, blur, glint)

const MorphInner: React.FC<{ c: MorphContent; t: number; w: number; h: number }> = ({ c, t, w, h }) => {
  switch (c.kind) {
    case "age": {
      const p = r(t, c.at, c.at + c.dur, EASE_IO);
      const tagK = c.tagAt ? r(t, c.tagAt, c.tagAt + 0.3, POP) : 0;
      return (
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 22, height: "100%" }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, letterSpacing: 3, opacity: 0.85, width: 150, lineHeight: 1.15 }}>{c.label}</div>
          <div style={{ color: CARAMEL }}><Odo value={lerp(c.n0, c.n1, p)} size={104} /></div>
          {c.tag && tagK > 0 && <div style={{ background: GREEN, color: ESPRESSO, fontWeight: 900, fontSize: 32, padding: "8px 14px", borderRadius: 14,
            transform: `scale(${tagK}) rotate(-4deg)` }}>{c.tag}</div>}
        </div>
      );
    }
    case "pill": {
      const s = c.strikeAt !== undefined ? r(t, c.strikeAt, c.strikeAt + 0.25, EASE_IO) : 0;
      return (
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", fontWeight: 900, fontSize: 52, position: "relative" }}>
          <span style={{ opacity: 1 - 0.55 * s, transform: `scale(${1 - 0.05 * s})`, display: "inline-block" }}>{c.text}</span>
          <div style={{ position: "absolute", left: 26, right: 26, top: "50%", height: 3, borderRadius: 2, background: "rgba(255,255,255,0.92)", boxShadow: "0 0 6px rgba(255,255,255,0.6)", transformOrigin: "left", transform: `scaleX(${s})` }} />
        </div>
      );
    }
    case "eq":
      return (
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 10, height: "100%" }}>
          {c.items.map((it, i) => {
            const a = r(t, it.at, it.at + 0.3, EASE);
            return (
              <React.Fragment key={i}>
                {i > 0 && <span style={{ fontWeight: 900, fontSize: 46, opacity: a }}>+</span>}
                <span style={{ fontWeight: 800, fontSize: 42, opacity: a, transform: `translateX(${(1 - a) * -40}px)`, display: "inline-block",
                  background: "rgba(255,235,210,0.14)", borderRadius: 18, padding: "8px 16px" }}>{it.text}</span>
              </React.Fragment>
            );
          })}
          {c.result && t >= c.result.at && (
            <>
              <span style={{ fontWeight: 900, fontSize: 46 }}>=</span>
              <span style={{ background: CARAMEL, color: ESPRESSO, borderRadius: 18, padding: "8px 16px", fontWeight: 900, fontSize: 44,
                transform: `scale(${r(t, c.result.at, c.result.at + 0.3, POP)})`, display: "inline-block" }}>{c.result.text}</span>
            </>
          )}
        </div>
      );
    case "cafes": {
      const cols = 6, S = 66, G = 10;
      const whip = r(t, c.whipAt, c.whipAt + 0.4, EASE_IN);
      const count = Math.min(c.n, Math.floor(Math.max(0, t - c.at) / 0.045));
      return (
        <div style={{ padding: 24, transform: `translateX(${-whip * 900}px)`, filter: whip > 0.02 ? `blur(${whip * 8}px)` : undefined }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 3, opacity: 0.85, marginBottom: 12 }}>{c.label}  {count}{count >= c.n ? "+" : ""}</div>
          <div style={{ position: "relative" }}>
            {Array.from({ length: c.n }, (_, i) => {
              const a = r(t, c.at + i * 0.045, c.at + i * 0.045 + 0.2, POP);
              return <div key={i} style={{ position: "absolute", left: (i % cols) * (S + G), top: Math.floor(i / cols) * (S + G), width: S, height: S, borderRadius: 16,
                background: "rgba(255,235,210,0.14)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 38, transform: `scale(${a})` }}>☕</div>;
            })}
          </div>
        </div>
      );
    }
    case "ticket":
      return (
        <div style={{ padding: "22px 28px", fontFamily: MONO, color: ESPRESSO }}>
          {c.lines.map((l, i) => {
            if (t < l.at) return null;
            const n = Math.floor((t - l.at) / 0.03);
            return <div key={i} style={{ fontWeight: l.big ? 700 : 500, fontSize: l.big ? 36 : 28, lineHeight: 1.55, whiteSpace: "nowrap", color: l.big ? ESPRESSO : "#5A3B28" }}>
              {Array.from(l.text).slice(0, n).join("")}</div>;
          })}
        </div>
      );
    case "review":
      return (
        <div style={{ padding: "22px 30px", color: ESPRESSO }}>
          <div style={{ fontSize: 42, letterSpacing: 4, color: "#E0A030" }}>★<span style={{ color: "#C9BFB2" }}>★★★★</span></div>
          <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 64, lineHeight: 1.05, marginTop: 4 }}>“{c.quote}”</div>
          <div style={{ fontFamily: MONO, fontSize: 24, marginTop: 8, opacity: 0.7 }}>{c.author}</div>
        </div>
      );
    case "strikes":
      return (
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 14, height: "100%" }}>
          {c.items.map((it, i) => {
            if (t < it.at) return null;
            const a = r(t, it.at, it.at + 0.3, POP);
            const s = r(t, it.strikeAt, it.strikeAt + 0.25, EASE_IO);
            return (
              <div key={i} style={{ position: "relative", padding: "8px 18px", borderRadius: 18, background: "rgba(255,235,210,0.14)", fontWeight: 800, fontSize: 42,
                transform: `scale(${a * (1 - 0.05 * s)})` }}>
                <span style={{ opacity: 1 - 0.55 * s }}>{it.text}</span>
                <div style={{ position: "absolute", left: 10, right: 10, top: "50%", height: 3, borderRadius: 2, background: "rgba(255,255,255,0.92)", boxShadow: "0 0 6px rgba(255,255,255,0.6)", transformOrigin: "left", transform: `scaleX(${s})` }} />
              </div>
            );
          })}
        </div>
      );
    case "mood": {
      const s = r(t, c.at, c.at + 0.45, Easing.bezier(0.3, 1.3, 0.5, 1));
      const half = (w - 28) / 2;
      return (
        <div style={{ position: "relative", height: "100%", padding: 14, boxSizing: "border-box" }}>
          <div style={{ position: "absolute", top: 14, left: 14 + s * half, width: half, height: h - 28, borderRadius: 60,
            background: s > 0.5 ? CARAMEL : "rgba(255,255,255,0.2)", boxShadow: s > 0.5 ? `0 0 40px rgba(216,145,63,0.8)` : "none" }} />
          <div style={{ position: "relative", display: "flex", height: "100%" }}>
            {[c.left, c.right].map((lbl, i) => (
              <div key={i} style={{ width: half, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 40,
                color: i === 1 && s > 0.5 ? ESPRESSO : "#fff", opacity: i === 0 ? 1 - s * 0.5 : 0.6 + s * 0.4 }}>{lbl}</div>
            ))}
          </div>
        </div>
      );
    }
    case "team": {
      // 12 teammates; one turns toxic, the bad mood spreads to its neighbours; optionally the toxic one is removed
      const cols = 6, toxic = 8;
      const fire = c.fireAt !== undefined ? r(t, c.fireAt, c.fireAt + 0.45, EASE_IN) : 0;
      const heal = c.fireAt !== undefined ? r(t, c.fireAt + 0.35, c.fireAt + 0.8) : 0;
      return (
        <div style={{ padding: "16px 22px", height: "100%", boxSizing: "border-box" }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 20, letterSpacing: 3, opacity: 0.85, marginBottom: 8 }}>{c.label}</div>
          <div style={{ display: "grid", gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 8 }}>
            {Array.from({ length: 12 }, (_, i) => {
              const dx = Math.abs((i % cols) - (toxic % cols)), dy = Math.abs(Math.floor(i / cols) - Math.floor(toxic / cols));
              const dist = dx + dy;
              const isTox = i === toxic;
              const bad = isTox ? r(t, c.toxicAt, c.toxicAt + 0.25) : r(t, c.spreadAt + dist * 0.16, c.spreadAt + dist * 0.16 + 0.25);
              const b2 = isTox ? bad : bad * (1 - heal);
              const face = isTox ? (bad > 0.5 ? "😠" : "🙂") : (b2 > 0.5 ? "😟" : "🙂");
              const out = isTox ? fire : 0;
              return (
                <div key={i} style={{ height: 46, borderRadius: 23, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26,
                  background: isTox ? `rgba(255,90,78,${0.15 + 0.6 * bad})` : `rgba(${Math.round(255 * b2 + 255 * (1 - b2) * 0.3)},${Math.round(140 * b2 + 230 * (1 - b2) * 0.3)},80,${0.14 + 0.35 * b2})`,
                  transform: `translateY(${out * -120}px) scale(${1 - out * 0.4})`, opacity: 1 - out }}>{face}</div>
              );
            })}
          </div>
        </div>
      );
    }
    case "tools":
      return (
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, padding: 20, height: "100%", boxSizing: "border-box", alignContent: "center" }}>
          {c.items.map((it, i) => {
            const a = r(t, it.at, it.at + 0.3, POP);
            return (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 16px", borderRadius: 18, background: "rgba(255,255,255,0.12)",
                fontWeight: 800, fontSize: 34, opacity: t >= it.at ? 1 : 0.15, transform: `scale(${t >= it.at ? 0.85 + 0.15 * a : 0.9})` }}>
                <span style={{ fontSize: 38 }}>{it.emoji}</span>{it.text}
              </div>
            );
          })}
        </div>
      );
    default:
      return null;
  }
};

export const Morph: React.FC<{ m: MorphDef }> = ({ m }) => {
  const t = useT();
  if (t < m.from || t > m.to) return null;
  let i = 0;
  while (i + 1 < m.states.length && m.states[i + 1].at <= t) i++;
  const cur = m.states[i];
  const prev = m.states[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.5, EASE_IO);              // shape glide
  const outK = i === 0 ? 1 : r(t, cur.at, cur.at + 0.18, EASE_IN);          // old content leaves fast
  const inK = i === 0 ? r(t, m.from, m.from + 0.35) : r(t, cur.at + 0.2, cur.at + 0.5, EASE);
  const enter = r(t, m.from, m.from + 0.45, POP);
  const exit = r(t, m.to - 0.3, m.to, EASE_IN);
  // "punch" hand-offs (+20%): size overshoots and settles, the card tilts and squashes in flight,
  // motion-blurs at peak speed, and a light glint sweeps across it as the new state lands
  const kS = m.punch && i > 0 ? interpolate(t, [cur.at, cur.at + 0.55], [0, 1], { easing: Easing.bezier(0.34, 1.45, 0.64, 1), extrapolateLeft: "clamp", extrapolateRight: "clamp" }) : k;
  const flight = m.punch && i > 0 ? Math.sin(Math.PI * Math.min(1, Math.max(0, (t - cur.at) / 0.5))) : 0;
  const tilt = flight * 4 * (i % 2 ? 1 : -1);
  const glint = m.punch && i > 0 ? r(t, cur.at + 0.15, cur.at + 0.75, EASE_IO) : 0;
  const x = lerp(prev.x, cur.x, k), y = lerp(prev.y, cur.y, k), w = lerp(prev.w, cur.w, kS), h = lerp(prev.h, cur.h, kS);
  const rad = lerp(prev.radius ?? 30, cur.radius ?? 30, k);
  const rotY = lerp(prev.rotY ?? 0, cur.rotY ?? 0, k);
  const bgA = prev.bg ?? "rgba(34,20,12,0.5)", bgB = cur.bg ?? "rgba(34,20,12,0.5)";
  return (
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, perspective: 1400,
      transform: `scale(${enter * (1 - exit * 0.5)}) ${float(t, 2, 5)} rotate(${tilt}deg) scale(${1 + flight * 0.04}, ${1 - flight * 0.05})`, opacity: 1 - exit }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: rad, overflow: "hidden", transform: `rotateY(${rotY}deg)`,
        backdropFilter: "blur(22px) saturate(140%)", WebkitBackdropFilter: "blur(22px) saturate(140%)",
        boxShadow: "0 24px 50px rgba(0,0,0,0.35)", border: "1.5px solid rgba(255,235,210,0.28)", color: "#fff", fontFamily: UI }}>
        <div style={{ position: "absolute", inset: 0, background: bgA, opacity: 1 - k }} />
        <div style={{ position: "absolute", inset: 0, background: bgB, opacity: k }} />
        {i > 0 && outK < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - outK, transform: `scale(${1 - outK * 0.1})` }}>
          <MorphInner c={prev.content} t={t} w={w} h={h} /></div>}
        <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `scale(${0.94 + 0.06 * inK})`, filter: flight > 0.2 ? `blur(${flight * 3}px)` : undefined }}>
          <MorphInner c={cur.content} t={t} w={w} h={h} /></div>
        {glint > 0 && glint < 1 && <div style={{ position: "absolute", top: 0, bottom: 0, width: "45%", left: `${-50 + glint * 160}%`,
          background: "linear-gradient(100deg, transparent, rgba(255,255,255,0.35), transparent)", transform: "skewX(-18deg)" }} />}
      </div>
    </div>
  );
};


// ---------- EQT reveal (same as the Palm video's ending), usable after any morph chain ----------
export type RevealDef = { at: number; dot: { x: number; y: number }; lockAt: number; sub: string; site: string; video?: string;
  track?: [number, number, number][]; videoEnd?: number };
const BLUE = "#1E9BFF";
const CYAN = "#5ACDFF";
export const LogoReveal: React.FC<{ d: RevealDef }> = ({ d }) => {
  const t = useT();
  if (t < d.at) return null;
  const open = r(t, d.at, d.at + 0.45); // fast start: never a slow dark dot on his face
  const BIG = 440, CX = 540, CY = 720;
  const fromPos: Record<string, [number, number]> = { top: [540, -300], mid: [-400, 760], bot: [1480, 760] };
  const fly = (i: number) => r(t, d.lockAt - 0.55 + i * 0.1, d.lockAt - 0.05 + i * 0.1, EASE_IO);
  const lock = r(t, d.lockAt + 0.15, d.lockAt + 0.45, POP);
  const word = r(t, d.lockAt + 0.15, d.lockAt + 0.55);
  const subK = r(t, d.lockAt + 0.4, d.lockAt + 0.8);
  const siteK = r(t, d.lockAt + 0.75, d.lockAt + 1.1, POP);
  // face bubble keeps him present during the reveal, centred on the tracked face
  let fx = 540, fy = 900;
  if (d.track && d.track.length) {
    let i = 0;
    while (i + 1 < d.track.length && d.track[i + 1][0] <= t) i++;
    fx = d.track[i][1]; fy = d.track[i][2];
  }
  const pipIn = r(t, d.at + 0.3, d.at + 0.7, POP) * (1 - r(t, (d.videoEnd ?? 1e9) - 0.3, d.videoEnd ?? 1e9, EASE_IN));
  const PS = 0.3, D = 300;
  return (
    <AbsoluteFill style={{ clipPath: `circle(${open * 2300}px at ${d.dot.x}px ${d.dot.y}px)` }}>
      <AbsoluteFill style={{ background: "#05070C" }} />
      <AbsoluteFill style={{ background: "radial-gradient(60% 40% at 50% 40%, rgba(30,155,255,0.45), transparent 70%)" }} />
      {(["top", "mid", "bot"] as const).map((name, i) => {
        const k = fly(i);
        const x = lerp(fromPos[name][0], CX, k), y = lerp(fromPos[name][1], CY, k);
        return <Img key={name} src={staticFile(`eqt/layer-${name}.png`)} style={{ position: "absolute", left: x - BIG / 2, top: y - BIG / 2, width: BIG, height: BIG,
          opacity: 1 - word, filter: `drop-shadow(0 0 30px ${BLUE})` }} />;
      })}
      <div style={{ position: "absolute", left: 0, right: 0, top: CY - BIG / 2, display: "flex", justifyContent: "center", opacity: word, transform: `scale(${0.96 + 0.04 * lock})` }}>
        <Img src={staticFile("eqt/logo-mark.png")} style={{ width: BIG, height: BIG, filter: `drop-shadow(0 0 40px ${BLUE})` }} />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: CY + BIG / 2 - 10, textAlign: "center" }}>
        <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 150, color: "#fff", letterSpacing: 18 * (1 - word) + 6, opacity: word, filter: `blur(${(1 - word) * 12}px)` }}>EQT</div>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 34, letterSpacing: 14, color: CYAN, opacity: subK }}>{d.sub}</div>
        <div style={{ display: "inline-block", marginTop: 34, padding: "16px 40px", borderRadius: 50, background: BLUE, color: "#fff", fontFamily: UI, fontWeight: 900,
          fontSize: 60, boxShadow: `0 0 40px ${BLUE}`, opacity: siteK, transform: `scale(${0.8 + 0.2 * siteK})` }}>{d.site}</div>
      </div>
      {d.video && (
        <div style={{ position: "absolute", left: 60, top: 1150, width: D, height: D, borderRadius: D / 2, overflow: "hidden", border: "6px solid #fff",
          boxShadow: `0 0 40px rgba(30,155,255,0.55)`, transform: `scale(${pipIn})`, transformOrigin: "0% 100%" }}>
          <div style={{ position: "absolute", width: 1080, height: 1920, left: -(fx * PS) + D / 2, top: -(fy * PS) + D / 2, transform: `scale(${PS})`, transformOrigin: "0 0" }}>
            <OffthreadVideo src={staticFile(d.video)} muted style={{ width: 1080, height: 1920 }} />
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};

// ---------- background swap: the room behind him becomes a colour field with huge type (he stays in front via the matte) ----------
export type BgSwapDef = { from: number; to: number; c1: string; c2: string; words: { text: string; at: number; color?: string; size?: number; y: number; serif?: boolean }[] };
export const BgSwap: React.FC<{ d: BgSwapDef }> = ({ d }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const inK = r(t, d.from, d.from + 0.45, EASE_IO);
  const outK = r(t, d.to - 0.4, d.to, EASE_IN);
  // diagonal wipe in from the left, out to the right
  const a = inK * 160 - 30, b = outK * 160 - 30;
  const clip = `polygon(${b}% 0, ${a + 30}% 0, ${a}% 100%, ${b - 30}% 100%)`;
  return (
    <AbsoluteFill style={{ clipPath: clip }}>
      <AbsoluteFill style={{ background: `radial-gradient(120% 90% at 50% 35%, ${d.c1} 0%, ${d.c2} 75%)` }} />
      {/* soft moving light so it never feels like a flat card */}
      <div style={{ position: "absolute", left: 540 + Math.sin(t * 0.8) * 260 - 400, top: 300 + Math.cos(t * 0.6) * 180, width: 800, height: 800, borderRadius: 400,
        background: "rgba(255,255,255,0.10)", filter: "blur(120px)" }} />
      {d.words.map((w, i) => {
        if (t < w.at) return null;
        const k = r(t, w.at, w.at + 0.5, Easing.bezier(0.2, 1.2, 0.4, 1));
        const drift = (t - w.at) * 14;
        return (
          <div key={i} style={{ position: "absolute", left: 0, right: 0, top: w.y, textAlign: "center", whiteSpace: "nowrap",
            fontFamily: w.serif ? SERIF : UI, fontStyle: w.serif ? "italic" : "normal", fontWeight: w.serif ? 400 : 900,
            fontSize: w.size ?? 260, lineHeight: 0.9, letterSpacing: w.serif ? -4 : -8, color: w.color ?? "rgba(255,255,255,0.92)",
            opacity: k, transform: `translateX(${(1 - k) * (i % 2 ? 300 : -300) + (i % 2 ? -drift : drift)}px) scale(${0.9 + 0.1 * k})`,
            filter: k < 1 ? `blur(${(1 - k) * 12}px)` : undefined }}>{w.text}</div>
        );
      })}
    </AbsoluteFill>
  );
};
