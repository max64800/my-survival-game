import React from "react";
import { interpolate } from "remotion";
import {
  useT, r, lerp, clamp, typed, rand, mix, C, EASE, EASE_IN, EASE_IO, POP, LIQUID, Backdrop, Sounds, DemoCaption, LibItem,
  UI, SERIF, MONO, DISPLAY,
} from "./common";

// Family m3 — Data & UI. Rebuilt, crisp UI that makes proof visual. Every demo is ONE container that morphs through
// 2-4 states (liquid size overshoot, old content leaves fast, new content is born inside it). Illustrative round AED numbers.
const FAM = "Data & UI";
type SfxName = "whoosh" | "swish" | "pop" | "impact" | "tick" | "type" | "ding" | "riser";
type Snd = [number, SfxName, number?];
/** n soft ticks spread between a and b (for counters) */
const tk = (a: number, b: number, n: number, s: SfxName = "tick", v = 0.13): Snd[] =>
  Array.from({ length: n }, (_, i) => [a + ((b - a) * i) / Math.max(1, n - 1), s, v] as Snd);
const fmt = (n: number) => Math.round(n).toLocaleString("en-US");
const ri = (t: number, a: number, b: number, e = EASE) => r(t, a, b, e);
const liq = (t: number, a: number, b: number) =>
  interpolate(t, [a, b], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });

// ---------- odometer with thousands separators (rests on whole numbers) ----------
const OdoN: React.FC<{ value: number; size: number; color?: string; font?: string; weight?: number; sep?: string; digits?: number; spacing?: number; dec?: number }> =
  ({ value, size, color = "#fff", font = UI, weight = 900, sep = ",", digits, spacing = 0, dec = 0 }) => {
    const v = Math.max(0, value);
    const n = Math.max(digits ?? String(Math.round(v)).length, dec + 1);
    const H = size * 1.08;
    const out: React.ReactNode[] = [];
    for (let d = n - 1; d >= 0; d--) {
      const p = Math.pow(10, d), base = Math.floor(v / p) % 10;
      const c = d === 0 ? base + (v - Math.floor(v)) : base + Math.max(0, (v % p) - (p - 1));
      out.push(
        <div key={`d${d}`} style={{ height: H, overflow: "hidden", marginRight: spacing }}>
          <div style={{ transform: `translateY(${-c * H}px)` }}>
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((m, j) => (
              <div key={j} style={{ height: H, fontSize: size, lineHeight: `${H}px`, fontFamily: font, fontWeight: weight, textAlign: "center", fontVariantNumeric: "tabular-nums" }}>{m}</div>
            ))}
          </div>
        </div>,
      );
      if (dec && d === dec) out.push(<div key="dot" style={{ height: H, fontSize: size, lineHeight: `${H}px`, fontFamily: font, fontWeight: weight }}>.</div>);
      if (!dec && sep && d > 0 && d % 3 === 0) out.push(<div key={`s${d}`} style={{ height: H, fontSize: size, lineHeight: `${H}px`, fontFamily: font, fontWeight: weight }}>{sep}</div>);
    }
    return <div style={{ display: "flex", height: H, overflow: "hidden", color }}>{out}</div>;
  };

// ---------- the morphing container ----------
type BS = { at: number; x: number; y: number; w: number; h: number; r?: number; bg?: string };
type G = { t: number; i: number; k: number; kS: number; flight: number; x: number; y: number; w: number; h: number; rad: number;
  /** value for the current state, gliding from the previous one */ pv: (a: number[]) => number };
const geo = (t: number, S: BS[]): G => {
  let i = 0;
  while (i + 1 < S.length && S[i + 1].at <= t) i++;
  const cur = S[i], prev = S[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.55, EASE_IO);
  const kS = i === 0 ? 1 : liq(t, cur.at, cur.at + 0.62);
  const flight = i > 0 ? Math.sin(Math.PI * clamp((t - cur.at) / 0.5)) : 0;
  return { t, i, k, kS, flight, x: lerp(prev.x, cur.x, k), y: lerp(prev.y, cur.y, k), w: lerp(prev.w, cur.w, kS), h: lerp(prev.h, cur.h, kS),
    rad: lerp(prev.r ?? 36, cur.r ?? 36, k), pv: (a) => lerp(a[Math.max(0, i - 1)] ?? a[a.length - 1], a[i] ?? a[a.length - 1], k) };
};
type Tone = "dark" | "cream" | "glass" | "white" | "none";
const TONES: Record<Tone, { bg: string; border: string; color: string; blur?: boolean }> = {
  dark: { bg: "rgba(22,22,24,0.92)", border: "rgba(255,255,255,0.16)", color: "#fff" },
  cream: { bg: "rgba(246,242,233,0.97)", border: "rgba(0,0,0,0.08)", color: C.ink },
  glass: { bg: "rgba(255,255,255,0.74)", border: "rgba(255,255,255,0.7)", color: C.ink, blur: true },
  white: { bg: "#FFFFFF", border: "rgba(0,0,0,0.07)", color: C.ink },
  none: { bg: "transparent", border: "transparent", color: "#fff" },
};
/** ONE container: glides between fitted states; `scenes[i]` hands off inside it (old leaves fast, new is born), `over` draws continuous content */
const Box: React.FC<{ S: BS[]; to: number; tone?: Tone; scenes?: ((g: G) => React.ReactNode)[]; over?: (g: G) => React.ReactNode; shadow?: boolean; float?: boolean }> =
  ({ S, to, tone = "dark", scenes, over, shadow = true, float: fl = true }) => {
    const t = useT();
    const from = S[0].at;
    if (t < from) return null;
    const g = geo(t, S);
    const T = TONES[tone];
    const enter = liq(t, from, from + 0.6), fade = r(t, from, from + 0.2);
    const exit = r(t, to - 0.5, to - 0.05, EASE_IN);
    const w = g.w, h = g.h;
    const sc = lerp(0.55, 1, enter) * (1 - 0.8 * exit);
    const curBg = S[g.i].bg, prevBg = S[Math.max(0, g.i - 1)].bg;
    const bg = curBg && prevBg && curBg.startsWith("#") && prevBg.startsWith("#") ? mix(prevBg, curBg, g.k) : curBg ?? T.bg;
    const outK = g.i === 0 ? 1 : r(t, S[g.i].at, S[g.i].at + 0.16, EASE_IN);
    const inK = g.i === 0 ? r(t, from + 0.04, from + 0.32) : r(t, S[g.i].at + 0.18, S[g.i].at + 0.5);
    const gg = { ...g, w: g.w, h: g.h };
    const content = 1 - r(t, to - 0.4, to - 0.15);
    return (
      <div style={{ position: "absolute", left: g.x - w / 2, top: g.y + (g.h - h) / 2, width: w, height: h, opacity: fade * (1 - r(t, to - 0.15, to)),
        transform: `${fl ? `translateY(${Math.sin(t * 1.3) * 4}px)` : ""} scale(${sc}) scale(${1 + g.flight * 0.025}, ${1 - g.flight * 0.035})` }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: exit > 0 ? lerp(g.rad, Math.min(w, h) / 2, exit) : g.rad, overflow: "hidden", background: bg,
          border: `1.5px solid ${T.border}`, color: T.color, fontFamily: UI,
          boxShadow: shadow ? "0 22px 50px rgba(0,0,0,0.28)" : undefined, backdropFilter: T.blur ? "blur(26px) saturate(150%)" : undefined }}>
          <div style={{ position: "absolute", left: (w - g.w) / 2, top: (h - g.h) / 2, width: g.w, height: g.h, opacity: content }}>
            {scenes && g.i > 0 && outK < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - outK, transform: `scale(${1 - outK * 0.05})` }}>{scenes[g.i - 1]?.(gg)}</div>}
            {scenes && <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `scale(${0.96 + 0.04 * inK})` }}>{scenes[g.i]?.(gg)}</div>}
            {over && over(gg)}
          </div>
        </div>
      </div>
    );
  };

const lab = (color = "rgba(255,255,255,0.62)", size = 28): React.CSSProperties =>
  ({ fontFamily: MONO, fontWeight: 700, fontSize: size, letterSpacing: 3, color, whiteSpace: "nowrap" });
const Chip: React.FC<{ k: number; bg?: string; color?: string; size?: number; children: React.ReactNode; style?: React.CSSProperties }> =
  ({ k, bg = "#2C2C2E", color = "#fff", size = 36, children, style }) => (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 10, padding: `${size * 0.24}px ${size * 0.5}px`, borderRadius: size * 0.55, background: bg, color,
      fontFamily: UI, fontWeight: 800, fontSize: size, whiteSpace: "nowrap", opacity: clamp(k * 1.5), transform: `scale(${0.6 + 0.4 * k})`, ...style }}>{children}</div>
  );
const Caps: React.FC<{ lines: [string, number, number][]; y?: number }> = ({ lines, y }) => (
  <>{lines.map(([s, a, b], i) => <DemoCaption key={i} text={s} from={a} to={b} y={y} />)}</>
);

/** soft split: a panel slides down from the top and pushes Max's clip down (gradual, never a hard cut) */
const SplitBg: React.FC<{ top: number; shift: number; panel: string }> = ({ top, shift, panel }) => (
  <>
    <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: 1920, background: "#000" }} />
    <div style={{ position: "absolute", left: 0, top, width: 1080, height: 1920 - top, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, top: shift - top, width: 1080, height: 1920 }}><Backdrop /></div>
    </div>
    <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: top, background: panel, borderBottomLeftRadius: 0, borderBottomRightRadius: 0 }} />
  </>
);

// =====================================================================================================================
// m3-01 Price odometer: one graphite plate; the price rolls up, gains a per-sq-ft row, becomes then-vs-now, ends as a pill
// =====================================================================================================================
const D01: React.FC = () => {
  const t = useT();
  const S: BS[] = [
    { at: 0.2, x: 540, y: 290, w: 720, h: 230 },
    { at: 3.6, x: 540, y: 280, w: 860, h: 270 },
    { at: 6.8, x: 540, y: 280, w: 920, h: 270 },
    { at: 9.8, x: 540, y: 330, w: 640, h: 150, r: 75 },
  ];
  const price = lerp(1200000, 2450000, ri(t, 0.6, 2.6));
  const sqft = lerp(1200, 1850, ri(t, 4.0, 5.4));
  const pct = 69 * ri(t, 7.6, 8.9, EASE_IO);
  return (
    <>
      <Backdrop />
      <Box S={S} to={12} tone="dark" scenes={[
        (g) => (
          <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
            <div style={lab()}>AVG 3-BED VILLA · AED</div>
            <OdoN value={price} size={112} />
          </div>
        ),
        (g) => (
          <div style={{ position: "absolute", inset: 0, padding: "26px 40px", boxSizing: "border-box" }}>
            <div style={lab()}>AVG 3-BED VILLA · AED</div>
            <div style={{ marginTop: 6 }}><OdoN value={2450000} size={92} /></div>
            <div style={{ display: "flex", alignItems: "center", gap: 18, marginTop: 10 }}>
              <div style={lab(C.gold)}>PER SQ FT</div>
              <OdoN value={sqft} size={52} color={C.gold} />
              <Chip k={ri(t, 5.6, 6.0, POP)} bg="rgba(48,209,88,0.2)" color={C.green} size={34}>▲ 18% a year</Chip>
            </div>
          </div>
        ),
        (g) => (
          <div style={{ position: "absolute", inset: 0, padding: "26px 40px", boxSizing: "border-box" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div style={{ opacity: ri(t, 7.0, 7.4) }}>
                <div style={lab()}>2019</div>
                <OdoN value={1450000} size={62} color="rgba(255,255,255,0.5)" />
              </div>
              <div style={{ fontSize: 60, fontWeight: 900, color: C.gold, marginTop: 40, transform: `translateX(${(1 - ri(t, 7.2, 7.7)) * -40}px)`, opacity: ri(t, 7.2, 7.5) }}>→</div>
              <div style={{ textAlign: "right" }}>
                <div style={lab()}>2026</div>
                <OdoN value={2450000} size={62} />
              </div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 18, marginTop: 22 }}>
              <div style={{ height: 22, flex: 1, borderRadius: 11, background: "rgba(255,255,255,0.1)", overflow: "hidden" }}>
                <div style={{ height: "100%", width: `${(59 + 41 * ri(t, 7.6, 8.9, EASE_IO))}%`, background: C.green, borderRadius: 11 }} />
              </div>
              <div style={{ display: "flex", alignItems: "baseline", color: C.green }}>
                <span style={{ fontSize: 56, fontWeight: 900 }}>+</span><OdoN value={pct} size={60} color={C.green} /><span style={{ fontSize: 56, fontWeight: 900 }}>%</span>
              </div>
            </div>
          </div>
        ),
        (g) => (
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 22 }}>
            <span style={{ fontSize: 66, fontWeight: 900 }}>AED 2.45M</span>
            <Chip k={ri(t, 10.3, 10.7, POP)} bg={C.green} color="#0B2A14" size={40}>▲ 69%</Chip>
          </div>
        ),
      ]} />
      <Caps lines={[["The average villa here?", 0.4, 3.4], ["Per square foot, it's climbing", 3.7, 6.6], ["Seven years: up 69%", 6.9, 9.6], ["That's the real number", 9.9, 11.6]]} />
      <Sounds list={[[0.2, "swish", 0.3], ...tk(0.6, 2.5, 12), [2.6, "ding", 0.3], [3.6, "whoosh", 0.25], ...tk(4.0, 5.3, 8), [5.6, "pop", 0.3],
        [6.8, "whoosh", 0.25], [7.2, "swish", 0.2], ...tk(7.6, 8.8, 8), [8.9, "ding", 0.3], [9.8, "whoosh", 0.25], [10.3, "pop", 0.32], [11.5, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-02 Fee calculator: cream plate; price chip spawns × 4% = fee, the fee drops into a receipt, receipt squashes into the total
// =====================================================================================================================
const D02: React.FC = () => {
  const t = useT();
  const INK = C.ink;
  const S: BS[] = [
    { at: 0.2, x: 540, y: 330, w: 520, h: 140, r: 70 },
    { at: 2.0, x: 540, y: 300, w: 960, h: 200, r: 44 },
    { at: 5.0, x: 540, y: 270, w: 780, h: 300, r: 36 },
    { at: 9.4, x: 540, y: 300, w: 820, h: 200, r: 50 },
  ];
  const chip = (bg: string, color: string, k: number, dx: number, child: React.ReactNode) => (
    <div style={{ padding: "12px 20px", borderRadius: 24, background: bg, color, fontFamily: UI, fontWeight: 900, fontSize: 44, whiteSpace: "nowrap",
      opacity: clamp(k * 1.6), transform: `translateX(${(1 - k) * dx}px) scale(${0.7 + 0.3 * k})`, display: "flex", alignItems: "center", gap: 8 }}>{child}</div>
  );
  const rows: [string, number, number][] = [["DLD fee · 4%", 80000, 5.4], ["Agency · 2%", 40000, 6.4], ["Trustee", 4000, 7.3]];
  const totK = ri(t, 8.1, 9.0, EASE_IO);
  return (
    <>
      <Backdrop />
      <Box S={S} to={13} tone="cream" scenes={[
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, color: INK }}>
            <span style={{ fontSize: 40, fontWeight: 800, opacity: 0.55 }}>AED</span>
            <OdoN value={lerp(1000000, 2000000, ri(t, 0.5, 1.6))} size={64} color={INK} />
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
            <div style={lab("rgba(0,0,0,0.5)")}>TRANSFER FEE</div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              {chip("#FFFFFF", INK, 1, 0, <><span style={{ opacity: 0.5, fontSize: 34 }}>AED</span> 2,000,000</>)}
              {chip("transparent", INK, ri(t, 2.4, 2.8, POP), -120, "×")}
              {chip(C.blue, "#fff", ri(t, 2.6, 3.0, POP), -200, "4%")}
              {chip("transparent", INK, ri(t, 3.1, 3.4, POP), -120, "=")}
              {chip(C.ink, "#fff", ri(t, 3.2, 3.6, POP), -160, <OdoN value={80000 * ri(t, 3.4, 4.4)} size={44} digits={5} />)}
            </div>
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, padding: "24px 40px", boxSizing: "border-box", color: INK }}>
            <div style={{ display: "flex", justifyContent: "space-between" }}><div style={lab("rgba(0,0,0,0.5)")}>ON TOP OF AED 2M</div><div style={lab("rgba(0,0,0,0.5)")}>AED</div></div>
            {rows.map(([n, v, at], i) => {
              const k = ri(t, at, at + 0.45, POP);
              const squash = totK;
              return (
                <div key={n} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", height: 54, borderBottom: "2px dashed rgba(0,0,0,0.12)",
                  opacity: clamp(k * 1.5) * (1 - squash * 0.65), transform: `translateY(${(1 - k) * -30 + squash * (2 - i) * 10}px)` }}>
                  <span style={{ fontSize: 36, fontWeight: 700 }}>{n}</span>
                  <OdoN value={v * ri(t, at + 0.1, at + 0.8)} size={38} color={INK} digits={String(v).length} />
                </div>
              );
            })}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 12, opacity: ri(t, 8.0, 8.3) }}>
              <span style={{ fontSize: 40, fontWeight: 900 }}>Extra costs</span>
              <OdoN value={lerp(100000, 124000, totK)} size={52} color={C.red} />
            </div>
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8, color: INK }}>
            <div style={lab("rgba(0,0,0,0.5)")}>YOU ACTUALLY NEED</div>
            <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
              <span style={{ fontSize: 44, fontWeight: 800, opacity: 0.5 }}>AED</span>
              <OdoN value={lerp(2000000, 2124000, ri(t, 9.8, 10.8))} size={80} color={INK} />
              <Chip k={ri(t, 11.0, 11.4, POP)} bg={C.red} color="#fff" size={36}>+6.2%</Chip>
            </div>
          </div>
        ),
      ]} />
      <Caps lines={[["You found a 2 million flat", 0.4, 1.9], ["The transfer fee alone is 4%", 2.2, 4.8], ["Then agency and trustee", 5.2, 9.2], ["So you need 2.12 million", 9.6, 12.4]]} />
      <Sounds list={[[0.2, "swish", 0.3], ...tk(0.5, 1.5, 6), [2.0, "whoosh", 0.25], [2.4, "pop", 0.25], [2.6, "pop", 0.3], [3.1, "pop", 0.22], [3.2, "pop", 0.3],
        ...tk(3.4, 4.3, 6), [4.4, "ding", 0.3], [5.0, "whoosh", 0.25], [5.4, "pop", 0.28], [6.4, "pop", 0.28], [7.3, "pop", 0.28], [8.1, "swish", 0.25], ...tk(8.2, 8.9, 5),
        [9.0, "impact", 0.3], [9.4, "whoosh", 0.25], ...tk(9.8, 10.7, 6), [11.0, "pop", 0.35], [12.5, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-03 Mortgage slider: full-screen blue; one white card. Drag the deposit, then the term, then it flips into total interest
// =====================================================================================================================
const pay = (loan: number, years: number, rate = 0.045) => { const m = rate / 12, n = years * 12; return (loan * m) / (1 - Math.pow(1 + m, -n)); };
const D03: React.FC = () => {
  const t = useT();
  const price = 3000000;
  const dp = lerp(20, 30, ri(t, 2.6, 4.0, EASE_IO));
  const yrs = lerp(25, 15, ri(t, 5.6, 7.0, EASE_IO));
  const p20 = Math.round(pay(price * 0.8, 25)), p30 = Math.round(pay(price * 0.7, 25)), p15 = Math.round(pay(price * 0.7, 15));
  const payment = t < 5.6 ? lerp(p20, p30, ri(t, 2.6, 4.0, EASE_IO)) : lerp(p30, p15, ri(t, 5.6, 7.0, EASE_IO));
  const i25 = Math.round((p30 * 300 - price * 0.7) / 1000) * 1000, i15 = Math.round((p15 * 180 - price * 0.7) / 1000) * 1000;
  const S: BS[] = [
    { at: 0.1, x: 540, y: 400, w: 900, h: 490, r: 48, bg: "#FFFFFF" },
    { at: 5.0, x: 540, y: 400, w: 900, h: 630, r: 48, bg: "#FFFFFF" },
    { at: 8.4, x: 540, y: 400, w: 900, h: 560, r: 48, bg: "#FFFFFF" },
  ];
  const Slider: React.FC<{ label: string; val: string; frac: number; y: number; active: boolean }> = ({ label, val, frac, y, active }) => (
    <div style={{ position: "absolute", left: 50, right: 50, top: y }}>
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: 34, fontWeight: 700, color: "#3A3A3C" }}><span>{label}</span><span style={{ fontWeight: 900, color: C.ink }}>{val}</span></div>
      <div style={{ position: "relative", height: 12, borderRadius: 6, background: "#E5E5EA", marginTop: 26 }}>
        <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${frac * 100}%`, borderRadius: 6, background: C.blue }} />
        <div style={{ position: "absolute", left: `${frac * 100}%`, top: 6, width: 54, height: 54, marginLeft: -27, marginTop: -27, borderRadius: 27, background: "#fff",
          boxShadow: "0 3px 10px rgba(0,0,0,0.25)", border: "1px solid rgba(0,0,0,0.06)", transform: `scale(${active ? 1.12 : 1})` }} />
      </div>
    </div>
  );
  const bar = (n: string, v: number, max: number, k: number, col: string, y: number) => (
    <div style={{ position: "absolute", left: 50, right: 50, top: y }}>
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: 34, fontWeight: 800, color: C.ink }}><span>{n}</span>
        <span style={{ display: "flex", gap: 8, alignItems: "baseline" }}><span style={{ fontSize: 28, opacity: 0.5 }}>AED</span><OdoN value={v * k} size={38} color={C.ink} digits={String(v).length} /></span></div>
      <div style={{ height: 34, borderRadius: 12, background: "#F2F2F7", marginTop: 12, overflow: "hidden" }}>
        <div style={{ height: "100%", width: `${(v / max) * 100 * k}%`, background: col, borderRadius: 12 }} />
      </div>
    </div>
  );
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: C.blue }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 260, textAlign: "center", fontFamily: SERIF, fontSize: 76, color: "#fff", opacity: ri(t, 0.2, 0.7) }}>
        {t < 8.4 ? "What will I pay a month?" : "What it really costs"}</div>
      <Box S={S} to={13} tone="white" float={false} scenes={[
        () => null, () => null,
        () => (
          <>
            <div style={{ position: "absolute", left: 50, top: 44, ...lab("rgba(0,0,0,0.45)") }}>TOTAL INTEREST · AED 2.1M LOAN</div>
            {bar("25 years", i25, i25, ri(t, 8.8, 9.9, EASE_IO), "#FF9F0A", 120)}
            {bar("15 years", i15, i25, ri(t, 9.4, 10.5, EASE_IO), C.green, 270)}
            <div style={{ position: "absolute", left: 50, right: 50, top: 450, display: "flex", alignItems: "center", justifyContent: "center", gap: 16 }}>
              <Chip k={ri(t, 10.9, 11.3, POP)} bg={C.green} color="#0B2A14" size={46}>You keep AED {fmt(i25 - i15)}</Chip>
            </div>
          </>
        ),
      ]} over={(g) => g.i < 2 || g.k < 0.3 ? (
        <div style={{ position: "absolute", inset: 0, opacity: g.i < 2 ? 1 : 1 - r(t, 8.4, 8.6) }}>
          <div style={{ position: "absolute", left: 50, top: 44, ...lab("rgba(0,0,0,0.45)") }}>MONTHLY PAYMENT</div>
          <div style={{ position: "absolute", left: 50, top: 92, display: "flex", alignItems: "baseline", gap: 14 }}>
            <span style={{ fontSize: 44, fontWeight: 800, color: "#8E8E93" }}>AED</span><OdoN value={payment} size={110} color={C.ink} />
          </div>
          <Slider label="Property price" val="AED 3,000,000" frac={0.6} y={250} active={false} />
          <Slider label="Down payment" val={`${Math.round(dp)}%`} frac={(dp - 10) / 40} y={390} active={t > 2.4 && t < 4.2} />
          {g.i >= 1 && <div style={{ opacity: ri(t, 5.2, 5.6) }}><Slider label="Loan term" val={`${Math.round(yrs)} years`} frac={(yrs - 5) / 25} y={530} active={t > 5.4 && t < 7.2} /></div>}
        </div>
      ) : null} />
      <Caps lines={[["Put 20% down: 13 grand a month", 0.6, 2.4], ["Put 30% down instead", 2.6, 4.8], ["Now pay it off in 15 years", 5.4, 8.2], ["And save over half a million", 8.6, 12.4]]} y={1340} />
      <Sounds list={[[0.1, "whoosh", 0.3], [0.5, "pop", 0.2], [2.6, "swish", 0.22], ...tk(2.7, 3.9, 9), [4.0, "ding", 0.25], [5.0, "whoosh", 0.25], [5.3, "pop", 0.25],
        [5.6, "swish", 0.22], ...tk(5.7, 6.9, 9), [7.0, "ding", 0.25], [8.4, "whoosh", 0.3], ...tk(8.8, 10.4, 10), [10.9, "impact", 0.3], [12.4, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-04 Rent vs Buy table: full-screen cream paper, serif title; rows draw in, ticks/crosses stamp, BUY column gets the highlight
// =====================================================================================================================
const D04: React.FC = () => {
  const t = useT();
  const INK = "#1E1B16";
  const rows: { n: string; a: string | boolean; b: string | boolean; at: number }[] = [
    { n: "Monthly cost", a: "12,000", b: "11,500", at: 1.6 },
    { n: "Builds equity", a: false, b: true, at: 3.0 },
    { n: "Easy to move", a: true, b: false, at: 4.4 },
    { n: "Cash upfront", a: "48,000", b: "720,000", at: 5.8 },
    { n: "Visa from AED 2M", a: false, b: true, at: 7.2 },
  ];
  const hi = ri(t, 8.8, 9.5, EASE_IO);
  const verdict = ri(t, 10.6, 11.3, LIQUID);
  const W = 920, X = 80, Y = 520, RH = 150, c1 = 470, c2 = 700;
  const cell = (v: string | boolean, k: number, win: boolean) => typeof v === "boolean" ? (
    <div style={{ width: 66, height: 66, borderRadius: 33, background: v ? C.green : "#E8E2D5", color: v ? "#fff" : "#A39E92", display: "flex", alignItems: "center",
      justifyContent: "center", fontSize: 40, fontWeight: 900, transform: `scale(${k}) rotate(${(1 - k) * -40}deg)` }}>{v ? "✓" : "✕"}</div>
  ) : (
    <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 46, color: win ? INK : "#6E685D", opacity: clamp(k * 1.5), transform: `translateY(${(1 - k) * 20}px)` }}>{v}</div>
  );
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#F3EEE3" }} />
      {/* paper rules */}
      {Array.from({ length: 30 }, (_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: i * 64 + 20, height: 1, background: "rgba(30,27,22,0.05)" }} />)}
      <div style={{ position: "absolute", left: X, top: 300, fontFamily: SERIF, fontSize: 130, color: INK, lineHeight: 1, opacity: ri(t, 0.1, 0.6), transform: `translateY(${(1 - ri(t, 0.1, 0.7)) * 30}px)` }}>
        Rent <span style={{ color: "#B3A994" }}>or</span> buy?</div>
      {/* the BUY highlight column (slides in from the RENT column) */}
      <div style={{ position: "absolute", left: X + lerp(c1, c2, hi) - 30, top: Y - 20, width: 250, height: RH * 5 + 110, borderRadius: 28,
        background: C.gold, opacity: ri(t, 8.6, 8.9) * (1 - verdict), transform: `scaleY(${0.3 + 0.7 * ri(t, 8.6, 9.2, LIQUID)})`, transformOrigin: "50% 0%" }} />
      <div style={{ position: "absolute", left: X, top: Y, width: W, opacity: 1 - verdict, transform: `scale(${1 - 0.08 * verdict})`, transformOrigin: "50% 30%" }}>
        <div style={{ display: "flex", height: 80, alignItems: "center", ...lab("#6E685D", 30) }}>
          <div style={{ width: c1 }} /><div style={{ width: c2 - c1, opacity: ri(t, 0.8, 1.2) }}>RENT</div><div style={{ opacity: ri(t, 1.0, 1.4), color: hi > 0.5 ? INK : undefined }}>BUY</div>
        </div>
        {rows.map((row, i) => {
          const line = ri(t, row.at - 0.3, row.at + 0.3, EASE_IO);
          const k1 = ri(t, row.at + 0.2, row.at + 0.55, POP), k2 = ri(t, row.at + 0.45, row.at + 0.8, POP);
          return (
            <div key={row.n} style={{ position: "relative", display: "flex", alignItems: "center", height: RH }}>
              <div style={{ position: "absolute", left: 0, bottom: 0, height: 2, width: `${line * 100}%`, background: "rgba(30,27,22,0.18)" }} />
              <div style={{ width: c1, fontFamily: UI, fontWeight: 700, fontSize: 46, color: INK, opacity: line, whiteSpace: "nowrap" }}>{row.n}</div>
              <div style={{ width: c2 - c1 }}>{cell(row.a, k1, false)}</div>
              <div>{cell(row.b, k2, true)}</div>
            </div>
          );
        })}
      </div>
      {verdict > 0 && (
        <div style={{ position: "absolute", left: lerp(X + c2 - 30, 140, verdict), top: lerp(Y - 20, 760, verdict), width: lerp(250, 800, verdict), height: lerp(RH * 5 + 110, 380, verdict),
          borderRadius: 40, background: C.gold, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8 }}>
          <div style={{ opacity: ri(t, 11.0, 11.4), ...lab("rgba(0,0,0,0.55)", 30) }}>STAYING 5+ YEARS?</div>
          <div style={{ opacity: ri(t, 11.1, 11.5), fontFamily: SERIF, fontSize: 170, color: INK, lineHeight: 1, transform: `scale(${0.8 + 0.2 * ri(t, 11.1, 11.6, POP)})` }}>Buy.</div>
        </div>
      )}
      <Sounds list={[[0.1, "swish", 0.25], ...rows.flatMap((row) => [[row.at - 0.3, "swish", 0.14], [row.at + 0.25, "pop", 0.25], [row.at + 0.5, "pop", 0.3]] as Snd[]),
        [8.6, "whoosh", 0.3], [9.4, "ding", 0.3], [10.6, "whoosh", 0.3], [11.2, "impact", 0.35]]} />
    </>
  );
};

// =====================================================================================================================
// m3-05 Deal timeline: soft split (panel slides down, pushes Max down); a gold dot rides a line from viewing to keys
// =====================================================================================================================
const D05: React.FC = () => {
  const t = useT();
  const open = ri(t, 0, 0.9, EASE_IO) * (1 - ri(t, 12.1, 12.9, EASE_IO));
  const top = lerp(0, 900, open), shift = lerp(0, 400, open);
  const ms = [
    { d: 1, n: "Viewing", e: "👀", at: 1.6 },
    { d: 2, n: "Offer accepted", e: "🤝", at: 3.3 },
    { d: 7, n: "MOU signed · 10%", e: "✍️", at: 5.0 },
    { d: 21, n: "Developer NOC", e: "📄", at: 6.7 },
    { d: 30, n: "Transfer · keys", e: "🔑", at: 8.4 },
  ];
  const L = 120, R = 960, LY = 600;
  const px = (idx: number) => lerp(L, R, idx / (ms.length - 1));
  // dot rides between milestones (evenly spaced stops; the day counter rolls between their days)
  let idx = 0, day = 1;
  for (let i = 1; i < ms.length; i++) { const q = ri(t, ms[i].at - 0.7, ms[i].at, EASE_IO); idx = lerp(idx, i, q); day = lerp(day, ms[i].d, q); }
  const lineK = ri(t, 0.9, 1.7, EASE_IO);
  let cur = 0;
  ms.forEach((m, i) => { if (t >= m.at) cur = i; });
  const collapse = ri(t, 10.2, 10.9, EASE_IO);
  const hand = r(t, ms[cur].at, ms[cur].at + 0.3);
  return (
    <>
      <SplitBg top={top} shift={shift} panel="#161618" />
      <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: top, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: top - 900, height: 900 }}>
          <div style={{ position: "absolute", left: L, top: 300, ...lab() }}>VIEWING → KEYS</div>
          <div style={{ position: "absolute", left: L, top: 350, display: "flex", alignItems: "baseline", gap: 16, color: "#fff", fontFamily: UI }}>
            <span style={{ fontSize: 60, fontWeight: 800, opacity: 0.6 }}>Day</span><OdoN value={day} size={110} color={C.gold} />
          </div>
          {/* line */}
          <div style={{ position: "absolute", left: L, top: LY - 4, height: 8, width: (R - L) * lineK * (1 - collapse), borderRadius: 4, background: "rgba(255,255,255,0.14)" }} />
          <div style={{ position: "absolute", left: L, top: LY - 4, height: 8, width: (px(idx) - L) * (1 - collapse), borderRadius: 4, background: C.gold }} />
          {ms.map((m, i) => {
            const on = ri(t, m.at - 0.05, m.at + 0.3, POP);
            const x = lerp(px(i), L, collapse);
            return <div key={i} style={{ position: "absolute", left: x - 26, top: LY - 26, width: 52, height: 52, borderRadius: 26, background: on > 0.5 ? C.gold : "#2C2C2E",
              border: `4px solid ${on > 0.5 ? C.gold : "rgba(255,255,255,0.25)"}`, boxSizing: "border-box", transform: `scale(${(0.9 + 0.2 * Math.sin(on * Math.PI) + 0.1 * on) * lineK * (1 - collapse)})`,
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, color: C.ink, fontWeight: 900 }}>{on > 0.5 ? "✓" : ""}</div>;
          })}
          {/* the travelling dot */}
          <div style={{ position: "absolute", left: px(idx) - 20, top: LY - 20, width: 40, height: 40, borderRadius: 20, background: "#fff", opacity: lineK * (1 - collapse) }} />
          {/* one card whose content hands off per milestone */}
          <div style={{ position: "absolute", left: clamp(px(idx) - 230, 60, 1020 - 460), top: LY + 70, width: 460, height: 120, borderRadius: 30, background: "#2C2C2E",
            display: "flex", alignItems: "center", gap: 20, padding: "0 28px", boxSizing: "border-box", opacity: ri(t, 1.4, 1.8) * (1 - collapse) }}>
            <div style={{ fontSize: 58, transform: `scale(${0.6 + 0.4 * hand})` }}>{ms[cur].e}</div>
            <div style={{ opacity: hand, transform: `translateY(${(1 - hand) * 14}px)` }}>
              <div style={lab(C.gold, 28)}>DAY {ms[cur].d}</div>
              <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 44, color: "#fff", whiteSpace: "nowrap" }}>{ms[cur].n}</div>
            </div>
          </div>
          {/* collapse: the whole line becomes one pill */}
          {collapse > 0 && <div style={{ position: "absolute", left: 540 - 300 * collapse, top: LY - 70, width: 600 * collapse, height: 140, borderRadius: 70, background: C.gold,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 18, overflow: "hidden" }}>
            <span style={{ fontSize: 60 }}>🔑</span><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 64, color: C.ink, whiteSpace: "nowrap", opacity: ri(t, 10.6, 10.9) }}>30 days. Done.</span>
          </div>}
        </div>
      </div>
      <Caps lines={[["Viewing on day one", 1.4, 3.1], ["Offer the next day", 3.3, 4.9], ["MOU and 10% deposit", 5.0, 6.6], ["NOC from the developer", 6.7, 8.3], ["Keys on day 30", 8.4, 10.1]]} y={1330} />
      <Sounds list={[[0.0, "whoosh", 0.3], [0.9, "swish", 0.2], ...ms.flatMap((m) => [[m.at - 0.7, "swish", 0.14], [m.at, "pop", 0.3], [m.at + 0.1, "tick", 0.2]] as Snd[]),
        [8.5, "ding", 0.3], [10.2, "whoosh", 0.3], [10.7, "impact", 0.3], [12.1, "whoosh", 0.25]]} />
    </>
  );
};

// =====================================================================================================================
// m3-06 Progress rings: full-screen black; three concentric rings fill, spread into a row of three, then the middle one becomes the hero
// =====================================================================================================================
const Ring: React.FC<{ cx: number; cy: number; rad: number; sw: number; p: number; color: string; track?: number }> = ({ cx, cy, rad, sw, p, color, track = 0.22 }) => {
  const c = 2 * Math.PI * rad;
  return (
    <g>
      <circle cx={cx} cy={cy} r={rad} fill="none" stroke={color} strokeOpacity={track} strokeWidth={sw} />
      {p > 0.001 && <circle cx={cx} cy={cy} r={rad} fill="none" stroke={color} strokeWidth={sw} strokeLinecap="round" strokeDasharray={`${c * p} ${c}`}
        transform={`rotate(-90 ${cx} ${cy})`} />}
    </g>
  );
};
const D06: React.FC = () => {
  const t = useT();
  const rings = [
    { n: "Units sold", v: 94, col: "#FF6B4A", a: 0.8 },
    { n: "Built", v: 72, col: C.gold, a: 2.6 },
    { n: "You've paid", v: 40, col: C.teal, a: 4.4 },
  ];
  const spread = ri(t, 7.0, 7.9, EASE_IO);
  const hero = ri(t, 10.0, 10.9, EASE_IO);
  const cy0 = 780;
  const fills = rings.map((g) => ri(t, g.a, g.a + 1.4, EASE_IO));
  let curI = 0;
  rings.forEach((g, i) => { if (t >= g.a) curI = i; });
  const born = ri(t, 0.1, 0.7, LIQUID);
  const geo6 = (i: number) => {
    const conc = { cx: 540, cy: cy0, rad: [300, 225, 150][i], sw: 58 };
    const row = { cx: [210, 540, 870][i], cy: 700, rad: 120, sw: 32 };
    const her = i === 1 ? { cx: 540, cy: 760, rad: 270, sw: 62 } : { cx: 540, cy: 760, rad: 0.1, sw: 0 };
    const a = { cx: lerp(conc.cx, row.cx, spread), cy: lerp(conc.cy, row.cy, spread), rad: lerp(conc.rad, row.rad, spread), sw: lerp(conc.sw, row.sw, spread) };
    return { cx: lerp(a.cx, her.cx, hero), cy: lerp(a.cy, her.cy, hero), rad: lerp(a.rad, her.rad, hero) * born, sw: lerp(a.sw, her.sw, hero) };
  };
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#050506" }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 280, textAlign: "center", ...lab("rgba(255,255,255,0.6)", 30), opacity: ri(t, 0.2, 0.6) }}>
        OFF-PLAN TOWER · LIVE PROGRESS</div>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        {rings.map((g, i) => { const q = geo6(i); return <Ring key={i} cx={q.cx} cy={q.cy} rad={q.rad} sw={q.sw} p={fills[i] * g.v / 100} color={g.col} track={0.2 * (i === 1 ? 1 : 1 - hero)} />; })}
      </svg>
      {/* centre number (concentric state): the ring being filled */}
      <div style={{ position: "absolute", left: 340, top: cy0 - 75, width: 400, display: "flex", justifyContent: "center", alignItems: "baseline", opacity: 1 - spread * 3,
        color: rings[curI].col }}>
        <OdoN value={rings[curI].v * fills[curI]} size={120} color={rings[curI].col} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 70 }}>%</span>
      </div>
      {/* legend (concentric) → labels under each ring (row) */}
      {rings.map((g, i) => {
        const q = geo6(i);
        const k = ri(t, g.a - 0.2, g.a + 0.3);
        const lx = lerp(160, q.cx - 160, spread), ly = lerp(1110 + i * 80, q.cy + 150, spread);
        return (
          <div key={i} style={{ position: "absolute", left: lx, top: ly, width: 320 + (1 - spread) * 440, display: "flex", alignItems: "center", gap: 18,
            justifyContent: spread > 0.5 ? "center" : "flex-start", opacity: k * (1 - hero), fontFamily: UI, color: "#fff" }}>
            {spread < 0.5 && <div style={{ width: 30, height: 30, borderRadius: 15, background: g.col }} />}
            <span style={{ fontSize: 46, fontWeight: 700, flex: spread < 0.5 ? 1 : undefined }}>{g.n}</span>
            {spread < 0.5 && <span style={{ fontSize: 50, fontWeight: 900, color: g.col }}>{Math.round(g.v * fills[i])}%</span>}
          </div>
        );
      })}
      {/* row state: % inside each ring */}
      {rings.map((g, i) => {
        const q = geo6(i);
        const k = spread * (1 - hero);
        return <div key={i} style={{ position: "absolute", left: q.cx - 110, top: q.cy - 42, width: 220, textAlign: "center", fontFamily: UI, fontWeight: 900, fontSize: 70,
          color: g.col, opacity: clamp((k - 0.5) * 2) }}>{g.v}%</div>;
      })}
      {/* hero state */}
      <div style={{ position: "absolute", left: 240, top: 640, width: 600, textAlign: "center", opacity: ri(t, 10.6, 11.0), fontFamily: UI, color: "#fff" }}>
        <div style={{ fontSize: 150, fontWeight: 900, color: C.gold, lineHeight: 1 }}>72%</div>
        <div style={{ fontSize: 50, fontWeight: 700, marginTop: 8 }}>built</div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1110, display: "flex", justifyContent: "center" }}>
        <Chip k={ri(t, 11.2, 11.6, POP)} bg={C.gold} color={C.ink} size={50}>Keys in Q4 2027</Chip>
      </div>
      <Caps lines={[["94% of units already sold", 0.8, 2.5], ["72% of the tower is built", 2.6, 4.3], ["And you've only paid 40%", 4.4, 6.8]]} y={1350} />
      <Sounds list={[[0.1, "swish", 0.3], ...rings.flatMap((g) => [[g.a, "riser", 0.12], ...tk(g.a + 0.1, g.a + 1.3, 7), [g.a + 1.4, "ding", 0.28]] as Snd[]),
        [7.0, "whoosh", 0.3], [7.8, "pop", 0.25], [10.0, "whoosh", 0.3], [10.8, "impact", 0.3], [11.2, "pop", 0.32]]} />
    </>
  );
};

// =====================================================================================================================
// m3-07 Settings toggles: light glass plate above the head; flip three filters, the match count rolls down, plate becomes the result
// =====================================================================================================================
const Toggle: React.FC<{ on: number }> = ({ on }) => (
  <div style={{ width: 104, height: 62, borderRadius: 31, background: mix("#D1D1D6", "#30D158", on), position: "relative", flexShrink: 0 }}>
    <div style={{ position: "absolute", top: 4, left: lerp(4, 46, on), width: 54, height: 54, borderRadius: 27, background: "#fff", boxShadow: "0 2px 6px rgba(0,0,0,0.2)",
      transform: `scaleX(${1 + Math.sin(on * Math.PI) * 0.18})` }} />
  </div>
);
const D07: React.FC = () => {
  const t = useT();
  const sw = [
    { n: "Ready to move in", e: "🔑", at: 2.0 },
    { n: "Sea view", e: "🌊", at: 3.9 },
    { n: "Under AED 3M", e: "💰", at: 5.8 },
  ];
  const counts = [1240, 410, 96, 12];
  let count = counts[0];
  sw.forEach((s, i) => { count = lerp(count, counts[i + 1], ri(t, s.at + 0.1, s.at + 1.0, EASE_IO)); });
  const S: BS[] = [
    { at: 0.2, x: 540, y: 262, w: 820, h: 316, r: 34 },
    { at: 8.2, x: 540, y: 330, w: 680, h: 140, r: 70 },
    { at: 10.2, x: 540, y: 270, w: 800, h: 270, r: 40 },
  ];
  const press = ri(t, 9.6, 9.8) * (1 - ri(t, 9.8, 10.0));
  return (
    <>
      <Backdrop />
      <Box S={S} to={13} tone="glass" scenes={[
        () => (
          <div style={{ position: "absolute", inset: 0, padding: "18px 34px", boxSizing: "border-box", color: C.ink }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", height: 70 }}>
              <span style={{ fontSize: 44, fontWeight: 900 }}>Filters</span>
              <span style={{ display: "flex", alignItems: "baseline", gap: 10, fontSize: 32, fontWeight: 700, color: "#6C6C70" }}>
                <OdoN value={count} size={46} color={C.blue} /> homes</span>
            </div>
            {sw.map((s, i) => (
              <div key={s.n} style={{ display: "flex", alignItems: "center", gap: 18, height: 74, borderTop: "1.5px solid rgba(0,0,0,0.08)" }}>
                <div style={{ width: 50, height: 50, borderRadius: 12, background: ["#FF9F0A", C.teal, C.green][i], display: "flex", alignItems: "center", justifyContent: "center", fontSize: 30 }}>{s.e}</div>
                <span style={{ flex: 1, fontSize: 38, fontWeight: 700 }}>{s.n}</span>
                <Toggle on={ri(t, s.at, s.at + 0.35, EASE_IO)} />
              </div>
            ))}
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 18px 0 40px", color: C.ink }}>
            <span style={{ fontSize: 50, fontWeight: 900 }}>🏡 12 homes</span>
            <div style={{ padding: "18px 34px", borderRadius: 40, background: C.blue, color: "#fff", fontSize: 40, fontWeight: 800, transform: `scale(${1 - press * 0.1})` }}>View →</div>
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, padding: 26, boxSizing: "border-box", display: "flex", gap: 26, color: C.ink }}>
            <div style={{ width: 218, height: 218, borderRadius: 26, background: "linear-gradient(180deg,#9ED8FF,#5AB2F2 60%,#F2D7A8 60%)", position: "relative", flexShrink: 0, overflow: "hidden" }}>
              <div style={{ position: "absolute", left: 40, bottom: 34, width: 138, height: 92, background: "#fff", borderRadius: 6 }} />
              <div style={{ position: "absolute", left: 30, bottom: 120, width: 0, height: 0, borderLeft: "79px solid transparent", borderRight: "79px solid transparent", borderBottom: `56px solid ${C.ink}` }} />
              <div style={{ position: "absolute", left: 92, bottom: 34, width: 34, height: 52, background: C.orange, borderRadius: "6px 6px 0 0" }} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", justifyContent: "center", gap: 10 }}>
              <div style={lab("rgba(0,0,0,0.45)")}>MATCH 1 OF 12</div>
              <div style={{ fontSize: 42, fontWeight: 800 }}>3 bed · Sea view</div>
              <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}><span style={{ fontSize: 30, fontWeight: 800, color: "#8E8E93" }}>AED</span>
                <OdoN value={lerp(2000000, 2950000, ri(t, 10.6, 11.6))} size={52} color={C.ink} /></div>
              <div style={{ display: "flex", gap: 8 }}>
                <Chip k={ri(t, 11.7, 12.0, POP)} bg="rgba(48,209,88,0.18)" color="#1E8E3E" size={28}>✓ Ready</Chip>
                <Chip k={ri(t, 11.85, 12.15, POP)} bg="rgba(10,132,255,0.15)" color={C.blue} size={28}>🌊 View</Chip>
              </div>
            </div>
          </div>
        ),
      ]} />
      <Caps lines={[["Everyone starts with 1,240 listings", 0.4, 1.9], ["Ready to move in", 2.0, 3.8], ["Sea view", 3.9, 5.7], ["Under three million", 5.8, 8.0], ["Twelve homes. That's your list", 8.3, 12.4]]} />
      <Sounds list={[[0.2, "swish", 0.3], ...sw.flatMap((s) => [[s.at, "tick", 0.35], [s.at + 0.05, "pop", 0.22], ...tk(s.at + 0.15, s.at + 0.9, 5)] as Snd[]),
        [8.2, "whoosh", 0.28], [9.7, "tick", 0.35], [10.2, "whoosh", 0.28], ...tk(10.6, 11.5, 6), [11.6, "ding", 0.28], [11.7, "pop", 0.25], [11.85, "pop", 0.25], [12.5, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-08 Notification stack: lock-screen cards drop in above his head, older ones tuck behind; the stack folds into one gold pill
// =====================================================================================================================
const D08: React.FC = () => {
  const t = useT();
  const N = [
    { e: "📩", bg: C.blue, title: "New enquiry", body: "2-bed, sea view, ready", at: 0.4 },
    { e: "📅", bg: C.orange, title: "Viewing booked", body: "Saturday, 11:00", at: 2.2 },
    { e: "🤝", bg: C.purple, title: "Offer received", body: "AED 3,100,000", at: 4.0 },
    { e: "💳", bg: C.green, title: "Deposit cleared", body: "AED 310,000 · 10%", at: 5.8 },
    { e: "🔑", bg: C.gold, title: "Transfer done", body: "Keys handed over", at: 7.6 },
  ];
  const fold = ri(t, 9.8, 10.5, EASE_IO);
  const pill = ri(t, 10.3, 11.0, LIQUID);
  const W = 880, H = 150, X = 100, Y0 = 268;
  return (
    <>
      <Backdrop />
      {N.map((n, j) => {
        const inK = ri(t, n.at, n.at + 0.55, LIQUID);
        if (inK <= 0) return null;
        let d = 0;
        for (let k = j + 1; k < N.length; k++) d += ri(t, N[k].at, N[k].at + 0.5, EASE_IO);
        if (d > 3.2) return null;
        const dd = d * (1 - fold);
        const y = lerp(Y0 - 60, Y0, inK) + Math.min(dd, 2.4) * 30;
        const sc = (1 - Math.min(dd, 3) * 0.06) * (1 - fold * 0.15 * (j < 4 ? 1 : 0));
        const op = clamp(inK * 2) * clamp(3 - dd) * (1 - pill);
        return (
          <div key={j} style={{ position: "absolute", left: X, top: y, width: W, height: H, borderRadius: 38, zIndex: 10 - Math.round(d),
            background: d > 0.5 ? mix("#F2F2F4", "#D9D9DE", Math.min(dd, 2) / 2) : "rgba(246,246,248,0.97)",
            boxShadow: "0 14px 30px rgba(0,0,0,0.22)", transform: `scale(${sc}) ${float(t, j, 2)}`, transformOrigin: "50% 100%", opacity: op,
            display: "flex", alignItems: "center", gap: 24, padding: "0 30px", boxSizing: "border-box", fontFamily: UI, color: C.ink }}>
            <div style={{ width: 84, height: 84, borderRadius: 22, background: n.bg, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 46, flexShrink: 0,
              opacity: 1 - clamp(d) * 0.6 }}>{n.e}</div>
            <div style={{ flex: 1, opacity: 1 - clamp(d) * 0.85 }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ fontSize: 42, fontWeight: 800 }}>{n.title}</span><span style={{ fontSize: 28, color: "#8E8E93", fontWeight: 600 }}>now</span></div>
              <div style={{ fontSize: 36, fontWeight: 500, color: "#3A3A3C" }}>{n.body}</div>
            </div>
          </div>
        );
      })}
      {pill > 0 && (
        <div style={{ position: "absolute", left: 540 - lerp(W, 700, pill) / 2, top: lerp(Y0, Y0 + 20, pill), width: lerp(W, 700, pill), height: lerp(H, 130, pill), borderRadius: 65,
          background: C.gold, display: "flex", alignItems: "center", justifyContent: "center", gap: 18, fontFamily: UI, color: C.ink, boxShadow: "0 14px 30px rgba(0,0,0,0.22)", zIndex: 20 }}>
          <span style={{ fontSize: 56, opacity: ri(t, 10.6, 10.9) }}>🔑</span>
          <span style={{ fontSize: 52, fontWeight: 900, opacity: ri(t, 10.7, 11.0), whiteSpace: "nowrap" }}>Closed in</span>
          <span style={{ display: "flex", alignItems: "baseline", gap: 10, fontSize: 52, fontWeight: 900, opacity: ri(t, 10.7, 11.0) }}>
            <OdoN value={6 * ri(t, 10.8, 11.6)} size={60} color={C.ink} /> days</span>
        </div>
      )}
      <Caps lines={[["Monday: an enquiry", 0.5, 2.1], ["Viewing on Saturday", 2.2, 3.9], ["Offer that evening", 4.0, 5.7], ["Deposit the next day", 5.8, 7.5], ["Then the keys", 7.6, 9.7], ["Six days, start to finish", 10.2, 12.4]]} />
      <Sounds list={[...N.flatMap((n) => [[n.at, "swish", 0.2], [n.at + 0.2, "ding", 0.24]] as Snd[]), [9.8, "whoosh", 0.3], [10.4, "pop", 0.32], ...tk(10.8, 11.5, 4), [11.6, "impact", 0.28], [12.5, "swish", 0.2]]} />
    </>
  );
};
const float = (t: number, seed = 0, amp = 4) => `translate(${Math.sin(t * 1.2 + seed) * amp * 0.6}px, ${Math.sin(t * 1.6 + seed * 2) * amp}px)`;

// =====================================================================================================================
// m3-09 Chat thread: full-screen warm paper chat; a client asks, bubbles are born from the typing dots, a listing card and a booking land
// =====================================================================================================================
type Msg = { me: boolean; at: number; text?: string; card?: boolean; book?: boolean };
const D09: React.FC = () => {
  const t = useT();
  const msgs: Msg[] = [
    { me: false, at: 0.45, text: "Is the 2-bed in the Marina still available?" },
    { me: true, at: 2.4, text: "Yes, but 3 offers came in today" },
    { me: false, at: 4.0, text: "What's the asking? 👀" },
    { me: true, at: 5.6, card: true },
    { me: false, at: 7.6, text: "Can I see it today? 🙏" },
    { me: true, at: 9.2, text: "4pm works ✅" },
    { me: true, at: 10.4, book: true },
  ];
  const H = (m: Msg) => m.card ? 300 : m.book ? 120 : (m.text!.length > 26 ? 168 : 104);
  // thread scrolls up so the newest message sits above the input bar
  let total = 0;
  const ys: number[] = [];
  msgs.forEach((m) => { const k = ri(t, m.at - 0.5, m.at + 0.1, EASE_IO); ys.push(total); total += (H(m) + 22) * k; });
  const bottom = 1300;
  const scroll = Math.max(0, total - (bottom - 400));
  const typingFor = msgs.find((m) => t > m.at - 0.9 && t < m.at);
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#EFEAE0" }} />
      {/* header */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 380, background: "#F8F5EE", borderBottom: "1.5px solid rgba(0,0,0,0.08)", zIndex: 5 }}>
        <div style={{ position: "absolute", left: 70, top: 262, display: "flex", alignItems: "center", gap: 22, fontFamily: UI }}>
          <div style={{ width: 92, height: 92, borderRadius: 46, background: "#F7D9C4", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 54 }}>👩</div>
          <div><div style={{ fontSize: 44, fontWeight: 800, color: C.ink }}>Sara · buyer</div>
            <div style={{ fontSize: 30, fontWeight: 600, color: typingFor && !typingFor.me ? C.green : "#8E8E93" }}>{typingFor && !typingFor.me ? "typing…" : "online"}</div></div>
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 380, height: bottom - 380, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 30 - scroll }}>
          {msgs.map((m, i) => {
            const k = ri(t, m.at, m.at + 0.45, LIQUID);
            if (t < m.at - 0.5) return null;
            const bg = m.me ? C.eqt : "#FFFFFF", col = m.me ? "#fff" : C.ink;
            const side: React.CSSProperties = m.me ? { right: 60 } : { left: 60 };
            return (
              <div key={i} style={{ position: "absolute", top: ys[i], ...side, maxWidth: 760, transformOrigin: m.me ? "100% 100%" : "0% 100%",
                transform: `scale(${0.3 + 0.7 * k})`, opacity: clamp(k * 2) }}>
                {m.text && <div style={{ padding: "26px 34px", borderRadius: 38, background: bg, color: col, fontFamily: UI, fontWeight: 600, fontSize: 44, lineHeight: 1.25,
                  borderBottomRightRadius: m.me ? 10 : 38, borderBottomLeftRadius: m.me ? 38 : 10 }}>{m.text}</div>}
                {m.card && (
                  <div style={{ width: 640, height: 300, borderRadius: 34, background: "#fff", overflow: "hidden", fontFamily: UI, color: C.ink, border: `4px solid ${C.eqt}`, boxSizing: "border-box" }}>
                    <div style={{ height: 130, background: "linear-gradient(180deg,#8FD0FF,#4FA6E8)", position: "relative" }}>
                      {[0, 1, 2, 3].map((b) => <div key={b} style={{ position: "absolute", bottom: 0, left: 60 + b * 140, width: 90, height: 50 + ((b * 37) % 70), background: "rgba(255,255,255,0.85)", borderRadius: "8px 8px 0 0" }} />)}
                    </div>
                    <div style={{ padding: "16px 26px" }}>
                      <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}><span style={{ fontSize: 30, fontWeight: 800, color: "#8E8E93" }}>AED</span>
                        <OdoN value={lerp(1500000, 2100000, ri(t, 5.8, 6.8))} size={52} color={C.ink} /></div>
                      <div style={{ fontSize: 32, fontWeight: 600, color: "#3A3A3C" }}>2 bed · 1,250 sq ft · Marina</div>
                    </div>
                  </div>
                )}
                {m.book && (
                  <div style={{ display: "flex", alignItems: "center", gap: 18, padding: "22px 32px", borderRadius: 36, background: "#E3F8E8", border: `3px solid ${C.green}`, fontFamily: UI }}>
                    <span style={{ fontSize: 50 }}>📅</span>
                    <div><div style={{ ...lab("#1E8E3E", 28) }}>VIEWING BOOKED</div><div style={{ fontSize: 42, fontWeight: 800, color: C.ink }}>Today · 4:00 PM</div></div>
                  </div>
                )}
              </div>
            );
          })}
          {/* typing dots: the next bubble is born from them */}
          {typingFor && (
            <div style={{ position: "absolute", top: total, ...(typingFor.me ? { right: 60 } : { left: 60 }), padding: "26px 30px", borderRadius: 34, background: typingFor.me ? C.eqt : "#fff",
              display: "flex", gap: 12, opacity: ri(t, typingFor.at - 0.9, typingFor.at - 0.7) }}>
              {[0, 1, 2].map((d) => <div key={d} style={{ width: 18, height: 18, borderRadius: 9, background: typingFor.me ? "#fff" : "#8E8E93", opacity: 0.4 + 0.6 * Math.abs(Math.sin(t * 6 - d * 0.7)) }} />)}
            </div>
          )}
        </div>
      </div>
      {/* input bar */}
      <div style={{ position: "absolute", left: 50, right: 200, top: bottom + 10, height: 96, borderRadius: 48, background: "#fff", display: "flex", alignItems: "center", padding: "0 34px",
        fontFamily: UI, fontSize: 38, color: "#AEAEB2", border: "1.5px solid rgba(0,0,0,0.08)" }}>Message…</div>
      <Sounds list={[...msgs.flatMap((m) => [[m.at - 0.8, "type", 0.12], [m.at, m.me ? "swish" : "pop", 0.26]] as Snd[]), ...tk(5.8, 6.7, 5), [6.8, "ding", 0.25], [10.5, "ding", 0.35]]} />
    </>
  );
};

// =====================================================================================================================
// m3-10 Search typing: full-screen white; the query types, results stream in and narrow, the top result grows into the hero card
// =====================================================================================================================
const D10: React.FC = () => {
  const t = useT();
  const q = "3 bed villa with a garden";
  const text = typed(q, t, 0.5, 0.06);
  const caret = Math.floor(t * 2.5) % 2 === 0 && t < 2.2;
  const chips = [{ n: "Under AED 5M", at: 4.4 }, { n: "Ready", at: 5.6 }];
  let count = lerp(0, 1284, ri(t, 2.2, 3.4, EASE_IO));
  count = lerp(count, 214, ri(t, 4.5, 5.3, EASE_IO));
  count = lerp(count, 37, ri(t, 5.7, 6.5, EASE_IO));
  const grow = ri(t, 7.8, 8.7, EASE_IO);
  const res = [
    { n: "Garden villa · 3 bed", p: "4,600,000", c: "#C9E6B8" },
    { n: "Townhouse · 3 bed", p: "3,900,000", c: "#F5D9B0" },
    { n: "Corner villa · 3 bed", p: "4,950,000", c: "#BFD9F2" },
    { n: "Family villa · 3 bed", p: "4,200,000", c: "#E8C9E0" },
  ];
  const RY = 540, RH = 170;
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#FFFFFF" }} />
      {/* search bar */}
      <div style={{ position: "absolute", left: 60, right: 60, top: 280, height: 116, borderRadius: 58, background: "#F2F2F7", display: "flex", alignItems: "center", gap: 20, padding: "0 36px",
        fontFamily: UI, transform: `scaleX(${lerp(0.4, 1, ri(t, 0, 0.5, LIQUID))})`, opacity: 1 - grow * 0.4 }}>
        <svg width="44" height="44" viewBox="0 0 24 24"><circle cx="10" cy="10" r="7" fill="none" stroke="#8E8E93" strokeWidth="2.6" /><path d="M15 15 L21 21" stroke="#8E8E93" strokeWidth="2.6" strokeLinecap="round" /></svg>
        <span style={{ fontSize: 46, fontWeight: 600, color: text ? C.ink : "#AEAEB2", whiteSpace: "nowrap", overflow: "hidden" }}>{text || "Search homes"}{caret && <span style={{ color: C.blue }}>|</span>}</span>
      </div>
      {/* filter chips + count */}
      <div style={{ position: "absolute", left: 60, right: 60, top: 430, display: "flex", alignItems: "center", gap: 14, opacity: ri(t, 2.2, 2.5) * (1 - grow) }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, fontFamily: UI, fontSize: 36, fontWeight: 700, color: "#3A3A3C" }}>
          <OdoN value={count} size={50} color={C.ink} /> homes</div>
        <div style={{ flex: 1 }} />
        {chips.map((c) => <Chip key={c.n} k={ri(t, c.at, c.at + 0.4, POP)} bg={C.ink} color="#fff" size={32}>{c.n} ✕</Chip>)}
      </div>
      {/* results */}
      {res.map((rr, i) => {
        const a = ri(t, 2.3 + i * 0.25, 2.8 + i * 0.25, LIQUID);
        const shuffle = ri(t, 4.5, 5.0, EASE_IO) * (1 - ri(t, 5.0, 5.4)) + ri(t, 5.7, 6.2, EASE_IO) * (1 - ri(t, 6.2, 6.6));
        const isHero = i === 0;
        const g = isHero ? grow : 0;
        const others = isHero ? 0 : grow;
        const top = lerp(RY + i * (RH + 24), 300, g), left = lerp(60, 60, g), h = lerp(RH, 1060, g);
        return (
          <div key={i} style={{ position: "absolute", left, right: 60, top: top + others * 300, height: h, borderRadius: lerp(30, 44, g), background: "#fff",
            border: "1.5px solid rgba(0,0,0,0.08)", boxShadow: "0 8px 24px rgba(0,0,0,0.08)", overflow: "hidden", opacity: clamp(a * 2) * (1 - others) * (1 - shuffle * 0.5 * (i % 2)),
            transform: `translateX(${(1 - a) * 80 + shuffle * (i % 2 ? 30 : 0)}px)`, fontFamily: UI, color: C.ink, zIndex: isHero ? 2 : 1 }}>
            <div style={{ position: "absolute", left: 18, top: 18, width: lerp(134, 924, g), height: lerp(134, 480, g), borderRadius: 22, background: rr.c, overflow: "hidden" }}>
              <div style={{ position: "absolute", left: "22%", bottom: "16%", width: "56%", height: "44%", background: "#fff", borderRadius: 8 }} />
              <div style={{ position: "absolute", left: "16%", bottom: "60%", width: "68%", height: "26%", background: C.ink, clipPath: "polygon(50% 0, 100% 100%, 0 100%)" }} />
              <div style={{ position: "absolute", left: "44%", bottom: "16%", width: "12%", height: "24%", background: C.orange, borderRadius: "6px 6px 0 0" }} />
            </div>
            <div style={{ position: "absolute", left: lerp(178, 40, g), top: lerp(28, 530, g) }}>
              <div style={{ fontSize: lerp(40, 54, g), fontWeight: 800 }}>{rr.n}</div>
              <div style={{ fontSize: lerp(36, 46, g), fontWeight: 700, color: C.blue, marginTop: 8 }}>AED {rr.p}</div>
            </div>
            {isHero && (
              <div style={{ position: "absolute", left: 40, right: 40, top: 690, display: "flex", gap: 14, flexWrap: "wrap", opacity: ri(t, 8.6, 8.9) }}>
                {[["🛏", "3 beds", 8.8], ["🌳", "Garden", 9.2], ["📐", "3,400 sq ft", 9.6], ["✅", "Ready", 10.0]].map(([e, n, at]) => (
                  <Chip key={n as string} k={ri(t, at as number, (at as number) + 0.35, POP)} bg="#F2F2F7" color={C.ink} size={36}>{e} {n}</Chip>))}
                <div style={{ width: "100%", marginTop: 14, height: 100, borderRadius: 50, background: C.blue, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 44, fontWeight: 800, opacity: ri(t, 10.6, 10.9), transform: `scale(${0.9 + 0.1 * ri(t, 10.6, 11.0, POP)})` }}>Book a viewing</div>
              </div>
            )}
          </div>
        );
      })}
      <Sounds list={[[0.0, "swish", 0.25], ...tk(0.5, 1.9, 12, "type", 0.1), [2.3, "whoosh", 0.22], ...res.map((_, i) => [2.4 + i * 0.25, "pop", 0.18] as Snd), ...tk(2.3, 3.3, 6),
        ...chips.flatMap((c) => [[c.at, "pop", 0.3], ...tk(c.at + 0.1, c.at + 0.8, 4)] as Snd[]), [7.8, "whoosh", 0.3], [8.8, "pop", 0.2], [9.2, "pop", 0.2], [9.6, "pop", 0.2], [10.0, "pop", 0.2], [10.6, "ding", 0.3]]} />
    </>
  );
};

// ---------- split-flap character: top flap falls, bottom flap lands (k 0 → 1) ----------
const Flap: React.FC<{ a: string; b: string; k: number; w: number; h: number; size: number; bg?: string; color?: string; font?: string }> =
  ({ a, b, k, w, h, size, bg = "#1C1C1E", color = "#fff", font = UI }) => {
    const half = (ch: string, top: boolean, extra?: React.CSSProperties) => (
      <div style={{ position: "absolute", left: 0, width: w, height: h / 2, top: top ? 0 : h / 2, overflow: "hidden", background: bg,
        borderRadius: top ? "10px 10px 0 0" : "0 0 10px 10px", ...extra }}>
        <div style={{ position: "absolute", left: 0, width: w, height: h, top: top ? 0 : -h / 2, lineHeight: `${h}px`, textAlign: "center", fontSize: size, fontFamily: font, fontWeight: 900, color }}>{ch}</div>
      </div>
    );
    const k1 = clamp(k * 2), k2 = clamp(k * 2 - 1);
    return (
      <div style={{ position: "relative", width: w, height: h, perspective: 600 }}>
        {half(b, true)}
        {half(k >= 0.5 ? b : a, false)}
        {k > 0 && k < 0.5 && half(a, true, { transformOrigin: "50% 100%", transform: `rotateX(${-90 * k1}deg)`, filter: `brightness(${1 - 0.4 * k1})` })}
        {k >= 0.5 && k < 1 && half(b, false, { transformOrigin: "50% 0%", transform: `rotateX(${90 * (1 - k2)}deg)`, filter: `brightness(${0.6 + 0.4 * k2})` })}
        <div style={{ position: "absolute", left: 0, right: 0, top: h / 2 - 1.5, height: 3, background: "rgba(0,0,0,0.55)" }} />
      </div>
    );
  };
/** a row of flaps that cascades from string a to string b between t0 and t0+dur */
const FlapRow: React.FC<{ a: string; b: string; t: number; t0: number; w: number; h: number; size: number; gap?: number; bg?: string; color?: string; font?: string }> =
  ({ a, b, t, t0, w, h, size, gap = 6, bg, color, font }) => {
    const n = Math.max(a.length, b.length);
    const A = a.padStart(n, " "), B = b.padStart(n, " ");
    return (
      <div style={{ display: "flex", gap }}>
        {Array.from({ length: n }, (_, i) => {
          const st = t0 + i * 0.05;
          const k = A[i] === B[i] ? 1 : r(t, st, st + 0.32, EASE_IN);
          return <Flap key={i} a={A[i]} b={B[i]} k={k} w={w} h={h} size={size} bg={bg} color={color} font={font} />;
        })}
      </div>
    );
  };

// =====================================================================================================================
// m3-11 Countdown calendar: full-screen forest green; days cross off on a paper calendar, the grid folds into a flip-clock, then into the deadline card
// =====================================================================================================================
const D11: React.FC = () => {
  const t = useT();
  const crossed = Math.floor(clamp((t - 1.2) / 3.4) * 17);           // days 1..17 crossed one by one
  const fold = ri(t, 5.6, 6.4, EASE_IO);
  const card = ri(t, 10.0, 10.8, EASE_IO);
  const CW = 900, X = 90, Y = 400;
  const cell = 112, gx = 14;
  const calH = 720;
  // the flip clock: days left 14 → 13 at a beat, hours/min tick
  const left = 31 - 17;
  const sec = Math.floor(Math.max(0, t - 6.6) * 1);
  const clock = [String(left).padStart(2, "0"), "09", String(59 - (sec % 60)).padStart(2, "0")];
  const prevClock = [String(left).padStart(2, "0"), "09", String(59 - ((sec + 59) % 60)).padStart(2, "0")];
  const h = lerp(lerp(calH, 360, fold), 380, card);
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#123D30" }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 270, textAlign: "center", fontFamily: SERIF, fontSize: 84, color: "#F4EBD8", opacity: ri(t, 0.2, 0.7) }}>
        {card < 0.5 ? "Launch price ends in…" : "Then the price goes up"}</div>
      <div style={{ position: "absolute", left: X, top: Y, width: CW, height: h * ri(t, 0.1, 0.7, LIQUID), borderRadius: 40, background: "#F6F0E3", overflow: "hidden",
        boxShadow: "0 24px 50px rgba(0,0,0,0.3)", transform: float(t, 1, 3) }}>
        {/* month grid */}
        <div style={{ position: "absolute", inset: 0, opacity: 1 - fold * 1.6, transform: `scale(${1 - 0.1 * fold})` }}>
          <div style={{ height: 110, background: C.red, color: "#fff", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 40px", fontFamily: UI }}>
            <span style={{ fontSize: 54, fontWeight: 900 }}>October</span><span style={{ ...lab("rgba(255,255,255,0.8)", 30) }}>LAUNCH WINDOW</span></div>
          <div style={{ position: "absolute", left: 40, top: 140, display: "flex", flexWrap: "wrap", width: 7 * cell + 6 * gx - 20, gap: gx - 4 }}>
            {Array.from({ length: 31 }, (_, i) => {
              const d = i + 1, x = d <= crossed, last = d === 31;
              const xk = x ? ri(t, 1.2 + (i / 17) * 3.4, 1.2 + (i / 17) * 3.4 + 0.2) : 0;
              const today = d === crossed + 1 && t > 1.2;
              return (
                <div key={d} style={{ width: cell - 10, height: 100, borderRadius: 18, position: "relative", display: "flex", alignItems: "center", justifyContent: "center",
                  background: last ? C.red : today ? C.ink : "transparent", color: last || today ? "#fff" : x ? "#B9B2A3" : C.ink, fontFamily: UI, fontWeight: 800, fontSize: 42 }}>
                  {d}
                  {x && <svg width={70} height={70} style={{ position: "absolute" }}><path d="M14 14 L56 56 M56 14 L14 56" stroke={C.red} strokeWidth={6} strokeLinecap="round"
                    strokeDasharray={60} strokeDashoffset={60 * (1 - xk)} opacity={0.8} /></svg>}
                </div>
              );
            })}
          </div>
        </div>
        {/* flip clock */}
        <div style={{ position: "absolute", left: 0, right: 0, top: 70, display: "flex", justifyContent: "center", gap: 50, opacity: clamp(fold * 2 - 1) * (1 - card * 2) }}>
          {["DAYS", "HRS", "MIN"].map((u, j) => (
            <div key={u} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
              <FlapRow a={j === 2 ? prevClock[2] : (j === 0 ? "31" : "00")} b={clock[j]} t={t} t0={j === 2 ? 6.6 + sec : 6.2 + j * 0.15} w={96} h={160} size={120} gap={8} />
              <div style={lab("#6E685D", 30)}>{u}</div>
            </div>
          ))}
        </div>
        {/* deadline card */}
        <div style={{ position: "absolute", inset: 0, opacity: clamp(card * 2 - 1), display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 50px", gap: 18, fontFamily: UI, color: C.ink }}>
          <div style={lab("#6E685D", 30)}>FROM 1 NOVEMBER</div>
          <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
            <span style={{ fontSize: 60, fontWeight: 800, color: "#9C9586", textDecoration: "line-through" }}>1.6M</span>
            <span style={{ fontSize: 60, fontWeight: 900 }}>→</span>
            <span style={{ fontSize: 84, fontWeight: 900 }}>AED 1.75M</span>
          </div>
          <Chip k={ri(t, 11.0, 11.4, POP)} bg={C.red} color="#fff" size={44} style={{ alignSelf: "flex-start" }}>+AED 150,000 for waiting</Chip>
        </div>
      </div>
      <Caps lines={[["The launch price is only for October", 0.6, 5.4], ["Two weeks left", 6.0, 9.8], ["After that, 150k more", 10.2, 12.4]]} y={1350} />
      <Sounds list={[[0.1, "swish", 0.28], ...Array.from({ length: 17 }, (_, i) => [1.2 + (i / 17) * 3.4, "tick", 0.2] as Snd), [5.6, "whoosh", 0.3],
        ...[0, 1, 2].map((j) => [6.2 + j * 0.15, "tick", 0.3] as Snd), ...Array.from({ length: 3 }, (_, i) => [7 + i, "tick", 0.18] as Snd), [10.0, "whoosh", 0.3], [11.0, "impact", 0.32]]} />
    </>
  );
};

// =====================================================================================================================
// m3-12 Price board flip: full-screen gold; a black split-flap board flips one villa's price through the years, then stamps the gain
// =====================================================================================================================
const D12: React.FC = () => {
  const t = useT();
  const years = [
    { y: "2016", p: "1,450,000", at: 1.0 },
    { y: "2020", p: "1,300,000", at: 3.2 },
    { y: "2023", p: "2,100,000", at: 5.4 },
    { y: "2026", p: "2,950,000", at: 7.6 },
  ];
  let i = 0;
  years.forEach((v, j) => { if (t >= v.at) i = j; });
  const prev = years[Math.max(0, i - 1)];
  const cur = years[i];
  const board = ri(t, 0.1, 0.7, LIQUID);
  const stamp = ri(t, 9.6, 10.0, POP);
  const shrink = ri(t, 11.2, 11.9, EASE_IO);
  const trend = (j: number) => j === 1 ? C.red : C.green;
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: C.gold }} />
      <div style={{ position: "absolute", left: 80, top: 280, fontFamily: DISPLAY, fontSize: 120, lineHeight: 1, color: C.ink, letterSpacing: 1, opacity: ri(t, 0.2, 0.6) }}>SAME VILLA.</div>
      <div style={{ position: "absolute", left: 80, top: 410, fontFamily: DISPLAY, fontSize: 120, lineHeight: 1, color: "rgba(28,28,30,0.35)", opacity: ri(t, 0.4, 0.8) }}>TEN YEARS.</div>
      <div style={{ position: "absolute", left: 60, top: 620, width: 960, height: lerp(560, 300, shrink), borderRadius: 36, background: "#111", padding: "36px 40px", boxSizing: "border-box",
        transform: `scale(${board}) ${float(t, 2, 3)}`, transformOrigin: "50% 0%", overflow: "hidden" }}>
        <div style={{ display: "flex", justifyContent: "space-between", ...lab("rgba(255,255,255,0.5)", 28) }}><span>YEAR</span><span>ASKING · AED</span></div>
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 18 }}>
          <FlapRow a={i === 0 ? "    " : prev.y} b={cur.y} t={t} t0={i === 0 ? 0.6 : cur.at} w={58} h={100} size={70} gap={5} bg="#2A2A2C" font={MONO} />
          <FlapRow a={i === 0 ? "         " : prev.p} b={cur.p} t={t} t0={i === 0 ? 0.7 : cur.at + 0.1} w={58} h={100} size={70} gap={5} bg="#2A2A2C" font={MONO} />
        </div>
        {/* history dots */}
        <div style={{ display: "flex", gap: 18, marginTop: 40, opacity: 1 - shrink }}>
          {years.map((v, j) => {
            const k = ri(t, v.at + 0.6, v.at + 0.9, POP);
            return <div key={v.y} style={{ flex: 1, height: 240, display: "flex", flexDirection: "column", justifyContent: "flex-end", alignItems: "center", gap: 10 }}>
              <div style={{ width: "70%", height: 190 * (parseInt(v.p.replace(/,/g, "")) / 2950000) * k, borderRadius: 12, background: j === i ? C.gold : "#3A3A3C" }} />
              <div style={{ ...lab(j === i ? C.gold : "rgba(255,255,255,0.5)", 28), opacity: k }}>{v.y}</div>
            </div>;
          })}
        </div>
        {/* trend chip */}
        {i > 0 && <div style={{ position: "absolute", right: 40, top: 30, opacity: shrink > 0 ? 0 : 1 }}>
          <Chip k={ri(t, cur.at + 0.6, cur.at + 0.9, POP)} bg={trend(i)} color={i === 1 ? "#fff" : "#0B2A14"} size={30}>{i === 1 ? "▼ dip" : "▲ up"}</Chip></div>}
        <div style={{ position: "absolute", left: 40, bottom: 34, ...lab(C.gold, 34), opacity: ri(t, 11.6, 12.0) }}>+103% SINCE 2016</div>
      </div>
      {/* stamp */}
      <div style={{ position: "absolute", left: 790, top: 500, transform: `rotate(-10deg) scale(${lerp(2.2, 1, stamp)})`, opacity: clamp(stamp * 2) * (1 - shrink),
        border: `8px solid ${C.red}`, borderRadius: 20, padding: "8px 26px", fontFamily: DISPLAY, fontSize: 90, color: C.red, background: C.gold, lineHeight: 1.1 }}>×2</div>
      <Caps lines={[["2016: one and a half million", 1.0, 3.1], ["2020 it dipped", 3.2, 5.3], ["2023 it took off", 5.4, 7.5], ["Today? Almost three", 7.6, 10.4]]} y={1350} />
      <Sounds list={[[0.1, "whoosh", 0.3], ...years.flatMap((v, j) => [...tk(j === 0 ? 0.6 : v.at, (j === 0 ? 0.6 : v.at) + 0.6, 6, "tick", 0.2), [v.at + 0.6, "pop", 0.2]] as Snd[]),
        [9.6, "impact", 0.4], [11.2, "whoosh", 0.25], [11.6, "ding", 0.28]]} />
    </>
  );
};

// =====================================================================================================================
// m3-13 Bar race: full-screen graphite; price per sq ft by area races 2020 → 2026 (bars re-rank), then the leader becomes a callout
// =====================================================================================================================
const D13: React.FC = () => {
  const t = useT();
  const areas = [
    { n: "Palm Jumeirah", c: C.gold, v: [2100, 2300, 3100, 3700, 4100, 4400, 4600] },
    { n: "Downtown", c: C.blue, v: [1900, 1950, 2300, 2600, 2900, 3050, 3200] },
    { n: "Dubai Marina", c: C.teal, v: [1450, 1500, 1800, 2050, 2200, 2300, 2400] },
    { n: "Business Bay", c: C.purple, v: [1300, 1350, 1650, 1950, 2250, 2400, 2500] },
    { n: "JVC", c: C.green, v: [750, 760, 900, 1050, 1150, 1250, 1300] },
  ];
  const T0 = 1.0, T1 = 8.6;
  const yr = clamp((t - T0) / (T1 - T0)) * 6;
  const yi = Math.min(5, Math.floor(yr)), f = EASE_IO(yr - yi);
  const val = (a: typeof areas[0]) => yr >= 6 ? a.v[6] : lerp(a.v[yi], a.v[yi + 1], f);
  const vals = areas.map(val);
  // smooth rank: count how many are above, with a soft step
  const rank = vals.map((v, i) => vals.reduce((s, w, j) => s + (j === i ? 0 : clamp((w - v) / 120 + 0.5)), 0));
  const MAX = 4800, BX = 70, BW = 720, Y0 = 560, RH = 132;
  const call = ri(t, 9.6, 10.4, EASE_IO);
  const year = 2020 + yr;
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#121214" }} />
      <div style={{ position: "absolute", left: BX, top: 290, fontFamily: UI, fontWeight: 900, fontSize: 64, color: "#fff", opacity: ri(t, 0.1, 0.5) }}>Price per sq ft</div>
      <div style={{ position: "absolute", left: BX, top: 375, ...lab(), opacity: ri(t, 0.2, 0.6) }}>AED · ILLUSTRATIVE</div>
      <div style={{ position: "absolute", right: 70, top: 280, opacity: ri(t, 0.3, 0.7) * (1 - call) }}><OdoN value={year} size={120} color="rgba(255,255,255,0.9)" sep="" /></div>
      {areas.map((a, i) => {
        const k = ri(t, 0.3 + i * 0.1, 0.8 + i * 0.1, EASE);
        const y = Y0 + rank[i] * RH;
        const lead = i === 0;
        const bw = (BW * vals[i]) / MAX * k;
        const cw = lead ? lerp(bw, 940, call) : bw;
        const ch = lead ? lerp(96, 420, call) : 96;
        return (
          <div key={a.n} style={{ position: "absolute", left: BX, top: lead ? lerp(y, Y0, call) : y + call * 380, opacity: lead ? 1 : 1 - call }}>
            <div style={{ position: "relative", width: cw, height: ch, borderRadius: lerp(18, 36, lead ? call : 0), background: a.c }}>
              {lead && call > 0 && (
                <div style={{ position: "absolute", inset: 0, padding: 40, opacity: ri(t, 10.2, 10.6), color: C.ink, fontFamily: UI }}>
                  <div style={lab("rgba(0,0,0,0.55)", 30)}>2020 → 2026</div>
                  <div style={{ fontSize: 72, fontWeight: 900, marginTop: 10 }}>Palm Jumeirah</div>
                  <div style={{ display: "flex", alignItems: "baseline", gap: 6, marginTop: 10 }}>
                    <span style={{ fontSize: 110, fontWeight: 900 }}>+</span><OdoN value={119 * ri(t, 10.4, 11.6)} size={130} color={C.ink} /><span style={{ fontSize: 110, fontWeight: 900 }}>%</span>
                  </div>
                </div>
              )}
            </div>
            <div style={{ position: "absolute", left: 24, top: 0, height: 96, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 40,
              color: C.ink, whiteSpace: "nowrap", opacity: (lead ? 1 - call * 3 : 1) * clamp(k * 2), clipPath: bw < 330 ? undefined : undefined }}>
              {bw > 330 ? a.n : ""}</div>
            <div style={{ position: "absolute", left: bw + 20, top: 0, height: 96, display: "flex", alignItems: "center", gap: 18, fontFamily: UI, whiteSpace: "nowrap",
              opacity: (lead ? 1 - call * 3 : 1) * clamp(k * 2) }}>
              {bw <= 330 && <span style={{ fontSize: 40, fontWeight: 800, color: "#fff" }}>{a.n}</span>}
              <span style={{ fontSize: 40, fontWeight: 900, color: a.c }}>{fmt(vals[i])}</span>
            </div>
          </div>
        );
      })}
      <Caps lines={[["2020: everything was cheap", 1.0, 3.0], ["Then 2022 happened", 3.4, 6.0], ["Business Bay passed the Marina", 6.6, 8.8], ["And Palm Jumeirah in Dubai more than doubled", 9.8, 12.4]]} y={1350} />
      <Sounds list={[[0.3, "swish", 0.28], ...Array.from({ length: 7 }, (_, i) => [T0 + (i * (T1 - T0)) / 6, "tick", 0.3] as Snd), [3.5, "riser", 0.15], [7.4, "pop", 0.3],
        [9.6, "whoosh", 0.3], ...tk(10.4, 11.5, 7), [11.6, "impact", 0.35]]} />
    </>
  );
};

// =====================================================================================================================
// m3-14 Line chart with tooltip: white plate above the head; the line draws, a tooltip rides the tip, a bracket shows the gain, plate shrinks to a pill
// =====================================================================================================================
const D14: React.FC = () => {
  const t = useT();
  const pts = [62, 60, 58, 66, 80, 92, 97, 100];      // rent index (k AED / yr for a 1-bed)
  const yrs = ["2019", "2020", "2021", "2022", "2023", "2024", "2025", "2026"];
  const S: BS[] = [
    { at: 0.2, x: 540, y: 262, w: 940, h: 320, r: 36 },
    { at: 9.4, x: 540, y: 320, w: 700, h: 150, r: 75 },
  ];
  const draw = ri(t, 1.0, 6.4, EASE_IO);
  const brk = ri(t, 7.0, 7.7, EASE_IO);
  const PW = 940 - 120, PH = 170, PX = 60, PY = 96;
  const xs = (i: number) => PX + (PW * i) / (pts.length - 1);
  const ys = (v: number) => PY + PH - ((v - 50) / 55) * PH;
  const pos = draw * (pts.length - 1);
  const pi = Math.min(pts.length - 2, Math.floor(pos)), pf = pos - pi;
  const tipX = lerp(xs(pi), xs(pi + 1), pf), tipV = lerp(pts[pi], pts[pi + 1], pf), tipY = ys(tipV);
  const path = pts.map((v, i) => `${i ? "L" : "M"}${xs(i)},${ys(v)}`).join(" ");
  const len = 1100;
  return (
    <>
      <Backdrop />
      <Box S={S} to={12.5} tone="white" scenes={[
        () => (
          <>
            <div style={{ position: "absolute", left: 36, top: 22, display: "flex", alignItems: "baseline", gap: 16 }}>
              <span style={{ fontSize: 40, fontWeight: 900, color: C.ink }}>1-bed rent</span><span style={lab("rgba(0,0,0,0.45)")}>AED K / YEAR</span></div>
            <svg width={940} height={320} style={{ position: "absolute", inset: 0 }}>
              {[0, 1, 2].map((g) => <line key={g} x1={PX} x2={PX + PW} y1={PY + (PH * g) / 2} y2={PY + (PH * g) / 2} stroke="rgba(0,0,0,0.07)" strokeWidth={2} />)}
              <defs><clipPath id="m314c"><rect x={0} y={0} width={tipX} height={320} /></clipPath></defs>
              <path d={`${path} L${xs(pts.length - 1)},${PY + PH} L${PX},${PY + PH} Z`} fill="rgba(10,132,255,0.10)" clipPath="url(#m314c)" />
              <path d={path} fill="none" stroke={C.blue} strokeWidth={7} strokeLinejoin="round" strokeLinecap="round" clipPath="url(#m314c)" strokeDasharray={len} strokeDashoffset={0} />
              {pts.map((v, i) => xs(i) <= tipX + 1 && <circle key={i} cx={xs(i)} cy={ys(v)} r={7} fill="#fff" stroke={C.blue} strokeWidth={4} />)}
              <circle cx={tipX} cy={tipY} r={13} fill={C.blue} stroke="#fff" strokeWidth={4} />
              {/* bracket */}
              <g opacity={brk}>
                <line x1={xs(2)} x2={xs(7)} y1={ys(58)} y2={ys(58)} stroke="#8E8E93" strokeWidth={3} strokeDasharray="8 8" />
                <line x1={xs(7) + 24} x2={xs(7) + 24} y1={ys(58)} y2={lerp(ys(58), ys(100), brk)} stroke={C.green} strokeWidth={6} strokeLinecap="round" />
              </g>
            </svg>
            {yrs.map((y, i) => <div key={y} style={{ position: "absolute", left: xs(i) - 50, width: 100, top: PY + PH + 12, textAlign: "center", ...lab(xs(i) <= tipX + 1 ? "rgba(0,0,0,0.55)" : "rgba(0,0,0,0.18)", 28), letterSpacing: 1 }}>{y}</div>)}
            {/* tooltip rides the tip */}
            <div style={{ position: "absolute", left: clamp(tipX - 80, 20, 940 - 190), top: tipY - 92, height: 66, padding: "0 20px", borderRadius: 18, background: C.ink, color: "#fff",
              display: "flex", alignItems: "center", gap: 6, fontFamily: UI, fontWeight: 900, fontSize: 38, opacity: ri(t, 1.0, 1.3) * (1 - brk) }}>
              <OdoN value={tipV} size={40} color="#fff" />k</div>
            <div style={{ position: "absolute", left: 130, top: 100, opacity: brk }}>
              <Chip k={ri(t, 7.5, 7.9, POP)} bg={C.green} color="#0B2A14" size={40}>+72%</Chip></div>
          </>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 18, color: C.ink }}>
            <svg width={110} height={60}><path d="M5 50 L30 44 L55 48 L80 22 L105 8" fill="none" stroke={C.blue} strokeWidth={7} strokeLinecap="round" strokeLinejoin="round" /></svg>
            <span style={{ fontSize: 56, fontWeight: 900 }}>Rents +72%</span>
          </div>
        ),
      ]} />
      <Caps lines={[["Rents in 2019?", 0.5, 2.4], ["Covid pushed them down", 2.5, 3.6], ["Then they took off", 3.8, 6.8], ["Up 72% from the bottom", 7.0, 9.2], ["Landlords are winning", 9.6, 12.2]]} />
      <Sounds list={[[0.2, "swish", 0.28], [1.0, "riser", 0.12], ...pts.slice(1).map((_, i) => [1.0 + ((i + 1) / 7) * 5.4 - 0.2, "tick", 0.2] as Snd), [6.4, "ding", 0.25],
        [7.0, "swish", 0.22], [7.5, "pop", 0.32], [9.4, "whoosh", 0.28], [12.0, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-15 Ticker tape: a fitted black ticker plate runs area moves above his head; it stops on one, swells into a card, then melts back
// =====================================================================================================================
const D15: React.FC = () => {
  const t = useT();
  const items: [string, number][] = [["Dubai Marina", 3.2], ["JVC", 5.1], ["Downtown", -0.8], ["Dubai Hills", 12.4], ["Business Bay", 4.6], ["Arjan", -1.9], ["Jumeirah", 6.3], ["Al Barsha", 2.2]];
  // speed eases to 0 so the hero item lands in the centre, then runs again
  const stopAt = 3.4, goAt = 9.4;
  const v = 260;
  const travelled = (tt: number) => {
    const a = Math.min(tt, stopAt - 1.2) * v;
    const decel = clamp((tt - (stopAt - 1.2)) / 1.2);
    const b = tt > stopAt - 1.2 ? v * 1.2 * (decel - decel * decel / 2) : 0;
    const c = tt > goAt ? v * Math.pow(tt - goAt, 2) / 1.6 * (tt - goAt < 0.8 ? 1 : 1) : 0;
    return a + b + c;
  };
  const IW = 480;
  const hero = 3;
  const total = items.length * IW;
  const off = travelled(t);
  // shift so the hero is centred when stopped
  const stopOff = travelled(stopAt);
  const base = 540 - (hero * IW + IW / 2) + stopOff;
  const swell = ri(t, 4.0, 4.8, LIQUID) * (1 - ri(t, 8.6, 9.3, EASE_IO));
  const h = lerp(110, 300, swell), w = lerp(940, 900, swell), top = lerp(300, 262, swell);
  const bars = [20, 26, 24, 36, 48, 60, 78, 100];
  return (
    <>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - w / 2, top, width: w, height: h * ri(t, 0.1, 0.6, LIQUID), borderRadius: lerp(55, 40, swell), background: "#0C0C0D",
        border: "1.5px solid rgba(255,255,255,0.14)", overflow: "hidden", boxShadow: "0 18px 40px rgba(0,0,0,0.3)", transform: `translateY(${Math.sin(t * 1.3) * 3}px)`, opacity: 1 - ri(t, 12.4, 12.9) }}>
        {/* ticker strip */}
        <div style={{ position: "absolute", left: 0, top: 0, height: 110, width: "100%", opacity: 1 - clamp(swell * 1.6), WebkitMaskImage: "linear-gradient(90deg, transparent 0, #000 60px, #000 calc(100% - 60px), transparent 100%)", maskImage: "linear-gradient(90deg, transparent 0, #000 60px, #000 calc(100% - 60px), transparent 100%)" }}>
          {Array.from({ length: items.length }, (_, k) => {
            const j = k % items.length;
            let x = base + k * IW - off - (540 - w / 2);
            x = (((x + IW) % total) + total) % total - IW;
            const [n, p] = items[j];
            const isHero = j === hero && Math.abs(x + IW / 2 - w / 2) < IW;
            return (
              <div key={k} style={{ position: "absolute", left: x, top: 0, width: IW, height: 110, display: "flex", alignItems: "center", justifyContent: "center", gap: 14,
                fontFamily: UI, whiteSpace: "nowrap", opacity: isHero || t < stopAt - 0.3 || t > goAt ? 1 : 0.35 }}>
                <span style={{ fontSize: 40, fontWeight: 800, color: "#fff" }}>{n}</span>
                <span style={{ fontSize: 38, fontWeight: 900, color: p > 0 ? C.green : C.red }}>{p > 0 ? "▲" : "▼"} {Math.abs(p).toFixed(1)}%</span>
              </div>
            );
          })}
        </div>
        {/* swollen card */}
        <div style={{ position: "absolute", inset: 0, opacity: clamp(swell * 2 - 0.8), padding: "28px 40px", boxSizing: "border-box", color: "#fff", fontFamily: UI }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 50, fontWeight: 900 }}>Dubai Hills</span>
            <span style={{ display: "flex", alignItems: "baseline", gap: 4, color: C.green, fontSize: 52, fontWeight: 900 }}>▲<OdoN value={12 * ri(t, 4.8, 6.0)} size={56} color={C.green} />%</span>
          </div>
          <div style={lab()}>VILLA PRICES · LAST 12 MONTHS</div>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 12, height: 110, marginTop: 14 }}>
            {bars.map((b, i) => <div key={i} style={{ flex: 1, height: `${b * ri(t, 5.0 + i * 0.12, 5.5 + i * 0.12, LIQUID)}%`, borderRadius: 8, background: i === bars.length - 1 ? C.green : "#3A3A3C" }} />)}
          </div>
        </div>
      </div>
      <Caps lines={[["Every area moves differently", 0.4, 3.3], ["But look at Dubai Hills in Dubai", 3.5, 6.2], ["Up 12% in a year", 6.3, 8.6], ["Pick the area, not the hype", 9.4, 12.2]]} />
      <Sounds list={[[0.1, "swish", 0.28], ...tk(0.4, 2.0, 6, "tick", 0.1), [3.3, "tick", 0.3], [4.0, "whoosh", 0.3], ...tk(4.8, 5.9, 7), [6.0, "ding", 0.28],
        ...bars.map((_, i) => [5.0 + i * 0.12, "pop", 0.1] as Snd), [8.6, "swish", 0.28], [9.4, "whoosh", 0.22], [12.4, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-16 Checklist: full-screen coral; a white card ticks five off-plan checks with a % bar, then shrinks into a signed pill
// =====================================================================================================================
const D16: React.FC = () => {
  const t = useT();
  const items = [
    { n: "Project is registered", at: 1.4 },
    { n: "Money goes to escrow", at: 2.9 },
    { n: "Payment plan in writing", at: 4.4 },
    { n: "Developer delivered before", at: 5.9 },
    { n: "Late-handover penalty", at: 7.4 },
  ];
  const done = items.filter((it) => t >= it.at + 0.3).length;
  const pct = items.reduce((s, it) => s + 20 * ri(t, it.at + 0.1, it.at + 0.6, EASE_IO), 0);
  const fold = ri(t, 9.0, 9.8, EASE_IO);
  const sign = ri(t, 10.1, 11.4, EASE_IO);
  const W = lerp(920, 760, fold), H = lerp(860, 260, fold), X = 540 - W / 2, Y = lerp(390, 560, fold);
  const born = ri(t, 0.1, 0.7, LIQUID);
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#FF6F59" }} />
      <div style={{ position: "absolute", left: 80, right: 80, top: 270, fontFamily: UI, fontWeight: 900, fontSize: 64, color: "#fff", lineHeight: 1.05, opacity: ri(t, 0.2, 0.6) * (1 - fold) }}>
        Before you sign off-plan</div>
      <div style={{ position: "absolute", left: X, top: Y, width: W, height: H * born, borderRadius: lerp(40, 130, fold), background: "#fff", overflow: "hidden",
        boxShadow: "0 24px 50px rgba(120,30,10,0.25)", transform: float(t, 3, 3), fontFamily: UI, color: C.ink }}>
        {/* progress header */}
        <div style={{ position: "absolute", left: 50, right: 50, top: 44, opacity: 1 - clamp(fold * 2.2) }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
            <span style={lab("rgba(0,0,0,0.45)", 30)}>CHECKED</span>
            <span style={{ display: "flex", alignItems: "baseline", fontWeight: 900, fontSize: 56 }}><OdoN value={pct} size={60} color={C.ink} />%</span>
          </div>
          <div style={{ height: 18, borderRadius: 9, background: "#F2F2F7", marginTop: 14, overflow: "hidden" }}>
            <div style={{ height: "100%", width: `${pct}%`, background: pct >= 99.5 ? C.green : "#FF6F59", borderRadius: 9 }} />
          </div>
        </div>
        {items.map((it, i) => {
          const k = ri(t, it.at, it.at + 0.4, POP);
          const tick = ri(t, it.at + 0.05, it.at + 0.35, EASE_IO);
          const row = ri(t, 0.4 + i * 0.12, 0.8 + i * 0.12);
          return (
            <div key={it.n} style={{ position: "absolute", left: 50, right: 50, top: 200 + i * 128, height: 104, display: "flex", alignItems: "center", gap: 28,
              opacity: row * (1 - clamp(fold * 2.2)), transform: `translateX(${(1 - row) * 40}px)`, borderTop: i ? "2px solid #F2F2F7" : undefined }}>
              <div style={{ width: 72, height: 72, borderRadius: 20, border: `5px solid ${tick > 0 ? C.green : "#D1D1D6"}`, background: tick > 0.4 ? C.green : "#fff", boxSizing: "border-box",
                display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + Math.sin(k * Math.PI) * 0.15})`, flexShrink: 0 }}>
                <svg width={44} height={44}><path d="M8 23 L18 33 L37 11" fill="none" stroke="#fff" strokeWidth={7} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={50} strokeDashoffset={50 * (1 - tick)} /></svg>
              </div>
              <span style={{ fontSize: 46, fontWeight: 700, color: i < done ? C.ink : "#8E8E93" }}>{it.n}</span>
            </div>
          );
        })}
        {/* signed pill */}
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 26, opacity: clamp(fold * 2.2 - 0.9) }}>
          <div style={{ width: 120, height: 120, borderRadius: 60, background: C.green, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 70, color: "#fff", fontWeight: 900,
            transform: `scale(${ri(t, 9.25, 9.65, POP)})` }}>✓</div>
          <div>
            <div style={lab("rgba(0,0,0,0.45)", 30)}>SAFE TO SIGN</div>
            <svg width={400} height={100}>
              <path d="M6 70 C 40 10, 60 10, 70 60 S 100 90, 120 40 S 160 10, 170 60 S 210 80, 240 40 C 260 20, 280 70, 300 50 S 360 30, 394 46" fill="none" stroke={C.ink} strokeWidth={6}
                strokeLinecap="round" strokeDasharray={700} strokeDashoffset={700 * (1 - sign)} />
              <line x1={0} x2={400} y1={92} y2={92} stroke="#D1D1D6" strokeWidth={3} />
            </svg>
          </div>
        </div>
      </div>
      <Caps lines={[["Is it registered?", 1.2, 2.8], ["Does your money go to escrow?", 2.9, 4.3], ["Payment plan in writing", 4.4, 5.8], ["Have they delivered before?", 5.9, 7.3], ["And a late-handover penalty", 7.4, 8.9], ["Then you sign", 10.0, 12.4]]} y={1340} />
      <Sounds list={[[0.1, "swish", 0.28], ...items.flatMap((it) => [[it.at, "tick", 0.32], [it.at + 0.1, "pop", 0.22]] as Snd[]), [7.9, "ding", 0.32], [9.0, "whoosh", 0.3],
        [9.25, "pop", 0.35], [10.1, "swish", 0.18], [10.7, "swish", 0.14], [11.4, "ding", 0.25]]} />
    </>
  );
};

// =====================================================================================================================
// m3-17 Star ratings: full-screen indigo; one card fills stars to 4.8, grows a review breakdown, then splits into a two-developer comparison
// =====================================================================================================================
const Stars: React.FC<{ v: number; size: number; color?: string; off?: string; uid: string }> = ({ v, size, color = C.gold, off = "#E5E5EA", uid }) => (
  <div style={{ display: "flex", gap: size * 0.12 }}>
    {[0, 1, 2, 3, 4].map((i) => {
      const f = clamp(v - i);
      return (
        <svg key={i} width={size} height={size} viewBox="0 0 24 24" style={{ transform: `scale(${1 + Math.sin(f * Math.PI) * 0.18})` }}>
          <defs><clipPath id={`m317s${uid}${i}`}><rect x={0} y={0} width={24 * f} height={24} /></clipPath></defs>
          <path d="M12 2 L14.9 8.6 L22 9.3 L16.6 14 L18.2 21 L12 17.3 L5.8 21 L7.4 14 L2 9.3 L9.1 8.6 Z" fill={off} />
          <path d="M12 2 L14.9 8.6 L22 9.3 L16.6 14 L18.2 21 L12 17.3 L5.8 21 L7.4 14 L2 9.3 L9.1 8.6 Z" fill={color} clipPath={`url(#m317s${uid}${i})`} />
        </svg>
      );
    })}
  </div>
);
const D17: React.FC = () => {
  const t = useT();
  const fill = ri(t, 0.9, 2.9, EASE_IO);
  const S: BS[] = [
    { at: 0.2, x: 540, y: 520, w: 880, h: 400, r: 44, bg: "#FFFFFF" },
    { at: 4.0, x: 540, y: 420, w: 880, h: 700, r: 44, bg: "#FFFFFF" },
    { at: 8.4, x: 540, y: 420, w: 940, h: 620, r: 44, bg: "#FFFFFF" },
  ];
  const dist = [78, 14, 5, 2, 1];
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: C.indigo }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 280, textAlign: "center", fontFamily: SERIF, fontSize: 80, color: "#fff", opacity: ri(t, 0.2, 0.6) }}>
        {t < 8.4 ? "Check the developer" : "Same price. Not the same."}</div>
      <Box S={S} to={13} tone="white" float={false} scenes={[
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, color: C.ink }}>
            <div style={lab("rgba(0,0,0,0.45)", 30)}>DEVELOPER A · BUYER REVIEWS</div>
            <div style={{ display: "flex", alignItems: "center", gap: 30 }}>
              <OdoN value={48 * fill} size={130} color={C.ink} dec={1} />
              <Stars v={4.8 * fill} size={84} uid="a" />
            </div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 10, fontSize: 36, fontWeight: 700, color: "#6C6C70" }}>
              from <OdoN value={1240 * ri(t, 1.2, 3.2)} size={40} color={C.ink} /> owners</div>
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, padding: "50px 56px", boxSizing: "border-box", color: C.ink }}>
            <div style={{ display: "flex", alignItems: "center", gap: 26 }}>
              <OdoN value={48} size={110} color={C.ink} dec={1} />
              <div><Stars v={4.8} size={60} uid="b" /><div style={{ fontSize: 34, fontWeight: 700, color: "#6C6C70", marginTop: 6 }}>1,240 owners</div></div>
            </div>
            {dist.map((d, i) => {
              const k = ri(t, 4.5 + i * 0.25, 5.3 + i * 0.25, EASE_IO);
              return (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 20, marginTop: 26 }}>
                  <span style={{ width: 70, fontSize: 38, fontWeight: 800 }}>{5 - i}★</span>
                  <div style={{ flex: 1, height: 34, borderRadius: 17, background: "#F2F2F7", overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${d * k}%`, background: i === 0 ? C.gold : "#C7C7CC", borderRadius: 17 }} />
                  </div>
                  <span style={{ width: 90, textAlign: "right", fontSize: 36, fontWeight: 800 }}>{Math.round(d * k)}%</span>
                </div>
              );
            })}
            <div style={{ marginTop: 30, display: "flex", gap: 14 }}>
              <Chip k={ri(t, 6.6, 7.0, POP)} bg="rgba(48,209,88,0.15)" color="#1E8E3E" size={34}>✓ On time</Chip>
              <Chip k={ri(t, 6.9, 7.3, POP)} bg="rgba(48,209,88,0.15)" color="#1E8E3E" size={34}>✓ Build quality</Chip>
            </div>
          </div>
        ),
        () => (
          <div style={{ position: "absolute", inset: 0, display: "flex", color: C.ink }}>
            {[{ n: "Developer A", v: 4.8, c: C.green, tag: "Handed over on time" }, { n: "Developer B", v: 3.1, c: C.red, tag: "14 months late" }].map((d, i) => {
              const k = ri(t, 8.8 + i * 0.5, 10.2 + i * 0.5, EASE_IO);
              return (
                <div key={d.n} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22, borderLeft: i ? "2px solid #F2F2F7" : undefined }}>
                  <div style={lab("rgba(0,0,0,0.45)", 30)}>{d.n.toUpperCase()}</div>
                  <OdoN value={d.v * 10 * k} size={130} color={d.c} dec={1} />
                  <Stars v={d.v * k} size={66} uid={`c${i}`} />
                  <Chip k={ri(t, 10.6 + i * 0.4, 11.0 + i * 0.4, POP)} bg={i ? "rgba(255,69,58,0.12)" : "rgba(48,209,88,0.15)"} color={i ? C.red : "#1E8E3E"} size={32}>{d.tag}</Chip>
                </div>
              );
            })}
          </div>
        ),
      ]} />
      <Caps lines={[["Look up the developer first", 0.6, 3.9], ["78% give it five stars", 4.4, 8.2], ["The other one? 3.1", 9.4, 12.4]]} y={1340} />
      <Sounds list={[[0.2, "whoosh", 0.28], ...[0, 1, 2, 3, 4].map((i) => [0.9 + i * 0.4, "pop", 0.2] as Snd), [3.0, "ding", 0.3], [4.0, "whoosh", 0.28],
        ...dist.map((_, i) => [4.5 + i * 0.25, "tick", 0.2] as Snd), [6.6, "pop", 0.28], [6.9, "pop", 0.28], [8.4, "whoosh", 0.3], ...tk(8.8, 10.6, 10), [10.6, "pop", 0.3], [11.0, "impact", 0.3]]} />
    </>
  );
};

// =====================================================================================================================
// m3-18 Spreadsheet: full-screen sheet; a selection box walks the cells, formulas type in the bar, then the yield cell lifts out into a hero card
// =====================================================================================================================
const D18: React.FC = () => {
  const t = useT();
  const rows: { a: string; v: number; f?: string; at: number; pct?: boolean; neg?: boolean }[] = [
    { a: "Price", v: 1200000, at: 1.0 },
    { a: "Rent / year", v: 90000, at: 2.2 },
    { a: "Service charge", v: 18000, at: 3.4, neg: true },
    { a: "Net rent", v: 72000, f: "=B3-B4", at: 4.8 },
    { a: "Net yield", v: 60, f: "=B5/B2", at: 6.6, pct: true },
  ];
  let sel = 0;
  rows.forEach((rw, i) => { if (t >= rw.at - 0.4) sel = i; });
  const selK = rows.reduce((s, rw, i) => i === 0 ? 0 : s + ri(t, rw.at - 0.6, rw.at - 0.3, EASE_IO), 0);
  const lift = ri(t, 8.6, 9.5, EASE_IO);
  const cmp = ri(t, 10.4, 11.0, EASE_IO);
  const GX = 40, GY = 520, colA = 90, colB = 470, colC = 460, RH = 110;
  const cur = rows[sel];
  const fText = cur.f ? typed(cur.f, t, cur.at - 0.3, 0.07) : fmt(cur.v * (cur.pct ? 0 : 1)).replace(/^0$/, "");
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#FFFFFF" }} />
      {/* toolbar + formula bar */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 250, height: 110, background: "#F6F7F8", borderBottom: "2px solid #E3E5E8", display: "flex", alignItems: "center", gap: 20, padding: "0 40px",
        fontFamily: MONO, opacity: 1 - lift * 0.5 }}>
        <span style={{ fontSize: 34, fontWeight: 700, color: "#6C6C70", width: 80 }}>B{sel + 2}</span>
        <span style={{ fontSize: 40, fontWeight: 700, color: "#1F7A44" }}>fx</span>
        <span style={{ fontSize: 42, fontWeight: 700, color: C.ink, whiteSpace: "nowrap" }}>{cur.f ? fText : cur.pct ? "" : fmt(cur.v * ri(t, cur.at, cur.at + 0.6))}
          {Math.floor(t * 2.5) % 2 === 0 && <span style={{ color: "#1F7A44" }}>|</span>}</span>
      </div>
      {/* grid */}
      <div style={{ position: "absolute", left: GX, top: GY - 70, opacity: 1 - lift * 0.75 }}>
        <div style={{ display: "flex", height: 70 }}>
          {[["", colA], ["A", colB], ["B", colC]].map(([n, w]) => <div key={n as string} style={{ width: w as number, display: "flex", alignItems: "center", justifyContent: "center",
            background: "#F6F7F8", border: "1px solid #E3E5E8", ...lab(n === "B" ? "#1F7A44" : "#8E8E93", 28) }}>{n}</div>)}
        </div>
        {[1, ...rows.map((_, i) => i + 2), 7].map((rn, i) => {
          const rw = i >= 1 && i <= rows.length ? rows[i - 1] : null;
          const k = rw ? ri(t, rw.at, rw.at + 0.6) : 0;
          return (
            <div key={rn} style={{ display: "flex", height: RH }}>
              <div style={{ width: colA, display: "flex", alignItems: "center", justifyContent: "center", background: "#F6F7F8", border: "1px solid #E3E5E8", ...lab("#8E8E93", 28) }}>{rn}</div>
              <div style={{ width: colB, display: "flex", alignItems: "center", padding: "0 24px", border: "1px solid #E3E5E8", boxSizing: "border-box", fontFamily: UI, fontSize: 42,
                fontWeight: i === 0 ? 900 : 600, color: C.ink }}>{i === 0 ? "1-bed, JVC" : rw ? <span style={{ opacity: ri(t, rw.at - 0.6, rw.at - 0.3) }}>{rw.a}</span> : ""}</div>
              <div style={{ width: colC, display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "0 24px", border: "1px solid #E3E5E8", boxSizing: "border-box",
                background: rw?.pct && k > 0.9 ? "#E3F6EA" : undefined, fontFamily: UI, fontWeight: 800, fontSize: 44, color: rw?.neg ? C.red : rw?.pct ? "#1F7A44" : C.ink, opacity: k > 0 ? 1 : 0 }}>
                {rw && (rw.neg ? "−" : "")}{rw && <OdoN value={rw.v * k} size={44} color={rw.neg ? C.red : rw.pct ? "#1F7A44" : C.ink} dec={rw.pct ? 1 : 0} digits={rw.pct ? 2 : String(rw.v).length} />}{rw?.pct ? "%" : ""}
              </div>
            </div>
          );
        })}
      </div>
      {/* selection box: the through-line */}
      <div style={{ position: "absolute", left: lerp(GX + colA + colB - 3, 90, lift), top: lerp(GY + RH + selK * RH - 3, 760, lift), width: lerp(colC + 6, 900, lift), height: lerp(RH + 6, 420, lift),
        border: `${lerp(5, 0, lift)}px solid #1F7A44`, borderRadius: lerp(4, 44, lift), background: lift > 0 ? `rgba(31,122,68,${lift})` : "transparent", boxSizing: "border-box",
        opacity: ri(t, 0.6, 0.9), boxShadow: lift > 0.5 ? "0 24px 50px rgba(0,0,0,0.2)" : undefined }}>
        <div style={{ position: "absolute", right: -9, bottom: -9, width: 14, height: 14, background: "#1F7A44", border: "3px solid #fff", opacity: 1 - lift }} />
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6, opacity: ri(t, 9.2, 9.6), color: "#fff", fontFamily: UI }}>
          <div style={lab("rgba(255,255,255,0.75)", 30)}>NET RENTAL YIELD</div>
          <div style={{ display: "flex", alignItems: "baseline" }}><OdoN value={60} size={170} color="#fff" dec={1} /><span style={{ fontSize: 120, fontWeight: 900 }}>%</span></div>
          <div style={{ display: "flex", gap: 14, opacity: cmp, transform: `translateY(${(1 - cmp) * 20}px)` }}>
            <span style={{ fontSize: 36, fontWeight: 700, color: "rgba(255,255,255,0.8)" }}>vs bank deposit</span><span style={{ fontSize: 36, fontWeight: 900 }}>4.0%</span></div>
        </div>
      </div>
      <Caps lines={[["Price: 1.2 million", 1.0, 2.1], ["Rent: 90k a year", 2.2, 3.3], ["Minus service charge", 3.4, 4.7], ["That's your net rent", 4.8, 6.5], ["Divide by the price", 6.6, 8.5], ["6% net. Every year.", 9.4, 12.4]]} y={1350} />
      <Sounds list={[[0.3, "swish", 0.25], ...rows.flatMap((rw, i) => [[rw.at - 0.6, "tick", 0.25], ...(rw.f ? tk(rw.at - 0.3, rw.at + 0.1, 4, "type", 0.12) : []), [rw.at + 0.6, "pop", 0.18]] as Snd[]),
        [7.2, "ding", 0.3], [8.6, "whoosh", 0.32], [9.5, "impact", 0.3], [10.4, "pop", 0.28]]} />
    </>
  );
};

// =====================================================================================================================
// m3-19 Phone feed: full-screen sand; a phone scrolls a listing feed, stops, hearts one, the card opens into the detail screen, viewing booked
// =====================================================================================================================
const House: React.FC<{ c: string; w: number; h: number; v?: number }> = ({ c, w, h, v = 0 }) => (
  <div style={{ position: "relative", width: w, height: h, background: c, overflow: "hidden" }}>
    <div style={{ position: "absolute", left: "-10%", right: "-10%", bottom: 0, height: "22%", background: "rgba(255,255,255,0.35)" }} />
    {v % 2 === 0 ? (
      <>
        <div style={{ position: "absolute", left: "24%", bottom: "18%", width: "52%", height: "40%", background: "#fff", borderRadius: 6 }} />
        <div style={{ position: "absolute", left: "18%", bottom: "57%", width: "64%", height: "24%", background: "#2C2C2E", clipPath: "polygon(50% 0,100% 100%,0 100%)" }} />
        <div style={{ position: "absolute", left: "45%", bottom: "18%", width: "10%", height: "20%", background: C.orange }} />
      </>
    ) : (
      <>
        {[0, 1, 2].map((b) => <div key={b} style={{ position: "absolute", left: `${14 + b * 26}%`, bottom: "18%", width: "20%", height: `${46 + b * 14}%`, background: "#fff", borderRadius: "6px 6px 0 0" }} />)}
      </>
    )}
  </div>
);
const D19: React.FC = () => {
  const t = useT();
  const feed = [
    { n: "Townhouse · 3 bed", p: "3,200,000", c: "#F5D9B0" },
    { n: "Sea-view flat · 2 bed", p: "2,400,000", c: "#BFE0F7" },
    { n: "Garden villa · 4 bed", p: "5,800,000", c: "#C9E6B8" },
    { n: "Loft · 1 bed", p: "1,150,000", c: "#E8C9E0" },
    { n: "Penthouse · 3 bed", p: "7,900,000", c: "#D7D2F5" },
    { n: "Corner villa · 5 bed", p: "8,600,000", c: "#F7E3A1" },
  ];
  const CH = 470, PW = 600, PH = 1180, PX = 240, PY = 300;
  // scroll: fast fling, settle on card 4 (index 4)
  const target = 4 * (CH + 24) - 60;
  const sc = interpolate(t, [0.8, 3.6], [0, target], { easing: EASE, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const heart = ri(t, 4.4, 4.75, POP);
  const open = ri(t, 5.6, 6.5, EASE_IO);
  const press = ri(t, 9.0, 9.15) * (1 - ri(t, 9.15, 9.35));
  const toast = ri(t, 9.4, 9.9, LIQUID) * (1 - ri(t, 12.0, 12.4));
  const born = ri(t, 0.1, 0.8, LIQUID);
  const speed = Math.abs(interpolate(t + 0.03, [0.8, 3.6], [0, target], { easing: EASE, extrapolateLeft: "clamp", extrapolateRight: "clamp" }) - sc);
  const hero = feed[4];
  const heroTop = 4 * (CH + 24) - sc + 140;
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#EADFCB" }} />
      <div style={{ position: "absolute", left: PX, top: PY, width: PW, height: PH, borderRadius: 86, background: "#111", padding: 16, boxSizing: "border-box",
        transform: `translateY(${(1 - born) * 300}px) ${float(t, 0, 3)}`, opacity: clamp(born * 2), boxShadow: "0 40px 80px rgba(80,50,10,0.3)" }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 72, background: "#F7F7F9", overflow: "hidden", fontFamily: UI, color: C.ink }}>
          {/* feed */}
          <div style={{ position: "absolute", left: 0, right: 0, top: 140 - sc, filter: speed > 6 ? `blur(${Math.min(4, speed / 6)}px)` : undefined, opacity: 1 - open }}>
            {feed.map((f, i) => (
              <div key={i} style={{ position: "absolute", left: 26, right: 26, top: i * (CH + 24), height: CH, borderRadius: 34, background: "#fff", overflow: "hidden", boxShadow: "0 4px 14px rgba(0,0,0,0.06)" }}>
                <House c={f.c} w={PW - 32 - 52} h={300} v={i} />
                <div style={{ padding: "18px 26px" }}>
                  <div style={{ fontSize: 36, fontWeight: 800 }}>{f.n}</div>
                  <div style={{ fontSize: 36, fontWeight: 800, color: C.blue, marginTop: 6 }}>AED {f.p}</div>
                </div>
                {i === 4 && <div style={{ position: "absolute", right: 22, top: 22, width: 80, height: 80, borderRadius: 40, background: "rgba(255,255,255,0.92)", display: "flex", alignItems: "center",
                  justifyContent: "center", fontSize: 44, transform: `scale(${1 + Math.sin(heart * Math.PI) * 0.35})` }}>{heart > 0.4 ? "❤️" : "🤍"}</div>}
              </div>
            ))}
          </div>
          {/* opened card: grows from the feed card to full screen */}
          {open > 0 && (
            <div style={{ position: "absolute", left: lerp(26, 0, open), right: lerp(26, 0, open), top: lerp(heroTop, 0, open), height: lerp(CH, PH - 32, open), borderRadius: lerp(34, 0, open), background: "#fff", overflow: "hidden" }}>
              <House c={hero.c} w={lerp(PW - 84, PW - 32, open)} h={lerp(300, 520, open)} v={4} />
              <div style={{ padding: "24px 32px" }}>
                <div style={{ fontSize: 42, fontWeight: 900 }}>{hero.n}</div>
                <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginTop: 10 }}><span style={{ fontSize: 30, fontWeight: 800, color: "#8E8E93" }}>AED</span>
                  <OdoN value={lerp(6000000, 7900000, ri(t, 6.4, 7.6))} size={50} color={C.ink} /></div>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 18 }}>
                  {[["🛏", "3 bed", 7.0], ["🌊", "Sea view", 7.3], ["📐", "3,900 sq ft", 7.6]].map(([e, n, at]) =>
                    <Chip key={n as string} k={ri(t, at as number, (at as number) + 0.3, POP)} bg="#F2F2F7" color={C.ink} size={30}>{e} {n}</Chip>)}
                </div>
              </div>
              <div style={{ position: "absolute", left: 30, right: 30, bottom: 50, height: 104, borderRadius: 52, background: C.blue, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 40, fontWeight: 800, opacity: ri(t, 8.0, 8.4), transform: `scale(${(0.9 + 0.1 * ri(t, 8.0, 8.5, POP)) * (1 - press * 0.08)})` }}>Book a viewing</div>
            </div>
          )}
          {/* app bar */}
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 130, background: "#F7F7F9", display: "flex", alignItems: "flex-end", justifyContent: "space-between",
            padding: "0 34px 18px", boxSizing: "border-box", opacity: 1 - open }}>
            <span style={{ fontSize: 48, fontWeight: 900 }}>Homes</span><span style={{ fontSize: 30, fontWeight: 700, color: "#8E8E93" }}>1,284 for sale</span>
          </div>
          {/* toast */}
          <div style={{ position: "absolute", left: 30, right: 30, top: lerp(-140, 70, toast), height: 120, borderRadius: 36, background: C.ink, color: "#fff", display: "flex", alignItems: "center", gap: 18,
            padding: "0 28px", opacity: clamp(toast * 2) }}>
            <span style={{ fontSize: 46 }}>📅</span><div><div style={lab(C.green, 26)}>BOOKED</div><div style={{ fontSize: 36, fontWeight: 800 }}>Saturday · 11:00</div></div>
          </div>
        </div>
      </div>
      <Sounds list={[[0.1, "whoosh", 0.3], [0.8, "swish", 0.3], ...tk(1.0, 3.0, 8, "tick", 0.08), [4.4, "pop", 0.35], [5.6, "whoosh", 0.3], ...tk(6.4, 7.5, 6), [7.0, "pop", 0.2], [7.3, "pop", 0.2],
        [7.6, "pop", 0.2], [8.0, "swish", 0.2], [9.05, "tick", 0.35], [9.4, "ding", 0.35], [12.0, "swish", 0.2]]} />
    </>
  );
};

// =====================================================================================================================
// m3-20 KPI dashboard: full-screen navy; four tiles count up with sparklines, then the volume tile takes over as a monthly bar chart
// =====================================================================================================================
const D20: React.FC = () => {
  const t = useT();
  const tiles = [
    { n: "Deals closed", v: 38, pre: "", suf: "", c: C.green, spark: [3, 4, 3, 5, 6, 8, 9] },
    { n: "Sales volume", v: 142, pre: "AED ", suf: "M", c: C.gold, spark: [10, 14, 12, 18, 22, 30, 36] },
    { n: "Days to sell", v: 21, pre: "", suf: "", c: C.teal, spark: [40, 36, 34, 30, 26, 23, 21] },
    { n: "New leads", v: 1920, pre: "", suf: "", c: C.pink, spark: [150, 190, 220, 260, 300, 380, 420] },
  ];
  const take = ri(t, 7.0, 7.9, EASE_IO);
  const months = [8, 11, 9, 14, 17, 15, 21, 26, 21];
  const mNames = ["J", "F", "M", "A", "M", "J", "J", "A", "S"];
  const TW = 450, TH = 330, G = 30, X0 = 60, Y0 = 440;
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: "#0A1430" }} />
      <div style={{ position: "absolute", left: X0, top: 280, fontFamily: UI, color: "#fff", opacity: ri(t, 0.1, 0.5) }}>
        <div style={lab("rgba(255,255,255,0.55)", 28)}>EQT · JAN–SEP 2026 · ILLUSTRATIVE</div>
        <div style={{ fontSize: 64, fontWeight: 900, marginTop: 8 }}>{take < 0.5 ? "This year so far" : "Volume by month"}</div>
      </div>
      {tiles.map((tl, i) => {
        const a = ri(t, 0.5 + i * 0.25, 1.1 + i * 0.25, LIQUID);
        const cnt = ri(t, 1.0 + i * 0.6, 2.6 + i * 0.6, EASE);
        const isHero = i === 1;
        const gx = X0 + (i % 2) * (TW + G), gy = Y0 + Math.floor(i / 2) * (TH + G);
        // others shrink into a row of small chips under the hero
        const sx = X0 + [0, 0, 1, 2][i] * 330, sy = 1190;
        const x = isHero ? lerp(gx, X0, take) : lerp(gx, sx, take);
        const y = isHero ? lerp(gy, Y0, take) : lerp(gy, sy, take);
        const w = isHero ? lerp(TW, 960, take) : lerp(TW, 300, take);
        const h = isHero ? lerp(TH, 720, take) : lerp(TH, 140, take);
        const mx = Math.max(...tl.spark), mn = Math.min(...tl.spark);
        const sp = tl.spark.map((v, j) => `${j ? "L" : "M"}${(j / 6) * 360},${70 - ((v - mn) / (mx - mn)) * 64}`).join(" ");
        const draw = ri(t, 1.2 + i * 0.6, 2.8 + i * 0.6, EASE_IO);
        return (
          <div key={tl.n} style={{ position: "absolute", left: x, top: y, width: w, height: h * a, borderRadius: 36, background: "#14224A", border: "1.5px solid rgba(255,255,255,0.1)",
            overflow: "hidden", fontFamily: UI, color: "#fff", transform: float(t, i, 2) }}>
            <div style={{ position: "absolute", left: 34, top: lerp(30, isHero ? 34 : 22, take), ...lab("rgba(255,255,255,0.6)", 28) }}>{tl.n.toUpperCase()}</div>
            <div style={{ position: "absolute", left: 34, top: lerp(80, isHero ? 84 : 62, take), display: "flex", alignItems: "baseline", gap: 4, color: tl.c,
              fontWeight: 900, fontSize: lerp(60, isHero ? 80 : 46, take) }}>
              {tl.pre && <span style={{ fontSize: lerp(40, isHero ? 52 : 30, take) }}>{tl.pre}</span>}
              <OdoN value={tl.v * cnt} size={lerp(84, isHero ? 110 : 52, take)} color={tl.c} />
              {tl.suf && <span>{tl.suf}</span>}
            </div>
            <svg width={400} height={80} style={{ position: "absolute", left: 34, top: 200, opacity: 1 - take }}>
              <path d={sp} fill="none" stroke={tl.c} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={600} strokeDashoffset={600 * (1 - draw)} />
            </svg>
            {isHero && take > 0 && (
              <div style={{ position: "absolute", left: 34, right: 34, bottom: 40, height: 440, display: "flex", alignItems: "flex-end", gap: 18, opacity: ri(t, 7.6, 7.9) }}>
                {months.map((m, j) => {
                  const k = ri(t, 7.8 + j * 0.14, 8.4 + j * 0.14, LIQUID);
                  const best = j === 7;
                  return (
                    <div key={j} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 10, height: "100%", justifyContent: "flex-end" }}>
                      {best && <Chip k={ri(t, 9.6, 10.0, POP)} bg={C.gold} color={C.ink} size={28}>26M</Chip>}
                      <div style={{ width: "100%", height: (m / 26) * 330 * k, borderRadius: 12, background: best ? C.gold : "rgba(255,214,10,0.35)" }} />
                      <div style={lab("rgba(255,255,255,0.55)", 28)}>{mNames[j]}</div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
      <Caps lines={[["38 deals this year", 1.0, 2.6], ["142 million in sales", 2.7, 4.2], ["21 days to sell, on average", 4.3, 5.6], ["Almost 2,000 new leads", 5.7, 6.9], ["August was the best month", 9.4, 12.4]]} y={1360} />
      <Sounds list={[...tiles.map((_, i) => [0.5 + i * 0.25, "pop", 0.2] as Snd), ...tiles.flatMap((_, i) => [...tk(1.0 + i * 0.6, 2.4 + i * 0.6, 5, "tick", 0.1), [2.6 + i * 0.6, "ding", 0.18]] as Snd[]),
        [7.0, "whoosh", 0.32], ...months.map((_, j) => [7.8 + j * 0.14, "tick", 0.16] as Snd), [9.6, "pop", 0.32], [12.5, "swish", 0.2]]} />
    </>
  );
};

export const M3: LibItem[] = [
  { id: "m3-01", title: "Price odometer", family: FAM, dur: 12, C: D01,
    note: "Graphite plate above the head: price rolls up, adds per-sq-ft, flips to then-vs-now +69%, ends as a pill. Any 'what it costs' line." },
  { id: "m3-02", title: "Fee calculator chips", family: FAM, dur: 13, C: D02,
    note: "Cream plate: price × 4% = fee chips, fees drop into a receipt, receipt squashes into the real total. For hidden-costs talk." },
  { id: "m3-03", title: "Mortgage sliders", family: FAM, dur: 13, C: D03,
    note: "Full-screen blue: one white card, drag deposit then term, payment rolls; flips into total-interest bars. For mortgage explainers." },
  { id: "m3-04", title: "Rent vs buy table", family: FAM, dur: 13, C: D04,
    note: "Full-screen cream paper: rows draw in, ticks stamp, gold highlight slides to BUY and becomes the verdict card. For any A-vs-B." },
  { id: "m3-05", title: "Viewing to keys timeline", family: FAM, dur: 13, C: D05,
    note: "Soft split (panel pushes Max down): gold dot rides day 1 → 30, one card hands off per step, line collapses into '30 days'. Process talk." },
  { id: "m3-06", title: "Progress rings", family: FAM, dur: 13, C: D06,
    note: "Full-screen black: three rings fill (sold / built / paid), spread into a row, then 'built' becomes the hero with the handover date. Off-plan progress." },
  { id: "m3-07", title: "Filter toggles", family: FAM, dur: 13, C: D07,
    note: "Light glass plate above the head: flip three iOS toggles, match count rolls 1,240 → 12, plate becomes the first match card. 'Narrow it down' lines." },
  { id: "m3-08", title: "Notification stack", family: FAM, dur: 13, C: D08,
    note: "Lock-screen cards drop in above the head and tuck behind each other (enquiry → keys), then fold into a gold 'Closed in 6 days' pill. Speed stories." },
  { id: "m3-09", title: "Client chat thread", family: FAM, dur: 13, C: D09,
    note: "Full-screen warm chat: bubbles born from typing dots, a listing card with rolling price, a green 'viewing booked' card. Client-story moments." },
  { id: "m3-10", title: "Search + results", family: FAM, dur: 13, C: D10,
    note: "Full-screen white: query types, results stream in, filter chips narrow 1,284 → 37, top result grows into the hero card. 'What buyers search' lines." },
  { id: "m3-11", title: "Countdown calendar", family: FAM, dur: 13, C: D11,
    note: "Full-screen forest green: days cross off a paper calendar, the grid folds into a flip-clock, then into the price-after-deadline card. Launch / deadline talk." },
  { id: "m3-12", title: "Split-flap price board", family: FAM, dur: 13, C: D12,
    note: "Full-screen gold: a black split-flap board flips one villa's price 2016 → 2026 with mini bars, ×2 stamp slams. 'Same villa, ten years' lines." },
  { id: "m3-13", title: "Area bar race", family: FAM, dur: 13, C: D13,
    note: "Full-screen graphite: price per sq ft by area races 2020 → 2026 with re-ranking, then the leader bar swells into a +119% callout. Market comparisons." },
  { id: "m3-14", title: "Line chart + tooltip", family: FAM, dur: 12.5, C: D14,
    note: "White plate above the head: rent line draws with a tooltip riding the tip, dashed bracket +72%, plate shrinks to a pill. Any trend line." },
  { id: "m3-15", title: "Ticker tape", family: FAM, dur: 13, C: D15,
    note: "Fitted black ticker above the head runs area % moves, brakes on one, swells into a card with bars, melts back and runs. 'Which area' talk." },
  { id: "m3-16", title: "Off-plan checklist", family: FAM, dur: 13, C: D16,
    note: "Full-screen coral: white card ticks five checks with a % bar, then folds into a green 'safe to sign' pill with a signature drawing. Due-diligence lists." },
  { id: "m3-17", title: "Developer star rating", family: FAM, dur: 13, C: D17,
    note: "Full-screen indigo: one card fills stars to 4.8, grows a 5-to-1 breakdown, then splits into Developer A 4.8 vs B 3.1. 'Check the developer' lines." },
  { id: "m3-18", title: "Spreadsheet yield", family: FAM, dur: 13, C: D18,
    note: "Full-screen sheet: selection box walks the cells while formulas type, then the yield cell lifts out as a green 6.0% hero vs bank 4%. ROI maths." },
  { id: "m3-19", title: "Phone listing feed", family: FAM, dur: 13, C: D19,
    note: "Full-screen sand with a phone: feed flings and settles, heart tap, card opens into the detail screen, 'viewing booked' toast. How buyers browse." },
  { id: "m3-20", title: "KPI dashboard", family: FAM, dur: 13, C: D20,
    note: "Full-screen navy: four KPI tiles count up with sparklines, then 'volume' takes over as a monthly bar chart, others shrink to chips. Results / proof." },
];
