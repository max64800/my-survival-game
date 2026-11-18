import React from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";

// Element types (times in seconds on the cut's timeline):
//   badge   {n, label}              numbered point badge, top-left
//   chip    {icon, text, slot}      white pill, top-right column, slot = row 0..5
//   sticker {emoji, x, y, size}     big emoji that pops in and gently wobbles
//   sizes   {a, b}                  two-rectangle size comparison card (cm)
type Base = { from: number; to: number };
export type El =
  | (Base & { type: "badge"; n: number; label: string })
  | (Base & { type: "chip"; icon: string; text: string; slot: number; accent?: boolean; side?: "left" | "right" })
  | (Base & { type: "sticker"; emoji: string; x: number; y: number; size?: number })
  | (Base & { type: "sizes"; a: { label: string; w: number; h: number }; b: { label: string; w: number; h: number } })
  | (Base & { type: "chips"; items: { icon: string; text: string; at: number; accent?: boolean }[] });
export type OverlayProps = { duration: number; elements: El[] };

const FONT = "-apple-system, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif";
const YELLOW = "#FFD600";
const TOP = 300; // below the app's top bar
const SIDE = 56;

// pop in with a spring, fade + shrink out over the last 0.2 s
const usePop = (from: number, to: number) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const start = Math.round(from * fps);
  const end = Math.round(to * fps);
  const inP = spring({ frame: frame - start, fps, config: { damping: 11, stiffness: 160, mass: 0.7 } });
  const outP = interpolate(frame, [end - 6, end], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const visible = frame >= start && frame <= end;
  return { visible, scale: inP * (0.85 + 0.15 * outP), opacity: Math.min(1, inP * 1.5) * outP, t: (frame - start) / fps };
};

const shadow = "0 10px 28px rgba(0,0,0,0.35)";

const Badge: React.FC<{ e: Extract<El, { type: "badge" }> }> = ({ e }) => {
  const p = usePop(e.from, e.to);
  if (!p.visible) return null;
  return (
    <div style={{ position: "absolute", left: SIDE, top: TOP, display: "flex", alignItems: "center", gap: 14,
      transform: `scale(${p.scale})`, transformOrigin: "left center", opacity: p.opacity }}>
      <div style={{ width: 96, height: 96, borderRadius: 48, background: YELLOW, color: "#111", fontFamily: FONT,
        fontWeight: 900, fontSize: 60, display: "flex", alignItems: "center", justifyContent: "center",
        boxShadow: shadow, border: "5px solid #111" }}>{e.n}</div>
      <div style={{ background: "#111", color: "white", fontFamily: FONT, fontWeight: 800, fontSize: 40,
        padding: "12px 22px", borderRadius: 18, boxShadow: shadow, letterSpacing: 0.5 }}>{e.label}</div>
    </div>
  );
};

const Chip: React.FC<{ e: Extract<El, { type: "chip" }> }> = ({ e }) => {
  const p = usePop(e.from, e.to);
  if (!p.visible) return null;
  const right = e.side !== "left";
  return (
    <div style={{ position: "absolute", top: TOP + 130 + e.slot * 92, [right ? "right" : "left"]: SIDE,
      transform: `scale(${p.scale}) translateX(${(1 - p.opacity) * (right ? 40 : -40)}px)`,
      transformOrigin: right ? "right center" : "left center", opacity: p.opacity,
      display: "flex", alignItems: "center", gap: 12, background: e.accent ? YELLOW : "white",
      color: "#111", fontFamily: FONT, fontWeight: 800, fontSize: 38, padding: "12px 24px 12px 18px",
      borderRadius: 40, boxShadow: shadow }}>
      <span style={{ fontSize: 44 }}>{e.icon}</span>
      <span>{e.text}</span>
    </div>
  );
};

// a row of small pills under the badge, in the wall space above the head; each pops in on its word
const ChipItem: React.FC<{ icon: string; text: string; at: number; to: number; accent?: boolean }> = (c) => {
  const p = usePop(c.at, c.to);
  if (!p.visible) return null;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8, background: c.accent ? YELLOW : "white",
      color: "#111", fontFamily: FONT, fontWeight: 800, fontSize: 32, padding: "9px 18px 9px 13px",
      borderRadius: 36, boxShadow: shadow, opacity: p.opacity, transform: `scale(${p.scale})` }}>
      <span style={{ fontSize: 36 }}>{c.icon}</span>
      <span>{c.text}</span>
    </div>
  );
};

const Chips: React.FC<{ e: Extract<El, { type: "chips" }> }> = ({ e }) => (
  <div style={{ position: "absolute", left: SIDE, right: SIDE, top: TOP + 116, display: "flex",
    flexWrap: "wrap", gap: 14 }}>
    {e.items.map((c, i) => <ChipItem key={i} {...c} to={e.to} />)}
  </div>
);

const Sticker: React.FC<{ e: Extract<El, { type: "sticker" }> }> = ({ e }) => {
  const p = usePop(e.from, e.to);
  if (!p.visible) return null;
  const wobble = Math.sin(p.t * 5) * 6;
  const size = e.size ?? 150;
  return (
    <div style={{ position: "absolute", left: e.x - size / 2, top: e.y - size / 2, width: size, height: size,
      fontSize: size * 0.82, lineHeight: `${size}px`, textAlign: "center", opacity: p.opacity,
      transform: `scale(${p.scale}) rotate(${wobble}deg)`, filter: "drop-shadow(0 8px 14px rgba(0,0,0,0.35))" }}>
      {e.emoji}
    </div>
  );
};

const Sizes: React.FC<{ e: Extract<El, { type: "sizes" }> }> = ({ e }) => {
  const p = usePop(e.from, e.to);
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (!p.visible) return null;
  const k = 1.0; // px per cm
  // the smaller (Dubai) bed "shrinks" out of the bigger one after 0.4 s
  const shrink = spring({ frame: frame - Math.round((e.from + 0.4) * fps), fps, config: { damping: 14 } });
  const bw = e.a.w + (e.b.w - e.a.w) * shrink;
  const bh = e.a.h + (e.b.h - e.a.h) * shrink;
  return (
    <div style={{ position: "absolute", left: SIDE, top: TOP + 116, padding: 18, display: "flex", gap: 18,
      alignItems: "center", background: "rgba(255,255,255,0.96)", borderRadius: 24, boxShadow: shadow,
      opacity: p.opacity, transform: `scale(${p.scale})`, transformOrigin: "left top", fontFamily: FONT }}>
      <div style={{ position: "relative", width: e.a.w * k, height: e.a.h * k, flexShrink: 0 }}>
        <div style={{ position: "absolute", left: 0, top: 0, width: e.a.w * k, height: e.a.h * k,
          border: "5px dashed #111", borderRadius: 14, boxSizing: "border-box" }} />
        <div style={{ position: "absolute", left: 0, bottom: 0, width: bw * k, height: bh * k,
          background: YELLOW, border: "5px solid #111", borderRadius: 14, boxSizing: "border-box",
          display: "flex", alignItems: "center", justifyContent: "center", fontSize: 70 }}>🛏️</div>
      </div>
      <div style={{ fontSize: 30, fontWeight: 800, color: "#111", lineHeight: 1.35, width: 250 }}>
        <div style={{ opacity: 0.7 }}>┄ {e.a.label}</div>
        <div style={{ marginTop: 8 }}><span style={{ background: YELLOW, padding: "0 6px", borderRadius: 6 }}>■</span> {e.b.label}</div>
      </div>
    </div>
  );
};

export const Overlay: React.FC<OverlayProps> = ({ elements }) => (
  <AbsoluteFill style={{ backgroundColor: "transparent" }}>
    {elements.map((e, i) => {
      switch (e.type) {
        case "badge": return <Badge key={i} e={e} />;
        case "chip": return <Chip key={i} e={e} />;
        case "sticker": return <Sticker key={i} e={e} />;
        case "sizes": return <Sizes key={i} e={e} />;
        case "chips": return <Chips key={i} e={e} />;
      }
    })}
  </AbsoluteFill>
);
