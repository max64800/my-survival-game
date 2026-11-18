import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { CameraMotionBlur } from "@remotion/motion-blur";
import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import * as Icons from "lucide-react";
import { fitText } from "@remotion/layout-utils";

const { fontFamily: DISPLAY } = loadAnton();
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "800"] });

// v2 style: one tall display font, black glass + one yellow accent, line icons, eased motion
// (no bounce), motion blur. Rendered twice: layer "behind" (big words that sit between the
// speaker and the wall, composited under the person matte) and layer "front" (badges, chips).
const YELLOW = "#FFD600";
const GLASS = "rgba(14,14,14,0.82)";
const INK = "#141414";
const TOP = 300;
const SIDE = 56;
const EASE = Easing.bezier(0.22, 1, 0.36, 1);          // fast out, soft landing
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);

type Base = { from: number; to: number };
export type V2El =
  | (Base & { type: "big"; text: string; accent?: string; y?: number; size?: number })
  | (Base & { type: "badge"; n: number; label: string })
  | (Base & { type: "chips"; items: { icon: string; text: string; at: number; accent?: boolean }[] })
  | (Base & { type: "sizes"; a: { label: string; w: number; h: number }; b: { label: string; w: number; h: number } });
export type V2Props = { duration: number; layer: "behind" | "front"; elements: V2El[] };

// 0 -> 1 eased entrance over `inDur`, 1 -> 0 eased exit over the last `outDur`
export const useAnim = (from: number, to: number, inDur = 0.45, outDur = 0.3) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = frame / fps;
  const enter = interpolate(t, [from, from + inDur], [0, 1], { easing: EASE, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const exit = interpolate(t, [to - outDur, to], [1, 0], { easing: EASE_IN, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return { visible: t >= from && t <= to, enter, exit, v: Math.min(enter, exit), t: t - from };
};

const Icon: React.FC<{ name: string; size: number; color: string }> = ({ name, size, color }) => {
  const C = (Icons as unknown as Record<string, React.FC<{ size: number; color: string; strokeWidth: number }>>)[name];
  return C ? <C size={size} color={color} strokeWidth={2.4} /> : null;
};

// big word(s) behind the speaker: letters open up from tight tracking, a light sweep passes once
export const Big: React.FC<{ e: Extract<V2El, { type: "big" }> }> = ({ e }) => {
  const a = useAnim(e.from, e.to, 0.6, 0.35);
  if (!a.visible) return null;
  // never wider than the frame (minus margins); `size` is the most it may be
  const fit = fitText({ text: e.text.toUpperCase(), withinWidth: 1080 - 2 * 60, fontFamily: DISPLAY, letterSpacing: "4px" }).fontSize;
  const size = Math.min(e.size ?? 250, fit);
  const sweep = interpolate(a.t, [0.2, 1.2], [-60, 160], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const words = e.text.split(" ");
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: e.y ?? 380, textAlign: "center",
      fontFamily: DISPLAY, fontSize: size, lineHeight: 0.95, letterSpacing: interpolate(a.enter, [0, 1], [-18, 4]),
      opacity: a.v, transform: `translateY(${(1 - a.enter) * 60 - (1 - a.exit) * 30}px) scale(${0.94 + 0.06 * a.enter})`,
      textTransform: "uppercase" }}>
      {words.map((w, i) => {
        const accent = e.accent && w.toUpperCase().includes(e.accent.toUpperCase());
        const base = accent ? YELLOW : "#FFFFFF";   // white/yellow + thick ink outline reads on light walls and busy desks
        return (
          <span key={i} style={{
            backgroundImage: `linear-gradient(100deg, ${base} 0%, ${base} ${sweep - 12}%, ${accent ? "#FFF6B0" : "#FFFBEA"} ${sweep}%, ${base} ${sweep + 12}%, ${base} 100%)`,
            WebkitBackgroundClip: "text", backgroundClip: "text", color: "transparent",
            WebkitTextStroke: `${Math.max(4, size / 34)}px ${INK}`, paintOrder: "stroke fill",
            filter: "drop-shadow(0 8px 22px rgba(0,0,0,0.22))", marginRight: i < words.length - 1 ? "0.22em" : 0 }}>
            {w}
          </span>
        );
      })}
    </div>
  );
};

const Badge: React.FC<{ e: Extract<V2El, { type: "badge" }> }> = ({ e }) => {
  const a = useAnim(e.from, e.to);
  if (!a.visible) return null;
  return (
    <div style={{ position: "absolute", left: SIDE, top: TOP, display: "flex", alignItems: "center",
      background: GLASS, borderRadius: 22, padding: "10px 22px 10px 12px", gap: 14, opacity: a.v,
      transform: `translateX(${(1 - a.enter) * -80}px)`, boxShadow: "0 12px 30px rgba(0,0,0,0.3)" }}>
      <div style={{ background: YELLOW, color: "#111", fontFamily: UI, fontWeight: 800, fontSize: 34,
        borderRadius: 14, padding: "4px 12px" }}>{String(e.n).padStart(2, "0")}</div>
      <div style={{ color: "white", fontFamily: UI, fontWeight: 800, fontSize: 36, letterSpacing: 1.5 }}>{e.label}</div>
    </div>
  );
};

const ChipItem: React.FC<{ icon: string; text: string; at: number; to: number; accent?: boolean; i: number }> = (c) => {
  const a = useAnim(c.at, c.to, 0.4, 0.25);
  if (!a.visible) return null;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10, background: c.accent ? YELLOW : GLASS,
      color: c.accent ? "#111" : "white", fontFamily: UI, fontWeight: 800, fontSize: 32,
      padding: "11px 20px 11px 14px", borderRadius: 18, opacity: a.v,
      transform: `translateY(${(1 - a.enter) * 26}px)`, boxShadow: "0 10px 26px rgba(0,0,0,0.28)" }}>
      <Icon name={c.icon} size={34} color={c.accent ? "#111" : YELLOW} />
      <span>{c.text}</span>
    </div>
  );
};

const Chips: React.FC<{ e: Extract<V2El, { type: "chips" }> }> = ({ e }) => (
  <div style={{ position: "absolute", left: SIDE, right: SIDE, top: TOP + 100, display: "flex", flexWrap: "wrap", gap: 12 }}>
    {e.items.map((c, i) => <ChipItem key={i} {...c} to={e.to} i={i} />)}
  </div>
);

const Sizes: React.FC<{ e: Extract<V2El, { type: "sizes" }> }> = ({ e }) => {
  const a = useAnim(e.from, e.to);
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (!a.visible) return null;
  const k = 0.95;
  const s = interpolate(frame / fps, [e.from + 0.5, e.from + 1.3], [0, 1], { easing: EASE, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const bw = e.a.w + (e.b.w - e.a.w) * s;
  const bh = e.a.h + (e.b.h - e.a.h) * s;
  return (
    <div style={{ position: "absolute", left: SIDE, top: TOP + 100, display: "flex", gap: 18, alignItems: "center",
      background: GLASS, borderRadius: 24, padding: 18, opacity: a.v, transform: `translateY(${(1 - a.enter) * 30}px)`,
      fontFamily: UI, boxShadow: "0 12px 30px rgba(0,0,0,0.3)" }}>
      <div style={{ position: "relative", width: e.a.w * k, height: e.a.h * k }}>
        <div style={{ position: "absolute", inset: 0, border: "4px dashed rgba(255,255,255,0.7)", borderRadius: 12 }} />
        <div style={{ position: "absolute", left: 0, bottom: 0, width: bw * k, height: bh * k, background: YELLOW,
          borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Icon name="BedDouble" size={70} color="#111" />
        </div>
      </div>
      <div style={{ color: "white", fontWeight: 800, fontSize: 28, lineHeight: 1.4, width: 240 }}>
        <div style={{ opacity: 0.7 }}>┄ {e.a.label}</div>
        <div style={{ marginTop: 8, color: YELLOW }}>■ {e.b.label}</div>
      </div>
    </div>
  );
};

export const OverlayV2: React.FC<V2Props> = ({ elements, layer }) => (
  <AbsoluteFill style={{ backgroundColor: "transparent" }}>
    <CameraMotionBlur shutterAngle={180} samples={6}>
      <AbsoluteFill>
        {elements.map((e, i) => {
          if (layer === "behind") return e.type === "big" ? <Big key={i} e={e} /> : null;
          switch (e.type) {
            case "badge": return <Badge key={i} e={e} />;
            case "chips": return <Chips key={i} e={e} />;
            case "sizes": return <Sizes key={i} e={e} />;
            default: return null;
          }
        })}
      </AbsoluteFill>
    </CameraMotionBlur>
  </AbsoluteFill>
);
