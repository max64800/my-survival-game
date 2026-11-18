import React from "react";
import { Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { AppLogo } from "./kit7";

// Kit 10 "bold plate" (Max on 021 v1, 2026-10-18: the graphite box "looks very software / vibe coded"; wants bigger,
// bolder, brighter, colour theory, no emojis, and animations that flow into each other).
// ONE plate travels the whole video. Each beat has its own flat, saturated iOS colour; the new colour sweeps out from the
// centre while the plate morphs size like water. Old content slides up and blurs away, new content rises in on a spring.
// Heavy type (Anton / Inter 900), crisp drawn shapes instead of emojis, FIXED pixel layouts (nothing can stick out).
const { fontFamily: ANTON } = loadAnton();
const { fontFamily: UI } = loadInter("normal", { weights: ["700", "800", "900"], subsets: ["latin"] });

export const BC = { blue: "#0A84FF", green: "#30D158", purple: "#5E5CE6", orange: "#FF9F0A", red: "#FF3B30", yellow: "#FFD60A",
  white: "#FFFFFF", ink: "#111111", teal: "#40C8E0", pink: "#FF2D55" };

const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const r = (t: number, a: number, b: number, e = Easing.bezier(0.22, 1, 0.36, 1)) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const LIQUID = Easing.bezier(0.34, 1.32, 0.64, 1);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const useSpring = () => {
  const f = useCurrentFrame(); const { fps } = useVideoConfig();
  return (at: number, damping = 14, stiffness = 160) => spring({ frame: f - Math.round(at * fps), fps, config: { damping, stiffness, mass: 0.7 } });
};
const typed = (text: string, t: number, at: number, cps = 0.04) => Array.from(text).slice(0, Math.max(0, Math.floor((t - at) / cps))).join("");
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;

// crisp drawn icons (no emoji)
const Arrow: React.FC<{ size: number; color: string }> = ({ size, color }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d="M12 19V5M5 12l7-7 7 7" fill="none" stroke={color} strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const Check: React.FC<{ size: number; color: string; k?: number }> = ({ size, color, k = 1 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke={color} strokeWidth={3.6} strokeLinecap="round" strokeLinejoin="round"
    pathLength={1} strokeDasharray={1} strokeDashoffset={1 - k} /></svg>);

export type BScene =
  | { kind: "tools"; title: string; items: { text: string; at: number }[]; noAt: number; no: [string, string]; noColor: string }
  | { kind: "prompt"; title: string; text: string; typeAt: number; sendAt: number }
  | { kind: "words"; words: { text: string; at: number }[]; size: number; color?: string }
  | { kind: "report"; title: string; rows: { text: string; tag: string; tagColor: string; at: number }[] }
  | { kind: "dm"; text: string; at: number; sentAt: number }
  | { kind: "flood"; label: string; pills: { text: string; at: number }[] }
  | { kind: "board"; title: string; names: string[]; order: { at: number; rank: number[] }[]; mine?: { name: string; at: number; tag: string } }
  | { kind: "curve"; label: string; curve: number[]; drawAt: number; dropAt: number; dropFrac: number; dropText: string }
  | { kind: "timeline"; label: string; hookText: string; resText: string; at: number; moveAt: number }
  | { kind: "score"; title: string; rows: { logo: string; name: string; at: number; tag: string; tagColor: string; count?: number; countAt?: number }[] }
  | { kind: "follow"; name: string; tagline: string; tapAt: number }
  | { kind: "gone" };
export type BState = { at: number; x: number; y: number; w: number; h: number; color: string; radius?: number; scale?: number; scene: BScene };
export type BoldDef = { from: number; to: number; states: BState[] };

const Scene: React.FC<{ s: BScene; w: number; h: number; t: number }> = ({ s, w, h, t }) => {
  const sp = useSpring();
  const P = 34;
  switch (s.kind) {
    case "tools": {
      // two white pills land on their words, each with a red "?" badge; on "don't" a thick strike crosses both and the
      // answer lands on the right while the plate colour sweeps to green (drawn by the plate itself)
      const no = sp(s.noAt, 13, 200);
      return <>
        <div style={{ position: "absolute", left: P, top: 26, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.title}</div>
        {s.items.map((it, i) => {
          if (t < it.at - 0.02) return null;
          const a = sp(it.at, 13); const st = r(t, s.noAt - 0.25 + i * 0.1, s.noAt + 0.05 + i * 0.1, EASE_IO);
          return <div key={i} style={{ position: "absolute", left: P, top: 78 + i * 88, height: 72, display: "flex", alignItems: "center", gap: 16, padding: "0 16px 0 24px",
            borderRadius: 18, background: BC.white, opacity: Math.min(1, a * 1.5) * (1 - 0.35 * st), transform: `translateX(${(1 - a) * -60}px)` }}>
            <span style={{ fontFamily: ANTON, fontSize: 48, color: BC.ink, letterSpacing: 0.5, whiteSpace: "nowrap" }}>{it.text}</span>
            <div style={{ width: 48, height: 48, borderRadius: 24, background: BC.red, color: BC.white, display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: UI, fontWeight: 900, fontSize: 32 }}>?</div>
            <div style={{ position: "absolute", left: 14, right: 14, top: 33, height: 7, borderRadius: 4, background: BC.ink, transformOrigin: "0% 50%", transform: `scaleX(${st})` }} />
          </div>;
        })}
        {t >= s.noAt - 0.02 && <div style={{ position: "absolute", right: P, top: 78, height: 160, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "flex-end",
          opacity: Math.min(1, no * 1.5), transform: `scale(${1.6 - 0.6 * no})`, transformOrigin: "100% 50%" }}>
          {s.no.map((ln, i) => <div key={i} style={{ fontFamily: ANTON, fontSize: 70, lineHeight: 1.0, color: BC.white, textShadow: "0 4px 0 rgba(0,0,0,0.18)" }}>{ln}</div>)}
        </div>}
      </>;
    }
    case "prompt": {
      const txt = typed(s.text, t, s.typeAt, 0.045);
      const sent = sp(s.sendAt, 12, 220);
      return <>
        <div style={{ position: "absolute", left: P, top: 26, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.title}</div>
        <div style={{ position: "absolute", left: P, right: P, top: 80, height: 104, borderRadius: 52, background: BC.white, boxShadow: "0 8px 0 rgba(0,0,0,0.15)" }}>
          <div style={{ position: "absolute", left: 38, top: 0, height: 104, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 42, color: BC.ink, whiteSpace: "nowrap" }}>
            {txt || <span style={{ color: "rgba(0,0,0,0.35)" }}>Ask Claude…</span>}
            {txt.length < s.text.length && txt && Math.floor(t * 2.5) % 2 === 0 && <span style={{ color: BC.purple, marginLeft: 2 }}>|</span>}</div>
          <div style={{ position: "absolute", right: 14, top: 14, width: 76, height: 76, borderRadius: 38, background: t >= s.sendAt ? BC.green : BC.ink, display: "flex",
            alignItems: "center", justifyContent: "center", transform: `scale(${t >= s.sendAt ? 1 + (1 - sent) * 0.25 : 1})` }}>
            {t >= s.sendAt ? <Check size={44} color={BC.white} k={r(t, s.sendAt, s.sendAt + 0.3)} /> : <Arrow size={40} color={BC.white} />}</div>
        </div>
      </>;
    }
    case "words": {
      // big Anton words in a FIXED row (all laid out from the start, each appears on its word: no re-centring)
      return <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 26 }}>
        {s.words.map((wd, i) => {
          const a = sp(wd.at, 11, 230); const on = t >= wd.at - 0.02;
          return <span key={i} style={{ fontFamily: ANTON, fontSize: s.size, lineHeight: 1, color: s.color ?? BC.ink, opacity: on ? Math.min(1, a * 1.6) : 0,
            transform: `translateY(${(1 - a) * 50}px) scale(${on ? 1.25 - 0.25 * a : 1})`, display: "inline-block" }}>{wd.text}</span>;
        })}
      </div>;
    }
    case "report": {
      return <>
        <div style={{ position: "absolute", left: P, top: 22, fontFamily: UI, fontWeight: 900, fontSize: 28, letterSpacing: 3, color: "rgba(0,0,0,0.45)" }}>{s.title}</div>
        {s.rows.map((rw, i) => {
          if (t < rw.at - 0.02) return null;
          const a = sp(rw.at, 13); const tg = sp(rw.at + 0.15, 11, 230);
          return <div key={i} style={{ position: "absolute", left: P, right: P, top: 64 + i * 64, height: 54, display: "flex", alignItems: "center", justifyContent: "space-between",
            opacity: Math.min(1, a * 1.5), transform: `translateY(${(1 - a) * 30}px)` }}>
            <span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: BC.ink, letterSpacing: -0.5 }}>{rw.text}</span>
            <span style={{ height: 50, padding: "0 20px", borderRadius: 25, background: rw.tagColor, color: BC.white, fontFamily: ANTON, fontSize: 32, display: "flex",
              alignItems: "center", letterSpacing: 1, transform: `scale(${0.6 + 0.4 * tg})`, opacity: Math.min(1, tg * 1.5) }}>{rw.tag}</span>
          </div>;
        })}
      </>;
    }
    case "dm": {
      const txt = typed(s.text, t, s.at, 0.045); const sent = t >= s.sentAt;
      return <>
        <div style={{ position: "absolute", left: P, right: 136, top: (h - 96) / 2, height: 96, borderRadius: 48, background: BC.white, display: "flex", alignItems: "center",
          padding: "0 34px", fontFamily: UI, fontWeight: 800, fontSize: 42, color: BC.ink, whiteSpace: "nowrap", overflow: "hidden", boxShadow: "0 8px 0 rgba(0,0,0,0.15)" }}>
          {txt || <span style={{ color: "rgba(0,0,0,0.35)" }}>Message…</span>}</div>
        <div style={{ position: "absolute", right: P, top: (h - 86) / 2, width: 86, height: 86, borderRadius: 43, background: sent ? BC.green : BC.white, display: "flex",
          alignItems: "center", justifyContent: "center" }}>
          {sent ? <Check size={46} color={BC.white} k={r(t, s.sentAt, s.sentAt + 0.3)} /> : <Arrow size={42} color={BC.blue} />}</div>
      </>;
    }
    case "flood": {
      // pills pile up fast in FIXED slots (2 columns x 3 rows), each lands tilted: "a new one every day"
      const slots = [[P, 76, -3], [w / 2 + 8, 76, 2], [P + 40, 170, 2], [w / 2 + 48, 170, -2], [P + 10, 264, -2], [w / 2 + 18, 264, 3]];   // 94 px rows: tilted pills never touch
      return <>
        <div style={{ position: "absolute", left: P, top: 26, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.label}</div>
        {s.pills.map((pl, i) => {
          if (t < pl.at - 0.02 || i >= slots.length) return null;
          const a = sp(pl.at, 11, 240); const [x, y, rot] = slots[i];
          return <div key={i} style={{ position: "absolute", left: x, top: y, height: 62, padding: "0 24px", borderRadius: 31, background: BC.white, color: BC.ink,
            display: "flex", alignItems: "center", fontFamily: ANTON, fontSize: 40, letterSpacing: 1, boxShadow: "0 6px 0 rgba(0,0,0,0.18)",
            opacity: Math.min(1, a * 1.6), transform: `rotate(${rot}deg) scale(${1.35 - 0.35 * a})` }}>{pl.text}</div>;   // pops in place: never passes over another pill
        })}
      </>;
    }
    case "board": {
      // a live leaderboard: rows glide to their new rank on each "this week / next week"; #1 row turns yellow.
      // Optional "mine": one row gets a YOUR TOOL tag and climbs back to #1.
      let oi = 0; while (oi + 1 < s.order.length && s.order[oi + 1].at <= t) oi++;
      const o = s.order[oi], po = s.order[Math.max(0, oi - 1)];
      const kk = oi === 0 ? 1 : interpolate(t, [o.at, o.at + 0.5], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      const ROW = 72, TOP0 = 72;
      return <>
        <div style={{ position: "absolute", left: P, top: 24, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.title}</div>
        {[0, 1, 2].map((rk) => <div key={rk} style={{ position: "absolute", left: P, top: TOP0 + rk * ROW + 4, width: 52, height: 52, borderRadius: 26,
          background: rk === 0 ? BC.yellow : "rgba(255,255,255,0.22)", color: rk === 0 ? BC.ink : BC.white, display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: ANTON, fontSize: 32 }}>{rk + 1}</div>)}
        {s.names.map((nm, ni) => {
          const y = TOP0 + lerp(po.rank[ni], o.rank[ni], kk) * ROW;
          const top = o.rank[ni] === 0 && kk > 0.5;
          const mine = s.mine && s.mine.name === nm && t >= s.mine.at - 0.02;
          const mk = s.mine && mine ? sp(s.mine.at, 12, 220) : 0;
          return <div key={nm} style={{ position: "absolute", left: P + 70, right: P, top: y, height: 60, borderRadius: 16, background: top ? BC.yellow : BC.white,
            display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 20px", boxShadow: mine ? `0 0 0 5px ${BC.orange}` : "0 5px 0 rgba(0,0,0,0.15)" }}>
            <span style={{ fontFamily: ANTON, fontSize: 40, color: BC.ink, letterSpacing: 1 }}>{nm}</span>
            {mine && <span style={{ height: 42, padding: "0 16px", borderRadius: 21, background: BC.orange, color: BC.white, fontFamily: ANTON, fontSize: 26, display: "flex",
              alignItems: "center", letterSpacing: 1, transform: `scale(${0.6 + 0.4 * mk})` }}>{s.mine!.tag}</span>}
          </div>;
        })}
      </>;
    }
    case "curve": {
      // his REAL average retention curve draws itself in yellow; a red marker drops on the backstory moment
      const draw = r(t, s.drawAt, s.drawAt + 1.2, EASE_IO), drop = sp(s.dropAt, 12, 220);
      const x0 = P, y0 = 74, W2 = w - P * 2, H2 = h - y0 - 30;
      const pts = s.curve.map((v, i) => [x0 + (i / (s.curve.length - 1)) * W2, y0 + (1 - v / 100) * H2]);
      const n = Math.max(2, Math.ceil(pts.length * draw));
      const d = pts.slice(0, n).map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
      const fi = s.dropFrac * (s.curve.length - 1), i0 = Math.floor(fi);
      const dx = x0 + s.dropFrac * W2, dy = y0 + (1 - lerp(s.curve[i0], s.curve[Math.min(i0 + 1, s.curve.length - 1)], fi - i0) / 100) * H2;
      return <>
        <div style={{ position: "absolute", left: P, top: 24, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.label}</div>
        <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
          <line x1={x0} x2={x0 + W2} y1={y0 + H2} y2={y0 + H2} stroke="rgba(255,255,255,0.35)" strokeWidth={3} />
          <path d={d} fill="none" stroke={BC.yellow} strokeWidth={10} strokeLinecap="round" strokeLinejoin="round" />
          {t >= s.dropAt - 0.02 && <circle cx={dx} cy={dy} r={16 * drop} fill={BC.red} stroke={BC.white} strokeWidth={4} />}
        </svg>
        {t >= s.dropAt - 0.02 && <div style={{ position: "absolute", left: dx + 170, top: y0 + 2, height: 52, padding: "0 20px", borderRadius: 26, background: BC.red,
          color: BC.white, fontFamily: ANTON, fontSize: 34, display: "flex", alignItems: "center", letterSpacing: 1, transform: `scale(${0.5 + 0.5 * drop})`,
          transformOrigin: "0% 50%", opacity: Math.min(1, drop * 1.5) }}>{s.dropText}</div>}
      </>;
    }
    case "timeline": {
      // a video timeline: HOOK sits at the start; the RESULT block slides from the far end up to right behind HOOK
      const a = sp(s.at, 14), m = r(t, s.moveAt, s.moveAt + 0.7, EASE_IO);
      const TW = w - P * 2, HW = 200, RW = 230, Y = 96, BH = 84;
      const rx = lerp(TW - RW, HW + 14, m);
      return <>
        <div style={{ position: "absolute", left: P, top: 24, fontFamily: UI, fontWeight: 900, fontSize: 30, letterSpacing: 3, color: "rgba(255,255,255,0.85)" }}>{s.label}</div>
        <div style={{ position: "absolute", left: P, top: Y, width: TW, height: BH, borderRadius: 20, background: "rgba(255,255,255,0.22)", opacity: Math.min(1, a * 1.5) }} />
        <div style={{ position: "absolute", left: P, top: Y, width: HW, height: BH, borderRadius: 20, background: BC.white, color: BC.ink, display: "flex", alignItems: "center",
          justifyContent: "center", fontFamily: ANTON, fontSize: 46, opacity: Math.min(1, a * 1.5) }}>{s.hookText}</div>
        <div style={{ position: "absolute", left: P + rx, top: Y, width: RW, height: BH, borderRadius: 20, background: m > 0.98 ? BC.green : BC.yellow, color: BC.ink,
          display: "flex", alignItems: "center", justifyContent: "center", fontFamily: ANTON, fontSize: 46, opacity: Math.min(1, a * 1.5),
          transform: `translateY(${Math.sin(Math.PI * m) * -18}px)` }}>{s.resText}</div>
      </>;
    }
    case "score": {
      return <>
        <div style={{ position: "absolute", left: P, top: 22, fontFamily: UI, fontWeight: 900, fontSize: 28, letterSpacing: 3, color: "rgba(0,0,0,0.45)" }}>{s.title}</div>
        {s.rows.map((rw, i) => {
          if (t < rw.at - 0.02) return null;
          const a = sp(rw.at, 13), tg = rw.countAt !== undefined ? sp(rw.countAt, 11, 230) : sp(rw.at + 0.2, 11, 230);
          const n = rw.count && rw.countAt !== undefined ? Math.round(rw.count * r(t, rw.countAt, rw.countAt + 0.8, EASE_IO)) : 0;
          const showTag = rw.countAt === undefined || t >= rw.countAt - 0.02;
          return <div key={i} style={{ position: "absolute", left: P, right: P, top: 62 + i * 66, height: 56, display: "flex", alignItems: "center", justifyContent: "space-between",
            opacity: Math.min(1, a * 1.5), transform: `translateX(${(1 - a) * -40}px)` }}>
            <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
              <AppLogo id={rw.logo} size={50} />
              <span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: BC.ink, letterSpacing: -0.5 }}>{rw.name}</span>
            </div>
            {showTag && <span style={{ height: 50, padding: "0 20px", borderRadius: 25, background: rw.tagColor, color: BC.white, fontFamily: ANTON, fontSize: 32, display: "flex",
              alignItems: "center", letterSpacing: 1, fontVariantNumeric: "tabular-nums", transform: `scale(${0.6 + 0.4 * tg})`, opacity: Math.min(1, tg * 1.5) }}>
              {rw.count ? `${n.toLocaleString("en-US")}+` : rw.tag}</span>}
          </div>;
        })}
      </>;
    }
    case "follow": {
      const on = t >= s.tapAt; const tp = sp(s.tapAt, 12, 220);
      return <>
        <div style={{ position: "absolute", left: P, top: 0, height: h, display: "flex", alignItems: "center", gap: 20 }}>
          <div style={{ width: 92, height: 92, borderRadius: 46, background: BC.white, color: BC.blue, display: "flex", alignItems: "center", justifyContent: "center",
            fontFamily: ANTON, fontSize: 56 }}>M</div>
          <div>
            <div style={{ fontFamily: ANTON, fontSize: 56, color: BC.white, lineHeight: 1 }}>{s.name}</div>
            <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 28, color: "rgba(255,255,255,0.85)", marginTop: 6 }}>{s.tagline}</div>
          </div>
        </div>
        <div style={{ position: "absolute", right: P, top: (h - 80) / 2, width: 260, height: 80, borderRadius: 40, background: on ? BC.green : BC.white,
          color: on ? BC.white : BC.ink, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontFamily: ANTON, fontSize: 38,
          transform: `scale(${on ? 1 + (1 - tp) * 0.14 : 1})` }}>{on ? <><Check size={36} color={BC.white} k={r(t, s.tapAt, s.tapAt + 0.3)} />FOLLOWING</> : "FOLLOW"}</div>
      </>;
    }
    case "gone":
      return null;
  }
};

export const BoldPlate: React.FC<{ d: BoldDef }> = ({ d }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  let i = 0;
  while (i + 1 < d.states.length && d.states[i + 1].at <= t) i++;
  const cur = d.states[i], prev = d.states[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.5, EASE_IO);
  const kS = i === 0 ? 1 : interpolate(t, [cur.at, cur.at + 0.6], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const out = i === 0 ? 1 : r(t, cur.at, cur.at + 0.22, Easing.bezier(0.55, 0, 1, 0.45));
  const inK = i === 0 ? r(t, d.from, d.from + 0.4) : r(t, cur.at + 0.22, cur.at + 0.6);   // new content only after the old has left
  const enter = r(t, d.from, d.from + 0.45, LIQUID), exit = r(t, d.to - 0.3, d.to);
  const x = lerp(prev.x, cur.x, k), y = lerp(prev.y, cur.y, k), w = lerp(prev.w, cur.w, kS), h = lerp(prev.h, cur.h, kS);
  const rad = lerp(prev.radius ?? 40, cur.radius ?? 40, k), sc = lerp(prev.scale ?? 1, cur.scale ?? 1, kS);
  const flight = i > 0 ? Math.sin(Math.PI * Math.min(1, Math.max(0, (t - cur.at) / 0.5))) : 0;
  // in-scene colour change (tools: blue -> green on "don't")
  const sceneColor = (st: BState) => st.scene.kind === "tools" && t >= st.scene.noAt - 0.05 ? st.scene.noColor : st.color;
  const prevCol = sceneColor(prev), curCol = sceneColor(cur);
  const toolsWipe = cur.scene.kind === "tools" ? r(t, cur.scene.noAt - 0.05, cur.scene.noAt + 0.35, EASE_IO) : 1;
  const wipe = i === 0 ? 1 : r(t, cur.at, cur.at + 0.32, EASE_IO);
  const dark = (c: string) => c === BC.white || c === BC.yellow;
  return (
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, opacity: 1 - exit, transformOrigin: "50% 0%",
      transform: `scale(${sc}) scale(${enter * (1 - exit * 0.4)}) scale(${1 + flight * 0.03}, ${1 - flight * 0.04}) translateY(${Math.sin(t * 1.4) * 4}px)` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: rad, overflow: "hidden", background: i === 0 ? cur.color : prevCol,
        boxShadow: "0 18px 40px rgba(0,0,0,0.28)", color: dark(curCol) ? BC.ink : BC.white }}>
        {/* the new colour sweeps out from the centre */}
        <div style={{ position: "absolute", inset: 0, background: cur.color, clipPath: `circle(${wipe * 110}% at 50% 50%)` }} />
        {cur.scene.kind === "tools" && <div style={{ position: "absolute", inset: 0, background: cur.scene.noColor, clipPath: `circle(${(t >= cur.scene.noAt - 0.05 ? toolsWipe : 0) * 75}% at 85% 50%)` }} />}
        {i > 0 && out < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - out, transform: `translateY(${-out * 34}px)`, filter: `blur(${out * 6}px)` }}>
          <Scene s={prev.scene} w={w} h={h} t={t} /></div>}
        <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `translateY(${(1 - inK) * 40}px)` }}>
          <Scene s={cur.scene} w={w} h={h} t={t} /></div>
      </div>
    </div>
  );
};

// ---------------- colour-word captions (from @itsjakethewizard, 2026-10-19) ----------------
// 2-3 word chunks, heavy caps with a thick black outline, mid-chest. Each KEY word gets its own colour (red / green /
// yellow rotating). The whole chunk is laid out from the start (fixed: no jitter); unsaid words are invisible.
export type CWord = { w: string; s: number; e: number; col?: string };
export const ColorCaps: React.FC<{ chunks: { from: number; to: number; words: CWord[] }[]; bottom: number; size?: number }> = ({ chunks, bottom, size = 84 }) => {
  const t = useT(); const sp = useSpring();
  const c = chunks.find((x) => t >= x.from && t < x.to);
  if (!c) return null;
  return <div style={{ position: "absolute", left: 60, right: 180, bottom: 1920 - bottom, display: "flex", justifyContent: "center", flexWrap: "wrap", columnGap: 30 }}>
    {c.words.map((w, i) => {
      const on = t >= w.s - 0.03; const a = sp(w.s - 0.03, 12, 260);
      return <span key={i} style={{ fontFamily: UI, fontWeight: 900, fontSize: size, lineHeight: 1.05, textTransform: "uppercase", letterSpacing: -1,
        color: w.col ?? BC.white, WebkitTextStroke: "7px #111", paintOrder: "stroke fill", textShadow: "0 6px 0 rgba(0,0,0,0.3)",
        opacity: on ? 1 : 0, transform: `scale(${on ? 1.18 - 0.18 * a : 1})`, display: "inline-block" }}>{w.w}</span>;
    })}
  </div>;
};
