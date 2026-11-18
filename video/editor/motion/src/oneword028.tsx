import React from "react";
import { Easing, interpolate } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// kit11 glass-card scenes for 028 "One word" (IMG_4235). Own file so parallel kit11 work doesn't collide; kit11's Scene
// falls through to Scene028 for these kinds. One card: 3,000+ messages + scrolling chat list -> each one-word answer
// stamps onto the card with its own proof (clock, overnight list, "still not..." bubbles, toggle, please/thanks bars).
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });
type Pal = { a: string; b: string; c: string; gold: string; gold2: string; ink: string; mute: string; glow: string[] };
type Q = { q: string; qAt: number; word: string; wordAt: number };
export type Scene028Def =
  | { kind: "msgs"; label: string; count: number; countAt: number; countD: number; plusAt: number; days: string; daysAt: number; ask: string; askAt: number; askD: number }
  | ({ kind: "nocturnal"; clockAt: number; hour: string; countAt: number; count: number; countLabel: string } & Q)
  | ({ kind: "asleep"; tasks: { text: string; at: number }[]; countAt: number; count: number; quote: string } & Q)
  | ({ kind: "impatience"; msgs: { text: string; at: number }[] } & Q)
  | ({ kind: "toggle"; left: string; right: string; flipAt: number; chip: string; chipAt: number } & Q)
  | ({ kind: "polite"; lead: string; please: number; pleaseAt: number; thanks: number; thanksAt: number; plusOneAt: number } & Q);
export const KINDS_028 = ["msgs", "nocturnal", "asleep", "impatience", "toggle", "polite"];

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
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 26, letterSpacing: 2.2, textTransform: "uppercase" };
const P = 36;
const fmt = (n: number) => Math.round(n).toLocaleString("en-US");
const Ico: React.FC<{ d: string; size: number; color: string; w?: number }> = ({ d, size, color, w = 2.2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" /></svg>);
const I = {
  check: "M5 12.5l4.5 4.5L19 7.5",
  moon: "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z",
  spark: "M12 3v5M12 16v5M3 12h5M16 12h5M5.6 5.6l3.5 3.5M14.9 14.9l3.5 3.5M5.6 18.4l3.5-3.5M14.9 9.1l3.5-3.5",
  heart: "M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z",
};

// question line (small, top-left) + the one-word answer stamping onto the card (scale down + settle, no bounce)
// Small topic label ("Q1 · Life in Dubai", not the caption word for word); before the answer Claude is "Thinking" (spinning
// spark + dots) so the card never sits empty, then the one word stamps in where that was.
const Stamp: React.FC<{ s: Q; t: number; p: Pal; size?: number; gold?: boolean }> = ({ s, t, p, size = 92, gold }) => {
  const k = r(t, s.wordAt, s.wordAt + 0.32, IO);
  const sw = r(t, s.wordAt - 0.12, s.wordAt + 0.18, IO);
  return <>
    {sw < 1 && <div style={{ position: "absolute", left: P, top: 84, display: "flex", alignItems: "center", gap: 20, opacity: (1 - sw) * r(t, s.qAt, s.qAt + 0.4),
      transform: `translateY(${-sw * 20}px)`, filter: sw > 0 ? `blur(${sw * 8}px)` : undefined }}>
      <div style={{ width: 76, height: 76, borderRadius: 38, background: G(p), display: "flex", alignItems: "center", justifyContent: "center",
        transform: `rotate(${(t - s.qAt) * 90}deg)` }}><Ico d={I.spark} size={44} color="#fff" w={2.4} /></div>
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 50, letterSpacing: -1.2, color: p.ink }}>Thinking</span>
      <div style={{ display: "flex", gap: 10, marginTop: 14 }}>{[0, 1, 2].map((j) => <div key={j} style={{ width: 14, height: 14, borderRadius: 7, background: p.a,
        opacity: 0.25 + 0.75 * Math.max(0, Math.sin((t - s.qAt) * 7 - j * 0.9)) }} />)}</div>
    </div>}
    <div style={{ ...LABEL, position: "absolute", left: P, top: 30, color: p.mute, whiteSpace: "nowrap", ...rise(t, s.qAt, 0.4, 8) }}>{s.q}</div>
    {t >= s.wordAt - 0.02 && <div style={{ position: "absolute", left: P - 4, top: 70, fontFamily: UI, fontWeight: 800, fontSize: size, letterSpacing: -size * 0.04,
      lineHeight: 1, whiteSpace: "nowrap", transformOrigin: "0% 60%", opacity: k, transform: `scale(${lerp(1.35, 1, k)}) rotate(${lerp(-3, 0, k)}deg)`,
      filter: k < 0.99 ? `blur(${(1 - k) * 10}px)` : undefined, ...gradText(gold ? `linear-gradient(135deg, ${p.gold2} 0%, #D9480F 100%)` : G(p)) }}>{s.word}</div>}
  </>;
};

// a generic chat-list row: coloured avatar + two grey bars + a night-time stamp (no client names, no real text)
const ROW_H = 58;
const ChatRow: React.FC<{ i: number; w: number; p: Pal }> = ({ i, w, p }) => {
  const cols = [p.a, p.b, p.gold2, "#7C3AED", "#E11D48", "#16A34A"];
  const times = ["10:42 PM", "11:58 PM", "12:31 AM", "1:07 AM", "9:15 PM", "2:44 AM", "10:03 PM", "11:21 PM"];
  return <div style={{ height: ROW_H, display: "flex", alignItems: "center", gap: 12, padding: "0 14px", boxSizing: "border-box", borderBottom: "1.5px solid #EDF1F6" }}>
    <div style={{ width: 34, height: 34, borderRadius: 17, background: cols[i % cols.length], flexShrink: 0 }} />
    <div style={{ flex: 1 }}>
      <div style={{ width: (w - 170) * (0.55 + 0.4 * ((i * 37) % 10) / 10), height: 11, borderRadius: 6, background: "#CBD5E1" }} />
      <div style={{ width: (w - 170) * (0.4 + 0.5 * ((i * 53) % 10) / 10), height: 9, borderRadius: 5, background: "#E3E8EF", marginTop: 8 }} />
    </div>
    <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 18, color: p.mute, fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap" }}>{times[i % times.length]}</span>
  </div>;
};

export const Scene028: React.FC<{ s: Scene028Def; w: number; h: number; t: number; p: Pal }> = ({ s, w, h, t, p }) => {
  switch (s.kind) {
    case "msgs": {
      // frame 1 = the result: 3,000+ messages / 73 days, a chat list scrolling fast; then the prompt bar types the question
      const LW = 470, RW = w - P * 2 - LW - 28;
      const c = r(t, s.countAt, s.countAt + s.countD, IO);
      const n = lerp(2000, s.count, c);   // starts on a round 2,000 and rolls up (lands on the spoken number)
      const pk = r(t, s.plusAt, s.plusAt + 0.3);
      const chars = Math.round(lerp(0, s.ask.length, r(t, s.askAt, s.askAt + s.askD, (x) => x)));
      const scroll = (t + 0.6) * 260;      // fast, constant scroll
      const first = Math.floor(scroll / ROW_H);
      return <>
        <div style={{ ...LABEL, position: "absolute", left: P, top: 32, color: p.mute, display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 30, height: 30, borderRadius: 15, background: G(p), display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Ico d={I.spark} size={19} color="#fff" w={2.6} /></div>{s.label}</div>
        <div style={{ position: "absolute", left: P - 4, top: 80, fontFamily: UI, fontWeight: 800, fontSize: 112, letterSpacing: -5, lineHeight: 1,
          fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap", ...gradText(G(p)) }}>{fmt(n)}<span style={{ opacity: pk }}>+</span></div>
        <div style={{ position: "absolute", left: P, top: 204, fontFamily: UI, fontWeight: 700, fontSize: 36, color: p.ink, letterSpacing: -0.8, whiteSpace: "nowrap" }}>
          messages <span style={{ ...rise(t, s.daysAt, 0.4, 8), display: "inline-block", color: p.b }}>· {s.days}</span></div>
        {/* prompt bar typing the question */}
        <div style={{ position: "absolute", left: P, top: h - 34 - 62, width: LW, height: 62, borderRadius: 31, background: "#F1F4F8", border: `2px solid ${t >= s.askAt ? p.a : "#E3E8EF"}`,
          display: "flex", alignItems: "center", padding: "0 24px", boxSizing: "border-box", ...rise(t, s.askAt - 0.3, 0.4, 10) }}>
          <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 26, color: p.ink, whiteSpace: "nowrap" }}>{s.ask.slice(0, chars)}
            <span style={{ display: "inline-block", width: 3, height: 28, background: p.a, marginLeft: 3, verticalAlign: "middle", opacity: Math.floor(t * 3) % 2 ? 1 : 0.2 }} /></span>
        </div>
        {/* the chat list window */}
        <div style={{ position: "absolute", right: P, top: 30, width: RW, height: h - 60, borderRadius: 22, background: "#FFFFFF", border: "1.5px solid #E1E6EE",
          overflow: "hidden", boxShadow: "0 10px 22px -14px rgba(15,23,42,0.35)" }}>
          <div style={{ height: 44, background: "#F6F8FB", display: "flex", alignItems: "center", gap: 8, padding: "0 16px", borderBottom: "1.5px solid #E3E8EF" }}>
            {["#F87171", "#FBBF24", "#34D399"].map((cc) => <div key={cc} style={{ width: 12, height: 12, borderRadius: 6, background: cc }} />)}
            <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 19, color: p.mute, marginLeft: 8 }}>Chats</span></div>
          <div style={{ position: "absolute", left: 0, right: 0, top: 44, bottom: 0, overflow: "hidden" }}>
            <div style={{ transform: `translateY(${-(scroll % ROW_H)}px)` }}>
              {Array.from({ length: 8 }, (_, j) => <ChatRow key={first + j} i={first + j} w={RW} p={p} />)}
            </div>
          </div>
        </div>
      </>;
    }
    case "nocturnal": {
      // clock hand sweeps to 10, "10 PM busiest hour"; then "231 after midnight" counts up
      const ck = r(t, s.clockAt, s.clockAt + 0.8, IO);
      const ang = lerp(-60, 300, ck);           // 12 o'clock = 0 deg, 10 o'clock = 300 deg
      const cc = r(t, s.countAt, s.countAt + 0.9, IO);
      const CY = 196, CS = 132;
      return <>
        <Stamp s={s} t={t} p={p} />
        <div style={{ position: "absolute", right: P, top: 34, ...rise(t, s.wordAt, 0.4, 8) }}><Ico d={I.moon} size={64} color={p.gold2} w={2.4} /></div>
        <div style={{ position: "absolute", left: P, top: CY, width: CS, height: CS, borderRadius: CS / 2, background: "#0E2433", ...rise(t, Math.min(s.clockAt - 0.2, s.wordAt + 0.4), 0.4, 10) }}>
          {Array.from({ length: 12 }, (_, j) => <div key={j} style={{ position: "absolute", left: CS / 2 - 2, top: 8, width: 4, height: 10, borderRadius: 2, background: j === 10 ? p.gold : "#5B7083",
            transformOrigin: `2px ${CS / 2 - 8}px`, transform: `rotate(${j * 30}deg)` }} />)}
          <div style={{ position: "absolute", left: CS / 2 - 3, top: CS / 2 - 44, width: 6, height: 44, borderRadius: 3, background: p.gold, transformOrigin: "3px 44px", transform: `rotate(${ang}deg)` }} />
          <div style={{ position: "absolute", left: CS / 2 - 8, top: CS / 2 - 8, width: 16, height: 16, borderRadius: 8, background: "#fff" }} />
        </div>
        <div style={{ position: "absolute", left: P + CS + 26, top: CY + 14, ...rise(t, s.clockAt + 0.4, 0.4, 10) }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 60, letterSpacing: -2, lineHeight: 1, color: p.ink, whiteSpace: "nowrap" }}>{s.hour}</div>
          <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 26, color: p.mute, marginTop: 10, whiteSpace: "nowrap" }}>busiest hour</div>
        </div>
        <div style={{ position: "absolute", right: P, top: CY, width: 300, height: CS, borderRadius: 22, background: "#F6F8FB", border: "1.5px solid #E3E8EF",
          display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 24px", boxSizing: "border-box", ...rise(t, s.countAt - 0.15, 0.4, 10) }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 60, letterSpacing: -2, lineHeight: 1, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{fmt(lerp(0, s.count, cc))}</div>
          <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 24, color: p.mute, marginTop: 8, whiteSpace: "nowrap" }}>{s.countLabel}</div>
        </div>
      </>;
    }
    case "asleep": {
      // overnight task list ticks while he sleeps; "56x" counter for the "I'm going to sleep, keep working" messages
      const top = 196, RW = 300, LW = w - P * 2 - RW - 28;
      const cc = r(t, s.countAt, s.countAt + 0.8, IO);
      return <>
        <Stamp s={s} t={t} p={p} />
        <div style={{ position: "absolute", right: P, top: 34, ...rise(t, s.wordAt, 0.4, 8) }}><Ico d={I.moon} size={64} color={p.gold2} w={2.4} /></div>
        <div style={{ position: "absolute", left: P, top, width: LW, height: h - top - 34, borderRadius: 22, background: "#0E2433", padding: "16px 22px", boxSizing: "border-box" }}>
          {s.tasks.map((row, i) => {
            const k = r(t, row.at, row.at + 0.35);
            return <div key={i} style={{ display: "flex", alignItems: "center", gap: 14, height: 46, marginTop: i ? 8 : 0 }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: k > 0.5 ? GOLD(p) : "#1F3A4D", display: "flex", alignItems: "center", justifyContent: "center",
                transform: `scale(${1 + 0.12 * Math.sin(Math.PI * k)})` }}>{k > 0.5 && <Ico d={I.check} size={22} color={p.ink} w={3} />}</div>
              <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: k > 0.5 ? "#FFFFFF" : "#8FA3B5", whiteSpace: "nowrap" }}>{row.text}</span>
            </div>;
          })}
        </div>
        <div style={{ position: "absolute", right: P, top, width: RW, height: h - top - 34, borderRadius: 22, background: "#F6F8FB", border: "1.5px solid #E3E8EF",
          display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 24px", boxSizing: "border-box", ...rise(t, s.countAt - 0.15, 0.4, 10) }}>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 72, letterSpacing: -2.5, lineHeight: 1, fontVariantNumeric: "tabular-nums", ...gradText(G(p)) }}>{fmt(lerp(0, s.count, cc))}×</div>
          <div style={{ fontFamily: UI, fontWeight: 700, fontStyle: "italic", fontSize: 24, lineHeight: 1.2, color: p.ink, marginTop: 10 }}>{s.quote}</div>
        </div>
      </>;
    }
    case "impatience": {
      // his own "still not..." messages stack up as chat bubbles (right-aligned, newest at the bottom)
      const BH = 60, GAP = 14, base = h - 34 - BH;
      return <>
        <Stamp s={s} t={t} p={p} />
        {s.msgs.map((m, i) => {
          if (t < m.at - 0.02) return null;
          const later = s.msgs.filter((x, j) => j > i && t >= x.at).length;
          const k = r(t, m.at, m.at + 0.35);
          const y = base - later * (BH + GAP);
          return <div key={i} style={{ position: "absolute", right: P, top: y + (1 - k) * 20, height: BH, borderRadius: 24, borderBottomRightRadius: 8, background: G(p), color: "#fff",
            display: "flex", alignItems: "center", padding: "0 26px", fontFamily: UI, fontWeight: 700, fontSize: 30, whiteSpace: "nowrap", opacity: k,
            boxShadow: `0 10px 20px -12px ${p.b}AA`, transition: "none" }}>{m.text}</div>;
        })}
      </>;
    }
    case "toggle": {
      // REAL ESTATE | CODE switch: the knob slides to CODE on his word; a CTO chip lands
      const fk = r(t, s.flipAt, s.flipAt + 0.5, IO);
      const TW = w - P * 2, TH = 84, ty = 200, half = TW / 2;
      const ck = r(t, s.chipAt, s.chipAt + 0.4);
      return <>
        <Stamp s={s} t={t} p={p} size={84} />
        <div style={{ position: "absolute", left: P, top: ty, width: TW, height: TH, borderRadius: TH / 2, background: "#F1F4F8", border: "1.5px solid #E3E8EF" }}>
          <div style={{ position: "absolute", top: 6, left: 6 + lerp(0, half - 6, fk), width: half - 6, height: TH - 12, borderRadius: (TH - 12) / 2,
            background: fk > 0.5 ? G(p) : "linear-gradient(135deg, #94A3B8, #64748B)", boxShadow: "0 8px 18px -8px rgba(15,23,42,0.4)" }} />
          {[s.left, s.right].map((lab, j) => {
            const on = j === 0 ? fk < 0.5 : fk >= 0.5;
            return <div key={j} style={{ position: "absolute", left: j * half, top: 0, width: half, height: TH, display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: UI, fontWeight: 800, fontSize: 34, color: on ? "#fff" : "#94A3B8", letterSpacing: -0.5 }}>{lab}</div>;
          })}
        </div>
        {t >= s.chipAt - 0.02 && <div style={{ position: "absolute", left: P, top: ty + TH + 24, height: 52, borderRadius: 26, background: GOLD(p), color: p.ink, padding: "0 22px",
          display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 26, opacity: ck, transform: `translateY(${(1 - ck) * 10}px)`, whiteSpace: "nowrap" }}>{s.chip}</div>}
      </>;
    }
    case "polite": {
      // "last answer" teaser -> POLITE stamps; please climbs to 917, thanks crawls to 46, then ticks to 47 (gold flash)
      const LBL = 190, TW = w - P * 2 - LBL - 130, BH = 58, y1 = 200, y2 = y1 + BH + 26;
      const pk = r(t, s.pleaseAt, s.pleaseAt + 1.0, IO);
      const tk = r(t, s.thanksAt, s.thanksAt + 1.4, IO);
      const ok = r(t, s.plusOneAt, s.plusOneAt + 0.3);
      const thanksN = lerp(0, s.thanks, tk) + ok;
      const flash = t >= s.plusOneAt ? Math.max(0, 1 - (t - s.plusOneAt) / 0.8) : 0;
      const bar = (y: number, label: string, frac: number, n: number, gold: boolean, vis: React.CSSProperties) => <div style={{ position: "absolute", left: P, top: y, right: P, height: BH, ...vis }}>
        <div style={{ position: "absolute", left: 0, top: 0, height: BH, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 800, fontSize: 32, color: p.ink }}>{label}</div>
        <div style={{ position: "absolute", left: LBL, top: 0, width: TW, height: BH, borderRadius: 16, background: "#F1F4F8" }} />
        <div style={{ position: "absolute", left: LBL, top: 0, width: Math.max(16, TW * frac), height: BH, borderRadius: 16, background: gold ? GOLD(p) : G(p) }} />
        <div style={{ position: "absolute", right: 0, top: 0, width: 116, height: BH, display: "flex", alignItems: "center", justifyContent: "flex-end", fontFamily: UI, fontWeight: 800,
          fontSize: 44, letterSpacing: -1.5, fontVariantNumeric: "tabular-nums", color: p.ink }}>{fmt(n)}</div>
      </div>;
      return <>
        {t < s.qAt && <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 18, paddingLeft: P, ...rise(t, -10, 0.1, 0) }}>
          <div style={{ width: 56, height: 56, borderRadius: 28, background: G(p), display: "flex", alignItems: "center", justifyContent: "center" }}><Ico d={I.heart} size={30} color="#fff" w={2.4} /></div>
          <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 48, letterSpacing: -1.2, color: p.ink }}>{s.lead}</span></div>}
        {t >= s.qAt && <Stamp s={s} t={t} p={p} gold />}
        {bar(y1, "please", pk, lerp(0, s.please, pk), false, rise(t, Math.min(s.pleaseAt - 0.2, s.wordAt + 0.35), 0.4, 10))}
        {bar(y2, "thanks", (thanksN / s.please), thanksN, true, rise(t, s.thanksAt - 0.2, 0.4, 10))}
        {flash > 0 && <div style={{ position: "absolute", left: P + LBL - 10, top: y2 - 10, right: P - 10, height: BH + 20, borderRadius: 22, border: `3px solid ${p.gold}`, opacity: flash }} />}
      </>;
    }
  }
};
