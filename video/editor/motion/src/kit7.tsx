import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";

// Kit 7: ONE graphite plate that travels the whole video and changes shape for every beat (fitted to its content,
// liquid overshoot on each hand-off). Inside it each line gets its own tool: emoji avatars, an app grid that drops
// into the trash, a prompt box, a 10/90 bar, a timeline, a crashing app window, a tutorial modal, 50 buttons that
// melt (SVG goo) into one, a padlock leaking data, chips, a comment box. A 1-2-3-4 stepper is the through-line for
// the four points. Built for the vibe-coders video (IMG_3882). Crisp flat iOS colours, no glows (culture-video rules).
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "700", "800", "900"], subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });

const BLUE = "#0A84FF";
const GREEN = "#30D158";
const RED = "#FF453A";
const GOLD = "#FFD60A";
const GREY = "#8E8E93";
const TILE = "#2C2C2E";
const LINE = "rgba(255,255,255,0.14)";
const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const POP = Easing.bezier(0.3, 1.5, 0.5, 1);
const LIQUID = Easing.bezier(0.34, 1.32, 0.64, 1);   // plate size: a little overshoot, then settles like water

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const r = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const typed = (text: string, t: number, at: number, cps = 0.045) => Array.from(text).slice(0, Math.max(0, Math.floor((t - at) / cps))).join("");
const label: React.CSSProperties = { fontFamily: MONO, fontWeight: 700, fontSize: 34, letterSpacing: 3, color: "rgba(255,255,255,0.62)" };

// real platform app icons (Max, 2026-10-16: "just use the TikTok, YouTube and Instagram logo"). Glyph paths: Simple Icons (CC0).
const LOGO_PATH = {
  yt: "M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z",
  tt: "M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z",
  ig: "M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077",
};
export const AppLogo: React.FC<{ id: string; size: number }> = ({ id, size }) => {
  const g = size * 0.6, off = (size - g) / 2;
  const tile: React.CSSProperties = { width: size, height: size, borderRadius: size * 0.24, position: "relative", flexShrink: 0, overflow: "hidden",
    boxShadow: "0 6px 16px rgba(0,0,0,0.3)" };
  const glyph = (d: string, fill: string, dx = 0, dy = 0) => (
    <svg width={g} height={g} viewBox="0 0 24 24" style={{ position: "absolute", left: off + dx, top: off + dy }}><path d={d} fill={fill} /></svg>);
  if (id === "yt") return <div style={{ ...tile, background: "#fff" }}>{glyph(LOGO_PATH.yt, "#FF0033")}</div>;
  if (id === "tt") return <div style={{ ...tile, background: "#010101" }}>
    {glyph(LOGO_PATH.tt, "#25F4EE", -size * 0.025, -size * 0.025)}{glyph(LOGO_PATH.tt, "#FE2C55", size * 0.025, size * 0.025)}{glyph(LOGO_PATH.tt, "#fff")}</div>;
  if (id === "ig") return <div style={{ ...tile, background: "radial-gradient(circle at 30% 107%, #fdf497 0%, #fdf497 5%, #fd5949 45%, #d6249f 60%, #285AEB 90%)" }}>
    {glyph(LOGO_PATH.ig, "#fff")}</div>;
  return null;
};
const isLogo = (icon: string) => icon === "yt" || icon === "tt" || icon === "ig";

// odometer that rests on whole numbers (a digit only moves while every digit below it rolls over)
const Odo: React.FC<{ value: number; size: number; color?: string }> = ({ value, size, color = "#fff" }) => {
  const v = Math.max(0, value);
  const digits = String(Math.round(v)).length;
  const cols: number[] = [];
  for (let d = digits - 1; d >= 0; d--) {
    const p = Math.pow(10, d), base = Math.floor(v / p) % 10;
    cols.push(d === 0 ? base + (v - Math.floor(v)) : base + Math.max(0, (v % p) - (p - 1)));
  }
  return (
    <div style={{ display: "flex", height: size * 1.05, overflow: "hidden", color }}>
      {cols.map((c, i) => (
        <div key={i} style={{ height: size * 1.05, overflow: "hidden" }}>
          <div style={{ transform: `translateY(${-c * size * 1.05}px)` }}>
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
              <div key={j} style={{ height: size * 1.05, fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: UI, fontWeight: 900, textAlign: "center" }}>{n}</div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};

const Chip: React.FC<{ k: number; bg?: string; color?: string; size?: number; children: React.ReactNode; style?: React.CSSProperties }> =
  ({ k, bg = TILE, color = "#fff", size = 38, children, style }) => (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 10, padding: "10px 20px", borderRadius: 20, background: bg, color, fontFamily: UI,
      fontWeight: 800, fontSize: size, whiteSpace: "nowrap", opacity: Math.min(1, k * 1.5), transform: `scale(${0.6 + 0.4 * k})`, ...style }}>{children}</div>
  );

// a thin soft-white strike (Max: no thick red paint strikes)
const Strike: React.FC<{ k: number }> = ({ k }) => (
  <div style={{ position: "absolute", left: 12, right: 12, top: "50%", height: 3, borderRadius: 2, background: "rgba(255,255,255,0.95)",
    transformOrigin: "left", transform: `scaleX(${k})` }} />
);

export type VScene =
  | { kind: "coders"; hateAt: number; meAt: number }
  | { kind: "apps"; at: number; pctAt: number; trashAt: number }
  | { kind: "prompt"; typeAt: number; sendAt: number; text: string }
  | { kind: "split"; at: number }
  | { kind: "crm"; weekendAt: number; monthsAt: number; usingAt: number }
  | { kind: "ninety"; at: number; nobodyAt: number }
  | { kind: "testing"; doneAt: number; clickAt: number }
  | { kind: "design"; at: number; noOneAt: number }
  | { kind: "buttons"; at: number; n50At: number; delAt: number; hideAt: number; killAt: number }
  | { kind: "security"; openAt: number; leakAt: number; bizAt: number; liabAt: number }
  | { kind: "replaced"; at: number; strikeAt: number }
  | { kind: "compare"; lead?: string; timeAt: number; moneyAt: number; neqAt: number }
  | { kind: "final"; meAt: number; restAt: number; ticks: number[] }
  | { kind: "comment"; at: number; text: string }
  | { kind: "dot" }                                // the plate collapsed to a small dot (hand-off between beats)
  // video 014 (vibe-coding tips)
  | { kind: "versions"; at: number; landAt: number; n: number; title: string }       // version counter climbing to n, chips piling up
  | { kind: "simple"; ok: string; okAt: number; items: { text: string; at: number; strikeAt: number }[]; title?: string } // simple start ✓, then each big idea appears ON its word and gets struck
  | { kind: "installs"; items: { icon: string; title: string; sub: string; at: number }[]; title?: string }   // notification stack
  | { kind: "hours"; at: number; n: number; label: string; icon: string; dur?: number; unit?: string }                      // hours counter with an emoji chip
  | { kind: "interview"; q: { text: string; at: number; opts: string[]; pick: number; pickAt: number }[] } // AI asks multiple-choice questions
  // video 015 (AI hype vs real)
  | { kind: "buzz"; words: string[]; at: number; hypeAt: number }                          // buzzword tags flood in, then all get stamped HYPE
  | { kind: "claim"; text: string; at: number; hypeAt: number; sub?: string; subAt?: number } // a claim card, stamped HYPE + thin strike
  | { kind: "bar1090"; codeAt: number; restAt: number; chips: { text: string; at: number }[] } // code 10% vs the other 90% (named chips)
  | { kind: "follow"; name: string; tagline: string; tapAt: number }                        // follow button tapped on "follow"
  // video 016 (website ego)
  | { kind: "site"; url: string; notAt: number; careAt: number }                             // flashy scroll-animated site; "0 clients" on "not"; freezes grey on "care"
  | { kind: "timer"; q: string; qAt: number; startAt: number; goneAt: number }               // visitor's question types in, 5 s ring runs out, tab closes
  | { kind: "jobs"; title: string; items: { icon: string; text: string; at: number }[]; pretty: string; prettyAt: number; strikeAt: number } // 2 jobs ticked, "pretty" added then struck
  | { kind: "choice"; title: string; at: number; clientAt: number; egoAt: number; labels?: [string, string] }           // CLIENT | EGO toggle, knob lands on EGO
  // video 018 (lazy superpower)
  | { kind: "lazy"; lazyAt: number; hardAt: number; bothAt: number }                       // LAZY + HARD WORKER chips melt into BOTH
  | { kind: "workbar"; fillAt: number; freeAt: number }                                    // work bar fills fast, then FREE
  | { kind: "beforeafter"; label: string; icon: string; before: string; beforeAt: number; after: string; afterAt: number }
  | { kind: "extreme"; at: number; levels: string[] }                                      // meter climbing to EXTREME
  | { kind: "game"; builtAt: number; adAt: number; killAt: number }                        // ORIGINAL phone game, ad pops up, ad killed
  | { kind: "objection"; text: string; at: number }
  | { kind: "once"; rows: { label: string; value: string; at: number; good: boolean }[] }
  | { kind: "finish"; finishAt: number; meAt: number; endlessAt: number; outAt: number }
  // video 019 (Claude analytics)
  | { kind: "connect"; apps: { icon: string; name: string; at: number }[]; mergeAt: number; working: string; answer: string; answerAt: number } // app tiles flow into one Claude bubble
  | { kind: "retention"; curve: number[]; drawAt: number; dropAt: number; dropFrac: number; label: string; dropText: string }                   // real avg retention curve, drop marker
  | { kind: "ask"; prompt: string; typeAt: number; rows: { icon: string; text: string; at: number; tone: "good" | "bad" | "info" }[] } // prompt types, answer rows land
  | { kind: "dashboard"; at: number; title: string; tiles: { logo: string; value: number; unit: string; label: string }[] };                                             // one dashboard instead of three apps
// step: 0 = the four empty slots, 1-4 = that point is active (earlier ones ticked), undefined = no stepper
// scale: the whole plate is drawn at this size from its top centre (fitted per beat so it stays above his eyes)
// jump: don't glide here (the path would cross his face): the old plate shrinks away and the new one pops in at its spot
export type VState = { at: number; x: number; y: number; w: number; h: number; radius?: number; step?: number; scale?: number; bg?: string; jump?: boolean; scene: VScene };
export type VibeDef = { from: number; to: number; states: VState[]; steps: string[] };

const STEP_H = 94;

// ---------- the 1-2-3-4 stepper (the through-line of the four points) ----------
const Stepper: React.FC<{ step: number; names: string[]; t: number; at: number; w: number }> = ({ step, names, t, at, w }) => {
  const n = names.length, pw = (w - 40 - (n - 1) * 10) / n;
  return (
    <div style={{ position: "absolute", left: 20, top: 18, display: "flex", gap: 10 }}>
      {names.map((n, i) => {
        const active = step === i + 1, done = step > i + 1;
        const k = active ? r(t, at + 0.15, at + 0.5, POP) : 1;
        return (
          <div key={i} style={{ width: pw, height: 64, borderRadius: 32, display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            background: active ? GOLD : done ? "rgba(48,209,88,0.22)" : "rgba(255,255,255,0.08)", color: active ? "#1C1C1E" : done ? GREEN : "rgba(255,255,255,0.55)",
            fontFamily: UI, fontWeight: 900, fontSize: step === 0 ? 36 : 31, transform: `scale(${active ? 0.9 + 0.1 * k : 1})`, whiteSpace: "nowrap" }}>
            {done ? "✓" : `${i + 1}`}{step > 0 && <span style={{ fontWeight: 800 }}>{step >= i + 1 ? n : ""}</span>}
          </div>
        );
      })}
    </div>
  );
};

// ---------- scenes ----------
const Scene: React.FC<{ s: VScene; t: number; w: number; h: number }> = ({ s, t, w, h }) => {
  switch (s.kind) {
    case "coders": {
      // five vibe coders; they all get an angry badge on "hate", then the middle one turns gold: that's me
      const me = r(t, s.meAt, s.meAt + 0.4, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
          <div style={{ ...label, color: r(t, s.hateAt, s.hateAt + 0.3) > 0.5 ? RED : label.color }}>VIBE CODERS</div>
          <div style={{ display: "flex", gap: 22 }}>
            {[0, 1, 2, 3, 4].map((i) => {
              const a = r(t, s.hateAt - 0.6 + i * 0.07, s.hateAt - 0.3 + i * 0.07, POP);
              const mad = r(t, s.hateAt + i * 0.06, s.hateAt + 0.3 + i * 0.06, POP);
              const isMe = i === 2;
              return (
                <div key={i} style={{ position: "relative", width: 112, height: 112, borderRadius: 56, background: isMe && me > 0 ? `rgba(255,214,10,${0.25 * me})` : TILE,
                  border: `4px solid ${isMe && me > 0.5 ? GOLD : "rgba(255,255,255,0.12)"}`, display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 62, transform: `scale(${a * (isMe ? 1 + 0.16 * me : 1 - 0.06 * me)})`, opacity: isMe ? 1 : 1 - 0.45 * me }}>
                  🧑‍💻
                  {!isMe && mad > 0 && <div style={{ position: "absolute", right: -8, top: -8, fontSize: 40, transform: `scale(${mad})` }}>😤</div>}
                  {isMe && me > 0 && <div style={{ position: "absolute", bottom: -34, left: "50%", transform: `translateX(-50%) scale(${me})`, background: GOLD, color: "#1C1C1E",
                    fontFamily: UI, fontWeight: 900, fontSize: 30, padding: "4px 14px", borderRadius: 14 }}>ME</div>}
                </div>
              );
            })}
          </div>
        </div>
      );
    }
    case "apps": {
      // a week of new AI apps pours in; on "99%" all but one go grey, then they fall out of the plate into the trash
      const n = 24, cols = 8, S = 70, G = 14;
      const gw = cols * S + (cols - 1) * G;
      const shown = Math.min(n, Math.floor(Math.max(0, t - s.at) / 0.07) + 1);
      const grey = r(t, s.pctAt, s.pctAt + 0.4);
      const hue = [BLUE, "#BF5AF2", "#FF9F0A", GREEN, "#64D2FF", "#FF375F"];
      const pct = r(t, s.pctAt - 0.05, s.pctAt + 0.55, EASE_IO);
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, right: 32, top: 24, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ ...label, whiteSpace: "nowrap" }}>NEW AI APPS</div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 4, opacity: pct > 0 ? 1 : 0, transform: `scale(${0.7 + 0.3 * Math.min(1, pct * 1.5)})` }}>
              <Odo value={lerp(80, 99, pct)} size={64} color={RED} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 52, color: RED }}>% TRASH</span>
            </div>
          </div>
          <div style={{ position: "absolute", left: (w - gw) / 2, top: 112, width: gw, height: 3 * S + 2 * G }}>
            {Array.from({ length: n }, (_, i) => {
              if (i >= shown) return null;
              const a = r(t, s.at + i * 0.07, s.at + i * 0.07 + 0.25, POP);
              const keep = i === 13;
              const fall = keep ? 0 : r(t, s.trashAt + (i % 7) * 0.05, s.trashAt + 0.55 + (i % 7) * 0.05, EASE_IN);
              return (
                <div key={i} style={{ position: "absolute", left: (i % cols) * (S + G), top: Math.floor(i / cols) * (S + G), width: S, height: S, borderRadius: 18,
                  background: keep ? hue[i % hue.length] : grey > 0 ? `color-mix(in srgb, ${hue[i % hue.length]} ${100 - grey * 80}%, ${GREY})` : hue[i % hue.length],
                  display: "flex", alignItems: "center", justifyContent: "center", fontSize: 34, opacity: (keep ? 1 : 1 - grey * 0.35) * (1 - fall),
                  transform: `scale(${a * (keep ? 1 + 0.1 * grey : 1)}) translateY(${fall * 420}px) rotate(${fall * (i % 2 ? 40 : -40)}deg)` }}>✨</div>
              );
            })}
          </div>
          <div style={{ position: "absolute", left: 0, right: 0, bottom: 20, display: "flex", justifyContent: "center" }}>
            <Chip k={r(t, s.trashAt - 0.2, s.trashAt + 0.2, POP)} bg="rgba(255,69,58,0.18)" color={RED} size={34}>🗑️ TRASH</Chip>
          </div>
        </div>
      );
    }
    case "prompt": {
      // the prompt box: "one prompt" sends it and an app pops out
      const sent = r(t, s.sendAt, s.sendAt + 0.35, POP);
      const app = r(t, s.sendAt + 0.25, s.sendAt + 0.6, POP);
      const text = typed(s.text, t, s.typeAt, 0.05);
      const caret = Math.floor(t * 2.5) % 2 === 0 && t < s.sendAt;
      return (
        <div style={{ position: "absolute", inset: 0, padding: 26, boxSizing: "border-box" }}>
          <div style={{ ...label, marginBottom: 16 }}>ONE PROMPT</div>
          <div style={{ display: "flex", alignItems: "center", gap: 16, background: TILE, borderRadius: 34, padding: "18px 18px 18px 30px", border: `2px solid ${LINE}` }}>
            <div style={{ flex: 1, fontFamily: UI, fontWeight: 700, fontSize: 42, color: text ? "#fff" : "rgba(255,255,255,0.4)", whiteSpace: "nowrap", overflow: "hidden" }}>
              {text || "Ask anything…"}{caret && <span style={{ color: BLUE }}>|</span>}
            </div>
            <div style={{ width: 70, height: 70, borderRadius: 35, background: sent > 0 ? BLUE : "rgba(255,255,255,0.18)", color: "#fff", fontSize: 40, fontWeight: 900,
              display: "flex", alignItems: "center", justifyContent: "center", transform: `scale(${1 + Math.sin(Math.min(1, sent) * Math.PI) * 0.2})` }}>↑</div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 16, marginTop: 20, opacity: Math.min(1, app * 1.5), transform: `translateY(${(1 - app) * 30}px)` }}>
            <div style={{ width: 70, height: 70, borderRadius: 18, background: BLUE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 36 }}>✨</div>
            <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: "#fff" }}>Your app is ready</div>
            <Chip k={app} bg={GREEN} color="#0B2A14" size={32}>✓ BUILT</Chip>
          </div>
        </div>
      );
    }
    case "split":
    case "ninety": {
      // the job as one bar: code is 10%, the other 90% is what nobody does
      const at = s.kind === "split" ? s.at : s.at;
      const code = s.kind === "split" ? r(t, at, at + 0.6, EASE_IO) : 1;
      const rest = s.kind === "ninety" ? r(t, at, at + 0.7, EASE_IO) : 0;
      const nobody = s.kind === "ninety" ? r(t, s.nobodyAt, s.nobodyAt + 0.35, POP) : 0;
      const BW = w - 64;
      const top = s.kind === "ninety" ? STEP_H + 20 : 30;
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top, ...label }}>THE JOB</div>
          <div style={{ position: "absolute", left: 32, top: top + 48, width: BW, height: 86, borderRadius: 24, background: "rgba(255,255,255,0.06)",
            border: `2px dashed rgba(255,255,255,${0.3 - 0.2 * rest})`, overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: BW * 0.1 * code, background: BLUE }} />
            <div style={{ position: "absolute", left: BW * 0.1, top: 0, bottom: 0, width: BW * 0.9 * rest, background: GOLD }} />
            <div style={{ position: "absolute", left: BW * 0.1 + 24, top: 0, bottom: 0, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 900, fontSize: 44,
              color: rest > 0.5 ? "#1C1C1E" : "rgba(255,255,255,0.4)" }}>{rest > 0.5 ? "EVERYTHING ELSE" : "???"}</div>
          </div>
          <div style={{ position: "absolute", left: 32, top: top + 148, display: "flex", alignItems: "baseline", gap: 10, opacity: code }}>
            <Odo value={10 * code} size={58} color={BLUE} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: BLUE }}>% CODE</span>
          </div>
          {s.kind === "ninety" && (
            <div style={{ position: "absolute", right: 32, top: top + 148, display: "flex", alignItems: "baseline", gap: 10 }}>
              <Odo value={lerp(10, 90, rest)} size={58} color={GOLD} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: GOLD }}>%</span>
              {nobody > 0 && <Chip k={nobody} bg="rgba(255,69,58,0.18)" color={RED} size={32} style={{ marginLeft: 10 }}>NOBODY DOES</Chip>}
            </div>
          )}
        </div>
      );
    }
    case "crm": {
      // build: one weekend (a short bar). Adoption: three months (a long bar, days counting), then the brokers light up
      const wk = r(t, s.weekendAt, s.weekendAt + 0.5, EASE_IO);
      const mo = r(t, s.monthsAt, s.monthsAt + 2.0, EASE_IO);
      const BW = w - 64 - 210;
      const row = (name: string, k: number, frac: number, color: string, tail: React.ReactNode, y: number) => (
        <div style={{ position: "absolute", left: 32, top: y, display: "flex", alignItems: "center", gap: 18 }}>
          <div style={{ width: 192, ...label, fontSize: 24 }}>{name}</div>
          <div style={{ position: "relative", width: BW, height: 54, borderRadius: 16, background: "rgba(255,255,255,0.07)" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: BW * frac * k, borderRadius: 16, background: color }} />
            <div style={{ position: "absolute", left: Math.max(BW * frac * k + 14, 14), top: 0, bottom: 0, display: "flex", alignItems: "center", opacity: k }}>{tail}</div>
          </div>
        </div>
      );
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 24, ...label }}>MY CRM</div>
          {row("BUILD", wk, 0.06, BLUE, <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#fff" }}>1 weekend</span>, 78)}
          {row("ADOPTION", mo, 0.62, GOLD, (
            <span style={{ display: "flex", alignItems: "baseline", gap: 8, fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#fff" }}>
              <Odo value={90 * mo} size={36} /> days
            </span>), 150)}
          <div style={{ position: "absolute", left: 32, right: 32, top: 232, display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 192, ...label, fontSize: 24 }}>BROKERS</div>
            {[0, 1, 2, 3, 4, 5].map((i) => {
              const on = r(t, s.usingAt + i * 0.1, s.usingAt + 0.3 + i * 0.1, POP);
              return <div key={i} style={{ width: 62, height: 62, borderRadius: 31, background: on > 0.5 ? "rgba(48,209,88,0.25)" : "rgba(255,255,255,0.07)",
                border: `3px solid ${on > 0.5 ? GREEN : "transparent"}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 32,
                opacity: lerp(0.45, 1, mo), transform: `scale(${0.9 + 0.1 * on})`, filter: on > 0.5 ? undefined : "grayscale(1)" }}>👤</div>;
            })}
            <Chip k={r(t, s.usingAt + 0.5, s.usingAt + 0.85, POP)} bg={GREEN} color="#0B2A14" size={30}>✓ USING IT</Chip>
          </div>
        </div>
      );
    }
    case "testing": {
      // "AI says it's done" in a little app window; the cursor clicks once and everything breaks
      const msg = typed("Done! It works ✅", t, s.doneAt, 0.05);
      const cur = r(t, s.clickAt - 0.9, s.clickAt - 0.05, EASE_IO);
      const boom = r(t, s.clickAt, s.clickAt + 0.3, POP);
      const shake = t > s.clickAt && t < s.clickAt + 0.5 ? Math.sin((t - s.clickAt) * 70) * 10 * (1 - (t - s.clickAt) / 0.5) : 0;
      const WW = w - 64, WH = h - STEP_H - 44;
      return (
        <div style={{ position: "absolute", left: 32, top: STEP_H + 18, width: WW, height: WH, borderRadius: 22, background: TILE, overflow: "hidden",
          border: `2px solid ${boom > 0.5 ? RED : LINE}`, transform: `translateX(${shake}px) rotate(${boom * -1.5}deg)` }}>
          <div style={{ display: "flex", gap: 10, padding: "14px 18px", borderBottom: `2px solid ${LINE}` }}>
            {[RED, "#FF9F0A", GREEN].map((c) => <div key={c} style={{ width: 18, height: 18, borderRadius: 9, background: c }} />)}
            <div style={{ ...label, fontSize: 20, marginLeft: 12 }}>my-new-app</div>
          </div>
          <div style={{ padding: "18px 22px", display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 54, height: 54, borderRadius: 27, background: BLUE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28 }}>✨</div>
            <div style={{ background: "rgba(255,255,255,0.1)", borderRadius: 20, padding: "12px 20px", fontFamily: UI, fontWeight: 700, fontSize: 36, color: "#fff", minHeight: 44 }}>{msg || "…"}</div>
          </div>
          <div style={{ position: "absolute", right: 30, bottom: 26, padding: "14px 34px", borderRadius: 18, background: BLUE, color: "#fff", fontFamily: UI, fontWeight: 900, fontSize: 36 }}>Submit</div>
          {/* cursor arrow */}
          <svg width="46" height="56" viewBox="0 0 46 56" style={{ position: "absolute", left: lerp(WW * 0.35, WW - 130, cur), top: lerp(WH + 20, WH - 70, cur),
            transform: `scale(${t > s.clickAt && t < s.clickAt + 0.15 ? 0.85 : 1})` }}>
            <path d="M4 3 L4 46 L15 35 L23 53 L31 49 L23 32 L39 32 Z" fill="#fff" stroke="#1C1C1E" strokeWidth="3" strokeLinejoin="round" />
          </svg>
          {boom > 0 && (
            <div style={{ position: "absolute", inset: 0, background: `rgba(255,69,58,${0.85 * Math.min(1, boom)})`, display: "flex", flexDirection: "column",
              alignItems: "center", justifyContent: "center", gap: 6, opacity: Math.min(1, boom * 1.4) }}>
              <div style={{ fontSize: 70, transform: `scale(${boom})` }}>⚠️</div>
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 52, color: "#fff" }}>Everything broke</div>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, color: "rgba(255,255,255,0.85)" }}>Error 500 · after 1 click</div>
            </div>
          )}
        </div>
      );
    }
    case "design": {
      // a 47-step tutorial nobody finishes: the steps count up, then "0 users"
      const steps = r(t, s.at, s.at + 1.1, EASE_IO);
      const none = r(t, s.noOneAt, s.noOneAt + 0.35, POP);
      return (
        <div style={{ position: "absolute", left: 32, right: 32, top: STEP_H + 18, bottom: 26, borderRadius: 22, background: TILE, border: `2px solid ${LINE}`, padding: "20px 26px", boxSizing: "border-box",
          opacity: 1 - 0.35 * none }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: "#fff" }}>📘 How to use this app</div>
            <div style={{ fontSize: 34, color: GREY }}>✕</div>
          </div>
          <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 12, fontFamily: UI, fontWeight: 800, fontSize: 34, color: "rgba(255,255,255,0.7)" }}>
            Step 1 of <Odo value={47 * steps} size={36} color={GOLD} />
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 7, marginTop: 14, width: 24 * 17 }}>
            {Array.from({ length: 47 }, (_, i) => <div key={i} style={{ width: 17, height: 17, borderRadius: 9, background: i === 0 ? BLUE : "rgba(255,255,255,0.18)",
              opacity: i / 47 <= steps ? 1 : 0 }} />)}
          </div>
          {none > 0 && <div style={{ position: "absolute", right: 26, bottom: 22, transform: `scale(${none}) rotate(-4deg)` }}>
            <Chip k={1} bg={RED} size={40}>0 USERS</Chip></div>}
        </div>
      );
    }
    case "buttons": {
      // 50 buttons pop in (you delete the app); then good software melts them (SVG goo) into 3, then into 1
      const N = 50, cols = 10, BWd = 62, BH = 38, G = 9;
      const gw = cols * BWd + (cols - 1) * G, gh = 5 * BH + 4 * G;
      const ox = (w - gw) / 2, oy = STEP_H + 74;
      const count = Math.min(N, Math.floor(N * r(t, s.at, s.n50At + 0.15, Easing.linear)));   // steady pour, lands on "50"
      const del = r(t, s.delAt, s.delAt + 0.3, POP) * (1 - r(t, s.hideAt - 0.1, s.hideAt + 0.2, EASE_IN));
      const hide = r(t, s.hideAt, s.hideAt + 0.8, EASE_IO);
      const kill = r(t, s.killAt, s.killAt + 0.8, EASE_IO);
      const three = [ox + gw * 0.18, ox + gw * 0.5, ox + gw * 0.82];
      const midY = oy + gh / 2;
      const shake = t > s.delAt && t < s.delAt + 0.4 ? Math.sin((t - s.delAt) * 60) * 6 : 0;
      const shapes = Array.from({ length: N }, (_, i) => {
        const a = i < count ? r(t, s.at + (i / N) * (s.n50At - s.at), s.at + (i / N) * (s.n50At - s.at) + 0.2, POP) : 0;
        const gx = ox + (i % cols) * (BWd + G) + BWd / 2, gy = oy + Math.floor(i / cols) * (BH + G) + BH / 2;
        const tx = three[i % 3], fx = lerp(lerp(gx, tx, hide), w / 2, kill), fy = lerp(lerp(gy, midY, hide), midY, kill);
        const bw = lerp(lerp(BWd, 150, hide), 330, kill), bh = lerp(lerp(BH, 76, hide), 100, kill);
        return <rect key={i} x={fx - (bw * a) / 2 + shake} y={fy - (bh * a) / 2} width={bw * a} height={bh * a} rx={lerp(10, 26, Math.max(hide, kill))}
          fill={kill > 0 ? GREEN : hide > 0 ? BLUE : i % 7 === 3 ? "#5E5CE6" : "#48484A"} />;
      });
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, right: 32, top: STEP_H + 16, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ ...label, display: "flex", alignItems: "baseline", gap: 10 }}>
              {hide < 0.5 ? <>BUTTONS <Odo value={count} size={34} color="#fff" /></> : kill < 0.5 ? "HIDE WHAT YOU DON'T NEED" : "OR DELETE IT"}
            </div>
            {del > 0 && <Chip k={del} bg="rgba(255,69,58,0.18)" color={RED} size={30}>🗑️ UNINSTALLED</Chip>}
          </div>
          <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
            <defs>
              <filter id="goo7"><feGaussianBlur in="SourceGraphic" stdDeviation={hide > 0 && hide < 1 || kill > 0 && kill < 1 ? 9 : 0.01} result="b" />
                <feColorMatrix in="b" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 22 -10" /></filter>
            </defs>
            <g filter="url(#goo7)">{shapes}</g>
          </svg>
          {kill > 0.75 && <div style={{ position: "absolute", left: 0, right: 0, top: midY - 50, height: 100, display: "flex", alignItems: "center", justifyContent: "center",
            fontFamily: UI, fontWeight: 900, fontSize: 46, color: "#0B2A14", opacity: r(t, s.killAt + 0.6, s.killAt + 0.85) }}>Done ✓</div>}
          {hide > 0.75 && kill < 0.4 && ["Save", "Share", "Send"].map((n, i) => (
            <div key={n} style={{ position: "absolute", left: three[i] - 75, top: midY - 38, width: 150, height: 76, display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#fff", opacity: r(t, s.hideAt + 0.6, s.hideAt + 0.85) * (1 - r(t, s.killAt, s.killAt + 0.15)) }}>{n}</div>
          ))}
        </div>
      );
    }
    case "security": {
      // the padlock's shackle swings open, data leaks out, a business buys it, liability maxes out
      const open = r(t, s.openAt, s.openAt + 0.45, POP);
      const liab = r(t, s.liabAt, s.liabAt + 0.9, EASE_IO);
      const shake = liab > 0.95 && t < s.liabAt + 1.4 ? Math.sin(t * 60) * 4 : 0;
      const leaks = ["🔑 passwords", "💳 card numbers", "📇 client data"];
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <svg width="170" height="200" viewBox="0 0 170 200" style={{ position: "absolute", left: 34, top: STEP_H + 20 }}>
            <g transform={`rotate(${-38 * open} 128 92)`}>
              <path d="M42 92 V62 a43 43 0 0 1 86 0 V92" fill="none" stroke="#C7C7CC" strokeWidth="18" strokeLinecap="round" transform={`translate(0 ${-26 * open})`} />
            </g>
            <rect x="20" y="88" width="130" height="104" rx="22" fill={open > 0.5 ? RED : GOLD} />
            <circle cx="85" cy="132" r="13" fill="#1C1C1E" /><rect x="79" y="136" width="12" height="28" rx="6" fill="#1C1C1E" />
          </svg>
          <div style={{ position: "absolute", left: 230, top: STEP_H + 22, display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start" }}>
            {leaks.map((l, i) => {
              // locked inside (faint) until the door opens, then they slide out bright: the plate is never empty
              const a = r(t, s.leakAt + i * 0.22, s.leakAt + 0.4 + i * 0.22, POP);
              return <div key={l} style={{ transform: `translateX(${a * 40}px)`, opacity: 0.32 + 0.68 * Math.min(1, a) }}>
                <Chip k={1} size={30} bg={a > 0.5 ? TILE : "rgba(255,255,255,0.06)"}>{l}</Chip></div>;
            })}
          </div>
          <div style={{ position: "absolute", left: 34, right: 34, bottom: 26, display: "flex", alignItems: "center", gap: 16, transform: `translateX(${shake}px)` }}>
            <Chip k={r(t, s.bizAt, s.bizAt + 0.35, POP)} size={30} bg="rgba(255,255,255,0.1)">🏢 BUSINESS</Chip>
            <div style={{ ...label, fontSize: 22, opacity: r(t, s.liabAt - 0.3, s.liabAt) }}>LIABILITY</div>
            <div style={{ flex: 1, height: 40, borderRadius: 20, background: "rgba(255,255,255,0.08)", overflow: "hidden", opacity: r(t, s.liabAt - 0.3, s.liabAt) }}>
              <div style={{ width: `${liab * 100}%`, height: "100%", background: `linear-gradient(90deg, ${GOLD}, ${RED})`, borderRadius: 20 }} />
            </div>
            {liab > 0.9 && <Chip k={r(t, s.liabAt + 0.8, s.liabAt + 1.1, POP)} bg={RED} size={30}>HUGE</Chip>}
          </div>
        </div>
      );
    }
    case "replaced": {
      const st = r(t, s.strikeAt, s.strikeAt + 0.3, EASE_IO);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 18 }}>
          <Chip k={r(t, s.at, s.at + 0.35, POP)} size={42}>👩‍💻 Good developers</Chip>
          <div style={{ position: "relative" }}>
            <Chip k={r(t, s.at + 0.25, s.at + 0.6, POP)} size={42} bg="rgba(255,69,58,0.2)" color={st > 0.5 ? "rgba(255,255,255,0.45)" : RED}>REPLACED</Chip>
            <Strike k={st} />
          </div>
        </div>
      );
    }
    case "compare": {
      const neq = r(t, s.neqAt, s.neqAt + 0.4, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 24, paddingTop: s.lead ? 40 : 0 }}>
          {s.lead && <div style={{ position: "absolute", left: 32, top: 22, ...label }}>{s.lead}</div>}
          <div style={{ display: "flex", flexDirection: "column", gap: 12, alignItems: "flex-start" }}>
            <Chip k={r(t, s.timeAt, s.timeAt + 0.35, POP)} bg="rgba(48,209,88,0.2)" color={GREEN} size={38}>⏱ saves time</Chip>
            <Chip k={r(t, s.moneyAt, s.moneyAt + 0.35, POP)} bg="rgba(48,209,88,0.2)" color={GREEN} size={38}>💰 makes money</Chip>
          </div>
          <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 96, color: "#fff", opacity: neq, transform: `scale(${0.5 + 0.5 * neq})` }}>≠</div>
          <Chip k={neq} size={38} bg="rgba(255,255,255,0.08)" color="rgba(255,255,255,0.75)">✍️ a prompt</Chip>
        </div>
      );
    }
    case "final": {
      // bookend: me again, and the 90% fills with the four points ticked
      const me = r(t, s.meAt, s.meAt + 0.4, POP);
      const rest = r(t, s.restAt, s.restAt + 0.7, EASE_IO);
      const BW = w - 64 - 140;
      const names = ["Testing", "Design", "Deleting", "Security"];
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 30, width: 112, height: 112, borderRadius: 56, background: "rgba(255,214,10,0.25)", border: `4px solid ${GOLD}`,
            display: "flex", alignItems: "center", justifyContent: "center", fontSize: 60, transform: `scale(${me})` }}>🧑‍💻</div>
          <div style={{ position: "absolute", left: 170, top: 44, width: BW, height: 84, borderRadius: 24, background: "rgba(255,255,255,0.06)", overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: BW * 0.1, background: BLUE }} />
            <div style={{ position: "absolute", left: BW * 0.1, top: 0, bottom: 0, width: BW * 0.9 * rest, background: GOLD }} />
            <div style={{ position: "absolute", left: BW * 0.1 + 22, top: 0, bottom: 0, display: "flex", alignItems: "center", fontFamily: UI, fontWeight: 900, fontSize: 40,
              color: "#1C1C1E", opacity: rest }}>THE OTHER 90%</div>
          </div>
          <div style={{ position: "absolute", left: 32, right: 32, top: 168, display: "flex", gap: 12, justifyContent: "space-between" }}>
            {names.map((n, i) => {
              const a = r(t, s.ticks[i], s.ticks[i] + 0.3, POP);
              return <Chip key={n} k={a} bg="rgba(48,209,88,0.2)" color={GREEN} size={32}>✓ {n}</Chip>;
            })}
          </div>
        </div>
      );
    }
    case "comment": {
      const txt = typed(s.text, t, s.at, 0.045);
      const caret = Math.floor(t * 2.5) % 2 === 0;
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 18, padding: "0 22px" }}>
          <div style={{ width: 84, height: 84, borderRadius: 42, background: GOLD, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 46, flexShrink: 0 }}>💬</div>
          <div style={{ flex: 1, fontFamily: UI, fontWeight: 700, fontSize: 52, color: txt ? "#fff" : "rgba(255,255,255,0.45)", whiteSpace: "nowrap", overflow: "hidden" }}>
            {txt || "Add comment…"}{caret && <span style={{ color: GOLD }}>|</span>}</div>
          <div style={{ width: 76, height: 76, borderRadius: 38, background: BLUE, color: "#fff", fontSize: 40, fontWeight: 900, display: "flex", alignItems: "center",
            justifyContent: "center", flexShrink: 0 }}>↑</div>
        </div>
      );
    }
    case "versions": {
      // "37 versions": the version number climbs while small version chips pile up behind; lands green on the last one
      const p = r(t, s.at, s.landAt, Easing.linear);
      const v = Math.max(1, Math.round(1 + (s.n - 1) * p));
      const done = r(t, s.landAt, s.landAt + 0.35, POP);
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 26, ...label }}>{s.title}</div>
          <div style={{ position: "absolute", left: 32, right: 32, top: 80, height: 76, display: "flex", flexWrap: "wrap", gap: 8, alignContent: "flex-start", overflow: "hidden" }}>
            {Array.from({ length: v }, (_, i) => (
              <div key={i} style={{ width: 52, height: 30, borderRadius: 9, background: i === s.n - 1 && done > 0.5 ? GREEN : "rgba(255,255,255,0.12)",
                color: i === s.n - 1 && done > 0.5 ? "#0B2A14" : "rgba(255,255,255,0.6)", fontFamily: MONO, fontWeight: 700, fontSize: 16, display: "flex",
                alignItems: "center", justifyContent: "center" }}>v{i + 1}</div>
            ))}
          </div>
          <div style={{ position: "absolute", left: 32, right: 32, bottom: 22, display: "flex", alignItems: "baseline", justifyContent: "space-between" }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
              <Odo value={1 + (s.n - 1) * p} size={124} color={done > 0.5 ? GREEN : "#fff"} />
              <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 54, color: "rgba(255,255,255,0.75)" }}>{1 + (s.n - 1) * p < 1.5 ? "version" : "versions"}</span>
            </div>
            {done > 0 && <Chip k={done} bg={GREEN} color="#0B2A14" size={46}>✓ WORKS</Chip>}
          </div>
        </div>
      );
    }
    case "simple": {
      // the big first projects get a thin strike (no red paint), then the simple one lands green
      const ok = r(t, s.okAt, s.okAt + 0.35, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
          {t < s.okAt - 0.02 && <div style={{ ...label, fontSize: 40, color: "rgba(255,255,255,0.8)" }}>{s.title ?? "YOUR FIRST APP"}</div>}
          {t >= s.okAt - 0.02 && <div style={{ opacity: Math.min(1, ok * 1.5), transform: `translateY(${(1 - ok) * 20}px)` }}>
            <Chip k={ok} size={56} bg={GREEN} color="#0B2A14">{s.ok}</Chip>
          </div>}
          <div style={{ display: "flex", gap: 14 }}>
            {s.items.filter((it) => t >= it.at - 0.02).map((it) => {
              const a = r(t, it.at, it.at + 0.3, POP);
              const st = r(t, it.strikeAt, it.strikeAt + 0.3, EASE_IO);
              return (
                <div key={it.text} style={{ position: "relative", transform: `scale(${(0.7 + 0.3 * a) * (1 - 0.06 * st)})`, opacity: Math.min(1, a * 1.5) * (1 - 0.5 * st) }}>
                  <Chip k={1} size={48} bg="rgba(255,255,255,0.1)">{it.text}</Chip>
                  <Strike k={st} />
                </div>
              );
            })}
          </div>
        </div>
      );
    }
    case "installs":
      // iOS-style notification cards stacking down, newest on top of the pile
      return (
        <div style={{ position: "absolute", left: 26, right: 26, top: 18, display: "flex", flexDirection: "column", gap: 12 }}>
          {s.title && <div style={{ ...label, marginBottom: 2 }}>{s.title}</div>}
          {s.items.map((it, i) => {
            const a = r(t, it.at, it.at + 0.35, POP);
            if (t < it.at - 0.02) return null;
            return (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 18, padding: "14px 20px", borderRadius: 24, background: "rgba(255,255,255,0.1)",
                border: `1.5px solid ${LINE}`, opacity: Math.min(1, a * 1.4), transform: `translateY(${(1 - a) * -26}px) scale(${0.92 + 0.08 * a})` }}>
                {isLogo(it.icon) ? <AppLogo id={it.icon} size={76} /> :
                  <div style={{ width: 76, height: 76, borderRadius: 18, background: "#F2F2F7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 44 }}>{it.icon}</div>}
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 46, color: "#fff", lineHeight: 1.1 }}>{it.title}</div>
                  <div style={{ fontFamily: UI, fontWeight: 500, fontSize: 32, color: "rgba(255,255,255,0.65)" }}>{it.sub}</div>
                </div>
                <div style={{ fontSize: 44, color: GREEN, fontWeight: 900 }}>✓</div>
              </div>
            );
          })}
        </div>
      );
    case "hours": {
      const p = r(t, s.at, s.at + (s.dur ?? 1.6), EASE_IO);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 26 }}>
          <div style={{ width: 120, height: 120, borderRadius: 30, background: "#F2F2F7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 70 }}>{s.icon}</div>
          <div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
              <Odo value={s.n * p} size={124} color={GOLD} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 56, color: GOLD }}>{s.unit ?? "+ hours"}</span>
            </div>
            <div style={{ ...label, marginTop: 4 }}>{s.label}</div>
          </div>
        </div>
      );
    }
    case "interview":
      // the AI interviews you: question bubble, multiple-choice chips, one gets tapped
      return (
        <div style={{ position: "absolute", left: 26, right: 26, top: 22, display: "flex", flexDirection: "column", gap: 14 }}>
          {s.q.map((q, qi) => {
            if (t < q.at - 0.02) return null;
            const a = r(t, q.at, q.at + 0.3, POP);
            const tap = r(t, q.pickAt, q.pickAt + 0.3, POP);
            const old = s.q.slice(qi + 1).some((n) => t >= n.at);
            if (old) return null;   // one question at a time (Max wants big, readable graphics)
            return (
              <div key={qi} style={{ opacity: old ? 0.45 : 1, transform: `scale(${old ? 0.94 : 1})`, transformOrigin: "0% 0%" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 14, opacity: Math.min(1, a * 1.4), transform: `translateY(${(1 - a) * 18}px)` }}>
                  <div style={{ width: 64, height: 64, borderRadius: 32, background: BLUE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 34 }}>✨</div>
                  <div style={{ background: "rgba(255,255,255,0.12)", borderRadius: "28px 28px 28px 10px", padding: "12px 26px", fontFamily: UI, fontWeight: 800, fontSize: 48, color: "#fff" }}>{q.text}</div>
                </div>
                <div style={{ display: "flex", gap: 12, marginTop: 14, marginLeft: 78 }}>
                  {q.opts.map((o, oi) => {
                    const oa = r(t, q.at + 0.25 + oi * 0.12, q.at + 0.5 + oi * 0.12, POP);
                    const picked = oi === q.pick && tap > 0;
                    return (
                      <div key={o} style={{ padding: "10px 24px", borderRadius: 20, fontFamily: UI, fontWeight: 800, fontSize: 40,
                        background: picked ? BLUE : "rgba(255,255,255,0.08)", color: "#fff", border: `2px solid ${picked ? BLUE : LINE}`,
                        opacity: Math.min(1, oa * 1.4) * (tap > 0.5 && !picked ? 0.45 : 1), transform: `scale(${(0.8 + 0.2 * oa) * (picked ? 1 + 0.06 * Math.sin(Math.min(1, tap) * Math.PI) : 1)})` }}>
                        <span style={{ fontFamily: MONO, opacity: 0.7, marginRight: 8 }}>{String.fromCharCode(65 + oi)}</span>{o}
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      );
    case "buzz": {
      // buzzword tags pour in fast; on "just hype" they all dim and one red HYPE stamp lands across them
      const hype = r(t, s.hypeAt, s.hypeAt + 0.3, POP);
      return (
        <div style={{ position: "absolute", inset: 0, padding: "22px 26px", boxSizing: "border-box" }}>
          <div style={{ ...label, marginBottom: 14 }}>ALL THE AI STUFF</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
            {s.words.map((w, i) => {
              const a = r(t, s.at + i * 0.16, s.at + i * 0.16 + 0.25, POP);
              if (t < s.at + i * 0.16) return null;
              return <div key={w} style={{ padding: "8px 18px", borderRadius: 16, background: "rgba(255,255,255,0.1)", fontFamily: UI, fontWeight: 800,
                fontSize: 36, color: "#fff", opacity: Math.min(1, a * 1.5) * (1 - 0.6 * hype), transform: `scale(${0.7 + 0.3 * a})` }}>{w}</div>;
            })}
          </div>
          {hype > 0 && <div style={{ position: "absolute", left: "50%", top: "58%", transform: `translate(-50%,-50%) rotate(-8deg) scale(${2 - hype})`, opacity: Math.min(1, hype * 2),
            border: `6px solid ${RED}`, borderRadius: 18, padding: "4px 30px", fontFamily: UI, fontWeight: 900, fontSize: 92, color: RED, letterSpacing: 4,
            background: "rgba(22,22,24,0.85)" }}>HYPE</div>}
        </div>
      );
    }
    case "claim": {
      // the claim, then (on its own row, never over the text) a flat rubber-stamp HYPE + the reason; thin strike on the claim
      const a = r(t, s.at, s.at + 0.35, POP);
      const hype = r(t, s.hypeAt, s.hypeAt + 0.3, POP);
      const st = r(t, s.hypeAt + 0.1, s.hypeAt + 0.4, EASE_IO);
      const sub = s.subAt !== undefined ? r(t, s.subAt, s.subAt + 0.35, POP) : 0;
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, padding: "0 30px" }}>
          <div style={{ position: "relative", opacity: Math.min(1, a * 1.5) * (1 - 0.45 * st), transform: `scale(${0.9 + 0.1 * a})` }}>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 52, color: "#fff", textAlign: "center", lineHeight: 1.12, letterSpacing: -0.5 }}>“{s.text}”</div>
            <Strike k={st} />
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 16, minHeight: 74 }}>
            {hype > 0 && <div style={{ transform: `rotate(-6deg) scale(${2 - hype})`, opacity: Math.min(1, hype * 2), border: `5px solid ${RED}`, borderRadius: 14,
              padding: "0 18px", fontFamily: UI, fontWeight: 900, fontSize: 54, color: RED, letterSpacing: 3, lineHeight: 1.25 }}>HYPE</div>}
            {s.sub && sub > 0 && <Chip k={sub} size={36} bg="rgba(255,255,255,0.1)" color="rgba(255,255,255,0.9)">{s.sub}</Chip>}
          </div>
        </div>
      );
    }
    case "bar1090": {
      // the job as a bar: code fills 10%, then the other 90% fills as he names testing, design, security
      const code = r(t, s.codeAt, s.codeAt + 0.5, EASE_IO);
      const rest = r(t, s.restAt, s.restAt + 0.7, EASE_IO);
      const BW = w - 64;
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 20, display: "flex", gap: 30, alignItems: "baseline" }}>
            <span style={{ display: "flex", alignItems: "baseline", gap: 6 }}><Odo value={10 * code} size={64} color={BLUE} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: BLUE }}>% code</span></span>
            {rest > 0 && <span style={{ display: "flex", alignItems: "baseline", gap: 6 }}><Odo value={10 + 80 * rest} size={64} color={GOLD} /><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: GOLD }}>% everything else</span></span>}
          </div>
          <div style={{ position: "absolute", left: 32, top: 104, width: BW, height: 64, borderRadius: 20, background: "rgba(255,255,255,0.07)", overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: BW * 0.1 * code, background: BLUE }} />
            <div style={{ position: "absolute", left: BW * 0.1, top: 0, bottom: 0, width: BW * 0.9 * rest, background: GOLD }} />
          </div>
          <div style={{ position: "absolute", left: 32, right: 32, top: 190, display: "flex", gap: 12, flexWrap: "wrap" }}>
            {s.chips.filter((c) => t >= c.at - 0.02).map((c) => <Chip key={c.text} k={r(t, c.at, c.at + 0.3, POP)} size={40} bg="rgba(255,214,10,0.18)" color={GOLD}>{c.text}</Chip>)}
          </div>
        </div>
      );
    }
    case "follow": {
      const tap = r(t, s.tapAt, s.tapAt + 0.3, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 22, padding: "0 28px" }}>
          <div style={{ width: 100, height: 100, borderRadius: 50, background: BLUE, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 900, fontSize: 52, color: "#fff", flexShrink: 0 }}>{s.name[0]}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 50, color: "#fff" }}>{s.name}</div>
            <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 34, color: "rgba(255,255,255,0.7)" }}>{s.tagline}</div>
          </div>
          <div style={{ padding: "16px 34px", borderRadius: 22, fontFamily: UI, fontWeight: 900, fontSize: 42, flexShrink: 0,
            background: tap > 0.5 ? "rgba(255,255,255,0.14)" : RED, color: "#fff", transform: `scale(${1 + Math.sin(Math.min(1, tap) * Math.PI) * 0.12})` }}>{tap > 0.5 ? "Following ✓" : "Follow"}</div>
        </div>
      );
    }
    case "site": {
      // a mini browser: abstract hero blocks that keep sliding/parallaxing (the "scroll animation"); a clients bar reads 0 on "not";
      // on "care" the whole show freezes and turns grey
      const care = r(t, s.careAt, s.careAt + 0.5, EASE_IO);
      const tt = care > 0 ? lerp(t, s.careAt, care) : t;            // the animation slows to a stop
      const zero = r(t, s.notAt, s.notAt + 0.35, POP);
      const BH = h - 70 - 86;                                         // viewport height between the url bar and the clients bar
      const scroll = (tt * 70) % 240;
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 70, display: "flex", alignItems: "center", gap: 10, padding: "0 24px", borderBottom: `1.5px solid ${LINE}` }}>
            {[RED, GOLD, GREEN].map((c) => <div key={c} style={{ width: 18, height: 18, borderRadius: 9, background: c }} />)}
            <div style={{ marginLeft: 16, flex: 1, height: 42, borderRadius: 21, background: "rgba(255,255,255,0.08)", display: "flex", alignItems: "center", padding: "0 20px",
              fontFamily: MONO, fontWeight: 500, fontSize: 28, color: "rgba(255,255,255,0.7)" }}>🔒 {s.url}</div>
          </div>
          <div style={{ position: "absolute", left: 0, right: 0, top: 70, height: BH, overflow: "hidden", filter: `grayscale(${care})`, opacity: 1 - 0.45 * care }}>
            <div style={{ position: "absolute", inset: 0, transform: `translateY(${-scroll}px)` }}>
              {[0, 1, 2].map((k) => (
                <div key={k} style={{ position: "absolute", left: 0, right: 0, top: k * 240, height: 240 }}>
                  <div style={{ position: "absolute", left: 36, top: 34, width: 360 + 80 * Math.sin(tt * 2 + k), height: 46, borderRadius: 12, background: "#fff" }} />
                  <div style={{ position: "absolute", left: 36, top: 96, width: 250, height: 22, borderRadius: 8, background: "rgba(255,255,255,0.35)" }} />
                  <div style={{ position: "absolute", left: 36, top: 140, width: 170, height: 52, borderRadius: 26, background: BLUE }} />
                  <div style={{ position: "absolute", right: 60 + 30 * Math.sin(tt * 1.6 + k), top: 30 + 20 * Math.cos(tt * 1.3 + k), width: 170, height: 170, borderRadius: 85,
                    background: `conic-gradient(from ${tt * 140 + k * 60}deg, ${BLUE}, #BF5AF2, ${GOLD}, ${BLUE})` }} />
                  <div style={{ position: "absolute", right: 250 + 40 * Math.sin(tt * 2.2 + k), top: 150, width: 90, height: 60, borderRadius: 16, background: "#BF5AF2",
                    transform: `rotate(${tt * 90 + k * 40}deg)` }} />
                </div>
              ))}
            </div>
          </div>
          <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 86, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px",
            borderTop: `1.5px solid ${LINE}`, background: "rgba(22,22,24,0.96)" }}>
            <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: "#fff" }}>New clients</div>
            {zero > 0 && <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 58, color: RED, opacity: Math.min(1, zero * 1.5), transform: `scale(${0.6 + 0.4 * zero})` }}>0</div>}
          </div>
        </div>
      );
    }
    case "timer": {
      // the visitor's question types in; the 5 s ring drains on "5 seconds"; on "gone" it turns red and the tab closes
      const left = 5 * (1 - r(t, s.startAt, s.goneAt, Easing.linear));
      const gone = r(t, s.goneAt, s.goneAt + 0.35, POP);
      const run = t >= s.startAt - 0.02;
      const R = 74, C = 2 * Math.PI * R;
      const txt = typed(s.q, t, s.qAt, 0.04);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 30, padding: "0 34px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 16 }}>
            <div style={{ ...label }}>YOUR VISITOR</div>
            <div style={{ alignSelf: "flex-start", maxWidth: "100%", padding: "16px 24px", borderRadius: "28px 28px 28px 8px", background: "rgba(255,255,255,0.12)",
              fontFamily: UI, fontWeight: 800, fontSize: 44, color: "#fff", lineHeight: 1.15, minHeight: 52 }}>{txt}{txt.length < s.q.length && <span style={{ color: GOLD }}>|</span>}</div>
            {gone > 0 && <Chip k={gone} size={38} bg="rgba(255,69,58,0.18)" color={RED} style={{ alignSelf: "flex-start" }}>✕ Tab closed</Chip>}
          </div>
          <div style={{ position: "relative", width: 2 * R + 24, height: 2 * R + 24, flexShrink: 0, opacity: run ? 1 : 0.35 }}>
            <svg width={2 * R + 24} height={2 * R + 24} style={{ position: "absolute", inset: 0, transform: "rotate(-90deg)" }}>
              <circle cx={R + 12} cy={R + 12} r={R} fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth={14} />
              <circle cx={R + 12} cy={R + 12} r={R} fill="none" stroke={gone > 0.3 ? RED : GOLD} strokeWidth={14} strokeLinecap="round"
                strokeDasharray={C} strokeDashoffset={C * (1 - left / 5)} />
            </svg>
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 900, fontSize: 76,
              color: gone > 0.3 ? RED : "#fff" }}>{Math.ceil(left - 0.001)}<span style={{ fontSize: 40, fontWeight: 800, marginLeft: 2 }}>s</span></div>
          </div>
        </div>
      );
    }
    case "jobs": {
      // checklist: each job lands with a green tick on its word; then "pretty" joins the list greyed out and gets struck
      const rowsK = s.items.map((it) => r(t, it.at, it.at + 0.35, POP));
      const pk = r(t, s.prettyAt, s.prettyAt + 0.35, POP);
      const st = r(t, s.strikeAt, s.strikeAt + 0.35, EASE_IO);
      const row = (icon: string, text: string, k: number, mark: React.ReactNode, dim = 0, strike = 0) => (
        <div style={{ display: "flex", alignItems: "center", gap: 18, padding: "12px 20px", borderRadius: 22, background: "rgba(255,255,255,0.08)", border: `1.5px solid ${LINE}`,
          opacity: Math.min(1, k * 1.5) * (1 - 0.45 * dim), transform: `translateY(${(1 - k) * 18}px) scale(${0.94 + 0.06 * k})` }}>
          <div style={{ width: 64, height: 64, borderRadius: 16, background: "#F2F2F7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 38, flexShrink: 0 }}>{icon}</div>
          <div style={{ position: "relative", flex: 1, fontFamily: UI, fontWeight: 800, fontSize: 46, color: "#fff", whiteSpace: "nowrap" }}>{text}<Strike k={strike} /></div>
          <div style={{ fontSize: 46, fontWeight: 900, flexShrink: 0 }}>{mark}</div>
        </div>
      );
      return (
        <div style={{ position: "absolute", left: 26, right: 26, top: 22, display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ ...label, marginBottom: 2 }}>{s.title}</div>
          {s.items.map((it, i) => t >= it.at - 0.02 ? <React.Fragment key={i}>{row(it.icon, it.text, rowsK[i], <span style={{ color: GREEN }}>✓</span>)}</React.Fragment> : null)}
          {t >= s.prettyAt - 0.02 && row("✨", s.pretty, pk, st > 0.5 ? <span style={{ color: RED }}>✕</span> : null, st, st)}
        </div>
      );
    }
    case "choice": {
      // a two-way toggle: the knob sits on CLIENT when he says "client", then slides over to EGO on "ego"
      const a = r(t, s.at, s.at + 0.35, POP);
      const c = r(t, s.clientAt, s.clientAt + 0.3, POP);
      const e = r(t, s.egoAt, s.egoAt + 0.45, LIQUID);
      const TW = w - 68, half = (TW - 16) / 2;
      const knobX = 8 + half * Math.min(1, e);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", justifyContent: "center", gap: 20, padding: "0 34px", opacity: Math.min(1, a * 1.5) }}>
          <div style={{ ...label, textAlign: "center" }}>{s.title}</div>
          <div style={{ position: "relative", width: TW, height: 120, borderRadius: 60, background: "rgba(255,255,255,0.08)", border: `1.5px solid ${LINE}` }}>
            {c > 0 && <div style={{ position: "absolute", left: knobX, top: 8, width: half, height: 104, borderRadius: 52, background: e > 0.5 ? GOLD : GREEN,
              opacity: Math.min(1, c * 1.5), transform: `scale(${0.85 + 0.15 * c})` }} />}
            {([[s.labels?.[0] ?? "CLIENT", e <= 0.5 && c > 0.5], [s.labels?.[1] ?? "EGO", e > 0.5]] as [string, boolean][]).map(([tx, on], i) => (
              <div key={i} style={{ position: "absolute", left: 8 + i * half, top: 8, width: half, height: 104, display: "flex", alignItems: "center", justifyContent: "center",
                fontFamily: UI, fontWeight: 900, fontSize: 58, letterSpacing: 1, color: on ? "#1C1C1E" : "rgba(255,255,255,0.75)" }}>{tx}</div>
            ))}
          </div>
        </div>
      );
    }
    case "lazy": {
      // two opposite labels land on their words, then melt together into one chip: BOTH
      const l = r(t, s.lazyAt, s.lazyAt + 0.3, POP), h2 = r(t, s.hardAt, s.hardAt + 0.3, POP);
      const m = r(t, s.bothAt, s.bothAt + 0.6, EASE_IO), both = r(t, s.bothAt + 0.35, s.bothAt + 0.7, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {both < 0.9 && <div style={{ display: "flex", gap: lerp(30, -60, m), opacity: 1 - both }}>
            {t >= s.lazyAt - 0.02 && <Chip k={l} size={58} bg="rgba(255,255,255,0.12)">😴 LAZY</Chip>}
            {t >= s.hardAt - 0.02 && <Chip k={h2} size={58} bg={GOLD} color="#1C1C1E">💪 HARD WORKER</Chip>}
          </div>}
          {both > 0 && <div style={{ position: "absolute" }}><Chip k={both} size={66} bg={GREEN} color="#0B2A14">BOTH</Chip></div>}
        </div>
      );
    }
    case "workbar": {
      const f = r(t, s.fillAt, s.fillAt + 1.6, EASE_IO), free = r(t, s.freeAt, s.freeAt + 0.35, POP);
      const BW = w - 64;
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 26, ...label }}>WORK</div>
          <div style={{ position: "absolute", left: 32, top: 82, width: BW, height: 70, borderRadius: 22, background: "rgba(255,255,255,0.08)", overflow: "hidden" }}>
            <div style={{ width: `${f * 100}%`, height: "100%", background: GOLD, borderRadius: 22 }} />
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", paddingLeft: 26, fontFamily: UI, fontWeight: 900, fontSize: 40, color: "#1C1C1E" }}>{f > 0.15 ? "as hard as possible" : ""}</div>
          </div>
          <div style={{ position: "absolute", left: 0, right: 0, top: 176, display: "flex", justifyContent: "center" }}>
            {free > 0 && <Chip k={free} size={54} bg={GREEN} color="#0B2A14">✓ DONE · FREE</Chip>}
          </div>
        </div>
      );
    }
    case "beforeafter": {
      const b = r(t, s.beforeAt, s.beforeAt + 0.3, POP), a2 = r(t, s.afterAt, s.afterAt + 0.35, POP);
      const st = r(t, s.afterAt - 0.1, s.afterAt + 0.2, EASE_IO);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 22 }}>
          <div style={{ width: 120, height: 120, borderRadius: 30, background: "#F2F2F7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 70 }}>{s.icon}</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <div style={{ ...label }}>{s.label}</div>
            <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
              {t >= s.beforeAt - 0.02 && <div style={{ position: "relative", opacity: 1 - 0.5 * st }}><Chip k={b} size={58} bg="rgba(255,255,255,0.1)">{s.before}</Chip><Strike k={st} /></div>}
              {a2 > 0 && <><span style={{ fontFamily: UI, fontWeight: 900, fontSize: 52, color: "rgba(255,255,255,0.6)" }}>→</span><Chip k={a2} size={62} bg={GREEN} color="#0B2A14">{s.after}</Chip></>}
            </div>
          </div>
        </div>
      );
    }
    case "extreme": {
      const p = r(t, s.at - 0.9, s.at + 0.1, EASE_IN);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 34px", gap: 14 }}>
          <div style={{ display: "flex", gap: 12 }}>
            {s.levels.map((lv, i) => {
              const on = p > (i + 0.5) / s.levels.length;
              const last = i === s.levels.length - 1;
              const col = last ? RED : i === 1 ? "#FF9F0A" : GOLD;
              return <div key={lv} style={{ flex: 1, height: 78, borderRadius: 20, background: on ? col : "rgba(255,255,255,0.08)", display: "flex", alignItems: "center",
                justifyContent: "center", fontFamily: UI, fontWeight: 900, fontSize: last ? 44 : 36, color: on ? "#1C1C1E" : "rgba(255,255,255,0.45)",
                transform: `scale(${on && last ? 1 + 0.06 * Math.sin(t * 9) : 1})` }}>{lv}</div>;
            })}
          </div>
        </div>
      );
    }
    case "game": {
      // an ORIGINAL simple game (falling coloured blocks; no real game, logo or art); an ad covers it, then gets killed for good
      const ad = r(t, s.adAt, s.adAt + 0.3, POP), kill = r(t, s.killAt, s.killAt + 0.35, EASE_IN);
      const built = r(t, s.builtAt, s.builtAt + 0.4, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 34 }}>
          <div style={{ position: "relative", width: 180, height: 300, borderRadius: 34, background: "#111", border: "6px solid #3A3A3C", overflow: "hidden", transform: `scale(${0.8 + 0.2 * built})` }}>
            {[0, 1, 2, 3, 4, 5].map((i) => {
              const y = ((t * 120 + i * 60) % 330) - 30;
              return <div key={i} style={{ position: "absolute", left: 20 + (i % 3) * 48, top: y, width: 40, height: 40, borderRadius: 10, background: [BLUE, GREEN, GOLD, "#BF5AF2", RED, "#64D2FF"][i] }} />;
            })}
            {ad > 0 && kill < 1 && <div style={{ position: "absolute", inset: 0, background: "rgba(255,255,255,0.97)", display: "flex", flexDirection: "column", alignItems: "center",
              justifyContent: "center", gap: 8, opacity: Math.min(1, ad * 1.5) * (1 - kill), transform: `translateY(${(1 - ad) * 60 - kill * 320}px)` }}>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 22, color: "#8E8E93" }}>AD · 0:30</div>
              <div style={{ fontSize: 40 }}>📺</div>
            </div>}
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 14, alignItems: "flex-start" }}>
            <div style={{ ...label }}>MY OWN VERSION</div>
            {kill > 0 ? <Chip k={kill} size={58} bg={GREEN} color="#0B2A14">ADS: 0</Chip> : <Chip k={1} size={46} bg="rgba(255,255,255,0.1)">🎮 my game</Chip>}
          </div>
        </div>
      );
    }
    case "objection": {
      const a2 = r(t, s.at, s.at + 0.35, POP);
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {t >= s.at - 0.02 && <Chip k={a2} size={60} bg="rgba(255,255,255,0.12)">{s.text}</Chip>}
        </div>
      );
    }
    case "once":
      return (
        <div style={{ position: "absolute", left: 32, right: 32, top: 0, bottom: 0, display: "flex", flexDirection: "column", justifyContent: "center", gap: 14 }}>
          {s.rows.filter((rw) => t >= rw.at - 0.02).map((rw) => {
            const a2 = r(t, rw.at, rw.at + 0.35, POP);
            return (
              <div key={rw.label} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 24px", borderRadius: 22, background: "rgba(255,255,255,0.08)",
                opacity: Math.min(1, a2 * 1.5), transform: `translateX(${(1 - a2) * -40}px)` }}>
                <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 44, color: "#fff" }}>{rw.label}</span>
                <Chip k={1} size={44} bg={rw.good ? GREEN : GOLD} color="#1C1C1E">{rw.value}</Chip>
              </div>
            );
          })}
        </div>
      );
    case "finish": {
      const f = r(t, s.finishAt, s.finishAt + 0.35, POP), me = r(t, s.meAt, s.meAt + 0.35, POP);
      const en = r(t, s.endlessAt, s.endlessAt + 0.35, POP), out = r(t, s.outAt, s.outAt + 0.35, POP);
      const col = (k: number, icon: string, title: string, chip: React.ReactNode, show: boolean) => (
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 12, opacity: show ? Math.min(1, k * 1.5) : 0, transform: `scale(${0.85 + 0.15 * k})` }}>
          <div style={{ fontSize: 80 }}>{icon}</div>
          <div style={{ ...label, fontSize: 32 }}>{title}</div>
          {chip}
        </div>
      );
      return (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", padding: "0 20px", gap: 10 }}>
          {col(f, "🏁", "FINISH LINE", me > 0 ? <Chip k={me} size={44} bg={GREEN} color="#0B2A14">nobody outworks me</Chip> : null, t >= s.finishAt - 0.02)}
          <div style={{ width: 2, alignSelf: "stretch", margin: "30px 0", background: LINE }} />
          {col(en, "♾️", "ENDLESS WORK", out > 0 ? <Chip k={out} size={44} bg={RED}>I'm out</Chip> : null, t >= s.endlessAt - 0.02)}
        </div>
      );
    }
    case "connect": {
      // FIXED layout (no flex re-centring = no jitter): three real app icons land on their names, then shrink into a
      // header row (icons → AI); below it a progress bar fills while it "reads" the stats, then the answer replaces it.
      const m = r(t, s.mergeAt, s.mergeAt + 0.55, EASE_IO), ans = r(t, s.answerAt, s.answerAt + 0.3, POP);
      const BIG = 116, SMALL = 60, GAPB = 170, HY = 26;
      const work = r(t, s.mergeAt + 0.3, s.answerAt - 0.05, Easing.linear);
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          {s.apps.map((a2, i) => {
            if (t < a2.at - 0.02) return null;
            const k2 = r(t, a2.at, a2.at + 0.3, POP);
            const size = lerp(BIG, SMALL, m);
            const x = lerp(w / 2 + (i - 1) * GAPB - BIG / 2, 34 + i * (SMALL + 16), m), y = lerp(36, HY, m);
            return <React.Fragment key={a2.name}>
              <div style={{ position: "absolute", left: x, top: y, transform: `scale(${0.6 + 0.4 * k2})`, opacity: Math.min(1, k2 * 1.5) }}><AppLogo id={a2.icon} size={size} /></div>
              <div style={{ position: "absolute", left: w / 2 + (i - 1) * GAPB - 100, width: 200, top: 36 + BIG + 14, textAlign: "center", fontFamily: UI, fontWeight: 800, fontSize: 32,
                color: "#fff", opacity: Math.min(1, k2 * 1.5) * (1 - r(t, s.mergeAt, s.mergeAt + 0.2)) }}>{a2.name}</div>
            </React.Fragment>;
          })}
          {m > 0.3 && <div style={{ position: "absolute", left: 34 + 3 * (SMALL + 16), top: HY, height: SMALL, display: "flex", alignItems: "center", gap: 16, opacity: r(t, s.mergeAt + 0.2, s.mergeAt + 0.45) }}>
            <span style={{ fontFamily: UI, fontWeight: 900, fontSize: 40, color: "rgba(255,255,255,0.6)" }}>→</span>
            <div style={{ width: SMALL, height: SMALL, borderRadius: SMALL / 2, background: BLUE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 32 }}>✨</div>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, color: "#fff" }}>AI</span>
          </div>}
          {m > 0.6 && ans < 1 && <div style={{ position: "absolute", left: 34, right: 34, top: HY + SMALL + 34, opacity: r(t, s.mergeAt + 0.35, s.mergeAt + 0.55) * (1 - ans) }}>
            <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 38, color: "rgba(255,255,255,0.75)" }}>{s.working}</div>
            <div style={{ marginTop: 16, height: 14, borderRadius: 7, background: "rgba(255,255,255,0.14)" }}>
              <div style={{ width: `${work * 100}%`, height: "100%", borderRadius: 7, background: BLUE }} /></div>
          </div>}
          {ans > 0 && <div style={{ position: "absolute", left: 34, right: 34, top: HY + SMALL + 34, fontFamily: UI, fontWeight: 900, fontSize: 54, color: "#fff",
            opacity: Math.min(1, ans * 1.5), transform: `translateY(${(1 - ans) * 16}px)` }}>{s.answer}</div>}
        </div>
      );
    }
    case "retention": {
      // the REAL average retention curve of his Shorts draws itself (gold line + soft gold fill); the big early drop is
      // shaded red and tagged. Axis labels sit LEFT of the chart, the tag sits right of the drop line, under the title.
      const draw = r(t, s.drawAt, s.drawAt + 1.4, EASE_IO), drop = r(t, s.dropAt, s.dropAt + 0.35, POP);
      const x0 = 118, y0 = 104, W2 = w - x0 - 40, H2 = h - y0 - 36;
      const pts = s.curve.map((v, i) => [x0 + (i / (s.curve.length - 1)) * W2, y0 + (1 - v / 100) * H2]);
      const n = Math.max(2, Math.ceil(pts.length * draw));
      const d = pts.slice(0, n).map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
      const area = `${d} L${pts[n - 1][0].toFixed(1)},${y0 + H2} L${x0},${y0 + H2} Z`;
      const dx = x0 + s.dropFrac * W2, fi = s.dropFrac * (s.curve.length - 1), i0 = Math.floor(fi);
      const dy = y0 + (1 - lerp(s.curve[i0], s.curve[Math.min(i0 + 1, s.curve.length - 1)], fi - i0) / 100) * H2;
      return (
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", left: 32, top: 22, ...label }}>{s.label}</div>
          <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
            <defs><linearGradient id="retfill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor={GOLD} stopOpacity={0.45} /><stop offset="1" stopColor={GOLD} stopOpacity={0.03} /></linearGradient></defs>
            {drop > 0 && <rect x={x0} y={y0} width={dx - x0} height={H2} fill={RED} opacity={0.18 * drop} />}
            {[0, 50, 100].map((g) => <line key={g} x1={x0} x2={x0 + W2} y1={y0 + (1 - g / 100) * H2} y2={y0 + (1 - g / 100) * H2} stroke="rgba(255,255,255,0.12)" strokeWidth={2} />)}
            <path d={area} fill="url(#retfill)" />
            <path d={d} fill="none" stroke={GOLD} strokeWidth={7} strokeLinecap="round" strokeLinejoin="round" />
            {drop > 0 && <line x1={dx} x2={dx} y1={y0} y2={y0 + H2} stroke={RED} strokeWidth={4} strokeDasharray="10 8" opacity={drop} />}
            {drop > 0 && <circle cx={dx} cy={dy} r={13 * drop} fill={RED} stroke="#fff" strokeWidth={3} />}
          </svg>
          {[100, 50, 0].map((g) => <div key={g} style={{ position: "absolute", right: w - x0 + 14, top: y0 + (1 - g / 100) * H2 - 16, fontFamily: MONO, fontWeight: 700, fontSize: 26,
            color: "rgba(255,255,255,0.6)" }}>{g}%</div>)}
          {drop > 0 && <div style={{ position: "absolute", left: dx + 34, top: y0 + 6, transform: `scale(${drop})`, transformOrigin: "0% 50%" }}>
            <Chip k={1} size={36} bg={RED}>{s.dropText}</Chip></div>}
        </div>
      );
    }
    case "ask": {
      const txt = typed(s.prompt, t, s.typeAt, 0.035);
      return (
        <div style={{ position: "absolute", inset: 0, padding: "22px 26px", boxSizing: "border-box", display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14, background: TILE, borderRadius: 26, padding: "14px 22px", border: `2px solid ${LINE}` }}>
            <div style={{ flex: 1, fontFamily: UI, fontWeight: 700, fontSize: 40, lineHeight: 1.2, color: txt ? "#fff" : "rgba(255,255,255,0.4)" }}>
              {txt || "Ask Claude…"}{Math.floor(t * 2.5) % 2 === 0 && txt.length < s.prompt.length && <span style={{ color: BLUE }}>|</span>}</div>
            <div style={{ width: 56, height: 56, borderRadius: 28, background: txt.length >= s.prompt.length ? BLUE : "rgba(255,255,255,0.18)", color: "#fff", fontSize: 32, fontWeight: 900,
              display: "flex", alignItems: "center", justifyContent: "center" }}>↑</div>
          </div>
          {s.rows.filter((rw) => t >= rw.at - 0.02).map((rw) => {
            const a2 = r(t, rw.at, rw.at + 0.3, POP);
            const col = rw.tone === "good" ? GREEN : rw.tone === "bad" ? RED : GOLD;
            return (
              <div key={rw.text} style={{ display: "flex", alignItems: "center", gap: 16, padding: "10px 20px", borderRadius: 20, background: "rgba(255,255,255,0.08)",
                opacity: Math.min(1, a2 * 1.5), transform: `translateX(${(1 - a2) * -40}px)` }}>
                <span style={{ fontSize: 40, color: col, fontWeight: 900, width: 44, textAlign: "center" }}>{rw.icon}</span>
                <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 42, color: "#fff" }}>{rw.text}</span>
              </div>
            );
          })}
        </div>
      );
    }
    case "dashboard": {
      // one dashboard: a coloured tile per platform with its REAL app icon and a view count that counts up
      return (
        <div style={{ position: "absolute", inset: 0, padding: "22px 30px 34px", boxSizing: "border-box", display: "flex", flexDirection: "column", gap: 20 }}>
          <div style={label}>{s.title}</div>
          <div style={{ flex: 1, display: "flex", gap: 20 }}>
            {s.tiles.map((tl, i) => {
              const k2 = r(t, s.at + i * 0.15, s.at + 0.4 + i * 0.15, POP), c = r(t, s.at + i * 0.15, s.at + 0.9 + i * 0.15, EASE);
              const tint = tl.logo === "yt" ? "rgba(255,0,51,0.22)" : tl.logo === "tt" ? "rgba(37,244,238,0.16)" : "rgba(214,36,159,0.24)";
              return <div key={tl.logo} style={{ flex: 1, borderRadius: 26, background: tint, border: `2px solid ${LINE}`, display: "flex", flexDirection: "column",
                alignItems: "center", justifyContent: "center", gap: 10, opacity: Math.min(1, k2 * 1.5), transform: `translateY(${(1 - k2) * 24}px) scale(${0.9 + 0.1 * k2})` }}>
                <AppLogo id={tl.logo} size={84} />
                <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 64, color: "#fff", lineHeight: 1, fontVariantNumeric: "tabular-nums" }}>{(tl.value * c).toFixed(1)}{tl.unit}</div>
                <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 28, color: "rgba(255,255,255,0.7)", lineHeight: 1 }}>{tl.label}</div>
              </div>;
            })}
          </div>
        </div>
      );
    }
    case "dot":
      return null;
    default:
      return null;
  }
};

// scenes written without their own stepper offset: drawn in a box below the stepper when one is shown
const BELOW_STEPPER = ["versions", "simple", "installs", "hours", "interview", "claim", "bar1090"];
const Stepped: React.FC<{ on: boolean; h: number; children: React.ReactNode }> = ({ on, h, children }) =>
  on ? <div style={{ position: "absolute", left: 0, right: 0, top: STEP_H, height: h - STEP_H }}>{children}</div> : <>{children}</>;

// ---------- the plate: glides between fitted sizes, content hands off inside it ----------
export const VibePlate: React.FC<{ d: VibeDef }> = ({ d }) => {
  const t = useT();
  if (t < d.from || t > d.to) return null;
  let i = 0;
  while (i + 1 < d.states.length && d.states[i + 1].at <= t) i++;
  const cur = d.states[i], prev = d.states[Math.max(0, i - 1)];
  if (i > 0 && cur.jump && t < cur.at + 0.6) {
    const gone = r(t, cur.at, cur.at + 0.14, EASE_IN), pop = r(t, cur.at + 0.12, cur.at + 0.5, POP);
    const box = (s: VState, k: number, o: number, content: React.ReactNode) => (
      <div style={{ position: "absolute", left: s.x - s.w / 2, top: s.y, width: s.w, height: s.h, opacity: o, transformOrigin: "50% 0%",
        transform: `scale(${(s.scale ?? 1) * k})` }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: s.radius ?? 36, overflow: "hidden", background: "rgba(22,22,24,0.9)",
          border: "1.5px solid rgba(255,255,255,0.16)", boxShadow: "0 22px 50px rgba(0,0,0,0.32)", color: "#fff", fontFamily: UI }}>{content}</div>
      </div>
    );
    const stepOf = (s: VState) => s.step !== undefined ? <Stepper step={s.step} names={d.steps} t={t} at={s.at} w={s.w} /> : null;
    return (
      <>
        {gone < 1 && box(prev, 1 - 0.3 * gone, 1 - gone, <>{stepOf(prev)}<Scene s={prev.scene} t={t} w={prev.w} h={prev.h} /></>)}
        {pop > 0 && box(cur, 0.7 + 0.3 * pop, Math.min(1, pop * 1.5), <>{stepOf(cur)}<Scene s={cur.scene} t={t} w={cur.w} h={cur.h} /></>)}
      </>
    );
  }
  const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.55, EASE_IO);
  const kS = i === 0 ? 1 : interpolate(t, [cur.at, cur.at + 0.6], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const outK = i === 0 ? 1 : r(t, cur.at, cur.at + 0.16, EASE_IN);
  const same = i > 0 && JSON.stringify(prev.scene) === JSON.stringify(cur.scene);   // only the plate size changes: keep the content steady
  const inK = same ? 1 : i === 0 ? r(t, d.from, d.from + 0.35) : r(t, cur.at + 0.18, cur.at + 0.48, EASE);
  const enter = r(t, d.from, d.from + 0.45, POP);
  const exit = r(t, d.to - 0.3, d.to, EASE_IN);
  const x = lerp(prev.x, cur.x, k), y = lerp(prev.y, cur.y, k);
  const w = lerp(prev.w, cur.w, kS), h = lerp(prev.h, cur.h, kS);
  const rad = lerp(prev.radius ?? 36, cur.radius ?? 36, k);
  const sc = lerp(prev.scale ?? 1, cur.scale ?? 1, kS);
  // squash in flight: the plate stretches along its move like a drop of water
  const flight = i > 0 ? Math.sin(Math.PI * Math.min(1, Math.max(0, (t - cur.at) / 0.5))) : 0;
  const stepShown = cur.step !== undefined;
  const stepWas = prev.step !== undefined && i > 0;
  const stepK = stepShown ? (stepWas ? 1 : r(t, cur.at + 0.2, cur.at + 0.5)) : (stepWas ? 1 - outK : 0);
  return (
    <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, opacity: 1 - exit, transformOrigin: "50% 0%",
      transform: `scale(${sc}) scale(${enter * (1 - exit * 0.4)}) scale(${1 + flight * 0.03}, ${1 - flight * 0.04}) translateY(${Math.sin(t * 1.4) * 4}px)` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: rad, overflow: "hidden", background: "rgba(22,22,24,0.9)", border: "1.5px solid rgba(255,255,255,0.16)",
        boxShadow: "0 22px 50px rgba(0,0,0,0.32)", color: "#fff", fontFamily: UI }}>
        {stepK > 0 && <div style={{ position: "absolute", inset: 0, opacity: stepK }}>
          <Stepper step={stepShown ? cur.step! : prev.step!} names={d.steps} t={t} at={cur.at} w={w} /></div>}
        {i > 0 && !same && outK < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - outK, transform: `scale(${1 - outK * 0.06})` }}>
          <Stepped on={prev.step !== undefined && BELOW_STEPPER.includes(prev.scene.kind)} h={h}><Scene s={prev.scene} t={t} w={w} h={h} /></Stepped></div>}
        {cur.bg && <div style={{ position: "absolute", inset: 0, background: cur.bg, opacity: i === 0 ? 1 : k }} />}
        {prev.bg && i > 0 && <div style={{ position: "absolute", inset: 0, background: prev.bg, opacity: 1 - r(t, cur.at, cur.at + 0.07) }} />}
        <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `scale(${0.96 + 0.04 * inK})` }}>
          <Stepped on={cur.step !== undefined && BELOW_STEPPER.includes(cur.scene.kind)} h={h}><Scene s={cur.scene} t={t} w={w} h={h - (cur.step !== undefined && BELOW_STEPPER.includes(cur.scene.kind) ? STEP_H : 0)} /></Stepped></div>
      </div>
    </div>
  );
};
