import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "../kit11";

// Video 040 "Our whole company runs on Telegram, not Slack" (Nov 8 batch, QUIET variant). Owned by the 040 edit only.
// ONE card at the top from frame 0 that becomes the company's Telegram chat and fills up toward the payoff:
// Slack (struck) -> Telegram -> open API: our tools plug in -> bot messages land (new lead; a voice note from the car -> CRM updated),
// each ticks "Done" in the header -> "$0 / month" price tag on "free" -> a Telegram poll "What does your team use?". All data is generic; names/phones/amounts are masked + blurred.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };

export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = () => null;

// faithful simple marks (Simple Icons paths)
const TG_BLUE = "#26A5E4";
const TG = "M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z";
const Telegram: React.FC<{ size: number }> = ({ size }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ flexShrink: 0 }}><circle cx={12} cy={12} r={11.4} fill="#fff" /><path d={TG} fill={TG_BLUE} /></svg>);
// Slack mark: 4 colour pairs (pink, blue, green, yellow)
const SLACK: [string, string][] = [
  ["#E01E5A", "M5.042 15.165a2.528 2.528 0 0 1-2.52 2.523A2.528 2.528 0 0 1 0 15.165a2.527 2.527 0 0 1 2.522-2.52h2.52v2.52zM6.313 15.165a2.527 2.527 0 0 1 2.521-2.52 2.527 2.527 0 0 1 2.521 2.52v6.313A2.528 2.528 0 0 1 8.834 24a2.528 2.528 0 0 1-2.521-2.522v-6.313z"],
  ["#36C5F0", "M8.834 5.042a2.528 2.528 0 0 1-2.521-2.52A2.528 2.528 0 0 1 8.834 0a2.528 2.528 0 0 1 2.521 2.522v2.52H8.834zM8.834 6.313a2.528 2.528 0 0 1 2.521 2.521 2.528 2.528 0 0 1-2.521 2.521H2.522A2.528 2.528 0 0 1 0 8.834a2.528 2.528 0 0 1 2.522-2.521h6.312z"],
  ["#2EB67D", "M18.956 8.834a2.528 2.528 0 0 1 2.522-2.521A2.528 2.528 0 0 1 24 8.834a2.528 2.528 0 0 1-2.522 2.521h-2.522V8.834zM17.688 8.834a2.528 2.528 0 0 1-2.523 2.521 2.527 2.527 0 0 1-2.52-2.521V2.522A2.527 2.527 0 0 1 15.165 0a2.528 2.528 0 0 1 2.523 2.522v6.312z"],
  ["#ECB22E", "M15.165 18.956a2.528 2.528 0 0 1 2.523 2.522A2.528 2.528 0 0 1 15.165 24a2.527 2.527 0 0 1-2.52-2.522v-2.522h2.52zM15.165 17.688a2.527 2.527 0 0 1-2.52-2.523 2.526 2.526 0 0 1 2.52-2.52h6.313A2.527 2.527 0 0 1 24 15.165a2.528 2.528 0 0 1-2.522 2.523h-6.313z"],
];
const Slack: React.FC<{ size: number; grey?: number }> = ({ size, grey = 0 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ flexShrink: 0, filter: grey > 0 ? `grayscale(${grey})` : undefined, opacity: 1 - 0.45 * grey }}>
    {SLACK.map(([c, d], i) => <path key={i} d={d} fill={c} />)}</svg>);
const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.3 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ flexShrink: 0 }}><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  house: "M3 11l9-7 9 7M5 9.5V20h14V9.5M10 20v-5h4v5",
  doc: "M7 3h7l4 4v14H7zM14 3v4h4M10 12h5M10 16h5",
  crm: "M4 5h16v14H4zM4 10h16M9 10v9",
  check: "M5 12.5l4.5 4.5L19 7.5",
  car: "M5 16h14M6.5 16l1.5-5h8l1.5 5M5 16v3h2.5v-2M19 16v3h-2.5v-2M8 13.5h0M16 13.5h0",
  bot: "M6 9h12v9H6zM12 5v4M9.5 13h0M14.5 13h0M4 13v2M20 13v2",
  arrow: "M4 12h15M14 7l5 5-5 5",
  globe: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.6 3.6 5.6 3.6 9s-1.1 6.4-3.6 9c-2.5-2.6-3.6-5.6-3.6-9S9.5 5.6 12 3z",
  chat: "M4 5h16v11H9l-5 4z",
  ads: "M4 10v4l12 5V5L4 10zM16 9.5c2 .5 2 4.5 0 5M7 14l1.5 5h3L10 15",
};

type Msg = { kind: "lead" | "out" | "crm" | "bill" | "poll"; at: number; done?: number; sent?: number };
export type TgDef = { from: number; to: number; x: number; y: number; w: number; h: number; scale: number;
  notAt: number; apiAt: number; tools: { name: string; icon: keyof typeof I; at: number }[];
  chatAt: number; msgs: Msg[]; freeAt: number; howAt: number; heights: { at: number; h: number }[] };

const MSG_H: Record<Msg["kind"], number> = { lead: 206, out: 120, crm: 132, bill: 64, poll: 214 };
const GAP = 18;

export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = ({ d: raw, pal }) => {
  const d = raw as unknown as TgDef;
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const P = 32, HEAD = 100, green = "#16A34A", red = "#E5484D";
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  const CH = d.heights.reduce((h, s, i) => (i === 0 ? s.h : lerp(h, s.h, r(t, s.at, s.at + 0.5, IO))), d.h);
  const chatK = r(t, d.chatAt - 0.1, d.chatAt + 0.4, IO);
  const apiK = r(t, d.apiAt - 0.1, d.apiAt + 0.5, IO);
  const dones = d.msgs.filter((m) => m.done !== undefined).map((m) => m.done as number);
  const nDone = dones.filter((x) => t >= x).length;
  const freeK = r(t, d.freeAt, d.freeAt + 0.45);
  const howK = r(t, d.howAt, d.howAt + 0.4);

  // ---------- header: the group chat ----------
  const slackOut = r(t, d.apiAt - 0.1, d.apiAt + 0.3, IN);
  const doneIn = r(t, d.chatAt, d.chatAt + 0.4) * (1 - r(t, d.freeAt - 0.1, d.freeAt + 0.2, IN));
  const header = <>
    <div style={{ position: "absolute", left: P, top: 0, height: HEAD, display: "flex", alignItems: "center", gap: 18 }}>
      <Telegram size={60} />
      <div>
        <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 32, color: pal.ink, letterSpacing: -0.5, whiteSpace: "nowrap" }}>Company HQ</div>
        <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 22, color: TG_BLUE, whiteSpace: "nowrap", marginTop: 2 }}>Telegram · our own bots</div>
      </div>
    </div>
    {/* right slot (absolute, right-aligned so changing content never jitters) */}
    <div style={{ position: "absolute", right: P, top: 22, height: 56, display: "flex", alignItems: "center", gap: 12, padding: "0 20px", borderRadius: 28,
      background: "#FEF2F2", border: `2px solid ${red}44`, opacity: r(t, d.notAt - 0.05, d.notAt + 0.3) * (1 - slackOut) }}>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 24, color: red }}>Not</span>
      <Slack size={30} />
      <span style={{ position: "relative", fontFamily: UI, fontWeight: 800, fontSize: 26, color: pal.ink }}>Slack
        <span style={{ position: "absolute", left: -4, right: -4, top: "52%", height: 4, borderRadius: 2, background: red,
          transform: `scaleX(${r(t, d.notAt + 0.1, d.notAt + 0.45, IO)})`, transformOrigin: "0 50%" }} /></span>
    </div>
    <div style={{ position: "absolute", right: P, top: 22, height: 56, display: "flex", alignItems: "center", gap: 12, opacity: doneIn }}>
      <span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>Done</span>
      {dones.map((at, i) => {
        const k = r(t, at, at + 0.35);
        return <div key={i} style={{ width: 38, height: 38, borderRadius: 19, boxSizing: "border-box", display: "flex", alignItems: "center", justifyContent: "center",
          background: k > 0.5 ? green : "#fff", border: `2.5px solid ${k > 0.5 ? green : "#CBD2DE"}`, transform: `scale(${1 + 0.25 * Math.sin(Math.PI * k)})` }}>
          {k > 0.5 && <Ico d={I.check} size={24} color="#fff" w={3.4} />}</div>;
      })}
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: pal.ink, width: 52, textAlign: "right", fontVariantNumeric: "tabular-nums" }}>{nDone}/{dones.length}</span>
    </div>
    <div style={{ position: "absolute", right: P, top: 18, height: 64, display: "flex", alignItems: "center", gap: 10, padding: "0 24px", borderRadius: 32,
      background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`, boxShadow: `0 10px 22px -10px ${pal.gold2}`,
      opacity: freeK, transform: `translateY(${(1 - freeK) * 10}px) scale(${0.9 + 0.1 * freeK}) rotate(${-3 * howK}deg)` }}>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: pal.ink, letterSpacing: -1 }}>$0</span>
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: pal.ink }}>/ month</span>
    </div>
    <div style={{ position: "absolute", left: P, right: P, top: HEAD - 2, borderTop: "2.5px dashed #D9DEE8" }} />
  </>;

  // ---------- hero: Slack -> Telegram, then the open API with our tools plugging in ----------
  const heroV = 1 - chatK;
  const slackK = 1 - apiK;           // Slack leaves when the API part starts
  const strike = r(t, d.notAt + 0.1, d.notAt + 0.45, IO);
  const TGX = lerp(640, 150, apiK);  // Telegram mark centre x slides left to make room for the tools
  const BODY_Y = HEAD + 26;
  const hero = heroV > 0.001 && <div style={{ position: "absolute", left: 0, right: 0, top: 0, bottom: 0, opacity: heroV,
    filter: heroV < 0.99 ? `blur(${(1 - heroV) * 8}px)` : undefined }}>
    {/* Slack, greyed + struck, slides off to the left */}
    <div style={{ position: "absolute", left: 160 - 120 * (1 - slackK), top: BODY_Y + 20, width: 220, display: "flex", flexDirection: "column", alignItems: "center", gap: 14, opacity: slackK }}>
      <div style={{ position: "relative" }}><Slack size={120} grey={strike} />
        <div style={{ position: "absolute", left: -14, right: -14, top: 56, height: 8, borderRadius: 4, background: red, transform: `rotate(-20deg) scaleX(${strike})` }} /></div>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: pal.mute }}>Slack</span>
    </div>
    <div style={{ position: "absolute", left: 418, top: BODY_Y + 46, opacity: slackK * r(t, d.notAt, d.notAt + 0.4) }}><Ico d={I.arrow} size={70} color="#94A3B8" w={2.6} /></div>
    <div style={{ position: "absolute", left: TGX - 110, top: BODY_Y + 20, width: 220, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{ borderRadius: 70, boxShadow: `0 16px 34px -12px ${TG_BLUE}`, width: 120, height: 120 }}><Telegram size={120} /></div>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: pal.ink }}>Telegram</span>
    </div>
    {/* open API: tool chips plug into the Telegram mark */}
    {d.tools.map((tool, i) => {
      const k = r(t, tool.at, tool.at + 0.5);
      const ty = BODY_Y + 8 + i * 72;
      const colors = [pal.a, pal.b, pal.gold2];
      return <React.Fragment key={i}>
        <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width={1} height={1}>
          <path d={`M ${TGX + 72} ${BODY_Y + 80} C ${TGX + 170} ${BODY_Y + 80}, ${420} ${ty + 30}, ${510} ${ty + 30}`} fill="none" stroke={colors[i]}
            strokeWidth={4} strokeLinecap="round" pathLength={1} strokeDasharray="1" strokeDashoffset={1 - k} opacity={apiK} />
        </svg>
        <div style={{ position: "absolute", left: 520, top: ty, width: 316, height: 60, borderRadius: 18, boxSizing: "border-box", padding: "0 18px",
          display: "flex", alignItems: "center", gap: 14, background: "#fff", border: `2px solid ${colors[i]}55`, boxShadow: "0 6px 14px -10px rgba(15,23,42,0.35)",
          opacity: k * apiK, transform: `translateX(${(1 - k) * 30}px)` }}>
          <div style={{ width: 38, height: 38, borderRadius: 11, background: `${colors[i]}22`, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ico d={I[tool.icon]} size={24} color={colors[i]} /></div>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 30, color: pal.ink, whiteSpace: "nowrap" }}>{tool.name}</span>
          <div style={{ marginLeft: "auto", width: 14, height: 14, borderRadius: 7, background: green, opacity: r(t, tool.at + 0.35, tool.at + 0.6) }} />
        </div>
      </React.Fragment>;
    })}
    <div style={{ position: "absolute", left: TGX - 70, top: BODY_Y + 204, height: 40, padding: "0 16px", borderRadius: 20, display: "flex", alignItems: "center",
      background: `${TG_BLUE}1F`, border: `2px solid ${TG_BLUE}66`, ...LABEL, fontSize: 20, color: "#1D7FB8", opacity: apiK * slackK < 0.5 ? apiK : 0 }}>Open API</div>
  </div>;

  // ---------- chat: bot messages stack from the bottom, older ones scroll off the top ----------
  const CHAT_TOP = HEAD, CHAT_H = CH - HEAD;
  const ks = d.msgs.map((m) => r(t, m.at, m.at + 0.5, IO));
  const bubble = (m: Msg, i: number, k: number) => {
    const doneK = m.done !== undefined ? r(t, m.done, m.done + 0.35) : 0;
    const badge = m.done !== undefined && <div style={{ position: "absolute", right: 18, top: 16, height: 40, padding: "0 16px", borderRadius: 20, display: "flex", alignItems: "center", gap: 8,
      background: green, color: "#fff", fontFamily: UI, fontWeight: 800, fontSize: 24, opacity: doneK, transform: `scale(${0.8 + 0.2 * doneK + 0.12 * Math.sin(Math.PI * doneK)})` }}>
      <Ico d={I.check} size={22} color="#fff" w={3.4} />Done</div>;
    const row = (label: string, value: string, masked = false) => <div style={{ display: "flex", alignItems: "center", gap: 16, height: 40 }}>
      <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 24, color: pal.mute, width: 110 }}>{label}</span>
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: pal.ink, filter: masked ? "blur(6px)" : undefined, letterSpacing: masked ? 2 : 0, whiteSpace: "nowrap" }}>{value}</span>
    </div>;
    const botAvatar = <div style={{ position: "absolute", left: 0, bottom: 0, width: 48, height: 48, borderRadius: 24, background: `linear-gradient(135deg, ${pal.a}, ${pal.b})`,
      display: "flex", alignItems: "center", justifyContent: "center" }}><Ico d={I.bot} size={28} color="#fff" w={2.4} /></div>;
    const card = (icon: keyof typeof I, color: string, title: string, body: React.ReactNode) => <>
      {botAvatar}
      <div style={{ position: "absolute", left: 62, right: 70, top: 0, bottom: 0, borderRadius: "22px 22px 22px 6px", background: "#fff", boxSizing: "border-box", padding: "16px 22px",
        boxShadow: "0 4px 10px -6px rgba(15,23,42,0.3)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, height: 44 }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: `${color}22`, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ico d={I[icon]} size={24} color={color} /></div>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 30, color: pal.ink, whiteSpace: "nowrap" }}>{title}</span>
        </div>
        <div style={{ marginTop: 8 }}>{body}</div>
        {badge}
      </div>
    </>;
    if (m.kind === "lead") return card("house", pal.a, "New lead · Villa enquiry", <>{row("Name", "Client name", true)}{row("Phone", "+971 50 000 0000", true)}{row("Source", "Website form")}</>);
    if (m.kind === "poll") {
      const opts: [React.ReactNode, string][] = [[<Slack size={30} />, "Slack"], [<Telegram size={30} />, "Telegram"]];
      return card("chat", TG_BLUE, "What does your team use?", <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 4 }}>
        {opts.map(([logo, name], j) => {
          const ok = r(t, m.at + 0.25 + j * 0.15, m.at + 0.65 + j * 0.15);
          return <div key={j} style={{ height: 52, borderRadius: 16, border: "2px solid #D9DEE8", display: "flex", alignItems: "center", gap: 14, padding: "0 18px",
            boxSizing: "border-box", opacity: ok, transform: `translateY(${(1 - ok) * 10}px)` }}>
            <div style={{ width: 24, height: 24, borderRadius: 12, border: "2.5px solid #94A3B8", boxSizing: "border-box" }} />{logo}
            <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: pal.ink }}>{name}</span></div>;
        })}</div>);
    }
    if (m.kind === "crm") return card("crm", green, "CRM updated", <>{row("Status", "Viewing booked")}</>);
    if (m.kind === "out") {
      // voice note: records live from `at` (driving, on a call), sent on `sent` ("voice note")
      const sk = r(t, m.sent ?? m.at, (m.sent ?? m.at) + 0.35);
      const rec = Math.min(1, Math.max(0, t - m.at) / Math.max(0.5, (m.sent ?? m.at + 1) - m.at));
      const secs = Math.min(12, Math.floor(rec * 12));
      return <div style={{ position: "absolute", right: 0, top: 0, bottom: 0, width: 600, borderRadius: "22px 22px 6px 22px", background: "#E3F6D3",
        boxSizing: "border-box", padding: "14px 22px", boxShadow: "0 4px 10px -6px rgba(15,23,42,0.3)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, height: 30 }}>
          <Ico d={I.car} size={26} color="#4D7C2F" />
          <span style={{ ...LABEL, fontSize: 18, color: "#4D7C2F", whiteSpace: "nowrap" }}>{sk > 0.5 ? "Voice note · sent" : "Driving · on a call"}</span>
          <div style={{ marginLeft: "auto", width: 14, height: 14, borderRadius: 7, background: red, opacity: (1 - sk) * (0.55 + 0.45 * Math.sin(t * 8)) }} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 16, marginTop: 10, height: 50 }}>
          <div style={{ width: 50, height: 50, borderRadius: 25, background: "#4FAE4E", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <svg width={22} height={22} viewBox="0 0 24 24"><path d="M7 4.5v15l12.5-7.5z" fill="#fff" /></svg></div>
          <svg width={380} height={44} viewBox="0 0 380 44" style={{ flexShrink: 0 }}>
            {Array.from({ length: 38 }, (_, j) => {
              const on = j / 38 < rec;
              const hgt = 8 + 30 * Math.abs(Math.sin(j * 1.7) * Math.cos(j * 0.6));
              return <rect key={j} x={j * 10} y={22 - hgt / 2} width={5} height={hgt} rx={2.5} fill={on ? "#4FAE4E" : "#B9DDA8"} />;
            })}
          </svg>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: "#4D7C2F", fontVariantNumeric: "tabular-nums", width: 52 }}>0:{String(secs).padStart(2, "0")}</span>
        </div>
      </div>;
    }
    return <div style={{ position: "absolute", left: "50%", top: 6, transform: "translateX(-50%)", height: 52, padding: "0 24px", borderRadius: 26, display: "flex", alignItems: "center", gap: 12,
      background: "rgba(15,23,42,0.55)", color: "#fff", fontFamily: UI, fontWeight: 700, fontSize: 26, whiteSpace: "nowrap" }}>Monthly bill: <span style={{ color: pal.gold, fontWeight: 800 }}>$0</span></div>;
  };
  let below = 0;
  const placed: { i: number; bottom: number; k: number }[] = [];
  for (let i = d.msgs.length - 1; i >= 0; i--) {
    if (ks[i] <= 0) continue;
    placed.push({ i, bottom: below, k: ks[i] });
    below += (MSG_H[d.msgs[i].kind] + GAP) * ks[i];
  }
  const chat = chatK > 0.001 && <div style={{ position: "absolute", left: 0, right: 0, top: CHAT_TOP, height: CHAT_H, opacity: chatK, overflow: "hidden",
    background: "linear-gradient(180deg, #E4EEF7 0%, #DCE9F3 100%)",
    WebkitMaskImage: "linear-gradient(180deg, transparent 0px, #000 36px)", maskImage: "linear-gradient(180deg, transparent 0px, #000 36px)" }}>
    {placed.map(({ i, bottom, k }) => {
      const m = d.msgs[i];
      // messages scrolling off the top fade out instead of showing a half-cut bubble
      const top = CHAT_H - 22 - bottom - MSG_H[m.kind];
      const off = interpolate(top, [-MSG_H[m.kind] * 0.35, 12], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      if (off <= 0.001) return null;
      return <div key={i} style={{ position: "absolute", left: P, right: P, bottom: 22 + bottom, height: MSG_H[m.kind], opacity: k * off,
        transform: `translateY(${(1 - k) * 24}px) scale(${0.97 + 0.03 * k})`, transformOrigin: m.kind === "out" ? "100% 100%" : "0% 100%" }}>{bubble(m, i, k)}</div>;
    })}
  </div>;

  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: CH, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${d.scale * (0.96 + 0.04 * enter)})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.5,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.a}55 45%, ${pal.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          {hero}
          {chat}
          {header}
        </div>
      </div>
    </div>
  );
};
