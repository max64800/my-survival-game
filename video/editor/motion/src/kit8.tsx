import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// Kit 8: "chat bubbles" captions (library style c2-04, Max 8/10 "very unique") for full edits. Each phrase arrives as a
// message (typing dots → white bubble) and the thread stacks upward with an avatar beside the newest message.
// Key words blue + bolder. No SFX per message (Max 2026-10-12: no sound on every new caption).
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "800"], subsets: ["latin"] });
const INK = "#1C1C1E";
const BLUE = "#0A84FF";
const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const POP = Easing.bezier(0.3, 1.5, 0.5, 1);

type Word = { w: string; s: number; e: number; em?: boolean };
export type ChatBubble = { from: number; dots: number; words: Word[] };
export type ChatDef = { bubbles: ChatBubble[]; top?: number; bottom?: number; hide?: { from: number; to: number }[]; initial?: string;
  maxVisible?: number; bubbleH?: number; fontSize?: number };   // keep only the newest N bubbles (a short band: no half-hidden ghost of the previous message)

const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const r = (t: number, a: number, b: number, e = EASE) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;

export const ChatCaptions: React.FC<{ d: ChatDef }> = ({ d }) => {
  const t = useT();
  const top = d.top ?? 1150, bottom = d.bottom ?? 1405;
  const BH = d.bubbleH ?? 86, GAP = Math.round(BH * 0.16), FS = d.fontSize ?? 46;
  // a hide range (e.g. a full-screen card) clears the thread; it restarts after it
  const hide = (d.hide ?? []).find((h) => t >= h.from && t <= h.to);
  const lastHideEnd = Math.max(-1, ...(d.hide ?? []).filter((h) => t > h.to).map((h) => h.to));
  const hideK = hide ? 1 - r(t, hide.from, hide.from + 0.2, EASE_IN) : 1;
  const all = d.bubbles.filter((b) => t >= b.dots && b.dots >= lastHideEnd - 0.01);
  const vis = d.maxVisible ? all.slice(-d.maxVisible) : all;
  if (!vis.length || hideK <= 0.001) return null;
  return (
    <>
      <div style={{ position: "absolute", left: 60, width: 840, top, height: bottom - top, overflow: "hidden", opacity: hideK,
        WebkitMaskImage: "linear-gradient(to bottom, transparent 0px, black 80px)", maskImage: "linear-gradient(to bottom, transparent 0px, black 80px)",
        display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
        {vis.map((b, bi) => {
          const hk = r(t, b.dots, b.dots + 0.2);
          const k = r(t, b.from - 0.06, b.from + 0.2);
          const age = vis.length - 1 - bi;
          return (
            <div key={b.from} style={{ height: hk * (BH + GAP), flexShrink: 0, position: "relative", opacity: age === 0 ? 1 : age === 1 ? 0.93 : 0.82 }}>
              <div style={{ position: "absolute", left: 80, bottom: 0, height: BH, maxWidth: lerp(132, 760, k), overflow: "hidden", borderRadius: "42px 42px 42px 12px",
                background: "#FFFFFF", boxShadow: "0 10px 24px rgba(0,0,0,0.28)", transformOrigin: "0% 100%", transform: `scale(${lerp(0.5, 1, hk)})`,
                display: "flex", alignItems: "center" }}>
                <div style={{ display: "flex", gap: 12, position: "absolute", left: 34, opacity: 1 - k }}>
                  {[0, 1, 2].map((i) => <div key={i} style={{ width: 16, height: 16, borderRadius: 8, background: "#9A9AA0", transform: `translateY(${Math.sin(t * 14 - i * 0.9) * 6}px)` }} />)}
                </div>
                <div style={{ padding: "0 32px", whiteSpace: "nowrap", fontFamily: UI, fontWeight: 600, fontSize: FS, color: INK, opacity: k, letterSpacing: -0.3 }}>
                  {b.words.filter((w, wi) => wi === 0 || t >= w.s - 0.03).map((w, wi) => (
                    <span key={wi} style={{ opacity: r(t, w.s - 0.03, w.s + 0.08), color: w.em ? BLUE : INK, fontWeight: w.em ? 800 : 600 }}>{(wi ? " " : "") + w.w}</span>
                  ))}
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <div style={{ position: "absolute", left: 60, top: bottom - 64, width: 64, height: 64, borderRadius: 32, background: BLUE, color: "#fff", opacity: hideK,
        display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 32, border: "3px solid #fff",
        boxShadow: "0 6px 16px rgba(0,0,0,0.3)", transform: `scale(${r(t, vis[0].dots, vis[0].dots + 0.25, POP)})` }}>{d.initial ?? "M"}</div>
    </>
  );
};

// ---------- glass-pill stepper captions (library c2-07, Max ~8/10 "really good, similar to 4") ----------
// Each phrase is a frosted pill with a step number; the newest sits at the bottom in burnt orange, older ones move up and
// turn chocolate, then fade out at the top of the band. Key words in italic serif. No SFX per pill (Max 2026-10-12).
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";
const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["700"], subsets: ["latin"] });
const CREAM = "#F6EBDD";

export type PillDef = { pills: { from: number; words: Word[] }[]; top?: number; bottom?: number; left?: number; size?: number };
export const PillCaptions: React.FC<{ d: PillDef }> = ({ d }) => {
  const t = useT();
  const top = d.top ?? 1120, bottom = d.bottom ?? 1405, left = d.left ?? 66, FS = d.size ?? 44;
  const PH = Math.round(FS * 1.8), PG = 14, PITCH = PH + PG;
  const P = d.pills;
  if (!P.length || t < P[0].from - 0.1) return null;
  const shown = P.reduce((a, p, i) => a + (i === 0 ? 1 : r(t, p.from - 0.05, p.from + 0.22)), 0);
  let ai = 0;
  P.forEach((p, i) => { if (t >= p.from - 0.05) ai = i; });
  const rowY = (i: number) => bottom - PH - (shown - 1 - i) * PITCH;   // newest at the bottom
  return (
    <>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        <line x1={left - 16} y1={Math.max(top + 30, rowY(Math.max(0, ai - 2)) + PH / 2)} x2={left - 16} y2={bottom - PH / 2} stroke={CREAM} strokeWidth={2.5} opacity={0.55} />
      </svg>
      {P.map((p, i) => {
        if (i > ai) return null;
        const y = rowY(i);
        if (y < top - 40) return null;
        const vis = Math.max(0, Math.min(1, (y - top + 40) / 90));
        const k = i === 0 ? r(t, P[0].from - 0.1, P[0].from + 0.15) : r(t, p.from - 0.05, p.from + 0.22);
        const ak = i === ai ? 1 : 1 - r(t, P[i + 1].from - 0.05, P[i + 1].from + 0.2);
        return (
          <div key={i} style={{ position: "absolute", left, top: y, height: PH, display: "flex", alignItems: "center", gap: 18, padding: "0 32px 0 22px",
            borderRadius: PH / 2, background: ak > 0.5 ? `rgba(196,86,29,${0.55 + 0.37 * ak})` : "rgba(59,36,24,0.55)",
            backdropFilter: "blur(14px) saturate(1.3)", WebkitBackdropFilter: "blur(14px) saturate(1.3)",
            border: `1.5px solid rgba(246,235,221,${0.35 + 0.3 * ak})`, boxShadow: "0 10px 26px rgba(40,20,10,0.3)",
            opacity: vis * k, transform: `translateX(${(1 - k) * -40}px) scale(${0.94 + 0.06 * k})`, transformOrigin: "0% 50%" }}>
            <div style={{ width: FS * 1.05, height: FS * 1.05, borderRadius: FS, background: ak > 0.5 ? CREAM : "rgba(246,235,221,0.18)", color: ak > 0.5 ? "#C4561D" : CREAM,
              fontFamily: MONO, fontWeight: 700, fontSize: FS * 0.56, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>{String(i + 1).padStart(2, "0")}</div>
            <div style={{ fontFamily: UI, fontWeight: 600, fontSize: FS, color: CREAM, whiteSpace: "nowrap", letterSpacing: -0.3 }}>
              {p.words.filter((w, wi) => wi === 0 || t >= w.s - 0.03).map((w, wi) => {   // only spoken words: the pill grows (no faint preview)
                const a = r(t, w.s - 0.02, w.s + 0.16);
                return <span key={wi} style={{ opacity: Math.max(0.25, a), filter: a < 1 ? `blur(${(1 - a) * 8}px)` : undefined,
                  fontFamily: w.em ? SERIF : UI, fontStyle: w.em ? "italic" : "normal", fontSize: w.em ? FS * 1.24 : FS, fontWeight: w.em ? 400 : 600 }}>{(wi ? " " : "") + w.w}</span>;
              })}
            </div>
          </div>
        );
      })}
    </>
  );
};

// ---------- die-cut sticker captions (library c1-09, Max 7/10 → fixed) for full edits ----------
// Each phrase is a die-cut text sticker (thick white cut line, crisp offset shadow) that slaps on at a slight angle and grows
// word by word as he speaks (only spoken words, fully opaque). Up to 3 pile up per sentence; the pile clears when the
// sentence ends. Key words get one iOS colour each. No SFX per sticker.
const CLAMP = (v: number) => Math.max(0, Math.min(1, v));
export type StickerDef = { stickers: { from: number; pile: number; words: (Word & { col?: string })[] }[]; pileEnd: number[];
  slots?: { x: number; y: number; rot: number }[]; size?: number };
export const StickerCaptions: React.FC<{ d: StickerDef }> = ({ d }) => {
  const t = useT();
  const SLOTS = d.slots ?? [{ x: 470, y: 1400, rot: -4 }, { x: 530, y: 1495, rot: 3 }, { x: 480, y: 1590, rot: -2 }];
  const FS = d.size ?? 70;
  const started = d.stickers.map((s, i) => ({ s, i, at: s.from - 0.04 })).filter((x) => t >= x.at);
  if (!started.length) return null;
  const pile = started[started.length - 1].s.pile;
  const inPile = started.filter((x) => x.s.pile === pile);
  const visible = inPile.slice(-3);
  const pileOut = r(t, d.pileEnd[pile] - 0.22, d.pileEnd[pile], EASE_IN);
  if (pileOut >= 1) return null;
  const font: React.CSSProperties = { fontFamily: UI, fontWeight: 800, fontSize: FS, letterSpacing: -1.5, lineHeight: 1, whiteSpace: "nowrap" };
  return (
    <>
      {visible.map((x, vi) => {
        const shift = inPile.length > 3 ? 1 - r(t, visible[visible.length - 1].at, visible[visible.length - 1].at + 0.25, EASE) : 0;
        const s0 = SLOTS[vi], s1 = SLOTS[Math.min(2, vi + 1)];
        const slot = vi < 2 && shift > 0 ? { x: lerp(s0.x, s1.x, shift), y: lerp(s0.y, s1.y, shift), rot: lerp(s0.rot, s1.rot, shift) } : s0;
        const k = r(t, x.at, x.at + 0.14, EASE_IN);
        const settle = r(t, x.at + 0.14, x.at + 0.3, EASE);
        const scale = lerp(1.6, 1, k) * (1 - 0.03 * Math.sin(settle * Math.PI));
        const rot = slot.rot + (1 - k) * 9 * (vi % 2 ? -1 : 1);
        const older = visible.length - 1 - vi;
        const text = x.s.words.filter((w, wi) => wi === 0 || t >= w.s - 0.03);
        return (
          <div key={x.i} style={{ position: "absolute", left: slot.x, top: slot.y, transform: `translate(-50%, -50%) translateY(${pileOut * 60}px) rotate(${rot}deg) scale(${scale * (1 - older * 0.03)})`,
            opacity: CLAMP(k * 3) * (1 - pileOut), filter: `drop-shadow(0 ${lerp(26, 6, k)}px 0 rgba(0,0,0,${lerp(0.08, 0.24, k)}))` }}>
            <div style={{ position: "relative" }}>
              <div style={{ ...font, position: "absolute", left: 0, top: 0, WebkitTextStroke: "30px #FFFFFF", color: "#fff" }}>
                {text.map((w, j) => <span key={j}>{j ? " " : ""}{w.w}</span>)}
              </div>
              <div style={{ ...font, position: "relative" }}>
                {text.map((w, j) => <span key={j} style={{ color: w.col ?? INK }}>{j ? " " : ""}{w.w}</span>)}
              </div>
            </div>
          </div>
        );
      })}
    </>
  );
};

// ---------- highlighter-tape captions (library c2-09, Max 7/10) ----------
// Black text on torn paper-tape strips, 1-2 strips per block, slight tilt; key words get a hand-drawn highlighter swipe
// (yellow / green / pink in turn). Only spoken words show (strip grows; no faint preview) and no SFX per strip (Max's rules).
// Sits low on the chest: block bottom edge at `bottom` (default 1630, per platform-safe-zones update 2026-10-14).
const TAPE_HL = ["#FFE14A", "#B8F35A", "#FF9EC0"];
const tapeRand = (i: number) => { const x = Math.sin(i * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };
const tornClip = (seed: number) => {
  const pts: string[] = [];
  for (let i = 0; i <= 7; i++) pts.push(`${(tapeRand(seed + i) * 2.2).toFixed(2)}% ${(i / 7) * 100}%`);
  for (let i = 7; i >= 0; i--) pts.push(`${(100 - tapeRand(seed + 40 + i) * 2.2).toFixed(2)}% ${(i / 7) * 100}%`);
  return `polygon(${pts.join(", ")})`;
};
export type TapeDef = { blocks: { from: number; to: number; strips: { from: number; words: Word[] }[] }[]; bottom?: number; size?: number };
export const TapeCaptions: React.FC<{ d: TapeDef }> = ({ d }) => {
  const t = useT();
  const b = d.blocks.find((x) => t >= x.from && t < x.to);
  if (!b) return null;
  const bi = d.blocks.indexOf(b);
  const out = r(t, b.to - 0.16, b.to, EASE_IN);
  const FS = d.size ?? 60;
  let keyN = d.blocks.slice(0, bi).reduce((n, x) => n + x.strips.reduce((m, s) => m + s.words.filter((w) => w.em).length, 0), 0);
  return (
    <div style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - (d.bottom ?? 1630), display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
      opacity: 1 - out, transform: `translateY(${out * 40}px)` }}>
      {b.strips.filter((s) => t >= s.from - 0.03).map((s, k) => {   // a strip appears WITH its first word (never an empty strip)
        const si = bi * 10 + k;
        const sk = r(t, s.from - 0.03, s.from + 0.12);
        const rot = (tapeRand(si * 3) - 0.5) * 3.6;
        const words = s.words.filter((w, wi) => wi === 0 || t >= w.s - 0.03);
        return (
          <div key={k} style={{ position: "relative", marginLeft: k % 2 ? 60 : -40, opacity: Math.min(1, sk * 3),
            transform: `rotate(${rot + (1 - sk) * 5}deg) scale(${1 + (1 - sk) * 0.14})`, filter: "drop-shadow(0 6px 10px rgba(0,0,0,0.3))" }}>
            <div style={{ clipPath: tornClip(si * 17), background: "linear-gradient(180deg, #F7F2E6 0%, #EFE8D8 100%)", padding: "12px 38px 14px",
              display: "flex", columnGap: 14, fontFamily: UI, fontWeight: 800, fontSize: FS, color: "#151515", letterSpacing: -0.6, lineHeight: 1.1, whiteSpace: "nowrap" }}>
              {words.map((w, wi) => {
                const m = r(t, w.s, w.s + 0.24, Easing.linear);
                const col = TAPE_HL[(keyN += w.em ? 1 : 0) % TAPE_HL.length];
                return (
                  <span key={wi} style={{ position: "relative", display: "inline-block", opacity: wi === 0 ? 1 : r(t, w.s - 0.03, w.s + 0.07) }}>
                    {w.em && (
                      <svg style={{ position: "absolute", left: -8, top: "18%", width: "calc(100% + 16px)", height: "70%", overflow: "visible" }} viewBox="0 0 100 40" preserveAspectRatio="none">
                        <path d={`M2 ${6 + tapeRand(wi) * 4} L98 ${3 + tapeRand(wi + 1) * 4} L99 ${34 + tapeRand(wi + 2) * 4} L1 ${37 - tapeRand(wi + 3) * 3} Z`} fill={col}
                          style={{ clipPath: `inset(0 ${100 - m * 100}% 0 0)` }} />
                      </svg>
                    )}
                    <span style={{ position: "relative" }}>{w.w}</span>
                  </span>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
};
