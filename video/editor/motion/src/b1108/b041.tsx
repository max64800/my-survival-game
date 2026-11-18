import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";

// Video 041 "Only 3% of households pay for AI" (IMG_4333, Nov 8 batch). Owned by the 041 edit only.
// kit11 glass-card scenes (kind "b041_*"): 100-dot household grid -> Bank of America card data -> AI everywhere tiles
// -> back to the grid (feels like 100%, really 3%) -> "Behind?" crossed out -> social feed vs reality.
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });

const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const rise = (t: number, at: number, d = 0.5, dy = 18): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined };
};
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const GOLD = (p: Pal) => `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`;
const gradText = (bg: string): React.CSSProperties => ({ background: bg, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" });
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };
const P = 36;
const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  card: "M3 6h18v12H3zM3 10h18M7 15h4",
  spark: "M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z",
  search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM16 16l5 5",
  mail: "M3 6h18v12H3zM3 7l9 7 9-7",
  photo: "M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 6M16 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3",
  chat: "M4 5h16v11H9l-5 4z",
  pen: "M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4",
  phone: "M7 2h10v20H7zM11 19h2",
  check: "M5 12.5l4.5 4.5L19 7.5",
  heart: "M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z",
  cart: "M3 4h2l2.5 11h11L21 7H6.5M9 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM18 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2z",
  fuel: "M4 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16M4 11h10M14 8l4 3v7a1.5 1.5 0 0 0 3 0v-9l-3-3",
  play: "M8 5.5v13l10.5-6.5z",
};
const Pill: React.FC<{ bg: string; color: string; children: React.ReactNode; h?: number; fs?: number; style?: React.CSSProperties }> =
  ({ bg, color, children, h = 52, fs = 26, style }) => (
  <div style={{ height: h, padding: `0 ${h * 0.42}px`, borderRadius: h / 2, background: bg, color, display: "flex", alignItems: "center", gap: 10,
    fontFamily: UI, fontWeight: 700, fontSize: fs, whiteSpace: "nowrap", ...style }}>{children}</div>);

// Bank of America flag mark, simplified: three red bands top-right, three navy bands bottom-left, split on a diagonal
export const BofA: React.FC<{ size: number }> = ({ size }) => (
  <svg width={size * 1.6} height={size} viewBox="0 0 48 30">
    {[0, 1, 2].map((i) => <path key={"r" + i} d={`M${14 + i * 4} ${2 + i * 5} L46 ${2 + i * 5} L46 ${5.5 + i * 5} L${17 + i * 4} ${5.5 + i * 5} Z`} fill="#E31837" />)}
    {[0, 1, 2].map((i) => <path key={"b" + i} d={`M2 ${13 + i * 5} L${31 - (2 - i) * 4} ${13 + i * 5} L${28 - (2 - i) * 4} ${16.5 + i * 5} L2 ${16.5 + i * 5} Z`} fill="#012169" />)}
  </svg>);

type Lab = { at: number; top: string; sub: string };
export type B041 =
  // big % counter + 10x10 households grid; `lit` dots light at `litAt`; optional allAt (every dot: "feels like") and dropAt (back to the lit ones)
  | { kind: "b041_dots"; labels: Lab[]; countAt: number; to: number; lit: number[]; litAt: number[]; allAt?: number; dropAt?: number; src: string; tag?: string; tagAt?: number }
  | { kind: "b041_bank"; label: string; title: string; sub: string; rows: { text: string; icon: string; at: number; ai?: boolean }[]; chip: string; chipAt: number; src: string }
  | { kind: "b041_ai"; label: string; tiles: { text: string; icon: string; at: number }[] }
  | { kind: "b041_behind"; label: string; q: string; strikeAt: number; ok: string; okAt: number }
  | { kind: "b041_feed"; label: string; posts: { who: string; text: string; at: number }[]; chip: string; chipAt: number };

const Dots: React.FC<{ s: Extract<B041, { kind: "b041_dots" }>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const D = 22, GAP = 8, GS = D * 10 + GAP * 9, gx = w - P - GS, gy = (h - GS) / 2;
  const all = s.allAt === undefined ? 0 : r(t, s.allAt, s.allAt + 0.9, IO);
  const drop = s.dropAt === undefined ? 0 : r(t, s.dropAt, s.dropAt + 0.9, IO);
  let v = s.to * r(t, s.countAt, s.countAt + 0.8, IO);
  v = lerp(v, 100, all); v = lerp(v, s.to, drop);
  let li = 0;
  while (li + 1 < s.labels.length && s.labels[li + 1].at <= t) li++;
  const lab = s.labels[li];
  const tg = s.tagAt === undefined ? 0 : r(t, s.tagAt, s.tagAt + 0.45);
  return <>
    <div key={"l" + li} style={{ position: "absolute", left: P, top: 30, ...(li > 0 ? rise(t, lab.at, 0.45, 10) : {}) }}>
      <div style={{ ...LABEL, color: p.mute }}>{lab.top}</div>
    </div>
    <div style={{ position: "absolute", left: P - 6, top: 62, fontFamily: UI, fontWeight: 800, fontSize: 168, letterSpacing: -7, lineHeight: 1,
      fontVariantNumeric: "tabular-nums", ...gradText(drop > 0.5 || all < 0.5 ? GOLD(p) : G(p)) }}>{Math.round(v)}%</div>
    <div key={"s" + li} style={{ position: "absolute", left: P, top: 238, fontFamily: UI, fontWeight: 700, fontSize: 34, color: p.ink, letterSpacing: -0.6,
      ...(li > 0 ? rise(t, lab.at, 0.45, 10) : {}) }}>{lab.sub}</div>
    <div style={{ position: "absolute", left: P, bottom: 26, display: "flex", alignItems: "center", gap: 10 }}>
      <BofA size={20} /><span style={{ fontFamily: UI, fontWeight: 600, fontSize: 18, color: p.mute }}>{s.src}</span></div>
    {Array.from({ length: 100 }, (_, i) => {
      const j = s.lit.indexOf(i);
      const on = j >= 0 ? r(t, s.litAt[j], s.litAt[j] + 0.4) : Math.min(r(t, (s.allAt ?? 1e9) + i * 0.006, (s.allAt ?? 1e9) + i * 0.006 + 0.35),
        1 - r(t, (s.dropAt ?? 1e9) + (99 - i) * 0.005, (s.dropAt ?? 1e9) + (99 - i) * 0.005 + 0.35));
      const hot = j >= 0;
      return <div key={i} style={{ position: "absolute", left: gx + (i % 10) * (D + GAP), top: gy + Math.floor(i / 10) * (D + GAP), width: D, height: D, borderRadius: D / 2,
        background: "#E4E7EF" }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: D / 2, opacity: on, transform: `scale(${0.6 + 0.4 * on})`,
          background: hot ? GOLD(p) : G(p), boxShadow: hot && on > 0.5 ? `0 0 14px ${p.gold2}` : undefined }} /></div>;
    })}
    {s.tag && tg > 0 && <Pill bg={GOLD(p)} color={p.ink} h={48} fs={24} style={{ position: "absolute", right: P + GS + 28, top: 36, opacity: tg,
      transform: `translateY(${(1 - tg) * 10}px)` }}>{s.tag}</Pill>}
  </>;
};

const Bank: React.FC<{ s: Extract<B041, { kind: "b041_bank" }>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const RW = 400, RH = 58, RG = 12, rx = w - P - RW, ry = (h - (RH * s.rows.length + RG * (s.rows.length - 1))) / 2;
  const ck = r(t, s.chipAt, s.chipAt + 0.45);
  return <>
    <div style={{ position: "absolute", left: P, top: 30, ...LABEL, color: p.mute }}>{s.label}</div>
    <div style={{ position: "absolute", left: P, top: 76, display: "flex", alignItems: "center", gap: 14 }}>
      <BofA size={44} />
      <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#012169", letterSpacing: -0.8, lineHeight: 1.05 }}>{s.title.split("|").map((x, i) => <div key={i}>{x}</div>)}</div>
    </div>
    <div style={{ position: "absolute", left: P, top: 186, display: "flex", alignItems: "center", gap: 10, fontFamily: UI, fontWeight: 700, fontSize: 28, color: p.ink }}>
      <Ico d={I.card} size={30} color={p.a} w={2.4} />{s.sub}</div>
    {t >= s.chipAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={52} fs={25} style={{ position: "absolute", left: P, top: 250, opacity: ck,
      transform: `translateY(${(1 - ck) * 10}px)` }}>{s.chip}</Pill>}
    <div style={{ position: "absolute", left: P, bottom: 22, fontFamily: UI, fontWeight: 600, fontSize: 17, color: p.mute }}>{s.src}</div>
    {s.rows.map((rw, i) => {
      const k = r(t, rw.at, rw.at + 0.45);
      return <div key={i} style={{ position: "absolute", left: rx, top: ry + i * (RH + RG), width: RW, height: RH, borderRadius: 16, boxSizing: "border-box",
        background: rw.ai ? "#FFF7E6" : "#F3F5F9", border: `1.5px solid ${rw.ai ? p.gold : "#E4E8F0"}`, display: "flex", alignItems: "center", gap: 14, padding: "0 18px",
        opacity: k, transform: `translateX(${(1 - k) * 30}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 6}px)` : undefined }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: rw.ai ? GOLD(p) : G(p), display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Ico d={I[rw.icon as keyof typeof I] ?? I.card} size={22} color={rw.ai ? p.ink : "#fff"} w={2.2} /></div>
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 27, color: p.ink, whiteSpace: "nowrap" }}>{rw.text}</span>
      </div>;
    })}
  </>;
};

const Tiles: React.FC<{ s: Extract<B041, { kind: "b041_ai" }>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const C = 3, GX = 24, GY = 20, top = 80, TW = (w - P * 2 - GX * (C - 1)) / C, rows = Math.ceil(s.tiles.length / C), TH = (h - top - 30 - GY * (rows - 1)) / rows;
  return <>
    <div style={{ position: "absolute", left: P, top: 30, ...LABEL, color: p.mute }}>{s.label}</div>
    {s.tiles.map((tl, i) => {
      const k = r(t, tl.at, tl.at + 0.45);
      return <div key={i} style={{ position: "absolute", left: P + (i % C) * (TW + GX), top: top + Math.floor(i / C) * (TH + GY), width: TW, height: TH, borderRadius: 20,
        boxSizing: "border-box", background: "#F3F5F9", border: "1.5px solid #E4E8F0", display: "flex", alignItems: "center", gap: 14, padding: "0 18px",
        opacity: k, transform: `translateY(${(1 - k) * 20}px) scale(${0.94 + 0.06 * k})`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined }}>
        <div style={{ width: 52, height: 52, borderRadius: 14, background: i % 2 ? GOLD(p) : G(p), display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
          <Ico d={I[tl.icon as keyof typeof I] ?? I.spark} size={28} color={i % 2 ? p.ink : "#fff"} w={2.3} /></div>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: p.ink, letterSpacing: -0.6, whiteSpace: "nowrap" }}>{tl.text}</span>
      </div>;
    })}
  </>;
};

const Behind: React.FC<{ s: Extract<B041, { kind: "b041_behind" }>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  // one row: icon + question (struck through), then a gold "You're not" pill lands at the right
  const st = r(t, s.strikeAt, s.strikeAt + 0.5, IO), ok = r(t, s.okAt, s.okAt + 0.5);
  const RY = 76;
  return <>
    <div style={{ position: "absolute", left: P, top: 28, ...LABEL, color: p.mute }}>{s.label}</div>
    <div style={{ position: "absolute", left: P, top: RY, height: 76, display: "flex", alignItems: "center", gap: 18 }}>
      <div style={{ width: 72, height: 72, borderRadius: 20, background: G(p), display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Ico d={I.spark} size={40} color="#fff" w={2.4} /></div>
      <div style={{ position: "relative", fontFamily: UI, fontWeight: 800, fontSize: 60, color: st > 0.5 ? p.mute : p.ink, letterSpacing: -2, whiteSpace: "nowrap" }}>
        {s.q}
        <div style={{ position: "absolute", left: -6, right: -6, top: "54%", height: 7, borderRadius: 4, background: "#EF4444", transformOrigin: "0 50%", transform: `scaleX(${st})` }} />
      </div>
    </div>
    {t >= s.okAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={64} fs={32} style={{ position: "absolute", right: P, top: RY + 6, opacity: ok, transform: `translateX(${(1 - ok) * 24}px)`,
      filter: ok < 0.99 ? `blur(${(1 - ok) * 6}px)` : undefined, boxShadow: `0 10px 22px -10px ${p.gold2}` }}><Ico d={I.check} size={32} color={p.ink} w={3} />{s.ok}</Pill>}
  </>;
};

const Feed: React.FC<{ s: Extract<B041, { kind: "b041_feed" }>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const RH = 64, RG = 12, top = 86, ck = r(t, s.chipAt, s.chipAt + 0.5), RW = w - P * 2 - 230 - 28;
  return <>
    <div style={{ position: "absolute", left: P, top: 30, ...LABEL, color: p.mute, display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.phone} size={24} color={p.mute} />{s.label}</div>
    <div style={{ position: "absolute", left: P, top, width: RW, height: h - top - 26, overflow: "hidden" }}>
      {s.posts.map((ps, i) => {
        const k = r(t, ps.at, ps.at + 0.45);
        return <div key={i} style={{ position: "absolute", left: 0, top: i * (RH + RG), width: RW, height: RH, borderRadius: 16, boxSizing: "border-box",
          background: "#F3F5F9", border: "1.5px solid #E4E8F0", display: "flex", alignItems: "center", gap: 12, padding: "0 14px", opacity: k,
          transform: `translateY(${(1 - k) * 22}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 6}px)` : undefined }}>
          <div style={{ width: 38, height: 38, borderRadius: 19, background: [G(p), GOLD(p), `linear-gradient(135deg, ${p.c}, ${p.b})`][i % 3], flex: "none" }} />
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: p.ink, whiteSpace: "nowrap" }}>{ps.text}</span>
          <div style={{ marginLeft: "auto", flex: "none" }}><Ico d={I.heart} size={24} color="#EF4444" w={2.4} /></div>
        </div>;
      })}
    </div>
    <div style={{ position: "absolute", right: P, top: (h - 190) / 2 + 14, width: 230, height: 190, borderRadius: 24, background: GOLD(p), opacity: ck,
      transform: `translateX(${(1 - ck) * 30}px)`, filter: ck < 0.99 ? `blur(${(1 - ck) * 8}px)` : undefined, boxShadow: `0 12px 26px -12px ${p.gold2}`,
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
      <div style={{ ...LABEL, fontSize: 20, color: p.ink }}>Real life</div>
      <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 84, color: p.ink, letterSpacing: -3, lineHeight: 1 }}>3%</div>
      <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 22, color: p.ink }}>{s.chip}</div>
    </div>
  </>;
};

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  const d = s as unknown as B041;
  switch (d.kind) {
    case "b041_dots": return <Dots s={d} w={w} h={h} t={t} p={p} />;
    case "b041_bank": return <Bank s={d} w={w} h={h} t={t} p={p} />;
    case "b041_ai": return <Tiles s={d} w={w} h={h} t={t} p={p} />;
    case "b041_behind": return <Behind s={d} w={w} h={h} t={t} p={p} />;
    case "b041_feed": return <Feed s={d} w={w} h={h} t={t} p={p} />;
    default: return null;
  }
};
export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = () => null;
