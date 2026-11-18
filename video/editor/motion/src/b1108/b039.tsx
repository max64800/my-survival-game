import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";

// Video 039 "My most expensive mistake as a CTO" (Vercel bill). Owned by the 039 edit only: other videos never touch this file.
// One kit11 glass card morphs: bill ($30 -> $112) -> vibe coder -> deploy list -> bot / 7,000 pages / Google -> x24 = 160,000+
// -> Vercel spend management (budget alert on) -> bookend bill. Every kind starts with "b039_" (kit11 routes them here).
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const GOLD = (p: Pal) => `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`;
const gradText = (bg: string): React.CSSProperties => ({ background: bg, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" });
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 26, letterSpacing: 2.2, textTransform: "uppercase", whiteSpace: "nowrap" };
const P = 36;
const fmt = (n: number) => Math.round(n).toLocaleString("en-US");
const show = (t: number, at: number, d = 0.45, dy = 12): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)` };
};

const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ flexShrink: 0 }}><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  bell: "M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0",
  clock: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3.5 2",
  check: "M5 12.5l4.5 4.5L19 7.5",
  q: "M9.2 9a3 3 0 1 1 4.3 2.7c-.9.45-1.5 1.1-1.5 2.1v.4M12 18h.01",
  up: "M12 19V5M6 11l6-6 6 6",
  page: "M6 3h8l4 4v14H6zM14 3v4h4",
  x: "M6 6l12 12M18 6L6 18",
};

// faithful Vercel mark: a plain solid triangle, white on a black tile
const Vercel: React.FC<{ size: number }> = ({ size }) => (
  <div style={{ width: size, height: size, borderRadius: size * 0.24, background: "#000", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center",
    boxShadow: "0 8px 18px -8px rgba(0,0,0,0.6)" }}>
    <svg width={size * 0.56} height={size * 0.56} viewBox="0 0 76 65"><path d="M37.5 0L75 65H0z" fill="#fff" /></svg>
  </div>);
// Google "G" (four-colour mark) on a white tile
const Google: React.FC<{ size: number }> = ({ size }) => (
  <div style={{ width: size, height: size, borderRadius: size * 0.24, background: "#fff", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center",
    border: "2px solid #E5E7EB", boxSizing: "border-box", boxShadow: "0 8px 18px -10px rgba(0,0,0,0.35)" }}>
    <svg width={size * 0.58} height={size * 0.58} viewBox="0 0 24 24">
      <path fill="#4285F4" d="M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z" />
      <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z" />
      <path fill="#FBBC05" d="M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29C.47 8.24 0 10.06 0 12s.47 3.76 1.29 5.38l3.98-3.09z" />
      <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09c.95-2.85 3.6-4.96 6.73-4.96z" />
    </svg>
  </div>);
// bot = a small UI robot glyph in the palette gradient (abstract icon, not object art)
const Bot: React.FC<{ size: number; p: Pal; blink: number }> = ({ size, p, blink }) => (
  <div style={{ width: size, height: size, borderRadius: size * 0.24, background: G(p), flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center",
    boxShadow: `0 10px 22px -10px ${p.b}` }}>
    <svg width={size * 0.62} height={size * 0.62} viewBox="0 0 24 24">
      <path d="M12 2.5v3" stroke="#fff" strokeWidth={2} strokeLinecap="round" /><circle cx={12} cy={2.5} r={1.4} fill="#fff" />
      <rect x={4} y={6.5} width={16} height={12} rx={4} fill="#fff" />
      <rect x={8} y={11} width={2.6} height={2.6 * (1 - 0.8 * blink)} rx={1.3} fill={p.b} /><rect x={13.4} y={11} width={2.6} height={2.6 * (1 - 0.8 * blink)} rx={1.3} fill={p.b} />
      <path d="M2 11v4M22 11v4" stroke="#fff" strokeWidth={2} strokeLinecap="round" />
    </svg>
  </div>);
const Chip: React.FC<{ bg: string; color: string; h?: number; fs?: number; style?: React.CSSProperties; children: React.ReactNode }> = ({ bg, color, h = 56, fs = 28, style, children }) => (
  <div style={{ display: "inline-flex", alignItems: "center", gap: 10, height: h, padding: `0 ${h * 0.4}px`, borderRadius: h / 2, background: bg, color, fontFamily: UI,
    fontWeight: 800, fontSize: fs, whiteSpace: "nowrap", boxSizing: "border-box", ...style }}>{children}</div>);

type Bill = { kind: "b039_bill"; label: string; total: number; from?: number; countAt?: number; expect?: string; expectAt?: number;
  tag?: string; tagAt?: number; gold?: boolean; alert?: string; alertAt?: number };
type Vibe = { kind: "b039_vibe"; label: string; title: string; at: number; chip: string; chipAt: number; q: string; qAt: number };
type Deploys = { kind: "b039_deploys"; label: string; at: number; rows: string[]; speed: number; featAt: number; feat: string };
type Bots = { kind: "b039_bots"; label: string; at: number; countAt: number; count: number; unit: string; hourAt: number; hour: string; googleAt: number; ask: string };
type MathS = { kind: "b039_math"; a: string; aAt: number; b: string; bAt: number; res: number; resAt: number; unit: string };
type Alert = { kind: "b039_alert"; title: string; at: number; budget: string; onAt: number; row: string; allAt: number; all: string };
export type B039 = Bill | Vibe | Deploys | Bots | MathS | Alert;

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = ({ s: raw, w, h, t, p }) => {
  const s = raw as unknown as B039;
  switch (s.kind) {
    case "b039_bill": {
      // invoice: Vercel tile | label, "should be" chip, big total that counts up on its spoken number, tag
      const k = s.countAt === undefined ? 1 : r(t, s.countAt, s.countAt + 1.1, IO);
      const v = (s.from ?? s.total) + (s.total - (s.from ?? s.total)) * k;
      const RX = P + 150 + 34;
      const over = v > 31;
      return <>
        <div style={{ position: "absolute", left: P, top: (h - 150) / 2 }}><Vercel size={150} /></div>
        <div style={{ position: "absolute", left: RX, right: P, top: 34 }}>
          <div style={{ ...LABEL, color: p.mute }}>{s.label}</div>
          <div style={{ display: "flex", alignItems: "center", gap: 18, marginTop: 6, height: 132 }}>
            <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 124, letterSpacing: -5, lineHeight: 1, fontVariantNumeric: "tabular-nums", width: 330,
              ...(over ? gradText("linear-gradient(135deg, #FF5A4E 0%, #D61F45 100%)") : { color: p.ink }) }}>${fmt(v)}</div>
            {s.expect && <div style={{ ...show(t, s.expectAt ?? 0), display: "flex", flexDirection: "column", gap: 6 }}>
              <span style={{ ...LABEL, fontSize: 20, color: p.mute }}>Should be</span>
              <Chip bg="#DCFCE7" color="#15803D" h={52} fs={30}>{s.expect}</Chip></div>}
          </div>
          <div style={{ display: "flex", gap: 16, marginTop: 14, height: 56 }}>
            {s.tag && <div style={show(t, s.tagAt ?? 0)}>
              <Chip bg={s.gold ? GOLD(p) : "#FEE2E2"} color={s.gold ? p.ink : "#B91C1C"}>
                <Ico d={s.gold ? I.check : I.up} size={28} color={s.gold ? p.ink : "#B91C1C"} w={2.8} />{s.tag}</Chip></div>}
            {s.alert && <div style={show(t, s.alertAt ?? 0)}>
              <Chip bg="#DCFCE7" color="#15803D"><Ico d={I.bell} size={28} color="#15803D" w={2.4} />{s.alert}</Chip></div>}
          </div>
        </div>
      </>;
    }
    case "b039_vibe": {
      // dark code window that types itself | "CTO" + "Vibe coder" chip + amber "?" chip
      const CWW = 330, CH = h - 68;
      const lines = [[0.55, "#C084FC"], [0.8, "#60A5FA"], [0.4, "#FBBF24"], [0.7, "#34D399"], [0.5, "#F472B6"]] as const;
      return <>
        <div style={{ position: "absolute", left: P, top: 34, width: CWW, height: CH, borderRadius: 22, background: "#0B0D12", overflow: "hidden" }}>
          <div style={{ display: "flex", gap: 8, padding: "16px 18px" }}>{["#FF5F57", "#FEBC2E", "#28C840"].map((c) => <div key={c} style={{ width: 14, height: 14, borderRadius: 7, background: c }} />)}</div>
          {lines.map(([lw, c], i) => {
            const f = r(t, s.at + i * 0.3, s.at + i * 0.3 + 0.35, IO);
            return <div key={i} style={{ position: "absolute", left: 22 + (i % 2) * 24, top: 58 + i * 34, height: 14, borderRadius: 7, background: c, opacity: 0.9,
              width: (CWW - 70) * lw * f }} />;
          })}
        </div>
        <div style={{ position: "absolute", left: P + CWW + 34, right: P, top: 34 }}>
          <div style={{ ...LABEL, color: p.mute }}>{s.label}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 64, letterSpacing: -2.4, lineHeight: 1.05, marginTop: 6, ...gradText(G(p)) }}>{s.title}</div>
          <div style={{ marginTop: 16, height: 58, ...show(t, s.chipAt) }}><Chip bg={G(p)} color="#fff" h={58} fs={30}>{s.chip}</Chip></div>
          <div style={{ marginTop: 16, height: 58, ...show(t, s.qAt) }}><Chip bg="#FEF3C7" color="#B45309" h={58} fs={30}>
            <Ico d={I.q} size={30} color="#B45309" w={2.6} />{s.q}</Chip></div>
        </div>
      </>;
    }
    case "b039_deploys": {
      // Vercel deployments list scrolling fast; rows enter from the bottom, all "Ready"
      const RH = 66, top = 104, view = h - top - 26;
      const off = view + Math.max(0, t - s.at) * s.speed * (1 + 0.6 * r(t, s.featAt, s.featAt + 0.8, IO));   // starts full
      const first = Math.max(0, Math.floor((off - view) / RH) - 1);   // row idx sits at the bottom when off = idx * RH, then rises
      const n = Math.ceil(view / RH) + 3;
      return <>
        <div style={{ position: "absolute", left: P, top: 26, display: "flex", alignItems: "center", gap: 16 }}><Vercel size={56} />
          <span style={{ ...LABEL, color: p.mute }}>{s.label}</span></div>
        <div style={{ position: "absolute", right: P, top: 26, ...show(t, s.featAt) }}><Chip bg={GOLD(p)} color={p.ink} h={56} fs={27}>
          <Ico d={I.up} size={26} color={p.ink} w={2.8} />{s.feat}</Chip></div>
        <div style={{ position: "absolute", left: P, right: P, top, height: view, overflow: "hidden",
          WebkitMaskImage: "linear-gradient(180deg, transparent 0%, #000 18%, #000 82%, transparent 100%)", maskImage: "linear-gradient(180deg, transparent 0%, #000 18%, #000 82%, transparent 100%)" }}>
          {Array.from({ length: n }, (_, j) => {
            const idx = first + j;
            const y = view - (off - idx * RH);
            if (y < -RH || y > view + RH) return null;
            return <div key={idx} style={{ position: "absolute", left: 0, right: 0, top: y, height: RH - 12, borderRadius: 16, background: idx % 2 ? "#F4F6FA" : "#FFFFFF",
              border: "1.5px solid #E6E9F0", display: "flex", alignItems: "center", gap: 16, padding: "0 18px", boxSizing: "border-box" }}>
              <div style={{ width: 14, height: 14, borderRadius: 7, background: "#22C55E", flexShrink: 0 }} />
              <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: p.ink, whiteSpace: "nowrap", flex: 1 }}>{s.rows[((idx % s.rows.length) + s.rows.length) % s.rows.length]}</span>
              <Chip bg="#DCFCE7" color="#15803D" h={36} fs={20}>Ready</Chip>
            </div>;
          })}
        </div>
      </>;
    }
    case "b039_bots": {
      // the whole bot line in one state: bot tile pings | page counter climbs to 7,000 on its word | Google tile lands on "Google";
      // under it: "every hour" chip (clock hand spins) and the "found?" question chip
      const TY = 96, TS = 132;
      const gk = r(t, s.googleAt, s.googleAt + 0.45);
      const ck = r(t, s.countAt, s.countAt + 1.1, IO);
      const ring = ((Math.max(0, t - s.at) * 1.25) % 1);
      const hand = Math.max(0, t - s.hourAt) * 360 * 1.2;
      const CX = P + TS + 40;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 34, color: p.mute }}>{s.label}</div>
        <div style={{ position: "absolute", left: P, top: TY }}>
          <div style={{ position: "absolute", left: 0, top: 0, width: TS, height: TS, borderRadius: TS * 0.24, border: `3px solid ${p.b}`, boxSizing: "border-box",
            opacity: t >= s.at ? (1 - ring) * 0.7 : 0, transform: `scale(${1 + ring * 0.35})` }} />
          <Bot size={TS} p={p} blink={Math.sin(t * 6) > 0.95 ? 1 : 0} /></div>
        <div style={{ position: "absolute", left: CX, top: TY - 2, ...show(t, s.countAt - 0.15) }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 100, letterSpacing: -4, lineHeight: 1, fontVariantNumeric: "tabular-nums", width: 330, ...gradText(G(p)) }}>
            {fmt(s.count * ck)}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: p.ink, marginTop: 6, display: "flex", alignItems: "center", gap: 8 }}>
            <Ico d={I.page} size={34} color={p.b} w={2.2} />{s.unit}</div>
        </div>
        <div style={{ position: "absolute", right: P, top: TY, transform: `scale(${0.85 + 0.15 * gk})`, opacity: gk }}><Google size={TS} /></div>
        <div style={{ position: "absolute", left: P, top: TY + TS + 30, ...show(t, s.hourAt) }}>
          <Chip bg="#FEE2E2" color="#B91C1C" h={60} fs={30}>
            <svg width={32} height={32} viewBox="0 0 24 24"><circle cx={12} cy={12} r={9} fill="none" stroke="#B91C1C" strokeWidth={2.4} />
              <path d="M12 12V6.5" stroke="#B91C1C" strokeWidth={2.4} strokeLinecap="round" transform={`rotate(${hand} 12 12)`} /></svg>{s.hour}</Chip></div>
        <div style={{ position: "absolute", right: P, top: TY + TS + 30, ...show(t, s.googleAt + 0.2) }}>
          <Chip bg="#EFF6FF" color="#1D4ED8" h={60} fs={30}><Ico d={I.q} size={30} color="#1D4ED8" w={2.4} />{s.ask}</Chip></div>
      </>;
    }
    case "b039_math": {
      // 7,000 pages x 24 a day -> the result counts up to "160,000+" (he said "over 160,000"; the exact sum is 168,000)
      const k = r(t, s.resAt, s.resAt + 1.2, IO);
      return <>
        <div style={{ position: "absolute", left: P, top: 28, display: "flex", alignItems: "center", gap: 18 }}>
          <div style={show(t, s.aAt)}><Chip bg="#EFF2F7" color={p.ink} h={58} fs={30}><Ico d={I.page} size={30} color={p.b} w={2.3} />{s.a}</Chip></div>
          <div style={{ ...show(t, s.bAt), fontFamily: UI, fontWeight: 800, fontSize: 44, color: p.mute }}>×</div>
          <div style={show(t, s.bAt)}><Chip bg="#EFF2F7" color={p.ink} h={58} fs={30}><Ico d={I.clock} size={30} color={p.b} w={2.3} />{s.b}</Chip></div>
        </div>
        <div style={{ position: "absolute", left: P, top: 102, ...show(t, s.resAt - 0.1) }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 108, letterSpacing: -4.5, lineHeight: 1, fontVariantNumeric: "tabular-nums",
            ...gradText("linear-gradient(135deg, #FF5A4E 0%, #D61F45 100%)") }}>{fmt(160000 * k)}{k >= 1 ? "+" : ""}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, color: p.ink, lineHeight: 1.1, marginTop: 8 }}>{s.unit}</div>
        </div>
      </>;
    }
    case "b039_alert": {
      // Vercel spend management: budget field, alert toggle flips on, then "on every project" chip
      const on = r(t, s.onAt, s.onAt + 0.4, IO);
      const RY = 116;
      return <>
        <div style={{ position: "absolute", left: P, top: 30, display: "flex", alignItems: "center", gap: 16 }}><Vercel size={56} />
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: p.ink, letterSpacing: -1 }}>{s.title}</span></div>
        <div style={{ position: "absolute", left: P, right: P, top: RY, height: 92, borderRadius: 22, background: "#F4F6FA", border: "1.5px solid #E6E9F0",
          display: "flex", alignItems: "center", gap: 18, padding: "0 22px", boxSizing: "border-box" }}>
          <div style={{ width: 56, height: 56, borderRadius: 16, background: on > 0.5 ? GOLD(p) : "#E2E8F0", display: "flex", alignItems: "center", justifyContent: "center",
            transform: `rotate(${Math.sin(Math.PI * on * 3) * 14 * (1 - on)}deg)` }}><Ico d={I.bell} size={34} color={on > 0.5 ? p.ink : "#94A3B8"} w={2.4} /></div>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: p.ink, whiteSpace: "nowrap", flex: 1 }}>{s.row}</span>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: p.mute, whiteSpace: "nowrap" }}>{s.budget}</span>
          <div style={{ width: 92, height: 52, borderRadius: 26, background: on > 0.5 ? "#22C55E" : "#CBD5E1", position: "relative", flexShrink: 0 }}>
            <div style={{ position: "absolute", top: 5, left: 5 + 40 * on, width: 42, height: 42, borderRadius: 21, background: "#fff", boxShadow: "0 2px 6px rgba(0,0,0,0.25)" }} />
          </div>
        </div>
        <div style={{ position: "absolute", left: P, top: RY + 92 + 26, ...show(t, s.allAt) }}>
          <Chip bg="#DCFCE7" color="#15803D" h={58} fs={30}><Ico d={I.check} size={30} color="#15803D" w={2.8} />{s.all}</Chip></div>
      </>;
    }
  }
  return null;
};
export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = () => null;
