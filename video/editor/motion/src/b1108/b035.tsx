import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";

// Video 035 "Was Dubai worth it?" (IMG_4328, Nov 8 batch). Owned by the 035 edit only: other videos never touch this file.
// kit11 glass-card scenes (kind starts with "b035_"): pop = Dubai population counter + rising chart (frame 1)
// -> move = Canada -> UAE flight arc, "worth it" verdict -> list = 5-reason fill-up list -> ask = comment box question.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const gradText = (bg: string): React.CSSProperties => ({ background: bg, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" });
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 24, letterSpacing: 2.4, textTransform: "uppercase" };
const P = 36;
const rise = (t: number, at: number, d = 0.45, dy = 12): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined };
};

const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const IC: Record<string, string> = {
  percent: "M19 5L5 19M7 9.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5zM17 19.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z",
  sun: "M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
  rain: "M7 14a4.5 4.5 0 1 1 1.3-8.8A5.5 5.5 0 0 1 18.5 8 3.5 3.5 0 0 1 17.5 14zM8 17l-1 3M12 17l-1 3M16 17l-1 3",
  shield: "M12 3l8 3v6c0 4.5-3.4 8-8 9-4.6-1-8-4.5-8-9V6zM8.5 12l2.5 2.5 4.5-5",
  kids: "M8 7a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5zM17 9a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM4 21v-6a4 4 0 0 1 8 0v6M14 21v-4.5a3 3 0 0 1 6 0V21",
  rocket: "M12 15l-3-3c1-4 4-8.5 10-9 -.5 6-5 9-9 10M9 12l-4 1 2-4h4M12 15l-1 4 4-2v-4M6 16c-1.5 1-2 3.5-2 4 .5 0 3-.5 4-2",
  code: "M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16",
  check: "M5 12.5l4.5 4.5L19 7.5",
  plane: "M21 15.5l-8.5-4.5V5a1.5 1.5 0 0 0-3 0v6L1 15.5V17l8.5-2.5V19l-2.5 1.8V22l4-1 4 1v-1.2L12.5 19v-4.5L21 17z",
  send: "M4 12l16-8-6 16-2.5-6.5z",
};

// flags: faithful simple marks (UAE = 4 bands; Canada = red-white-red with an 11-point maple leaf)
const UAE: React.FC<{ w: number }> = ({ w }) => (
  <svg width={w} height={w / 2} viewBox="0 0 12 6" style={{ borderRadius: 6, display: "block" }}>
    <rect width={12} height={2} y={0} fill="#00732F" /><rect width={12} height={2} y={2} fill="#FFFFFF" /><rect width={12} height={2} y={4} fill="#000000" />
    <rect width={3} height={6} fill="#FF0000" /></svg>);
const LEAF = "M0,-24 L4,-16 8,-18 6,-6 13,-13 15,-9 22,-11 19,-3 22,-2 11,7 12,11 1,9 1,20 -1,20 -1,9 -12,11 -11,7 -22,-2 -19,-3 -22,-11 -15,-9 -13,-13 -6,-6 -8,-18 -4,-16 Z";
const CAN: React.FC<{ w: number }> = ({ w }) => (
  <svg width={w} height={w / 2} viewBox="0 0 96 48" style={{ borderRadius: 6, display: "block" }}>
    <rect width={96} height={48} fill="#FFFFFF" /><rect width={24} height={48} fill="#D52B1E" /><rect x={72} width={24} height={48} fill="#D52B1E" />
    <path d={LEAF} transform="translate(48 25) scale(0.85)" fill="#D52B1E" /></svg>);

export type B035 =
  | { kind: "b035_pop"; label: string; src: string; at: number; to: number; d: number; plus: boolean; sub: string }
  | { kind: "b035_move"; fromAt: number; toAt: number; ago: string; agoAt: number; worth: string; worthAt: number }
  | { kind: "b035_list"; label: string; rows: { icon: string; text: string; at: number; vs?: { text: string; at: number } }[] }
  | { kind: "b035_build"; title: string; at: number; pot: string; potAt: number; people: string; peopleAt: number }
  | { kind: "b035_ask"; q: string; at: number; typed: string; typeAt: number; typeD: number };

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = ({ s: s0, w, h, t, p }) => {
  const s = s0 as unknown as B035;
  switch (s.kind) {
    case "b035_pop": {
      // frame 1: "over 226,000 people": the counter rolls up on the spoken number next to a rising Jan -> Sep curve
      const k = r(t, s.at, s.at + s.d, IO);
      const n = Math.round(lerp(0, s.to, k));
      const CW = 260, CH = 168, CX = w - P - CW, CY = 92;
      const pts = [0, 0.1, 0.22, 0.31, 0.45, 0.56, 0.7, 0.84, 1].map((v, i) => [CW * i / 8, CH - 14 - v * (CH - 34)] as const);
      const line = pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)} ${y.toFixed(1)}`).join(" ");
      const draw = r(t, -0.6, 0.5, IO);   // the curve is there on frame 1 (picture + proof), the number rolls on his words
      return <>
        <div style={{ position: "absolute", left: P, top: 30, display: "flex", alignItems: "center", gap: 14 }}>
          <UAE w={52} /><span style={{ ...LABEL, color: p.mute }}>{s.label}</span></div>
        <div style={{ position: "absolute", left: P - 4, top: 86, fontFamily: UI, fontWeight: 800, fontSize: 104, letterSpacing: -4, lineHeight: 1,
          fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap", ...gradText(G(p)) }}>{n.toLocaleString("en-US")}{s.plus && k > 0.98 ? "+" : ""}</div>
        <div style={{ position: "absolute", left: P, top: 214, fontFamily: UI, fontWeight: 700, fontSize: 30, color: p.ink, ...rise(t, -0.5) }}>{s.sub}</div>
        <div style={{ position: "absolute", left: P, bottom: 22, fontFamily: UI, fontWeight: 600, fontSize: 18, color: p.mute }}>{s.src}</div>
        <svg width={CW} height={CH} style={{ position: "absolute", left: CX, top: CY, overflow: "visible" }}>
          <defs>
            <linearGradient id="b035f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor={p.a} stopOpacity={0.35} /><stop offset="1" stopColor={p.a} stopOpacity={0} /></linearGradient>
            <linearGradient id="b035l" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stopColor={p.a} /><stop offset="1" stopColor={p.b} /></linearGradient>
            <clipPath id="b035c"><rect width={CW * draw + 1} height={CH + 20} y={-10} /></clipPath>
          </defs>
          <line x1={0} y1={CH - 14} x2={CW} y2={CH - 14} stroke="#E6E2EA" strokeWidth={2} />
          <g clipPath="url(#b035c)">
            <path d={`${line} L${CW} ${CH - 14} L0 ${CH - 14} Z`} fill="url(#b035f)" />
            <path d={line} fill="none" stroke="url(#b035l)" strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" />
          </g>
          <circle cx={pts[8][0]} cy={pts[8][1]} r={9} fill={p.b} stroke="#fff" strokeWidth={3} opacity={r(t, s.at + s.d, s.at + s.d + 0.3)} />
        </svg>
        <div style={{ position: "absolute", left: CX, top: CY + CH + 6, ...LABEL, fontSize: 18, color: p.mute }}>Jan</div>
        <div style={{ position: "absolute", right: P, top: CY + CH + 6, ...LABEL, fontSize: 18, color: p.mute }}>Sep</div>
      </>;
    }
    case "b035_move": {
      // "a year ago my family moved here from Canada": a plane flies the arc Vancouver -> Dubai, then the green verdict pill
      const FW = 132, FY = 44;
      const fly = r(t, s.fromAt + 0.1, s.toAt + 0.5, IO);
      // the arc runs between the two flags at flag height (never through the city names or the pill)
      const AX = P + FW + 24, BX = w - P - FW - 24, AY = FY + FW / 4, CY0 = FY - 34, MX = (AX + BX) / 2;
      const bez = (u: number) => [(1 - u) ** 2 * AX + 2 * (1 - u) * u * MX + u * u * BX, (1 - u) ** 2 * AY + 2 * (1 - u) * u * CY0 + u * u * AY] as const;
      const [px, py] = bez(fly);
      const [qx, qy] = bez(Math.min(1, fly + 0.01));
      const ang = Math.atan2(qy - py, qx - px) * 180 / Math.PI;
      const arcLen = 560;
      const wk = r(t, s.worthAt, s.worthAt + 0.45);
      const flag = (node: React.ReactNode, city: string, x: number, at: number) => <div style={{ position: "absolute", left: x, top: FY, width: FW, textAlign: "center", ...rise(t, at) }}>
        <div style={{ borderRadius: 8, overflow: "hidden", boxShadow: "0 8px 18px -8px rgba(15,23,42,0.45)", border: "1.5px solid #E6E2EA" }}>{node}</div>
        <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: p.ink, marginTop: 12 }}>{city}</div></div>;
      return <>
        <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
          <path d={`M${AX} ${AY} Q${MX} ${CY0} ${BX} ${AY}`} fill="none" stroke="#E2DAE6" strokeWidth={4} strokeDasharray="2 14" strokeLinecap="round" />
          <path d={`M${AX} ${AY} Q${MX} ${CY0} ${BX} ${AY}`} fill="none" stroke={p.b} strokeWidth={5} strokeLinecap="round"
            strokeDasharray={`${arcLen * fly} ${arcLen}`} />
        </svg>
        {flag(<CAN w={FW} />, "Vancouver", P, s.fromAt - 0.3)}
        {flag(<UAE w={FW} />, "Dubai", w - P - FW, s.toAt - 0.2)}
        {fly > 0 && fly < 1 && <div style={{ position: "absolute", left: px - 22, top: py - 22, transform: `rotate(${ang + 90}deg)` }}>
          <svg width={44} height={44} viewBox="0 0 24 24"><path d={IC.plane} fill={p.b} /></svg></div>}
        {fly >= 1 && <div style={{ position: "absolute", left: w - P - FW / 2 - 20, top: FY + FW / 4 - 20, width: 40, height: 40, borderRadius: 20, border: `3px solid ${p.b}`,
          opacity: 1 - r(t, s.toAt + 0.5, s.toAt + 1.3), transform: `scale(${1 + r(t, s.toAt + 0.5, s.toAt + 1.3)})` }} />}
        <div style={{ position: "absolute", left: (w - 220) / 2, top: FY + 74, width: 220, height: 50, borderRadius: 25, background: "#F3EEF6", color: p.ink,
          display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 700, fontSize: 25, ...rise(t, s.agoAt) }}>{s.ago}</div>
        {t >= s.worthAt - 0.02 && <div style={{ position: "absolute", left: (w - 470) / 2, top: h - 92, width: 470, height: 64, borderRadius: 32, background: "#DCFCE7",
          color: "#15803D", display: "flex", alignItems: "center", justifyContent: "center", gap: 12, fontFamily: UI, fontWeight: 800, fontSize: 31,
          opacity: wk, transform: `translateY(${(1 - wk) * 12}px) scale(${0.94 + 0.06 * wk})` }}><Ico d={IC.check} size={32} color="#15803D" w={3} />{s.worth}</div>}
      </>;
    }
    case "b035_list": {
      // the 5 reasons fill up on their spoken words: the number dot fills with the gradient, an icon tile in its own colour, the text rises
      const TOP = 86, RH = 70;
      const n = s.rows.filter((rw) => t >= rw.at).length;
      const COL = ["#F59E0B", "#FB923C", "#14B8A6", "#EC4899", "#8B5CF6"];
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 32, color: p.mute }}>{s.label}</div>
        <div style={{ position: "absolute", right: P, top: 22, width: 110, height: 48, borderRadius: 24, background: G(p), color: "#fff", display: "flex",
          alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 26, fontVariantNumeric: "tabular-nums" }}>{n}/5</div>
        {s.rows.map((rw, i) => {
          const k = r(t, rw.at - 0.05, rw.at + 0.4, IO);
          const y = TOP + i * RH;
          return <div key={i} style={{ position: "absolute", left: P, right: P, top: y, height: 56, display: "flex", alignItems: "center", gap: 18 }}>
            <div style={{ width: 46, height: 46, borderRadius: 23, flexShrink: 0, border: `2.5px solid ${k > 0.02 ? p.b : "#DAD3E0"}`, boxSizing: "border-box",
              background: k > 0.02 ? G(p) : "#FFFFFF", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 24,
              color: k > 0.02 ? "#fff" : "#B8AFC2", transform: `scale(${1 + 0.12 * Math.sin(Math.PI * k)})` }}>{i + 1}</div>
            <div style={{ width: 56, height: 56, borderRadius: 16, flexShrink: 0, background: `${COL[i]}22`, display: "flex", alignItems: "center", justifyContent: "center",
              opacity: k, transform: `scale(${0.7 + 0.3 * k})` }}><Ico d={IC[rw.icon]} size={32} color={COL[i]} w={2.4} /></div>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, letterSpacing: -0.8, color: p.ink, whiteSpace: "nowrap", ...rise(t, rw.at, 0.4, 8) }}>{rw.text}</span>
            {rw.vs && <div style={{ height: 52, padding: "0 18px", borderRadius: 26, background: "#EEF2F7", color: "#475569", display: "flex", alignItems: "center", gap: 8,
              fontFamily: UI, fontWeight: 700, fontSize: 28, whiteSpace: "nowrap", marginLeft: 4, ...rise(t, rw.vs.at, 0.4, 8) }}>
              <Ico d={IC.rain} size={30} color="#64748B" w={2.2} /><span style={{ position: "relative" }}>{rw.vs.text}
                <span style={{ position: "absolute", left: -2, right: -2, top: "52%", height: 2.5, background: "#94A3B8", transformOrigin: "0 50%",
                  transform: `scaleX(${r(t, rw.vs.at + 0.3, rw.vs.at + 0.7, IO)})` }} /></span></div>}
          </div>;
        })}
      </>;
    }
    case "b035_build": {
      // "I started to vibe code here": an editor window writes itself; "so much potential" pill; a row of people fills on "people that need it"
      const EW = 280, EY = 30, EH = h - 60, RX = P + EW + 36;
      const LW = [150, 196, 120, 176, 98, 160, 132];
      const LC = [p.a, "#94A3B8", p.b, "#94A3B8", p.gold2, "#94A3B8", p.a];
      const pk = r(t, s.potAt, s.potAt + 0.45);
      return <>
        <div style={{ position: "absolute", left: P, top: EY, width: EW, height: EH, borderRadius: 18, background: "#1E1B2E", padding: "18px 20px", boxSizing: "border-box",
          boxShadow: "0 12px 26px -12px rgba(15,23,42,0.6)" }}>
          <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>{["#FF5F57", "#FEBC2E", "#28C840"].map((c) => <div key={c} style={{ width: 13, height: 13, borderRadius: 7, background: c }} />)}</div>
          {LW.map((ww, j) => <div key={j} style={{ width: ww, height: 10, borderRadius: 5, background: LC[j], marginBottom: 13, marginLeft: j % 3 === 1 ? 22 : 0,
            transformOrigin: "0 50%", transform: `scaleX(${r(t, s.at + j * 0.14, s.at + j * 0.14 + 0.3, IO)})` }} />)}
        </div>
        <div style={{ position: "absolute", left: RX, top: EY + 2, display: "flex", alignItems: "center", gap: 12, ...rise(t, s.at) }}>
          <Ico d={IC.code} size={40} color={p.b} w={2.6} />
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1.2, color: p.ink, whiteSpace: "nowrap" }}>{s.title}</span></div>
        {t >= s.potAt - 0.02 && <div style={{ position: "absolute", left: RX, top: EY + 78, height: 54, padding: "0 22px", borderRadius: 27, background: "#FFF3D6",
          color: "#B45309", display: "flex", alignItems: "center", gap: 10, fontFamily: UI, fontWeight: 700, fontSize: 27, whiteSpace: "nowrap",
          opacity: pk, transform: `translateY(${(1 - pk) * 10}px)` }}><Ico d={IC.rocket} size={28} color="#B45309" w={2.4} />{s.pot}</div>}
        <div style={{ position: "absolute", left: RX, top: EY + 160, display: "flex", gap: 10 }}>
          {Array.from({ length: 8 }, (_, j) => {
            const k = r(t, s.peopleAt + j * 0.08, s.peopleAt + j * 0.08 + 0.35);
            return <div key={j} style={{ width: 44, height: 44, borderRadius: 22, background: k > 0.02 ? (j % 2 ? G(p) : `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`) : "#EEE9F2",
              display: "flex", alignItems: "flex-end", justifyContent: "center", overflow: "hidden", transform: `scale(${0.8 + 0.2 * k})` }}>
              <svg width={34} height={34} viewBox="0 0 24 24" style={{ opacity: k }}><circle cx={12} cy={9} r={4.2} fill="#fff" /><path d="M3.5 24c0-5 3.8-8.5 8.5-8.5s8.5 3.5 8.5 8.5z" fill="#fff" /></svg>
            </div>;
          })}
        </div>
        <div style={{ position: "absolute", left: RX, top: EY + 216, fontFamily: UI, fontWeight: 700, fontSize: 24, color: p.mute, ...rise(t, s.peopleAt + 0.3) }}>{s.people}</div>
      </>;
    }
    case "b035_ask": {
      // the closing question as a comment box: the question sits on top, the reply types itself and the send button lights up
      const typed = s.typed.slice(0, Math.round(s.typed.length * r(t, s.typeAt, s.typeAt + s.typeD, (x) => x)));
      const sent = r(t, s.typeAt + s.typeD + 0.1, s.typeAt + s.typeD + 0.45);
      return <>
        <div style={{ position: "absolute", left: P, top: 32, display: "flex", alignItems: "center", gap: 14 }}>
          <UAE w={52} /><span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, color: p.ink, ...rise(t, s.at) }}>{s.q}</span></div>
        <div style={{ position: "absolute", left: P, right: P, top: 118, height: 76, borderRadius: 38, background: "#F4F1F7", border: "1.5px solid #E6E2EA",
          display: "flex", alignItems: "center", paddingLeft: 30, boxSizing: "border-box" }}>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 32, color: typed ? p.ink : "#A39BAE", whiteSpace: "nowrap" }}>
            {typed || "Add a comment..."}{t >= s.typeAt && sent < 0.5 && Math.floor(t * 2.5) % 2 === 0 ? "|" : ""}</span>
          <div style={{ position: "absolute", right: 10, top: 8, width: 58, height: 58, borderRadius: 29, background: sent > 0.5 ? G(p) : "#E6E2EA",
            display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + 0.12 * Math.sin(Math.PI * sent)})` }}>
            <Ico d={IC.send} size={30} color="#fff" w={2.4} /></div>
        </div>
      </>;
    }
  }
  return null;
};
export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = () => null;
