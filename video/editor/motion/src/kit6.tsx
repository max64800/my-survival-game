import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";

// Kit 6: "shape stories". The idea of each line is acted out by simple animated shapes in the top panel, instead of
// cards with emojis (Max, 2026-10-10: "show what I'm talking about through little shapes"). One cast of 12 circles
// travels through the whole video, so every beat flows out of the last one.
// Built for the culture video (IMG_3873); cue times come from props so the scenes can be re-timed.
const { fontFamily: UI } = loadInter("normal", { weights: ["700", "800", "900"], subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["700"], subsets: ["latin"] });

const GREEN = "#34C759";
const RED = "#FF3B30";
const GREY = "#8E8E93";
const BLUE = "#0A84FF";
const GOLD = "#FFD60A";
const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const POP = Easing.bezier(0.3, 1.5, 0.5, 1);

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const r = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const mix = (c1: string, c2: string, k: number) => {
  const p = (c: string) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
  const a = p(c1), b = p(c2);
  return `rgb(${a.map((v, i) => Math.round(lerp(v, b[i], Math.max(0, Math.min(1, k))))).join(",")})`;
};

// a circle that can grow spikes (spike = 0 is a perfect circle)
const Blob: React.FC<{ x: number; y: number; rad: number; spike: number; fill: string; glow?: number; rot?: number; opacity?: number }> =
  ({ x, y, rad, spike, fill, glow = 0, rot = 0, opacity = 1 }) => {
    const n = 14, pts: string[] = [];
    for (let i = 0; i < n * 2; i++) {
      const a = (i / (n * 2)) * Math.PI * 2 + rot;
      const rr = i % 2 === 0 ? rad + spike : rad - spike * 0.15;
      pts.push(`${x + Math.cos(a) * rr},${y + Math.sin(a) * rr}`);
    }
    const d = spike < 0.5 ? undefined : `M ${pts.join(" L ")} Z`;
    return (
      <g opacity={opacity}>
        {d ? <path d={d} fill={fill} strokeLinejoin="round" /> : <circle cx={x} cy={y} r={rad} fill={fill} />}
      </g>
    );
  };

export type ShapeCues = Record<string, number>;
const W = 1080;
const CY = 500;            // vertical centre of the shape stage (inside the top panel)

// formations for the cast of 12
const cluster = (cx: number, cy: number, s = 1) =>
  Array.from({ length: 12 }, (_, i) => {
    const ring = i < 1 ? 0 : i < 7 ? 1 : 2;
    const idx = i < 1 ? 0 : i < 7 ? i - 1 : i - 7;
    const cnt = ring === 1 ? 6 : 5;
    const a = (idx / cnt) * Math.PI * 2 + (ring === 2 ? 0.6 : 0);
    const R = ring * 78 * s;
    return [cx + Math.cos(a) * R, cy + Math.sin(a) * R * 0.85];
  });
const three = () => [
  ...cluster(230, CY, 0.55).slice(0, 4), ...cluster(540, CY, 0.55).slice(0, 4), ...cluster(850, CY, 0.55).slice(0, 4),
];

export const ShapeStory: React.FC<{ c: ShapeCues; from: number; to: number }> = ({ c, from, to }) => {
  const t = useT();
  if (t < from || t > to) return null;
  const enter = r(t, from, from + 0.5, POP);
  const exitAll = r(t, to - 0.35, to, EASE_IN);
  const els: React.ReactNode[] = [];
  const labels: React.ReactNode[] = [];
  const lab = (key: string, text: string, x: number, y: number, size: number, at: number, until: number, color = "#fff") => {
    if (t < at || t > until) return;
    const k = r(t, at, at + 0.35, POP), o = 1 - r(t, until - 0.25, until, EASE_IN);
    labels.push(<div key={key} style={{ position: "absolute", left: x, top: y, transform: `translate(-50%,-50%) scale(${k})`, opacity: o,
      fontFamily: UI, fontWeight: 900, fontSize: size * 1.3, color, letterSpacing: -1, whiteSpace: "nowrap", textShadow: "0 2px 6px rgba(0,0,0,0.55), 0 0 2px rgba(0,0,0,0.4)" }}>{text}</div>);
  };

  // ---- the cast of 12: positions through the formations ----
  const F0 = cluster(540, CY, 1.15);
  const F3 = three();
  const balloon = r(t, c.balloonIn, c.balloonIn + 0.6, EASE_IO);           // merge into one balloon
  const pop = r(t, c.pop, c.pop + 0.6, EASE);                               // burst back out
  const toRings = r(t, c.rings, c.rings + 0.7, EASE_IO);                     // split into three companies
  const regroup = r(t, c.regroup, c.regroup + 0.7, EASE_IO);                 // back into one team
  const sink = r(t, c.poisonAll, c.poisonAll + 1.6, EASE_IN);                // whole team poisoned
  const castGone = r(t, c.castOut, c.castOut + 0.5, EASE_IN);
  const balloonY = CY - r(t, c.balloonIn + 0.4, c.pop, EASE_IO) * 90;

  for (let i = 0; i < 12; i++) {
    let [x, y] = F0[i];
    const [bx, by] = [540, balloonY];
    // after the pop, circles rain back into the cluster
    if (t < c.pop) { x = lerp(x, bx, balloon); y = lerp(y, by, balloon); }
    else { const k = pop; x = lerp(bx + Math.cos(i * 2.1) * 260, F0[i][0], k); y = lerp(by + Math.sin(i * 2.1) * 160, F0[i][1], k); }
    x = lerp(x, F3[i][0], toRings * (1 - regroup)); y = lerp(y, F3[i][1], toRings * (1 - regroup));
    // gentle float so nothing is ever frozen
    x += Math.sin(t * 1.3 + i) * 4; y += Math.cos(t * 1.1 + i * 1.7) * 4 + sink * 60;

    // colour: green -> red by contagion from the toxic one (scene 1), per company (scene 4), whole team (scene 6)
    let red = 0;
    const toxic = i === 0;
    if (t < c.balloonIn) {
      if (toxic) red = r(t, c.toxic, c.toxic + 0.5);
      else { const dist = Math.hypot(F0[i][0] - F0[0][0], F0[i][1] - F0[0][1]); red = r(t, c.spread + dist / 160 * 0.45, c.spread + dist / 160 * 0.45 + 0.6); }
    }
    const company = Math.floor(i / 4), lead = i % 4 === 0;
    if (t >= c.rings && t < c.regroup) {
      const at = [c.again1, c.again2, c.again3][company];
      red = lead ? r(t, at, at + 0.35) : r(t, at + 0.35 + (i % 4) * 0.12, at + 0.75 + (i % 4) * 0.12);
    }
    if (t >= c.poisonAll) { const d = Math.hypot(F0[i][0] - 540, F0[i][1] - CY); red = r(t, c.poisonAll + d / 160 * 0.35, c.poisonAll + 0.5 + d / 160 * 0.35); }
    let fill = mix(GREEN, RED, red);
    if (t >= c.poisonAll + 0.9) fill = mix(RED, GREY, r(t, c.poisonAll + 0.9, c.poisonAll + 1.6));
    const spikeTox = (t < c.balloonIn && toxic) ? r(t, c.toxic, c.toxic + 0.5, POP) * (16 + red * 10) :
      (t >= c.rings && t < c.regroup && lead) ? r(t, [c.again1, c.again2, c.again3][company], [c.again1, c.again2, c.again3][company] + 0.4, POP) * 14 : 0;
    const rad = (t < c.pop ? lerp(32, 10, balloon) : 32) * (t >= c.rings && t < c.regroup ? lerp(1, 0.78, toRings) : 1) * (toxic && t < c.balloonIn ? 1 + red * 0.35 : 1);
    if (t > c.balloonIn + 0.6 && t < c.pop) continue;                          // hidden inside the balloon
    if (castGone >= 1) continue;
    els.push(<Blob key={`c${i}`} x={x} y={y} rad={rad} spike={spikeTox} fill={fill}
      glow={red > 0.3 ? 14 : 6} rot={t * 0.6} opacity={(1 - castGone) * enter * (1 - exitAll)} />);
  }

  // ---- the VALUES balloon (mission statements "just PR") ----
  if (t >= c.balloonIn + 0.3 && t < c.pop + 0.2) {
    const grow = r(t, c.balloonIn + 0.3, c.balloonIn + 0.9, POP);
    const burst = r(t, c.pop, c.pop + 0.2, EASE_IN);
    const R = 150 * grow * (1 + burst * 0.4);
    els.push(<g key="balloon" opacity={1 - burst}>
      <path d={`M 540 ${balloonY + R} q -20 60 10 120 q 25 50 -10 100`} stroke="rgba(255,255,255,0.7)" strokeWidth="4" fill="none" />
      <ellipse cx={540} cy={balloonY} rx={R} ry={R * 1.12} fill={GREEN} />
      <ellipse cx={540 - R * 0.35} cy={balloonY - R * 0.45} rx={R * 0.18} ry={R * 0.28} fill="rgba(255,255,255,0.55)" transform={`rotate(-30 ${540 - R * 0.35} ${balloonY - R * 0.45})`} />
    </g>);
    lab("vals", "VALUES", 540, balloonY - 6, 50, c.balloonIn + 0.6, c.pop + 0.05, "#0B2A1A");
  }
  // pop flash
  if (t >= c.pop && t < c.pop + 0.4) {
    const k = r(t, c.pop, c.pop + 0.4);
    els.push(<circle key="popring" cx={540} cy={balloonY} r={120 + k * 260} fill="none" stroke="#fff" strokeWidth={10 * (1 - k)} opacity={1 - k} />);
    lab("pr", "PR?", 540, balloonY, 130, c.pop, c.pop + 1.0, "#fff");
  }

  // ---- company rings ----
  if (t >= c.rings && t < c.regroup + 0.4) {
    const ringOut = r(t, c.regroup, c.regroup + 0.4, EASE_IN);
    ["STARTUP", "COMPANY", "STARTUP"].forEach((name, k) => {
      const at = [c.ring1, c.ring2, c.ring3][k];
      const a = r(t, at, at + 0.45, POP);
      const cx = [230, 540, 850][k];
      els.push(<circle key={`ring${k}`} cx={cx} cy={CY} r={125 * a} fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.55)" strokeWidth="4"
        strokeDasharray="10 10" opacity={(1 - ringOut)} />);
      lab(`rl${k}`, name, cx, CY - 168, 40, at, c.regroup + 0.2);
    });
  }

  // ---- the top performer: big, gold-crowned, then spiky, then flicked out ----
  if (t >= c.star && t < c.fired + 1.0) {
    const inK = r(t, c.star, c.star + 0.5, POP);
    const bad = r(t, c.bad, c.bad + 0.6, EASE_IO);
    const fl = r(t, c.fired, c.fired + 0.7, EASE_IN);
    const x = 540 + fl * 760, y = CY - 20 - fl * 420 - Math.sin(fl * Math.PI) * 60;
    els.push(<Blob key="star" x={x} y={y} rad={62 * inK} spike={bad * 26} fill={mix(GOLD, RED, bad)} glow={22} rot={t * 1.5 + fl * 8}
      opacity={1 - r(t, c.fired + 0.5, c.fired + 0.7)} />);
    if (fl < 0.2) {
      // crown on top of the star performer
      const cx = 540, cy = CY - 20 - 62 * inK - 22;
      els.push(<path key="crown" d={`M ${cx - 38} ${cy + 18} L ${cx - 30} ${cy - 18} L ${cx - 12} ${cy + 2} L ${cx} ${cy - 24} L ${cx + 12} ${cy + 2} L ${cx + 30} ${cy - 18} L ${cx + 38} ${cy + 18} Z`}
        fill={GOLD} opacity={inK * (1 - fl * 5)} />);
    }
    lab("tp", "TOP PERFORMER", 540, CY + 192, 48, c.star + 0.2, c.bad + 0.1, GOLD);
    lab("ba", "BAD ATTITUDE", 540, CY + 192, 48, c.bad, c.fired, RED);
    lab("fi", "FIRED.", 540, CY + 192, 88, c.fired + 0.1, c.fired + 1.0, "#fff");
  }

  // ---- "otherwise…": the fired top performer comes back and poisons everyone ----
  if (t >= c.otherwise && t < c.castOut + 0.3) {
    const back = r(t, c.otherwise, c.otherwise + 0.6, EASE_IO);
    const gone = r(t, c.castOut, c.castOut + 0.3, EASE_IN);
    els.push(<Blob key="back" x={lerp(1300, 540, back)} y={lerp(CY - 440, CY, back)} rad={44} spike={22} fill={RED} rot={t * 1.5} opacity={1 - gone} />);
    lab("ow", "OTHERWISE…", 540, CY + 192, 48, c.otherwise + 0.1, c.poisonAll + 0.6, RED);
  }

  // ---- boutique network (EQT blue) ----
  const B6 = Array.from({ length: 6 }, (_, i) => [540 + Math.cos(i / 6 * Math.PI * 2 - Math.PI / 2) * 150, CY - 10 + Math.sin(i / 6 * Math.PI * 2 - Math.PI / 2) * 125]);
  if (t >= c.boutique && t < c.many + 0.4) {
    const out = r(t, c.many, c.many + 0.4, EASE_IN);
    B6.forEach(([x, y], i) => {
      const a = r(t, c.boutique + i * 0.08, c.boutique + 0.4 + i * 0.08, POP);
      const beat = 1 + Math.max(0, Math.sin((t - c.love) * 7)) * 0.12 * (t > c.love && t < c.love + 1.2 ? 1 : 0);
      B6.forEach(([x2, y2], j) => { if (j > i && (j - i === 1 || j - i === 3 || (i === 0 && j === 5))) els.push(<line key={`l${i}${j}`} x1={x} y1={y} x2={x2} y2={y2} stroke="rgba(90,205,255,0.5)" strokeWidth="4" opacity={a * (1 - out)} />); });
      els.push(<Blob key={`b${i}`} x={x} y={y} rad={40 * a * beat} spike={0} fill={BLUE} glow={20} opacity={1 - out} />);
    });
    lab("bq", "BOUTIQUE", 540, CY + 185, 76, c.boutiqueWord, c.many);
  }

  // ---- 150 agents: tiny grey dots pour in, a couple blink once ----
  if (t >= c.many && t < c.best + 0.5) {
    const out = r(t, c.best, c.best + 0.5, EASE_IN);
    const n = Math.floor(150 * r(t, c.many, c.many + 1.2, EASE_IO));
    for (let i = 0; i < n; i++) {
      const x = 90 + (i % 15) * 64 + (Math.floor(i / 15) % 2) * 20, y = CY - 165 + Math.floor(i / 15) * 31;
      const blink = (i === 37 || i === 112) && t > c.deals && t < c.deals + 0.8 ? 1 : 0;
      els.push(<circle key={`d${i}`} cx={x} cy={y} r={blink ? 12 : 9} fill={blink ? GREEN : GREY} opacity={(1 - out) * (blink ? 1 : 0.85)} />);
    }
    labels.push(<div key="cnt" style={{ position: "absolute", left: 540, top: CY + 190, transform: "translate(-50%,-50%)", fontFamily: UI, fontWeight: 900,
      fontSize: 120, color: "#fff", opacity: 1 - out }}>{n}<span style={{ fontFamily: MONO, fontSize: 44, marginLeft: 14, opacity: 0.8 }}>AGENTS</span></div>);
  }

  // ---- the best ones lift clients above themselves, then any client goes to any broker ----
  if (t >= c.best && t < to) {
    const backIn = r(t, c.best, c.best + 0.6, POP);
    const lift = r(t, c.above, c.above + 0.6, EASE_IO);
    const send = t >= c.send;
    const merge = r(t, c.merge, c.merge + 0.4, EASE_IN);
    B6.forEach(([x0, y0], i) => {
      const x = lerp(x0, 540, merge), y = lerp(y0 + 40, CY, merge);
      const lit = send ? r(t, c.send + i * 0.18, c.send + i * 0.18 + 0.3, POP) : 0;
      els.push(<Blob key={`bb${i}`} x={x} y={y} rad={40 * backIn * (1 + lit * 0.12) * (1 - merge * 0.4)} spike={0} fill={lit > 0.5 ? "#409CFF" : BLUE} opacity={1 - exitAll} />);
    });
    if (t >= c.clients && !send) B6.forEach(([x0, y0], i) => {
      const a = r(t, c.clients + i * 0.06, c.clients + 0.35 + i * 0.06, POP);
      els.push(<Blob key={`cl${i}`} x={x0} y={y0 + 40 - lerp(0, 82, lift)} rad={20 * a} spike={0} fill={GOLD} />);
    });
    if (t >= c.clients && !send) lab("cf", "CLIENTS FIRST", 540, CY + 200, 64, c.above, c.send, GOLD);
    if (send) {
      // one gold client bounces from broker to broker; each lights up as it lands
      const seg = Math.min(5.999, Math.max(0, (t - c.send) / 0.18));
      const i0 = Math.floor(seg), k = seg - i0;
      const [x1, y1] = B6[i0], [x2, y2] = B6[Math.min(5, i0 + 1)];
      const gx = lerp(x1, x2, k), gy = lerp(y1, y2, k) + 40 - 60 - Math.sin(k * Math.PI) * 50;
      if (t < c.eqt) els.push(<Blob key="gold" x={gx} y={gy} rad={20} spike={0} fill={GOLD} glow={18} />);
      lab("any", "ANY EQT BROKER ✓", 540, CY + 200, 60, c.send + 0.2, to - 0.2);
    }
  }
  // no card: crisp shapes float above his head. Only the 150-agents grid gets a small glass plate (tiny grey dots vanish on the wall).
  const S = 0.74, STAGE_Y = 400;
  const plate = c.many !== undefined ? r(t, c.many - 0.25, c.many + 0.15, EASE_IO) * (1 - r(t, c.best, c.best + 0.45, EASE_IN)) : 0;
  const PL = { w: 780, h: 330 };
  return (
    <div style={{ position: "absolute", inset: 0, opacity: enter * (1 - exitAll), transform: `translateY(${(1 - enter) * 30}px)` }}>
      {plate > 0.001 && <div style={{ position: "absolute", left: 540 - PL.w / 2, top: STAGE_Y - PL.h / 2 + 8, width: PL.w, height: PL.h, borderRadius: 36,
        background: "rgba(28,28,30,0.78)", border: "1.5px solid rgba(255,255,255,0.18)", boxShadow: "0 20px 50px rgba(0,0,0,0.3)",
        opacity: plate, transform: `scale(${0.92 + 0.08 * plate})` }} />}
      <div style={{ position: "absolute", left: 0, top: STAGE_Y - CY, width: W, height: 1000, transform: `scale(${S})`, transformOrigin: `540px ${CY}px`,
        filter: "drop-shadow(0 3px 5px rgba(0,0,0,0.28))" }}>
        <svg width={W} height={1000} style={{ position: "absolute", inset: 0, overflow: "visible" }}>{els}</svg>
        {labels}
      </div>
    </div>
  );
};
