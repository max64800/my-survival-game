import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/EBGaramond";
import { loadFont as loadScript } from "@remotion/google-fonts/GreatVibes";

// Kit 5: "stack" captions, after @karan.mp4_ (Max's favourite captions, 2026-10-10).
// Book serif for every word, ONE payoff word per screen in a connected script. 2-6 words in 2-3 lines, never all
// centred (zig-zag stack, or a setup line high behind the head + the payoff at chest height). Each word blurs in on
// its spoken word; lines dim to grey and vanish in reading order, the payoff last.
const { fontFamily: SERIF } = loadSerif("normal", { weights: ["500", "600"], subsets: ["latin"] });
const { fontFamily: SCRIPT } = loadScript("normal", { subsets: ["latin"] });

export type StackWord = { w: string; s: number; script?: boolean };
export type StackLine = { words: StackWord[]; x: number; y: number; align: "left" | "center" | "right"; behind?: boolean; outAt: number; size?: number };
export type StackGroup = { from: number; to: number; lines: StackLine[] };

const SERIF_SIZE = 84;
const SCRIPT_SIZE = 150;
const SHADOW = "0 3px 10px rgba(0,0,0,0.55), 0 0 2px rgba(0,0,0,0.35)";

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const r = (t: number, a: number, b: number, e = Easing.bezier(0.22, 1, 0.36, 1)) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });

const Word: React.FC<{ w: StackWord; t: number; size: number }> = ({ w, t, size }) => {
  const dur = w.script ? 0.26 : 0.18;
  const k = r(t, w.s - 0.02, w.s - 0.02 + dur);
  if (t < w.s - 0.02) return <span style={{ display: "inline-block", opacity: 0, fontSize: w.script ? size * 1.8 : size }}>{w.w}</span>;
  const blur = (1 - k) * (w.script ? 18 : 12);
  return (
    <span style={{ display: "inline-block", fontFamily: w.script ? SCRIPT : SERIF, fontWeight: w.script ? 400 : 500,
      fontSize: w.script ? size * 1.8 : size, lineHeight: w.script ? 0.9 : 1.0, letterSpacing: w.script ? 0 : -0.5, color: "#FFFFFF",
      opacity: k, transform: `scale(${1.06 - 0.06 * k})`, filter: `blur(${blur}px) brightness(${1 + (1 - k) * 0.6})`, textShadow: SHADOW }}>{w.w}</span>
  );
};

export const StackCaptions: React.FC<{ groups: StackGroup[]; layer: "front" | "behind"; hide?: { from: number; to: number }[] }> = ({ groups, layer, hide }) => {
  const t = useT();
  if (hide?.some((h) => t >= h.from && t <= h.to)) return null;
  const g = groups.find((x) => t >= x.from && t <= x.to);
  if (!g) return null;
  return (
    <>
      {g.lines.filter((l) => !!l.behind === (layer === "behind")).map((l, i) => {
        // out: dim to ~50% grey, then vanish with a little blur
        const dim = r(t, l.outAt, l.outAt + 0.14);
        const gone = r(t, l.outAt + 0.14, l.outAt + 0.3);
        if (gone >= 1) return null;
        const size = l.size ?? SERIF_SIZE;
        const pos: React.CSSProperties = l.align === "left" ? { left: l.x } : l.align === "right" ? { right: 1080 - l.x } : { left: l.x, transform: "translateX(-50%)" };
        return (
          <div key={i} style={{ position: "absolute", top: l.y, ...pos, display: "flex", gap: size * 0.28, alignItems: "baseline", whiteSpace: "nowrap",
            opacity: (1 - dim * 0.5) * (1 - gone), filter: `grayscale(${dim}) blur(${gone * 6}px)` }}>
            {l.words.map((w, j) => <Word key={j} w={w} t={t} size={size} />)}
          </div>
        );
      })}
    </>
  );
};
