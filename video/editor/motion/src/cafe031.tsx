import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "./kit11";

// 031 cafés with playgrounds: extra kit11 glass-card scenes, kept in their own file so parallel edits of kit11 don't collide.
// place = abstract map tile with a pin that drops + café name / area; trio = 3 icon tiles lighting up on their words;
// checks = 3 rows that tick on their words.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const GOLD = (p: Pal) => `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`;
const gradText = (bg: string): React.CSSProperties => ({ background: bg, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" });
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 28, letterSpacing: 2.4, textTransform: "uppercase" };
const P = 36;

const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
export const CI: Record<string, string> = {
  pin: "M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z",
  cup: "M4 9h12v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM16 10h1.5a2.5 2.5 0 0 1 0 5H16M8 3.5v2.5M12 3.5v2.5",
  laptop: "M5 5h14v10H5zM2.5 19h19",
  blocks: "M3 13h8v8H3zM13 13h8v8h-8zM8 3h8v8H8z",
  noscreen: "M4 5h16v11H4zM9 20h6M3 3l18 18",
  smile: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM8.5 14.5a4.5 4.5 0 0 0 7 0M9 9.5h.01M15 9.5h.01",
  check: "M5 12.5l4.5 4.5L19 7.5",
  trophy: "M7 4h10v5a5 5 0 0 1-10 0zM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4M12 14v4M8 20h8",
};

export type CafeScene =
  | { kind: "place"; label: string; title: string; sub: string; pinAt: number; badge?: string; badgeAt?: number }
  | { kind: "trio"; label: string; tiles: { icon: string; text: string; at: number }[] }
  | { kind: "checks"; label: string; rows: { icon: string; text: string; at: number }[] };

// abstract map tile: soft blocks + two roads + water edge, a pin drops in. No logos, no drawn buildings.
const MapTile: React.FC<{ w: number; h: number; t: number; pinAt: number; p: Pal }> = ({ w, h, t, pinAt, p }) => {
  const k = r(t, pinAt, pinAt + 0.55);
  const ring = r(t, pinAt + 0.35, pinAt + 1.3);
  return <div style={{ position: "relative", width: w, height: h, borderRadius: 24, overflow: "hidden", background: "#E3F1E7" }}>
    <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
      <path d={`M0 ${h * 0.78} C ${w * 0.35} ${h * 0.68}, ${w * 0.6} ${h * 0.95}, ${w} ${h * 0.8} L ${w} ${h} L 0 ${h} Z`} fill="#8FD0EA" />
      {[[0.08, 0.08, 0.34, 0.26], [0.52, 0.06, 0.4, 0.2], [0.08, 0.42, 0.26, 0.2], [0.56, 0.38, 0.36, 0.24]].map(([x, y, bw, bh], i) =>
        <rect key={i} x={x * w} y={y * h} width={bw * w} height={bh * h} rx={10} fill={i % 2 ? "#BFE6CC" : "#A8DDB9"} />)}
      <path d={`M ${w * 0.46} 0 L ${w * 0.46} ${h}`} stroke="#FFFFFF" strokeWidth={14} />
      <path d={`M 0 ${h * 0.34} L ${w} ${h * 0.31}`} stroke="#FFFFFF" strokeWidth={12} />
    </svg>
    <div style={{ position: "absolute", left: w * 0.46 - 40, top: h * 0.34 - 40, width: 80, height: 80, borderRadius: 40, border: `3px solid ${p.b}`,
      opacity: (1 - ring) * (ring > 0 ? 0.8 : 0), transform: `scale(${0.4 + ring * 1.2})` }} />
    <div style={{ position: "absolute", left: w * 0.46 - 30, top: h * 0.34 - 62, opacity: k, transform: `translateY(${(1 - k) * -40}px)` }}>
      <svg width={60} height={66} viewBox="0 0 24 26"><path d="M12 25s-8.5-7.6-8.5-14A8.5 8.5 0 0 1 20.5 11c0 6.4-8.5 14-8.5 14z" fill={p.b} stroke="#fff" strokeWidth={1.6} />
        <circle cx={12} cy={11} r={3.4} fill="#fff" /></svg>
    </div>
  </div>;
};

export const CafeSceneView: React.FC<{ s: CafeScene; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  switch (s.kind) {
    case "place": {
      const MW = h - 60, left = P + MW + 34;
      const bk = s.badgeAt === undefined ? 0 : r(t, s.badgeAt, s.badgeAt + 0.45);
      return <>
        <div style={{ position: "absolute", left: P, top: 30 }}><MapTile w={MW} h={MW} t={t} pinAt={s.pinAt} p={p} /></div>
        <div style={{ position: "absolute", left, right: P, top: 0, bottom: 0, display: "flex", flexDirection: "column", justifyContent: "center" }}>
          <div style={{ ...LABEL, color: p.mute }}>{s.label}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 64, letterSpacing: -2.4, lineHeight: 1.04, marginTop: 8, ...gradText(G(p)) }}>{s.title}</div>
          <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 33, color: p.ink, marginTop: 12, display: "flex", alignItems: "center", gap: 8 }}>
            <Ico d={CI.pin} size={32} color={p.b} />{s.sub}</div>
          {s.badge && <div style={{ height: 58, marginTop: 16, opacity: bk, transform: `translateY(${(1 - bk) * 10}px)` }}>
            <div style={{ display: "inline-flex", height: 58, padding: "0 24px", borderRadius: 29, background: GOLD(p), color: p.ink, alignItems: "center", gap: 10,
              fontFamily: UI, fontWeight: 800, fontSize: 30 }}><Ico d={CI.trophy} size={30} color={p.ink} w={2.4} />{s.badge}</div></div>}
        </div>
      </>;
    }
    case "trio": {
      const n = s.tiles.length, gap = 24, TW = (w - P * 2 - gap * (n - 1)) / n, top = 92, TH = h - top - 34;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 34, color: p.mute }}>{s.label}</div>
        {s.tiles.map((tl, i) => {
          const f = r(t, tl.at, tl.at + 0.45);
          return <div key={i} style={{ position: "absolute", left: P + i * (TW + gap), top, width: TW, height: TH, borderRadius: 22, overflow: "hidden",
            background: "linear-gradient(180deg, #EEF2F6 0%, #E2E8EF 100%)" }}>
            <div style={{ position: "absolute", inset: 0, background: i === n - 1 ? GOLD(p) : G(p), opacity: f }} />
            <div style={{ position: "absolute", left: 0, right: 0, top: 26, display: "flex", justifyContent: "center", transform: `scale(${0.85 + 0.15 * f})` }}>
              <Ico d={CI[tl.icon]} size={72} color={f > 0.5 ? (i === n - 1 ? p.ink : "#fff") : "#94A3B8"} w={2} /></div>
            <div style={{ position: "absolute", left: 0, right: 0, bottom: 22, textAlign: "center", fontFamily: UI, fontWeight: 800, fontSize: 42,
              color: f > 0.5 ? (i === n - 1 ? p.ink : "#fff") : "#94A3B8" }}>{tl.text}</div>
          </div>;
        })}
      </>;
    }
    case "checks": {
      const RH = 78, top = 94;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 32, color: p.mute }}>{s.label}</div>
        {s.rows.map((rw, i) => {
          const f = r(t, rw.at, rw.at + 0.45), c = r(t, rw.at + 0.15, rw.at + 0.5, IO);
          return <div key={i} style={{ position: "absolute", left: P, right: P, top: top + i * (RH + 16), height: RH, borderRadius: RH / 2, display: "flex", alignItems: "center",
            gap: 18, padding: "0 12px", background: f > 0 ? "#F0FDF4" : "#F1F4F8", border: `2px solid ${f > 0.5 ? p.a : "#E3E8EF"}`, opacity: 0.35 + 0.65 * f }}>
            <div style={{ width: 54, height: 54, borderRadius: 27, background: f > 0.5 ? G(p) : "#CBD5E1", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ transform: `scale(${c})` }}><Ico d={CI.check} size={34} color="#fff" w={3} /></div></div>
            <Ico d={CI[rw.icon]} size={40} color={f > 0.5 ? p.b : "#94A3B8"} />
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 44, color: f > 0.5 ? p.ink : "#94A3B8", whiteSpace: "nowrap" }}>{rw.text}</span>
          </div>;
        })}
      </>;
    }
  }
};
