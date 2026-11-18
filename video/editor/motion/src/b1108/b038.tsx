import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";

// Video 038 "Before you vibe code any app, ask one question" (QUIET variant, kit12b Brain pattern).
// ONE card at the top that fills toward the payoff: search box "Does this already exist?" -> 10 app tiles, 9 light up "9/10
// exist" -> "Skip it? Absolutely not." -> HubSpot (real sprocket mark) vs Our CRM -> 3-step plan -> "Hire a vibe coder, fraction of
// the cost". Layers cross-fade with a soft blur; the card height glides to fit each state.
// Scene = unused (no kit11 glass scenes on a quiet day). Card = props.b1108 = { id: "038", d: Def }.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };
// Simple Icons "hubspot" (same path as src/yt00/logos.ts), brand orange
const HUBSPOT = "M18.164 7.93V5.084a2.198 2.198 0 001.267-1.978v-.067A2.2 2.2 0 0017.238.845h-.067a2.2 2.2 0 00-2.193 2.193v.067a2.196 2.196 0 001.252 1.973l.013.006v2.852a6.22 6.22 0 00-2.969 1.31l.012-.01-7.828-6.095A2.497 2.497 0 104.3 4.656l-.012.006 7.697 5.991a6.176 6.176 0 00-1.038 3.446c0 1.343.425 2.588 1.147 3.607l-.013-.02-2.342 2.343a1.968 1.968 0 00-.58-.095h-.002a2.033 2.033 0 102.033 2.033 1.978 1.978 0 00-.1-.595l.005.014 2.317-2.317a6.247 6.247 0 104.782-11.134l-.036-.005zm-.964 9.378a3.206 3.206 0 113.215-3.207v.002a3.206 3.206 0 01-3.207 3.207z";
const ORANGE = "#FF7A59", GREEN = "#16A34A", RED = "#E5484D", GREY = "#CBD2DE";

type At = { text: string; at: number };
export type Def = { from: number; to: number; x: number; y: number; w: number; scale: number;
  q: string; typeAt: number; typeEnd: number;            // the question types into the search box (already typed at frame 0 if typeAt < 0)
  nineAt: number; nineEnd: number;                        // 9 of 10 tiles light up, counter runs 0 -> 9
  skipAt: number; noAt: number;                           // "Skip it?" -> "Absolutely not"
  cmpAt: number; hubAt: number; needAt: number; dontAt: number; ownAt: number; madeAt: number;
  planAt: number; steps: At[]; hireAt: number; costAt: number;
  heights: { at: number; h: number }[] };

const Check: React.FC<{ c: string; ok: boolean; s?: number }> = ({ c, ok, s = 30 }) =>
  <div style={{ width: s, height: s, borderRadius: s * 0.3, background: c, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
    <svg width={s * 0.66} height={s * 0.66} viewBox="0 0 24 24">{ok
      ? <path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" />
      : <path d="M7 7l10 10M17 7L7 17" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" />}</svg></div>;

const CardImpl: React.FC<{ d: Def; pal: Pal }> = ({ d, pal }) => {
  const f = useCurrentFrame(); const { fps } = useVideoConfig(); const t = f / fps;
  if (t < d.from || t > d.to) return null;
  const P = 36, HEAD = 78, IW = d.w - P * 2;
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  const CH = d.heights.reduce((h, s, i) => (i === 0 ? s.h : lerp(h, s.h, r(t, s.at, s.at + 0.5, IO))), d.heights[0].h);
  const modes = [d.from, d.cmpAt - 0.1, d.planAt - 0.1];
  const vis = (i: number) => {
    const a = modes[i], b = i + 1 < modes.length ? modes[i + 1] : 1e9;
    return Math.min(i === 0 ? 1 : r(t, a, a + 0.4, IO), 1 - r(t, b, b + 0.3, IN));
  };
  const layer = (i: number, node: React.ReactNode) => {
    const v = vis(i);
    if (v <= 0.001) return null;
    return <div key={i} style={{ position: "absolute", inset: 0, opacity: v, transform: `translateY(${(1 - v) * 12}px)`, filter: v < 0.99 ? `blur(${(1 - v) * 8}px)` : undefined }}>{node}</div>;
  };
  const header = (left: React.ReactNode, right: React.ReactNode, dot = pal.gold) => <>
    <div style={{ position: "absolute", left: P, right: P, top: 0, height: HEAD, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, ...LABEL, fontSize: 24, color: pal.ink }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: dot, boxShadow: `0 0 0 5px ${dot}44` }} />{left}</div>
      {right}
    </div>
    <div style={{ position: "absolute", left: P, right: P, top: HEAD - 2, borderTop: "2.5px dashed #D9DEE8" }} />
  </>;
  const grad = { background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" } as const;

  // ---------- 0: search -> 9/10 exist -> skip? No ----------
  const nType = d.typeAt < 0 ? d.q.length : Math.round(lerp(0, d.q.length, r(t, d.typeAt, d.typeEnd, Easing.linear)));
  const caret = Math.floor(t * 2.2) % 2 === 0;
  const SB_Y = HEAD + 24, SB_H = 84;
  const search = <div style={{ position: "absolute", left: P, top: SB_Y, width: IW, height: SB_H, borderRadius: 42, boxSizing: "border-box", padding: "0 30px",
    display: "flex", alignItems: "center", gap: 20, background: "#FFFFFF", border: `2.5px solid ${pal.a}66`, boxShadow: `0 10px 24px -14px ${pal.b}88` }}>
    <svg width={38} height={38} viewBox="0 0 24 24" style={{ flexShrink: 0 }}><circle cx={10.5} cy={10.5} r={6.5} fill="none" stroke={pal.b} strokeWidth={2.8} />
      <path d="M15.5 15.5L21 21" stroke={pal.b} strokeWidth={2.8} strokeLinecap="round" /></svg>
    <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 42, color: pal.ink, whiteSpace: "nowrap" }}>{d.q.slice(0, nType)}</span>
    <div style={{ width: 3, height: 42, marginLeft: -16, background: pal.b, opacity: caret ? 1 : 0 }} />
  </div>;
  const TILE_Y = SB_Y + SB_H + 28, TG = 14, TS = (IW - TG * 9) / 10;
  const lit = (i: number) => r(t, d.nineAt + i * ((d.nineEnd - d.nineAt) / 9), d.nineAt + i * ((d.nineEnd - d.nineAt) / 9) + 0.3);
  const tilesIn = r(t, d.nineAt - 0.35, d.nineAt + 0.05);
  const tiles = Array.from({ length: 10 }, (_, i) => {
    const k = i < 9 ? lit(i) : 0, tenth = i === 9 ? r(t, d.nineEnd, d.nineEnd + 0.4) : 0;
    return <div key={i} style={{ position: "absolute", left: P + i * (TS + TG), top: TILE_Y, width: TS, height: TS, borderRadius: 18, boxSizing: "border-box",
      background: k > 0.5 ? `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)` : "#F1F4F9",
      border: i === 9 ? `2.5px dashed ${tenth > 0.5 ? pal.gold2 : GREY}` : `2px solid ${k > 0.5 ? "transparent" : "#E3E8F0"}`,
      display: "flex", alignItems: "center", justifyContent: "center", opacity: tilesIn,
      transform: `translateY(${(1 - tilesIn) * 12}px) scale(${1 + 0.12 * Math.sin(Math.PI * k)})` }}>
      {i < 9 && k > 0.5 && <svg width={34} height={34} viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" /></svg>}
      {i === 9 && <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: tenth > 0.5 ? pal.gold2 : "#A7B0BF" }}>?</span>}
    </div>;
  });
  const n9 = Math.round(lerp(0, 9, r(t, d.nineAt, d.nineEnd + 0.3, Easing.linear)));
  const ROW_Y = TILE_Y + TS + 24;
  const ck = r(t, d.nineAt - 0.1, d.nineAt + 0.3);
  const counter = <div style={{ position: "absolute", left: P, top: ROW_Y, height: 72, display: "flex", alignItems: "center", gap: 16, opacity: ck,
    transform: `translateY(${(1 - ck) * 10}px)` }}>
    {/* fixed-width number box so "0/10" -> "9/10" never shifts the label */}
    <span style={{ width: 150, fontFamily: UI, fontWeight: 800, fontSize: 64, letterSpacing: -2, fontVariantNumeric: "tabular-nums", ...grad }}>{n9}/10</span>
    <span style={{ ...LABEL, fontSize: 24, color: pal.mute }}>exist</span>
  </div>;
  const sk = r(t, d.skipAt, d.skipAt + 0.4), nk = r(t, d.noAt, d.noAt + 0.35);
  const skip = <div style={{ position: "absolute", right: P, top: ROW_Y + 8, height: 56, display: "flex", alignItems: "center", gap: 14, opacity: sk,
    transform: `translateX(${(1 - sk) * 20}px)` }}>
    <div style={{ position: "relative", height: 56, padding: "0 22px", borderRadius: 28, display: "flex", alignItems: "center", background: "#F1F4F9",
      border: "2px solid #E3E8F0", fontFamily: UI, fontWeight: 700, fontSize: 28, color: nk > 0.5 ? "#94A3B8" : pal.ink, whiteSpace: "nowrap" }}>
      Skip it?
      <div style={{ position: "absolute", left: 18, right: 18, top: 27, height: 3, background: RED, transformOrigin: "0 50%", transform: `scaleX(${nk})` }} /></div>
    <div style={{ height: 56, padding: "0 22px", borderRadius: 28, display: "flex", alignItems: "center", background: RED, color: "#fff",
      fontFamily: UI, fontWeight: 800, fontSize: 30, whiteSpace: "nowrap", opacity: nk, transform: `scale(${0.7 + 0.3 * nk})` }}>Absolutely not</div>
  </div>;
  const ask = <>
    {header(<>Before you build</>, <span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>1 simple question</span>)}
    {search}{tiles}{counter}{skip}
  </>;

  // ---------- 1: HubSpot (used first) vs Our CRM (built for how we work) ----------
  const CW = (IW - 24) / 2, COL_Y = HEAD + 24;
  const ok = r(t, d.ownAt, d.ownAt + 0.45);
  const col = (x: number, logo: React.ReactNode, name: string, tag: string, tagC: string, rows: [string, boolean, number][], k: number, on: boolean) =>
    <div style={{ position: "absolute", left: x, top: COL_Y, width: CW, height: 96 + rows.length * 68 + 8, borderRadius: 24, boxSizing: "border-box",
      background: on ? `${pal.a}12` : "#FFFFFF", border: `2px solid ${on ? pal.a + "66" : "#E6EAF1"}`, opacity: k, transform: `translateY(${(1 - k) * 14}px)` }}>
      <div style={{ position: "absolute", left: 20, top: 18, display: "flex", alignItems: "center", gap: 14 }}>
        {logo}
        <div><div style={{ fontFamily: UI, fontWeight: 800, fontSize: 32, color: pal.ink, whiteSpace: "nowrap", lineHeight: 1.1 }}>{name}</div>
          <div style={{ ...LABEL, fontSize: 17, letterSpacing: 1.6, color: tagC, marginTop: 4 }}>{tag}</div></div>
      </div>
      {rows.map(([l, good, at], i) => {
        const rk = r(t, at, at + 0.4);
        return <div key={i} style={{ position: "absolute", left: 20, top: 100 + i * 68, height: 52, display: "flex", alignItems: "center", gap: 14, opacity: rk,
          transform: `translateY(${(1 - rk) * 10}px)` }}>
          <Check c={good ? GREEN : "#94A3B8"} ok={good} />
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: good ? pal.ink : pal.mute, whiteSpace: "nowrap" }}>{l}</span></div>;
      })}
    </div>;
  const hub = <div style={{ width: 58, height: 58, borderRadius: 16, background: ORANGE, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
    <svg width={36} height={36} viewBox="0 0 24 24"><path d={HUBSPOT} fill="#fff" /></svg></div>;
  const ours = <div style={{ width: 58, height: 58, borderRadius: 16, background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, display: "flex",
    alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
    {/* generic CRM mark: a contact card */}
    <svg width={34} height={34} viewBox="0 0 24 24"><rect x={3} y={5} width={18} height={14} rx={3} fill="none" stroke="#fff" strokeWidth={2.2} />
      <circle cx={9} cy={11} r={2.2} fill="#fff" /><path d="M5.8 16.2c.7-1.6 1.9-2.4 3.2-2.4s2.5.8 3.2 2.4" stroke="#fff" strokeWidth={2} fill="none" strokeLinecap="round" />
      <path d="M14.5 10h3.5M14.5 13.5h3.5" stroke="#fff" strokeWidth={2} strokeLinecap="round" /></svg></div>;
  const cmp = <>
    {header(<>Before our CRM</>, null)}
    {col(P, hub, "HubSpot", "Used it first", ORANGE, [["What worked", true, d.needAt], ["What didn't", false, d.dontAt]], r(t, d.hubAt, d.hubAt + 0.45), false)}
    {col(P + CW + 24, ours, "Our CRM", "Built by me", pal.b, [["Only what we need", true, d.ownAt + 0.35], ["Made how we work", true, d.madeAt]], ok, true)}
  </>;

  // ---------- 2: the 3-step plan -> or hire a vibe coder ----------
  const STEP_Y = HEAD + 26, hk = r(t, d.hireAt, d.hireAt + 0.45), ck2 = r(t, d.costAt, d.costAt + 0.4);
  // when the hire row lands the steps tighten (84 -> 62 px rows) so the card stays clear of his hair
  const SG = lerp(84, 62, r(t, d.hireAt - 0.1, d.hireAt + 0.4, IO)), SF = lerp(44, 36, r(t, d.hireAt - 0.1, d.hireAt + 0.4, IO));
  const plan = <>
    {header(<>Your plan</>, <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, fontVariantNumeric: "tabular-nums", ...grad,
      opacity: r(t, d.steps[0].at, d.steps[0].at + 0.3) }}>{d.steps.filter((x) => t >= x.at).length}/3</span>)}
    {d.steps.map((x, i) => {
      const k = r(t, x.at, x.at + 0.45);
      return <div key={i} style={{ position: "absolute", left: P, right: P, top: STEP_Y + i * SG, height: Math.min(68, SG - 8), display: "flex", alignItems: "center", gap: 18,
        opacity: k, transform: `translateY(${(1 - k) * 16}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 6}px)` : undefined }}>
        <div style={{ width: 50, height: 50, borderRadius: 15, flexShrink: 0, background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, color: "#fff",
          display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 28 }}>{i + 1}</div>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: SF, color: pal.ink, whiteSpace: "nowrap", letterSpacing: -0.5 }}>{x.text}</span>
      </div>;
    })}
    <div style={{ position: "absolute", left: P, right: P, top: STEP_Y + 2 * SG + 68 + 18, height: 92, borderRadius: 24, boxSizing: "border-box", padding: "0 22px",
      display: "flex", alignItems: "center", gap: 18, background: `${pal.gold}24`, border: `2px solid ${pal.gold}`, opacity: hk, transform: `translateY(${(1 - hk) * 16}px)` }}>
      <div style={{ width: 52, height: 52, borderRadius: 15, flexShrink: 0, background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`,
        display: "flex", alignItems: "center", justifyContent: "center" }}>
        <svg width={32} height={32} viewBox="0 0 24 24"><path d="M8 7l-5 5 5 5M16 7l5 5-5 5" fill="none" stroke="#fff" strokeWidth={2.8} strokeLinecap="round" strokeLinejoin="round" /></svg></div>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 32, color: pal.ink, whiteSpace: "nowrap" }}>Or hire a vibe coder</span>
      <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 10, opacity: ck2, transform: `translateX(${(1 - ck2) * 16}px)` }}>
        {/* the full price bar shrinks to a sliver: "a fraction of the cost" */}
        <div style={{ width: 120, height: 16, borderRadius: 8, background: "#E3E8F0", position: "relative" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, borderRadius: 8, width: lerp(120, 26, r(t, d.costAt + 0.1, d.costAt + 0.9, IO)), background: pal.gold2 }} /></div>
        <span style={{ ...LABEL, fontSize: 20, letterSpacing: 1.4, color: pal.gold2, whiteSpace: "nowrap" }}>Fraction of cost</span></div>
    </div>
  </>;

  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: CH, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${d.scale * (0.96 + 0.04 * enter)})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.5,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.a}55 45%, ${pal.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          {layer(0, ask)}
          {layer(1, cmp)}
          {layer(2, plan)}
        </div>
      </div>
    </div>
  );
};

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = () => null;
export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = ({ d, pal }) => <CardImpl d={d as unknown as Def} pal={pal} />;
