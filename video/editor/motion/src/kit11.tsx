import React from "react";
import { Easing, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { AppLogo } from "./kit7";
import { CafeScene, CafeSceneView } from "./cafe031";
import { BatchScene, isBatchKind } from "./b1108";
import { Scene029, Scene029Def, KINDS_029 } from "./glass029";
import { Scene028, Scene028Def, KINDS_028 } from "./oneword028";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// Kit 11 "gradient glass" (Max, 2026-10-21: kit10 was "very in your face... not smooth... childish"; wants professional,
// minimal, still bright, smooth, a style of our own). Stripe-like: a flowing gradient band at the top, ONE white glass card
// with a gradient rim that morphs between clean UI mockups, Inter only, ease-out curves with no overshoot.
// Palette per video from colour theory (024: warm oak + gold shirt -> complementary indigo/blue, gold accents).
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });

export type Pal = { a: string; b: string; c: string; gold: string; gold2: string; ink: string; mute: string; glow: string[] };
export const PAL: Pal = { a: "#5B4BFF", b: "#2F7BFF", c: "#8B5CF6", gold: "#F7D774", gold2: "#E9A53A", ink: "#0F172A", mute: "#64748B",
  glow: ["#5B4BFF", "#2F7BFF", "#8B5CF6", "#38BDF8"] };
const G = (p: Pal) => `linear-gradient(135deg, ${p.a} 0%, ${p.b} 100%)`;
const GOLD = (p: Pal) => `linear-gradient(135deg, ${p.gold} 0%, ${p.gold2} 100%)`;
const gradText = (bg: string): React.CSSProperties => ({ background: bg, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" });

const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);        // expo-out: entrances
const IO = Easing.bezier(0.65, 0, 0.35, 1);        // on-screen moves and morphs
const IN = Easing.bezier(0.3, 0, 1, 1);            // exits
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
// soft entrance: fade + rise + un-blur, no bounce
const rise = (t: number, at: number, d = 0.5, dy = 18): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined };
};
const count = (t: number, at: number, to: number, d = 0.9, from = 0) => Math.round(lerp(from, to, r(t, at, at + d, IO)));
const fmt = (n: number) => n.toLocaleString("en-US");

const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };
const Pill: React.FC<{ bg: string; color: string; children: React.ReactNode; h?: number; fs?: number; style?: React.CSSProperties }> =
  ({ bg, color, children, h = 52, fs = 26, style }) => (
  <div style={{ height: h, padding: `0 ${h * 0.42}px`, borderRadius: h / 2, background: bg, color, display: "flex", alignItems: "center", gap: 10,
    fontFamily: UI, fontWeight: 700, fontSize: fs, whiteSpace: "nowrap", ...style }}>{children}</div>);

// thin line icons
const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  play: "M8 5.5v13l10.5-6.5z",
  eye: "M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z",
  cap: "M2 9l10-5 10 5-10 5zM6 11v5c0 1.5 2.7 3 6 3s6-1.5 6-3v-5",
  lock: "M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3",
  check: "M5 12.5l4.5 4.5L19 7.5",
  doc: "M7 3h7l4 4v14H7zM14 3v4h4",
  pin: "M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z",
  sun: "M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
  pen: "M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4",
  chat: "M4 5h16v11H9l-5 4z",
  x: "M6 6l12 12M18 6L6 18",
  clock: "M12 7v5l3 2M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z",
};

// ---------------- top gradient band (replaces the flat soft-split panel) ----------------
// slowly flowing mesh of the palette, solid at the top and melting into the video by `fade` px
export const Aurora: React.FC<{ k: number; solid: number; fade: number; pal?: Pal }> = ({ k, solid, fade, pal = PAL }) => {
  const t = useT();
  const m = (s: number, a: number) => 50 + Math.sin(t * s + a) * 30;
  const bg = [
    `radial-gradient(40% 70% at ${m(0.35, 0)}% ${30 + Math.sin(t * 0.5) * 20}%, ${pal.c}EE 0%, ${pal.c}00 70%)`,
    `radial-gradient(45% 80% at ${m(0.28, 2)}% ${40 + Math.cos(t * 0.4) * 25}%, #38BDF8CC 0%, #38BDF800 70%)`,
    `radial-gradient(22% 40% at ${m(0.22, 4)}% ${55 + Math.sin(t * 0.33 + 1) * 20}%, ${pal.gold}B0 0%, ${pal.gold}00 70%)`,
    `linear-gradient(120deg, ${pal.a} 0%, ${pal.b} 55%, ${pal.c} 100%)`,
  ].join(", ");
  const mask = `linear-gradient(180deg, #000 0px, #000 ${solid * k}px, transparent ${fade * k}px)`;
  return <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: Math.max(1, fade * k + 4), background: bg, opacity: Math.min(1, k * 1.3),
    WebkitMaskImage: mask, maskImage: mask }} />;
};

// ---------------- the glass card scenes ----------------
export type GScene =
  | { kind: "viral"; label: string; countAt: number; countTo: number; courseAt: number; course: string; price: string }
  | { kind: "grid"; label: string; tiles: { v: string; hot?: boolean }[]; at: number; tagAt: number; tag: string }
  | { kind: "equation"; leftAt: number; rightAt: number; neqAt: number; left: [string, string]; right: [string, string] }
  | { kind: "bars"; labelA: string; labelB: string; months: string[]; A: number[]; B: number[]; growAt: number; stagger?: number; morphAt: number; spikeText?: string;
      tagA: { text: string; at: number }; tagB: { text: string; at: number } }
  | { kind: "twist"; text: string }
  | { kind: "doc"; title: string; chip: string; chipAt: number; docAt: number; countAt: number; count: number }
  | { kind: "checkout"; course: string; price: string; noAt: number; viewsAt: number; views: number }
  // 026 shade map (Lagoon palette)
  | { kind: "title"; label: string; title: string; pillAt: number; time0: number; time1: number; left: number }
  | { kind: "week"; label: string; days: string[]; at: number; stagger: number; chip: string; chipAt: number }
  | { kind: "notes"; label: string; rows: { text: string; at: number }[]; strikeAt: number; tag: string }
  | { kind: "board"; label: string; chips: { text: string; color: string; at: number }[]; tag: { text: string; at: number; chip: number } }
  | { kind: "url"; url: string; at: number; dur?: number; freeAt?: number }
  | { kind: "comment"; prompt: string; at: number; areas: string[]; mapAt: number; mapText: string }
  // 033 Palm video disaster: stopwatch -> YouTube player (real Sentinel-2 Palm) -> script page -> fill-up problem list -> publish
  | { kind: "stopwatch"; label: string; at: number; to: number; d: number; doneAt: number; doneText: string }
  | { kind: "player"; title: string[]; img: string; durAt: number; dur: number; credit: string }
  | { kind: "script"; title: string; at: number; okAt: number; ok: string; fillerAt: number; filler: string }
  | { kind: "fixlist"; label: string; cols: { title: string; rows: { text: string; at: number; fail?: number; slow?: number }[] }[] }
  | { kind: "publish"; title: string; img: string; credit: string; messAt: number; mess: string; pressAt: number; done: string };
export type GState = { at: number; x: number; y: number; w: number; h: number; scale?: number; scene: GScene | CafeScene };
export type GlassDef = { from: number; to: number; states: GState[]; pal?: Pal };

const P = 36;
const Scene: React.FC<{ s: GScene | CafeScene; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  switch (s.kind) {
    case "viral": {
      // their one video: a phone tile + a view counter running to 10,000; then the course they sell lands on the right
      const n = count(t, s.countAt, s.countTo, 1.0);
      const c = r(t, s.courseAt, s.courseAt + 0.5);
      return <>
        <div style={{ position: "absolute", left: P, top: (h - 170) / 2, width: 128, height: 170, borderRadius: 22, background: G(p), display: "flex",
          alignItems: "center", justifyContent: "center", boxShadow: `0 12px 24px -8px ${p.a}88` }}>
          <div style={{ width: 58, height: 58, borderRadius: 29, background: "rgba(255,255,255,0.22)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <svg width={26} height={26} viewBox="0 0 24 24"><path d={I.play} fill="#fff" /></svg></div>
        </div>
        <div style={{ position: "absolute", left: P + 128 + 28, top: (h - 128) / 2 }}>
          <div style={{ ...LABEL, color: p.mute, display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.eye} size={24} color={p.mute} />{s.label}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 76, letterSpacing: -2.5, lineHeight: 1.1, marginTop: 8, fontVariantNumeric: "tabular-nums",
            ...gradText(G(p)) }}>{fmt(n)}</div>
        </div>
        {t >= s.courseAt - 0.02 && <div style={{ position: "absolute", right: P, top: (h - 170) / 2, width: 270, height: 170, borderRadius: 22,
          background: "#F5F6FA", border: "1.5px solid #E6E8F0", padding: "18px 22px", boxSizing: "border-box", opacity: c,
          transform: `translateX(${(1 - c) * 40}px)`, filter: c < 0.99 ? `blur(${(1 - c) * 8}px)` : undefined }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, ...LABEL, fontSize: 19, color: p.mute }}><Ico d={I.cap} size={22} color={p.mute} />{s.course}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 46, color: p.ink, letterSpacing: -1.5, marginTop: 6 }}>{s.price}</div>
          <Pill bg={G(p)} color="#fff" h={44} fs={22} style={{ position: "absolute", left: 22, bottom: 16, boxShadow: `0 8px 18px -6px ${p.b}AA` }}>Buy now</Pill>
        </div>}
      </>;
    }
    case "grid": {
      // their profile: one tile at 10K, the rest ~200. "luck?" tags the hot one
      const TW = 118, gap = (w - P * 2 - TW * s.tiles.length) / (s.tiles.length - 1), TH = 150, top = 74;
      const tg = r(t, s.tagAt, s.tagAt + 0.45);
      const hot = s.tiles.findIndex((x) => x.hot);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 26, color: p.mute }}>{s.label}</div>
        {s.tiles.map((tl, i) => (
          <div key={i} style={{ position: "absolute", left: P + i * (TW + gap), top, width: TW, height: TH, borderRadius: 18,
            background: tl.hot ? G(p) : "linear-gradient(180deg, #EEF0F6 0%, #E2E5EE 100%)", ...rise(t, s.at + i * 0.06, 0.45, 22),
            boxShadow: tl.hot ? `0 14px 28px -10px ${p.a}AA` : undefined }}>
            <div style={{ position: "absolute", left: 12, bottom: 10, display: "flex", alignItems: "center", gap: 5, fontFamily: UI, fontWeight: 700,
              fontSize: tl.hot ? 30 : 22, color: tl.hot ? "#fff" : p.mute }}>
              <svg width={tl.hot ? 20 : 16} height={tl.hot ? 20 : 16} viewBox="0 0 24 24"><path d={I.play} fill={tl.hot ? "#fff" : p.mute} /></svg>{tl.v}</div>
          </div>))}
        {t >= s.tagAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={46} fs={24} style={{ position: "absolute", left: P + hot * (TW + gap) + TW / 2, top: top - 30,
          transform: `translateX(-50%) translateY(${(1 - tg) * 12}px)`, opacity: tg, boxShadow: "0 8px 18px -8px rgba(0,0,0,0.35)" }}>{s.tag}</Pill>}
      </>;
    }
    case "equation": {
      // first sale (a payment row)  ->  business course; on "doesn't make sense" the arrow turns into a soft red "≠"
      const ne = r(t, s.neqAt, s.neqAt + 0.45, IO);
      const BW = (w - P * 2 - 110) / 2, BH = h - 2 * 34, top = 34;
      const box = (side: 0 | 1, at: number, ln: [string, string], icon: React.ReactNode) => (
        <div style={{ position: "absolute", left: side ? w - P - BW : P, top, width: BW, height: BH, borderRadius: 22, background: "#F5F6FA",
          border: "1.5px solid #E6E8F0", padding: "22px 24px", boxSizing: "border-box", ...rise(t, at, 0.5) }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, ...LABEL, fontSize: 20, color: p.mute }}>{icon}{ln[0]}</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 52, letterSpacing: -1.8, color: p.ink, marginTop: 10, whiteSpace: "nowrap" }}>{ln[1]}</div>
        </div>);
      return <>
        {box(0, s.leftAt, s.left, <div style={{ width: 14, height: 14, borderRadius: 7, background: "#22C55E", boxShadow: "0 0 0 5px #22C55E33" }} />)}
        {box(1, s.rightAt, s.right, <Ico d={I.cap} size={24} color={p.mute} />)}
        <div style={{ position: "absolute", left: w / 2 - 40, top: h / 2 - 40, width: 80, height: 80, borderRadius: 40, display: "flex", alignItems: "center",
          justifyContent: "center", background: ne > 0.5 ? "#FEE2E2" : "#EEF0F6", ...rise(t, Math.max(s.leftAt, s.rightAt), 0.4) }}>
          <span style={{ position: "absolute", fontFamily: UI, fontWeight: 800, fontSize: 44, color: p.a, opacity: 1 - ne, transform: `rotate(${ne * 90}deg)` }}>→</span>
          <span style={{ position: "absolute", fontFamily: UI, fontWeight: 800, fontSize: 52, color: "#EF4444", opacity: ne, transform: `scale(${0.6 + 0.4 * ne})` }}>≠</span>
        </div>
      </>;
    }
    case "bars": {
      // monthly revenue grows bar by bar (steady), then the SAME bars morph into views per video: one spike, the rest flat
      const n = s.A.length, top = 80, base = h - 52, BW = (w - P * 2) / n - 12;
      const m = r(t, s.morphAt, s.morphAt + 0.8, IO);
      const lab = r(t, s.morphAt, s.morphAt + 0.5, IO);
      const peak = s.B.indexOf(Math.max(...s.B));
      const ta = r(t, s.tagA.at, s.tagA.at + 0.45), tb = r(t, s.tagB.at, s.tagB.at + 0.45);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 26, color: p.mute, opacity: 1 - lab }}>{s.labelA}</div>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 26, color: p.mute, opacity: lab }}>{s.labelB}</div>
        {s.A.map((a, i) => {
          const g = r(t, s.growAt + i * (s.stagger ?? 0.07), s.growAt + i * (s.stagger ?? 0.07) + 0.55);
          const v = lerp(a * g, s.B[i], m);
          const H = Math.max(6, v * (base - top));
          const spike = i === peak && m > 0.5;
          return <React.Fragment key={i}>
            <div style={{ position: "absolute", left: P + i * (BW + 12) + 6, top: base - H, width: BW, height: H, borderRadius: 10,
              background: spike ? GOLD(p) : G(p), opacity: m > 0 && i !== peak ? 1 - 0.55 * m : 1 }} />
            <div style={{ position: "absolute", left: P + i * (BW + 12) + 6, top: base + 12, width: BW, textAlign: "center", fontFamily: UI, fontWeight: 600,
              fontSize: 20, color: p.mute, opacity: g * (1 - lab) }}>{s.months[i]}</div>
          </React.Fragment>;
        })}
        {s.spikeText && m > 0 && <div style={{ position: "absolute", left: P + peak * (BW + 12) + 6 + BW + 12, top: base - s.B[peak] * (base - top) * m,
          fontFamily: UI, fontWeight: 800, fontSize: 34, letterSpacing: -1, opacity: r(t, s.morphAt + 0.5, s.morphAt + 0.9), ...gradText(GOLD(p)) }}>{s.spikeText}</div>}
        {t >= s.tagA.at - 0.02 && <Pill bg="#DCFCE7" color="#15803D" h={46} fs={23} style={{ position: "absolute", right: P, top: 16, opacity: ta * (1 - lab),
          transform: `translateY(${(1 - ta) * 10}px)` }}><Ico d={I.check} size={22} color="#15803D" w={3} />{s.tagA.text}</Pill>}
        {t >= s.tagB.at - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={46} fs={23} style={{ position: "absolute", right: P, top: 16, opacity: tb,
          transform: `translateY(${(1 - tb) * 10}px)` }}>{s.tagB.text}</Pill>}
      </>;
    }
    case "twist": {
      return <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 14 }}>
        <div style={{ width: 16, height: 16, borderRadius: 8, background: GOLD(p), boxShadow: `0 0 0 6px ${p.gold}44` }} />
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: p.ink, letterSpacing: -0.5 }}>{s.text}</span>
      </div>;
    }
    case "doc": {
      // his guide: a page stack that thickens while the page count runs to 100+
      const n = count(t, s.countAt, s.count, 1.1);
      const thick = r(t, s.countAt, s.countAt + 1.1, IO);
      const DX = P + 10, DY = (h - 176) / 2;
      return <>
        {[3, 2, 1, 0].map((k) => (
          <div key={k} style={{ position: "absolute", left: DX + k * 7 * thick, top: DY + k * 5 * thick, width: 132, height: 176, borderRadius: 14,
            background: k ? "#E9ECF4" : "#FFFFFF", border: "1.5px solid #E1E4EE", ...rise(t, s.docAt, 0.5), opacity: k ? thick * (1 - k * 0.15) : 1 }}>
            {!k && <div style={{ padding: "22px 18px" }}>
              <div style={{ width: 52, height: 10, borderRadius: 5, background: G(p), marginBottom: 14 }} />
              {[86, 96, 70, 92, 60].map((ww, j) => <div key={j} style={{ width: ww, height: 7, borderRadius: 4, background: "#E3E6EE", marginBottom: 10 }} />)}
            </div>}
          </div>))}
        <div style={{ position: "absolute", left: DX + 132 + 64, top: DY - 2 }}>
          {t >= s.chipAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={42} fs={21} style={{ display: "inline-flex", ...rise(t, s.chipAt, 0.45, 10) }}>{s.chip}</Pill>}
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1.2, color: p.ink, marginTop: 14, ...rise(t, s.docAt, 0.5) }}>{s.title}</div>
          {t >= s.countAt - 0.02 && <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 4, ...rise(t, s.countAt, 0.4, 10) }}>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 60, letterSpacing: -2, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{n}{n >= s.count ? "+" : ""}</span>
            <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 28, color: p.mute }}>pages</span></div>}
        </div>
      </>;
    }
    case "checkout": {
      // bookend: the course card from the hook comes back as his own; "Buy now" morphs into a locked "Not for sale",
      // then his views keep climbing underneath while the badge stays put
      const no = r(t, s.noAt, s.noAt + 0.55, IO);
      const vk = r(t, s.viewsAt, s.viewsAt + 0.5);
      const v = count(t, s.viewsAt, s.views, 1.2, 1200);
      const BTW = lerp(200, 270, no);
      return <>
        <div style={{ position: "absolute", left: P, top: (h - 150) / 2, width: 150, height: 150, borderRadius: 24, background: G(p), display: "flex",
          alignItems: "center", justifyContent: "center", boxShadow: `0 14px 28px -10px ${p.a}AA` }}><Ico d={I.cap} size={70} color="#fff" w={1.8} /></div>
        <div style={{ position: "absolute", left: P + 150 + 30, top: (h - 150) / 2 + 4 }}>
          <div style={{ ...LABEL, fontSize: 20, color: p.mute }}>Course</div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1.2, color: p.ink, marginTop: 4, whiteSpace: "nowrap" }}>{s.course}</div>
          <div style={{ position: "relative", height: 50, marginTop: 6 }}>
            <div style={{ position: "absolute", display: "flex", alignItems: "baseline", gap: 10, opacity: 1 - vk }}>
              <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 42, color: p.ink, letterSpacing: -1 }}>{s.price}</span>
              <div style={{ position: "absolute", left: -4, right: -4, top: 26, height: 4, borderRadius: 2, background: "#EF4444", transformOrigin: "0 50%", transform: `scaleX(${no})` }} />
            </div>
            {t >= s.viewsAt - 0.02 && <div style={{ position: "absolute", display: "flex", alignItems: "center", gap: 10, ...rise(t, s.viewsAt, 0.5, 12) }}>
              <Ico d={I.eye} size={34} color={p.b} w={2.4} />
              <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 42, letterSpacing: -1, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{fmt(v)}{v >= s.views ? "+" : ""}</span>
              <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 26, color: p.mute }}>views</span></div>}
          </div>
        </div>
        <div style={{ position: "absolute", right: P, top: h - 34 - 58, width: BTW, height: 58, borderRadius: 29, overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, background: G(p), opacity: 1 - no }} />
          <div style={{ position: "absolute", inset: 0, background: "#E5E7EB", opacity: no }} />
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 700, fontSize: 25,
            color: "#fff", opacity: 1 - no, transform: `translateY(${-no * 20}px)` }}>Buy now</div>
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, fontFamily: UI, fontWeight: 700, fontSize: 25,
            color: "#334155", opacity: no, transform: `translateY(${(1 - no) * 20}px)`, whiteSpace: "nowrap" }}><Ico d={I.lock} size={24} color="#334155" w={2.4} />Not for sale</div>
        </div>
      </>;
    }
    case "title": {
      // frame 1: the real map sits in the phone on the left (PhoneShot layer); the name + a shade clock on the right
      const pk = r(t, s.pillAt, s.pillAt + 0.5);
      const mins = Math.round(lerp(s.time0, s.time1, r(t, s.pillAt, s.pillAt + 1.0, IO)) / 5) * 5;
      const hh = String(Math.floor(mins / 60)).padStart(2, "0"), mm = String(mins % 60).padStart(2, "0");
      return <div style={{ position: "absolute", left: s.left, top: 0, bottom: 0, display: "flex", flexDirection: "column", justifyContent: "center" }}>
        <div style={{ ...LABEL, fontSize: 21, color: p.mute, display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.pin} size={24} color={p.b} />{s.label}</div>
        <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 82, letterSpacing: -3, lineHeight: 1.05, marginTop: 8, ...gradText(G(p)) }}>{s.title}</div>
        <div style={{ height: 56, marginTop: 18, opacity: pk, transform: `translateY(${(1 - pk) * 10}px)` }}>
          <Pill bg={GOLD(p)} color={p.ink} h={56} fs={27} style={{ display: "inline-flex" }}><Ico d={I.sun} size={28} color={p.ink} w={2.4} />Shade at
            <span style={{ fontVariantNumeric: "tabular-nums", width: 84 }}>{hh}:{mm}</span></Pill></div>
      </div>;
    }
    case "week": {
      // every single day: seven day tiles fill with sun, one by one; "Age 2" chip
      const n = s.days.length, gap = 14, TW = (w - P * 2 - gap * (n - 1)) / n, top = 92, TH = h - top - 34;
      const ck = r(t, s.chipAt, s.chipAt + 0.45);
      const done = s.days.filter((_, i) => t >= s.at + i * s.stagger + 0.2).length;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 34, color: p.mute }}>{s.label}</div>
        {t >= s.chipAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={46} fs={23} style={{ position: "absolute", right: P, top: 22, opacity: ck,
          transform: `translateY(${(1 - ck) * 10}px)` }}>{s.chip}</Pill>}
        {s.days.map((d, i) => {
          const f = r(t, s.at + i * s.stagger, s.at + i * s.stagger + 0.45);
          return <div key={i} style={{ position: "absolute", left: P + i * (TW + gap), top, width: TW, height: TH, borderRadius: 18, overflow: "hidden",
            background: "linear-gradient(180deg, #EEF2F6 0%, #E2E8EF 100%)" }}>
            <div style={{ position: "absolute", inset: 0, background: G(p), opacity: f, boxShadow: `0 12px 24px -10px ${p.b}AA` }} />
            <div style={{ position: "absolute", left: 0, right: 0, top: 16, display: "flex", justifyContent: "center", opacity: 0.35 + 0.65 * f,
              transform: `scale(${0.8 + 0.2 * f})` }}><Ico d={I.sun} size={34} color={f > 0.5 ? "#fff" : p.mute} w={2.2} /></div>
            <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, textAlign: "center", fontFamily: UI, fontWeight: 700, fontSize: 24,
              color: f > 0.5 ? "#fff" : p.mute }}>{d}</div>
          </div>;
        })}
        <div style={{ display: "none" }}>{done}</div>
      </>;
    }
    case "notes": {
      // the old way: a paper note of shade guesses, struck through on "a bit odd"
      const st = r(t, s.strikeAt, s.strikeAt + 0.5, IO);
      const NW = w - P * 2 - 230;
      return <>
        <div style={{ position: "absolute", left: P, top: 30, width: NW, height: h - 60, borderRadius: 18, background: "#FFFBEB", border: "1.5px solid #F3E6B8",
          padding: "20px 24px", boxSizing: "border-box" }}>
          <div style={{ ...LABEL, fontSize: 19, color: "#A16207", display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.pen} size={22} color="#A16207" />{s.label}</div>
          {s.rows.map((row, i) => (
            <div key={i} style={{ position: "relative", marginTop: 14, height: 40, ...rise(t, row.at, 0.4, 8) }}>
              <span style={{ fontFamily: UI, fontWeight: 600, fontStyle: "italic", fontSize: 30, color: "#57534E", whiteSpace: "nowrap" }}>{row.text}</span>
              <div style={{ position: "absolute", left: -6, right: 0, top: 21, height: 4, borderRadius: 2, background: "#EF4444", transformOrigin: "0 50%",
                transform: `scaleX(${r(t, s.strikeAt + i * 0.12, s.strikeAt + i * 0.12 + 0.4, IO)})` }} />
            </div>))}
        </div>
        <div style={{ position: "absolute", right: P, top: (h - 58) / 2, opacity: st, transform: `translateY(${(1 - st) * 12}px)` }}>
          <Pill bg="#FEE2E2" color="#B91C1C" h={58} fs={26}>{s.tag}</Pill></div>
      </>;
    }
    case "board": {
      // all ten map layers; the ones he names light up, the count climbs to 10; gold tag lands on Dog spots
      const lit = s.chips.filter((c) => t >= c.at).length;
      const n = Math.round(lerp(0, lit, 1));
      const tg = r(t, s.tag.at, s.tag.at + 0.45);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 30, color: p.mute }}>{s.label}</div>
        {t >= s.tag.at - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={46} fs={22} style={{ position: "absolute", right: P + 150, top: 18, opacity: tg,
          transform: `translateY(${(1 - tg) * 10}px)`, boxShadow: "0 8px 18px -8px rgba(0,0,0,0.35)" }}><div style={{ width: 16, height: 16, borderRadius: 8,
          background: s.chips[s.tag.chip].color }} />{s.tag.text}</Pill>}
        <div style={{ position: "absolute", right: P, top: 14, display: "flex", alignItems: "baseline", gap: 6 }}>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 50, letterSpacing: -1.5, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{n}</span>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 26, color: p.mute }}>/ {s.chips.length}</span></div>
        <div style={{ position: "absolute", left: P, right: P, top: 88, display: "flex", flexWrap: "wrap", gap: 14 }}>
          {s.chips.map((c, i) => {
            const k = r(t, c.at, c.at + 0.4);
            return <div key={i} style={{ position: "relative", height: 50, padding: "0 20px 0 14px", borderRadius: 25, display: "flex", alignItems: "center", gap: 10,
              background: k > 0 ? `${c.color}${Math.round(0x14 + k * 0x18).toString(16)}` : "#F1F4F8", border: `2px solid ${k > 0.5 ? c.color : "#E3E8EF"}`,
              fontFamily: UI, fontWeight: 700, fontSize: 24, color: k > 0.5 ? p.ink : "#94A3B8", transform: `scale(${1 + 0.06 * Math.sin(Math.PI * k)})` }}>
              <div style={{ width: 22, height: 22, borderRadius: 11, background: k > 0.5 ? c.color : "#CBD5E1" }} />{c.text}

            </div>;
          })}
        </div>
      </>;
    }
    case "url": {
      // browser bar: the address types itself, then a gold FREE pill
      const chars = Math.round(lerp(0, s.url.length, r(t, s.at, s.at + (s.dur ?? 0.9), (x) => x)));
      const fk = s.freeAt === undefined ? 0 : r(t, s.freeAt, s.freeAt + 0.45);
      const BH = 76;
      return <>
        <div style={{ position: "absolute", left: P, right: s.freeAt === undefined ? P : P + 170, top: (h - BH) / 2, height: BH, borderRadius: BH / 2, background: "#F1F5F9", border: "1.5px solid #E2E8F0",
          display: "flex", alignItems: "center", gap: 14, padding: "0 26px", boxSizing: "border-box" }}>
          <Ico d={I.lock} size={28} color={p.mute} w={2.4} />
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 36, color: p.ink, letterSpacing: -0.5, whiteSpace: "nowrap" }}>{s.url.slice(0, chars)}</span>
          <div style={{ width: 3, height: 38, background: p.b, opacity: chars < s.url.length || Math.floor(t * 2) % 2 ? 1 : 0 }} />
        </div>
        {s.freeAt !== undefined && t >= s.freeAt - 0.02 && <Pill bg={GOLD(p)} color={p.ink} h={64} fs={30} style={{ position: "absolute", right: P, top: (h - 64) / 2, opacity: fk,
          transform: `translateY(${(1 - fk) * 12}px)` }}>FREE</Pill>}
      </>;
    }
    case "comment": {
      // the ask: a comment box cycles real area names, a map tile answers "next"
      const per = 0.7, idx = Math.min(s.areas.length - 1, Math.max(0, Math.floor((t - s.at) / per)));
      const loc = t - s.at - idx * per;
      const area = s.areas[idx];
      const typed = area.slice(0, Math.round(lerp(0, area.length, Math.min(1, Math.max(0, loc / 0.35)))));
      const mk = r(t, s.mapAt, s.mapAt + 0.5);
      const MW = 220;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 30, color: p.mute, display: "flex", alignItems: "center", gap: 8 }}><Ico d={I.chat} size={24} color={p.mute} />{s.prompt}</div>
        <div style={{ position: "absolute", left: P, top: 84, width: w - P * 2 - MW - 28, height: h - 84 - 34, borderRadius: 22, background: "#F1F5F9",
          border: "1.5px solid #E2E8F0", display: "flex", alignItems: "center", gap: 14, padding: "0 24px", boxSizing: "border-box", ...rise(t, s.at - 0.3, 0.45) }}>
          <div style={{ width: 48, height: 48, borderRadius: 24, background: G(p), flexShrink: 0 }} />
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 36, color: p.ink, whiteSpace: "nowrap" }}>{typed}</span>
          <div style={{ width: 3, height: 38, background: p.b }} />
        </div>
        <div style={{ position: "absolute", right: P, top: 84, width: MW, height: h - 84 - 34, borderRadius: 22, overflow: "hidden", background: G(p),
          opacity: mk, transform: `translateX(${(1 - mk) * 30}px)`, boxShadow: `0 12px 24px -10px ${p.b}AA` }}>
          <div style={{ position: "absolute", left: 18, top: 16 }}><Ico d={I.pin} size={40} color="#fff" w={2.2} /></div>
          <div style={{ position: "absolute", left: 18, right: 14, bottom: 14, fontFamily: UI, fontWeight: 800, fontSize: 25, lineHeight: 1.12, color: "#fff" }}>{s.mapText}</div>
        </div>
      </>;
    }
    case "stopwatch": {
      // 033 frame 1: a live stopwatch rolls to 3:30:00 on the spoken number; the edit bar stays stuck and turns "still not done"
      const roll = r(t, s.at, s.at + s.d, IO);
      const v = lerp(Math.max(0, t), s.to + Math.max(0, t - s.at - s.d), roll);
      const dk = r(t, s.doneAt, s.doneAt + 0.45);
      const BY = h - 34 - 48;
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 32, color: p.mute, display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 14, height: 14, borderRadius: 7, background: "#EF4444", opacity: Math.floor(t * 2) % 2 ? 1 : 0.35 }} />{s.label}</div>
        <div style={{ position: "absolute", right: P, top: 26 }}><AppLogo id="yt" size={64} /></div>
        <div style={{ position: "absolute", left: P - 4, top: 78, fontFamily: UI, fontWeight: 800, fontSize: 124, letterSpacing: -4, lineHeight: 1,
          fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{hms(v)}</div>
        <div style={{ position: "absolute", left: P, width: w - P * 2 - 290, top: BY, height: 48, display: "flex", alignItems: "center", gap: 16 }}>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 26, color: p.mute }}>Edit</span>
          <div style={{ flex: 1, height: 14, borderRadius: 7, background: "#E6EAF0", overflow: "hidden" }}>
            <div style={{ width: `${lerp(0, 68, r(t, s.at, s.at + 1.6, IO))}%`, height: "100%", borderRadius: 7, background: dk > 0.5 ? "#EF4444" : G(p) }} /></div>
        </div>
        {t >= s.doneAt - 0.02 && <Pill bg="#FEE2E2" color="#B91C1C" h={48} fs={24} style={{ position: "absolute", right: P, top: BY, opacity: dk,
          transform: `translateY(${(1 - dk) * 10}px)` }}><Ico d={I.x} size={24} color="#B91C1C" w={2.8} />{s.doneText}</Pill>}
      </>;
    }
    case "player": {
      // the 19-minute video: real Sentinel-2 aerial of Palm Jumeirah as the thumbnail, the duration badge counts to 19:00
      const TW = 360, TH = 212, TY = (h - TH) / 2;
      const sec = count(t, s.durAt, s.dur, 1.0);
      return <>
        <div style={{ position: "absolute", left: P, top: TY, width: TW, height: TH, borderRadius: 20, overflow: "hidden", background: "#0B1A2A",
          boxShadow: "0 12px 26px -12px rgba(2,6,23,0.55)" }}>
          <Img src={staticFile(s.img)} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover" }} />
          <div style={{ position: "absolute", right: 12, bottom: 12, height: 38, width: 84, borderRadius: 9, background: "rgba(0,0,0,0.8)", color: "#fff",
            fontFamily: UI, fontWeight: 700, fontSize: 24, display: "flex", alignItems: "center", justifyContent: "center", fontVariantNumeric: "tabular-nums" }}>
            {Math.floor(sec / 60)}:{String(sec % 60).padStart(2, "0")}</div>
        </div>
        <div style={{ position: "absolute", left: P + TW + 28, right: P, top: TY - 4, height: TH + 8, display: "flex", flexDirection: "column", justifyContent: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}><AppLogo id="yt" size={44} /><span style={{ ...LABEL, fontSize: 20, color: p.mute }}>New video</span></div>
          {s.title.map((l, i) => <div key={i} style={{ fontFamily: UI, fontWeight: 800, fontSize: 38, letterSpacing: -1, lineHeight: 1.14, color: p.ink,
            whiteSpace: "nowrap", marginTop: i ? 0 : 14 }}>{l}</div>)}
          <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 16, color: p.mute, marginTop: 12 }}>{s.credit}</div>
        </div>
      </>;
    }
    case "script": {
      // "I script every line": a page writes itself line by line, a green "every line" check, then the filler gets struck out
      const DW = 240, DY = 32, DH = h - 64;
      const ok = r(t, s.okAt, s.okAt + 0.45), fk = r(t, s.fillerAt, s.fillerAt + 0.45), st = r(t, s.fillerAt + 0.3, s.fillerAt + 0.7, IO);
      const RX = P + DW + 40;
      return <>
        <div style={{ position: "absolute", left: P, top: DY, width: DW, height: DH, borderRadius: 18, background: "#FFFFFF", border: "1.5px solid #E1E4EE",
          boxShadow: "0 10px 22px -14px rgba(15,23,42,0.35)", padding: "24px 22px", boxSizing: "border-box" }}>
          <div style={{ width: 70, height: 12, borderRadius: 6, background: G(p), marginBottom: 18 }} />
          {[176, 150, 168, 118, 160, 136, 92].map((ww, j) => <div key={j} style={{ width: ww, height: 9, borderRadius: 5, background: "#D5DAE4", marginBottom: 14,
            transformOrigin: "0 50%", transform: `scaleX(${r(t, s.at + j * 0.12, s.at + j * 0.12 + 0.35, IO)})` }} />)}
        </div>
        <div style={{ position: "absolute", left: RX, top: DY + 4, fontFamily: UI, fontWeight: 800, fontSize: 46, letterSpacing: -1.5, color: p.ink, ...rise(t, s.at, 0.5) }}>{s.title}</div>
        {t >= s.okAt - 0.02 && <Pill bg="#DCFCE7" color="#15803D" h={56} fs={27} style={{ position: "absolute", left: RX, top: DY + 86, opacity: ok,
          transform: `translateY(${(1 - ok) * 10}px)` }}><Ico d={I.check} size={28} color="#15803D" w={2.8} />{s.ok}</Pill>}
        {t >= s.fillerAt - 0.02 && <div style={{ position: "absolute", left: RX, top: DY + 166, height: 56, opacity: fk, transform: `translateY(${(1 - fk) * 10}px)` }}>
          <Pill bg="#F1F4F8" color={p.mute} h={56} fs={27} style={{ opacity: 1 - 0.45 * st }}>{s.filler}</Pill>
          <div style={{ position: "absolute", left: 14, right: 14, top: 26, height: 3, borderRadius: 2, background: "#EF4444", transformOrigin: "0 50%", transform: `scaleX(${st})` }} />
        </div>}
      </>;
    }
    case "fixlist": {
      // the fill-up problem list: each fix appears on its spoken word, then gets a red X + thin strike; the count climbs
      const rows = s.cols.flatMap((c) => c.rows);
      const fails = rows.filter((rw) => rw.fail !== undefined && t >= rw.fail).length;
      const firstFail = Math.min(...rows.map((rw) => rw.fail ?? 1e9));
      const ck = r(t, firstFail, firstFail + 0.45);
      const CWD = (w - P * 2 - 40) / 2, TOPR = 144, RH = 74;
      return <>
        <div style={{ ...LABEL, fontSize: 24, position: "absolute", left: P, top: 34, color: p.mute }}>{s.label}</div>
        {t >= firstFail - 0.02 && <Pill bg="#FEE2E2" color="#B91C1C" h={54} fs={28} style={{ position: "absolute", right: P, top: 20, width: 236, boxSizing: "border-box",
          opacity: ck, transform: `translateY(${(1 - ck) * 10}px)` }}><Ico d={I.x} size={26} color="#B91C1C" w={2.8} />
          <span style={{ fontVariantNumeric: "tabular-nums" }}>{fails}</span>{fails === 1 ? "problem" : "problems"}</Pill>}
        <div style={{ position: "absolute", left: P + CWD + 19, top: 92, bottom: 30, width: 2, background: "#E6E8F0" }} />
        {s.cols.map((c, ci) => <div key={ci} style={{ position: "absolute", left: P + ci * (CWD + 40), top: 92, width: CWD }}>
          <div style={{ ...LABEL, fontSize: 24, color: p.b, opacity: r(t, c.rows[0].at - 0.2, c.rows[0].at + 0.2) }}>{c.title}</div>
          {c.rows.map((rw, ri) => {
            const f = rw.fail === undefined ? 0 : r(t, rw.fail, rw.fail + 0.4, IO);
            const sl = rw.slow === undefined ? 0 : r(t, rw.slow, rw.slow + 0.4, IO);
            const bg = f > 0.5 ? "#EF4444" : sl > 0.5 ? "#F59E0B" : "#FFFFFF";
            return <div key={ri} style={{ position: "absolute", left: 0, top: TOPR - 92 + ri * RH, width: CWD, height: 54, display: "flex", alignItems: "center", gap: 14,
              ...rise(t, rw.at, 0.4, 8) }}>
              <div style={{ width: 44, height: 44, borderRadius: 22, flexShrink: 0, background: bg, border: `2.5px solid ${f > 0.5 ? "#EF4444" : sl > 0.5 ? "#F59E0B" : "#CBD5E1"}`,
                boxSizing: "border-box", display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + 0.12 * Math.sin(Math.PI * Math.max(f, sl))})` }}>
                {f > 0.5 && <Ico d={I.x} size={26} color="#fff" w={3} />}{sl > 0.5 && <Ico d={I.clock} size={28} color="#fff" w={2.6} />}</div>
              <div style={{ position: "relative", opacity: 1 - 0.55 * f, transform: `scale(${1 - 0.05 * f})`, transformOrigin: "0 50%" }}>
                <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: p.ink, whiteSpace: "nowrap" }}>{rw.text}</span>
                <div style={{ position: "absolute", left: -4, right: -4, top: "52%", height: 3, borderRadius: 2, background: "#EF4444", transformOrigin: "0 50%",
                  transform: `scaleX(${f})` }} />
              </div>
            </div>;
          })}
        </div>)}
      </>;
    }
    case "publish": {
      // bookend: the same Palm thumbnail in an upload card; "a mess" chip, then Publish is pressed and turns to `done` ("Coming soon": not live yet)
      const TW = 300, TH = 177, TY = (h - TH) / 2;
      const mk = r(t, s.messAt, s.messAt + 0.45);
      const pr = r(t, s.pressAt, s.pressAt + 0.35, IO);
      const dip = 1 - 0.06 * Math.sin(Math.PI * r(t, s.pressAt - 0.1, s.pressAt + 0.25, IO));
      const RX = P + TW + 28;
      return <>
        <div style={{ position: "absolute", left: P, top: TY, width: TW, height: TH, borderRadius: 18, overflow: "hidden", background: "#0B1A2A",
          boxShadow: "0 12px 26px -12px rgba(2,6,23,0.55)" }}>
          <Img src={staticFile(s.img)} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover" }} />
          <div style={{ position: "absolute", right: 10, bottom: 10, height: 34, width: 76, borderRadius: 8, background: "rgba(0,0,0,0.8)", color: "#fff",
            fontFamily: UI, fontWeight: 700, fontSize: 22, display: "flex", alignItems: "center", justifyContent: "center" }}>19:00</div>
        </div>
        <div style={{ position: "absolute", left: RX, right: P, top: TY - 2 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}><AppLogo id="yt" size={40} /><span style={{ ...LABEL, fontSize: 19, color: p.mute }}>Upload</span></div>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, letterSpacing: -1, color: p.ink, marginTop: 10, whiteSpace: "nowrap" }}>{s.title}</div>
          <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 15, color: p.mute, marginTop: 4 }}>{s.credit}</div>
        </div>
        {t >= s.messAt - 0.02 && <Pill bg="#FEE2E2" color="#B91C1C" h={56} fs={26} style={{ position: "absolute", left: RX, top: TY + TH - 56, opacity: mk,
          transform: `translateY(${(1 - mk) * 10}px)` }}>{s.mess}</Pill>}
        <div style={{ position: "absolute", right: P, top: TY + TH - 56, width: 236, height: 56, borderRadius: 28, transform: `scale(${dip})`,
          background: pr > 0.5 ? GOLD(p) : G(p), boxShadow: `0 10px 22px -10px ${pr > 0.5 ? p.gold2 : p.b}`,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontFamily: UI, fontWeight: 800, fontSize: 27, color: pr > 0.5 ? p.ink : "#fff" }}>
          {pr > 0.5 && <Ico d={I.clock} size={28} color={p.ink} w={2.6} />}{pr > 0.5 ? s.done : "Publish"}</div>
      </>;
    }
    default: return isBatchKind((s as { kind: string }).kind) ? <BatchScene s={s as unknown as { kind: string }} w={w} h={h} t={t} p={p} />   // Nov 8 batch (src/b1108/)
      : KINDS_028.includes((s as { kind: string }).kind) ? <Scene028 s={s as unknown as Scene028Def} w={w} h={h} t={t} p={p} />   // 028 scenes (src/oneword028.tsx)
      : KINDS_029.includes((s as { kind: string }).kind) ? <Scene029 s={s as unknown as Scene029Def} w={w} h={h} t={t} p={p} />   // 029 scenes (src/glass029.tsx)
      : <CafeSceneView s={s as unknown as CafeScene} w={w} h={h} t={t} p={p} />;   // 031 scenes (src/cafe031.tsx)
  }
};
const hms = (n: number) => { const x = Math.floor(n); return `${Math.floor(x / 3600)}:${String(Math.floor((x % 3600) / 60)).padStart(2, "0")}:${String(x % 60).padStart(2, "0")}`; };

export const GlassCard: React.FC<{ d: GlassDef }> = ({ d }) => {
  const t = useT();
  const p = d.pal ?? PAL;
  if (t < d.from || t > d.to) return null;
  let i = 0;
  while (i + 1 < d.states.length && d.states[i + 1].at <= t) i++;
  const cur = d.states[i], prev = d.states[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.6, IO);                       // the card morphs size + place, no overshoot
  const out = i === 0 ? 1 : r(t, cur.at, cur.at + 0.24, IN);                     // old content blurs away first
  const inK = i === 0 ? r(t, d.from, d.from + 0.5) : r(t, cur.at + 0.2, cur.at + 0.7);
  const enter = r(t, d.from, d.from + 0.6), exit = r(t, d.to - 0.35, d.to, IN);
  const x = lerp(prev.x, cur.x, k), y = lerp(prev.y, cur.y, k), w = lerp(prev.w, cur.w, k), h = lerp(prev.h, cur.h, k);
  const sc = lerp(prev.scale ?? 1, cur.scale ?? 1, k);
  const glow = p.glow[i % p.glow.length], glowPrev = p.glow[Math.max(0, i - 1) % p.glow.length];
  const rad = Math.min(36, h / 2);
  return (
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${sc * (0.94 + 0.06 * enter)}) translateY(${(1 - enter) * 20 + Math.sin(t * 0.9) * 3}px)`,
      filter: enter < 0.99 ? `blur(${(1 - enter) * 10}px)` : undefined }}>
      {/* coloured glow under the card, drifting hue per scene */}
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: rad, filter: "blur(34px)", opacity: 0.55,
        background: `linear-gradient(90deg, ${glowPrev}, ${glow})` }} />
      {/* gradient rim + white glass face */}
      <div style={{ position: "absolute", inset: 0, borderRadius: rad, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${p.a}55 45%, ${p.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${p.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: rad - 2, overflow: "hidden",
          background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          {i > 0 && out < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - out, transform: `translateY(${-out * 16}px)`, filter: `blur(${out * 8}px)` }}>
            <Scene s={prev.scene} w={w} h={h} t={t} p={p} /></div>}
          <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `translateY(${(1 - inK) * 16}px)`, filter: inK < 0.99 ? `blur(${(1 - inK) * 8}px)` : undefined }}>
            <Scene s={cur.scene} w={w} h={h} t={t} p={p} /></div>
        </div>
      </div>
    </div>
  );
};

// ---------------- the real screen recording in a phone frame (026): never cropped, morphs between a small spot in the card
// and a big centred view over a dimmed backdrop. Each state plays the recording at 1x from `src` (seconds in the recording).
export type PState = { at: number; x: number; y: number; h: number; src: number; show?: boolean };
export type PhoneDef = { video: string; aspect: number; states: PState[]; to: number };
export const PhoneShot: React.FC<{ d: PhoneDef; pal?: Pal }> = ({ d, pal = PAL }) => {
  const t = useT();
  const { fps } = useVideoConfig();
  if (t > d.to + 0.5) return null;
  let i = 0;
  while (i + 1 < d.states.length && d.states[i + 1].at <= t) i++;
  const cur = d.states[i], prev = d.states[Math.max(0, i - 1)];
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.6, IO);
  const vis = (s: PState) => (s.show === false ? 0 : 1);
  const show = lerp(vis(prev), vis(cur), i === 0 ? 1 : r(t, cur.at, cur.at + 0.45, IO)) * (1 - r(t, d.to - 0.35, d.to, IN));
  if (show <= 0.001) return null;
  // a hidden state keeps the previous rect (the phone fades in place)
  const R = (s: PState, o: PState) => (s.show === false ? o : s);
  const a = R(prev, cur), b = R(cur, prev);
  const x = lerp(a.x, b.x, k), y = lerp(a.y, b.y, k), h = lerp(a.h, b.h, k), w = h / d.aspect;
  const big = Math.min(1, Math.max(0, (h - 500) / 600));
  const bez = Math.max(4, h * 0.008), rad = w * 0.12;
  // the clip that plays: the latest visible state at or before t
  let vi = i;
  while (vi > 0 && d.states[vi].show === false) vi--;
  return <>
    <div style={{ position: "absolute", inset: 0, opacity: big * show, background: `radial-gradient(120% 80% at 50% 40%, ${pal.ink}C8 0%, ${pal.ink}F0 100%)` }} />
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, borderRadius: rad, padding: bez, boxSizing: "border-box", background: "#0B1220",
      opacity: show, transform: `translateY(${Math.sin(t * 0.9) * 3 * (1 - big)}px) scale(${0.96 + 0.04 * show})`, boxShadow: `0 40px 80px -24px ${pal.a}88, 0 16px 34px -12px rgba(2,6,23,0.55)` }}>
      <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: rad - bez, overflow: "hidden", background: "#E8EEF2" }}>
        {d.states.map((s, j) => s.show === false ? null : (
          <Sequence key={j} from={Math.round(s.at * fps) - (j === 0 ? 0 : 0)} durationInFrames={Math.max(1, Math.round(((d.states.slice(j + 1).find((n) => n.show !== false)?.at ?? d.to + 0.5) - s.at) * fps))} layout="none">
            {vi === j && <OffthreadVideo src={staticFile(d.video)} muted startFrom={Math.round(s.src * fps)} style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} />}
          </Sequence>))}
      </div>
    </div>
  </>;
};

// ---------------- big word behind the head (gradient Inter, rises out of a blur) ----------------
export type GBig = { from: number; to: number; at: number; text: string; size: number; y: number; gold?: boolean; fill?: string };
export const GlassBehind: React.FC<{ items: GBig[]; pal?: Pal }> = ({ items, pal = PAL }) => {
  const t = useT();
  return <>{items.map((b, i) => {
    if (t < b.at - 0.05 || t > b.to) return null;
    const k = r(t, b.at, b.at + 0.7), ex = r(t, b.to - 0.35, b.to, IN);
    return <div key={i} style={{ position: "absolute", left: 0, width: 1080, top: b.y, textAlign: "center", fontFamily: UI, fontWeight: 800, fontSize: b.size,
      letterSpacing: -b.size * 0.045, lineHeight: 1, opacity: k * (1 - ex), transform: `translateY(${(1 - k) * 60 - ex * 20}px) scale(${1.04 - 0.04 * k})`,
      filter: k < 0.99 || ex > 0 ? `blur(${(1 - k) * 14 + ex * 10}px)` : undefined }}>
      <span style={{ ...gradText(b.fill ? b.fill : b.gold ? GOLD(pal) : `linear-gradient(180deg, #FFFFFF 0%, ${pal.gold} 120%)`),
        filter: `drop-shadow(0 6px 18px ${pal.a}88)` }}>{b.text}</span>
    </div>;
  })}</>;
};

// ---------------- captions: words land as spoken, a gradient pill glides from word to word ----------------
// x/width per word are measured offline with the real Inter 800 (plan script), so lines are fixed (no re-centring jitter)
export type GWord = { w: string; s: number; e: number; x: number; wd: number; key?: boolean };
export type GlideDef = { chunks: { from: number; to: number; y: number; words: GWord[] }[]; size: number };
export const GlideCaptions: React.FC<{ d: GlideDef; pal?: Pal }> = ({ d, pal = PAL }) => {
  const t = useT();
  const c = d.chunks.find((x) => t >= x.from && t < x.to);
  if (!c) return null;
  const PAD = 16, H = d.size * 1.28;
  // active word = last word already started; the pill moves to it over 0.14 s
  let ai = -1;
  c.words.forEach((w, i) => { if (t >= w.s - 0.03) ai = i; });
  const a = c.words[Math.max(0, ai)], pv = c.words[Math.max(0, ai - 1)];
  const mk = ai <= 0 ? 1 : r(t, a.s - 0.03, a.s + 0.11, IO);
  const px = lerp(pv.x, a.x, mk) - PAD, pw = lerp(pv.wd, a.wd, mk) + PAD * 2;
  const pin = r(t, c.words[0].s - 0.03, c.words[0].s + 0.15);
  const keyK = a.key ? mk : pv.key && ai > 0 ? 1 - mk : 0;
  return <div style={{ position: "absolute", left: 0, top: c.y, width: 1080, height: H }}>
    {ai >= 0 && <div style={{ position: "absolute", left: px, top: 2, width: pw, height: H - 4, borderRadius: 18, opacity: pin,
      boxShadow: `0 10px 24px -8px ${pal.a}AA` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: G(pal) }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: GOLD(pal), opacity: keyK }} />
    </div>}
    {c.words.map((w, i) => {
      const on = t >= w.s - 0.03;
      const k = r(t, w.s - 0.03, w.s + 0.22);
      const onPill = i === ai;
      return <span key={i} style={{ position: "absolute", left: w.x, top: 0, height: H, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800,
        fontSize: d.size, letterSpacing: 0, whiteSpace: "nowrap", color: onPill && w.key && mk > 0.5 ? pal.ink : "#FFFFFF", opacity: on ? k : 0,
        transform: `translateY(${(1 - k) * 10}px)`, textShadow: onPill ? "none" : "0 2px 2px rgba(0,0,0,0.35), 0 6px 20px rgba(0,0,0,0.45)" }}>{w.w}</span>;
    })}
  </div>;
};
