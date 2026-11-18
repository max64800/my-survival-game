import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// kit11 glass-card scenes for 029 "vibe coding backlash" (IMG_4225). Kept in their own file so parallel kit11 work
// doesn't collide; kit11's Scene falls through to Scene029 for these kinds. Same look: Inter, ease-out, no overshoot.
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });
type Pal = { a: string; b: string; c: string; gold: string; gold2: string; ink: string; mute: string; glow: string[] };
export type Scene029Def =
  | { kind: "hook"; label: string; words: { w: string; s: number }[]; pill: string; pillAt: number; chip: string }
  | { kind: "build"; title: string; who: string; rows: { text: string; at: number }[]; startAt: number; doneAt: number; minutes: number; readyAt: number }
  | { kind: "compare"; label: string; meAt: number; meDoneAt: number; me: string; ai: string }
  | { kind: "rec"; text: string; at: number }
  | { kind: "mistake"; msg: string; msgAt: number; msgDur: number; siteAt: number; feature: string; okAt: number; ok: string; wrong: string; wrongAt: number }
  | { kind: "job"; label: string; rowA: string; rowAAt: number; strikeAt: number; rowB: string; rowBAt: number; checkAt: number };
export const KINDS_029 = ["hook", "build", "compare", "rec", "mistake", "job"];

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
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 24, letterSpacing: 2.4, textTransform: "uppercase" };
const P = 36;
const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  check: "M5 12.5l4.5 4.5L19 7.5",
  chat: "M4 5h16v11H9l-5 4z",
  spark: "M12 3v5M12 16v5M3 12h5M16 12h5M5.6 5.6l3.5 3.5M14.9 14.9l3.5 3.5M5.6 18.4l3.5-3.5M14.9 9.1l3.5-3.5",
  code: "M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16",
  x: "M6 6l12 12M18 6L6 18",
  clock: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2",
};
const Pill: React.FC<{ bg: string; color: string; children: React.ReactNode; h?: number; fs?: number; style?: React.CSSProperties }> =
  ({ bg, color, children, h = 52, fs = 26, style }) => (
  <div style={{ height: h, padding: `0 ${h * 0.42}px`, borderRadius: h / 2, background: bg, color, display: "flex", alignItems: "center", gap: 10,
    fontFamily: UI, fontWeight: 700, fontSize: fs, whiteSpace: "nowrap", ...style }}>{children}</div>);

// a small report page (generic mockup, no real client data)
const Page: React.FC<{ x: number; y: number; w: number; h: number; p: Pal; fill: number }> = ({ x, y, w, h, p, fill }) => (
  <div style={{ position: "absolute", left: x, top: y, width: w, height: h, borderRadius: 16, background: "#FFFFFF", border: "1.5px solid #E1E6EE",
    boxShadow: "0 10px 22px -12px rgba(15,23,42,0.35)", overflow: "hidden" }}>
    <div style={{ height: h * 0.2, background: G(p) }} />
    <div style={{ padding: `${h * 0.07}px ${w * 0.12}px` }}>
      {[0.8, 0.95, 0.6, 0.85].map((ww, j) => <div key={j} style={{ width: w * 0.76 * ww * Math.min(1, Math.max(0, fill * 4 - j)), height: h * 0.04, borderRadius: 4,
        background: "#E3E8EF", marginBottom: h * 0.05 }} />)}
      <div style={{ display: "flex", alignItems: "flex-end", gap: w * 0.05, height: h * 0.2, marginTop: h * 0.03 }}>
        {[0.45, 0.7, 0.55, 1].map((v, j) => <div key={j} style={{ width: w * 0.13, height: `${v * 100 * Math.min(1, Math.max(0, fill * 4 - 1 - j * 0.5))}%`,
          borderRadius: 4, background: j === 3 ? GOLD(p) : G(p) }} />)}
      </div>
    </div>
  </div>);

export const Scene029: React.FC<{ s: Scene029Def; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  switch (s.kind) {
    case "hook": {
      // frame 1: the finished report (the result) + what people say, word by word; gold "That's the point" on "Yes"
      const PW = 168, PH = 224, left = P + PW + 40;
      const pk = r(t, s.pillAt, s.pillAt + 0.45);
      return <>
        <Page x={P} y={(h - PH) / 2} w={PW} h={PH} p={p} fill={1} />
        <div style={{ position: "absolute", left: P + PW / 2, top: (h + PH) / 2 - 22, transform: "translateX(-50%)" }}><Pill bg={G(p)} color="#fff" h={40} fs={21}>{s.chip}</Pill></div>
        <div style={{ position: "absolute", left, right: P, top: 34 }}>
          <div style={{ ...LABEL, color: p.mute, display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.chat} size={26} color={p.mute} />{s.label}</div>
          <div style={{ fontFamily: UI, fontWeight: 700, fontStyle: "italic", fontSize: 44, lineHeight: 1.14, letterSpacing: -1, color: p.ink, marginTop: 10 }}>
            {s.words.map((x, i) => <span key={i} style={{ opacity: x.s <= 0 ? 1 : r(t, x.s - 0.05, x.s + 0.15) }}>{i ? " " : ""}{x.w}</span>)}
          </div>
        </div>
        {t >= s.pillAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={56} fs={28} style={{ position: "absolute", left, bottom: 34, opacity: pk,
          transform: `translateY(${(1 - pk) * 12}px)`, boxShadow: "0 8px 18px -8px rgba(0,0,0,0.35)" }}><Ico d={I.check} size={26} color={p.ink} w={3} />{s.pill}</Pill>}
      </>;
    }
    case "build": {
      // the report builds itself: rows tick in, a timer runs to 10 min and lands on "minutes"
      const fill = r(t, s.startAt, s.doneAt, IO);
      const m = Math.round(lerp(0, s.minutes, fill));
      const rk = r(t, s.readyAt, s.readyAt + 0.45);
      const RW = 240, LW = w - P * 2 - RW - 28;
      const ring = 2 * Math.PI * 62;
      return <>
        <div style={{ position: "absolute", left: P, top: 30, width: LW, height: h - 60, borderRadius: 22, background: "#F6F8FB", border: "1.5px solid #E3E8EF",
          padding: "22px 26px", boxSizing: "border-box" }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 38, letterSpacing: -1.2, color: p.ink, whiteSpace: "nowrap" }}>{s.title}</div>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 10 }}>
            <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 26, color: p.mute }}>{s.who}</span>
            {/* client name is never shown: a blurred bar */}
            <div style={{ width: 190, height: 22, borderRadius: 11, background: "#CBD5E1", filter: "blur(2.5px)" }} />
          </div>
          {s.rows.map((row, i) => {
            const k = r(t, row.at, row.at + 0.4);
            return <div key={i} style={{ display: "flex", alignItems: "center", gap: 14, marginTop: 12, height: 40, ...rise(t, row.at, 0.4, 8) }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: k > 0.5 ? G(p) : "#E3E8EF", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <Ico d={I.check} size={22} color="#fff" w={3} /></div>
              <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 32, color: p.ink, whiteSpace: "nowrap" }}>{row.text}</span>
            </div>;
          })}
        </div>
        <div style={{ position: "absolute", right: P, top: 30, width: RW, height: h - 60, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
          <div style={{ position: "relative", width: 150, height: 150 }}>
            <svg width={150} height={150} style={{ position: "absolute", inset: 0, transform: "rotate(-90deg)" }}>
              <circle cx={75} cy={75} r={62} fill="none" stroke="#E3E8EF" strokeWidth={12} />
              <circle cx={75} cy={75} r={62} fill="none" stroke={p.a} strokeWidth={12} strokeLinecap="round" strokeDasharray={ring} strokeDashoffset={ring * (1 - fill)} />
            </svg>
            <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
              <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 54, letterSpacing: -2, lineHeight: 1, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{m}</span>
              <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: p.mute }}>min</span>
            </div>
          </div>
          <div style={{ height: 50, opacity: rk, transform: `translateY(${(1 - rk) * 10}px)` }}>
            <Pill bg={GOLD(p)} color={p.ink} h={50} fs={25}><Ico d={I.check} size={24} color={p.ink} w={3} />Ready</Pill></div>
        </div>
      </>;
    }
    case "compare": {
      // same report, two times: his full day (long grey bar) vs Claude's 10 minutes (short gradient bar)
      const g = r(t, s.meAt, s.meDoneAt, IO);
      const LBL = 150, TW = w - P * 2 - LBL, BH = 70, y1 = 96, y2 = y1 + BH + 30;
      const lk = r(t, s.meDoneAt - 0.2, s.meDoneAt + 0.3);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 34, color: p.mute }}>{s.label}</div>
        <div style={{ position: "absolute", left: P, top: y1, height: BH, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 34, color: p.ink }}>Me</div>
        <div style={{ position: "absolute", left: P + LBL, top: y1, width: TW, height: BH, borderRadius: 18, background: "#F1F4F8" }} />
        <div style={{ position: "absolute", left: P + LBL, top: y1, width: Math.max(BH, TW * g), height: BH, borderRadius: 18, background: "linear-gradient(90deg, #94A3B8, #64748B)",
          display: "flex", alignItems: "center", justifyContent: "flex-end", paddingRight: 24, boxSizing: "border-box", overflow: "hidden" }}>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 32, color: "#fff", whiteSpace: "nowrap", opacity: lk }}>{s.me}</span></div>
        <div style={{ position: "absolute", left: P, top: y2, height: BH, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 34, color: p.ink }}>Claude</div>
        <div style={{ position: "absolute", left: P + LBL, top: y2, width: TW, height: BH, borderRadius: 18, background: "#F1F4F8" }} />
        <div style={{ position: "absolute", left: P + LBL, top: y2, width: 120, height: BH, borderRadius: 18, background: G(p), boxShadow: `0 10px 20px -10px ${p.a}AA` }} />
        <div style={{ position: "absolute", left: P + LBL + 120 + 24, top: y2, height: BH, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800,
          fontSize: 34, letterSpacing: -0.8, ...gradText(G(p)) }}>{s.ai}</div>
      </>;
    }
    case "rec": {
      const blink = 0.75 + 0.25 * Math.cos((t - s.at) * Math.PI * 2);
      return <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 18 }}>
        <div style={{ width: 26, height: 26, borderRadius: 13, background: "#EF4444", opacity: blink, boxShadow: "0 0 0 7px #EF444433" }} />
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: p.ink, letterSpacing: -0.8 }}>{s.text}</span>
      </div>;
    }
    case "mistake": {
      // Claude says the site is missing something; the site slides in and shows it's already there; Claude's note gets "Wrong"
      const chars = Math.round(lerp(0, s.msg.length, r(t, s.msgAt, s.msgAt + s.msgDur, (x) => x)));
      const sk = r(t, s.siteAt, s.siteAt + 0.55);
      const ok = r(t, s.okAt, s.okAt + 0.45);
      const wr = r(t, s.wrongAt, s.wrongAt + 0.45);
      const CW = 470, SW = w - P * 2 - CW - 28, top = 30, H = h - 60;
      return <>
        <div style={{ position: "absolute", left: P, top, width: CW, height: H, borderRadius: 22, background: "#F6F8FB", border: "1.5px solid #E3E8EF",
          padding: "22px 24px", boxSizing: "border-box" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 22, background: G(p), display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Ico d={I.spark} size={26} color="#fff" w={2.4} /></div>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: p.ink }}>Claude</span>
          </div>
          <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 36, lineHeight: 1.2, letterSpacing: -0.6, color: p.ink, marginTop: 14 }}>
            {s.msg.slice(0, chars)}<span style={{ opacity: 0 }}>{s.msg.slice(chars)}</span></div>
          {t >= s.wrongAt - 0.02 && <Pill bg="#FEE2E2" color="#B91C1C" h={50} fs={25} style={{ position: "absolute", left: 24, bottom: 20, opacity: wr,
            transform: `translateY(${(1 - wr) * 10}px)` }}><Ico d={I.x} size={22} color="#B91C1C" w={3} />{s.wrong}</Pill>}
        </div>
        <div style={{ position: "absolute", right: P, top, width: SW, height: H, borderRadius: 22, background: "#FFFFFF", border: "1.5px solid #E1E6EE", overflow: "hidden",
          opacity: sk, transform: `translateX(${(1 - sk) * 40}px)`, filter: sk < 0.99 ? `blur(${(1 - sk) * 8}px)` : undefined }}>
          <div style={{ height: 40, background: "#F1F4F8", display: "flex", alignItems: "center", gap: 8, padding: "0 16px" }}>
            {["#F87171", "#FBBF24", "#34D399"].map((c) => <div key={c} style={{ width: 12, height: 12, borderRadius: 6, background: c }} />)}
            <div style={{ flex: 1, height: 18, borderRadius: 9, background: "#E2E8F0", marginLeft: 8 }} /></div>
          <div style={{ margin: "16px 18px 0", height: 62, borderRadius: 12, background: G(p), opacity: 0.85 }} />
          <div style={{ margin: "16px 18px 0", height: 58, borderRadius: 14, border: `2.5px solid ${ok > 0.5 ? "#16A34A" : "#E3E8EF"}`,
            background: ok > 0.5 ? "#DCFCE7" : "#F8FAFC", display: "flex", alignItems: "center", gap: 10, padding: "0 14px", boxSizing: "border-box",
            transform: `scale(${1 + 0.05 * Math.sin(Math.PI * ok)})` }}>
            <div style={{ width: 30, height: 30, borderRadius: 15, background: ok > 0.5 ? "#16A34A" : "#CBD5E1", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Ico d={I.check} size={20} color="#fff" w={3} /></div>
            <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 26, color: p.ink, whiteSpace: "nowrap" }}>{s.feature}</span>
          </div>
          {t >= s.okAt - 0.02 && <div style={{ position: "absolute", left: 18, bottom: 16, opacity: ok, transform: `translateY(${(1 - ok) * 10}px)` }}>
            <Pill bg="#16A34A" color="#fff" h={44} fs={22}>{s.ok}</Pill></div>}
        </div>
      </>;
    }
    case "job": {
      // the real job: "typing code" gets a thin strike and dims; "catching mistakes" ticks gold
      const st = r(t, s.strikeAt, s.strikeAt + 0.45, IO);
      const ck = r(t, s.checkAt, s.checkAt + 0.45);
      const row = (y: number, at: number, icon: React.ReactNode, text: string, extra: React.CSSProperties, strike?: number) => (
        <div style={{ position: "absolute", left: P, right: P, top: y, height: 76, borderRadius: 20, background: "#F6F8FB", border: "1.5px solid #E3E8EF",
          display: "flex", alignItems: "center", gap: 18, padding: "0 22px", boxSizing: "border-box", ...rise(t, at, 0.45, 12) }}>
          {icon}
          <span style={{ position: "relative", fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, whiteSpace: "nowrap", ...extra }}>{text}
            {strike !== undefined && <div style={{ position: "absolute", left: -4, right: -4, top: "52%", height: 3, borderRadius: 2, background: "#475569",
              transformOrigin: "0 50%", transform: `scaleX(${strike})` }} />}</span>
        </div>);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 30, color: p.mute }}>{s.label}</div>
        {row(78, s.rowAAt, <div style={{ width: 46, height: 46, borderRadius: 12, background: "#E3E8EF", display: "flex", alignItems: "center", justifyContent: "center",
          opacity: 1 - 0.5 * st }}><Ico d={I.code} size={28} color={p.mute} w={2.4} /></div>, s.rowA,
          { color: p.ink, opacity: 1 - 0.55 * st, transform: `scale(${1 - 0.05 * st})`, transformOrigin: "0 50%", display: "inline-block" }, st)}
        {t >= s.rowBAt - 0.05 && row(78 + 76 + 26, s.rowBAt, <div style={{ width: 46, height: 46, borderRadius: 12, background: ck > 0.5 ? GOLD(p) : "#E3E8EF",
          display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + 0.12 * Math.sin(Math.PI * ck)})` }}>
          <Ico d={I.check} size={28} color={ck > 0.5 ? p.ink : "#fff"} w={3} /></div>, s.rowB, gradText(G(p)))}
      </>;
    }
  }
};
