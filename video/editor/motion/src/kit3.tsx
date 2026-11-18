import React from "react";
import { AbsoluteFill, Easing, Img, OffthreadVideo, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadSerif } from "@remotion/google-fonts/InstrumentSerif";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";

// Kit 3: "flow" — nothing pops in from nowhere. One through-line (a blue light/dot, then the three layers of the
// EQT mark) carries every beat into the next: draw -> collapse to a dot -> dot opens the scene -> colour-field
// wipes between scenes while the face bubble and the logo dock stay -> objects turn into logo layers -> the layers
// assemble into the real EQT logo -> the face bubble grows back to full screen. See memory: motion-flow-rules.
const { fontFamily: UI } = loadInter("normal", { weights: ["500", "700", "800", "900"], subsets: ["latin"] });
const { fontFamily: SERIF } = loadSerif("italic", { subsets: ["latin"] });
const { fontFamily: MONO } = loadMono("normal", { weights: ["500", "700"], subsets: ["latin"] });

const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const EASE_IO = Easing.bezier(0.65, 0, 0.35, 1);
const POP = Easing.bezier(0.3, 1.5, 0.5, 1);
const BLUE = "#1E9BFF";
const CYAN = "#5ACDFF";
const RED = "#FF4D4D";

const useT = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return f / fps;
};
const r = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;

// ---------- Palm Jumeirah outline (trunk, fronds, crescent) drawn by a moving light ----------
const PALM_PATHS = (() => {
  const p: string[] = [];
  p.push("M 540 660 L 540 420");                                       // trunk
  for (let i = 0; i < 8; i++) {                                         // fronds, left and right
    const y = 432 + i * 28;
    const len = 175 - Math.abs(i - 3.5) * 12;
    p.push(`M 540 ${y} C ${540 - len * 0.4} ${y - 8}, ${540 - len * 0.85} ${y - 4}, ${540 - len} ${y + 2}`);
    p.push(`M 540 ${y} C ${540 + len * 0.4} ${y - 8}, ${540 + len * 0.85} ${y - 4}, ${540 + len} ${y + 2}`);
  }
  p.push("M 320 405 A 220 200 0 0 1 760 405");                         // crescent breakwater
  return p;
})();

export const PalmDraw: React.FC<{ from: number; to: number; y?: number; scale?: number }> = ({ from, to, y = 0, scale = 1 }) => {
  const t = useT();
  if (t < from || t > to) return null;
  const draw = r(t, from, from + 1.4, EASE_IO);
  const collapse = r(t, to - 0.35, to, EASE_IN);
  return (
    <AbsoluteFill style={{ transform: `translateY(${y}px) scale(${scale * (1 - collapse)})`, transformOrigin: "540px 600px", opacity: 1 - collapse * 0.3 }}>
      <div style={{ position: "absolute", left: 250, top: 270, width: 580, height: 440, borderRadius: 44, background: "rgba(8,14,30,0.62)",
        border: "1.5px solid rgba(255,255,255,0.18)", boxShadow: "0 30px 60px rgba(0,0,0,0.4)", transform: `scale(${r(t, from, from + 0.35, POP)})` }} />
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <filter id="palmglow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="7" result="b" />
            <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge></filter>
        </defs>
        {PALM_PATHS.map((d, i) => {
          const k = r(draw, i / PALM_PATHS.length * 0.7, i / PALM_PATHS.length * 0.7 + 0.35, EASE);
          return <path key={i} d={d} fill="none" stroke={i === PALM_PATHS.length - 1 ? CYAN : "#FFFFFF"} strokeWidth={i === 0 ? 9 : 6}
            strokeLinecap="round" pathLength={1} strokeDasharray="1" strokeDashoffset={1 - k} filter="url(#palmglow)" />;
        })}
      </svg>
    </AbsoluteFill>
  );
};

export const Intro: React.FC<{ from: number; to: number; label: string }> = ({ from, to, label }) => {
  const t = useT();
  if (t < from || t > to) return null;
  const collapse = r(t, to - 0.35, to, EASE_IN);
  const lab = r(t, from, from + 0.35, POP);
  return (
    <AbsoluteFill style={{ transform: `scale(${1 - collapse * 0.97})`, transformOrigin: "540px 600px", opacity: 1 - collapse * 0.2 }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 280, textAlign: "center", transform: `scale(${lab})` }}>
        <span style={{ display: "inline-block", padding: "12px 26px", borderRadius: 40, background: "rgba(8,14,30,0.72)", color: "#fff",
          fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 5, border: "1.5px solid rgba(255,255,255,0.2)" }}>{label}</span>
      </div>
      {["01", "02", "03"].map((n, i) => {
        const a = r(t, from + 0.25 + i * 0.22, from + 0.6 + i * 0.22, POP);
        const x = 540 + (i - 1) * 230;
        return (
          <div key={n} style={{ position: "absolute", left: x - 100, top: 400, width: 200, height: 250, borderRadius: 30,
            background: "rgba(8,14,30,0.72)", border: "1.5px solid rgba(255,255,255,0.22)", boxShadow: `0 0 30px rgba(30,155,255,0.35)`,
            transform: `translateY(${(1 - a) * 80}px) rotate(${(i - 1) * 6 * a}deg) scale(${a})`, display: "flex", flexDirection: "column",
            alignItems: "center", justifyContent: "center", color: "#fff" }}>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 24, letterSpacing: 4, opacity: 0.7 }}>TYPE</div>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 96, lineHeight: 1 }}>{n}</div>
            <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 54, color: CYAN }}>?</div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// ---------- the through-line dot that the palm collapses into, and that opens the first scene ----------
export const Dot: React.FC<{ at: number; x: number; y: number }> = ({ at, x, y }) => {
  const t = useT();
  if (t < at - 0.05 || t > at + 0.5) return null;
  const k = r(t, at, at + 0.15, POP);
  const out = r(t, at + 0.3, at + 0.5);
  return <div style={{ position: "absolute", left: x - 22, top: y - 22, width: 44, height: 44, borderRadius: 22, background: BLUE,
    boxShadow: `0 0 40px ${BLUE}, 0 0 90px ${BLUE}`, transform: `scale(${k * (1 + out * 2)})`, opacity: 1 - out * 0.4 }} />;
};

// ---------- scene objects ----------
const Door: React.FC<{ t: number; s: SceneDef }> = ({ t, s }) => {
  const chart = r(t, s.at + 0.3, s.at + 1.0, EASE_IO);
  const chartOut = r(t, (s.k1 ?? 0) - 0.1, (s.k1 ?? 0) + 0.3);
  const door = r(t, s.k1 ?? 0, (s.k1 ?? 0) + 0.7, EASE_IO);
  const sign = r(t, s.k2 ?? 99, (s.k2 ?? 99) + 0.5, POP);
  const swing = Math.sin((t - (s.k2 ?? 0)) * 6) * 14 * Math.exp(-(t - (s.k2 ?? 0)) * 1.6);
  const bell = t >= (s.k3 ?? 99);
  const ring = r(t, s.k3 ?? 99, (s.k3 ?? 99) + 0.6);
  const unplug = r(t, s.k4 ?? 99, (s.k4 ?? 99) + 0.35, POP);
  const stamp = r(t, (s.k4 ?? 99) + 0.5, (s.k4 ?? 99) + 0.8, POP);
  return (
    <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
      {/* IPO chart rockets up, then morphs into the door */}
      <polyline points="250,980 380,930 470,960 590,820 690,700 830,430" fill="none" stroke={CYAN} strokeWidth="12" strokeLinecap="round"
        strokeLinejoin="round" pathLength={1} strokeDasharray="1" strokeDashoffset={1 - chart} opacity={1 - chartOut} />
      {chart > 0.9 && chartOut < 1 && <text x="840" y="410" fill={CYAN} fontFamily={MONO} fontWeight="700" fontSize="44" opacity={1 - chartOut}>IPO ↑</text>}
      <path d="M 390 1000 L 390 640 A 150 150 0 0 1 690 640 L 690 1000 Z" fill="rgba(255,255,255,0.06)" stroke="#fff" strokeWidth="10"
        pathLength={1} strokeDasharray="1" strokeDashoffset={1 - door} strokeLinejoin="round" />
      {door > 0.6 && <circle cx="650" cy="830" r="12" fill="#fff" opacity={door} />}
      {/* "do not disturb" hanger swinging from the handle */}
      {sign > 0 && (
        <g transform={`translate(650 840) rotate(${swing}) scale(${sign})`}>
          <line x1="0" y1="0" x2="0" y2="40" stroke="#fff" strokeWidth="4" />
          <rect x="-90" y="40" width="180" height="110" rx="16" fill="#fff" />
          <text x="0" y="88" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="30" fill="#0E1E45">DO NOT</text>
          <text x="0" y="126" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="30" fill="#0E1E45">DISTURB</text>
        </g>
      )}
      {/* doorbell: pressed, rings, then the cable is unplugged */}
      {door > 0.8 && (
        <g transform="translate(770 800)">
          <circle r="34" fill={bell ? CYAN : "#fff"} stroke="#0E1E45" strokeWidth="6" />
          <path d={`M 0 34 C 0 120, ${60 + unplug * 40} 140, ${90 + unplug * 90} ${210 + unplug * 60}`} fill="none" stroke="#fff" strokeWidth="6" strokeLinecap="round" />
          <rect x={80 + unplug * 90} y={200 + unplug * 60} width="36" height="26" rx="5" fill="#fff" transform={`rotate(${unplug * 40} ${98 + unplug * 90} ${213 + unplug * 60})`} />
          {ring > 0 && ring < 1 && [1, 2].map((i) => (
            <circle key={i} r={40 + ring * 60 * i} fill="none" stroke={CYAN} strokeWidth="5" opacity={1 - ring} />
          ))}
          {unplug > 0.6 && <text x={140 + unplug * 90} y={200 + unplug * 40} fontSize="44">⚡</text>}
        </g>
      )}
      {stamp > 0 && (
        <g transform={`translate(540 1120) rotate(-8) scale(${1.6 - 0.6 * stamp})`} opacity={stamp}>
          <rect x="-230" y="-55" width="460" height="110" rx="14" fill="none" stroke={RED} strokeWidth="8" />
          <text x="0" y="22" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="58" fill={RED} letterSpacing="4">SINCE 2021</text>
        </g>
      )}
    </svg>
  );
};

const Villa: React.FC<{ t: number; s: SceneDef }> = ({ t, s }) => {
  const draw = r(t, s.at + 0.2, s.at + 1.0, EASE_IO);
  const buy = r(t, s.k1 ?? 99, (s.k1 ?? 99) + 0.3, POP);
  const reno = r(t, s.k2 ?? 99, (s.k2 ?? 99) + 0.6);
  const sold = r(t, s.k3 ?? 99, (s.k3 ?? 99) + 0.3, POP);
  const recK = r(t, s.k4 ?? 99, (s.k4 ?? 99) + 0.3);
  const count = t < (s.k4 ?? 99) ? 1 : 1 + Math.min(4, Math.floor((t - (s.k4 ?? 0)) / 0.6));
  const stroke = reno > 0.5 ? "#FFD27A" : "#fff";
  return (
    <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
      <path d="M 300 1000 L 300 740 L 540 560 L 780 740 L 780 1000 Z M 470 1000 L 470 860 L 610 860 L 610 1000 M 360 790 L 440 790 L 440 850 L 360 850 Z M 640 790 L 720 790 L 720 850 L 640 850 Z"
        fill="none" stroke={stroke} strokeWidth="10" strokeLinejoin="round" pathLength={1} strokeDasharray="1" strokeDashoffset={1 - draw}
        style={{ filter: reno > 0.5 ? "drop-shadow(0 0 18px rgba(255,210,122,0.9))" : undefined }} />
      {reno > 0 && reno < 1 && [[330, 700], [760, 690], [540, 520], [290, 960], [800, 950]].map(([x, y], i) => (
        <text key={i} x={x} y={y} fontSize={50 + 30 * Math.sin(reno * Math.PI)} opacity={Math.sin(reno * Math.PI)} textAnchor="middle">✨</text>
      ))}
      {buy > 0 && sold === 0 && (
        <g transform={`translate(820 620) rotate(10) scale(${buy})`}>
          <rect x="-90" y="-40" width="180" height="80" rx="14" fill="#fff" />
          <text x="0" y="16" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="44" fill="#C2502E">BUY</text>
        </g>
      )}
      {sold > 0 && (
        <g transform={`translate(540 900) rotate(-10) scale(${1.8 - 0.8 * sold})`} opacity={sold}>
          <rect x="-190" y="-62" width="380" height="124" rx="16" fill="#fff" />
          <text x="0" y="28" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="86" fill={RED} letterSpacing="6">SOLD</text>
        </g>
      )}
      {recK > 0 && (
        <g opacity={recK}>
          <circle cx="330" cy="520" r="16" fill={RED} opacity={Math.floor(t * 2) % 2 ? 1 : 0.35} />
          <text x="360" y="534" fontFamily={MONO} fontWeight="700" fontSize="40" fill="#fff">REC  sold while filming:</text>
          <text x="540" y="1190" textAnchor="middle" fontFamily={UI} fontWeight="900" fontSize="150" fill="#fff">{count}</text>
          <text x="540" y="1240" textAnchor="middle" fontFamily={MONO} fontWeight="700" fontSize="30" fill="rgba(255,255,255,0.75)">VILLAS SOLD</text>
        </g>
      )}
    </svg>
  );
};

// pins of every "top broker" pop all over the palm; on "only one" they drop away except one glowing pin
const PINS = [[300, 680], [420, 640], [540, 620], [660, 640], [780, 680], [340, 800], [460, 770], [600, 770], [740, 800],
  [300, 920], [420, 900], [660, 900], [780, 920], [540, 880]];
const Pins: React.FC<{ t: number; s: SceneDef }> = ({ t, s }) => {
  const drop = r(t, s.k2 ?? 99, (s.k2 ?? 99) + 0.6, EASE_IN);
  const glow = r(t, s.k3 ?? 99, (s.k3 ?? 99) + 0.4, POP);
  return (
    <svg width="1080" height="1920" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
      {PINS.map(([x, y], i) => {
        const at = (s.k1 ?? 99) + i * 0.1;
        const a = r(t, at, at + 0.25, POP);
        const winner = i === 13;
        const fall = winner ? 0 : drop;
        const jostle = winner ? 0 : Math.sin(t * 9 + i * 1.7) * 10 * (1 - drop);           // everyone pushing for the spot
        const toCentre = winner ? r(t, s.k3 ?? 99, (s.k3 ?? 99) + 0.5, EASE_IO) : 0;
        const px = lerp(x, 540, toCentre), py = lerp(y, 800, toCentre);
        return (
          <g key={i} transform={`translate(${px + jostle} ${py + fall * 900}) scale(${a * (winner ? 1.4 + glow * 0.6 : 1.3)})`} opacity={winner ? 1 : 1 - fall}>
            {winner && glow > 0 && <circle r={60 + 16 * Math.sin(t * 6)} fill={BLUE} opacity={0.35 * glow} />}
            <path d="M 0 0 C -26 -30, -26 -70, 0 -70 C 26 -70, 26 -30, 0 0 Z" fill={winner && glow > 0 ? BLUE : "#9AA3B2"} stroke="#fff" strokeWidth="4" />
            <circle cy="-46" r="9" fill="#fff" />
          </g>
        );
      })}
    </svg>
  );
};

// ---------- scene sequence ----------
export type SceneDef = { at: number; bg: string; num: string; title: string; sub: string; obj: "door" | "villa" | "pins";
  k1?: number; k2?: number; k3?: number; k4?: number; layer: "top" | "mid" | "bot"; handoff: number };
export type FlowDef = {
  from: number; to: number; dot: { x: number; y: number }; pip: { ox: number; oy: number }; scenes: SceneDef[];
  reveal: { at: number; sub: string; site: string }; exit: number; video: string; track: [number, number, number][];
};

const PIP = { x: 70, y: 880, d: 380 };      // face bubble (bottom left, above the captions)

const LayerImg: React.FC<{ name: string; x: number; y: number; s: number; o?: number; glow?: number }> = ({ name, x, y, s, o = 1, glow = 0 }) => (
  <Img src={staticFile(`eqt/layer-${name}.png`)} style={{ position: "absolute", left: x - s / 2, top: y - s / 2, width: s, height: s, opacity: o,
    filter: glow ? `drop-shadow(0 0 ${glow}px ${BLUE})` : undefined }} />
);

export const Flow: React.FC<{ f: FlowDef }> = ({ f }) => {
  const t = useT();
  if (t < f.from || t > f.exit + 0.5) return null;
  // which scene is showing, and how far the colour wipe into it has come
  let si = 0;
  while (si + 1 < f.scenes.length && f.scenes[si + 1].at <= t) si++;
  const s = f.scenes[si];
  const prev = si > 0 ? f.scenes[si - 1] : null;
  const open = r(t, f.from, f.from + 0.5, EASE_IO);                       // dot -> full screen
  const wipe = prev ? r(t, s.at, s.at + 0.5, EASE_IO) : 1;               // colour-field wipe between scenes
  const revealK = r(t, f.reveal.at, f.reveal.at + 0.5, EASE_IO);
  const exitK = r(t, f.exit, f.exit + 0.5, EASE_IO);                      // face bubble grows back to full screen
  const pipIn = r(t, f.from + 0.3, f.from + 0.8, POP);
  const pipCx = PIP.x + PIP.d / 2, pipCy = PIP.y + PIP.d / 2;
  const mask = exitK > 0 ? `radial-gradient(circle at ${pipCx}px ${pipCy}px, transparent ${PIP.d / 2 + exitK * 2200}px, black ${PIP.d / 2 + exitK * 2200 + 2}px)` : undefined;
  const titleK = r(t, s.at + 0.15, s.at + 0.6);
  const prevTitleOut = prev ? r(t, s.at, s.at + 0.3) : 1;

  // logo: only at the end. The three real layers fly in from three sides and lock into the mark
  const BIG = 460, CX = 540, CY = 700;
  const fromPos: Record<string, [number, number]> = { top: [540, -300], mid: [-400, 760], bot: [1480, 760] };
  const layers = (["top", "mid", "bot"] as const).map((name, i) => {
    const k = r(t, f.reveal.at + 0.1 + i * 0.12, f.reveal.at + 0.55 + i * 0.12, EASE_IO);
    return { name, x: lerp(fromPos[name][0], CX, k), y: lerp(fromPos[name][1], CY, k), sz: BIG, o: t >= f.reveal.at ? 1 : 0 };
  });
  const lock = r(t, f.reveal.at + 0.8, f.reveal.at + 1.05, POP);
  const word = r(t, f.reveal.at + 0.8, f.reveal.at + 1.2);

  const bgPrev = prev ? prev.bg : s.bg;
  // face centre at this moment (track is pre-smoothed, 10 per second), so the face stays centred in the bubble
  let ti = 0;
  while (ti + 1 < f.track.length && f.track[ti + 1][0] <= t) ti++;
  const A = f.track[ti], B = f.track[Math.min(ti + 1, f.track.length - 1)];
  const kk = B[0] > A[0] ? (t - A[0]) / (B[0] - A[0]) : 0;
  const fx = lerp(A[1], B[1], Math.max(0, Math.min(1, kk))), fy = lerp(A[2], B[2], Math.max(0, Math.min(1, kk)));
  const PS = 0.32;                                   // face is ~700-950 px tall, so this fits the whole head in the bubble
  return (
    <AbsoluteFill style={{ WebkitMaskImage: mask, maskImage: mask }}>
      {/* the scene opens out of the through-line dot */}
      <AbsoluteFill style={{ clipPath: `circle(${open * 2300}px at ${f.dot.x}px ${f.dot.y}px)` }}>
        <AbsoluteFill style={{ background: bgPrev }} />
        <AbsoluteFill style={{ background: s.bg, clipPath: `polygon(0 0, ${wipe * 220}% 0, ${wipe * 220 - 60}% 100%, 0 100%)` }} />
        <AbsoluteFill style={{ background: "#05070C", opacity: revealK }} />
        <AbsoluteFill style={{ background: `radial-gradient(60% 40% at 50% 42%, rgba(30,155,255,${0.45 * revealK}), transparent 70%)` }} />

        {/* title block, top left: TYPE 0N in mono + serif subtitle (old title slides up as the new one arrives) */}
        {revealK < 1 && (
          <div style={{ position: "absolute", left: 70, top: 270, opacity: 1 - revealK }}>
            {prev && prevTitleOut < 1 && (
              <div style={{ position: "absolute", opacity: 1 - prevTitleOut, transform: `translateY(${-prevTitleOut * 60}px)` }}>
                <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 6, color: "rgba(255,255,255,0.7)" }}>TYPE {prev.num}</div>
                <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 92, color: "#fff", lineHeight: 1 }}>{prev.title}</div>
                <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 64, color: "#fff", opacity: 0.9 }}>{prev.sub}</div>
              </div>
            )}
            <div style={{ opacity: titleK, transform: `translateY(${(1 - titleK) * 60}px)` }}>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, letterSpacing: 6, color: "rgba(255,255,255,0.7)" }}>TYPE {s.num}</div>
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 92, color: "#fff", lineHeight: 1 }}>{s.title}</div>
              <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 64, color: "#fff", opacity: 0.9 }}>{s.sub}</div>
            </div>
          </div>
        )}

        {/* the scene's object; it shrinks into its logo layer at the hand-off */}
        {f.scenes.map((sc, i) => {
          const live = t >= sc.at && t < (f.scenes[i + 1]?.at ?? f.reveal.at) + 0.05;
          if (!live) return null;
          const shrink = r(t, sc.handoff - 0.25, sc.handoff + 0.05, EASE_IN);
          return (
            <AbsoluteFill key={i} style={{ transform: `translate(70px, -40px) scale(${0.9 * (1 - shrink * 0.85)})`, transformOrigin: `${CX}px ${CY}px`, opacity: 1 - shrink }}>
              {sc.obj === "door" && <Door t={t} s={sc} />}
              {sc.obj === "villa" && <Villa t={t} s={sc} />}
              {sc.obj === "pins" && <Pins t={t} s={sc} />}
            </AbsoluteFill>
          );
        })}

        {/* logo layers travelling to the dock and assembling */}
        {layers.map((l) => l.o > 0 && <LayerImg key={l.name} name={l.name} x={l.x} y={l.y} s={l.sz} o={l.o * (1 - word)} glow={revealK * 30} />)}
        {revealK > 0 && (
          <div style={{ position: "absolute", left: 0, right: 0, top: CY - BIG / 2, display: "flex", justifyContent: "center",
            opacity: word, transform: `scale(${0.96 + 0.04 * lock})` }}>
            <Img src={staticFile("eqt/logo-mark.png")} style={{ width: BIG, height: BIG, filter: `drop-shadow(0 0 40px ${BLUE})` }} />
          </div>
        )}
        {revealK > 0 && (
          <div style={{ position: "absolute", left: 0, right: 0, top: CY + BIG / 2 - 10, textAlign: "center" }}>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 150, color: "#fff", letterSpacing: 18 * (1 - word) + 6, opacity: word,
              filter: `blur(${(1 - word) * 12}px)` }}>EQT</div>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 34, letterSpacing: 14, color: CYAN, opacity: r(t, f.reveal.at + 1.0, f.reveal.at + 1.35) }}>{f.reveal.sub}</div>
            <div style={{ display: "inline-block", marginTop: 34, padding: "16px 40px", borderRadius: 50, background: BLUE, color: "#fff", fontFamily: UI,
              fontWeight: 900, fontSize: 60, letterSpacing: 1, boxShadow: `0 0 40px ${BLUE}`, opacity: r(t, f.reveal.at + 1.3, f.reveal.at + 1.6),
              transform: `scale(${0.8 + 0.2 * r(t, f.reveal.at + 1.3, f.reveal.at + 1.6, POP)})` }}>{f.reveal.site}</div>
          </div>
        )}

      </AbsoluteFill>

      {/* face bubble: stays put through every scene (part of the through-line) */}
      <div style={{ position: "absolute", left: PIP.x, top: PIP.y, width: PIP.d, height: PIP.d, borderRadius: PIP.d / 2, overflow: "hidden",
        border: "6px solid #fff", boxShadow: `0 0 40px rgba(30,155,255,0.55)`, transform: `scale(${pipIn * (1 - exitK) * (1 - 0.38 * revealK * (1 - exitK))})`, transformOrigin: "0% 100%", opacity: 1 - exitK }}>
        <div style={{ position: "absolute", width: 1080, height: 1920, left: -(fx * PS) + PIP.d / 2, top: -(fy * PS) + PIP.d / 2,
          transform: `scale(${PS})`, transformOrigin: "0 0" }}>
          <OffthreadVideo src={staticFile(f.video)} muted style={{ width: 1080, height: 1920 }} />
        </div>
      </div>
    </AbsoluteFill>
  );
};
