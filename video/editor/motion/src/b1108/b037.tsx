import React from "react";
import { Easing, Img, interpolate, staticFile } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";
import { LOGOS } from "../yt00/logos";

// Video 037 "Sales guy, vibe coding since May, still not rich" (IMG_4330, kit11 day). Owned by the 037 edit only.
// ONE glass card: a "shipped since May" board whose 5 slots fill as he names each thing (CRM, offer builder, websites,
// Deep Rise on Steam, small tools); the panel under the slots acts out the current item. Then it morphs into a bank card:
// "Shipped" bar full vs "Rich" bar barely started. Real Steam mark + Deep Rise art from his Steam cache; real Google G.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const rise = (t: number, at: number, d = 0.5, dy = 16): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined };
};
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const GOLD = (p: Pal) => `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };
const P = 36;

const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  users: "M16 20v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 18.5V20M10 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM20 20v-1.5a3.5 3.5 0 0 0-2.5-3.35M15.5 4.2a3.5 3.5 0 0 1 0 6.6",
  pen: "M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4",
  globe: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3z",
  tools: "M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.5 2.5-2.4-.6-.6-2.4z",
  code: "M8 7l-5 5 5 5M16 7l5 5-5 5",
  check: "M5 12.5l4.5 4.5L19 7.5",
  bank: "M3 10h18M5 10v8M9.7 10v8M14.3 10v8M19 10v8M3 20h18M12 3l9 5H3z",
  spark: "M12 3l1.9 5.6L19.5 10.5l-5.6 1.9L12 18l-1.9-5.6L4.5 10.5l5.6-1.9z",
  bell: "M6 16V11a6 6 0 1 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0",
  cal: "M4 6h16v14H4zM4 10h16M8 3v4M16 3v4",
  doc: "M7 3h7l4 4v14H7zM14 3v4h4",
  chart: "M4 20V10M10 20V4M16 20v-7M22 20H2",
  chat: "M4 5h16v11H9l-5 4z",
  clock: "M12 7v5l3 2M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z",
  mail: "M3 6h18v12H3zM3 6l9 7 9-7",
};
const BrandMark: React.FC<{ id: string; size: number; color?: string }> = ({ id, size, color = "#fff" }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={LOGOS[id].d} fill={color} /></svg>);
const GoogleG: React.FC<{ size: number }> = ({ size }) => (
  <svg width={size} height={size} viewBox="0 0 48 48">
    <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z" />
    <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z" />
    <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z" />
    <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z" />
  </svg>);

type Item = { id: "crm" | "offer" | "web" | "steam" | "tools"; label: string; at: number; a?: number; b?: number; text?: string };
type Board = { kind: "b037_board"; label: string; code: string; items: Item[]; allAt?: number };
type Bank = { kind: "b037_bank"; label: string; shipAt: number; richAt: number; rich: number; tag: string; tagAt: number };

// slot colours: a coloured icon tile per product (colour + picture on every card)
const TILE: Record<Item["id"], (p: Pal) => string> = {
  crm: (p) => G(p), offer: (p) => `linear-gradient(135deg, ${p.c} 0%, #0E9384 100%)`, web: () => "#FFFFFF",
  steam: () => "linear-gradient(135deg, #1B2838 0%, #2A475E 100%)", tools: (p) => GOLD(p) };
const TileIcon: React.FC<{ id: Item["id"]; size: number }> = ({ id, size }) =>
  id === "steam" ? <BrandMark id="steam" size={size * 0.62} />
  : id === "web" ? <GoogleG size={size * 0.56} />
  : <Ico d={id === "crm" ? I.users : id === "offer" ? I.pen : I.tools} size={size * 0.56} color="#fff" w={2.3} />;

// ---------- the panel under the slots: acts out the current item ----------
const Detail: React.FC<{ it: Item; t: number; w: number; h: number; p: Pal }> = ({ it, t, w, h, p }) => {
  const ink = p.ink, mute = p.mute;
  if (it.id === "crm") {
    // a pipeline: three columns, lead chips glide from New -> Viewing -> Deal
    const cols = ["New", "Viewing", "Deal"], cw = (w - 2 * 24 - 2 * 20) / 3;
    const mv = r(t, it.a ?? it.at + 0.8, (it.a ?? it.at + 0.8) + 0.7, IO);
    return <>{cols.map((c, i) => (
      <div key={c} style={{ position: "absolute", left: 24 + i * (cw + 20), top: 18, width: cw, height: h - 36, borderRadius: 18, background: "#FFFFFF",
        border: "1.5px solid #E6E8F0", boxSizing: "border-box", padding: "12px 14px", ...rise(t, it.at + 0.1 + i * 0.12) }}>
        <div style={{ ...LABEL, fontSize: 18, color: mute }}>{c}</div>
      </div>))}
      {[0, 1].map((j) => {
        const x = 24 + 14 + (j === 0 ? 2 : 1) * mv * (cw + 20), y = 18 + 46 + j * 58;   // lead 0 glides New -> Deal, lead 1 New -> Viewing
        return <div key={j} style={{ position: "absolute", left: x, top: y, width: cw - 28, height: 48, borderRadius: 12,
          background: j === 0 ? G(p) : `${p.a}22`, display: "flex", alignItems: "center", gap: 10, padding: "0 12px", boxSizing: "border-box",
          ...rise(t, it.at + 0.4 + j * 0.15) }}>
          <div style={{ width: 26, height: 26, borderRadius: 13, background: j === 0 ? "rgba(255,255,255,0.35)" : `${p.a}55` }} />
          <div style={{ flex: 1, height: 10, borderRadius: 5, background: j === 0 ? "rgba(255,255,255,0.6)" : "#D5DAE5" }} />
        </div>;
      })}
    </>;
  }
  if (it.id === "offer") {
    // an offer page on the left, the client's signature draws itself, then "Signed online"
    const sig = r(t, it.a ?? it.at + 0.9, (it.a ?? it.at + 0.9) + 0.8, Easing.linear);
    const ok = r(t, (it.a ?? it.at + 0.9) + 0.8, (it.a ?? it.at + 0.9) + 1.2);
    const DW = 260;
    return <>
      <div style={{ position: "absolute", left: 24, top: 16, width: DW, height: h - 32, borderRadius: 14, background: "#fff", border: "1.5px solid #E6E8F0",
        boxSizing: "border-box", padding: 16, ...rise(t, it.at + 0.1) }}>
        <div style={{ width: 120, height: 14, borderRadius: 7, background: p.c }} />
        {[0, 1, 2].map((k) => <div key={k} style={{ width: [200, 170, 190][k], height: 9, borderRadius: 5, background: "#E3E7EF", marginTop: 12 }} />)}
        <svg width={DW - 32} height={46} viewBox="0 0 220 46" style={{ position: "absolute", left: 16, bottom: 10 }}>
          <line x1={0} y1={42} x2={220} y2={42} stroke="#CBD2DE" strokeWidth={2} />
          <path d="M8 34 C 22 6, 30 6, 34 30 S 52 40, 60 18 S 74 4, 80 30 C 86 44, 100 18, 112 24 S 140 34, 160 16" fill="none" stroke={p.ink} strokeWidth={3.2}
            strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - sig} />
        </svg>
      </div>
      <div style={{ position: "absolute", left: 24 + DW + 28, right: 24, top: 16, ...rise(t, it.at + 0.3) }}>
        <div style={{ ...LABEL, fontSize: 18, color: mute }}>Offer builder</div>
        <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, color: ink, letterSpacing: -1, marginTop: 6 }}>{it.text ?? "Clients sign online"}</div>
      </div>
      <div style={{ position: "absolute", left: 24 + DW + 28, bottom: 22, height: 52, padding: "0 22px", borderRadius: 26, background: "#DCFCE7", color: "#15803D",
        display: "flex", alignItems: "center", gap: 10, fontFamily: UI, fontWeight: 800, fontSize: 26, opacity: ok, transform: `translateY(${(1 - ok) * 10}px)` }}>
        <Ico d={I.check} size={26} color="#15803D" w={3} />Signed</div>
    </>;
  }
  if (it.id === "web") {
    // Google result + AI answer (both cite his site), then real leads drop in
    const ai = r(t, it.a ?? it.at + 0.8, (it.a ?? it.at + 0.8) + 0.5);
    const leadAt = it.b ?? it.at + 1.8;
    const LW = 250, RW = w - 48 - LW - 20;
    return <>
      <div style={{ position: "absolute", left: 24, top: 16, width: RW, height: 60, borderRadius: 30, background: "#fff", border: "1.5px solid #E6E8F0",
        display: "flex", alignItems: "center", gap: 14, padding: "0 20px", boxSizing: "border-box", ...rise(t, it.at + 0.1) }}>
        <GoogleG size={30} />
        <div style={{ height: 12, width: 200, borderRadius: 6, background: "#E3E7EF" }} />
        <div style={{ marginLeft: "auto", fontFamily: UI, fontWeight: 800, fontSize: 22, color: "#1A73E8" }}>#1</div>
      </div>
      <div style={{ position: "absolute", left: 24, top: 92, width: RW, height: h - 108, borderRadius: 18, background: `linear-gradient(135deg, ${p.a}18, ${p.b}18)`,
        border: `1.5px solid ${p.a}44`, boxSizing: "border-box", padding: "12px 18px", opacity: ai, transform: `translateY(${(1 - ai) * 12}px)`,
        filter: ai < 0.99 ? `blur(${(1 - ai) * 8}px)` : undefined }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, ...LABEL, fontSize: 18, color: p.a }}><Ico d={I.spark} size={22} color={p.a} w={2.4} />AI answer</div>
        <div style={{ display: "flex", gap: 10, marginTop: 10 }}>
          <div style={{ height: 10, width: 150, borderRadius: 5, background: `${p.a}55` }} /><div style={{ height: 10, width: 90, borderRadius: 5, background: `${p.a}33` }} /></div>
      </div>
      {[0, 1].map((j) => (
        <div key={j} style={{ position: "absolute", right: 24, top: j === 0 ? 16 : h - 16 - 56, width: LW, height: 56, borderRadius: 14,
          background: "#fff", border: "1.5px solid #E6E8F0", display: "flex", alignItems: "center", gap: 10, padding: "0 14px", boxSizing: "border-box",
          boxShadow: "0 8px 18px -10px rgba(15,23,42,0.3)", ...rise(t, leadAt + j * 0.35, 0.45, -14) }}>
          <div style={{ width: 30, height: 30, borderRadius: 15, background: "#DCFCE7", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ico d={I.bell} size={18} color="#15803D" w={2.4} /></div>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 24, color: ink }}>New client</span>
        </div>))}
    </>;
  }
  if (it.id === "steam") {
    // the real Deep Rise header art + the real Steam mark
    const IW = Math.round((h - 32) * (460 / 215));
    const k = r(t, it.at + 0.1, it.at + 0.7);
    return <>
      <div style={{ position: "absolute", left: 24, top: 16, width: IW, height: h - 32, borderRadius: 14, overflow: "hidden", opacity: k,
        transform: `scale(${0.96 + 0.04 * k})`, boxShadow: "0 12px 26px -12px rgba(2,6,23,0.55)" }}>
        <Img src={staticFile("v4330/dr-header.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${1.02 + 0.04 * r(t, it.at, it.at + 4, (x) => x)})` }} />
      </div>
      <div style={{ position: "absolute", left: 24 + IW + 26, right: 24, top: 18, ...rise(t, it.at + 0.3) }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 42, height: 42, borderRadius: 10, background: "#1B2838", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <BrandMark id="steam" size={30} /></div>
          <span style={{ ...LABEL, fontSize: 18, color: mute }}>Steam</span>
        </div>
        <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 38, color: ink, letterSpacing: -1, marginTop: 10 }}>Deep Rise</div>
        <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 22, color: mute, marginTop: 2 }}>My first video game</div>
      </div>
      {it.a !== undefined && <div style={{ position: "absolute", right: 24, top: 16, height: 46, padding: "0 18px", borderRadius: 23, background: "linear-gradient(135deg, #A4D007, #5BA32B)",
        color: "#fff", display: "flex", alignItems: "center", gap: 8, fontFamily: UI, fontWeight: 800, fontSize: 22, ...rise(t, it.a, 0.4, 10) }}>
        <Ico d={I.check} size={22} color="#fff" w={3} />Released</div>}
    </>;
  }
  // tools: a small grid of everyday tools, one by one
  const icons = [I.cal, I.doc, I.chart, I.chat, I.clock, I.mail];
  const cols = ["#F97316", p.a, p.c, "#6366F1", p.gold2, "#0EA5E9"];
  const S = Math.min(84, (h - 32 - 16) / 2), gx = (w - 48 - 6 * S) / 5;
  return <>{icons.map((d, j) => (
    <div key={j} style={{ position: "absolute", left: 24 + j * (S + gx), top: (h - S) / 2, width: S, height: S, borderRadius: S * 0.26, background: cols[j],
      display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 10px 20px -10px ${cols[j]}`, ...rise(t, it.at + 0.15 + j * 0.12, 0.45) }}>
      <Ico d={d} size={S * 0.5} color="#fff" w={2.4} /></div>))}</>;
};

const BoardView: React.FC<{ s: Board; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const n = s.items.length, SW = (w - 2 * P - (n - 1) * 16) / n, SH = 64, SY = 92;
  const lit = s.items.filter((it) => t >= it.at).length;
  const fill = s.items.reduce((acc, it) => acc + r(t, it.at, it.at + 0.6, IO), 0) / n;
  const cur = [...s.items].reverse().find((it) => t >= it.at - 0.05);
  const prev = cur ? s.items[s.items.indexOf(cur) - 1] : undefined;
  const sw = cur ? r(t, cur.at - 0.05, cur.at + 0.25) : 0;
  const all = s.allAt !== undefined ? r(t, s.allAt, s.allAt + 0.5, IO) : 0;
  const DY = SY + SH + 46, DH = h - DY - 24;
  return <>
    <div style={{ position: "absolute", left: P, top: 30, ...LABEL, color: p.mute }}>{s.label}</div>
    {/* "0 lines of code" chip: a struck code icon */}
    <div style={{ position: "absolute", right: P, top: 20, height: 46, padding: "0 18px", borderRadius: 23, background: `${p.a}14`, border: `1.5px solid ${p.a}44`,
      display: "flex", alignItems: "center", gap: 10, fontFamily: UI, fontWeight: 800, fontSize: 22, color: p.ink, whiteSpace: "nowrap" }}>
      <span style={{ position: "relative", display: "inline-flex" }}><Ico d={I.code} size={26} color={p.a} w={2.6} />
        <svg width={26} height={26} viewBox="0 0 24 24" style={{ position: "absolute", left: 0, top: 0 }}><path d="M4 20L20 4" stroke={p.a} strokeWidth={2.6} strokeLinecap="round" /></svg></span>
      {s.code}</div>
    {/* five slots: dashed until he names one, then the coloured tile lands */}
    {s.items.map((it, i) => {
      const k = r(t, it.at - 0.05, it.at + 0.45);
      const active = cur === it ? 1 - all : 0;
      return <div key={it.id} style={{ position: "absolute", left: P + i * (SW + 16), top: SY, width: SW, height: SH, borderRadius: 18, boxSizing: "border-box",
        border: k > 0.02 ? `2px solid ${active > 0.5 ? p.a : "#E6E8F0"}` : "2px dashed #CBD2DE", background: k > 0.02 ? "#fff" : "transparent",
        display: "flex", alignItems: "center", gap: 10, padding: "0 10px", boxShadow: active > 0.5 ? `0 10px 22px -12px ${p.a}` : undefined }}>
        <div style={{ width: 44, height: 44, flexShrink: 0, borderRadius: 12, background: k > 0.02 ? TILE[it.id](p) : "#EEF0F5",
          border: it.id === "web" && k > 0.02 ? "1.5px solid #E6E8F0" : undefined, boxSizing: "border-box",
          display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${lerp(0.7, 1, k)})` }}>
          {k > 0.02 && <div style={{ opacity: k, display: "flex" }}><TileIcon id={it.id} size={44} /></div>}
        </div>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 21, color: p.ink, opacity: k, whiteSpace: "nowrap" }}>{it.label}</span>
      </div>;
    })}
    {/* May -> Nov bar fills one fifth per item */}
    <div style={{ position: "absolute", left: P + 70, right: P + 70, top: SY + SH + 20, height: 8, borderRadius: 4, background: "#E9ECF3" }}>
      <div style={{ width: `${fill * 100}%`, height: "100%", borderRadius: 4, background: lit === n ? GOLD(p) : G(p) }} /></div>
    <div style={{ position: "absolute", left: P, top: SY + SH + 10, ...LABEL, fontSize: 18, color: p.mute }}>May</div>
    <div style={{ position: "absolute", right: P, top: SY + SH + 10, ...LABEL, fontSize: 18, color: p.mute }}>Nov</div>
    {/* the panel acts out the current item; the previous one blurs away first */}
    <div style={{ position: "absolute", left: P, right: P, top: DY, height: DH, borderRadius: 22, background: "#F4F6FA", border: "1.5px solid #E9ECF3", overflow: "hidden" }}>
      {prev && sw < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - sw, filter: `blur(${sw * 8}px)` }}>
        <Detail it={prev} t={t} w={w - 2 * P} h={DH} p={p} /></div>}
      {cur && <div style={{ position: "absolute", inset: 0, opacity: sw * (1 - all) }}><Detail it={cur} t={t} w={w - 2 * P} h={DH} p={p} /></div>}
      {/* frame 1 + "we live in the future": the five finished products line up in the panel (result first, then the recap) */}
      {(!cur || all > 0) && <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 22, opacity: cur ? all : 1 }}>
        {s.items.map((it, i) => <div key={it.id} style={{ width: 92, height: 92, borderRadius: 24, background: TILE[it.id](p), border: it.id === "web" ? "1.5px solid #E6E8F0" : undefined,
          boxSizing: "border-box", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 12px 24px -12px rgba(15,23,42,0.45)",
          transform: `translateY(${cur ? (1 - r(t, s.allAt! + i * 0.07, s.allAt! + i * 0.07 + 0.5)) * 30 : Math.sin(t * 2 + i) * 3}px)` }}><TileIcon id={it.id} size={92} /></div>)}
      </div>}
    </div>
  </>;
};

const BankView: React.FC<{ s: Bank; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const rows = [
    { label: "Shipped", at: s.shipAt, to: 1, bg: GOLD(p), value: "5 / 5" },
    { label: "Rich", at: s.richAt, to: s.rich, bg: "linear-gradient(90deg, #F87171, #EF4444)", value: s.tag },
  ];
  const tag = r(t, s.tagAt, s.tagAt + 0.4);
  return <>
    <div style={{ position: "absolute", left: P, top: 26, display: "flex", alignItems: "center", gap: 14 }}>
      <div style={{ width: 52, height: 52, borderRadius: 14, background: G(p), display: "flex", alignItems: "center", justifyContent: "center",
        boxShadow: `0 10px 20px -10px ${p.a}` }}><Ico d={I.bank} size={30} color="#fff" w={2.4} /></div>
      <span style={{ ...LABEL, color: p.mute }}>{s.label}</span>
    </div>
    {rows.map((row, i) => {
      const k = r(t, row.at, row.at + (i === 0 ? 0.7 : 1.1), IO);
      const y = 104 + i * 84;
      return <div key={row.label} style={{ position: "absolute", left: P, right: P, top: y, height: 64, ...rise(t, row.at - 0.2, 0.4) }}>
        <span style={{ position: "absolute", left: 0, top: 12, width: 150, fontFamily: UI, fontWeight: 800, fontSize: 32, color: p.ink }}>{row.label}</span>
        <div style={{ position: "absolute", left: 160, right: 170, top: 18, height: 28, borderRadius: 14, background: "#E9ECF3", overflow: "hidden" }}>
          <div style={{ width: `${Math.max(0.02, row.to * k) * 100}%`, height: "100%", borderRadius: 14, background: row.bg }} /></div>
        <span style={{ position: "absolute", right: 0, top: 12, width: 150, textAlign: "right", fontFamily: UI, fontWeight: 800, fontSize: 30, color: p.ink,
          fontVariantNumeric: "tabular-nums" }}>{row.value || `${Math.round(row.to * k * 100)}%`}</span>
      </div>;
    })}
    {tag > 0 && false && <div style={{ position: "absolute", right: P, top: 22, height: 56, padding: "0 24px", borderRadius: 28, background: "#FEE2E2", color: "#B91C1C",
      display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 28, opacity: tag, transform: `translateY(${(1 - tag) * 10}px)`, whiteSpace: "nowrap" }}>
      {s.tag}</div>}
  </>;
};

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) =>
  s.kind === "b037_board" ? <BoardView s={s as unknown as Board} w={w} h={h} t={t} p={p} />
  : s.kind === "b037_bank" ? <BankView s={s as unknown as Bank} w={w} h={h} t={t} p={p} />
  : null;
export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = () => null;
