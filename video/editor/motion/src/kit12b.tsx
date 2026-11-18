import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "./kit11";

// 034 "second brain" (kit12 QUIET variant): ONE card at the top from frame 0 that is the second-brain dashboard and fills up
// toward the payoff: project tiles land -> the count runs up and 3 business tabs light -> half the tiles go grey ("losing track")
// -> every tile gets a Done/Next dot -> a red "passwords found" warning slides over the tiles (values masked + blurred)
// -> a "Rules" list -> "Worth it?" with a verdict date. Same card size throughout; layers cross-fade with a soft blur (kit12 Tasks).
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };

export type BrainTile = { name: string; biz: number; at: number; lost?: boolean; status: "done" | "next" };
export type BrainDef = { from: number; to: number; x: number; y: number; w: number; h: number; scale: number; title: string;
  biz: { name: string; at: number }[]; tiles: BrainTile[]; total: number; countAt: number; lostAt: number;
  windowAt: number; doneAt: number; nextAt: number;
  warnAt: number; warnCountAt: number; leaks: string[]; file: string;
  rulesAt: number; rules: { text: string; at: number }[];
  worthAt: number; unsureAt: number; verdictAt: number; verdict: string;
  heights: { at: number; h: number }[] };   // card height glides to fit each state (fitted plate)

export const Brain: React.FC<{ d: BrainDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const P = 36, HEAD = 78, green = "#16A34A", amber = "#F59E0B", red = "#E5484D", grey = "#CBD2DE";
  const BIZ = [pal.a, pal.b, pal.gold2];
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  const CH = d.heights.reduce((h, s, i) => (i === 0 ? s.h : lerp(h, s.h, r(t, s.at, s.at + 0.5, IO))), d.h);
  const modes: [string, number][] = [["dash", d.from], ["warn", d.warnAt - 0.1], ["rules", d.rulesAt - 0.1], ["worth", d.worthAt - 0.1]];
  const vis = (i: number) => {
    const a = modes[i][1], b = i + 1 < modes.length ? modes[i + 1][1] : 1e9;
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

  // ---------- dash: business tabs + 3x4 project tiles ----------
  const cn = Math.round(lerp(0, d.total, r(t, d.countAt, d.countAt + 1.0, IO)));
  const lost = r(t, d.lostAt, d.lostAt + 0.5, IO) * (1 - r(t, d.windowAt, d.windowAt + 0.5, IO));
  const TAB_Y = HEAD + 22, TAB_H = 50, COLS = 3, GAP = 18;
  const rowK = r(t, d.biz[0].at - 0.1, d.biz[0].at + 0.4, IO), GRID_Y = TAB_Y + rowK * (TAB_H + 24);
  const TW = (d.w - P * 2 - GAP * (COLS - 1)) / COLS, TH = 56;
  const tabs = <div style={{ position: "absolute", left: P, top: TAB_Y, height: TAB_H, display: "flex", gap: 14 }}>
    {d.biz.map((b, i) => {
      const k = r(t, b.at, b.at + 0.45);
      return <div key={i} style={{ height: TAB_H, padding: "0 20px", borderRadius: 25, display: "flex", alignItems: "center", gap: 10, boxSizing: "border-box",
        background: `${BIZ[i]}1F`, border: `2px solid ${BIZ[i]}66`, opacity: k,
        transform: `translateY(${(1 - k) * 8}px)` }}>
        <div style={{ width: 12, height: 12, borderRadius: 6, background: BIZ[i] }} />
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 26, color: pal.ink, whiteSpace: "nowrap" }}>{b.name}</span>
      </div>;
    })}
  </div>;
  const tiles = d.tiles.map((tile, i) => {
    const k = r(t, tile.at, tile.at + 0.45);
    if (k <= 0) return null;
    const col = i % COLS, row = Math.floor(i / COLS);
    const gone = tile.lost ? lost : 0;
    const sk = tile.status === "done" ? r(t, d.doneAt + (i % 6) * 0.06, d.doneAt + (i % 6) * 0.06 + 0.35) : r(t, d.nextAt + (i % 6) * 0.06, d.nextAt + (i % 6) * 0.06 + 0.35);
    const dot = sk > 0.5 ? (tile.status === "done" ? green : amber) : grey;
    return <div key={i} style={{ position: "absolute", left: P + col * (TW + GAP), top: GRID_Y + row * (TH + 12), width: TW, height: TH, borderRadius: 18,
      boxSizing: "border-box", padding: "0 18px", display: "flex", alignItems: "center", gap: 14, background: "#FFFFFF",
      border: `2px solid ${sk > 0.5 ? dot + "55" : "#E6EAF1"}`, boxShadow: "0 6px 14px -10px rgba(15,23,42,0.35)",
      opacity: k * (1 - 0.6 * gone), transform: `translateY(${(1 - k) * 14}px) scale(${1 - 0.04 * gone})`, filter: gone > 0.05 ? `grayscale(${gone}) blur(${gone * 1.6}px)` : undefined }}>
      <div style={{ width: 6, height: 34, borderRadius: 3, background: BIZ[tile.biz], flexShrink: 0 }} />
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 32, color: pal.ink, whiteSpace: "nowrap" }}>{tile.name}</span>
      <div style={{ marginLeft: "auto", width: 18, height: 18, borderRadius: 9, flexShrink: 0, background: dot, transform: `scale(${1 + 0.35 * Math.sin(Math.PI * sk)})`,
        boxShadow: sk > 0.5 ? `0 0 0 5px ${dot}33` : undefined }} />
    </div>;
  });
  // legend under the header right: Done / Next counts once the dots light
  const nDone = d.tiles.filter((x) => x.status === "done").length, nNext = d.tiles.length - nDone;
  const dk = r(t, d.doneAt, d.doneAt + 0.4), nk = r(t, d.nextAt, d.nextAt + 0.4);
  const ck = r(t, d.countAt - 0.05, d.countAt + 0.35);
  const right = <div style={{ display: "flex", alignItems: "baseline", gap: 8, opacity: ck, transform: `translateY(${(1 - ck) * 8}px)` }}>
    <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, fontVariantNumeric: "tabular-nums", ...grad }}>{cn}</span>
    <span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>projects</span></div>;
  const legend = <div style={{ position: "absolute", left: P, top: TAB_Y, height: TAB_H, display: "flex", alignItems: "center", gap: 18 }}>
    {[[green, "Done", nDone, dk], [amber, "Next", nNext, nk]].map(([c, l, n, k], i) =>
      <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, opacity: k as number, transform: `translateY(${(1 - (k as number)) * 8}px)` }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: c as string }} />
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: pal.mute }}>{l as string}</span>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 28, color: pal.ink, fontVariantNumeric: "tabular-nums" }}>{n as number}</span></div>)}
  </div>;
  // "one window" moment: the tabs make room for the legend
  const tabsOut = r(t, d.doneAt - 0.3, d.doneAt + 0.1, IN);
  const dash = <>
    {header(<>{d.title}</>, right)}
    <div style={{ opacity: 1 - tabsOut, transform: `translateX(${-tabsOut * 20}px)` }}>{tabs}</div>
    {legend}
    {tiles}
  </>;

  // ---------- warn: passwords found in a notes file (values masked + blurred) ----------
  const wn = Math.max(1, Math.round(lerp(0, d.leaks.length, r(t, d.warnCountAt, d.warnCountAt + 0.6, IO))));
  const warn = <>
    {header(<>Safety check</>, <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 18px", borderRadius: 22, background: red, color: "#fff",
      fontFamily: UI, fontWeight: 800, fontSize: 26, fontVariantNumeric: "tabular-nums", opacity: r(t, d.warnCountAt, d.warnCountAt + 0.3),
      transform: `scale(${0.9 + 0.1 * r(t, d.warnCountAt, d.warnCountAt + 0.3)})` }}>
      <svg width={26} height={26} viewBox="0 0 24 24"><path d="M12 3L2 20h20L12 3z" fill="#fff" /><path d="M12 9v5" stroke={red} strokeWidth={2.6} strokeLinecap="round" /><circle cx={12} cy={17} r={1.5} fill={red} /></svg>
      {wn} {wn === 1 ? "password" : "passwords"} found</div>, red)}
    <div style={{ position: "absolute", left: P, right: P, top: HEAD + 22, height: 52, display: "flex", alignItems: "center", gap: 14 }}>
      <svg width={30} height={36} viewBox="0 0 30 36"><path d="M3 3h16l8 8v22H3z" fill="#FEE2E2" stroke={red} strokeWidth={2.4} strokeLinejoin="round" /><path d="M19 3v8h8" fill="none" stroke={red} strokeWidth={2.4} strokeLinejoin="round" /></svg>
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 30, color: pal.ink }}>{d.file}</span>
      <span style={{ ...LABEL, fontSize: 20, color: red, marginLeft: "auto" }}>Wrong file</span>
    </div>
    {d.leaks.map((l, i) => {
      const k = r(t, d.warnCountAt + i * 0.2, d.warnCountAt + i * 0.2 + 0.45);
      return <div key={i} style={{ position: "absolute", left: P, right: P, top: HEAD + 96 + i * 76, height: 62, borderRadius: 16, background: "#FEF2F2",
        border: `2px solid ${red}33`, display: "flex", alignItems: "center", gap: 18, padding: "0 22px", boxSizing: "border-box",
        opacity: k, transform: `translateX(${(1 - k) * 24}px)` }}>
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: pal.ink, width: 230 }}>{l}</span>
        {/* never real values: masked dots under a blur */}
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: "#94A3B8", letterSpacing: 5, filter: "blur(5px)" }}>{"••••••••••••••"}</span>
        <span style={{ marginLeft: "auto", ...LABEL, fontSize: 18, color: red, letterSpacing: 1.6 }}>Exposed</span>
      </div>;
    })}
  </>;

  // ---------- rules ----------
  const rules = <>
    {header(<>Rules it follows</>, <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <span style={{ padding: "6px 16px", borderRadius: 20, background: "#FEF2F2", border: "2px solid #E5484D55", fontFamily: UI, fontWeight: 800, fontSize: 24, color: "#E5484D" }}>Made mistakes</span>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, fontVariantNumeric: "tabular-nums", ...grad, opacity: r(t, d.rules[0].at, d.rules[0].at + 0.3) }}>
      {d.rules.filter((x) => t >= x.at).length}</span></div>)}
    {d.rules.map((x, i) => {
      const k = r(t, x.at, x.at + 0.45);
      return <div key={i} style={{ position: "absolute", left: P, right: P, top: HEAD + 26 + i * 84, height: 68, display: "flex", alignItems: "center", gap: 18,
        opacity: k, transform: `translateY(${(1 - k) * 16}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 6}px)` : undefined }}>
        <div style={{ width: 46, height: 46, borderRadius: 14, flexShrink: 0, background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, color: "#fff",
          display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 26 }}>{i + 1}</div>
        <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: pal.ink, whiteSpace: "nowrap" }}>{x.text}</span>
      </div>;
    })}
  </>;

  // ---------- worth it? the whole board in small + a verdict date ----------
  const vk = r(t, d.verdictAt, d.verdictAt + 0.5);
  const marks = [[`${d.total} projects in one place`, green], ["Passwords caught", green], ["Rules set", green]] as const;
  const worth = <>
    {header(<>{d.title}</>, null)}
    <div style={{ position: "absolute", left: P, top: HEAD + 18, fontFamily: UI, fontWeight: 800, fontSize: 64, letterSpacing: -2, lineHeight: 1.1, ...grad }}>Worth it?</div>
    <div style={{ position: "absolute", right: P, top: HEAD + 30, height: 56, padding: "0 22px", borderRadius: 28, display: "flex", alignItems: "center",
      background: "#FEF3C7", border: "2px solid #F59E0B88", fontFamily: UI, fontWeight: 800, fontSize: 28, color: "#B45309", whiteSpace: "nowrap",
      opacity: r(t, d.unsureAt, d.unsureAt + 0.4), transform: `translateY(${(1 - r(t, d.unsureAt, d.unsureAt + 0.4)) * 10}px)` }}>Not sure yet</div>
    {marks.map(([l, c], i) => <div key={i} style={{ position: "absolute", left: P, top: HEAD + 118 + i * 56, height: 44, display: "flex", alignItems: "center", gap: 14 }}>
      <div style={{ width: 30, height: 30, borderRadius: 9, background: c, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <svg width={20} height={20} viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" /></svg></div>
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 30, color: pal.mute, whiteSpace: "nowrap" }}>{l}</span></div>)}
    <div style={{ position: "absolute", right: P, top: HEAD + 118, width: 300, height: 156, borderRadius: 24, boxSizing: "border-box", padding: "18px 22px",
      background: `${pal.gold}24`, border: `2px solid ${pal.gold}`, opacity: vk, transform: `translateY(${(1 - vk) * 16}px)` }}>
      <div style={{ ...LABEL, fontSize: 20, color: pal.gold2 }}>Verdict</div>
      <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 44, color: pal.ink, marginTop: 8, letterSpacing: -1, whiteSpace: "nowrap" }}>{d.verdict}</div>
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
          {layer(0, dash)}
          {layer(1, warn)}
          {layer(2, rules)}
          {layer(3, worth)}
        </div>
      </div>
    </div>
  );
};
