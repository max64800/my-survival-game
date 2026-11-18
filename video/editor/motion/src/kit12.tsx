import React from "react";
import { Easing, Img, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "./kit11";

// Kit 12 "quiet proof" (A/B test vs kit11, Max 2026-10-22 after the week-3 audit + research): the real proof fills frame 1,
// then shrinks into ONE card that fills up line by line (a receipt that prints), captions are plain words with one gold
// emphasis colour, one push-in at the payoff, no behind-head words. Same easing family as kit11, no overshoot.
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "700", "800"], subsets: ["latin"] });

const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const rise = (t: number, at: number, d = 0.5, dy = 18): React.CSSProperties => {
  const k = r(t, at, at + d);
  return { opacity: k, transform: `translateY(${(1 - k) * dy}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined };
};
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };

// ---------------- frame 1: the real screenshot, full screen, then it shrinks into the card ----------------
// marks/focus are fractions of the source image; the image fills the frame width
export type Mark = { at: number; x0: number; y0: number; x1: number; y1: number };
export type ProofDef = { src: string; aspect: number; from: number; morphAt: number; to: number; focus: [number, number]; push: [number, number];
  pushFocus: [number, number]; target: { x: number; y: number; w: number; h: number }; marks: Mark[];
  start?: { x: number; y: number; w: number; h: number };   // card rect for frame 1 (x = centre, y = top); default = full screen
  shade?: boolean };                                           // dark fade at the bottom for captions (full-screen start only)
export const ProofShot: React.FC<{ d: ProofDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const m = r(t, d.morphAt, d.morphAt + 0.6, IO);
  const fade = r(t, d.morphAt + 0.3, d.to, IN);
  const pk = r(t, d.from, d.morphAt, Easing.bezier(0.33, 0, 0.67, 1));
  const s0 = d.start ?? { x: 540, y: 0, w: 1080, h: 1920 };
  const enter = d.start ? r(t, d.from, d.from + 0.35) : 1;
  const cx = lerp(s0.x, d.target.x, m), cy = lerp(s0.y + s0.h / 2, d.target.y + d.target.h / 2, m);
  const cw = lerp(s0.w, d.target.w, m), ch = lerp(s0.h, d.target.h, m);
  const zoom = lerp(lerp(d.push[0], d.push[1], pk), 1.25, m);
  const fx = lerp(lerp(d.focus[0], d.pushFocus[0], pk), d.pushFocus[0], m), fy = lerp(lerp(d.focus[1], d.pushFocus[1], pk), d.pushFocus[1], m);
  const iw = cw * zoom, ih = iw * d.aspect;
  const il = cw / 2 - fx * iw, it = ch / 2 - fy * ih;
  return (
    <div style={{ position: "absolute", left: cx - cw / 2, top: cy - ch / 2, width: cw, height: ch, borderRadius: d.start ? 36 : lerp(0, 36, m), overflow: "hidden",
      opacity: (1 - fade) * enter, transform: `scale(${0.96 + 0.04 * enter})`, background: "#EEF2F1", boxShadow: m > 0 || d.start ? `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` : undefined }}>
      <div style={{ position: "absolute", left: il, top: it, width: iw, height: ih }}>
        <Img src={staticFile(d.src)} style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} />
        {d.marks.map((k, i) => {
          const a = r(t, k.at, k.at + 0.45);
          if (a <= 0) return null;
          const pad = 0.012;
          return <div key={i} style={{ position: "absolute", left: `${(k.x0 - pad) * 100}%`, top: `${(k.y0 - pad / d.aspect) * 100}%`,
            width: `${(k.x1 - k.x0 + 2 * pad) * 100}%`, height: `${(k.y1 - k.y0 + 2 * pad / d.aspect) * 100}%`, borderRadius: 14,
            border: `5px solid ${pal.gold}`, background: `${pal.gold}26`, opacity: a * (1 - m), transform: `scale(${1.08 - 0.08 * a})`,
            boxShadow: `0 0 0 6px ${pal.gold}33` }} />;
        })}
      </div>
      {/* a soft shade at the bottom so the captions stay readable on the light screenshot */}
      {(d.shade ?? !d.start) && <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: "38%", opacity: 1 - m,
        background: "linear-gradient(180deg, rgba(15,23,42,0) 0%, rgba(15,23,42,0.62) 100%)" }} />}
    </div>
  );
};

// ---------------- the receipt: one card that prints a row per line and scrolls; a stamp lands on the payoff ----------------
export type Row = { at: number; label: string; value: string; count?: { to: number; prefix?: string; suffix?: string }; tone?: "bad" | "good" | "gold";
  strikeAt?: number; note?: string };
export type ReceiptDef = { from: number; to: number; x: number; y: number; w: number; scale: number; title: string; meta: string; rows: Row[]; visible: number;
  stamp?: { at: number; to?: number; text: string } };
export const RECEIPT_H = (visible: number) => 84 + visible * 96 + 26;
export const Receipt: React.FC<{ d: ReceiptDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const RH = 96, H = RECEIPT_H(d.visible), P = 40;
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  // scroll: each row past `visible` pushes the list up by one row height, eased
  const scroll = d.rows.reduce((acc, row, i) => acc + (i >= d.visible ? r(t, row.at, row.at + 0.45, IO) : 0), 0) * RH;
  const red = "#E5484D", green = "#16A34A";
  const st = d.stamp ? r(t, d.stamp.at, d.stamp.at + 0.35, Easing.bezier(0.2, 0.9, 0.3, 1)) * (1 - (d.stamp.to ? r(t, d.stamp.to - 0.3, d.stamp.to, IN) : 0)) : 0;
  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: H, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${d.scale})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.5,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.a}55 45%, ${pal.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          <div style={{ position: "absolute", left: P, right: P, top: 0, height: 84, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, ...LABEL, fontSize: 25, color: pal.ink }}>
              <div style={{ width: 14, height: 14, borderRadius: 7, background: pal.gold, boxShadow: `0 0 0 5px ${pal.gold}44` }} />{d.title}</div>
            <div style={{ ...LABEL, fontSize: 22, color: pal.mute, letterSpacing: 1.6 }}>{d.meta}</div>
          </div>
          <div style={{ position: "absolute", left: P, right: P, top: 82, borderTop: "2.5px dashed #D9DEE8" }} />
          <div style={{ position: "absolute", left: 0, right: 0, top: 86, height: d.visible * RH + 8, overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, right: 0, top: -scroll }}>
              {d.rows.map((row, i) => {
                if (t < row.at - 0.02) return null;
                const k = r(t, row.at, row.at + 0.45);
                const n = row.count ? Math.round(lerp(0, row.count.to, r(t, row.at, row.at + 0.8, IO))) : 0;
                const val = row.count ? `${row.count.prefix ?? ""}${n.toLocaleString("en-US")}${row.count.suffix ?? ""}` : row.value;
                const sk = row.strikeAt !== undefined ? r(t, row.strikeAt, row.strikeAt + 0.4, IO) : 0;
                const col = row.tone === "bad" ? red : row.tone === "good" ? green : pal.ink;
                return <div key={i} style={{ position: "absolute", left: P, right: P, top: i * RH, height: RH, display: "flex", alignItems: "center",
                  justifyContent: "space-between", opacity: k, transform: `translateY(${(1 - k) * 18}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined,
                  borderBottom: "1.5px solid #EEF0F5" }}>
                  <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 38, color: pal.mute }}>{row.label}</span>
                  <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                    {row.note && sk > 0 && <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: pal.mute, opacity: sk, letterSpacing: 0.5 }}>{row.note}</span>}
                    <span style={{ position: "relative", fontFamily: UI, fontWeight: 800, fontSize: 54, letterSpacing: -1.5, color: row.tone === "gold" ? undefined : col,
                      fontVariantNumeric: "tabular-nums", opacity: 1 - 0.45 * sk,
                      ...(row.tone === "gold" ? { background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`, WebkitBackgroundClip: "text",
                        backgroundClip: "text", color: "transparent" } : {}) }}>{val}
                      {sk > 0 && <span style={{ position: "absolute", left: -6, right: -6, top: "52%", height: 4, borderRadius: 2, background: red,
                        transformOrigin: "0 50%", transform: `scaleX(${sk})` }} />}
                    </span>
                  </div>
                </div>;
              })}
            </div>
          </div>
        </div>
      </div>
      {d.stamp && st > 0 && <div style={{ position: "absolute", left: "50%", top: H / 2, transform: `translate(-50%, -50%) rotate(-7deg) scale(${lerp(1.6, 1, st)})`,
        opacity: Math.min(1, st * 1.5), padding: "10px 30px", border: `6px solid ${red}`, borderRadius: 18, background: "rgba(255,255,255,0.92)",
        fontFamily: UI, fontWeight: 800, fontSize: 60, letterSpacing: 2, color: red, whiteSpace: "nowrap", boxShadow: "0 18px 40px -14px rgba(229,72,77,0.55)" }}>
        {d.stamp.text}</div>}
    </div>
  );
};

// ---------------- captions: plain Inter words, 1-4 per line, landing as spoken; key words in gold. No pill, no box ----------------
export type QWord = { w: string; s: number; e: number; x: number; key?: boolean };
export type QuietCapsDef = { chunks: { from: number; to: number; y: number; words: QWord[] }[]; size: number };
export const QuietCaptions: React.FC<{ d: QuietCapsDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  const c = d.chunks.find((x) => t >= x.from && t < x.to);
  if (!c) return null;
  return <div style={{ position: "absolute", left: 0, top: c.y, width: 1080, height: d.size * 1.3 }}>
    {c.words.map((w, i) => {
      const k = r(t, w.s - 0.04, w.s + 0.2);
      if (k <= 0) return null;
      return <span key={i} style={{ position: "absolute", left: w.x, top: 0, fontFamily: UI, fontWeight: 800, fontSize: d.size, lineHeight: 1.3, whiteSpace: "nowrap",
        color: w.key ? pal.gold : "#FFFFFF", opacity: k, transform: `translateY(${(1 - k) * 8}px)`,
        textShadow: "0 2px 3px rgba(0,0,0,0.55), 0 0 2px rgba(0,0,0,0.35), 0 6px 22px rgba(0,0,0,0.55)" }}>{w.w}</span>;
    })}
  </div>;
};

// ---------------- 027 "350 tasks": one card that is the master list, then the Claude chat with the top 3, then 3 vs 350 ----------------
// modes by time: list (scrolls, 350 count) -> chat (prompt types, 3 rows, ticks, batches swap) -> list2 (fast scroll, 15 -> 350, blurs)
// -> split (3 clean vs 350 overflowing) -> cta (comment box). Same card size throughout; content cross-fades with a soft blur.
export type TasksDef = { from: number; to: number; x: number; y: number; w: number; h: number; scale: number; title: string;
  tasks: string[]; total: number; promptAt: number; prompt: string; typeDur: number; replyAt: number;
  batches: { at: number; rows: string[]; ticks: number[] }[]; updateAt: number;
  overAt: number; countAt: number; countFrom: number; blurAt: number; splitAt: number; easyAt: number; impAt: number; ctaAt: number; cta: string };
export const Tasks: React.FC<{ d: TasksDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const P = 36, HEAD = 78, RH = 54, green = "#16A34A", red = "#E5484D";
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  const modes: [string, number][] = [["list", d.from], ["chat", d.promptAt - 0.1], ["list2", d.overAt - 0.1], ["split", d.splitAt - 0.1], ["cta", d.ctaAt - 0.1]];
  const vis = (i: number) => {   // 0..1 visibility of mode i (cross-fade 0.35 s)
    const a = modes[i][1], b = i + 1 < modes.length ? modes[i + 1][1] : 1e9;
    return Math.min(i === 0 ? 1 : r(t, a, a + 0.35, IO), 1 - r(t, b, b + 0.3, IN));
  };
  const layer = (i: number, node: React.ReactNode) => {
    const v = vis(i);
    if (v <= 0.001) return null;
    return <div key={i} style={{ position: "absolute", inset: 0, opacity: v, transform: `translateY(${(1 - v) * 12}px)`, filter: v < 0.99 ? `blur(${(1 - v) * 8}px)` : undefined }}>{node}</div>;
  };
  const Check: React.FC<{ on: number; size?: number }> = ({ on, size = 28 }) => (
    <div style={{ width: size, height: size, borderRadius: 8, flexShrink: 0, border: `2.5px solid ${on > 0.5 ? green : "#CBD2DE"}`, background: on > 0.5 ? green : "#fff",
      display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + 0.15 * Math.sin(Math.PI * on)})` }}>
      {on > 0.5 && <svg width={size * 0.7} height={size * 0.7} viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" /></svg>}
    </div>);
  const header = (left: React.ReactNode, right: React.ReactNode) => <>
    <div style={{ position: "absolute", left: P, right: P, top: 0, height: HEAD, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, ...LABEL, fontSize: 24, color: pal.ink }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: pal.gold, boxShadow: `0 0 0 5px ${pal.gold}44` }} />{left}</div>
      {right}
    </div>
    <div style={{ position: "absolute", left: P, right: P, top: HEAD - 2, borderTop: "2.5px dashed #D9DEE8" }} />
  </>;
  const big = (n: number, color?: string) => <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, letterSpacing: -1, fontVariantNumeric: "tabular-nums",
    ...(color ? { color } : { background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent" }) }}>{n}</span>;
  // the long list: rows loop, scroll offset in px
  const listRows = (off: number, blur = 0, dim = false) => {
    const n = Math.ceil((d.h - HEAD) / RH) + 2, first = Math.floor(off / RH);
    return <div style={{ position: "absolute", left: 0, right: 0, top: HEAD + 4, bottom: 0, overflow: "hidden", filter: blur > 0.2 ? `blur(${blur}px)` : undefined }}>
      {Array.from({ length: n }, (_, j) => {
        const idx = first + j, task = d.tasks[((idx % d.tasks.length) + d.tasks.length) % d.tasks.length];
        return <div key={idx} style={{ position: "absolute", left: P, right: P, top: idx * RH - off + 10, height: RH, display: "flex", alignItems: "center", gap: 16 }}>
          <Check on={0} size={26} />
          <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 30, color: dim ? "#94A3B8" : "#475569", whiteSpace: "nowrap" }}>{task}</span>
          <span style={{ marginLeft: "auto", fontFamily: UI, fontWeight: 600, fontSize: 22, color: "#B6BFCC", fontVariantNumeric: "tabular-nums" }}>#{idx + 1}</span>
        </div>;
      })}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 70, background: "linear-gradient(180deg, rgba(247,248,252,0) 0%, #F7F8FC 100%)" }} />
    </div>;
  };
  // ---- chat mode state ----
  const bi = Math.max(0, d.batches.reduce((acc, b, i) => (t >= b.at - 0.02 ? i : acc), -1));
  const done = d.batches.reduce((acc, b) => acc + b.ticks.filter((tk) => t >= tk).length, 0);
  const left = d.total - (t >= d.updateAt ? done : 0);
  const typed = d.prompt.slice(0, Math.round(lerp(0, d.prompt.length, r(t, d.promptAt, d.promptAt + d.typeDur, (x) => x))));
  const BUB_TOP = HEAD + 22;
  const chat = <>
    {header(<>Claude</>, <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
      <span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>Done</span>{big(done, green)}
      <span style={{ ...LABEL, fontSize: 20, color: pal.mute, marginLeft: 6 }}>Left</span>{big(left)}</div>)}
    <div style={{ position: "absolute", right: P, top: BUB_TOP, maxWidth: d.w - P * 2 - 60, padding: "16px 22px", borderRadius: 22, borderTopRightRadius: 8,
      background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, color: "#fff", fontFamily: UI, fontWeight: 600, fontSize: 28, lineHeight: 1.3,
      boxShadow: `0 10px 22px -10px ${pal.a}AA` }}>{typed}<span style={{ opacity: typed.length < d.prompt.length ? 1 : 0 }}>|</span></div>
    {d.batches.map((b, i) => {
      const inK = r(t, b.at, b.at + 0.45), outK = i + 1 < d.batches.length ? r(t, d.batches[i + 1].at - 0.05, d.batches[i + 1].at + 0.25, IN) : 0;
      if (inK <= 0 || outK >= 1) return null;
      return <div key={i} style={{ position: "absolute", left: P, right: P, top: BUB_TOP + 134, opacity: inK * (1 - outK),
        transform: `translateY(${(1 - inK) * 24 - outK * 24}px)` }}>
        {b.rows.map((row, j) => {
          const tk = b.ticks[j] !== undefined ? r(t, b.ticks[j], b.ticks[j] + 0.3) : 0;
          const rk = r(t, b.at + j * 0.12, b.at + j * 0.12 + 0.4);
          return <div key={j} style={{ height: 62, display: "flex", alignItems: "center", gap: 16, opacity: rk, transform: `translateX(${(1 - rk) * 20}px)` }}>
            <div style={{ width: 34, fontFamily: UI, fontWeight: 800, fontSize: 28, color: pal.b }}>{j + 1}</div>
            <Check on={tk} />
            <span style={{ position: "relative", fontFamily: UI, fontWeight: 700, fontSize: 32, color: tk > 0.5 ? "#94A3B8" : pal.ink, whiteSpace: "nowrap" }}>{row}
              <span style={{ position: "absolute", left: -4, right: -4, top: "54%", height: 3, borderRadius: 2, background: "#94A3B8", transformOrigin: "0 50%",
                transform: `scaleX(${tk})` }} /></span>
          </div>;
        })}
      </div>;
    })}
  </>;
  // ---- list2: the full list comes back, scrolls fast while the count runs up, then blurs into a wall ----
  const cn = Math.round(lerp(d.countFrom, d.total, r(t, d.countAt, d.countAt + 1.4, IO)));
  const bl = r(t, d.blurAt, d.blurAt + 0.8, IO);
  const sp = (x: number) => Math.max(0, x - d.overAt);
  const off2 = sp(t) * 260 + sp(t) * sp(t) * 120;
  // ---- split ----
  const ek = r(t, d.easyAt, d.easyAt + 0.45), ik = r(t, d.impAt, d.impAt + 0.45);
  const HW = (d.w - P * 2 - 24) / 2, BOXT = 30, BOXH = d.h - BOXT - 30;
  const split = <>
    <div style={{ position: "absolute", left: P, top: BOXT, width: HW, height: BOXH, borderRadius: 24, background: "#F0FDF4", border: `2px solid ${green}55`, padding: "18px 22px", boxSizing: "border-box" }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 92, letterSpacing: -3, lineHeight: 1, color: green }}>3</span>
        <span style={{ ...LABEL, fontSize: 20, color: green }}>tasks</span></div>
      {d.batches[0].rows.map((row, j) => <div key={j} style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 14 }}>
        <Check on={0} size={24} /><span style={{ fontFamily: UI, fontWeight: 700, fontSize: 24, color: pal.ink, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", maxWidth: HW - 90 }}>{row}</span></div>)}
      <div style={{ position: "absolute", right: 18, top: 22, opacity: ek, transform: `translateY(${(1 - ek) * 10}px)`, padding: "8px 18px", borderRadius: 22, background: green,
        color: "#fff", fontFamily: UI, fontWeight: 800, fontSize: 24 }}>Easy</div>
    </div>
    <div style={{ position: "absolute", right: P, top: BOXT, width: HW, height: BOXH, borderRadius: 24, background: "#FEF2F2", border: `2px solid ${red}44`, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 22, top: 18, display: "flex", alignItems: "baseline", gap: 10, zIndex: 2 }}>
        <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 92, letterSpacing: -3, lineHeight: 1, color: red }}>350</span>
        <span style={{ ...LABEL, fontSize: 20, color: red }}>tasks</span></div>
      <div style={{ position: "absolute", right: 18, bottom: 18, zIndex: 3, boxShadow: "0 8px 18px -8px rgba(0,0,0,0.35)", opacity: ik, transform: `translateY(${(1 - ik) * 10}px)`, padding: "8px 18px", borderRadius: 22,
        background: red, color: "#fff", fontFamily: UI, fontWeight: 800, fontSize: 24 }}>Impossible</div>
      <div style={{ position: "absolute", left: 22, right: 22, top: 128, filter: "blur(1.2px)", transform: `translateY(${-(t - d.splitAt) * 40}px)` }}>
        {Array.from({ length: 30 }, (_, j) => <div key={j} style={{ display: "flex", alignItems: "center", gap: 8, height: 24 }}>
          <div style={{ width: 14, height: 14, borderRadius: 4, border: "2px solid #E7B4B6" }} />
          <div style={{ height: 8, borderRadius: 4, background: "#EBC3C5", width: `${55 + ((j * 37) % 40)}%` }} /></div>)}
      </div>
    </div>
  </>;
  // ---- cta ----
  const cta = <>
    {header(<>Comment</>, null)}
    <div style={{ position: "absolute", left: P, right: P, top: HEAD + 30, height: 96, borderRadius: 24, background: "#F1F5F9", border: "1.5px solid #E2E8F0",
      display: "flex", alignItems: "center", gap: 18, padding: "0 26px", boxSizing: "border-box" }}>
      <div style={{ width: 52, height: 52, borderRadius: 26, background: `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, flexShrink: 0 }} />
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: pal.ink, whiteSpace: "nowrap" }}>{d.cta}</span>
      <div style={{ width: 3, height: 40, background: pal.b, opacity: Math.floor(t * 2) % 2 ? 1 : 0.15 }} />
    </div>
    {/* his own answer, pinned under the box */}
    <div style={{ position: "absolute", left: P, right: P, top: HEAD + 150, display: "flex", alignItems: "center", gap: 16, ...rise(t, d.ctaAt + 0.6, 0.5) }}>
      <div style={{ width: 44, height: 44, borderRadius: 22, background: `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`, flexShrink: 0 }} />
      <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 28, color: pal.ink }}>Max</span>
      <span style={{ ...LABEL, fontSize: 18, color: pal.mute }}>Pinned</span>
      <span style={{ fontFamily: UI, fontWeight: 700, fontSize: 30, color: pal.ink, marginLeft: 8 }}>Mine: <b style={{ color: "#E5484D" }}>350</b></span>
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
          {layer(0, <>{header(<>{d.title}</>, <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>{big(d.total)}<span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>tasks</span></div>)}
            {listRows(Math.max(0, t - d.from) * 70)}</>)}
          {layer(1, chat)}
          {layer(2, <>{header(<>{d.title}</>, <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>{big(cn, bl > 0.3 ? red : undefined)}<span style={{ ...LABEL, fontSize: 20, color: pal.mute }}>tasks</span></div>)}
            {listRows(off2, bl * 7, bl > 0.3)}</>)}
          {layer(3, split)}
          {layer(4, cta)}
        </div>
      </div>
    </div>
  );
};
