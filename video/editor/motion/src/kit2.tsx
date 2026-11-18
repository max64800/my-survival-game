import React from "react";
import { AbsoluteFill, Easing, OffthreadVideo, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";

// Kit 2: "quiet luxury + smooth motion" look (dark glass, glow, light trails, full-screen slates).
// Learned from @calsaistudio (minimal slates, one-word captions) and @vizibilonline (morphs, glow, trails).
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "600", "800", "900"], subsets: ["latin"] });
const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });

const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const INDIGO = "#6366F1";
const TEAL = "#2DE1C2";
const GLASS = "rgba(16,16,24,0.78)";
const PAPER = "#F3F2EE";
const RED = "#FF5A5F";

type Base = { from: number; to: number };
export type K2 =
  | (Base & { type: "slate"; words: { w: string; s: number; serif?: boolean }[] })
  | (Base & { type: "stage"; pip: { ox: number; oy: number }; stages: { at: number; n: number; title: string; tokens?: { text: string; at: number; strike?: boolean; good?: boolean }[] }[] })
  | (Base & { type: "glowword"; text: string; y: number; size?: number })
  | (Base & { type: "trail"; y: number; label?: string; dir?: number })
  | (Base & { type: "spark"; x: number; y: number; title: string; at: number })
  | (Base & { type: "tiles"; y: number; tiles: { big: string; label: string; at: number; good?: boolean }[] })
  | (Base & { type: "gchips"; y: number; chips: { text: string; emoji?: string; at: number; bad?: boolean }[] })
  | (Base & { type: "gtoggle"; x: number; y: number; label: string; at: number })
  | (Base & { type: "gchat"; x: number; y: number; title: string; msgs: { from: "me" | "ai"; text: string; at: number }[] })
  | (Base & { type: "gstrike"; text: string; y: number; at: number; serif?: boolean })
  | (Base & { type: "pill"; text: string; at: number; avatar: string });
export const K2_TYPES = ["slate", "stage", "glowword", "trail", "spark", "tiles", "gchips", "gtoggle", "gchat", "gstrike", "pill"];

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const ramp = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const on = (t: number, e: Base) => t >= e.from && t <= e.to;
const io = (t: number, e: Base, i = 0.4, o = 0.25) => ({ k: ramp(t, e.from, e.from + i), out: ramp(t, e.to - o, e.to, EASE_IN) });
const float = (t: number, seed: number, amp = 6) => `translate(${Math.sin(t * 1.2 + seed) * amp * 0.6}px, ${Math.sin(t * 1.6 + seed * 2) * amp}px)`;

const Glass: React.FC<{ style?: React.CSSProperties; children: React.ReactNode }> = ({ style, children }) => (
  <div style={{ background: GLASS, border: "1.5px solid rgba(255,255,255,0.14)", borderRadius: 34, color: "#fff", fontFamily: UI,
    boxShadow: `0 30px 70px rgba(0,0,0,0.45), 0 0 60px rgba(99,102,241,0.25)`, ...style }}>{children}</div>
);

// soft drifting glow blobs (used on dark full-screen scenes)
const Blobs: React.FC<{ t: number }> = ({ t }) => (
  <>
    <div style={{ position: "absolute", left: 140 + Math.sin(t * 0.5) * 120, top: 300 + Math.cos(t * 0.4) * 100, width: 700, height: 700,
      borderRadius: 350, background: INDIGO, opacity: 0.32, filter: "blur(140px)" }} />
    <div style={{ position: "absolute", left: 420 + Math.cos(t * 0.45) * 140, top: 900 + Math.sin(t * 0.55) * 120, width: 560, height: 560,
      borderRadius: 280, background: TEAL, opacity: 0.18, filter: "blur(140px)" }} />
  </>
);

// full-screen minimal sentence: words go grey -> black as they're said, grid lines draw in around it
const Slate: React.FC<{ e: Extract<K2, { type: "slate" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const k = ramp(t, e.from, e.from + 0.3);
  const out = ramp(t, e.to - 0.25, e.to, EASE_IN);
  const g = ramp(t, e.from + 0.35, e.from + 1.0, EASE_IO);
  return (
    <AbsoluteFill style={{ background: PAPER, transform: `translateX(${(1 - k) * 1080 - out * 1080}px)` }}>
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
        {[180, 900].map((x) => <line key={x} x1={x} y1={960 - 900 * g} x2={x} y2={960 + 900 * g} stroke="#D9D7D0" strokeWidth="2" />)}
        {[800, 1120].map((y) => <line key={y} x1={540 - 540 * g} y1={y} x2={540 + 540 * g} y2={y} stroke="#D9D7D0" strokeWidth="2" />)}
      </svg>
      <div style={{ position: "absolute", left: 200, right: 200, top: 800, height: 320, display: "flex", flexWrap: "wrap", alignContent: "center",
        justifyContent: "center", columnGap: 16, rowGap: 4, transform: `scale(${1 + (t - e.from) * 0.012})` }}>
        {e.words.map((w, i) => (
          <span key={i} style={{ fontFamily: w.serif ? SERIF : UI, fontStyle: w.serif ? "italic" : "normal", fontWeight: w.serif ? 400 : 600,
            fontSize: w.serif ? 84 : 62, lineHeight: 1.15, letterSpacing: w.serif ? -1 : -1.5,
            color: t >= w.s ? "#141414" : "#C9C7C0", transition: "none" }}>{w.w}</span>
        ))}
      </div>
    </AbsoluteFill>
  );
};

// full-screen dark rules stage: giant glowing numeral rolls between rules, speaker in a round bubble
const Stage: React.FC<{ e: Extract<K2, { type: "stage" }>; video: string }> = ({ e, video }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const k = ramp(t, e.from, e.from + 0.35);
  const out = ramp(t, e.to - 0.3, e.to, EASE_IN);
  let si = 0;
  while (si + 1 < e.stages.length && e.stages[si + 1].at <= t) si++;
  const st = e.stages[si];
  const prev = e.stages[Math.max(0, si - 1)];
  const sw = si === 0 ? ramp(t, st.at, st.at + 0.5) : ramp(t, st.at, st.at + 0.45);
  const trail = si === 0 ? -1 : ramp(t, st.at - 0.1, st.at + 0.5, EASE_IO);
  const pipK = ramp(t, e.from + 0.2, e.from + 0.6, Easing.bezier(0.2, 1.4, 0.4, 1));
  const numY = (1 - sw) * 140;
  return (
    <AbsoluteFill style={{ opacity: 1 - out, transform: `translateY(${(1 - k) * 1920}px)` }}>
      <AbsoluteFill style={{ background: "radial-gradient(120% 80% at 50% 30%, #17172B 0%, #0A0A10 70%)", overflow: "hidden" }}>
        <Blobs t={t} />
        {/* light trail sweeping across on each rule change */}
        {trail > 0 && trail < 1 && (
          <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
            <path d="M -100 760 C 300 560, 700 980, 1180 640" fill="none" stroke={TEAL} strokeWidth="14" strokeLinecap="round"
              strokeDasharray="1400" strokeDashoffset={1400 - 2800 * trail} style={{ filter: `drop-shadow(0 0 18px ${TEAL})` }} />
          </svg>
        )}
        <div style={{ position: "absolute", left: 0, right: 0, top: 300, textAlign: "center" }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 8, color: "rgba(255,255,255,0.55)" }}>RULE</div>
          <div style={{ position: "relative", height: 420, overflow: "hidden" }}>
            {si > 0 && sw < 1 && (
              <div style={{ position: "absolute", left: 0, right: 0, fontFamily: UI, fontWeight: 900, fontSize: 400, lineHeight: "420px", color: "#fff",
                opacity: 1 - sw, transform: `translateY(${-sw * 160}px) scale(${1 - sw * 0.2})`, filter: `blur(${sw * 10}px)` }}>{prev.n}</div>
            )}
            <div style={{ position: "absolute", left: 0, right: 0, fontFamily: UI, fontWeight: 900, fontSize: 400, lineHeight: "420px", color: "#fff",
              opacity: sw, transform: `translateY(${numY}px) scale(${0.85 + 0.15 * sw})`, filter: `blur(${(1 - sw) * 10}px)`,
              textShadow: `0 0 60px rgba(99,102,241,0.9), 0 0 140px rgba(99,102,241,0.6)` }}>{st.n}</div>
          </div>
          <div style={{ position: "relative", height: 110, marginTop: 6 }}>
            {si > 0 && sw < 1 && <div style={{ position: "absolute", left: 0, right: 0, fontFamily: SERIF, fontStyle: "italic", fontSize: 92, color: "#fff",
              opacity: 1 - sw, transform: `translateY(${-sw * 50}px)` }}>{prev.title}</div>}
            <div style={{ position: "absolute", left: 0, right: 0, fontFamily: SERIF, fontStyle: "italic", fontSize: 92, color: "#fff",
              opacity: sw, transform: `translateY(${(1 - sw) * 50}px)` }}>{st.title}</div>
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 40, flexWrap: "wrap", padding: "0 90px" }}>
            {(st.tokens ?? []).map((tk, i) => {
              const a = ramp(t, tk.at, tk.at + 0.3, Easing.bezier(0.3, 1.4, 0.5, 1));
              const s = tk.strike ? ramp(t, tk.at + 0.2, tk.at + 0.45, EASE_IO) : 0;
              if (t < tk.at) return null;
              return (
                <div key={`${si}-${i}`} style={{ position: "relative", padding: "14px 30px", borderRadius: 40, fontFamily: UI, fontWeight: 800, fontSize: 44,
                  color: tk.good ? TEAL : tk.strike ? RED : "#fff", background: "rgba(255,255,255,0.08)", border: `1.5px solid ${tk.good ? TEAL : "rgba(255,255,255,0.18)"}`,
                  boxShadow: tk.good ? `0 0 30px rgba(45,225,194,0.45)` : "none", transform: `scale(${a})` }}>
                  {tk.text}
                  {tk.strike && <div style={{ position: "absolute", left: 16, right: 16, top: "50%", height: 6, borderRadius: 3, background: RED,
                    transformOrigin: "left", transform: `scaleX(${s}) rotate(-5deg)` }} />}
                </div>
              );
            })}
          </div>
        </div>
      </AbsoluteFill>
      <div style={{ position: "absolute", left: 80, top: 1010, width: 380, height: 380, borderRadius: 190, overflow: "hidden",
        border: "6px solid rgba(255,255,255,0.9)", boxShadow: `0 0 50px rgba(99,102,241,0.6)`, transform: `scale(${pipK}) ${float(t, 2, 5)}` }}>
        <div style={{ position: "absolute", width: 1080, height: 1920, left: -(e.pip.ox * 0.45) + 190, top: -(e.pip.oy * 0.45) + 190,
          transform: "scale(0.45)", transformOrigin: "0 0" }}>
          <OffthreadVideo src={staticFile(video)} muted style={{ width: 1080, height: 1920 }} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

// a word in front of the speaker with a glow bloom behind it (never hidden by the head)
const GlowWord: React.FC<{ e: Extract<K2, { type: "glowword" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e, 0.45);
  const size = e.size ?? 170;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: e.y, textAlign: "center", opacity: k * (1 - out),
      transform: `translateY(${(1 - k) * 40}px) scale(${0.9 + 0.1 * k}) ${float(t, 1, 4)}` }}>
      <div style={{ position: "absolute", left: "50%", top: size * 0.15, width: size * 3.4, height: size * 1.1, marginLeft: -size * 1.7,
        borderRadius: size, background: INDIGO, opacity: 0.55, filter: "blur(60px)" }} />
      <span style={{ position: "relative", fontFamily: SERIF, fontStyle: "italic", fontSize: size, color: "#fff", lineHeight: 1,
        letterSpacing: -2, textShadow: "0 0 30px rgba(255,255,255,0.35), 0 6px 30px rgba(0,0,0,0.5)", filter: `blur(${(1 - k) * 8}px)` }}>{e.text}</span>
    </div>
  );
};

// light streak that writes across the top of the frame, carrying a small label
const Trail: React.FC<{ e: Extract<K2, { type: "trail" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const p = ramp(t, e.from, e.to - 0.15, EASE_IO);
  const out = ramp(t, e.to - 0.3, e.to, EASE_IN);
  const dir = e.dir ?? 1;
  const x = dir > 0 ? -150 + p * 1380 : 1230 - p * 1380;
  const y = e.y + Math.sin(p * Math.PI) * -90;
  const d = dir > 0 ? `M -150 ${e.y} Q 540 ${e.y - 180} 1230 ${e.y}` : `M 1230 ${e.y} Q 540 ${e.y - 180} -150 ${e.y}`;
  return (
    <AbsoluteFill style={{ opacity: 1 - out }}>
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
        <path d={d} fill="none" stroke={TEAL} strokeWidth="10" strokeLinecap="round" strokeDasharray="1700"
          strokeDashoffset={1700 - 1700 * p} style={{ filter: `drop-shadow(0 0 14px ${TEAL})` }} opacity={0.9} />
      </svg>
      {e.label && <div style={{ position: "absolute", left: x, top: y - 40, transform: "translate(-50%,-50%)", fontFamily: UI, fontWeight: 800,
        fontSize: 46, color: "#fff", whiteSpace: "nowrap", textShadow: `0 0 20px ${TEAL}, 0 4px 14px rgba(0,0,0,0.6)` }}>{e.label}</div>}
    </AbsoluteFill>
  );
};

// glass card with an on/off zigzag history line drawing itself
const Spark: React.FC<{ e: Extract<K2, { type: "spark" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e);
  const p = ramp(t, e.at, e.at + 1.1, EASE_IO);
  const pts = [0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0].map((v, i) => `${20 + i * 52},${v ? 30 : 120}`).join(" ");
  return (
    <div style={{ position: "absolute", left: e.x - 330, top: e.y, width: 660, opacity: k * (1 - out), transform: `translateY(${(1 - k) * 50}px) ${float(t, 3)}` }}>
      <Glass style={{ padding: "26px 30px" }}>
        <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 4, color: "rgba(255,255,255,0.6)" }}>{e.title}</div>
        <svg width="600" height="150" style={{ marginTop: 10 }}>
          <text x="0" y="36" fill="rgba(255,255,255,0.5)" fontFamily={MONO} fontSize="20">ON</text>
          <text x="0" y="126" fill="rgba(255,255,255,0.5)" fontFamily={MONO} fontSize="20">OFF</text>
          <g transform="translate(40,0)">
            <polyline points={pts} fill="none" stroke={RED} strokeWidth="7" strokeLinejoin="round" strokeLinecap="round"
              strokeDasharray="1600" strokeDashoffset={1600 - 1600 * p} style={{ filter: `drop-shadow(0 0 10px ${RED})` }} />
          </g>
        </svg>
      </Glass>
    </div>
  );
};

// a row of stat tiles popping in one by one
const Tiles: React.FC<{ e: Extract<K2, { type: "tiles" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const out = ramp(t, e.to - 0.25, e.to, EASE_IN);
  const n = e.tiles.length;
  const w = Math.min(300, (960 - (n - 1) * 18) / n);
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: e.y, display: "flex", justifyContent: "center", gap: 18, opacity: 1 - out }}>
      {e.tiles.map((tl, i) => {
        const a = ramp(t, tl.at, tl.at + 0.35, Easing.bezier(0.3, 1.3, 0.5, 1));
        if (t < tl.at) return <div key={i} style={{ width: w }} />;
        return (
          <div key={i} style={{ width: w, transform: `translateY(${(1 - a) * 60}px) scale(${0.8 + 0.2 * a}) ${float(t, i * 1.7, 5)}`, opacity: Math.min(1, a * 1.5) }}>
            <Glass style={{ padding: "26px 10px", textAlign: "center", boxShadow: tl.good ? `0 0 40px rgba(45,225,194,0.35), 0 24px 50px rgba(0,0,0,0.4)` : undefined }}>
              <div style={{ fontWeight: 900, fontSize: 70, lineHeight: 1, color: tl.good ? TEAL : "#fff" }}>{tl.big}</div>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 22, letterSpacing: 2, color: "rgba(255,255,255,0.65)", marginTop: 12 }}>{tl.label}</div>
            </Glass>
          </div>
        );
      })}
    </div>
  );
};

// glass chips stacking in a row
const GChips: React.FC<{ e: Extract<K2, { type: "gchips" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const out = ramp(t, e.to - 0.25, e.to, EASE_IN);
  return (
    <div style={{ position: "absolute", left: 70, right: 70, top: e.y, display: "flex", flexWrap: "wrap", justifyContent: "center", gap: 14, opacity: 1 - out }}>
      {e.chips.map((c, i) => {
        if (t < c.at) return null;
        const a = ramp(t, c.at, c.at + 0.3, Easing.bezier(0.3, 1.4, 0.5, 1));
        return (
          <div key={i} style={{ transform: `scale(${a}) ${float(t, i, 4)}` }}>
            <Glass style={{ padding: "14px 26px", borderRadius: 40, fontWeight: 800, fontSize: 42, display: "flex", gap: 12, alignItems: "center",
              color: c.bad ? RED : "#fff" }}>{c.emoji && <span>{c.emoji}</span>}{c.text}</Glass>
          </div>
        );
      })}
    </div>
  );
};

const GToggle: React.FC<{ e: Extract<K2, { type: "gtoggle" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e);
  const s = ramp(t, e.at, e.at + 0.28, Easing.bezier(0.3, 1.4, 0.5, 1));
  return (
    <div style={{ position: "absolute", left: e.x - 300, top: e.y, width: 600, opacity: k * (1 - out), transform: `translateY(${(1 - k) * 50}px) ${float(t, 5)}` }}>
      <Glass style={{ padding: "26px 34px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontWeight: 900, fontSize: 58 }}>{e.label}</div>
        <div style={{ width: 170, height: 96, borderRadius: 48, background: s > 0.5 ? TEAL : "rgba(255,255,255,0.18)", position: "relative",
          boxShadow: s > 0.5 ? `0 0 ${50 * s}px rgba(45,225,194,0.8)` : "none" }}>
          <div style={{ position: "absolute", top: 8, left: 8 + s * 74, width: 80, height: 80, borderRadius: 40, background: "#fff" }} />
        </div>
      </Glass>
    </div>
  );
};

const GChat: React.FC<{ e: Extract<K2, { type: "gchat" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e);
  return (
    <div style={{ position: "absolute", left: e.x - 360, top: e.y, width: 720, opacity: k * (1 - out), transform: `translateY(${(1 - k) * 50}px) ${float(t, 8)}` }}>
      <Glass style={{ padding: "26px 30px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 14, height: 14, borderRadius: 7, background: TEAL, boxShadow: `0 0 12px ${TEAL}` }} />
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 4, color: "rgba(255,255,255,0.6)" }}>{e.title}</div>
        </div>
        {e.msgs.map((m, i) => {
          if (t < m.at) return null;
          const me = m.from === "me";
          const a = ramp(t, m.at, m.at + 0.25);
          const typed = me ? Array.from(m.text).slice(0, Math.floor((t - m.at) / 0.035)).join("") : m.text;
          const dots = !me && t < m.at + 0.6;
          return (
            <div key={i} style={{ display: "flex", justifyContent: me ? "flex-end" : "flex-start", marginTop: 16, opacity: a }}>
              <div style={{ maxWidth: 520, padding: "16px 22px", borderRadius: 26, fontWeight: 700, fontSize: 36, lineHeight: 1.25,
                background: me ? INDIGO : "rgba(255,255,255,0.1)", color: "#fff" }}>
                {dots ? ".".repeat(1 + (Math.floor(t * 6) % 3)) : typed}
              </div>
            </div>
          );
        })}
      </Glass>
    </div>
  );
};

// a word that gets struck through with a red line (front of the speaker)
const GStrike: React.FC<{ e: Extract<K2, { type: "gstrike" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e, 0.35);
  const s = ramp(t, e.at, e.at + 0.3, EASE_IO);
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: e.y, display: "flex", justifyContent: "center", opacity: k * (1 - out),
      transform: `scale(${0.9 + 0.1 * k}) ${float(t, 6, 4)}` }}>
      <div style={{ position: "relative", fontFamily: e.serif ? SERIF : UI, fontStyle: e.serif ? "italic" : "normal", fontWeight: e.serif ? 400 : 900,
        fontSize: e.serif ? 170 : 120, color: "#fff", lineHeight: 1, textShadow: "0 6px 30px rgba(0,0,0,0.55)" }}>
        {e.text}
        <div style={{ position: "absolute", left: -10, right: -10, top: "55%", height: 12, borderRadius: 6, background: RED,
          boxShadow: `0 0 20px ${RED}`, transformOrigin: "left", transform: `scaleX(${s}) rotate(-4deg)` }} />
      </div>
    </div>
  );
};

// dark-glass comment pill: avatar + keyword typing + blue send (calsaistudio-style CTA)
const Pill: React.FC<{ e: Extract<K2, { type: "pill" }> }> = ({ e }) => {
  const t = useT();
  if (!on(t, e)) return null;
  const { k, out } = io(t, e, 0.35, 0.2);
  const chars = Array.from(e.text);
  const n = Math.floor(Math.max(0, t - e.at) / 0.08);
  const sent = n > chars.length + 4;
  return (
    <div style={{ position: "absolute", left: 90, right: 190, top: 1150, opacity: k * (1 - out), transform: `translateY(${(1 - k) * 60}px)` }}>
      <Glass style={{ borderRadius: 60, padding: "16px 18px", display: "flex", alignItems: "center", gap: 18 }}>
        <div style={{ width: 70, height: 70, borderRadius: 35, background: "linear-gradient(135deg,#8B8DF7,#2DE1C2)", display: "flex",
          alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 34 }}>{e.avatar}</div>
        <div style={{ flex: 1, fontWeight: 800, fontSize: 44, letterSpacing: 1 }}>{chars.slice(0, n).join("")}
          {!sent && Math.floor(t * 2.5) % 2 === 0 && <span style={{ color: INDIGO }}>|</span>}</div>
        <div style={{ width: 70, height: 70, borderRadius: 35, background: sent ? "#3B82F6" : "rgba(255,255,255,0.15)", display: "flex",
          alignItems: "center", justifyContent: "center", fontSize: 38, fontWeight: 900, boxShadow: sent ? "0 0 30px rgba(59,130,246,0.8)" : "none",
          transform: `scale(${sent ? 1.1 : 1})` }}>↑</div>
      </Glass>
    </div>
  );
};

export const renderK2 = (e: K2, i: number, video: string) => {
  switch (e.type) {
    case "slate": return <Slate key={`k2${i}`} e={e} />;
    case "stage": return <Stage key={`k2${i}`} e={e} video={video} />;
    case "glowword": return <GlowWord key={`k2${i}`} e={e} />;
    case "trail": return <Trail key={`k2${i}`} e={e} />;
    case "spark": return <Spark key={`k2${i}`} e={e} />;
    case "tiles": return <Tiles key={`k2${i}`} e={e} />;
    case "gchips": return <GChips key={`k2${i}`} e={e} />;
    case "gtoggle": return <GToggle key={`k2${i}`} e={e} />;
    case "gchat": return <GChat key={`k2${i}`} e={e} />;
    case "gstrike": return <GStrike key={`k2${i}`} e={e} />;
    case "pill": return <Pill key={`k2${i}`} e={e} />;
    default: return null;
  }
};

// full-screen layers sit above captions
export const K2_FULL = ["slate", "stage"];

// one word at a time, quiet-luxury captions (white Inter, key words in white italic serif)
export const SingleCaptions: React.FC<{ words: { w: string; s: number; e: number; em?: boolean }[]; bottom: number; right: number; hide: { from: number; to: number }[] }> =
  ({ words, bottom, right, hide }) => {
    const t = useT();
    if (hide.some((h) => t >= h.from && t <= h.to)) return null;
    let i = -1;
    for (let j = 0; j < words.length; j++) if (words[j].s - 0.03 <= t) i = j;
    if (i < 0) return null;
    const w = words[i];
    const next = words[i + 1]?.s ?? w.e + 0.5;
    if (t > Math.max(w.e + 0.35, Math.min(next, w.e + 0.35))) return null;
    const a = ramp(t, w.s - 0.03, w.s + 0.08);
    return (
      <div style={{ position: "absolute", left: 90, right, bottom, textAlign: "center", opacity: a, transform: `translateY(${(1 - a) * 10}px)` }}>
        <span style={{ fontFamily: w.em ? SERIF : UI, fontStyle: w.em ? "italic" : "normal", fontWeight: w.em ? 400 : 600, fontSize: w.em ? 104 : 74,
          color: "#fff", letterSpacing: w.em ? -1 : -1.5, textShadow: "0 3px 2px rgba(0,0,0,0.3), 0 6px 26px rgba(0,0,0,0.55)" }}>{w.w}</span>
      </div>
    );
  };
