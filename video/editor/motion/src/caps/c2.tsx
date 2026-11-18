import React from "react";
import { AbsoluteFill, Easing } from "remotion";
import { loadFont as loadArchivoBlack } from "@remotion/google-fonts/ArchivoBlack";
import { CapItem, Clip, Person, WORDS, Word, chunk, isKey } from "./capcommon";
import { C, DISPLAY, EASE, EASE_IN, MONO, POP, SERIF, Sfx, UI, clamp, lerp, r, rand, useT } from "../lib/common";

// Caption lab, batch c2: 10 caption styles over the same 11.6 s clip of Max.
// Clip geometry (close-up shots): mouth ≈ y 1110-1140, chin up to ≈ 1290, so captions live in the chest band
// y ≈ 1180-1410 (x 60-900, right rail kept clear) and never cover eyes/mouth.

const { fontFamily: ARCHIVO } = loadArchivoBlack("normal", { subsets: ["latin"] });
const LIN = Easing.linear;
const SH = "0 3px 2px rgba(0,0,0,0.35), 0 6px 24px rgba(0,0,0,0.55)";
const G = (a: number, b: number) => WORDS.slice(a, b + 1);
const END = 99;
const BAND_BOTTOM = 1405; // last caption line sits on this y

// ============ c2-01 Karaoke sweep ============
const KPAGES: Word[][][] = [[[0, 2], [3, 8]], [[9, 12], [13, 15]], [[16, 19], [20, 23], [24, 26]], [[27, 30], [31, 34]]]
  .map((p) => p.map(([a, b]) => G(a, b)));
const kStart = (i: number) => (i === 0 ? 0 : KPAGES[i][0][0].s - 0.3);
const Karaoke: React.FC = () => {
  const t = useT();
  return (
    <AbsoluteFill>
      <Clip />
      {KPAGES.map((page, pi) => {
        const from = kStart(pi), to = pi + 1 < KPAGES.length ? kStart(pi + 1) : END;
        if (t < from || t >= to) return null;
        const kin = pi === 0 ? 1 : r(t, from, from + 0.22), kout = r(t, to - 0.18, to, EASE_IN);
        const flat = page.flat();
        let ai = -1;
        flat.forEach((w, i) => { if (t >= w.s) ai = i; });
        return (
          <div key={pi} style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - BAND_BOTTOM, display: "flex", flexDirection: "column",
            alignItems: "center", gap: 4, opacity: kin * (1 - kout), transform: `translateY(${(1 - kin) * 34 - kout * 34}px)` }}>
            {page.map((line, li) => (
              <div key={li} style={{ display: "flex", columnGap: 17, justifyContent: "center" }}>
                {line.map((w) => {
                  const idx = flat.indexOf(w);
                  const f = r(t, w.s, Math.max(w.s + 0.12, w.e), LIN);
                  const next = flat[idx + 1];
                  const p = clamp((t - w.s) / ((next ? next.s : w.e + 0.15) - w.s));
                  return (
                    <span key={idx} style={{ position: "relative", display: "inline-block", fontFamily: UI, fontWeight: 800, fontSize: 62,
                      lineHeight: 1.16, letterSpacing: -0.5 }}>
                      <span style={{ color: "#fff", textShadow: SH }}>{w.w}</span>
                      <span style={{ position: "absolute", left: 0, top: 0, color: C.gold, clipPath: `inset(-30% ${100 - f * 100}% -30% -5%)`,
                        textShadow: "0 3px 2px rgba(0,0,0,0.35)" }}>{w.w}</span>
                      {idx === ai && (
                        <span style={{ position: "absolute", left: `calc(${p * 100}% - 10px)`, top: -16 - Math.sin(Math.PI * p) * 24, width: 20, height: 20,
                          borderRadius: 10, background: C.gold, boxShadow: "0 3px 6px rgba(0,0,0,0.45)" }} />
                      )}
                    </span>
                  );
                })}
              </div>
            ))}
          </div>
        );
      })}
      {KPAGES.slice(1).map((_, i) => <Sfx key={i} at={kStart(i + 1)} s="swish" v={0.1} />)}
    </AbsoluteFill>
  );
};

// ============ c2-02 Terminal ============
type TLine = { prefix: string; words: Word[] };
const TLINES: TLine[] = (() => {
  const out: TLine[] = [];
  [G(0, 15), G(16, 26), G(27, 34)].forEach((s) => {
    let cur: Word[] = [], len = 2, first = true;
    for (const w of s) {
      if (cur.length && len + 1 + w.w.length > 27) { out.push({ prefix: first ? "$" : " ", words: cur }); first = false; cur = []; len = 2; }
      len += (cur.length ? 1 : 0) + w.w.length; cur.push(w);
    }
    out.push({ prefix: first ? "$" : " ", words: cur });
  });
  return out;
})();
const typeDur = (w: Word) => Math.min(0.28, Math.max(0.1, w.e - w.s));
const Terminal: React.FC = () => {
  const t = useT();
  const FS = 40, LH = 54, VIS = 3, TB = 50, PAD = 18;
  const H = TB + VIS * LH + PAD * 2, top = BAND_BOTTOM - H;
  const shown = TLINES.reduce((a, l, i) => a + (i === 0 ? 1 : r(t, l.words[0].s - 0.02, l.words[0].s + 0.16)), 0);
  const scroll = Math.max(0, shown - VIS) * LH;
  let curLine = 0;
  TLINES.forEach((l, i) => { if (t >= l.words[0].s - 0.02) curLine = i; });
  const last = WORDS.filter((w) => t >= w.s).pop();
  const typing = !!last && t < last.s + typeDur(last) + 0.15;
  const cursorOn = typing || Math.floor(t * 2.2) % 2 === 0;
  const kin = r(t, 0, 0.25);
  return (
    <AbsoluteFill>
      <Clip />
      <div style={{ position: "absolute", left: 70, width: 810, top, height: H, borderRadius: 22, background: "rgba(14,15,17,0.94)",
        border: "1.5px solid rgba(255,255,255,0.14)", boxShadow: "0 22px 50px rgba(0,0,0,0.35)", overflow: "hidden",
        opacity: kin, transform: `translateY(${(1 - kin) * 20 + Math.sin(t * 1.3) * 3}px) scale(${0.96 + 0.04 * kin})` }}>
        <div style={{ height: TB, display: "flex", alignItems: "center", gap: 10, padding: "0 22px", borderBottom: "1.5px solid rgba(255,255,255,0.08)",
          background: "rgba(255,255,255,0.04)" }}>
          {["#5A5A5E", "#5A5A5E", "#5A5A5E"].map((c, i) => <div key={i} style={{ width: 16, height: 16, borderRadius: 8, background: c }} />)}
          <div style={{ flex: 1, textAlign: "center", fontFamily: MONO, fontWeight: 500, fontSize: 28, color: "rgba(255,255,255,0.5)", marginRight: 60 }}>~/ai-apps · zsh</div>
        </div>
        <div style={{ position: "relative", height: VIS * LH, margin: `${PAD}px 26px`, overflow: "hidden" }}>
          <div style={{ transform: `translateY(${-scroll}px)` }}>
            {TLINES.map((l, li) => {
              const vis = li === 0 || t >= l.words[0].s - 0.02;
              return (
                <div key={li} style={{ height: LH, display: "flex", alignItems: "center", whiteSpace: "pre", fontFamily: MONO, fontWeight: 500, fontSize: FS,
                  opacity: vis ? 1 : 0, color: "#E8E8EA" }}>
                  <span style={{ color: C.teal, fontWeight: 700 }}>{l.prefix} </span>
                  {l.words.map((w, wi) => {
                    const n = Math.floor(w.w.length * clamp((t - w.s) / typeDur(w)));
                    const key = isKey(w);
                    return (
                      <span key={wi} style={{ color: key ? C.green : "#E8E8EA", fontWeight: key ? 700 : 500 }}>
                        {(wi ? " " : "") + w.w.slice(0, n)}
                      </span>
                    );
                  }).filter((_, wi) => t >= l.words[wi].s)}
                  {li === curLine && (
                    <span style={{ display: "inline-block", width: FS * 0.6, height: FS * 1.05, marginLeft: 3, background: C.green, opacity: cursorOn ? 0.95 : 0 }} />
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
      {WORDS.map((w, i) => <Sfx key={i} at={w.s} s="type" v={isKey(w) ? 0.12 : 0.07} />)}
    </AbsoluteFill>
  );
};

// ============ c2-03 3D slam ============
const SLAM = chunk(WORDS, 2, 0.25);
const slamFrom = (i: number) => SLAM[i].words[0].s - 0.15;

// ============ c2-04 Chat bubbles ============
const CHAT = [[0, 2], [3, 8], [9, 12], [13, 15], [16, 18], [19, 21], [22, 23], [24, 26], [27, 30], [31, 34]]
  .map(([a, b], i, arr) => {
    const from = WORDS[a].s;
    const prev = i ? WORDS[arr[i - 1][0]].s : -1;
    return { words: G(a, b), from, dots: Math.max(0, prev + 0.12, from - 0.4) };
  });
const Chat: React.FC = () => {
  const t = useT();
  const BH = 86, GAP = 14;
  const vis = CHAT.filter((b) => t >= b.dots);
  return (
    <AbsoluteFill>
      <Clip />
      <div style={{ position: "absolute", left: 60, width: 840, top: 1150, height: BAND_BOTTOM - 1150, overflow: "hidden",
        WebkitMaskImage: "linear-gradient(to bottom, transparent 0px, black 80px)", maskImage: "linear-gradient(to bottom, transparent 0px, black 80px)",
        display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
        {vis.map((b, bi) => {
          const hk = r(t, b.dots, b.dots + 0.2, EASE);
          const k = r(t, b.from - 0.06, b.from + 0.2, EASE);
          const age = vis.length - 1 - bi;
          return (
            <div key={b.from} style={{ height: hk * (BH + GAP), flexShrink: 0, position: "relative", opacity: age === 0 ? 1 : age === 1 ? 0.93 : 0.82 }}>
              <div style={{ position: "absolute", left: 80, bottom: 0, height: BH, maxWidth: lerp(132, 760, k), overflow: "hidden", borderRadius: "42px 42px 42px 12px",
                background: "#FFFFFF", boxShadow: "0 10px 24px rgba(0,0,0,0.28)", transformOrigin: "0% 100%", transform: `scale(${lerp(0.5, 1, hk)})`,
                display: "flex", alignItems: "center" }}>
                <div style={{ display: "flex", gap: 12, position: "absolute", left: 34, opacity: 1 - k }}>
                  {[0, 1, 2].map((d) => (
                    <div key={d} style={{ width: 16, height: 16, borderRadius: 8, background: "#9A9AA0", transform: `translateY(${Math.sin(t * 14 - d * 0.9) * 6}px)` }} />
                  ))}
                </div>
                <div style={{ padding: "0 32px", whiteSpace: "nowrap", fontFamily: UI, fontWeight: 600, fontSize: 46, color: C.ink, opacity: k, letterSpacing: -0.3 }}>
                  {b.words.filter((w, wi) => wi === 0 || t >= w.s - 0.03).map((w, wi) => {
                    const a = r(t, w.s - 0.03, w.s + 0.08);
                    return (
                      <span key={wi} style={{ opacity: a, color: isKey(w) ? C.blue : C.ink, fontWeight: isKey(w) ? 800 : 600 }}>{(wi ? " " : "") + w.w}</span>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>
      {/* avatar sits next to the newest message */}
      <div style={{ position: "absolute", left: 60, top: BAND_BOTTOM - 64, width: 64, height: 64, borderRadius: 32, background: C.blue, color: "#fff",
        display: "flex", alignItems: "center", justifyContent: "center", fontFamily: UI, fontWeight: 800, fontSize: 32, border: "3px solid #fff",
        boxShadow: "0 6px 16px rgba(0,0,0,0.3)", transform: `scale(${r(t, 0, 0.25, POP)})` }}>M</div>
      {CHAT.map((b, i) => <Sfx key={i} at={b.from - 0.05} s="pop" v={0.15} />)}
    </AbsoluteFill>
  );
};

// ============ c2-05 Word ladder ============
const LADDER: { lead: Word[]; pay: Word[]; tail?: Word[] }[] = [
  { lead: G(0, 1), pay: G(2, 2) }, { lead: G(3, 6), pay: G(7, 8) }, { lead: G(9, 9), pay: G(10, 10) }, { lead: G(11, 14), pay: G(15, 15) },
  { lead: G(16, 16), pay: G(17, 17) }, { lead: G(18, 23), pay: G(24, 25), tail: G(26, 26) }, { lead: G(27, 30), pay: G(31, 31) }, { lead: G(32, 33), pay: G(34, 34) },
];
const LIME = "#D6FF3B";
const ladFrom = (i: number) => (i === 0 ? 0 : LADDER[i].lead[0].s - 0.05);

// ============ c2-06 Outline → fill ============
const OUTL = chunk(WORDS, 3, 0.3).map((c) => {
  const chars = c.words.map((w) => w.w).join(" ").length;
  const lines = chars > 11 && c.words.length > 1 ? [c.words.slice(0, Math.ceil(c.words.length / 2)), c.words.slice(Math.ceil(c.words.length / 2))] : [c.words];
  const maxC = Math.max(...lines.map((l) => l.map((w) => w.w).join(" ").length));
  return { ...c, lines, fs: Math.min(124, 800 / (maxC * 0.78)) };
});
const ORANGE = "#FF5A1F";
const Outline: React.FC = () => {
  const t = useT();
  let ci = 0;
  OUTL.forEach((c, i) => { if (t >= c.from - 0.12) ci = i; });
  const c = OUTL[ci];
  const st = c.from - 0.12;
  const nextFrom = ci + 1 < OUTL.length ? OUTL[ci + 1].from - 0.12 : END;
  const out = r(t, nextFrom - 0.1, nextFrom, EASE_IN);
  const fs = c.fs;
  let wi = 0;
  return (
    <AbsoluteFill>
      <Clip />
      <div style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - BAND_BOTTOM, display: "flex", flexDirection: "column", alignItems: "center",
        gap: fs * 0.06, opacity: 1 - out, transform: `scale(${1 - out * 0.06})`, filter: "drop-shadow(0 4px 10px rgba(0,0,0,0.45))" }}>
        {c.lines.map((line, li) => (
          <div key={li} style={{ display: "flex", columnGap: fs * 0.28 }}>
            {line.map((w) => {
              const idx = wi++;
              const draw = r(t, st + idx * 0.04, st + idx * 0.04 + 0.26, EASE);
              const f = r(t, w.s, w.s + Math.max(0.14, Math.min(0.3, w.e - w.s)), EASE);
              const word = w.w.toUpperCase();
              const col = isKey(w) ? ORANGE : "#FFFFFF";
              const id = `c2-06-${ci}-${idx}`;
              const base = fs * 0.86;
              return (
                <span key={idx} style={{ position: "relative", display: "inline-block", fontFamily: ARCHIVO, fontSize: fs, lineHeight: 1.04, color: "transparent", whiteSpace: "pre" }}>
                  {word}
                  <svg style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }} width="100%" height="100%">
                    <defs><clipPath id={id}><rect x={-20} y={base + fs * 0.04 - fs * 0.84 * f} width={fs * 10} height={fs * 2} /></clipPath></defs>
                    <text x={0} y={base} fontFamily={ARCHIVO} fontSize={fs} fill={col} clipPath={`url(#${id})`}>{word}</text>
                    <text x={0} y={base} fontFamily={ARCHIVO} fontSize={fs} fill="none" stroke={isKey(w) && f > 0 ? ORANGE : "#FFFFFF"} strokeWidth={3.2}
                      strokeLinejoin="round" strokeDasharray={fs * 4.2} strokeDashoffset={fs * 4.2 * (1 - draw)}>{word}</text>
                  </svg>
                </span>
              );
            })}
          </div>
        ))}
      </div>
      {OUTL.map((o, i) => <Sfx key={i} at={o.from - 0.12} s="swish" v={0.07} />)}
    </AbsoluteFill>
  );
};

// ============ c2-07 Glass pills stepper ============
const PILLS = chunk(WORDS, 3, 0.3);
const CREAM = "#F6EBDD", BURNT = "#C4561D", CHOC = "#3B2418";
const estW = (s: string) => s.length * 22.5 + 80 + 64;  // ≈ Inter 600 @42 px + padding + step number (conservative)
const Pills: React.FC = () => {
  const t = useT();
  const PH = 78, PG = 14, PITCH = PH + PG;
  const shown = PILLS.reduce((a, p, i) => a + (i === 0 ? 1 : r(t, p.from - 0.05, p.from + 0.22, EASE)), 0);
  let ai = 0;
  PILLS.forEach((p, i) => { if (t >= p.from - 0.05) ai = i; });
  const rowY = (i: number) => BAND_BOTTOM - PH - (shown - 1 - i) * PITCH;   // newest at the bottom
  // tether from the active pill's right end to a dot on his chest
  const prevW = ai ? estW(PILLS[ai - 1].words.map((w) => w.w).join(" ")) : 300;
  const curW = estW(PILLS[ai].words.map((w) => w.w).join(" "));
  const sw = r(t, PILLS[ai].from - 0.05, PILLS[ai].from + 0.25, EASE);
  const x0 = 66 + lerp(prevW, curW, sw) * 0.82, y0 = BAND_BOTTOM - PH / 2;
  const ax = 800 + Math.sin(t * 1.1) * 6, ay = 1250 + Math.sin(t * 1.4) * 5;
  const draw = r(t, 0.1, 0.6, EASE);
  return (
    <AbsoluteFill>
      <Clip />
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        <path d={`M ${x0} ${y0} C ${x0 + 90} ${y0}, ${ax - 80} ${ay + 60}, ${ax} ${ay}`} fill="none" stroke={CREAM} strokeWidth={3} strokeLinecap="round"
          strokeDasharray={900} strokeDashoffset={900 * (1 - draw)} opacity={0.9} />
        <circle cx={ax} cy={ay} r={11 * draw} fill={BURNT} stroke={CREAM} strokeWidth={3} />
        <circle cx={ax} cy={ay} r={11 + 26 * ((t * 0.9) % 1)} fill="none" stroke={CREAM} strokeWidth={2} opacity={draw * (1 - ((t * 0.9) % 1)) * 0.8} />
        {/* stepper rail */}
        <line x1={50} y1={Math.max(1150, rowY(0) + PH / 2)} x2={50} y2={BAND_BOTTOM - PH / 2} stroke={CREAM} strokeWidth={2.5} opacity={0.55} />
      </svg>
      {PILLS.map((p, i) => {
        if (i > ai) return null;
        const y = rowY(i);
        if (y < 1060) return null;
        const vis = clamp((y - 1080) / 90);
        const k = i === 0 ? r(t, 0, 0.25) : r(t, p.from - 0.05, p.from + 0.22, EASE);
        const active = i === ai;
        const ak = active ? 1 : 1 - r(t, PILLS[i + 1].from - 0.05, PILLS[i + 1].from + 0.2);
        return (
          <div key={i} style={{ position: "absolute", left: 66, top: y, height: PH, display: "flex", alignItems: "center", gap: 18, padding: "0 32px 0 22px",
            borderRadius: PH / 2, background: ak > 0.5 ? `rgba(196,86,29,${0.55 + 0.37 * ak})` : "rgba(59,36,24,0.5)",
            backdropFilter: "blur(14px) saturate(1.3)", WebkitBackdropFilter: "blur(14px) saturate(1.3)",
            border: `1.5px solid rgba(246,235,221,${0.35 + 0.3 * ak})`, boxShadow: "0 10px 26px rgba(40,20,10,0.3)",
            opacity: vis * k, transform: `translateX(${(1 - k) * -40}px) scale(${0.94 + 0.06 * k})`, transformOrigin: "0% 50%" }}>
            <div style={{ width: 44, height: 44, borderRadius: 22, background: ak > 0.5 ? CREAM : "rgba(246,235,221,0.18)", color: ak > 0.5 ? BURNT : CREAM,
              fontFamily: MONO, fontWeight: 700, fontSize: 24, display: "flex", alignItems: "center", justifyContent: "center" }}>{String(i + 1).padStart(2, "0")}</div>
            <div style={{ fontFamily: UI, fontWeight: 600, fontSize: 42, color: CREAM, whiteSpace: "nowrap", letterSpacing: -0.3 }}>
              {p.words.map((w, wi) => {
                const a = r(t, w.s - 0.02, w.s + 0.16);
                return (
                  <span key={wi} style={{ opacity: Math.max(0.25, a), filter: a < 1 ? `blur(${(1 - a) * 8}px)` : undefined,
                    fontFamily: isKey(w) ? SERIF : UI, fontStyle: isKey(w) ? "italic" : "normal", fontSize: isKey(w) ? 52 : 42,
                    fontWeight: isKey(w) ? 400 : 600 }}>{(wi ? " " : "") + w.w}</span>
                );
              })}
            </div>
          </div>
        );
      })}
      {PILLS.map((p, i) => <Sfx key={i} at={p.from - 0.05} s="tick" v={0.16} />)}
    </AbsoluteFill>
  );
};

// ============ c2-08 Flying 3D words ============
const FLY = chunk(WORDS, 4, 0.3);
const flyFrom = (i: number) => FLY[i].words[0].s - 0.42;
const flyPose = (p: number, seed: number) => {
  const side = rand(seed) > 0.5 ? 1 : -1;
  const dx = side * (260 + rand(seed + 1) * 260), dy = -(420 + rand(seed + 2) * 260), dz = -1300;
  const q = 1 - p;
  return `translate3d(${dx * q + side * Math.sin(Math.PI * p) * 170}px, ${dy * q * q}px, ${dz * q}px) rotateY(${q * side * -55}deg) rotateZ(${q * side * 18}deg)`;
};
// a block stays until the NEXT block's first word lands (so it's on screen long enough to read), then zooms past the camera
const flyEnd = (i: number) => (i + 1 < FLY.length ? FLY[i + 1].words[0].s + 0.02 : END);
const FlyBlocks: React.FC<{ layer: "back" | "front" }> = ({ layer }) => {
  const t = useT();
  return <>{FLY.map((_, i) => (t >= flyFrom(i) && t < flyEnd(i) ? <FlyBlock key={i} ci={i} layer={layer} /> : null))}</>;
};
const FlyBlock: React.FC<{ ci: number; layer: "back" | "front" }> = ({ ci, layer }) => {
  const t = useT();
  const c = FLY[ci];
  const nextFrom = flyEnd(ci);
  const out = r(t, nextFrom - 0.32, nextFrom, EASE_IN);
  const half = Math.ceil(c.words.length / 2);
  const lines = c.words.length > 2 ? [c.words.slice(0, half), c.words.slice(half)] : [c.words];
  let wi = 0;
  return (
    <div style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - BAND_BOTTOM + 10, display: "flex", flexDirection: "column", alignItems: "center",
      perspective: 1000, perspectiveOrigin: "50% -60%", opacity: 1 - out, filter: out > 0 ? `blur(${out * 6}px)` : undefined,
      transform: `scale(${1 + out * 0.25}) translateY(${-out * 40}px)` }}>
      {lines.map((line, li) => (
        <div key={li} style={{ display: "flex", columnGap: 20, alignItems: "baseline", height: 96, transformStyle: "preserve-3d" }}>
          {line.map((w) => {
            const idx = wi++;
            const seed = ci * 10 + idx;
            const p = r(t, w.s - 0.4, w.s + 0.02, EASE);
            const key = isKey(w);
            const style: React.CSSProperties = key
              ? { fontFamily: SERIF, fontStyle: "italic", fontSize: 108, color: C.gold, lineHeight: 1.0 }
              : { fontFamily: UI, fontWeight: 800, fontSize: 80, color: "#fff", lineHeight: 1.08, letterSpacing: -1 };
            const inBack = p < 0.45;
            const show = layer === "back" ? inBack && p > 0 : !inBack;
            const ghosts = layer === "front" && p < 0.995 && !inBack ? [1, 2, 3] : [];
            return (
              <span key={idx} style={{ ...style, position: "relative", display: "inline-block", transformStyle: "preserve-3d" }}>
                <span style={{ visibility: "hidden" }}>{w.w}</span>
                {ghosts.map((g) => (
                  <span key={g} style={{ position: "absolute", left: 0, top: 0, opacity: 0.16 / g, transform: flyPose(Math.max(0, p - g * 0.05), seed),
                    textShadow: SH }}>{w.w}</span>
                ))}
                {show && (
                  <span style={{ position: "absolute", left: 0, top: 0, transform: flyPose(p, seed), textShadow: SH, opacity: clamp(p * 4),
                    filter: p < 0.9 ? `blur(${(1 - p) * 5}px)` : undefined }}>{w.w}</span>
                )}
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
};
const Flying: React.FC = () => (
  <AbsoluteFill>
    <Clip />
    <FlyBlocks layer="back" />
    <Person />
    <FlyBlocks layer="front" />
    {FLY.map((_, i) => <Sfx key={i} at={flyFrom(i) + 0.05} s="whoosh" v={0.13} />)}
  </AbsoluteFill>
);

// ============ c2-09 Highlighter tape ============
const STRIPS = [[0, 2], [3, 8], [9, 12], [13, 15], [16, 19], [20, 23], [24, 26], [27, 30], [31, 34]].map(([a, b]) => G(a, b));
const TBLOCKS = [[0, 1], [2, 3], [4, 5], [6], [7, 8]];
const HL = ["#FFE14A", "#B8F35A", "#FF9EC0"];
const tornClip = (seed: number) => {
  const pts: string[] = [];
  const n = 7;
  for (let i = 0; i <= n; i++) pts.push(`${(rand(seed + i) * 2.2).toFixed(2)}% ${(i / n) * 100}%`);       // left edge (top→bottom)
  for (let i = n; i >= 0; i--) pts.push(`${(100 - rand(seed + 40 + i) * 2.2).toFixed(2)}% ${(i / n) * 100}%`); // right edge (bottom→top)
  return `polygon(${pts.join(", ")})`;
};
const blockFrom = (bi: number) => (bi === 0 ? 0 : STRIPS[TBLOCKS[bi][0]][0].s - 0.1);
const Tape: React.FC = () => {
  const t = useT();
  let bi = 0;
  TBLOCKS.forEach((_, i) => { if (t >= blockFrom(i)) bi = i; });
  const to = bi + 1 < TBLOCKS.length ? blockFrom(bi + 1) : END;
  const out = r(t, to - 0.16, to, EASE_IN);
  let keyN = 0;
  return (
    <AbsoluteFill>
      <Clip />
      <div style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - BAND_BOTTOM, display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
        opacity: 1 - out, transform: `translateY(${out * 40}px)` }}>
        {TBLOCKS[bi].map((si, k) => {
          const words = STRIPS[si];
          const at = si === 0 ? 0 : words[0].s - 0.1;
          const s = si === 0 ? 1 : r(t, at, at + 0.18, EASE);
          const rot = (rand(si * 3) - 0.5) * 3.6;
          return (
            <div key={si} style={{ position: "relative", marginLeft: k % 2 ? 60 : -40, opacity: clamp(s * 3),
              transform: `rotate(${rot + (1 - s) * 5}deg) scale(${1 + (1 - s) * 0.14})`, filter: "drop-shadow(0 6px 10px rgba(0,0,0,0.3))" }}>
              <div style={{ clipPath: tornClip(si * 17), background: "linear-gradient(180deg, #F7F2E6 0%, #EFE8D8 100%)", padding: "12px 38px 14px",
                display: "flex", columnGap: 14, fontFamily: UI, fontWeight: 800, fontSize: 56, color: "#151515", letterSpacing: -0.6, lineHeight: 1.1 }}>
                {words.map((w, wi) => {
                  const said = r(t, w.s - 0.03, w.s + 0.07);
                  const key = isKey(w);
                  const m = r(t, w.s, w.s + 0.24, LIN);
                  const col = HL[(keyN += key ? 1 : 0) % HL.length];
                  return (
                    <span key={wi} style={{ position: "relative", display: "inline-block" }}>
                      {key && (
                        <svg style={{ position: "absolute", left: -8, top: "18%", width: "calc(100% + 16px)", height: "70%", overflow: "visible" }} viewBox="0 0 100 40" preserveAspectRatio="none">
                          <path d={`M2 ${6 + rand(wi) * 4} L98 ${3 + rand(wi + 1) * 4} L99 ${34 + rand(wi + 2) * 4} L1 ${37 - rand(wi + 3) * 3} Z`} fill={col}
                            style={{ clipPath: `inset(0 ${100 - m * 100}% 0 0)` }} />
                        </svg>
                      )}
                      <span style={{ position: "relative", opacity: 0.22 + 0.78 * said }}>{w.w}</span>
                    </span>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
      {STRIPS.slice(1).map((w, i) => <Sfx key={i} at={w[0].s - 0.1} s="swish" v={0.12} />)}
      {WORDS.filter(isKey).map((w, i) => <Sfx key={"k" + i} at={w.s} s="tick" v={0.12} />)}
    </AbsoluteFill>
  );
};

// ============ c2-10 Colour punch ============
// Each phrase rides on a solid colour card that wipes to the next colour; key words invert into a tilted chip, the frame edge
// camera punches in. No background swap: the room stays real. (Max 2026-10-12: no frame border matching the caption colour.)
const PUNCH = chunk(WORDS, 3, 0.3);
const PAL = [{ bg: C.blue, fg: "#fff" }, { bg: C.gold, fg: C.ink }, { bg: C.pink, fg: "#fff" }, { bg: C.green, fg: C.ink }, { bg: C.purple, fg: "#fff" }, { bg: C.orange, fg: C.ink }];
const punchFrom = (i: number) => (i === 0 ? 0 : PUNCH[i].words[0].s - 0.06);
const Punch: React.FC = () => {
  const t = useT();
  let ci = 0;
  PUNCH.forEach((_, i) => { if (t >= punchFrom(i)) ci = i; });
  const c = PUNCH[ci], pal = PAL[ci % PAL.length], prev = PAL[(ci + PAL.length - 1) % PAL.length];
  const q = ci === 0 ? 1 : r(t, punchFrom(ci), punchFrom(ci) + 0.2, EASE);
  let flash = 0;
  for (const w of WORDS) if (isKey(w) && t >= w.s - 0.03) {
    const d = t - w.s + 0.03;
    const v = d < 0.06 ? d / 0.06 : Math.max(0, 1 - (d - 0.06) / 0.45);
    if (v > flash) flash = v;
  }
  const fl = EASE(flash);
  return (
    <AbsoluteFill>
      <Clip zoom={1.03 + 0.085 * fl} />
      <div style={{ position: "absolute", left: 60, width: 840, bottom: 1920 - BAND_BOTTOM, display: "flex", justifyContent: "center" }}>
        <div style={{ position: "relative", borderRadius: 22, background: prev.bg, overflow: "hidden", maxWidth: 820, padding: "18px 30px 20px",
          boxShadow: "0 16px 36px rgba(0,0,0,0.35)", transform: `rotate(${ci % 2 ? 1.5 : -1.5}deg) scale(${0.92 + 0.08 * q})` }}>
          <div style={{ position: "absolute", inset: 0, background: pal.bg, clipPath: `polygon(0 0, ${q * 135}% 0, ${q * 135 - 35}% 100%, 0 100%)` }} />
          <div style={{ position: "relative", display: "flex", flexWrap: "wrap", justifyContent: "center", alignItems: "center", columnGap: 18, rowGap: 6 }}>
            {c.words.map((w, i) => {
              const a = r(t, w.s - 0.04, w.s + 0.1, EASE);
              const key = isKey(w);
              return (
                <span key={i} style={{ display: "inline-block", fontFamily: UI, fontWeight: 900, fontSize: key ? 84 : 70, lineHeight: 1.08, textTransform: "uppercase",
                  letterSpacing: -1.5, color: key ? pal.bg : pal.fg, background: key ? pal.fg : "transparent", padding: key ? "0 16px" : 0,
                  borderRadius: 12, opacity: a, transform: `translateY(${(1 - a) * 26}px) rotate(${key ? -3 * a : 0}deg) scale(${key ? 1 + (1 - a) * 0.3 : 1})` }}>
                  {w.w}
                </span>
              );
            })}
          </div>
        </div>
      </div>
      {PUNCH.slice(1).map((_, i) => <Sfx key={i} at={punchFrom(i + 1)} s="swish" v={0.1} />)}
      {WORDS.filter(isKey).map((w, i) => <Sfx key={"k" + i} at={w.s - 0.03} s="impact" v={0.2} />)}
    </AbsoluteFill>
  );
};

export const C2: CapItem[] = [
  { id: "c2-01", title: "Karaoke sweep", note: "Full sentence lines (2-3 at a time); a gold fill sweeps through each word as it's spoken, a little ball hops along. Easy to follow, no SFX except a soft swish per page.", C: Karaoke },
  { id: "c2-04", title: "Chat bubbles", note: "Each phrase arrives as a message (typing dots → bubble), stacking upward like a messaging thread; key words blue, soft pop per message.", C: Chat },
  { id: "c2-07", title: "Glass pills stepper", note: "karan.mp4_ #5: frosted pills per phrase in a numbered stepper, active pill burnt orange, a thin cream tether to his chest; serif italic key words.", C: Pills },
  { id: "c2-08", title: "Flying 3D words", note: "johnbucog-style: words fly out from behind his head on curved 3D paths with motion trails, then settle into a 2-line block; key words gold serif.", C: Flying },
  { id: "c2-09", title: "Highlighter tape", note: "Black text on torn paper-tape strips that slap on; key words get a hand-drawn highlighter swipe (yellow/green/pink).", C: Tape },
  { id: "c2-10", title: "Colour punch", note: "Phrase on a solid colour card that wipes to a new colour each phrase; key words invert into a chip and the camera punches in (no frame border).", C: Punch },
];
