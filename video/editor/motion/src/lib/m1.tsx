import React from "react";
import { AbsoluteFill } from "remotion";
import {
  C, UI, SERIF, MONO, DISPLAY, EASE, EASE_IN, EASE_IO, POP, LIQUID, useT, r, lerp, clamp, env, rand, mix,
  Backdrop, Sounds, Plate, Odo, DemoCaption, LibItem,
} from "./common";

// Family m1 — Shape stories & liquid morphs (2D). Each demo acts out one business / real-estate idea with crisp flat
// shapes; formations hand off through SVG goo (liquid merge with crisp edges), never pop. Half sit on a fitted plate
// over Max (free zone y 260-560), half are full-screen colour-block scenes.
const FAM = "Shape stories & liquid morphs";
type SfxName = "whoosh" | "swish" | "pop" | "impact" | "tick" | "type" | "ding" | "riser";
type SL = [number, SfxName, number?][];

// ---------- helpers ----------
/** goo filter with a big user-space region (no clipping at the bbox edge) */
const Goo: React.FC<{ id: string; b?: number }> = ({ id, b = 10 }) => (
  <filter id={id} filterUnits="userSpaceOnUse" x={-400} y={-400} width={1880} height={2720} colorInterpolationFilters="sRGB">
    <feGaussianBlur in="SourceGraphic" stdDeviation={b} result="bl" />
    <feColorMatrix in="bl" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 24 -11" />
  </filter>
);

/** centred text; k = 0..1 (may overshoot for a pop) */
const Txt: React.FC<{ x: number; y: number; size: number; k?: number; color?: string; font?: string; weight?: number; ls?: number;
  children: React.ReactNode; style?: React.CSSProperties; anchor?: "c" | "l" | "r" }> =
  ({ x, y, size, k = 1, color = "#fff", font = UI, weight = 900, ls = -1, children, style, anchor = "c" }) => {
    if (k <= 0.001) return null;
    const tx = anchor === "c" ? "-50%" : anchor === "l" ? "0%" : "-100%";
    return (
      <div style={{ position: "absolute", left: x, top: y, transform: `translate(${tx},-50%) scale(${0.75 + 0.25 * k})`,
        transformOrigin: anchor === "c" ? "50% 50%" : anchor === "l" ? "0% 50%" : "100% 50%",
        opacity: clamp(k * 1.6), fontFamily: font, fontWeight: weight, fontSize: size, color, letterSpacing: ls, whiteSpace: "nowrap", lineHeight: 1.05, ...style }}>
        {children}
      </div>
    );
  };
const Tag: React.FC<Omit<React.ComponentProps<typeof Txt>, "font" | "weight" | "ls" | "size"> & { size?: number }> = (p) =>
  <Txt font={MONO} weight={700} ls={3} size={p.size ?? 30} {...p} />;

/** a word that collapses to a line and re-expands as the next word (flow, never pop) */
const Swap: React.FC<{ t: number; at: number; a: React.ReactNode; b: React.ReactNode; x: number; y: number; dur?: number }> =
  ({ t, at, a, b, x, y, dur = 0.5 }) => {
    const out = r(t, at, at + dur / 2, EASE_IN), inn = r(t, at + dur / 2, at + dur, EASE);
    const sx = t < at + dur / 2 ? 1 - out : inn;
    return (
      <div style={{ position: "absolute", left: x, top: y, transform: `translate(-50%,-50%) scale(${Math.max(0.02, sx)}, ${t < at + dur / 2 ? 1 - out * 0.85 : 0.15 + 0.85 * inn})` }}>
        {t < at + dur / 2 ? a : b}
      </div>
    );
  };

const Full: React.FC<{ bg: string; children: React.ReactNode }> = ({ bg, children }) => <AbsoluteFill style={{ background: bg, overflow: "hidden" }}>{children}</AbsoluteFill>;
const Svg: React.FC<{ w?: number; h?: number; children: React.ReactNode }> = ({ w = 1080, h = 1920, children }) =>
  <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>{children}</svg>;

/** caption for colour scenes (DemoCaption is white-on-video) */
const SceneLine: React.FC<{ text: string; from: number; to: number; y: number; color: string; size?: number; font?: string }> =
  ({ text, from, to, y, color, size = 76, font = SERIF }) => {
    const t = useT();
    if (t < from || t > to) return null;
    const k = env(t, from, to, 0.35, 0.25);
    return <div style={{ position: "absolute", left: 70, right: 180, top: y, textAlign: "center", fontFamily: font, fontSize: size, color, lineHeight: 1.1,
      opacity: k, transform: `translateY(${(1 - k) * 24}px)`, fontWeight: font === UI ? 800 : 400 }}>{text}</div>;
  };

const gearPath = (cx: number, cy: number, R: number, n: number, depth: number, a0: number) => {
  const pts: string[] = [];
  const step = (Math.PI * 2) / n;
  for (let i = 0; i < n; i++) {
    const a = a0 + i * step;
    // trapezoid tooth centred on a
    const ang = [a - step * 0.27, a - step * 0.16, a + step * 0.16, a + step * 0.27];
    const rad = [R - depth * 0.1, R + depth, R + depth, R - depth * 0.1];
    ang.forEach((g, j) => pts.push(`${(cx + Math.cos(g) * rad[j]).toFixed(1)},${(cy + Math.sin(g) * rad[j]).toFixed(1)}`));
    const mid = a + step * 0.5;
    pts.push(`${(cx + Math.cos(mid) * (R - depth * 0.1)).toFixed(1)},${(cy + Math.sin(mid) * (R - depth * 0.1)).toFixed(1)}`);
  }
  return `M ${pts.join(" L ")} Z`;
};

// =====================================================================================================================
// m1-01 Lead funnel: 1,000 dots pour into a funnel as liquid, the level drains past REPLIED / VIEWED / OFFERED,
// three drops fall out and turn into gold buyers.
const M101: React.FC = () => {
  const t = useT();
  const COLS = 40, ROWS = 25, SP = 16, GX = 540 - ((COLS - 1) * SP) / 2, GY = 430;
  const FT = 900, FB = 1230, HW = 380, NW = 32, NB = 1290;
  const hw = (y: number) => lerp(HW, NW, clamp((y - FT) / (FB - FT)));
  const draw = r(t, 1.5, 2.2, EASE_IO);
  const fill = r(t, 2.6, 4.7, EASE_IO);
  const drain = clamp((t - 5) / 3);
  const level = t < 5 ? lerp(NB + 30, FT + 70, fill) : lerp(FT + 70, FB - 6, drain);
  const dots: React.ReactNode[] = [], falling: React.ReactNode[] = [];
  for (let j = 0; j < ROWS; j++) for (let i = 0; i < COLS; i++) {
    const gx = GX + i * SP, gy = GY + j * SP;
    const born = r(t, 0.05 + j * 0.05, 0.25 + j * 0.05, POP);
    const tf = 2.2 + (ROWS - 1 - j) * 0.07 + rand(i * 31 + j) * 0.3;
    const k = r(t, tf, tf + 0.55, EASE_IN);
    if (k <= 0) { dots.push(<circle key={`d${i}_${j}`} cx={gx} cy={gy + Math.sin(t * 2 + i * 0.4) * 2} r={5 * born} fill={C.ink} opacity={0.85} />); continue; }
    if (k >= 1) continue;
    falling.push(<circle key={`f${i}_${j}`} cx={lerp(gx, 540 + (gx - 540) * 0.75, k)} cy={lerp(gy, FT + 60, k)} r={lerp(5, 9, k)} fill={C.blue} />);
  }
  const wave = Array.from({ length: 20 }, (_, i) => `L ${i * 60} ${(level + Math.sin(i * 0.9 + t * 5) * 6 * (1 - drain * 0.6)).toFixed(1)}`).join(" ");
  const funnelIn = `M ${540 - HW + 8} ${FT} L ${540 + HW - 8} ${FT} L ${540 + NW - 4} ${FB} L ${540 + NW - 4} ${NB} L ${540 - NW + 4} ${NB} L ${540 - NW + 4} ${FB} Z`;
  // three drops: grow at the neck, pinch off, fall, land gold
  const LAND = [440, 540, 640];
  const dropEls: React.ReactNode[] = [], gold: React.ReactNode[] = [];
  let landed = 0;
  [8.2, 9.0, 9.8].forEach((at, d) => {
    const grow = r(t, at, at + 0.35, EASE_IO), fall = r(t, at + 0.35, at + 0.8, EASE_IN);
    if (t >= at && fall < 1) dropEls.push(<circle key={`dr${d}`} cx={lerp(540, LAND[d], fall)} cy={NB + 4 + grow * 16 + fall * 50} r={18 * grow} fill={C.blue} />);
    if (fall >= 1) {
      const p = r(t, at + 0.8, at + 1.1, POP);
      landed += r(t, at + 0.8, at + 1.1, EASE);
      gold.push(<circle key={`g${d}`} cx={LAND[d]} cy={1355 + Math.sin(t * 2 + d) * 3} r={30 * p} fill={C.gold} stroke={C.ink} strokeWidth={4} />);
    }
  });
  // rejected leads flick out of the surface at each band
  const BANDS = [{ y: 1000, s: "REPLIED" }, { y: 1100, s: "VIEWED" }, { y: 1200, s: "OFFERED" }];
  const bandT = BANDS.map((b) => 5 + (3 * (b.y - (FT + 70))) / (FB - 6 - (FT + 70)));
  const rejects: React.ReactNode[] = [];
  bandT.forEach((tb, b) => {
    for (let n = 0; n < 12; n++) {
      const dt = t - tb; if (dt < 0 || dt > 1.4) continue;
      const side = n % 2 ? 1 : -1, y0 = BANDS[b].y - 10;
      const x0 = 540 + side * rand(n + b * 9) * hw(y0) * 0.8;
      rejects.push(<circle key={`rj${b}_${n}`} cx={x0 + side * (220 + rand(n * 3 + b) * 260) * dt} cy={y0 - (360 + rand(n * 7) * 200) * dt + 900 * dt * dt}
        r={9} fill={C.grey} opacity={1 - clamp((dt - 1) / 0.4)} />);
    }
  });
  const topSwap = 7.75;
  return (
    <Full bg={C.cream}>
      <Svg>
        <defs>
          <Goo id="m1-01goo" b={9} />
          <clipPath id="m1-01clip"><path d={`M 0 ${level} ${wave} L 1140 ${level} L 1140 1920 L 0 1920 Z`} /></clipPath>
        </defs>
        {dots}
        <g filter="url(#m1-01goo)">
          {falling}
          <path d={funnelIn} fill={C.blue} clipPath="url(#m1-01clip)" />
          {dropEls}
        </g>
        <path d={`M ${540 - HW - 10} ${FT - 8} L ${540 - NW - 6} ${FB} L ${540 - NW - 6} ${NB}`} fill="none" stroke={C.ink} strokeWidth={12} strokeLinejoin="round" strokeLinecap="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - draw} />
        <path d={`M ${540 + HW + 10} ${FT - 8} L ${540 + NW + 6} ${FB} L ${540 + NW + 6} ${NB}`} fill="none" stroke={C.ink} strokeWidth={12} strokeLinejoin="round" strokeLinecap="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - draw} />
        {rejects}
        {gold}
      </Svg>
      {BANDS.map((b, i) => <Tag key={b.s} x={540 - hw(b.y) - 34} y={b.y} anchor="r" color={C.ink} k={r(t, bandT[i], bandT[i] + 0.3, POP)}>{b.s} ✓</Tag>)}
      <Swap t={t} at={topSwap} x={540} y={320}
        a={<div style={{ display: "flex", alignItems: "baseline", gap: 18, opacity: r(t, 0, 0.3) }}><Odo value={1000 * r(t, 0.05, 1.4, (x) => x)} size={120} color={C.ink} /><span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 40, letterSpacing: 3, color: C.ink }}>LEADS</span></div>}
        b={<div style={{ display: "flex", alignItems: "baseline", gap: 18 }}><Odo value={landed} size={120} color={C.ink} /><span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 40, letterSpacing: 3, color: C.ink }}>BUYERS</span></div>} />
      <div style={{ position: "absolute", left: 540, top: 620, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 14,
        opacity: r(t, 4.9, 5.3) * (1 - r(t, 10.3, 10.7)) }}>
        <Odo value={997 * r(t, 5.0, 8.0, (x) => x)} size={96} color={C.red} />
        <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 36, letterSpacing: 3, color: C.ink }}>FILTERED OUT</span>
      </div>
      <SceneLine text="the three that matter" from={10.8} to={13} y={570} color={C.ink} size={92} />
      <Sounds list={[[0.1, "tick", 0.2], [0.4, "tick", 0.2], [0.7, "tick", 0.2], [1.0, "tick", 0.2], [1.3, "ding", 0.2], [1.5, "whoosh", 0.3], [2.2, "riser", 0.25], [2.7, "swish", 0.3],
        ...bandT.flatMap((b) => [[b, "tick", 0.35], [b + 0.05, "swish", 0.2]] as SL), [topSwap, "whoosh", 0.3],
        [9.0, "pop", 0.4], [9.8, "pop", 0.4], [10.6, "pop", 0.4], [10.7, "ding", 0.35], [10.8, "whoosh", 0.25]]} />
    </Full>
  );
};

// =====================================================================================================================
// m1-02 Magnet: a red dot chases white clients (they flee), melts into a magnet, and the clients get pulled in and
// stick as a liquid ring; then everything pools into one gold "12 clients" disc. Fitted plate over Max.
const M102: React.FC = () => {
  const t = useT();
  const PW = 880, PH = 290;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const MX = 300, MY = 180;
  // phase 1: chase
  const chase = r(t, 0.4, 2.8, EASE_IO);
  const you = { x: lerp(90, 640, chase), y: 175 + Math.sin(t * 5) * 18 };
  const toMag = r(t, 2.8, 3.5, EASE_IO);
  const yx = lerp(you.x, MX, toMag), yy = lerp(you.y, MY, toMag);
  const morph = r(t, 3.3, 3.9, LIQUID);
  const N = 12;
  const P = Array.from({ length: N }, (_, i) => [i < 9 ? 140 + (i % 5) * 150 + (Math.floor(i / 5) ? 75 : 0) : [-60, PW + 60, PW / 2][i - 9], i < 9 ? (Math.floor(i / 5) ? 220 : 120) + rand(i) * 30 : [130, 230, PH + 60][i - 9]]);
  const slot = (i: number) => { const a = -Math.PI * 0.95 + (i / (N - 1)) * Math.PI * 1.9 - Math.PI / 2; return [MX + Math.cos(a) * 112, MY + 6 + Math.sin(a) * 100]; };
  const pullAt = (i: number) => 4.0 + i * 0.36;
  const pool = r(t, 8.9, 9.6, EASE_IO), disc = r(t, 9.3, 10.0, LIQUID), gold = r(t, 9.7, 10.2);
  let stuck = 0;
  const whites = P.map(([px, py], i) => {
    let x = px, y = py;
    if (t < 3.6) {           // flee from the chaser
      const dx = px - you.x, dy = py - you.y, d = Math.hypot(dx, dy) || 1, push = Math.max(0, 190 - d) * 0.9;
      x = px + (dx / d) * push; y = py + (dy / d) * push * 0.5;
    }
    const pk = r(t, pullAt(i), pullAt(i) + 0.55, EASE_IN);
    const [sx, sy] = slot(i);
    x = lerp(x, sx, pk) + Math.sin(t * 2 + i) * 3 * (1 - pk); y = lerp(y, sy, pk);
    x = lerp(x, MX, pool); y = lerp(y, MY, pool);
    stuck += r(t, pullAt(i) + 0.45, pullAt(i) + 0.6);
    return <circle key={i} cx={x} cy={y} r={lerp(24, 10, pool)} fill="#fff" />;
  });
  const magPath = "M -52 -44 L -52 8 A 52 52 0 0 0 52 8 L 52 -44";
  const magS = morph * (1 - pool);
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-02gooR" b={8} /><Goo id="m1-02gooW" b={8} /></defs>
          <g filter="url(#m1-02gooW)">{whites}<circle cx={MX} cy={MY} r={92 * disc} fill="#fff" /></g>
          <g filter="url(#m1-02gooR)">
            <circle cx={yx} cy={yy} r={26 * (1 - morph)} fill={C.red} />
            {magS > 0.01 && <g transform={`translate(${MX} ${MY - 8}) scale(${magS})`}><path d={magPath} fill="none" stroke={C.red} strokeWidth={36} /></g>}
          </g>
          {magS > 0.01 && <g transform={`translate(${MX} ${MY - 8}) scale(${magS})`}>
            <rect x={-70} y={-62} width={36} height={22} fill="#E5E5EA" /><rect x={34} y={-62} width={36} height={22} fill="#E5E5EA" /></g>}
          {gold > 0 && <circle cx={MX} cy={MY} r={92 * disc} fill={C.gold} opacity={gold} />}
          {t < 3.2 && [0, 1, 2].map((s) => <line key={s} x1={you.x - 40 - s * 22} y1={you.y - 12 + s * 12} x2={you.x - 70 - s * 22} y2={you.y - 12 + s * 12}
            stroke="rgba(255,255,255,0.4)" strokeWidth={5} strokeLinecap="round" opacity={chase > 0 && chase < 1 ? 1 : 0} />)}
        </svg>
        <Swap t={t} at={3.4} x={150} y={36}
          a={<span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 3, color: C.red, whiteSpace: "nowrap" }}>CHASING…</span>}
          b={<span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.7)", whiteSpace: "nowrap" }}>ATTRACTING</span>} />
        {t > 3.9 && t < 9.4 && <div style={{ position: "absolute", right: 36, top: 8, display: "flex", alignItems: "baseline", gap: 12, opacity: r(t, 3.9, 4.3) * (1 - r(t, 9.1, 9.4)) }}>
          <Odo value={stuck} size={52} />
          <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 28, letterSpacing: 3, color: "rgba(255,255,255,0.7)" }}>CLIENTS</span></div>}
        {disc > 0.3 && <div style={{ position: "absolute", left: MX - 110, top: MY - 52, width: 220, display: "flex", justifyContent: "center", opacity: r(t, 9.8, 10.1) }}>
          <Odo value={12} size={96} color={C.ink} /></div>}
        <Txt x={500} y={150} anchor="l" size={64} font={SERIF} weight={400} ls={0} k={r(t, 10.0, 10.5, EASE)}>came to you.</Txt>
        <Tag x={500} y={225} anchor="l" k={r(t, 10.3, 10.7, EASE)} color={C.gold}>NO COLD CALLS</Tag>
      </Plate>
      <DemoCaption text="Stop chasing clients." from={0.4} to={3.7} />
      <DemoCaption text="Become the magnet." from={3.9} to={8.8} />
      <DemoCaption text="They come to you." from={9.2} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.3], [0.5, "whoosh", 0.3], [1.6, "swish", 0.2], [2.8, "swish", 0.3], [3.4, "pop", 0.35], [3.5, "whoosh", 0.2],
        ...Array.from({ length: 12 }, (_, i) => [pullAt(i) + 0.5, "tick", 0.3] as SL[number]), [8.9, "riser", 0.25], [9.3, "swish", 0.3], [9.8, "impact", 0.3], [10.0, "ding", 0.35], [10.3, "pop", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-03 Domino referrals: a gold client rolls into 12 white dominoes (two rows), DEALS counts up; the fallen dominoes
// melt into one bar that swells into a card. Full-screen blue scene.
const M103: React.FC = () => {
  const t = useT();
  const T0 = 1.9, STEP = 0.32, LEAN = 33.6;
  const DW = 46, DH = 170;
  const dom = Array.from({ length: 12 }, (_, i) => {
    const row = i < 6 ? 0 : 1;
    const x = row === 0 ? 150 + i * 140 : 850 - (i - 6) * 140;
    const floor = row === 0 ? 880 : 1240;
    const dir = row === 0 ? 1 : -1;
    const last = i === 5 || i === 11;
    const a = r(t, T0 + i * STEP, T0 + i * STEP + 0.32, EASE_IN) * (last ? 82 : LEAN) * dir;
    return { x, floor, dir, a, born: r(t, 0.1 + i * 0.05, 0.4 + i * 0.05, POP) };
  });
  const toppled = dom.reduce((s, _, i) => s + r(t, T0 + i * STEP + 0.12, T0 + i * STEP + 0.3), 0);
  const melt = r(t, 6.3, 7.1, EASE_IO), card = r(t, 7.1, 7.9, LIQUID);
  const ball = r(t, 0.9, T0, EASE_IN);
  const bx = lerp(-40, 150 - DW / 2 - 24, ball) - r(t, T0, T0 + 0.4, EASE) * 20;
  const els = dom.map((d, i) => {
    const px = d.x + (d.dir * DW) / 2, py = d.floor;
    // centre of the rotated domino
    const rad = (d.a * Math.PI) / 180;
    const cx0 = px + (-d.dir * DW / 2) * Math.cos(rad) - (-DH / 2) * Math.sin(rad);
    const cy0 = py + (-d.dir * DW / 2) * Math.sin(rad) + (-DH / 2) * Math.cos(rad);
    const tx = 200 + (i % 12) * (680 / 11), ty = 1000;
    const cx = lerp(cx0, tx, melt), cy = lerp(cy0, ty, melt);
    const w = lerp(DW, 66, melt), h = lerp(DH, 66, melt) * d.born;
    return <rect key={i} x={-w / 2} y={-h / 2} width={w} height={h} rx={lerp(10, 33, melt)} fill="#fff"
      transform={`translate(${cx} ${cy}) rotate(${d.a * (1 - melt)})`} opacity={card > 0.02 ? 1 - card : 1} />;
  });
  const cw = lerp(740, 840, card), ch = lerp(70, 380, card), cy = lerp(965, 800, card);
  return (
    <Full bg={C.blue}>
      <Svg>
        <defs><Goo id="m1-03goo" b={10} /></defs>
        <line x1={90} x2={930} y1={882} y2={882} stroke="rgba(255,255,255,0.25)" strokeWidth={4} opacity={1 - melt} />
        <line x1={90} x2={930} y1={1242} y2={1242} stroke="rgba(255,255,255,0.25)" strokeWidth={4} opacity={1 - melt} />
        <g filter="url(#m1-03goo)">
          {els}
          {card > 0 && <rect x={540 - cw / 2} y={cy} width={cw} height={ch} rx={60} fill="#fff" />}
        </g>
        {t < 6.4 && <circle cx={bx} cy={882 - 24} r={24} fill={C.gold} opacity={1 - r(t, 6.0, 6.3)} />}
      </Svg>
      <Tag x={90} y={640} anchor="l" color={C.gold} k={r(t, 0.8, 1.2, POP) * (1 - r(t, 6.0, 6.3))} size={34}>1 HAPPY CLIENT →</Tag>
      <div style={{ position: "absolute", left: 540, top: 360, transform: `translate(-50%,-50%) scale(${1 - r(t, 6.6, 7.0, EASE_IN)})`, display: "flex", alignItems: "baseline", gap: 18,
        opacity: r(t, 0.2, 0.6) }}>
        <Odo value={toppled} size={140} /><span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 40, letterSpacing: 3, color: "rgba(255,255,255,0.8)" }}>DEALS</span>
      </div>
      <div style={{ position: "absolute", left: 540, top: 990, transform: `translate(-50%,-50%) scale(${0.8 + 0.2 * r(t, 7.8, 8.3, POP)})`, opacity: r(t, 7.8, 8.2),
        display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 18 }}><Odo value={12 * r(t, 7.8, 8.6, EASE_IO)} size={170} color={C.blue} font={DISPLAY} weight={400} />
          <span style={{ fontFamily: DISPLAY, fontSize: 110, color: C.blue }}>DEALS</span></div>
        <div style={{ fontFamily: SERIF, fontSize: 64, color: C.ink, marginTop: 6, opacity: r(t, 8.8, 9.3) }}>from one happy client</div>
      </div>
      <SceneLine text="Referrals compound." from={9.6} to={12} y={330} color="#fff" size={96} />
      <Sounds list={[[0.1, "pop", 0.2], [0.4, "pop", 0.2], [0.9, "whoosh", 0.25], [T0, "impact", 0.3],
        ...Array.from({ length: 12 }, (_, i) => [T0 + i * STEP + 0.28, "tick", 0.35] as SL[number]), [6.3, "swish", 0.35], [7.1, "whoosh", 0.3], [7.9, "impact", 0.3], [8.6, "ding", 0.35], [9.6, "whoosh", 0.25]]} />
    </Full>
  );
};


// =====================================================================================================================
// m1-05 Team gears: three gears turn, DEALS climbs; the middle gear turns red and jams the machine, melts into a
// puddle, and a new gear rises out of the liquid; everything spins faster. Full-screen indigo scene.
const speed05 = (t: number) => {
  if (t < 0.4) return 0;
  if (t < 3.6) return r(t, 0.4, 0.9);
  if (t < 4.0) return 1 - r(t, 3.6, 4.0, EASE_IN);
  if (t < 8.0) return 0;
  return r(t, 8.0, 8.6) * 1.8;
};
const M105: React.FC = () => {
  const t = useT();
  let ang = 0;
  for (let f = 0; f < Math.round(t * 30); f++) ang += speed05(f / 30) / 30 * 1.6;
  const G = [
    { x: 290, y: 800, R: 150, n: 12, label: "LEADS" },
    { x: 565, y: 1016, R: 200, n: 16, label: "TEAM" },
    { x: 745, y: 776, R: 100, n: 8, label: "CLOSE" },
  ];
  const th1 = Math.atan2(G[1].y - G[0].y, G[1].x - G[0].x);
  const a0 = th1 + ang;
  const pB = (2 * Math.PI) / 16;
  const aB0 = th1 + Math.PI - Math.PI / 16;
  const a1 = aB0 - ang * (12 / 16);
  const th2 = Math.atan2(G[2].y - G[1].y, G[2].x - G[1].x);
  const delta = ((((aB0 - th2) % pB) + pB) % pB);
  const aC0 = th2 + Math.PI - Math.PI / 8 - delta * (16 / 8);
  const a2 = aC0 + ang * (12 / 8);
  const bad = r(t, 3.3, 3.7);
  const shake = t > 4.0 && t < 4.4 ? Math.sin(t * 90) * 8 * (1 - r(t, 4.0, 4.4)) : 0;
  const melt = r(t, 5.4, 6.4, EASE_IN), regrow = r(t, 6.9, 7.9, LIQUID);
  const deals = 40 * r(t, 0.6, 3.6, (x) => x) + 60 * r(t, 8.3, 11.4, (x) => x);
  const Bx = G[1].x + shake, By = G[1].y;
  return (
    <Full bg={C.indigo}>
      <Svg>
        <defs><Goo id="m1-05goo" b={9} /></defs>
        {[0, 2].map((gi) => {
          const g = G[gi], a = gi === 0 ? a0 : a2;
          const s = r(t, 0.05 + gi * 0.15, 0.45 + gi * 0.15, POP);
          return <g key={gi} transform={`translate(${g.x + (gi === 0 ? shake * 0.5 : -shake * 0.5)} ${g.y}) scale(${s})`}>
            <path d={gearPath(0, 0, g.R, g.n, 26, a)} fill="#fff" /><circle r={g.R * 0.56} fill={C.indigo} /></g>;
        })}
        {/* the middle gear: crisp while turning, goo only while it melts / regrows */}
        {melt < 0.02 && <g transform={`translate(${Bx} ${By}) scale(${r(t, 0.15, 0.55, POP)})`}>
          <path d={gearPath(0, 0, G[1].R, G[1].n, 26, a1)} fill={mix("#FFFFFF", C.red, bad)} /><circle r={G[1].R * 0.56} fill={C.indigo} /></g>}
        {melt >= 0.02 && regrow < 0.98 && <g filter="url(#m1-05goo)">
          {melt < 1 && <g transform={`translate(${Bx} ${By + melt * 220}) scale(${1 - melt * 0.75}, ${1 - melt * 0.9})`}>
            <path d={gearPath(0, 0, G[1].R, G[1].n, 26, a1)} fill={t < 6.9 ? C.red : "#fff"} /></g>}
          <ellipse cx={Bx} cy={1330} rx={lerp(30, 230, melt) * (1 - regrow)} ry={lerp(8, 34, melt) * (1 - regrow * 0.5)} fill={t < 6.9 ? C.red : "#fff"} />
          {t >= 6.9 && <g transform={`translate(${Bx} ${lerp(1300, By, regrow)}) scale(${0.25 + 0.75 * regrow})`}>
            <path d={gearPath(0, 0, G[1].R, G[1].n, 26, a1)} fill="#fff" /></g>}
        </g>}
        {melt >= 0.02 && t < 6.9 && t > 6.3 && <ellipse cx={Bx} cy={1330} rx={230 * (1 - r(t, 6.3, 6.9, EASE_IN))} ry={34} fill={C.red} />}
        {regrow >= 0.98 && <g transform={`translate(${Bx} ${By})`}><path d={gearPath(0, 0, G[1].R, G[1].n, 26, a1)} fill={C.green} /><circle r={G[1].R * 0.56} fill={C.indigo} /></g>}
        {regrow > 0.3 && regrow < 0.98 && <circle cx={Bx} cy={lerp(1300, By, regrow)} r={G[1].R * 0.56 * (0.25 + 0.75 * regrow)} fill={C.indigo} />}
      </Svg>
      <Txt x={G[0].x} y={G[0].y} size={36} font={MONO} weight={700} ls={2} k={r(t, 0.3, 0.6)}>{G[0].label}</Txt>
      <Txt x={G[2].x} y={G[2].y} size={28} font={MONO} weight={700} ls={2} k={r(t, 0.5, 0.8)}>{G[2].label}</Txt>
      <Txt x={Bx} y={By} size={40} font={MONO} weight={700} ls={2} k={r(t, 0.4, 0.7) * (1 - r(t, 5.3, 5.5))} color="#fff">{bad > 0.5 ? "BAD HIRE" : "TEAM"}</Txt>
      <Txt x={Bx} y={By} size={36} font={MONO} weight={700} ls={2} k={r(t, 7.8, 8.2, POP)}>RIGHT HIRE</Txt>
      <div style={{ position: "absolute", left: 540, top: 380, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 16, opacity: r(t, 0.2, 0.6) }}>
        <Odo value={deals} size={130} color={t > 4 && t < 8 ? "rgba(255,255,255,0.45)" : "#fff"} />
        <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 38, letterSpacing: 3, color: "rgba(255,255,255,0.8)" }}>DEALS</span>
      </div>
      <Txt x={540} y={500} size={50} color={C.gold} k={r(t, 4.0, 4.3, POP) * (1 - r(t, 6.6, 6.9))}>MACHINE STOPS.</Txt>
      <Txt x={540} y={500} size={50} color="#fff" k={r(t, 8.6, 9.0, POP)}>WHOLE TEAM SPEEDS UP</Txt>
      <SceneLine text="One hire moves the whole machine." from={9.6} to={12} y={1360} color="#fff" size={58} />
      <Sounds list={[[0.05, "pop", 0.3], [0.2, "pop", 0.3], [0.35, "pop", 0.3], [0.6, "riser", 0.15], [3.3, "tick", 0.35], [4.0, "impact", 0.45], [5.4, "swish", 0.35],
        [6.2, "swish", 0.2], [6.9, "whoosh", 0.3], [7.85, "pop", 0.4], [8.0, "ding", 0.3], [8.4, "riser", 0.25], [8.6, "whoosh", 0.25], [9.6, "whoosh", 0.2]]} />
    </Full>
  );
};

// =====================================================================================================================
/** header text that collapses to a line and re-expands each time the beat changes */
const Seq: React.FC<{ t: number; x: number; y: number; items: [number, React.ReactNode][]; dur?: number }> = ({ t, x, y, items, dur = 0.45 }) => {
  let i = 0;
  items.forEach(([at], j) => { if (t >= at) i = j; });
  if (t < items[0][0]) return null;
  if (i === 0) {
    const k = r(t, items[0][0], items[0][0] + 0.35, EASE);
    return <div style={{ position: "absolute", left: x, top: y, transform: `translate(-50%,-50%) scaleX(${Math.max(0.02, k)})`, opacity: clamp(k * 2) }}>{items[0][1]}</div>;
  }
  return <Swap t={t} at={items[i][0] - dur / 2} a={items[i - 1][1]} b={items[i][1]} x={x} y={y} dur={dur} />;
};
const mono = (s: string, color = "rgba(255,255,255,0.75)", size = 30) =>
  <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: size, letterSpacing: 3, color, whiteSpace: "nowrap" }}>{s}</span>;

const KeyIcon: React.FC<{ x: number; y: number; s?: number; color?: string }> = ({ x, y, s = 1, color = C.gold }) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <circle cx={-26} cy={0} r={20} fill="none" stroke={color} strokeWidth={11} />
    <rect x={-8} y={-6} width={56} height={12} rx={4} fill={color} />
    <rect x={28} y={4} width={9} height={16} rx={2} fill={color} /><rect x={42} y={4} width={9} height={12} rx={2} fill={color} />
  </g>
);

// m1-06 Bridge: buyer on one cliff, keys on the other; four liquid drops land and flatten into planks (viewing, offer,
// mortgage, transfer) that melt into one road; the buyer rolls across and lifts the key. Plate over Max.
const M106: React.FC = () => {
  const t = useT();
  const PW = 860, PH = 290;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 10.6, 11, EASE_IN));
  const cliffs = r(t, 0.25, 0.9, LIQUID);
  const TOP = 196, GL = 230, GR = 630, PWD = (GR - GL) / 4;
  const STEPS = ["VIEWING", "OFFER", "MORTGAGE", "TRANSFER"], ST = [1.4, 2.6, 3.8, 5.0];
  const planks = ST.map((s, i) => {
    if (t < s) return null;
    const fall = r(t, s, s + 0.4, EASE_IN), flat = r(t, s + 0.4, s + 0.8, LIQUID);
    const cx = GL + PWD * (i + 0.5);
    if (flat <= 0) return <circle key={i} cx={cx} cy={lerp(-30, TOP - 6, fall)} r={24} fill="#fff" />;
    const w = lerp(48, PWD + 8, flat), h = lerp(48, 22, flat);
    return <rect key={i} x={cx - w / 2} y={TOP + 11 - h / 2 + (1 - flat) * -10} width={w} height={h} rx={lerp(24, 6, flat)} fill="#fff" />;
  });
  const walk = r(t, 6.4, 8.0, EASE_IO);
  const dx = lerp(130, 712, walk), dy = TOP - 22 - Math.abs(Math.sin(walk * Math.PI * 5)) * 20 * (walk > 0 && walk < 1 ? 1 : 0) + Math.sin(t * 3) * 2;
  const lift = r(t, 8.0, 8.5, POP);
  const placed = ST.reduce((s, a) => s + r(t, a + 0.4, a + 0.6), 0);
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-06goo" b={7} /></defs>
          <g transform={`translate(0 ${(1 - cliffs) * 160})`}>
            <rect x={30} y={TOP} width={GL - 30} height={140} rx={18} fill="#3A3A3C" />
            <rect x={GR} y={TOP} width={830 - GR} height={140} rx={18} fill="#3A3A3C" />
          </g>
          <g filter="url(#m1-06goo)">{planks}</g>
          <KeyIcon x={735} y={TOP - 46 - lift * 34 + Math.sin(t * 2) * 3} s={0.95} />
          <circle cx={dx} cy={dy} r={22} fill={walk >= 1 ? mix(C.blue, C.gold, r(t, 8.0, 8.3)) : C.blue} />
        </svg>
        <Tag x={130} y={TOP + 52} size={28} color="rgba(255,255,255,0.7)" k={cliffs}>YOU</Tag>
        <Tag x={730} y={TOP + 52} size={28} color="rgba(255,255,255,0.7)" k={cliffs}>KEYS</Tag>
        <Seq t={t} x={300} y={40} items={[[0.3, mono("BUYER → KEYS")], ...ST.map((s, i) => [s + 0.4, mono(`${i + 1}. ${STEPS[i]}`, "#fff")] as [number, React.ReactNode]),
          [6.4, mono("WALK ACROSS", C.blue)], [8.05, mono("KEYS IN HAND ✓", C.gold)]]} />
        <div style={{ position: "absolute", right: 36, top: 26, display: "flex", gap: 12 }}>
          {[0, 1, 2, 3].map((j) => { const f = clamp(placed - j); return <div key={j} style={{ width: 26, height: 26, borderRadius: 13, border: "3px solid rgba(255,255,255,0.4)",
            background: f > 0.5 ? (t > 8.0 ? C.gold : "#fff") : "transparent", transform: `scale(${1 + Math.sin(f * Math.PI) * 0.4})` }} />; })}
        </div>
      </Plate>
      <DemoCaption text="My job? Build the bridge." from={0.4} to={4.9} />
      <DemoCaption text="Viewing, offer, mortgage, transfer." from={5.0} to={7.9} />
      <DemoCaption text="You just walk across." from={8.1} to={10.8} />
      <Sounds list={[[0.05, "pop", 0.3], [0.3, "whoosh", 0.25], ...ST.flatMap((s) => [[s, "swish", 0.2], [s + 0.42, "pop", 0.35]] as SL), [6.4, "whoosh", 0.25],
        ...[0.2, 0.4, 0.6, 0.8].map((p) => [6.4 + 1.6 * p, "tick", 0.25] as SL[number]), [8.0, "ding", 0.4], [8.05, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-07 Ripple: one gold drop (a review) lands in a field of grey people; three rings spread and light them gold, the
// count climbs, then every gold dot flows (liquid) into one REPUTATION disc. Full-screen navy scene.
const RIP = Array.from({ length: 170 }, (_, i) => {
  const a = rand(i + 3) * Math.PI * 2, rr = 80 + Math.sqrt(rand(i + 911)) * 420;
  return { x: 540 + Math.cos(a) * rr, y: 880 + Math.sin(a) * rr * 0.95, rr, i };
}).filter((d) => d.x > 70 && d.x < 1010 && d.y > 470);
const M107: React.FC = () => {
  const t = useT();
  const CX = 540, CY = 880, V = 300;
  const W0 = [1.1, 3.4, 5.7], BAND = [200, 340, 999];
  const drop = r(t, 0.5, 1.1, EASE_IN);
  const litAt = (d: typeof RIP[number]) => { const b = d.rr < BAND[0] ? 0 : d.rr < BAND[1] ? 1 : 2; return W0[b] + d.rr / V; };
  const gather = (d: typeof RIP[number]) => r(t, 8.6 + rand(d.i) * 0.5, 9.5 + rand(d.i) * 0.5, EASE_IO);
  let lit = 0;
  const grey: React.ReactNode[] = [], gold: React.ReactNode[] = [], goldGoo: React.ReactNode[] = [];
  RIP.forEach((d) => {
    const la = litAt(d), on = r(t, la, la + 0.25, POP);
    lit += r(t, la, la + 0.2);
    const fy = Math.sin(t * 1.5 + d.i) * 3;
    if (on <= 0) { grey.push(<circle key={d.i} cx={d.x} cy={d.y + fy} r={10} fill="#3B5378" />); return; }
    const g = gather(d);
    const el = <circle key={d.i} cx={lerp(d.x, CX, g)} cy={lerp(d.y + fy, CY, g)} r={10 * (0.6 + 0.4 * Math.min(on, 1.3)) * (1 + g * 0.6)} fill={C.gold} />;
    (t >= 8.6 ? goldGoo : gold).push(el);
  });
  const disc = r(t, 9.2, 10.2, LIQUID);
  const waves = W0.map((w, j) => {
    const p = (t - w) / 1.9; if (p < 0 || p > 1) return null;
    return <ellipse key={j} cx={CX} cy={CY} rx={20 + p * 560} ry={(20 + p * 560) * 0.95} fill="none" stroke="#fff" strokeWidth={8 * (1 - p) + 1} opacity={1 - p} />;
  });
  return (
    <Full bg="#0B2545">
      <Svg>
        <defs><Goo id="m1-07goo" b={9} /></defs>
        {grey}
        {waves}
        {gold}
        <g filter="url(#m1-07goo)">
          {goldGoo}
          {t < 1.4 && <circle cx={CX} cy={lerp(300, CY, drop)} r={24 * (1 + r(t, 1.1, 1.4) * 0.3)} fill={C.gold} />}
          {disc > 0 && <circle cx={CX} cy={CY} r={190 * disc} fill={C.gold} />}
        </g>
        {t >= 1.1 && t < 9.4 && <circle cx={CX} cy={CY} r={22 + Math.sin(t * 3) * 2} fill={C.gold} />}
      </Svg>
      <div style={{ position: "absolute", left: 540, top: 330, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 16, opacity: r(t, 1.0, 1.4) }}>
        <Odo value={lit} size={130} color={C.gold} />
        <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 38, letterSpacing: 3, color: "rgba(255,255,255,0.8)", whiteSpace: "nowrap" }}>PEOPLE HEARD</span>
      </div>
      <Seq t={t} x={540} y={1395} items={[[0.3, mono("1 HONEST REVIEW", C.gold, 34)], [W0[1], mono("THEIR FRIENDS", "#fff", 34)], [W0[2], mono("FRIENDS OF FRIENDS", "#fff", 34)], [8.7, mono("…ALL POINTING AT YOU", C.gold, 34)]]} />
      <Txt x={CX} y={CY} size={72} font={DISPLAY} weight={400} ls={1} color={C.ink} k={r(t, 9.9, 10.3, POP)}>REPUTATION</Txt>
      <SceneLine text="one review travels further than an ad" from={10.4} to={12} y={480} color="#fff" size={62} />
      <Sounds list={[[0.4, "whoosh", 0.2], [1.1, "pop", 0.4], ...W0.flatMap((w) => [[w, "swish", 0.3], [w + 0.4, "tick", 0.2], [w + 0.9, "tick", 0.2]] as SL), [8.6, "riser", 0.25], [9.3, "swish", 0.3], [9.9, "impact", 0.35], [10.1, "ding", 0.3], [10.4, "whoosh", 0.2]]} />
    </Full>
  );
};

// =====================================================================================================================
// m1-08 Orbit: clients circle you while CHECK-INS is on; switch it off and the orbits widen until they drift out of the
// plate; switch it on, a pulse goes out and each client flows back through a liquid bridge. Plate over Max.
const M108: React.FC = () => {
  const t = useT();
  const PW = 880, PH = 300, CX = 440, CY = 182;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const off = t >= 3.5 && t < 6.6;
  const tog = r(t, 3.5, 3.75, EASE) * (1 - r(t, 6.6, 6.85, EASE));
  const N = 7;
  const back = (i: number) => 7.0 + i * 0.22;
  let repeat = 0;
  const cl = Array.from({ length: N }, (_, i) => {
    const w = 0.55 + rand(i + 2) * 0.35, th = (i / N) * Math.PI * 2 + t * w;
    const drift = r(t, 3.6 + i * 0.12, 6.2 + i * 0.05, EASE_IN);
    const b = r(t, back(i), back(i) + 0.5, EASE_IN), out = r(t, back(i) + 0.5, back(i) + 1.1, LIQUID);
    let rho = 1 + drift * 1.8;
    if (t >= back(i)) rho = lerp(lerp(2.8, 0.12, b), 1, out);
    repeat += r(t, back(i) + 0.4, back(i) + 0.6);
    return { x: CX + Math.cos(th) * 300 * rho, y: CY + Math.sin(th) * 92 * rho, i };
  });
  const tint = off ? mix(C.blue, C.grey, r(t, 3.5, 4.2)) : t >= 6.6 ? mix(C.grey, C.blue, r(t, 6.6, 7.0)) : C.blue;
  const pulses = [6.8, 7.25].map((p, j) => { const q = (t - p) / 0.9; if (q < 0 || q > 1) return null;
    return <ellipse key={j} cx={CX} cy={CY} rx={40 + q * 340} ry={(40 + q * 340) * 0.32} fill="none" stroke="#fff" strokeWidth={6 * (1 - q)} opacity={1 - q} />; });
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-08goo" b={8} /></defs>
          <ellipse cx={CX} cy={CY} rx={300} ry={92} fill="none" stroke="rgba(255,255,255,0.18)" strokeWidth={3} strokeDasharray="10 12" opacity={off ? 1 - r(t, 3.6, 4.2) : t > 7 ? r(t, 8.2, 8.8) : 1} />
          {pulses}
          <g filter="url(#m1-08goo)">
            <circle cx={CX} cy={CY} r={44 * r(t, 0.1, 0.5, POP)} fill={tint} />
            {cl.filter((c) => c.y < CY).map((c) => <circle key={c.i} cx={c.x} cy={c.y} r={18} fill={tint} />)}
            {cl.filter((c) => c.y >= CY).map((c) => <circle key={c.i} cx={c.x} cy={c.y} r={18} fill={tint} />)}
          </g>
        </svg>
        <Txt x={CX} y={CY} size={30} font={MONO} weight={700} ls={2} k={r(t, 0.3, 0.6)}>YOU</Txt>
        <div style={{ position: "absolute", left: 32, top: 18, display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ width: 84, height: 48, borderRadius: 24, background: mix(C.green, "#48484A", tog), position: "relative" }}>
            <div style={{ position: "absolute", top: 4, left: lerp(40, 4, tog), width: 40, height: 40, borderRadius: 20, background: "#fff" }} /></div>
          {mono("CHECK-INS", "rgba(255,255,255,0.8)", 28)}
        </div>
        {t > 3.8 && t < 7.2 && <Tag x={PW - 40} y={42} anchor="r" color={C.red} size={28} k={r(t, 3.8, 4.1, POP) * (1 - r(t, 6.9, 7.2))}>GONE QUIET</Tag>}
        {t > 7.0 && <div style={{ position: "absolute", right: 36, top: 14, display: "flex", alignItems: "baseline", gap: 12, opacity: r(t, 7.0, 7.3) }}>
          <Odo value={repeat} size={52} color={C.green} />{mono("REPEAT CLIENTS", "rgba(255,255,255,0.8)", 28)}</div>}
      </Plate>
      <DemoCaption text="Stay in touch and clients orbit you." from={0.4} to={3.4} />
      <DemoCaption text="Go quiet… they drift away." from={3.6} to={6.5} />
      <DemoCaption text="One check-in brings them back." from={6.7} to={11.7} />
      <Sounds list={[[0.05, "pop", 0.3], [0.3, "swish", 0.2], [3.5, "tick", 0.45], [3.8, "whoosh", 0.2], [5.0, "swish", 0.15], [6.6, "tick", 0.45], [6.8, "riser", 0.2], [6.85, "swish", 0.3],
        ...Array.from({ length: N }, (_, i) => [back(i) + 0.45, "pop", 0.25] as SL[number]), [8.9, "ding", 0.35]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-09 Maze: alone, the dot wanders into dead ends (red X) while WEEKS climbs; the trail rewinds like liquid back to the
// start, then the guide's blue path draws straight to the keys. Full-screen gold scene.
const MZ = 6;
const MAZE = (() => {
  const right = Array.from({ length: MZ }, () => Array(MZ).fill(true) as boolean[]);
  const down = Array.from({ length: MZ }, () => Array(MZ).fill(true) as boolean[]);
  const seen = Array.from({ length: MZ }, () => Array(MZ).fill(false) as boolean[]);
  let seed = 3;
  const stack: [number, number][] = [[0, 0]]; seen[0][0] = true;
  while (stack.length) {
    const [a0, b0] = stack[stack.length - 1];
    const nb = ([[a0 - 1, b0], [a0 + 1, b0], [a0, b0 - 1], [a0, b0 + 1]] as [number, number][]).filter(([a, b]) => a >= 0 && b >= 0 && a < MZ && b < MZ && !seen[a][b]);
    if (!nb.length) { stack.pop(); continue; }
    seed++;
    const [a, b] = nb[Math.floor(rand(seed * 7.3) * nb.length)];
    if (a === a0) right[a0][Math.min(b, b0)] = false; else down[Math.min(a, a0)][b0] = false;
    seen[a][b] = true; stack.push([a, b]);
  }
  const open = (a0: number, b0: number, a1: number, b1: number) => (a0 === a1 ? !right[a0][Math.min(b0, b1)] : !down[Math.min(a0, a1)][b0]);
  const nbrs = (a0: number, b0: number) => ([[a0, b0 - 1], [a0 - 1, b0], [a0, b0 + 1], [a0 + 1, b0]] as [number, number][])
    .filter(([a, b]) => a >= 0 && b >= 0 && a < MZ && b < MZ && open(a0, b0, a, b));
  const wander: [number, number][] = [], dead: number[] = [];
  const vis = new Set<string>();
  const dfs = (a0: number, b0: number): boolean => {
    vis.add(`${a0},${b0}`); wander.push([a0, b0]);
    if (a0 === MZ - 1 && b0 === MZ - 1) return true;
    let any = false;
    for (const [a, b] of nbrs(a0, b0)) if (!vis.has(`${a},${b}`)) { any = true; if (dfs(a, b)) return true; wander.push([a0, b0]); }
    if (!any) dead.push(wander.length - 1);
    return false;
  };
  dfs(0, 0);
  const prev = new Map<string, string>(); const q: [number, number][] = [[0, 0]]; const s2 = new Set(["0,0"]);
  while (q.length) { const [a0, b0] = q.shift()!; for (const [a, b] of nbrs(a0, b0)) { const kk = `${a},${b}`; if (!s2.has(kk)) { s2.add(kk); prev.set(kk, `${a0},${b0}`); q.push([a, b]); } } }
  const path: [number, number][] = []; let cur = `${MZ - 1},${MZ - 1}`;
  while (cur) { const [a, b] = cur.split(",").map(Number); path.unshift([a, b]); cur = prev.get(cur) as string; }
  return { right, down, wander, dead, path };
})();
const M109: React.FC = () => {
  const t = useT();
  const CS = 120, X0 = 540 - (MZ * CS) / 2, Y0 = 560;
  const P = ([a, b]: [number, number]) => [X0 + b * CS + CS / 2, Y0 + a * CS + CS / 2];
  const walls: React.ReactNode[] = [];
  const wl = (x1: number, y1: number, x2: number, y2: number, key: string) => walls.push(<line key={key} x1={x1} y1={y1} x2={x2} y2={y2} stroke={C.ink} strokeWidth={12} strokeLinecap="round" />);
  for (let a = 0; a < MZ; a++) for (let b = 0; b < MZ; b++) {
    if (b < MZ - 1 && MAZE.right[a][b]) wl(X0 + (b + 1) * CS, Y0 + a * CS, X0 + (b + 1) * CS, Y0 + (a + 1) * CS, `r${a}${b}`);
    if (a < MZ - 1 && MAZE.down[a][b]) wl(X0 + b * CS, Y0 + (a + 1) * CS, X0 + (b + 1) * CS, Y0 + (a + 1) * CS, `d${a}${b}`);
  }
  wl(X0 + CS, Y0, X0 + MZ * CS, Y0, "top"); wl(X0, Y0, X0, Y0 + MZ * CS, "left");
  wl(X0 + MZ * CS, Y0, X0 + MZ * CS, Y0 + (MZ - 1) * CS, "right"); wl(X0, Y0 + MZ * CS, X0 + MZ * CS, Y0 + MZ * CS, "bottom");
  const build = r(t, 0.1, 0.8, LIQUID);
  // wander 1.0 -> 5.0, rewind 5.2 -> 5.9, guide 6.2 -> 8.0
  const WS = 0.1, maxN = Math.min(MAZE.wander.length - 1, 42);
  const wf = clamp((t - 1.0) / WS, 0, maxN);
  const rew = r(t, 5.35, 6.0, EASE_IO);
  const n = wf * (1 - rew);
  const pts = MAZE.wander.slice(0, Math.floor(n) + 1).map(P);
  const i0 = Math.floor(n), fr = n - i0;
  const a = P(MAZE.wander[i0]), b = P(MAZE.wander[Math.min(i0 + 1, MAZE.wander.length - 1)]);
  let dot = [lerp(a[0], b[0], fr), lerp(a[1], b[1], fr)];
  pts.push(dot);
  const gp = MAZE.path.map(P);
  const gk = r(t, 6.2, 8.0, EASE_IO), gn = gk * (gp.length - 1), g0 = Math.floor(gn);
  if (t >= 6.2) { const A = gp[g0], B = gp[Math.min(g0 + 1, gp.length - 1)]; dot = [lerp(A[0], B[0], gn - g0), lerp(A[1], B[1], gn - g0)]; }
  const startY = Y0 - 70;
  if (t < 1.0) dot = [P([0, 0])[0], lerp(startY, P([0, 0])[1], r(t, 0.6, 1.0, EASE_IO))];
  const deadSeen = MAZE.dead.filter((d) => d <= maxN);
  const weeks = 12 * clamp((t - 1.0) / 4.2);
  const done = r(t, 8.0, 8.4, POP);
  const [ex, ey] = P([MZ - 1, MZ - 1]);
  return (
    <Full bg={C.gold}>
      <Svg>
        <g opacity={build} transform={`translate(540 900) scale(${0.9 + 0.1 * build}) translate(-540 -900)`}>{walls}</g>
        <polyline points={pts.map((p) => p.join(",")).join(" ")} fill="none" stroke="#fff" strokeWidth={16} strokeLinecap="round" strokeLinejoin="round" opacity={t < 6.2 ? 0.95 : 0} />
        {deadSeen.map((d) => { const at = 1.0 + d * WS; const kx = r(t, at, at + 0.25, POP) * (1 - rew); if (kx <= 0) return null; const [x, y] = P(MAZE.wander[d]);
          return <g key={d} transform={`translate(${x} ${y}) scale(${kx})`} stroke={C.red} strokeWidth={12} strokeLinecap="round"><line x1={-20} y1={-20} x2={20} y2={20} /><line x1={20} y1={-20} x2={-20} y2={20} /></g>; })}
        <polyline points={gp.map((p) => p.join(",")).join(" ")} fill="none" stroke={C.blue} strokeWidth={18} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - gk} />
        <circle cx={dot[0]} cy={dot[1]} r={26} fill={t >= 6.2 ? C.blue : C.ink} />
        <g transform={`translate(${ex + CS / 2 + 78} ${ey}) scale(${0.8 + 0.25 * done})`}><KeyIcon x={0} y={0} s={1.3} color={C.ink} /></g>
      </Svg>
      <Seq t={t} x={540} y={330} items={[[0.2, <span style={{ fontFamily: DISPLAY, fontSize: 96, color: C.ink }}>ON YOUR OWN</span>],
        [6.1, <span style={{ fontFamily: DISPLAY, fontSize: 96, color: C.blue }}>WITH A GUIDE</span>]]} />
      <div style={{ position: "absolute", left: 540, top: 450, transform: "translate(-50%,-50%)", display: "flex", alignItems: "center", gap: 40, opacity: r(t, 1.0, 1.3) }}>
        <div style={{ position: "relative", display: "flex", alignItems: "baseline", gap: 10, opacity: t > 6.2 ? 0.55 : 1 }}>
          <Odo value={weeks} size={64} color={C.ink} />{mono("WEEKS", C.ink, 30)}
          <div style={{ position: "absolute", left: -6, right: -6, top: "52%", height: 6, borderRadius: 3, background: C.red, transformOrigin: "left", transform: `scaleX(${r(t, 8.1, 8.5)})` }} />
        </div>
        {t > 6.2 && <div style={{ display: "flex", alignItems: "baseline", gap: 10, opacity: r(t, 6.2, 6.5) }}><Odo value={3 * gk} size={64} color={C.blue} />{mono("WEEKS", C.blue, 30)}</div>}
      </div>
      <SceneLine text="Paperwork is a maze. Hire the map." from={8.6} to={12} y={1352} color={C.ink} size={46} font={UI} />
      <Sounds list={[[0.1, "whoosh", 0.25], [0.7, "pop", 0.3], ...Array.from({ length: 10 }, (_, i) => [1.0 + i * 0.4, "tick", 0.15] as SL[number]),
        ...deadSeen.map((d) => [1.0 + d * WS, "impact", 0.18] as SL[number]), [5.35, "swish", 0.35], [6.1, "whoosh", 0.3], [6.3, "riser", 0.2], [8.0, "ding", 0.4], [8.1, "swish", 0.2], [8.6, "whoosh", 0.2]]} />
    </Full>
  );
};

// =====================================================================================================================
// m1-10 Venn: one white blob splits (liquid) into LOCATION / PRICE / YIELD; the triple overlap lights gold = the deal;
// then all three drain back into that gold centre, which becomes a BUY chip. Plate over Max.
const M110: React.FC = () => {
  const t = useT();
  const PW = 860, PH = 300;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const VX = 300, VY = 168, R0 = 82, OFF = 52;
  const split = r(t, 0.5, 1.5, LIQUID), merge = r(t, 8.6, 9.4, EASE_IO);
  const dirs = [[0, -1], [-0.866, 0.5], [0.866, 0.5]];
  const cols = [C.blue, C.green, C.orange], names = ["LOCATION", "PRICE", "YIELD"];
  const colour = r(t, 1.4, 1.9);
  const cs = dirs.map(([dx, dy]) => ({ x: VX + dx * OFF * split * (1 - merge), y: VY + dy * OFF * split * (1 - merge), R: R0 * (1 - merge * 0.75) }));
  const ticks = [2.2, 3.2, 4.2];
  const gold = r(t, 5.4, 5.9);
  const chip = r(t, 9.4, 9.9, POP);
  const pct = r(t, 6.0, 7.2, EASE_IO);
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs>
            <Goo id="m1-10goo" b={9} />
            <clipPath id="m1-10a"><circle cx={cs[0].x} cy={cs[0].y} r={cs[0].R} /></clipPath>
            <clipPath id="m1-10b"><circle cx={cs[1].x} cy={cs[1].y} r={cs[1].R} /></clipPath>
          </defs>
          <g filter="url(#m1-10goo)" opacity={1 - colour}>
            {cs.map((c, i) => <circle key={i} cx={c.x} cy={c.y} r={c.R * r(t, 0.15 + i * 0.05, 0.6, POP)} fill="#fff" />)}
          </g>
          {colour > 0 && cs.map((c, i) => {
            const on = r(t, ticks[i], ticks[i] + 0.3);
            return <circle key={i} cx={c.x} cy={c.y} r={c.R} fill={cols[i]} fillOpacity={(0.22 + 0.2 * on) * colour * (1 - merge)} stroke={cols[i]} strokeWidth={5} strokeOpacity={colour * (1 - merge)} />;
          })}
          <g clipPath="url(#m1-10a)"><g clipPath="url(#m1-10b)">
            <circle cx={cs[2].x} cy={cs[2].y} r={cs[2].R} fill={C.gold} opacity={gold * (1 - chip)} />
          </g></g>
          {merge > 0.6 && <circle cx={VX} cy={VY} r={lerp(30, 36, merge) * (1 - chip)} fill={C.gold} />}
        </svg>
        <Txt x={VX} y={VY + 8} size={28} font={MONO} weight={700} ls={2} color={C.ink} k={r(t, 5.7, 6.0, POP) * (1 - r(t, 8.5, 8.7))}>✓</Txt>
        <div style={{ position: "absolute", left: 470, top: 34, display: "flex", flexDirection: "column", gap: 14, opacity: 1 - r(t, 8.4, 8.8) }}>
          {names.map((nm, i) => { const kk = r(t, ticks[i], ticks[i] + 0.3, POP); return (
            <div key={nm} style={{ display: "flex", alignItems: "center", gap: 14, opacity: 0.35 + 0.65 * clamp(kk), transform: `translateX(${(1 - clamp(kk)) * 12}px)` }}>
              <div style={{ width: 22, height: 22, borderRadius: 11, background: cols[i] }} />
              {mono(nm, "#fff", 30)}{kk > 0 && <span style={{ color: cols[i], fontFamily: UI, fontWeight: 900, fontSize: 30, transform: `scale(${kk})` }}>✓</span>}
            </div>); })}
          <div style={{ display: "flex", alignItems: "baseline", gap: 10, opacity: r(t, 5.9, 6.2), marginTop: 2 }}>
            <Odo value={3 * pct} size={56} color={C.gold} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 44, color: C.gold }}>%</span>
            {mono("OF LISTINGS", "rgba(255,255,255,0.8)", 28)}
          </div>
        </div>
        <div style={{ position: "absolute", left: VX, top: VY, transform: `translate(-50%,-50%) scale(${chip})`, background: C.gold, color: C.ink, borderRadius: 40,
          padding: "16px 34px", fontFamily: UI, fontWeight: 900, fontSize: 52, whiteSpace: "nowrap", opacity: clamp(chip * 2) }}>BUY THIS ONE</div>
        <Txt x={500} y={168} anchor="l" size={58} font={SERIF} weight={400} ls={0} k={r(t, 9.7, 10.2)}>the overlap</Txt>
      </Plate>
      <DemoCaption text="Great location. Fair price. Real yield." from={0.4} to={5.2} />
      <DemoCaption text="Only about 3% of listings tick all three." from={5.4} to={8.5} />
      <DemoCaption text="That's the one you buy." from={8.8} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.3], [0.5, "swish", 0.3], [1.4, "pop", 0.2], ...ticks.map((x) => [x, "tick", 0.4] as SL[number]), [5.4, "ding", 0.4], [6.0, "riser", 0.15],
        [8.6, "swish", 0.3], [9.4, "impact", 0.3], [9.5, "pop", 0.35], [9.7, "whoosh", 0.2]]} />
    </AbsoluteFill>
  );
};
// =====================================================================================================================
const wedge = (cx: number, cy: number, R: number, a0: number, a1: number) => {
  const p = (a: number) => `${(cx + Math.cos(a) * R).toFixed(1)} ${(cy + Math.sin(a) * R).toFixed(1)}`;
  return `M ${cx} ${cy} L ${p(a0)} A ${R} ${R} 0 ${a1 - a0 > Math.PI ? 1 : 0} 1 ${p(a1)} Z`;
};

// m1-11 Payment plan pie: a price disc sweeps in, splits into 10 / 50 / 40 slices, each slice flies down and melts
// (liquid) into its bar on a timeline; a big 60/40 lands where the pie was. Full-screen ink scene.
const M111: React.FC = () => {
  const t = useT();
  const CX = 540, CY = 730, R = 230;
  const sweep = r(t, 0.2, 1.1, EASE_IO);
  const S = [{ p: 10, c: C.gold, n: "BOOKING" }, { p: 50, c: C.blue, n: "BUILD" }, { p: 40, c: C.green, n: "HANDOVER" }];
  let acc = -Math.PI / 2;
  const BX = 120, BW = 780 - 16, BY = 1150, BH = 96;
  let bx = BX;
  const parts = S.map((s, i) => {
    const a0 = acc, a1 = acc + (s.p / 100) * Math.PI * 2; acc = a1;
    const mid = (a0 + a1) / 2;
    const w = (BW * s.p) / 100, x = bx; bx += w + 8;
    return { ...s, a0, a1, mid, bx: x, bw: w, fly: 3.6 + i * 0.55 };
  });
  const explode = r(t, 1.3, 1.8, LIQUID);
  const big = r(t, 6.2, 6.8, POP);
  const brace = r(t, 8.0, 8.6, EASE_IO);
  return (
    <Full bg="#111113">
      <Svg>
        <defs>{parts.map((_, i) => <Goo key={i} id={`m1-11g${i}`} b={9} />)}</defs>
        {parts.map((s, i) => {
          const f = r(t, s.fly, s.fly + 0.85, EASE_IO);
          const a1 = Math.min(s.a1, -Math.PI / 2 + sweep * Math.PI * 2);
          if (a1 <= s.a0 + 0.001) return null;
          const ox = Math.cos(s.mid) * 26 * explode, oy = Math.sin(s.mid) * 26 * explode;
          const sx = lerp(CX + ox, s.bx + s.bw / 2, f), sy = lerp(CY + oy, BY + BH / 2, f);
          const shrink = 1 - r(t, s.fly + 0.2, s.fly + 0.8, EASE_IN);
          const bar = r(t, s.fly + 0.45, s.fly + 1.0, LIQUID);
          return (
            <g key={i} filter={f > 0 && bar < 1 ? `url(#m1-11g${i})` : undefined}>
              {shrink > 0 && <g transform={`translate(${sx} ${sy}) scale(${shrink})`}><path d={wedge(0, 0, R, s.a0, a1)} transform={`translate(${-Math.cos(s.mid) * R * 0.5 * f} ${-Math.sin(s.mid) * R * 0.5 * f})`} fill={s.c} /></g>}
              {bar > 0 && <rect x={s.bx + (s.bw * (1 - bar)) / 2} y={BY + (BH * (1 - Math.min(1, bar))) / 2} width={s.bw * bar} height={BH * Math.min(1.1, bar)} rx={22} fill={s.c} />}
            </g>
          );
        })}
        <path d={`M ${BX} ${BY - 26} L ${BX} ${BY - 44} L ${BX + (parts[1].bx + parts[1].bw - BX) * brace} ${BY - 44} L ${BX + (parts[1].bx + parts[1].bw - BX) * brace} ${BY - 26}`}
          fill="none" stroke={C.gold} strokeWidth={6} strokeLinejoin="round" opacity={brace > 0 ? 1 : 0} />
        <path d={`M ${parts[2].bx} ${BY - 26} L ${parts[2].bx} ${BY - 44} L ${parts[2].bx + parts[2].bw * brace} ${BY - 44} L ${parts[2].bx + parts[2].bw * brace} ${BY - 26}`}
          fill="none" stroke={C.green} strokeWidth={6} strokeLinejoin="round" opacity={brace > 0 ? 1 : 0} />
      </Svg>
      {parts.map((s, i) => {
        const k1 = r(t, 1.5 + i * 0.25, 1.9 + i * 0.25, POP) * (1 - r(t, s.fly - 0.1, s.fly + 0.15));
        const lx = CX + Math.cos(s.mid) * (R * 0.62 + 26), ly = CY + Math.sin(s.mid) * (R * 0.62 + 26);
        const kb = r(t, s.fly + 0.9, s.fly + 1.2, POP);
        return (
          <React.Fragment key={i}>
            {k1 > 0 && <div style={{ position: "absolute", left: lx, top: ly, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * k1})`, opacity: clamp(k1 * 2), display: "flex", alignItems: "baseline" }}>
              <Odo value={s.p * r(t, 1.5 + i * 0.25, 2.4 + i * 0.25, EASE_IO)} size={i === 0 ? 44 : 72} color={C.ink} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: i === 0 ? 34 : 52, color: C.ink }}>%</span></div>}
            <Txt x={s.bx + s.bw / 2} y={BY + BH / 2} size={i === 0 ? 30 : 46} color={C.ink} k={kb}>{s.p}%</Txt>
            <Tag x={i === 0 ? s.bx : s.bx + s.bw / 2} anchor={i === 0 ? "l" : "c"} y={BY + BH + 40} size={28} color="rgba(255,255,255,0.75)" k={kb}>{s.n}</Tag>
          </React.Fragment>
        );
      })}
      <Tag x={540} y={330} size={36} color="rgba(255,255,255,0.75)" k={r(t, 0.1, 0.5)}>OFF-PLAN PAYMENT PLAN</Tag>
      <div style={{ position: "absolute", left: 540, top: 720, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * big})`, opacity: clamp(big * 2), display: "flex", alignItems: "center", gap: 10 }}>
        <Odo value={60 * r(t, 6.2, 7.2, EASE_IO)} size={250} color={C.blue} font={DISPLAY} weight={400} />
        <span style={{ fontFamily: DISPLAY, fontSize: 200, color: "rgba(255,255,255,0.35)" }}>/</span>
        <Odo value={40 * r(t, 6.4, 7.4, EASE_IO)} size={250} color={C.green} font={DISPLAY} weight={400} />
      </div>
      <Tag x={BX} anchor="l" y={BY - 80} size={28} color={C.gold} k={r(t, 8.4, 8.8, POP)}>BEFORE KEYS</Tag>
      <Tag x={parts[2].bx} anchor="l" y={BY - 80} size={28} color={C.green} k={r(t, 8.6, 9.0, POP)}>ON KEYS</Tag>
      <SceneLine text="You don't pay it all on day one." from={9.4} to={12} y={480} color="#fff" size={62} />
      <Sounds list={[[0.2, "whoosh", 0.3], [1.3, "pop", 0.35], [1.5, "tick", 0.25], [1.75, "tick", 0.25], [2.0, "tick", 0.25], ...parts.flatMap((s) => [[s.fly, "swish", 0.3], [s.fly + 0.9, "pop", 0.3]] as SL),
        [6.2, "impact", 0.35], [7.3, "ding", 0.3], [8.0, "swish", 0.25], [8.5, "tick", 0.3], [9.4, "whoosh", 0.2]]} />
    </Full>
  );
};


// =====================================================================================================================
// m1-13 Property ladder: steps pour out of each other (liquid) — STUDIO, 1-BED, TOWNHOUSE, VILLA — and a white dot
// hops up, growing each step; PROPERTIES counts up. Full-screen green scene.
const M113: React.FC = () => {
  const t = useT();
  const N = ["STUDIO", "1-BED", "TOWNHOUSE", "VILLA"];
  const SW = 190, X0 = 140, BASE = 1230, SH = 230;
  const born = (i: number) => 0.4 + i * 2.1;
  const steps = N.map((_, i) => {
    const g = r(t, born(i), born(i) + 0.7, LIQUID);
    const h = (i + 1) * SH * 0.62 + 40;
    return { x: X0 + i * SW, top: BASE - h, h, g };
  });
  // dot hops onto step i at born(i)+0.8
  const hop = (i: number) => born(i) + 0.8;
  let si = -1; N.forEach((_, i) => { if (t >= hop(i)) si = i; });
  const hk = si >= 0 ? r(t, hop(si), hop(si) + 0.5, EASE_IO) : 0;
  const from = si <= 0 ? { x: X0 + SW / 2 - 140, y: BASE } : { x: steps[si - 1].x + SW / 2, y: steps[si - 1].top };
  const to = si < 0 ? from : { x: steps[si].x + SW / 2, y: steps[si].top };
  const rad = 26 + Math.max(0, si) * 9 * hk + (si > 0 ? (si - 1) * 9 * (1 - hk) : 0);
  const dx = lerp(from.x, to.x, hk), dy = lerp(from.y, to.y, hk) - Math.sin(hk * Math.PI) * 120 - rad - Math.max(0, Math.sin(t * 4)) * 3;
  const squash = si >= 0 ? 1 - Math.max(0, Math.sin(r(t, hop(si) + 0.45, hop(si) + 0.7) * Math.PI)) * 0.25 : 1;
  const fin = r(t, 9.2, 9.9, LIQUID);
  const owned = N.reduce((a, _, i) => a + r(t, hop(i) + 0.4, hop(i) + 0.6), 0);
  return (
    <Full bg="#1E8E4E">
      <Svg>
        <defs><Goo id="m1-13goo" b={10} /></defs>
        <g filter="url(#m1-13goo)">
          {steps.map((s, i) => {
            if (s.g <= 0) return null;
            // each step is poured from the previous one: grows rightwards out of its neighbour
            const w = SW * s.g, h = lerp(i ? steps[i - 1].h : 30, s.h, s.g);
            return <rect key={i} x={s.x} y={BASE - h} width={w + 2} height={h + 60} rx={14} fill="#fff" />;
          })}
        </g>
        <ellipse cx={dx} cy={dy + rad * (1 - squash)} rx={rad * (2 - squash)} ry={rad * squash} fill={C.gold} />
      </Svg>
      {steps.map((s, i) => <Tag key={i} x={s.x + SW / 2} y={s.top + 44} size={28} color="#1E8E4E" k={r(t, born(i) + 0.5, born(i) + 0.8, POP)}>{N[i]}</Tag>)}
      <div style={{ position: "absolute", left: 120, top: 400, display: "flex", alignItems: "baseline", gap: 18, opacity: r(t, 0.2, 0.5) }}>
        <Odo value={owned} size={150} color="#fff" font={DISPLAY} weight={400} />
        <span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 38, letterSpacing: 3, color: "rgba(255,255,255,0.85)", whiteSpace: "nowrap" }}>{Math.round(owned) === 1 ? "PROPERTY" : "PROPERTIES"}</span>
      </div>
      <Tag x={120} y={350} anchor="l" size={30} color="rgba(255,255,255,0.8)" k={r(t, 0.3, 0.7)}>THE PROPERTY LADDER</Tag>
      <Txt x={500} y={1370} size={56} font={SERIF} weight={400} ls={0} color="#fff" k={fin}>Start with the first step.</Txt>
      <Sounds list={[...N.flatMap((_, i) => [[born(i), "swish", 0.3], [hop(i) + 0.45, "pop", 0.4], [born(i) + 0.55, "tick", 0.25]] as SL), [8.0, "riser", 0.15], [hop(3) + 0.5, "ding", 0.4], [9.2, "whoosh", 0.25]]} />
    </Full>
  );
};

// =====================================================================================================================
// m1-14 Tug of war: BUYER (blue) and SELLER (red) pull the price knot back and forth while the price ticks up; a gold
// agent drops on the knot, the rope slackens, both sides walk in and merge (liquid) into one green DEAL. Plate over Max.
const M114: React.FC = () => {
  const t = useT();
  const PW = 860, PH = 280;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const RY = 186;
  const calm = r(t, 5.0, 5.8, EASE_IO);
  const off = (Math.sin(t * 2.2) * 44 + Math.sin(t * 5.3) * 10) * (1 - calm) * r(t, 0.4, 1.0);
  const walk = r(t, 5.8, 7.6, EASE_IO);
  const green = r(t, 7.5, 7.9), merge = r(t, 7.7, 8.5, EASE_IO), chip = r(t, 8.4, 9.0, LIQUID);
  const KX = 430 + off;
  const team = (side: -1 | 1) => [0, 1, 2].map((j) => {
    const base = 430 + side * (250 + j * 52);
    const lean = side * Math.max(0, side * off) * 0.0 + off * 0.9;
    const x0 = base + lean;
    const x = lerp(lerp(x0, 430 + side * (70 + j * 46), walk), 430, merge);
    return { x, y: RY + Math.sin(t * 6 + j + side) * 3 * (1 - walk) };
  });
  const L = team(-1), R = team(1);
  const sag = walk * 40;
  const price = 1850 + 100 * r(t, 0.6, 7.0, EASE_IO);
  const one = green > 0.5;
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-14gA" b={8} /><Goo id="m1-14gB" b={8} /><Goo id="m1-14gC" b={8} /></defs>
          {merge < 0.6 && <path d={`M ${L[2].x} ${RY} Q ${KX} ${RY + sag} ${R[2].x} ${RY}`} fill="none" stroke="#E5E5EA" strokeWidth={8} strokeLinecap="round" opacity={1 - merge / 0.6} />}
          {!one && <g filter="url(#m1-14gA)">{L.map((p, j) => <circle key={j} cx={p.x} cy={p.y} r={26} fill={C.blue} />)}</g>}
          {!one && <g filter="url(#m1-14gB)">{R.map((p, j) => <circle key={j} cx={p.x} cy={p.y} r={26} fill={C.red} />)}</g>}
          {one && <g filter="url(#m1-14gC)">
            {[...L, ...R].map((p, j) => <circle key={j} cx={p.x} cy={p.y} r={26 * (1 - chip * 0.5)} fill={C.green} />)}
            {chip > 0 && <rect x={430 - 170 * chip} y={RY - 46} width={340 * chip} height={92} rx={46} fill={C.green} />}
          </g>}
          {merge < 0.5 && <g transform={`translate(${KX} ${RY + sag * 0.5})`}>
            <rect x={-10} y={-26} width={20} height={52} rx={6} fill={C.gold} opacity={1 - merge * 2} />
            {t > 4.9 && <circle cx={0} cy={lerp(-150, -54, r(t, 4.9, 5.3, EASE_IN))} r={24 * r(t, 4.9, 5.0)} fill={C.gold} opacity={1 - merge * 2} />}
          </g>}
        </svg>
        <Tag x={40} y={40} anchor="l" color={C.blue} k={1 - green}>BUYER</Tag>
        <Tag x={PW - 40} y={40} anchor="r" color={C.red} k={1 - green}>SELLER</Tag>
        <div style={{ position: "absolute", left: 430, top: 40, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 8, whiteSpace: "nowrap" }}>
          {mono("AED", "rgba(255,255,255,0.6)", 28)}<Odo value={price} size={56} color={one ? C.green : "#fff"} />{mono("K", "rgba(255,255,255,0.6)", 28)}
        </div>
        <Tag x={KX} y={RY - 92} size={28} color={C.gold} k={r(t, 5.3, 5.6, POP) * (1 - r(t, 7.4, 7.6))}>AGENT</Tag>
        <Txt x={430} y={RY} size={52} color={C.ink} k={r(t, 8.8, 9.2, POP)}>DEAL ✓</Txt>
      </Plate>
      <DemoCaption text="Buyer pulls one way, seller the other." from={0.4} to={4.8} />
      <DemoCaption text="My job is the middle." from={5.0} to={7.6} />
      <DemoCaption text="Both walk away happy." from={7.8} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.3], [0.6, "swish", 0.2], [1.9, "swish", 0.2], [3.3, "swish", 0.2], [4.9, "whoosh", 0.2], [5.3, "impact", 0.3], [5.8, "swish", 0.2], [7.5, "tick", 0.3], [7.8, "swish", 0.3], [8.5, "pop", 0.4], [8.9, "ding", 0.4]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-15 Crowd vs early: 60 ink dots flock into the hyped zone and pack into a blob; one gold dot goes to an empty zone;
// years pass, the crowd pours across in a liquid stream and the gold dot grows. Full-screen paper scene.
const CROWD = Array.from({ length: 60 }, (_, i) => ({ x: 110 + rand(i + 40) * 780, y: 420 + rand(i + 140) * 1000, i }));
const M115: React.FC = () => {
  const t = useT();
  const A = { x: 700, y: 720 }, B = { x: 330, y: 1150 };
  const flock = (i: number) => r(t, 0.9 + rand(i) * 0.6, 2.6 + rand(i) * 0.6, EASE_IO);
  const pour = (i: number) => r(t, 5.6 + rand(i * 3) * 1.2, 6.6 + rand(i * 3) * 1.2, EASE_IO);
  const slotA = (i: number) => { const a = i * 2.4, d = Math.sqrt(i / 60) * 120; return { x: A.x + Math.cos(a) * d, y: A.y + Math.sin(a) * d }; };
  const slotB = (i: number) => { const a = i * 2.4, d = 60 + Math.sqrt(i / 60) * 120; return { x: B.x + Math.cos(a) * d, y: B.y + Math.sin(a) * d * 0.9 }; };
  let inB = 1;
  const dots = CROWD.map((d) => {
    const f = flock(d.i), p = pour(d.i);
    const sa = slotA(d.i), sb = slotB(d.i);
    const x = lerp(lerp(d.x, sa.x, f), sb.x, p), y = lerp(lerp(d.y, sa.y, f), sb.y, p) + Math.sin(t * 2 + d.i) * 4 * (1 - f) - Math.sin(p * Math.PI) * 40;
    inB += r(t, 6.4 + rand(d.i * 3) * 1.2, 6.6 + rand(d.i * 3) * 1.2);
    return <circle key={d.i} cx={x} cy={y} r={15 * r(t, 0.02 * (d.i % 15), 0.3 + 0.02 * (d.i % 15), POP)} fill={C.ink} />;
  });
  const g0 = r(t, 1.0, 2.6, EASE_IO);
  const gx = lerp(540, B.x, g0), gy = lerp(1000, B.y, g0);
  const grow = r(t, 6.2, 8.4, EASE_IO);
  const zoneA = r(t, 0.5, 0.9, POP), zoneB = r(t, 2.2, 2.6, POP);
  return (
    <Full bg={C.paper}>
      <Svg>
        <defs><Goo id="m1-15goo" b={10} /></defs>
        <circle cx={A.x} cy={A.y} r={190 * zoneA} fill="none" stroke={C.red} strokeWidth={6} strokeDasharray="14 12" opacity={1 - r(t, 7.6, 8.2) * 0.7} />
        <circle cx={B.x} cy={B.y} r={210 * zoneB} fill="none" stroke={C.gold} strokeWidth={6} strokeDasharray="14 12" />
        <g filter="url(#m1-15goo)">{dots}</g>
        <circle cx={gx} cy={gy} r={lerp(22, 62, grow) * r(t, 0.1, 0.4, POP)} fill={C.gold} stroke={C.ink} strokeWidth={5} />
      </Svg>
      <Tag x={A.x} y={A.y - 225} size={30} color={C.red} k={zoneA}>EVERYONE'S BUYING</Tag>
      <Tag x={B.x} y={B.y - 245} size={30} color={C.ink} k={zoneB}>NOBODY'S HERE (YET)</Tag>
      <div style={{ position: "absolute", left: 540, top: 330, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 18, opacity: r(t, 0.1, 0.4) }}>
        <Odo value={2026 + r(t, 4.0, 5.6, (x) => Math.round(x * 3) / 3) * 3} size={130} color={C.ink} font={DISPLAY} weight={400} />
      </div>
      <div style={{ position: "absolute", left: B.x + 230, top: B.y + 10, transform: "translate(0,-50%)", display: "flex", alignItems: "baseline", gap: 12, opacity: r(t, 2.6, 3.0) }}>
        <Odo value={inB} size={84} color={C.ink} />{mono(inB >= 2 ? "BUYERS" : "BUYER", C.ink, 30)}
      </div>
      <SceneLine text="Be early, not crowded." from={8.6} to={12} y={1330} color={C.ink} size={70} />
      <Sounds list={[[0.1, "pop", 0.25], [0.5, "pop", 0.3], [1.0, "whoosh", 0.3], [2.2, "pop", 0.3], [2.7, "tick", 0.2], [4.0, "tick", 0.3], [4.55, "tick", 0.3], [5.1, "tick", 0.3], [5.6, "riser", 0.2],
        [6.0, "swish", 0.35], [6.8, "swish", 0.25], [8.4, "ding", 0.35], [8.6, "whoosh", 0.2]]} />
    </Full>
  );
};
// =====================================================================================================================
// m1-16 Puzzle: four coloured jigsaw pieces (PRICE, AREA, TIMING, FINANCE) fly in and snap into a square; then they
// turn white and melt (liquid) into one round green READY check. Plate over Max.
const M116: React.FC = () => {
  const t = useT();
  const PW = 820, PH = 300;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const CX = 200, CY = 150, S = 116;
  const P = [
    { n: "PRICE", c: C.blue, gx: -1, gy: -1, from: [-160, -120], knobs: [[1, 0], [0, 1]] },
    { n: "AREA", c: C.green, gx: 1, gy: -1, from: [560, -140], knobs: [[0, 1]] },
    { n: "TIMING", c: C.orange, gx: -1, gy: 1, from: [-140, 420], knobs: [[1, 0]] },
    { n: "FINANCE", c: C.purple, gx: 1, gy: 1, from: [600, 420], knobs: [] as number[][] },
  ];
  const snap = (i: number) => 1.0 + i * 1.1;
  const melt = r(t, 6.6, 7.4, EASE_IO), round = r(t, 7.2, 8.0, LIQUID), white = r(t, 6.2, 6.6);
  const pieces = P.map((p, i) => {
    const f = r(t, snap(i) - 0.6, snap(i), EASE_IN);
    const tx = CX + (p.gx * S) / 2, ty = CY + (p.gy * S) / 2;
    const x = lerp(p.from[0], tx, f), y = lerp(p.from[1], ty, f) ;
    const xm = lerp(x, CX, melt), ym = lerp(y, CY, melt);
    const sc = 1 - melt * 0.35;
    return { ...p, x: xm, y: ym, sc, on: t >= snap(i) - 0.6 };
  });
  const shape = (p: typeof pieces[number], fill: string) => (
    <g transform={`translate(${p.x} ${p.y}) scale(${p.sc})`}>
      <rect x={-S / 2} y={-S / 2} width={S} height={S} rx={lerp(10, S / 2, melt)} fill={fill} />
      {p.knobs.map(([kx, ky], j) => <circle key={j} cx={(kx * S) / 2} cy={(ky * S) / 2} r={22 * (1 - melt)} fill={fill} />)}
    </g>
  );
  const ticks = P.map((_, i) => r(t, snap(i), snap(i) + 0.3, POP));
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-16goo" b={9} /></defs>
          <rect x={CX - S} y={CY - S} width={S * 2} height={S * 2} rx={12} fill="none" stroke="rgba(255,255,255,0.2)" strokeWidth={3} strokeDasharray="10 10" opacity={1 - r(t, 4.4, 4.8)} />
          {white < 1 && pieces.filter((p) => p.on).map((p, i) => <g key={i} opacity={1 - white}>{shape(p, p.c)}</g>)}
          {white > 0 && <g filter="url(#m1-16goo)">
            {round < 1 && pieces.map((p, i) => <g key={i}>{shape(p, mix("#FFFFFF", C.green, round))}</g>)}
            <circle cx={CX} cy={CY} r={112 * round} fill={C.green} />
          </g>}
          {round > 0.6 && <path d={`M ${CX - 46} ${CY + 2} L ${CX - 12} ${CY + 36} L ${CX + 50} ${CY - 34}`} fill="none" stroke="#fff" strokeWidth={18} strokeLinecap="round" strokeLinejoin="round"
            pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - r(t, 7.8, 8.3, EASE_IO)} />}
        </svg>
        {pieces.map((p, i) => <Txt key={i} x={p.x} y={p.y} size={26} font={MONO} weight={700} ls={1} k={r(t, snap(i), snap(i) + 0.2) * (1 - white)}>{p.n}</Txt>)}
        <div style={{ position: "absolute", left: 400, top: 34, display: "flex", flexDirection: "column", gap: 12, opacity: 1 - r(t, 7.0, 7.4) }}>
          {P.map((p, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 14, opacity: 0.35 + 0.65 * clamp(ticks[i]) }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: ticks[i] > 0.5 ? p.c : "rgba(255,255,255,0.15)", color: "#fff", fontSize: 22, fontWeight: 900, fontFamily: UI,
                display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${0.8 + 0.2 * ticks[i]})` }}>{ticks[i] > 0.5 ? "✓" : ""}</div>
              {mono(p.n, "#fff", 30)}
            </div>))}
        </div>
        <Txt x={390} y={120} anchor="l" size={70} font={DISPLAY} weight={400} ls={1} k={r(t, 7.6, 8.1, POP)}>READY TO BUY</Txt>
        <Tag x={404} y={196} anchor="l" size={28} color={C.green} k={r(t, 8.2, 8.6, POP)}>ALL FOUR PIECES FIT</Tag>
      </Plate>
      <DemoCaption text="Price, area, timing, finance…" from={0.4} to={4.8} />
      <DemoCaption text="when every piece fits," from={5.0} to={7.2} />
      <DemoCaption text="that's when you buy." from={7.4} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.3], ...P.flatMap((_, i) => [[snap(i) - 0.6, "whoosh", 0.18], [snap(i), "impact", 0.28], [snap(i) + 0.05, "tick", 0.3]] as SL), [6.2, "swish", 0.2], [6.6, "swish", 0.3], [7.4, "pop", 0.4], [7.9, "ding", 0.4], [8.2, "tick", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-17 Share tree: one video seeds a tree — 3 shares, 9, 27 viewers bloom as branches draw; two leaves turn gold
// (clients) and gold sap flows back down the branches to the root. Full-screen deep-teal scene.
type TNode = { x: number; y: number; p: number; lvl: number; at: number };
const TREE: TNode[] = (() => {
  const n: TNode[] = [{ x: 540, y: 1290, p: -1, lvl: 0, at: 0.4 }];
  const LY = [1290, 1040, 820, 630], SP = [0, 250, 84, 27];
  for (let l = 1; l <= 3; l++) {
    n.filter((q) => q.lvl === l - 1).forEach((q) => {
      const pi = n.indexOf(q);
      [-1, 0, 1].forEach((d, j) => n.push({ x: q.x + d * SP[l], y: LY[l] + (l === 3 ? (j === 1 ? -14 : 8) : 0), p: pi, lvl: l, at: [0, 1.3, 2.6, 3.9][l] + j * 0.12 + rand(pi + j) * 0.25 }));
    });
  }
  return n;
})();
const M117: React.FC = () => {
  const t = useT();
  const GOLD = [TREE.length - 9, TREE.length - 22];
  const goldAt = 6.0;
  const isPath = (i: number) => { const s = new Set<number>(); GOLD.forEach((g) => { let c = g; while (c >= 0) { s.add(c); c = TREE[c].p; } }); return s.has(i); };
  const sap = (i: number) => { const lvl = TREE[i].lvl; const a = goldAt + 0.6 + (3 - lvl) * 0.55; return r(t, a, a + 0.55, EASE_IO); };
  let views = 0;
  const branches: React.ReactNode[] = [], nodes: React.ReactNode[] = [], sapEls: React.ReactNode[] = [];
  TREE.forEach((q, i) => {
    const pop = r(t, q.at + 0.35, q.at + 0.6, POP);
    if (i > 0) {
      const pa = TREE[q.p], g = r(t, q.at, q.at + 0.45, EASE_IO);
      const d = `M ${pa.x} ${pa.y} C ${pa.x} ${lerp(pa.y, q.y, 0.6)}, ${q.x} ${lerp(pa.y, q.y, 0.4)}, ${q.x} ${q.y}`;
      branches.push(<path key={`b${i}`} d={d} fill="none" stroke="rgba(255,255,255,0.85)" strokeWidth={[0, 12, 8, 5][q.lvl]} strokeLinecap="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - g} />);
      if (isPath(i)) { const sk = sap(i); sapEls.push(<path key={`s${i}`} d={d} fill="none" stroke={C.gold} strokeWidth={[0, 16, 12, 9][q.lvl]} strokeLinecap="round" pathLength={1} strokeDasharray="1 1" strokeDashoffset={-(1 - sk)} opacity={sk > 0 ? 1 : 0} />); }
    }
    views += q.lvl > 0 ? r(t, q.at + 0.35, q.at + 0.5) : 0;
    const gold = (GOLD.includes(i) ? r(t, goldAt, goldAt + 0.35) : 0) || (i === 0 ? r(t, goldAt + 0.6 + 3 * 0.55 + 0.4, goldAt + 0.6 + 3 * 0.55 + 0.7) : 0);
    const rad = [62, 24, 16, 11][q.lvl] * (i === 0 ? 1 + gold * 0.25 : 1) * (GOLD.includes(i) ? 1 + 0.6 * gold : 1);
    nodes.push(<circle key={`n${i}`} cx={q.x} cy={q.y + Math.sin(t * 2 + i) * (q.lvl === 3 ? 3 : 0)} r={rad * (i === 0 ? r(t, 0.1, 0.5, POP) : pop)} fill={mix("#FFFFFF", C.gold, gold)} />);
  });
  return (
    <Full bg="#0F3D3E">
      <Svg>{branches}{sapEls}{nodes}</Svg>
      <Tag x={540} y={1290} size={24} color="#0F3D3E" k={r(t, 0.3, 0.6) * (1 - r(t, 8.4, 8.6))}>VIDEO</Tag>
      <Txt x={540} y={1290} size={30} font={MONO} weight={700} ls={1} color={C.ink} k={r(t, 8.6, 8.9, POP)}>YOU</Txt>
      <div style={{ position: "absolute", left: 540, top: 360, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 16, opacity: r(t, 1.2, 1.5) }}>
        <Odo value={views} size={130} color="#fff" /><span style={{ fontFamily: MONO, fontWeight: 700, fontSize: 38, letterSpacing: 3, color: "rgba(255,255,255,0.8)", whiteSpace: "nowrap" }}>SHARES</span>
      </div>
      <Tag x={540} y={490} size={32} color={C.gold} k={r(t, goldAt + 0.1, goldAt + 0.4, POP)}>2 OF THEM BECAME CLIENTS</Tag>
      <SceneLine text="Content you post once keeps branching." from={9.2} to={12} y={1360} color="#fff" size={52} />
      <Sounds list={[[0.1, "pop", 0.35], [1.3, "swish", 0.25], [1.65, "pop", 0.25], [2.6, "swish", 0.25], [2.95, "tick", 0.25], [3.1, "tick", 0.2], [3.9, "swish", 0.25], [4.25, "tick", 0.2], [4.45, "tick", 0.2], [4.65, "tick", 0.2],
        [goldAt, "ding", 0.35], [goldAt + 0.6, "riser", 0.2], [goldAt + 0.65, "swish", 0.2], [goldAt + 1.2, "swish", 0.2], [goldAt + 1.75, "swish", 0.2], [8.6, "impact", 0.3], [9.2, "whoosh", 0.2]]} />
    </Full>
  );
};

// =====================================================================================================================
// m1-18 Sieve: 40 listings rest on a mesh; each shake (filter) drops the small ones through into a grey liquid pool;
// three big ones stay and turn gold. Plate over Max.
const LIST18 = Array.from({ length: 36 }, (_, i) => ({ i, x: 70 + (i % 18) * 40 + (Math.floor(i / 18) ? 20 : 0), size: [8, 10, 12, 14][Math.floor(rand(i + 77) * 4)], round: 1 + Math.floor(rand(i + 5) * 3) }))
  .map((d) => (d.i === 7 || d.i === 20 || d.i === 31 ? { ...d, size: 22, round: 9 } : d));
const M118: React.FC = () => {
  const t = useT();
  const PW = 860, PH = 300;
  const k = r(t, 0, 0.45, LIQUID) * (1 - r(t, 11.6, 12, EASE_IN));
  const MY = 170, SH = [1.5, 3.5, 5.5], FIL = ["OVERPRICED", "WRONG AREA", "BAD LAYOUT"];
  const shakeAmt = SH.reduce((a, s) => a + (t > s && t < s + 0.9 ? Math.sin((t - s) * 40) * 12 * (1 - (t - s) / 0.9) : 0), 0);
  const gather = r(t, 7.4, 8.2, EASE_IO);
  let gone = 0;
  const pool = (n: number) => 6 + n * 0.9;
  const els = LIST18.map((d) => {
    const st = d.round <= 3 ? SH[d.round - 1] + 0.15 + rand(d.i) * 0.4 : 99;
    const f = r(t, st, st + 0.5, EASE_IN);
    gone += r(t, st + 0.35, st + 0.5);
    const row = d.i < 18 ? 0 : 1;
    const y0 = MY - d.size - 4 - row * 34;
    const x = d.x + shakeAmt + Math.sin(t * 2 + d.i) * 1.5;
    if (f >= 1) return null;
    return { key: d.i, x, y: lerp(y0, PH - 10, f), rr: d.size, falling: f > 0 };
  }).filter(Boolean) as { key: number; x: number; y: number; rr: number; falling: boolean }[];
  const keepers = LIST18.filter((d) => d.round === 9);
  const kx = (j: number) => 300 + j * 130;
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={262} w={PW} h={PH} k={k}>
        <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
          <defs><Goo id="m1-18goo" b={7} /></defs>
          <g filter="url(#m1-18goo)">
            {els.filter((e) => e.falling).map((e) => <circle key={e.key} cx={e.x} cy={e.y} r={e.rr} fill="#636366" />)}
            <rect x={30} y={PH - 4 - pool(gone) * 0.7} width={PW - 60} height={60} rx={10} fill="#636366" />
          </g>
          {els.filter((e) => !e.falling && !keepers.some((q) => q.i === e.key)).map((e) => <circle key={e.key} cx={e.x} cy={e.y} r={e.rr} fill="#AEAEB2" />)}
          {keepers.map((d, j) => {
            const row = d.i < 18 ? 0 : 1, x0 = d.x + shakeAmt, y0 = MY - d.size - 4 - row * 34;
            const gold = r(t, 6.6, 7.0);
            return <circle key={d.i} cx={lerp(x0, kx(j), gather)} cy={lerp(y0, 120, gather)} r={d.size * (1 + gather * 0.9)} fill={mix("#AEAEB2", C.gold, gold)} />;
          })}
          {/* the mesh: a line with holes */}
          <g transform={`translate(${shakeAmt} 0)`} opacity={1 - gather * 0.8}>
            {Array.from({ length: 21 }, (_, j) => <line key={j} x1={40 + j * 37} x2={40 + j * 37 + 22} y1={MY} y2={MY} stroke="#fff" strokeWidth={6} strokeLinecap="round" />)}
          </g>
        </svg>
        <Seq t={t} x={230} y={34} items={[[0.2, mono("100 LISTINGS", "rgba(255,255,255,0.75)", 28)], ...SH.map((s, i) => [s, mono(`✕ ${FIL[i]}`, C.red, 28)] as [number, React.ReactNode]), [6.6, mono("WORTH A VIEWING", C.gold, 28)]]} />
        <div style={{ position: "absolute", right: 36, top: 10, display: "flex", alignItems: "baseline", gap: 10 }}>
          <Odo value={Math.round(gone * (97 / 33) * 4) / 4} size={50} color="#fff" />{mono("FILTERED", "rgba(255,255,255,0.7)", 28)}
        </div>
        <Txt x={kx(1)} y={232} size={54} font={SERIF} weight={400} ls={0} k={r(t, 8.3, 8.8)}>these three</Txt>
      </Plate>
      <DemoCaption text="A hundred listings." from={0.4} to={1.4} />
      <DemoCaption text="I shake out the bad ones…" from={1.5} to={6.4} />
      <DemoCaption text="you only see the three worth seeing." from={6.6} to={11.8} />
      <Sounds list={[[0.05, "pop", 0.3], ...SH.flatMap((s) => [[s, "swish", 0.3], [s + 0.3, "tick", 0.2], [s + 0.6, "tick", 0.2]] as SL), [6.6, "ding", 0.4], [7.4, "whoosh", 0.25], [8.2, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-19 Speed to lead: one enquiry drop splits into two pipes. Big agency: a long zig-zag through inbox → manager →
// assistant → agent while HOURS climb. You: one straight pipe, replied in 4 minutes. Full-screen split scene.
const PIPE_L: [number, number][] = [[270, 620], [100, 700], [440, 800], [100, 900], [440, 1000], [100, 1100], [270, 1200]];
const PIPE_R: [number, number][] = [[810, 620], [810, 1200]];
const along = (pts: [number, number][], k: number): [number, number] => {
  const seg = pts.slice(1).map((p, i) => Math.hypot(p[0] - pts[i][0], p[1] - pts[i][1]));
  let d = clamp(k) * seg.reduce((a, b) => a + b, 0);
  for (let i = 0; i < seg.length; i++) { if (d <= seg[i] || i === seg.length - 1) { const f = seg[i] ? Math.min(1, d / seg[i]) : 0; return [lerp(pts[i][0], pts[i + 1][0], f), lerp(pts[i][1], pts[i + 1][1], f)]; } d -= seg[i]; }
  return pts[pts.length - 1];
};
const M119: React.FC = () => {
  const t = useT();
  const split = r(t, 0.5, 1.1, EASE_IO);
  const kR = r(t, 1.2, 2.0, EASE_IN), kL = r(t, 1.2, 9.0, (x) => x);
  const slug = (pts: [number, number][], kk: number, key: string) => [0, 0.012, 0.024, 0.036].map((o, j) => { const [x, y] = along(pts, Math.max(0, kk - o)); return <circle key={key + j} cx={x} cy={y} r={20 - j * 3} fill={C.blue} />; });
  const drop = <circle cx={540} cy={lerp(400, 560, r(t, 0, 0.5, EASE_IN))} r={26} fill={C.blue} />;
  const repl = r(t, 2.0, 2.3, POP), late = r(t, 9.0, 9.3, POP);
  const pathD = (pts: [number, number][]) => `M ${pts.map((p) => p.join(" ")).join(" L ")}`;
  const nodesL = ["INBOX", "MANAGER", "ASSISTANT", "AGENT"];
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ background: "#1C1C1E" }} />
      <div style={{ position: "absolute", left: 540, top: 0, width: 540, height: 1920, background: "#E8F4FF" }} />
      <Svg>
        <defs><Goo id="m1-19goo" b={9} /></defs>
        <path d={pathD(PIPE_L)} fill="none" stroke="#3A3A3C" strokeWidth={46} strokeLinejoin="round" strokeLinecap="round" />
        <path d={pathD(PIPE_R)} fill="none" stroke="#C7DDF5" strokeWidth={46} strokeLinecap="round" />
        <g filter="url(#m1-19goo)">
          {t < 1.3 && drop}
          {t < 1.3 && <><circle cx={lerp(540, 270, split)} cy={lerp(560, 620, split)} r={20 * split} fill={C.blue} /><circle cx={lerp(540, 810, split)} cy={lerp(560, 620, split)} r={20 * split} fill={C.blue} /></>}
          {t >= 1.2 && slug(PIPE_L, kL, "l")}
          {t >= 1.2 && kR < 1 && slug(PIPE_R, kR, "r")}
          {kR >= 1 && <circle cx={810} cy={1200} r={20 + 30 * repl} fill={C.blue} />}
        </g>
        {[1, 2, 4, 6].map((pi, j) => { const [x, y] = PIPE_L[pi]; return <circle key={j} cx={x} cy={y} r={14} fill={kL * 6 >= pi ? C.orange : "#636366"} />; })}
      </Svg>
      {[1, 2, 4, 6].map((pi, j) => { const [x, y] = PIPE_L[pi]; const lit = kL * 6 >= pi;
        return <Tag key={j} x={clamp(x, 120, 420)} y={j === 3 ? y + 62 : y - 56} size={26} color={lit ? C.ink : "rgba(255,255,255,0.8)"} k={r(t, 0.3 + j * 0.1, 0.6 + j * 0.1)}
          style={{ background: lit ? C.orange : "#2C2C2E", padding: "6px 14px", borderRadius: 12, border: "1.5px solid rgba(255,255,255,0.18)" }}>{nodesL[j]}</Tag>; })}
      <Tag x={270} y={330} size={32} color="rgba(255,255,255,0.85)" k={r(t, 0.1, 0.4)}>BIG AGENCY</Tag>
      <Tag x={810} y={330} size={32} color={C.ink} k={r(t, 0.1, 0.4)}>YOU</Tag>
      <div style={{ position: "absolute", left: 270, top: 440, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 10 }}>
        <Odo value={Math.floor(48 * kL)} size={96} color={C.orange} />{mono("HRS", "rgba(255,255,255,0.8)", 30)}</div>
      <div style={{ position: "absolute", left: 810, top: 440, transform: "translate(-50%,-50%)", display: "flex", alignItems: "baseline", gap: 10 }}>
        <Odo value={4 * kR} size={96} color={C.blue} />{mono("MIN", C.ink, 30)}</div>
      <Txt x={810} y={1290} size={48} color={C.blue} k={repl}>REPLIED ✓</Txt>
      <Txt x={270} y={1335} size={44} color={C.red} k={late}>TOO LATE</Txt>
      <Tag x={270} y={1392} size={24} color="rgba(255,255,255,0.7)" k={r(t, 9.3, 9.6)}>CLIENT ALREADY BOUGHT</Tag>
      <Txt x={810} y={760} size={64} font={SERIF} weight={400} ls={0} color={C.ink} k={r(t, 3.0, 3.5)}>speed</Txt>
      <Txt x={810} y={840} size={64} font={SERIF} weight={400} ls={0} color={C.ink} k={r(t, 3.4, 3.9)}>wins</Txt>
      <Txt x={810} y={920} size={64} font={SERIF} weight={400} ls={0} color={C.ink} k={r(t, 3.8, 4.3)}>leads.</Txt>
      <Sounds list={[[0.05, "whoosh", 0.2], [0.5, "pop", 0.3], [1.0, "swish", 0.3], [2.0, "ding", 0.4], [3.0, "type", 0.2], [3.4, "type", 0.2], [3.8, "type", 0.2],
        ...[1, 2, 4, 6].map((pi) => [1.2 + (7.8 * pi) / 6 * 0.86, "tick", 0.3] as SL[number]), [9.0, "impact", 0.4], [9.3, "swish", 0.2]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================================
// m1-20 Vortex sort: 90 mixed leads swirl into a whirlpool (liquid), then spit out into three columns that melt into
// bars — BUYERS, RENTERS, INVESTORS — each counting up. Full-screen deep-purple scene.
const LEADS20 = Array.from({ length: 90 }, (_, i) => ({ i, c: i % 9 < 4 ? 0 : i % 9 < 7 ? 1 : 2, a: rand(i + 9) * Math.PI * 2, d: 200 + rand(i + 99) * 260 }));
const M120: React.FC = () => {
  const t = useT();
  const CX = 540, CY = 820;
  const COLS = [{ n: "BUYERS", c: C.blue, x: 270 }, { n: "RENTERS", c: C.green, x: 540 }, { n: "INVESTORS", c: C.orange, x: 790 }];
  const BASE = 1250;
  const idx = [0, 0, 0];
  const pull = r(t, 0.6, 3.4, EASE_IO);
  const spin = (t: number) => t * 1.2 + r(t, 0.6, 3.6, EASE_IN) * 6;
  const counts = [0, 0, 0];
  const groups: React.ReactNode[][] = [[], [], []];
  LEADS20.forEach((L) => {
    const slot = idx[L.c]++;
    const out = r(t, 4.0 + slot * 0.045 + L.c * 0.15, 4.7 + slot * 0.045 + L.c * 0.15, EASE_IO);
    const a = L.a + spin(t) * (1 - out), d = lerp(L.d, 30 + rand(L.i) * 40, pull);
    const vx = CX + Math.cos(a) * d, vy = CY + Math.sin(a) * d * 0.9;
    const sx = COLS[L.c].x + ((slot % 4) - 1.5) * 34, sy = BASE - 20 - Math.floor(slot / 4) * 34;
    counts[L.c] += r(t, 4.5 + slot * 0.045 + L.c * 0.15, 4.7 + slot * 0.045 + L.c * 0.15);
    groups[L.c].push(<circle key={L.i} cx={lerp(vx, sx, out)} cy={lerp(vy, sy, out) - Math.sin(out * Math.PI) * 120} r={lerp(15, 19, out) * r(t, 0.02 * (L.i % 20), 0.3 + 0.02 * (L.i % 20), POP)} fill={COLS[L.c].c} />);
  });
  const bar = r(t, 7.0, 7.6, EASE_IO);
  return (
    <Full bg="#24104A">
      <Svg>
        <defs>{COLS.map((_, i) => <Goo key={i} id={`m1-20g${i}`} b={9} />)}</defs>
        {[0, 1, 2].map((j) => { const q = (t * 0.7 + j / 3) % 1; return <ellipse key={j} cx={CX} cy={CY} rx={lerp(420, 30, q)} ry={lerp(380, 27, q)} fill="none" stroke="rgba(255,255,255,0.14)" strokeWidth={4} opacity={(1 - r(t, 3.8, 4.4)) * r(t, 0.4, 0.9)} />; })}
        {COLS.map((c, i) => <g key={i} filter={`url(#m1-20g${i})`}>{groups[i]}
          {bar > 0 && <rect x={c.x - 72} y={BASE - Math.ceil(idx[i] / 4) * 34 - 10 + 0} width={144} height={Math.ceil(idx[i] / 4) * 34 + 18} rx={20} fill={c.c} opacity={bar} />}
        </g>)}
      </Svg>
      {COLS.map((c, i) => (
        <React.Fragment key={i}>
          <Tag x={c.x} y={BASE + 60} size={28} color="#fff" k={r(t, 4.6, 5.0, POP)}>{c.n}</Tag>
          <div style={{ position: "absolute", left: c.x, top: BASE - Math.ceil(idx[i] / 4) * 34 - 70, transform: "translate(-50%,-50%)", opacity: r(t, 4.5, 4.8) }}>
            <Odo value={counts[i]} size={68} color="#fff" /></div>
        </React.Fragment>
      ))}
      <Seq t={t} x={540} y={340} items={[[0.1, <span style={{ fontFamily: DISPLAY, fontSize: 92, color: "#fff", whiteSpace: "nowrap" }}>90 LEADS. ONE MESS.</span>],
        [4.0, <span style={{ fontFamily: DISPLAY, fontSize: 92, color: "#fff", whiteSpace: "nowrap" }}>SORTED IN A DAY</span>]]} />
      <SceneLine text="Know who you're talking to." from={8.2} to={12} y={1360} color="#fff" size={56} />
      <Sounds list={[[0.1, "pop", 0.25], [0.6, "riser", 0.25], [1.5, "swish", 0.2], [2.6, "swish", 0.25], [4.0, "whoosh", 0.35], [4.3, "tick", 0.2], [4.6, "tick", 0.2], [4.9, "tick", 0.2], [5.2, "tick", 0.2], [5.5, "tick", 0.2], [6.2, "ding", 0.3], [7.0, "swish", 0.25], [8.2, "whoosh", 0.2]]} />
    </Full>
  );
};

export const M1: LibItem[] = [
  { id: "m1-01", title: "Lead funnel → 3 buyers", family: FAM, dur: 13, C: M101,
    note: "1,000 lead dots pour into a funnel as liquid, drain past replied/viewed/offered, 3 gold buyers drip out. For 'most leads are noise'." },
  { id: "m1-02", title: "Be the magnet", family: FAM, dur: 12, C: M102,
    note: "Red dot chases fleeing clients, melts into a magnet, 12 clients stick as a liquid ring. For 'stop chasing, build reputation'." },
  { id: "m1-03", title: "Referral dominoes", family: FAM, dur: 12, C: M103,
    note: "One gold client topples 12 dominoes (DEALS counts up), they melt into a 12 DEALS card. For 'one happy client = referrals'." },
  { id: "m1-05", title: "Team gears: one bad hire", family: FAM, dur: 12, C: M105,
    note: "Three gears + deals counter; the middle gear goes red, jams, melts and a new one rises from the liquid. For hiring/team lines." },
  { id: "m1-06", title: "Bridge to the keys", family: FAM, dur: 11, C: M106,
    note: "Liquid drops flatten into 4 planks (viewing/offer/mortgage/transfer) bridging buyer to keys; buyer rolls across. For 'what an agent actually does'." },
  { id: "m1-07", title: "Review ripple", family: FAM, dur: 12, C: M107,
    note: "A gold drop lands, 3 ripples light up 150+ people, all flow into a REPUTATION disc. For reviews / word of mouth." },
  { id: "m1-08", title: "Client orbit (check-ins)", family: FAM, dur: 12, C: M108,
    note: "Clients orbit you; toggle CHECK-INS off and they drift away, on and they flow back. For 'stay in touch with past clients'." },
  { id: "m1-09", title: "Paperwork maze", family: FAM, dur: 12, C: M109,
    note: "Dot wanders into dead ends alone (12 weeks), rewinds, then a guide's path solves it (3 weeks). For process / why use an agent." },
  { id: "m1-10", title: "Venn: the deal overlap", family: FAM, dur: 12, C: M110,
    note: "A blob splits into location/price/yield circles; the gold overlap (3% of listings) becomes a BUY chip. For 'how to pick a property'." },
  { id: "m1-11", title: "Payment plan pie → timeline", family: FAM, dur: 12, C: M111,
    note: "Price disc splits 10/50/40, slices melt into timeline bars (booking/construction/handover), big 60/40. For off-plan payment plans." },
  { id: "m1-13", title: "Property ladder", family: FAM, dur: 11, C: M113,
    note: "Steps pour out of each other (studio → 1-bed → townhouse → villa), a gold dot hops up and grows. For 'start small, climb'." },
  { id: "m1-14", title: "Tug of war → deal", family: FAM, dur: 12, C: M114,
    note: "Buyer vs seller pull the price knot; agent drops in, both walk in and merge into a green DEAL. For negotiation lines." },
  { id: "m1-15", title: "Crowd vs early", family: FAM, dur: 12, C: M115,
    note: "60 dots crowd the hyped zone, one gold dot goes early; years pass and the crowd pours over. For 'buy before the hype'." },
  { id: "m1-16", title: "Puzzle pieces → ready", family: FAM, dur: 12, C: M116,
    note: "Price/area/timing/finance jigsaw pieces snap into a square, then melt into a green READY check. For 'when to buy'." },
  { id: "m1-17", title: "Share tree", family: FAM, dur: 12, C: M117,
    note: "One video grows a tree of 3/9/27 shares, two leaves turn gold and gold sap flows back to YOU. For content/brand lines." },
  { id: "m1-18", title: "Listing sieve", family: FAM, dur: 12, C: M118,
    note: "Three shakes drop overpriced/wrong-area/bad-layout listings into a grey pool; 3 gold keepers remain. For 'I filter for you'." },
  { id: "m1-19", title: "Speed to lead pipes", family: FAM, dur: 12, C: M119,
    note: "Split screen: an enquiry crawls through a big agency's zig-zag pipe (48 hrs) vs your straight pipe (4 min). For response speed." },
  { id: "m1-20", title: "Lead vortex sort", family: FAM, dur: 12, C: M120,
    note: "90 mixed dots swirl into a whirlpool, then spit out into buyer/renter/investor bars that count up. For CRM / qualifying leads." },
];
