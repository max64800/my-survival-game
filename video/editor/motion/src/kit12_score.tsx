import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { Baby, Briefcase, Building2, EyeOff, Heart, House, Lightbulb, PhoneCall, Refrigerator, Sofa, UserRound, Users, Zap } from "lucide-react";
import type { Pal } from "./kit11";

// kit12 (quiet A/B) for 032 "working from home is a trap": ONE card at the top from frame 0 that fills toward the payoff.
// modes: hook (house tile + TRAP stamp + "I love it") -> 1 in 100 dot grid (count climbs to 100) -> HOME vs OFFICE scoreboard
// (3 minuses, 3 ticks, office score 0 -> 3) -> "grow the company?" chart + couch struck -> board again, office alone: ticks fade, 3 -> 0, "Stay home".
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 24, letterSpacing: 2.4, textTransform: "uppercase" };
const ICONS = { people: Users, fridge: Refrigerator, kid: Baby, wife: Heart, eye: EyeOff, idea: Lightbulb, phone: PhoneCall, zap: Zap } as const;
type Item = { at: number; label: string; icon: keyof typeof ICONS };
export type ScoreDef = { from: number; to: number; x: number; y: number; w: number; h: number; scale: number;
  trapAt: number; loveAt: number; countIn: number; oneAt: number; hundredAt: number; prodAt: number; boardAt: number; officeAt: number; home: Item[]; office: Item[];
  askAt: number; howAt: number; growAt: number; couchAt: number; aloneAt: number; stayAt: number };

export const Score: React.FC<{ d: ScoreDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const P = 36, HEAD = 80, green = "#16A34A", red = "#E5484D", warm = pal.c;
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  const modes = [d.from, d.countIn - 0.15, d.boardAt - 0.15, d.askAt - 0.15, d.aloneAt - 0.15];
  const vis = (i: number) => {
    const a = modes[i], b = i + 1 < modes.length ? modes[i + 1] : 1e9;
    return Math.min(i === 0 ? 1 : r(t, a, a + 0.35, IO), 1 - r(t, b, b + 0.3, IN));
  };
  const layer = (i: number, node: React.ReactNode) => {
    const v = vis(i);
    if (v <= 0.001) return null;
    return <div key={i} style={{ position: "absolute", inset: 0, opacity: v, transform: `translateY(${(1 - v) * 12}px)`, filter: v < 0.99 ? `blur(${(1 - v) * 8}px)` : undefined }}>{node}</div>;
  };
  const pop = (at: number, d0 = 0.45): React.CSSProperties => {
    const k = r(t, at, at + d0);
    return { opacity: k, transform: `translateY(${(1 - k) * 16}px) scale(${0.94 + 0.06 * k})`, filter: k < 0.99 ? `blur(${(1 - k) * 6}px)` : undefined };
  };
  const header = (left: React.ReactNode, right: React.ReactNode = null) => <>
    <div style={{ position: "absolute", left: P, right: P, top: 0, height: HEAD, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, ...LABEL, color: pal.ink }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: pal.gold, boxShadow: `0 0 0 5px ${pal.gold}44` }} />{left}</div>
      {right}
    </div>
    <div style={{ position: "absolute", left: P, right: P, top: HEAD - 2, borderTop: "2.5px dashed #D9DEE8" }} />
  </>;
  const tile = (Icon: React.FC<{ size?: number; color?: string; strokeWidth?: number }>, bg: string, size = 60) =>
    <div style={{ width: size, height: size, borderRadius: size * 0.3, background: bg, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center",
      boxShadow: "0 8px 18px -10px rgba(15,23,42,0.45)" }}><Icon size={size * 0.56} color="#fff" strokeWidth={2.4} /></div>;
  const WARM = `linear-gradient(135deg, ${warm} 0%, ${pal.gold2} 100%)`, COOL = `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`;
  const BODY = d.h - HEAD;

  // ---- 0 hook: house tile + "Working from home", TRAP stamp, then a gold "I love it" chip ----
  const tk = r(t, d.trapAt, d.trapAt + 0.32, Easing.bezier(0.2, 0.9, 0.3, 1));
  const hook = <>
    {header(<>Work from home</>)}
    <div style={{ position: "absolute", left: P, top: HEAD + 40, display: "flex", alignItems: "center", gap: 26 }}>
      {tile(House, WARM, 132)}
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 76, letterSpacing: -2, color: pal.ink, lineHeight: 1.05 }}>Working<br />from home</span>
    </div>
    <div style={{ position: "absolute", left: P + 8, right: P, top: HEAD + 236, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ opacity: Math.min(1, tk * 1.5), transform: `rotate(-4deg) scale(${lerp(1.5, 1, tk)})`, padding: "8px 26px", border: `5px solid ${red}`, borderRadius: 16,
        fontFamily: UI, fontWeight: 800, fontSize: 64, letterSpacing: 4, color: red, background: "#FFF5F5" }}>TRAP</div>
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "14px 24px", borderRadius: 40, background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`,
        ...pop(d.loveAt) }}>
        <Heart size={40} color="#fff" fill="#fff" strokeWidth={2} />
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 46, color: "#fff" }}>I love it</span>
      </div>
    </div>
  </>;

  // ---- 1: 1 in 100. one gold dot on "1", the other 99 fill in and the count climbs on "100" ----
  const fill = r(t, d.hundredAt, d.hundredAt + 1.1, IO);
  const n = Math.round(lerp(1, 100, fill));
  const DOT = 26, GAP = 9, GW = 10 * DOT + 9 * GAP, GX = d.w - P - GW, GY = HEAD + (BODY - GW) / 2;
  const hundred = <>
    {header(<>In my experience</>)}
    <div style={{ position: "absolute", left: P, top: HEAD + 36, ...pop(d.oneAt) }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 14 }}>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 150, letterSpacing: -6, lineHeight: 1, background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`,
          WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" }}>1</span>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 64, color: pal.ink, letterSpacing: -2 }}>in</span>
        <span style={{ display: "inline-block", width: 130, fontFamily: UI, fontWeight: 800, fontSize: 64, color: pal.ink, letterSpacing: -2, fontVariantNumeric: "tabular-nums",
          opacity: r(t, d.hundredAt - 0.05, d.hundredAt + 0.2) }}>{n}</span>
      </div>
      <div style={{ position: "relative", height: 70, marginTop: 14 }}>
        <div style={{ position: "absolute", ...LABEL, fontSize: 26, color: pal.mute, letterSpacing: 1.6, opacity: 1 - r(t, d.prodAt - 0.1, d.prodAt + 0.2) }}>people</div>
        <div style={{ position: "absolute", fontFamily: UI, fontWeight: 800, fontSize: 36, lineHeight: 1.1, color: pal.ink, ...pop(d.prodAt) }}>more productive<br />at home</div></div>
    </div>
    {Array.from({ length: 100 }, (_, i) => {
      const k = i === 0 ? r(t, d.oneAt, d.oneAt + 0.4) : r(t, d.hundredAt + (i / 100) * 1.0, d.hundredAt + (i / 100) * 1.0 + 0.25);
      return <div key={i} style={{ position: "absolute", left: GX + (i % 10) * (DOT + GAP), top: GY + Math.floor(i / 10) * (DOT + GAP), width: DOT, height: DOT, borderRadius: DOT / 2,
        background: k > 0 ? (i === 0 ? pal.gold : "#CBD5E1") : "transparent", border: k > 0 ? undefined : "2.5px solid #E2E8F0", boxSizing: "border-box", opacity: k > 0 ? k : 1, transform: `scale(${k > 0 ? (i === 0 ? 1 + 0.25 * Math.sin(Math.PI * k) : 1) * (0.5 + 0.5 * k) : 1})`,
        boxShadow: i === 0 ? `0 0 0 5px ${pal.gold}44` : undefined }} />;
    })}
  </>;

  // ---- 2 / 4: the scoreboard. "alone" fades the office ticks (they need people) and the score counts back down ----
  const CW = (d.w - P * 2 - 24) / 2, CT = HEAD + 22, CH = d.h - CT - 26, RH = Math.min(74, (CH - 108) / Math.max(d.home.length, d.office.length));
  const al = (x: number) => r(t, d.aloneAt + 0.25 + x * 0.25, d.aloneAt + 0.6 + x * 0.25, IO);
  const board = (alone: boolean) => {
    const got = d.office.filter((o) => t >= o.at + 0.1).length;
    const lost = alone ? d.office.reduce((acc, _, i) => acc + al(i), 0) : 0;
    const score = Math.round(got - lost);
    const sk = alone ? r(t, d.stayAt, d.stayAt + 0.4, Easing.bezier(0.2, 0.9, 0.3, 1)) : 0;
    const col = (home: boolean) => {
      const items = home ? d.home : d.office;
      const bg = home ? "#FFF4EE" : "#EEF8FA", line = home ? `${warm}55` : `${pal.a}55`;
      return <div style={{ position: "absolute", left: home ? P : P + CW + 24, top: CT, width: CW, height: CH, borderRadius: 26, background: bg, border: `2px solid ${line}`,
        boxSizing: "border-box", overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 22, right: 22, top: 16, height: 66, display: "flex", alignItems: "center", gap: 14 }}>
          {tile(home ? House : alone ? UserRound : Building2, home ? WARM : COOL, 50)}
          <span style={{ ...LABEL, fontSize: 28, color: pal.ink }}>{home ? "Home" : alone ? "Alone" : "Office"}</span>
          {!home && <span style={{ marginLeft: "auto", width: 44, textAlign: "right", fontFamily: UI, fontWeight: 800, fontSize: 52, letterSpacing: -2,
            fontVariantNumeric: "tabular-nums", color: score > 0 ? green : pal.mute }}>{score}</span>}
          {home && <span style={{ marginLeft: "auto", width: 44, textAlign: "right", fontFamily: UI, fontWeight: 800, fontSize: 52, letterSpacing: -2, color: pal.mute }}>0</span>}
        </div>
        {items.map((it, i) => {
          const Icon = ICONS[it.icon];
          const f = home ? 0 : alone ? al(i) : 0;
          return <div key={i} style={{ position: "absolute", left: 22, right: 22, top: 98 + i * RH, height: RH, display: "flex", alignItems: "center", gap: 16,
            ...(alone ? {} : pop(it.at)) }}>
            {tile(Icon, home ? `linear-gradient(135deg, ${red} 0%, ${warm} 100%)` : f > 0.5 ? "#CBD5E1" : `linear-gradient(135deg, ${green} 0%, ${pal.a} 100%)`, RH - 22)}
            <span style={{ position: "relative", fontFamily: UI, fontWeight: 700, fontSize: 34, color: f > 0.5 ? "#94A3B8" : pal.ink, whiteSpace: "nowrap" }}>{it.label}
              {f > 0 && <span style={{ position: "absolute", left: -4, right: -4, top: "54%", height: 3, borderRadius: 2, background: "#94A3B8", transformOrigin: "0 50%",
                transform: `scaleX(${f})` }} />}</span>
          </div>;
        })}
      </div>;
    };
    return <>
      {header(<>{alone ? "If you're alone" : "Home vs office"}</>)}
      {col(true)}<div style={{ position: "absolute", inset: 0, ...(alone ? {} : pop(d.officeAt)) }}>{col(false)}</div>
      {alone && sk > 0 && <div style={{ position: "absolute", right: P, top: HEAD / 2, transform: `translateY(-50%) scale(${lerp(1.4, 1, sk)})`, transformOrigin: "100% 50%",
        opacity: Math.min(1, sk * 1.5), padding: "6px 22px", borderRadius: 18, background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`,
        fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#fff", whiteSpace: "nowrap", boxShadow: `0 12px 28px -12px ${pal.gold2}AA` }}>Home wins</div>}
    </>;
  };

  // ---- 3: the one question. chart line draws on "grow", then "my couch" lands and gets struck ----
  const gk = r(t, d.growAt - 0.1, d.growAt + 0.9, IO), ck = r(t, d.couchAt, d.couchAt + 0.45);
  const strike = r(t, d.couchAt + 0.35, d.couchAt + 0.75, IO);
  const CHX = d.w - P - 300, CHY = HEAD + 34, CHW = 300, CHH = 170;
  const pts = [[0, 150], [60, 128], [120, 132], [180, 90], [240, 70], [300, 20]];
  const path = pts.map((p, i) => `${i ? "L" : "M"}${p[0]},${p[1]}`).join(" ");
  const question = <>
    {header(<>Business owner</>)}
    <div style={{ position: "absolute", left: P, top: HEAD + 34, width: d.w - P * 2 - CHW - 30 }}>
      <div style={{ ...LABEL, fontSize: 24, color: pal.mute, letterSpacing: 1.6, ...pop(d.askAt) }}>My one question</div>
      <div style={{ position: "absolute", left: 0, top: 50, display: "flex", alignItems: "center", gap: 20, ...pop(d.askAt), opacity: r(t, d.askAt, d.askAt + 0.45) * (1 - r(t, d.howAt - 0.15, d.howAt + 0.15)) }}>
        {tile(Briefcase, COOL, 84)}<span style={{ fontFamily: UI, fontWeight: 800, fontSize: 48, letterSpacing: -1.5, lineHeight: 1.1, color: pal.ink }}>Ex-business<br />owner</span></div>
      <div style={{ ...pop(d.howAt), fontFamily: UI, fontWeight: 800, fontSize: 52, letterSpacing: -1.5, lineHeight: 1.1, color: pal.ink, marginTop: 10 }}>How can I grow the company?</div>
    </div>
    <div style={{ position: "absolute", left: CHX, top: CHY, width: CHW, height: CHH, opacity: r(t, d.askAt, d.askAt + 0.4) }}>
      <svg width={CHW} height={CHH} viewBox={`0 0 ${CHW} ${CHH}`} style={{ overflow: "visible" }}>
        {[40, 90, 140].map((y) => <line key={y} x1={0} x2={CHW} y1={y} y2={y} stroke="#E2E8F0" strokeWidth={2} />)}
        <path d={path} fill="none" stroke={green} strokeWidth={7} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - gk} />
      </svg>
    </div>
    <div style={{ position: "absolute", left: P, top: d.h - 26 - 84, display: "flex", alignItems: "center", gap: 18, opacity: ck, transform: `translateY(${(1 - ck) * 16}px)` }}>
      {tile(Sofa, `linear-gradient(135deg, ${warm} 0%, ${pal.gold2} 100%)`, 64)}
      <span style={{ position: "relative", fontFamily: UI, fontWeight: 800, fontSize: 46, color: strike > 0.5 ? "#94A3B8" : pal.ink }}>My couch
        <span style={{ position: "absolute", left: -6, right: -6, top: "54%", height: 4, borderRadius: 2, background: red, transformOrigin: "0 50%", transform: `scaleX(${strike})` }} /></span>
      <span style={{ padding: "8px 20px", borderRadius: 22, background: red, color: "#fff", fontFamily: UI, fontWeight: 800, fontSize: 30, opacity: strike,
        marginLeft: 8 }}>Rarely</span>
    </div>
  </>;

  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: d.h, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${d.scale * (0.96 + 0.04 * enter)})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.5,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.a}55 45%, ${pal.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          {layer(0, hook)}
          {layer(1, hundred)}
          {layer(2, board(false))}
          {layer(3, question)}
          {layer(4, board(true))}
        </div>
      </div>
    </div>
  );
};
