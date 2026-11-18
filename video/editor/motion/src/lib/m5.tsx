import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile } from "remotion";
import {
  useT, r, lerp, clamp, env, typed, float, rand, mix, C, EASE, EASE_IN, EASE_IO, POP, LIQUID,
  Backdrop, Sounds, Label, Odo, DemoCaption, LibItem, UI, SERIF, MONO, DISPLAY,
} from "./common";

// family 5 of the motion-graphics library: real-estate & money explainers (EQT).
// All AED amounts are round, clearly illustrative numbers (no claims about real current fees or laws).
const FAM = "Real-estate & money explainers";
const fmt = (n: number) => Math.round(n).toLocaleString("en-US");

// ---------- shared helpers (local to m5) ----------
/** odometer with thousands commas; rests on whole numbers */
const OdoC: React.FC<{ value: number; size: number; color?: string; font?: string; weight?: number }> = ({ value, size, color = "#fff", font = UI, weight = 900 }) => {
  const v = Math.max(0, value);
  const digits = String(Math.round(v)).length;
  const out: React.ReactNode[] = [];
  for (let d = digits - 1; d >= 0; d--) {
    const p = Math.pow(10, d), base = Math.floor(v / p) % 10;
    const c = d === 0 ? base + (v - Math.floor(v)) : base + Math.max(0, (v % p) - (p - 1));
    out.push(
      <div key={`d${d}`} style={{ height: size * 1.05, overflow: "hidden" }}>
        <div style={{ transform: `translateY(${-c * size * 1.05}px)` }}>
          {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
            <div key={j} style={{ height: size * 1.05, fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: font, fontWeight: weight, textAlign: "center" }}>{n}</div>
          ))}
        </div>
      </div>,
    );
    if (d > 0 && d % 3 === 0) out.push(<div key={`c${d}`} style={{ fontSize: size, lineHeight: `${size * 1.05}px`, fontFamily: font, fontWeight: weight }}>,</div>);
  }
  return <div style={{ display: "flex", height: size * 1.05, overflow: "hidden", color }}>{out}</div>;
};

/** pill chip */
const Chip: React.FC<{ k: number; bg?: string; color?: string; size?: number; children: React.ReactNode; style?: React.CSSProperties }> =
  ({ k, bg = C.tile, color = "#fff", size = 34, children, style }) => (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 10, padding: "10px 20px", borderRadius: 999, background: bg, color, fontFamily: UI,
      fontWeight: 800, fontSize: size, whiteSpace: "nowrap", opacity: clamp(k * 1.5), transform: `scale(${0.6 + 0.4 * k})`, ...style }}>{children}</div>
  );

/** caption for full-screen colour scenes (DemoCaption is white with shadow: made for video) */
const SceneCap: React.FC<{ text: string; from: number; to: number; y?: number; color?: string; size?: number; font?: string }> =
  ({ text, from, to, y = 1250, color = C.ink, size = 58, font = UI }) => {
    const t = useT();
    if (t < from || t > to) return null;
    const k = env(t, from, to, 0.25, 0.2);
    return (
      <div style={{ position: "absolute", left: 80, right: 180, top: y, textAlign: "center", fontFamily: font, fontWeight: 800, fontSize: size, color,
        lineHeight: 1.15, opacity: k, transform: `translateY(${(1 - k) * 18}px)` }}>{text}</div>
    );
  };

/** damped swing: sum of kicks [time, amplitude deg] */
const swing = (t: number, kicks: [number, number][], freq = 5.2, damp = 1.5) =>
  kicks.reduce((s, [at, a]) => (t < at ? s : s + a * Math.exp(-(t - at) * damp) * Math.sin((t - at) * freq)), 0);

type MS = { at: number; x: number; y: number; w: number; h: number; radius?: number; bg?: string; c: React.ReactNode };
/** ONE container that glides between fitted states; old content fades out while the new one is born inside it */
const Morph: React.FC<{ states: MS[]; from: number; to: number; border?: string; shadow?: boolean; collapseTo?: { x: number; y: number } }> =
  ({ states, from, to, border = "1.5px solid rgba(255,255,255,0.16)", shadow = true }) => {
    const t = useT();
    if (t < from || t > to) return null;
    let i = 0;
    while (i + 1 < states.length && states[i + 1].at <= t) i++;
    const cur = states[i], prev = states[Math.max(0, i - 1)];
    const k = i === 0 ? 1 : r(t, cur.at, cur.at + 0.55, EASE_IO);
    const kS = i === 0 ? 1 : interpolate(t, [cur.at, cur.at + 0.62], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    const outK = i === 0 ? 1 : r(t, cur.at, cur.at + 0.18, EASE_IN);
    const inK = i === 0 ? r(t, from + 0.1, from + 0.45) : r(t, cur.at + 0.2, cur.at + 0.5, EASE);
    const enter = r(t, from, from + 0.5, POP);
    const exit = r(t, to - 0.35, to, EASE_IN);
    const x = lerp(prev.x, cur.x, k), y = lerp(prev.y, cur.y, k);
    const w = lerp(prev.w, cur.w, kS), h = lerp(prev.h, cur.h, kS);
    const rad = lerp(prev.radius ?? 40, cur.radius ?? 40, k);
    const bg = mix(prev.bg ?? "#161618", cur.bg ?? "#161618", k);
    const flight = i > 0 ? Math.sin(Math.PI * clamp((t - cur.at) / 0.5)) : 0;
    return (
      <div style={{ position: "absolute", left: x - w / 2, top: y, width: w, height: h, opacity: 1 - exit, transformOrigin: "50% 0%",
        transform: `scale(${enter * (1 - exit * 0.5)}) scale(${1 + flight * 0.03}, ${1 - flight * 0.04}) translateY(${Math.sin(t * 1.4) * 4}px)` }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: rad, overflow: "hidden", background: bg, border,
          boxShadow: shadow ? "0 22px 50px rgba(0,0,0,0.3)" : undefined, color: "#fff", fontFamily: UI }}>
          {i > 0 && outK < 1 && <div style={{ position: "absolute", inset: 0, opacity: 1 - outK, transform: `scale(${1 - outK * 0.06})` }}>{prev.c}</div>}
          <div style={{ position: "absolute", inset: 0, opacity: inK, transform: `scale(${0.96 + 0.04 * inK})` }}>{cur.c}</div>
        </div>
      </div>
    );
  };

const center: React.CSSProperties = { position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" };

// =====================================================================================================
// m5-01  Price tag swing: a cream tag hangs from a string above his head; each new number kicks it
// =====================================================================================================
const PriceTag: React.FC = () => {
  const t = useT();
  const drop = r(t, 0.1, 0.9, EASE);
  const ang = swing(t, [[0.5, 16], [4.0, -11], [7.6, 9]]) + Math.sin(t * 1.3) * 1.2;
  const up = r(t, 4.0, 5.6, EASE_IO);
  const price = t < 4 ? lerp(1000000, 1600000, r(t, 0.9, 2.6, EASE_IO)) : lerp(1600000, 2400000, up);
  const flip = r(t, 7.6, 8.2, EASE_IO);
  const sx = Math.abs(Math.cos(flip * Math.PI));
  const back = flip > 0.5;
  const pct = r(t, 5.3, 5.7, POP);
  const gone = r(t, 11.3, 11.9, EASE_IN);
  const PIN = 170;
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <div style={{ position: "absolute", left: 540, top: PIN, width: 0, height: 0, transform: `translateY(${(drop - 1) * 520 - gone * 700}px) rotate(${ang}deg)` }}>
        {/* string */}
        <div style={{ position: "absolute", left: -2, top: 0, width: 4, height: 150, background: "rgba(255,255,255,0.85)", borderRadius: 2 }} />
        <div style={{ position: "absolute", left: -11, top: -11, width: 22, height: 22, borderRadius: 11, background: C.gold }} />
        {/* the tag */}
        <div style={{ position: "absolute", left: -340, top: 140, width: 680, height: 270, transform: `scaleX(${sx})` }}>
          <svg width="680" height="270" viewBox="0 0 600 270" preserveAspectRatio="none" style={{ position: "absolute", inset: 0 }}>
            <path d="M 80 0 L 520 0 L 600 70 L 600 246 Q 600 270 576 270 L 24 270 Q 0 270 0 246 L 0 70 Z" fill={back ? C.green : C.paper} />
            <circle cx="300" cy="34" r="16" fill={back ? "#1f9e45" : "#D9D2C3"} />
          </svg>
          {!back ? (
            <div style={{ position: "absolute", left: 0, right: 0, top: 66, display: "flex", flexDirection: "column", alignItems: "center", color: C.ink }}>
              <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
                <Label color="rgba(28,28,30,0.6)">VILLA · LISTED</Label>
                <div style={{ position: "relative", height: 44, width: 110, overflow: "hidden", background: C.ink, color: C.paper, borderRadius: 12 }}>
                  {["2021", "2026"].map((yy, j) => (
                    <div key={yy} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: MONO, fontWeight: 700, fontSize: 30,
                      transform: `translateY(${(j - up) * 44}px)` }}>{yy}</div>
                  ))}
                </div>
              </div>
              <div style={{ display: "flex", alignItems: "baseline", gap: 12, marginTop: 14 }}>
                <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 40, color: "rgba(28,28,30,0.55)" }}>AED</span>
                <OdoC value={price} size={88} color={C.ink} />
              </div>
            </div>
          ) : (
            <div style={{ position: "absolute", left: 0, right: 0, top: 70, display: "flex", flexDirection: "column", alignItems: "center", color: "#06290F" }}>
              <Label color="rgba(6,41,15,0.7)">ON PAPER, IN 5 YEARS</Label>
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 92, marginTop: 10 }}>+AED 800k</div>
            </div>
          )}
        </div>
        {/* +50% chip hangs off the corner */}
        {!back && pct > 0 && (
          <div style={{ position: "absolute", left: 250, top: 106, transform: `rotate(8deg) scale(${pct})` }}>
            <Chip k={1} bg={C.green} color="#06290F" size={40}>▲ 50%</Chip>
          </div>
        )}
      </div>
      <DemoCaption text="In 2021 this villa was listed at 1.6M" from={0.9} to={3.9} />
      <DemoCaption text="Today the same villa? 2.4M" from={4.1} to={7.4} />
      <DemoCaption text="That's 800k made just by holding" from={7.7} to={11.3} />
      <Sounds list={[[0.15, "whoosh", 0.3], [0.9, "tick", 0.25], [4.0, "swish", 0.35], [4.1, "tick", 0.25], [5.3, "pop", 0.35], [5.7, "ding", 0.25],
        [7.6, "swish", 0.35], [8.0, "pop", 0.3], [11.3, "whoosh", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-02  Key handover: a key flies into the keyhole, turns, the door swings open, we dolly into the home
// =====================================================================================================
const KeySvg: React.FC<{ color?: string; hole?: string }> = ({ color = C.gold, hole = C.eqt }) => (
  <svg width="300" height="110" viewBox="0 0 300 110">
    <circle cx="55" cy="55" r="50" fill={color} />
    <circle cx="55" cy="55" r="20" fill={hole} />
    <rect x="96" y="44" width="200" height="22" rx="8" fill={color} />
    <rect x="236" y="62" width="18" height="30" rx="4" fill={color} />
    <rect x="268" y="62" width="18" height="22" rx="4" fill={color} />
  </svg>
);

// =====================================================================================================
// m5-03  Contract: a cream sheet types itself, a pen draws the signature, a stamp lands
// =====================================================================================================
const SIG = "M 0 60 C 20 0, 40 -10, 34 40 C 30 80, 10 90, 22 60 C 40 20, 70 10, 74 50 C 76 80, 92 70, 100 44 C 108 20, 120 30, 124 56 C 128 76, 146 70, 154 40 C 160 18, 176 18, 176 48 C 176 72, 196 72, 206 46 C 214 26, 232 30, 240 56 L 300 48";
const Contract: React.FC = () => {
  const t = useT();
  const sheet = r(t, 0.0, 0.7, EASE);
  const sig1 = r(t, 4.2, 5.6, EASE_IO);
  const sig2 = r(t, 6.0, 7.3, EASE_IO);
  const stamp = r(t, 8.0, 8.25, EASE_IN);
  const shake = t > 8.25 && t < 8.6 ? Math.sin((t - 8.25) * 80) * 8 * (1 - (t - 8.25) / 0.35) : 0;
  const fold = r(t, 10.6, 11.4, EASE_IO);
  const chip = r(t, 11.2, 11.7, POP);
  const pen = (p: number, ox: number, oy: number) => {
    // pen tip follows the signature as it draws (approximate the path's x progress)
    const x = ox + p * 300, y = oy + 40 + Math.sin(p * 30) * 22;
    return { x, y };
  };
  const p1 = pen(sig1, 90, 1040), p2 = pen(sig2, 560, 1040);
  const activeP = t < 5.8 ? p1 : p2;
  const penOn = (t > 4.0 && t < 5.7) || (t > 5.9 && t < 7.4);
  const rows: [string, string, number][] = [["BUYER", "A. Buyer", 1.2], ["SELLER", "B. Seller", 1.8], ["PROPERTY", "Villa, plot 00", 2.4], ["PRICE", "AED 3,000,000", 3.0]];
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: "#E9E1D3" }}>
      <div style={{ position: "absolute", left: 70, top: 260, width: 940, height: 1100, background: C.paper, borderRadius: 18, boxShadow: "0 30px 60px rgba(80,60,30,0.18)",
        transform: `translateY(${(1 - sheet) * 900 + shake}px) rotate(${-1.2 + fold * 2}deg) scale(${1 - fold * 0.75})`, transformOrigin: "50% 40%", opacity: 1 - r(t, 11.0, 11.4) }}>
        <div style={{ position: "absolute", left: 70, top: 70, right: 70 }}>
          <Label color="rgba(28,28,30,0.5)">CONTRACT · SAMPLE</Label>
          <div style={{ fontFamily: SERIF, fontSize: 84, color: C.ink, lineHeight: 1.05, marginTop: 10 }}>Sale agreement</div>
          <div style={{ height: 3, background: C.ink, marginTop: 26, transformOrigin: "left", transform: `scaleX(${r(t, 0.5, 1.2, EASE_IO)})` }} />
          {rows.map(([k, v, at]) => (
            <div key={k} style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "22px 0", borderBottom: "2px solid #ECE5D8",
              opacity: r(t, at - 0.2, at) }}>
              <Label color="rgba(28,28,30,0.5)">{k}</Label>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 42, color: k === "PRICE" ? C.eqt : C.ink }}>{typed(v, t, at, 0.04)}</div>
            </div>
          ))}
          {/* text lines: little grey bars filling */}
          {[0, 1, 2].map((i) => (
            <div key={i} style={{ height: 14, borderRadius: 7, background: "#E4DDCF", marginTop: i === 0 ? 34 : 16, width: `${[92, 80, 64][i]}%`, transformOrigin: "left",
              transform: `scaleX(${r(t, 3.4 + i * 0.15, 3.9 + i * 0.15, EASE_IO)})` }} />
          ))}
        </div>
        {/* signature lines */}
        {[0, 1].map((i) => {
          const sx = i === 0 ? 70 : 520;
          const p = i === 0 ? sig1 : sig2;
          return (
            <div key={i} style={{ position: "absolute", left: sx, top: 900, width: 350 }}>
              <svg width="350" height="140" viewBox="-10 -10 350 140" style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
                <path d={SIG} pathLength={1} fill="none" stroke={i === 0 ? C.ink : "#123E7A"} strokeWidth={5} strokeLinecap="round" strokeLinejoin="round"
                  strokeDasharray="1" strokeDashoffset={1 - p} transform={i === 1 ? "translate(20 6) scale(0.95 1.05)" : undefined} />
              </svg>
              <div style={{ position: "absolute", left: 0, right: 0, top: 140, height: 3, background: C.ink, opacity: 0.8 }} />
              <div style={{ position: "absolute", left: 0, top: 156 }}><Label color="rgba(28,28,30,0.55)">{i === 0 ? "BUYER SIGNS" : "SELLER SIGNS"}</Label></div>
              {p === 0 && t > 3.6 && <div style={{ position: "absolute", left: 6, top: 82, fontFamily: UI, fontWeight: 900, fontSize: 44, color: C.red,
                opacity: r(t, 3.6 + i * 0.5, 3.9 + i * 0.5) * (0.6 + 0.4 * Math.sin(t * 6)) }}>✕</div>}
            </div>
          );
        })}
        {/* the stamp */}
        {t > 7.8 && (
          <div style={{ position: "absolute", left: 560, top: 640, width: 300, height: 300, borderRadius: 150, border: `10px solid ${C.eqt}`, display: "flex",
            alignItems: "center", justifyContent: "center", flexDirection: "column", color: C.eqt, transform: `rotate(-14deg) scale(${lerp(2.2, 1, stamp)})`,
            opacity: stamp * 0.92 }}>
            <div style={{ fontFamily: DISPLAY, fontSize: 84, letterSpacing: 4, lineHeight: 1 }}>AGREED</div>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 28, marginTop: 8 }}>10 · 10 · 2026</div>
          </div>
        )}
      </div>
      {/* the pen */}
      {penOn && (
        <div style={{ position: "absolute", left: activeP.x + 70, top: activeP.y + 260 - 160 + (1 - sheet) * 900, transform: "rotate(30deg)", transformOrigin: "0% 100%" }}>
          <svg width="40" height="170" viewBox="0 0 40 170">
            <rect x="6" y="0" width="28" height="130" rx="10" fill={C.ink} />
            <rect x="6" y="20" width="28" height="10" fill={C.gold} />
            <path d="M 6 128 L 34 128 L 20 168 Z" fill="#3A3A3C" />
          </svg>
        </div>
      )}
      {/* end: the sheet folds into a chip */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 700, display: "flex", justifyContent: "center", transform: float(t, 1, 5) }}>
        <Chip k={chip} bg={C.ink} color="#fff" size={56} style={{ padding: "22px 40px", opacity: clamp(chip * 1.5) }}>✍️ Signed · deal agreed</Chip>
      </div>
      <SceneCap text="Then it goes to transfer" from={11.6} to={14} y={880} />
      <Sounds list={[[0.0, "whoosh", 0.3], [1.2, "type", 0.25], [1.8, "type", 0.25], [2.4, "type", 0.25], [3.0, "type", 0.3], [3.6, "pop", 0.2], [4.2, "swish", 0.3],
        [6.0, "swish", 0.3], [8.2, "impact", 0.45], [10.6, "whoosh", 0.3], [11.2, "pop", 0.35], [11.6, "ding", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-04  Off-plan 60/40 payment plan: one graphite plate morphs: plan bar -> amounts -> takeaway pill
// =====================================================================================================
const PaymentPlan: React.FC = () => {
  const t = useT();
  const W = 940;
  const BW = W - 80;
  const fill60 = r(t, 1.0, 3.2, EASE_IO);
  const fill40 = r(t, 3.6, 4.6, EASE_IO);
  const crane = r(t, 1.0, 3.2, EASE_IO);
  const amt1 = r(t, 6.0, 7.4, EASE_IO);
  const amt2 = r(t, 7.4, 8.4, EASE_IO);
  const plan = (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", left: 40, top: 30, right: 40, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <Label>OFF-PLAN · PAYMENT PLAN</Label>
        <Chip k={r(t, 4.6, 5.0, POP)} bg={C.gold} color={C.ink} size={30}>60 / 40</Chip>
      </div>
      <div style={{ position: "absolute", left: 40, top: 110, width: BW, height: 92, borderRadius: 24, background: "rgba(255,255,255,0.07)", overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: BW * 0.6 * fill60, background: C.blue }} />
        <div style={{ position: "absolute", left: BW * 0.6, top: 0, bottom: 0, width: BW * 0.4 * fill40, background: C.gold }} />
        <div style={{ position: "absolute", left: BW * 0.6 - 2, top: 0, bottom: 0, width: 4, background: "#161618" }} />
        <div style={{ position: "absolute", left: 26, top: 0, bottom: 0, display: "flex", alignItems: "center", gap: 6, fontWeight: 900, fontSize: 52 }}>
          <Odo value={60 * fill60} size={52} /><span>%</span>
        </div>
        <div style={{ position: "absolute", left: BW * 0.6 + 26, top: 0, bottom: 0, display: "flex", alignItems: "center", gap: 6, fontWeight: 900, fontSize: 52, color: C.ink,
          opacity: fill40 > 0.05 ? 1 : 0 }}>
          <Odo value={40 * fill40} size={52} color={C.ink} /><span>%</span>
        </div>
      </div>
      {/* crane rides along the construction part, keys at the end */}
      <div style={{ position: "absolute", left: 40 + BW * 0.6 * crane - 30, top: 210, fontSize: 52, transform: `translateY(${Math.abs(Math.sin(t * 6)) * -6 * (crane > 0 && crane < 1 ? 1 : 0)}px)` }}>🏗️</div>
      <div style={{ position: "absolute", left: 40 + BW - 60, top: 210, fontSize: 52, transform: `scale(${r(t, 4.5, 4.9, POP)})` }}>🔑</div>
      <div style={{ position: "absolute", left: 40, top: 286, display: "flex", width: BW }}>
        <div style={{ width: BW * 0.6 }}><Label size={28}>WHILE IT'S BUILT</Label></div>
        <div style={{ width: BW * 0.4 }}><Label size={28} color={C.gold}>ON HANDOVER</Label></div>
      </div>
    </div>
  );
  const amounts = (
    <div style={{ position: "absolute", inset: 0, padding: "30px 40px", boxSizing: "border-box" }}>
      <Label>ON AN AED 2,000,000 UNIT</Label>
      {[["Over 3 years", 1200000, amt1, C.blue], ["At the keys", 800000, amt2, C.gold]].map(([lbl, v, k, col], i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: i === 0 ? 26 : 14, height: 96, borderRadius: 24,
          background: "rgba(255,255,255,0.07)", padding: "0 28px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16, fontWeight: 800, fontSize: 40 }}>
            <div style={{ width: 22, height: 22, borderRadius: 11, background: col as string }} />{lbl as string}
          </div>
          <div style={{ display: "flex", alignItems: "baseline", gap: 10, color: col as string }}>
            <span style={{ fontWeight: 800, fontSize: 32 }}>AED</span><OdoC value={(v as number) * (k as number)} size={58} color={col as string} />
          </div>
        </div>
      ))}
    </div>
  );
  const pill = (
    <div style={{ ...center, flexDirection: "row", gap: 18, fontWeight: 900, fontSize: 50 }}>
      <span style={{ fontSize: 56 }}>🏗️</span> Pay most of it <span style={{ color: C.gold }}>while it's built</span>
    </div>
  );
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <Morph from={0.2} to={13.0} states={[
        { at: 0, x: 540, y: 250, w: W, h: 350, c: plan },
        { at: 5.6, x: 540, y: 250, w: 900, h: 330, c: amounts },
        { at: 9.6, x: 540, y: 300, w: 960, h: 130, radius: 65, c: pill },
      ]} />
      <DemoCaption text="Most off-plan deals are 60/40" from={0.6} to={3.4} />
      <DemoCaption text="60% while it's being built, 40% when you get the keys" from={3.5} to={5.5} />
      <DemoCaption text="On a 2 million unit that's 1.2M spread out" from={5.8} to={9.3} />
      <DemoCaption text="and 800k on handover" from={9.6} to={12.8} />
      <Sounds list={[[0.2, "pop", 0.3], [1.0, "riser", 0.2], [3.2, "tick", 0.3], [3.6, "swish", 0.25], [4.6, "ding", 0.3], [4.7, "pop", 0.3], [5.6, "whoosh", 0.3],
        [6.0, "tick", 0.25], [7.4, "tick", 0.25], [8.4, "pop", 0.3], [9.6, "whoosh", 0.3], [10.1, "ding", 0.2], [12.7, "swish", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-05  Rent vs buy balance: indigo colour block, a beam scale; rent chips pile up year by year, the house fills
// =====================================================================================================
const HouseSvg: React.FC<{ fill: number; w?: number; color?: string; empty?: string }> = ({ fill, w = 220, color = C.green, empty = "rgba(255,255,255,0.18)" }) => {
  const h = w * 0.9;
  const id = `m505h${Math.round(w)}`;
  return (
    <svg width={w} height={h} viewBox="0 0 100 90">
      <defs><clipPath id={id}><path d="M 50 4 L 96 44 L 86 44 L 86 88 L 14 88 L 14 44 L 4 44 Z" /></clipPath></defs>
      <path d="M 50 4 L 96 44 L 86 44 L 86 88 L 14 88 L 14 44 L 4 44 Z" fill={empty} />
      <g clipPath={`url(#${id})`}><rect x="0" y={90 - 90 * fill} width="100" height="90" fill={color} /></g>
      <rect x="42" y="60" width="16" height="28" rx="3" fill="rgba(0,0,0,0.25)" />
    </svg>
  );
};
const RentVsBuy: React.FC = () => {
  const t = useT();
  const yp = r(t, 2.0, 9.0, (x) => x);
  const year = 1 + 9 * yp;
  const yrs = Math.floor(year + 1e-6);
  const ang = lerp(-6, 9, r(t, 2.0, 9.6, EASE_IO)) + swing(t, [[1.0, 3]]) + Math.sin(t * 1.5) * 0.6;
  const win = r(t, 10.0, 10.5, POP);
  const enter = r(t, 0.2, 1.0, EASE);
  const CX = 540, CY = 790, L = 330;
  const a = (ang * Math.PI) / 180;
  const left = { x: CX - L * Math.cos(a), y: CY - L * Math.sin(a) };
  const right = { x: CX + L * Math.cos(a), y: CY + L * Math.sin(a) };
  const pan = (p: { x: number; y: number }, label: string, col: string, children: React.ReactNode, total: React.ReactNode) => (
    <div style={{ position: "absolute", left: p.x - 160, top: p.y }}>
      <svg width="320" height="230" style={{ position: "absolute", left: 0, top: 0 }}>
        <line x1="160" y1="0" x2="30" y2="220" stroke="rgba(255,255,255,0.7)" strokeWidth="3" />
        <line x1="160" y1="0" x2="290" y2="220" stroke="rgba(255,255,255,0.7)" strokeWidth="3" />
      </svg>
      <div style={{ position: "absolute", left: 0, top: 216, width: 320, height: 26, borderRadius: 13, background: "#fff" }} />
      <div style={{ position: "absolute", left: 0, width: 320, bottom: -216 + 0, top: 0, height: 216, display: "flex", flexDirection: "column-reverse", alignItems: "center" }}>{children}</div>
      <div style={{ position: "absolute", left: 0, width: 320, top: 260, textAlign: "center" }}>
        <div style={{ fontFamily: DISPLAY, fontSize: 64, color: col, letterSpacing: 2 }}>{label}</div>
        <div style={{ marginTop: 6 }}>{total}</div>
      </div>
    </div>
  );
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: C.indigo, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 270, display: "flex", justifyContent: "center", alignItems: "center", gap: 20, opacity: enter }}>
        <Label color="rgba(255,255,255,0.75)" size={34}>YEAR</Label>
        <div style={{ background: "rgba(255,255,255,0.14)", borderRadius: 22, padding: "4px 22px" }}><Odo value={year} size={80} /></div>
        <Label color="rgba(255,255,255,0.75)" size={34}>OF 10</Label>
      </div>
      <div style={{ position: "absolute", inset: 0, transform: `translateY(${(1 - enter) * 300}px)`, opacity: enter }}>
        {/* stand */}
        <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
          <path d={`M ${CX} ${CY} L ${CX - 90} ${CY + 470} L ${CX + 90} ${CY + 470} Z`} fill="rgba(255,255,255,0.22)" />
          <rect x={CX - 170} y={CY + 466} width={340} height={22} rx={11} fill="rgba(255,255,255,0.3)" />
          <line x1={left.x} y1={left.y} x2={right.x} y2={right.y} stroke="#fff" strokeWidth={16} strokeLinecap="round" />
          <circle cx={CX} cy={CY} r={22} fill={C.gold} />
        </svg>
        {pan(left, "RENT", "#FFB4AE",
          Array.from({ length: 10 }, (_, i) => {
            const k = r(t, 2.0 + i * 0.7, 2.25 + i * 0.7, POP);
            return <div key={i} style={{ width: 210, height: 19, marginBottom: 2, borderRadius: 8, background: i % 2 ? "#FF6B61" : C.red, transform: `scale(${k}) translateY(${(1 - k) * -60}px)`,
              opacity: clamp(k * 2), flexShrink: 0 }} />;
          }).concat([<div key="pad" style={{ height: 0 }} />]),
          <div style={{ display: "flex", justifyContent: "center", alignItems: "baseline", gap: 8, color: "#fff" }}>
            <span style={{ fontWeight: 800, fontSize: 30 }}>AED</span><OdoC value={yrs * 120000} size={44} /></div>)}
        {pan(right, "BUY", "#9BF2B1",
          [<div key="h" style={{ marginBottom: 4 }}><HouseSvg fill={yp} w={190} /></div>],
          <div style={{ display: "flex", justifyContent: "center", alignItems: "baseline", gap: 8, color: "#fff" }}>
            <Odo value={100 * yp} size={44} /><span style={{ fontWeight: 800, fontSize: 30 }}>% OWNED</span></div>)}
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1320, display: "flex", justifyContent: "center", transform: float(t, 3, 4) }}>
        <Chip k={win} bg="#fff" color={C.indigo} size={50} style={{ padding: "18px 34px" }}>Rent: paid away · Buy: it's yours</Chip>
      </div>
      <SceneCap text="Renting at AED 120k a year" from={1.4} to={5.0} y={420} color="#fff" size={52} />
      <SceneCap text="after 10 years: 1.2M gone" from={5.2} to={9.8} y={420} color="#fff" size={52} />
      <Sounds list={[[0.2, "whoosh", 0.3], [1.0, "swish", 0.2], ...Array.from({ length: 10 }, (_, i) => [2.0 + i * 0.7, "tick", 0.22] as [number, "tick", number]),
        [9.0, "riser", 0.15], [9.6, "impact", 0.3], [10.0, "pop", 0.35], [10.3, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-06  ROI coin stack: split screen; coins drop year by year into 5 stacks, then the stacks slide into one
// =====================================================================================================
const Coin: React.FC<{ w?: number }> = ({ w = 150 }) => (
  <svg width={w} height={w * 0.36} viewBox="0 0 120 44" style={{ display: "block" }}>
    <ellipse cx="60" cy="26" rx="58" ry="17" fill="#C99A06" />
    <rect x="2" y="16" width="116" height="10" fill="#C99A06" />
    <ellipse cx="60" cy="16" rx="58" ry="15" fill={C.gold} />
    <ellipse cx="60" cy="16" rx="40" ry="9" fill="none" stroke="#E2B500" strokeWidth="3" />
  </svg>
);
const RoiCoins: React.FC = () => {
  const t = useT();
  const SPLIT = 960;
  const per = 3, years = 5;
  const dropAt = (y: number, c: number) => 1.4 + y * 1.1 + c * 0.22;
  const merge = r(t, 8.2, 9.2, EASE_IO);
  const big = r(t, 9.2, 9.7, POP);
  const shown = Array.from({ length: years }, (_, y) => Array.from({ length: per }, (_, c) => r(t, dropAt(y, c), dropAt(y, c) + 0.3, EASE_IN)));
  const roi = 2 * shown.flat().reduce((a, k) => a + k, 0);            // 3 coins a year = 6 % a year
  const gap = 185;
  const enter = r(t, 0, 0.6, EASE);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: C.ink, overflow: "hidden" }}>
      {/* bottom half: Max, framed in his own window */}
      <div style={{ position: "absolute", left: 0, top: SPLIT, width: 1080, height: 1920 - SPLIT, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, top: -560, width: 1080, height: 1920 }}><Backdrop /></div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: SPLIT - 4, height: 8, background: C.gold, transformOrigin: "left", transform: `scaleX(${enter})` }} />
      {/* top half: the coin stacks */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 250, display: "flex", justifyContent: "space-between", alignItems: "center", padding: "0 90px", opacity: enter }}>
        <div>
          <Label color="rgba(255,255,255,0.6)">AED 1,500,000 FLAT</Label>
          <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 44, color: "#fff", marginTop: 6 }}>Rent: AED 90k / yr</div>
        </div>
        <div style={{ textAlign: "right" }}>
          <Label color={C.gold}>RETURN</Label>
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "flex-end", gap: 4, color: C.gold }}>
            <Odo value={lerp(0, roi, 1)} size={96} color={C.gold} /><span style={{ fontWeight: 900, fontSize: 64 }}>%</span>
          </div>
        </div>
      </div>
      {Array.from({ length: years }, (_, y) => {
        const x0 = 540 + (y - 2) * gap;
        const x = lerp(x0, 540, merge);
        return (
          <div key={y} style={{ position: "absolute", left: x - 75, top: 440, width: 150, height: 420 }}>
            {shown[y].map((k, c) => {
              if (k <= 0) return null;
              const yy = lerp(lerp(-160, 330 - c * 40, k), 330 - (y * per + c) * 24, merge);   // coins fall in, then restack into one tower
              return <div key={c} style={{ position: "absolute", left: 0, top: yy, zIndex: y * per + c, opacity: clamp(k * 3) }}><Coin /></div>;
            })}
            <div style={{ position: "absolute", left: 0, right: 0, top: 400, textAlign: "center", opacity: 1 - merge }}>
              <Label color="rgba(255,255,255,0.7)">Y{y + 1}</Label>
            </div>
          </div>
        );
      })}
      {/* merged: one tall stack label */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 880, display: "flex", justifyContent: "center", transform: float(t, 2, 3) }}>
        <Chip k={big} bg={C.gold} color={C.ink} size={44}>AED 450,000 back in 5 years</Chip>
      </div>
      <DemoCaption text="Every year the rent drops in" from={1.4} to={5.0} y={1330} />
      <DemoCaption text="6% a year, 30% in five" from={5.2} to={8.6} y={1330} />
      <DemoCaption text="and you still own the flat" from={9.4} to={12.6} y={1330} />
      <Sounds list={[[0, "whoosh", 0.3], ...Array.from({ length: 15 }, (_, i) => [dropAt(Math.floor(i / 3), i % 3) + 0.3, "tick", 0.22] as [number, "tick", number]),
        [8.2, "swish", 0.3], [9.2, "pop", 0.35], [9.5, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-07  Listing card: a line stretches into a white listing card; photo, price, bed/bath/sqft chips count up
// =====================================================================================================
const VillaArt: React.FC<{ w: number; h: number; inside?: boolean }> = ({ w, h, inside }) => (
  <svg width={w} height={h} viewBox="0 0 300 260" preserveAspectRatio="xMidYMid slice">
    {!inside ? (
      <>
        <rect width="300" height="260" fill="#8FD3FF" />
        <circle cx="240" cy="60" r="26" fill="#FFE27A" />
        <rect x="0" y="190" width="300" height="70" fill="#E9DCC3" />
        <rect x="40" y="96" width="170" height="100" fill="#FFFFFF" />
        <rect x="120" y="60" width="130" height="66" fill="#F4F1EA" />
        <rect x="30" y="88" width="190" height="10" fill="#2C2C2E" />
        <rect x="112" y="52" width="148" height="10" fill="#2C2C2E" />
        <rect x="56" y="118" width="60" height="64" fill="#0A84FF" opacity="0.85" />
        <rect x="132" y="118" width="60" height="64" fill="#0A84FF" opacity="0.85" />
        <rect x="140" y="76" width="90" height="34" fill="#0A84FF" opacity="0.7" />
        <rect x="60" y="206" width="180" height="26" rx="6" fill="#30B4FF" />
        <text x="250" y="200" fontSize="54">🌴</text>
      </>
    ) : (
      <>
        <rect width="300" height="260" fill="#F4EBDD" />
        <rect x="0" y="180" width="300" height="80" fill="#D9C4A3" />
        <rect x="180" y="40" width="90" height="110" fill="#BDE6FF" stroke="#fff" strokeWidth="8" />
        <rect x="30" y="140" width="150" height="50" rx="12" fill="#5E5CE6" />
        <rect x="30" y="120" width="150" height="34" rx="12" fill="#7D7BFF" />
        <circle cx="230" cy="190" r="22" fill="#30D158" />
        <rect x="60" y="60" width="60" height="44" rx="4" fill="#FFD60A" />
      </>
    )}
  </svg>
);
const ListingCard: React.FC = () => {
  const t = useT();
  const line = r(t, 0.2, 0.6, EASE);
  const grow = r(t, 0.6, 1.2, LIQUID);
  const W = 960, H = 340;
  const w = lerp(20, W, line), h = lerp(8, H, grow);
  const chips: [string, string, number, number][] = [["🛏", "bd", 4, 2.2], ["🛁", "ba", 5, 2.8], ["📐", "sqft", 4200, 3.4]];
  const heart = r(t, 5.0, 5.35, POP);
  const swipe = r(t, 7.0, 7.6, EASE_IO);
  const badge = r(t, 9.0, 9.4, POP);
  const out = r(t, 11.6, 12.0, EASE_IN);
  const PW = 310;
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - w / 2, top: 260 + (H - h) / 2, width: w, height: h, borderRadius: lerp(4, 40, grow), background: C.paper, overflow: "hidden",
        boxShadow: "0 22px 50px rgba(0,0,0,0.3)", transform: `scale(${1 - out * 0.3}) ${float(t, 1, 3)}`, opacity: 1 - out, color: C.ink }}>
        <div style={{ position: "absolute", left: 20, top: 20, width: PW, height: H - 40, borderRadius: 26, overflow: "hidden", opacity: grow }}>
          <div style={{ position: "absolute", left: -swipe * PW, top: 0, display: "flex" }}>
            <VillaArt w={PW} h={H - 40} /><VillaArt w={PW} h={H - 40} inside />
          </div>
          <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, display: "flex", justifyContent: "center", gap: 8 }}>
            {[0, 1].map((i) => <div key={i} style={{ width: 12, height: 12, borderRadius: 6, background: "#fff", opacity: Math.abs(i - swipe) < 0.5 ? 1 : 0.5 }} />)}
          </div>
          <div style={{ position: "absolute", right: 14, top: 14, width: 64, height: 64, borderRadius: 32, background: "rgba(255,255,255,0.9)", display: "flex",
            alignItems: "center", justifyContent: "center", fontSize: 36, transform: `scale(${1 + Math.sin(heart * Math.PI) * 0.3})` }}>{heart > 0.4 ? "❤️" : "🤍"}</div>
        </div>
        <div style={{ position: "absolute", left: PW + 50, right: 30, top: 34, opacity: r(t, 1.0, 1.4) }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <Label color="rgba(28,28,30,0.5)">VILLA · FOR SALE</Label>
            {badge > 0 && <Chip k={badge} bg={C.red} size={26} style={{ padding: "6px 14px" }}>NEW</Chip>}
          </div>
          <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 10 }}>
            <span style={{ fontWeight: 800, fontSize: 32, opacity: 0.5 }}>AED</span>
            <OdoC value={lerp(0, 8500000, r(t, 1.2, 2.2, EASE_IO))} size={62} color={C.ink} />
          </div>
          <div style={{ fontWeight: 700, fontSize: 32, opacity: 0.6, marginTop: 2 }}>{typed("Garden villa · private pool", t, 1.6, 0.03)}</div>
          <div style={{ display: "flex", gap: 10, marginTop: 22 }}>
            {chips.map(([ic, lbl, n, at]) => {
              const k = r(t, at - 0.2, at + 0.2, POP);
              const v = lerp(0, n, r(t, at, at + 0.8, EASE_IO));
              return (
                <div key={lbl} style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 14px", borderRadius: 18, background: "#ECE6DA", fontWeight: 800, fontSize: 30,
                  transform: `scale(${0.6 + 0.4 * k})`, opacity: clamp(k * 1.5) }}>
                  <span style={{ fontSize: 28 }}>{ic}</span><OdoC value={v} size={30} color={C.ink} /><span style={{ fontSize: 26, opacity: 0.6 }}>{lbl}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <DemoCaption text="Here's what 8.5 million gets you" from={1.0} to={4.8} />
      <DemoCaption text="four beds, five baths, 4,200 square feet" from={4.9} to={8.7} />
      <DemoCaption text="and it just hit the market" from={8.9} to={11.6} />
      <Sounds list={[[0.2, "swish", 0.25], [0.6, "pop", 0.3], [1.2, "tick", 0.25], [1.6, "type", 0.2], [2.2, "pop", 0.25], [2.8, "pop", 0.25], [3.4, "pop", 0.25],
        [5.0, "pop", 0.4], [5.1, "ding", 0.2], [7.0, "swish", 0.3], [9.0, "pop", 0.35], [11.6, "whoosh", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-08  Floor plan: blueprint navy scene, walls draw themselves, rooms fill with flat colour, a dot tours it
// =====================================================================================================
const PLAN = { x: 120, y: 420, w: 840, h: 760 };
const WALLS: [string, number][] = [
  // outer shell, then inner walls (absolute coords inside a 840x760 box)
  ["M 0 0 L 840 0 L 840 760 L 0 760 Z", 0.4],
  ["M 0 330 L 300 330 M 380 330 L 520 330", 1.5],
  ["M 520 0 L 520 210 M 520 290 L 520 760", 1.8],
  ["M 520 470 L 700 470 M 780 470 L 840 470", 2.1],
  ["M 300 330 L 300 470 M 300 550 L 300 760", 2.4],
];
const ROOMS: { x: number; y: number; w: number; h: number; name: string; col: string; at: number }[] = [
  { x: 0, y: 0, w: 520, h: 330, name: "Living", col: "#FFD60A", at: 6.0 },
  { x: 520, y: 0, w: 320, h: 470, name: "Kitchen", col: "#FF9F0A", at: 6.4 },
  { x: 0, y: 330, w: 300, h: 430, name: "Bed 1", col: "#64D2FF", at: 6.8 },
  { x: 300, y: 330, w: 220, h: 430, name: "Bath", col: "#30D158", at: 7.2 },
  { x: 520, y: 470, w: 320, h: 290, name: "Bed 2", col: "#BF5AF2", at: 7.6 },
];
const TOUR: [number, number][] = [[260, 160], [340, 300], [340, 390], [150, 540], [340, 510], [410, 640], [480, 400], [560, 250], [680, 230], [740, 420], [680, 600]];
const FloorPlan: React.FC = () => {
  const t = useT();
  const bg = "#0B2545";
  const sq = r(t, 2.6, 4.6, EASE_IO);
  const tourK = r(t, 8.4, 11.6, EASE_IO);
  const segs = TOUR.length - 1;
  const fi = Math.min(segs - 0.0001, tourK * segs);
  const a = TOUR[Math.floor(fi)], b = TOUR[Math.min(segs, Math.floor(fi) + 1)];
  const dot = { x: lerp(a[0], b[0], fi % 1), y: lerp(a[1], b[1], fi % 1) };
  const dotK = r(t, 8.2, 8.5, POP) * (1 - r(t, 11.8, 12.1, EASE_IN));
  const inRoom = ROOMS.findIndex((rm) => dot.x > rm.x && dot.x < rm.x + rm.w && dot.y > rm.y && dot.y < rm.y + rm.h);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: bg, overflow: "hidden" }}>
      <svg width="1080" height="1920" style={{ position: "absolute", inset: 0 }}>
        {Array.from({ length: 28 }, (_, i) => <line key={`v${i}`} x1={i * 40} y1={0} x2={i * 40} y2={1920} stroke="rgba(255,255,255,0.05)" strokeWidth={2} />)}
        {Array.from({ length: 48 }, (_, i) => <line key={`h${i}`} x1={0} y1={i * 40} x2={1080} y2={i * 40} stroke="rgba(255,255,255,0.05)" strokeWidth={2} />)}
      </svg>
      <div style={{ position: "absolute", left: 120, right: 120, top: 270, display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
        <div>
          <Label color="rgba(255,255,255,0.55)">FLOOR PLAN · 2 BED</Label>
          <div style={{ fontFamily: SERIF, fontSize: 76, color: "#fff", lineHeight: 1 }}>the layout</div>
        </div>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8, color: C.gold, opacity: r(t, 2.5, 2.8) }}>
          <OdoC value={1400 * sq} size={70} color={C.gold} /><span style={{ fontWeight: 800, fontSize: 34 }}>sqft</span>
        </div>
      </div>
      <svg width={PLAN.w + 40} height={PLAN.h + 120} style={{ position: "absolute", left: PLAN.x - 20, top: PLAN.y - 20, overflow: "visible" }}>
        <g transform="translate(20 20)">
          {ROOMS.map((rm, i) => {
            const k = r(t, rm.at, rm.at + 0.4, EASE);
            const hot = inRoom === i && dotK > 0.5;
            return <rect key={i} x={rm.x + 6} y={rm.y + 6} width={rm.w - 12} height={rm.h - 12} fill={rm.col} opacity={k * (hot ? 0.95 : 0.7)}
              style={{ transformOrigin: `${rm.x + rm.w / 2}px ${rm.y + rm.h / 2}px`, transform: `scale(${0.6 + 0.4 * k})` }} />;
          })}
          {WALLS.map(([d, at], i) => (
            <path key={i} d={d} pathLength={1} fill="none" stroke="#fff" strokeWidth={i === 0 ? 14 : 9} strokeLinecap="square"
              strokeDasharray="1" strokeDashoffset={1 - r(t, at, at + (i === 0 ? 1.2 : 0.5), EASE_IO)} />
          ))}
          {/* door swings */}
          {[[300, 330, 0], [520, 210, 90], [700, 470, 0], [300, 470, 90]].map(([x, y, rot], i) => (
            <path key={`d${i}`} d="M 0 0 L 80 0 A 80 80 0 0 1 0 80" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth={3}
              transform={`translate(${x} ${y}) rotate(${rot})`} opacity={r(t, 3.0 + i * 0.2, 3.3 + i * 0.2)} />
          ))}
          {/* dimension line */}
          <g opacity={r(t, 2.6, 3.0)}>
            <line x1={0} y1={800} x2={840 * sq} y2={800} stroke={C.gold} strokeWidth={3} />
            <line x1={0} y1={786} x2={0} y2={814} stroke={C.gold} strokeWidth={3} />
            {sq > 0.98 && <line x1={840} y1={786} x2={840} y2={814} stroke={C.gold} strokeWidth={3} />}
          </g>
          {ROOMS.map((rm, i) => (
            <text key={`t${i}`} x={rm.x + rm.w / 2} y={rm.y + rm.h / 2 + 14} textAnchor="middle" fontFamily={UI} fontWeight={800} fontSize={40}
              fill={r(t, rm.at, rm.at + 0.4) > 0.5 ? C.ink : "#fff"} opacity={r(t, 4.0 + i * 0.25, 4.4 + i * 0.25)}>{rm.name}</text>
          ))}
          {dotK > 0 && <circle cx={dot.x} cy={dot.y} r={24 * dotK} fill="#fff" stroke={C.ink} strokeWidth={5} />}
        </g>
      </svg>
      <SceneCap text="Look at the layout, not the photos" from={0.6} to={5.6} y={1340} color="#fff" size={52} />
      <SceneCap text="no space wasted on corridors" from={8.4} to={12.0} y={1340} color="#fff" size={52} />
      <Sounds list={[[0.4, "swish", 0.3], [1.5, "tick", 0.2], [1.8, "tick", 0.2], [2.1, "tick", 0.2], [2.4, "tick", 0.2], [2.6, "riser", 0.15], [4.6, "ding", 0.25],
        [6.0, "pop", 0.25], [6.4, "pop", 0.25], [6.8, "pop", 0.25], [7.2, "pop", 0.25], [7.6, "pop", 0.25], [8.2, "pop", 0.3], [8.4, "whoosh", 0.2], [11.8, "swish", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-09  Building floors counter: a sky scene, a generic tower rises floor by floor, the counter follows
// =====================================================================================================
const FloorsCounter: React.FC = () => {
  const t = useT();
  const N = 40;
  const grow = r(t, 0.8, 7.0, EASE_IO);
  const built = N * grow;
  const FH = 21, TW = 340, BASE = 1380, TX = 450;
  const pick = r(t, 8.0, 8.5, POP);
  const MINE = 32;
  const zoom = r(t, 9.6, 10.6, EASE_IO);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: "#9FD8FF", overflow: "hidden" }}>
      <div style={{ position: "absolute", inset: 0, transformOrigin: `${TX + 150}px ${BASE - MINE * FH}px`, transform: `scale(${1 + zoom * 0})` }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: BASE, bottom: 0, background: "#E9DCC3" }} />
        {Array.from({ length: N }, (_, i) => {
          const k = clamp(built - i);
          if (k <= 0) return null;
          const mine = i === MINE - 1 && pick > 0;
          return (
            <div key={i} style={{ position: "absolute", left: TX - TW / 2, top: BASE - (i + 1) * FH, width: TW, height: FH - 3, background: mine ? C.gold : i % 2 ? "#F4F1EA" : "#FFFFFF",
              transformOrigin: "50% 100%", transform: `scaleY(${k})`, display: "flex", justifyContent: "space-evenly", alignItems: "center" }}>
              {Array.from({ length: 7 }, (_, j) => <div key={j} style={{ width: 30, height: FH - 10, borderRadius: 2, background: mine ? "#B38F00" : "#0A84FF", opacity: 0.75 }} />)}
            </div>
          );
        })}
        {/* crane rides the top floor */}
        <div style={{ position: "absolute", left: TX + 40, top: BASE - built * FH - 150, width: 8, height: 150, background: C.orange, opacity: 1 - r(t, 7.0, 7.6) }}>
          <div style={{ position: "absolute", left: -180, top: 0, width: 290, height: 8, background: C.orange }} />
          <div style={{ position: "absolute", left: -150, top: 8, width: 3, height: 60 + Math.sin(t * 3) * 10, background: C.ink }} />
        </div>
        {/* roof cap */}
        <div style={{ position: "absolute", left: TX - TW / 2 - 12, top: BASE - N * FH - 14, width: TW + 24, height: 14, background: C.ink, opacity: r(t, 7.0, 7.3) }} />
        {/* pin on my floor */}
        {pick > 0 && (
          <div style={{ position: "absolute", left: TX + TW / 2 + 16, top: BASE - MINE * FH - 30, transform: `scale(${pick})`, transformOrigin: "0% 50%" }}>
            <Chip k={1} bg={C.ink} size={36}>◀ your unit · floor 32</Chip>
          </div>
        )}
      </div>
      <div style={{ position: "absolute", left: 450 + 186, top: 1380 - 32 * 21 + 50, transform: `scale(${r(t, 9.8, 10.2, POP)})`, transformOrigin: "0% 50%" }}>
        <Chip k={1} bg={C.gold} color={C.ink} size={34}>+ views = + price</Chip>
      </div>
      {/* counter */}
      <div style={{ position: "absolute", left: 760, top: 300, opacity: r(t, 0.2, 0.6) }}>
        <Label color="rgba(28,28,30,0.6)" size={32}>FLOORS</Label>
        <Odo value={Math.floor(built + 1e-6) + (built % 1 > 0.999 ? 0 : 0)} size={170} color={C.ink} font={DISPLAY} weight={400} />
      </div>
      <SceneCap text="40 floors, built from the ground up" from={0.8} to={7.4} y={1440} color={C.ink} size={50} />
      <SceneCap text="higher floor = higher price" from={8.2} to={11.8} y={1440} color={C.ink} size={50} />
      <Sounds list={[[0.2, "whoosh", 0.3], [0.8, "riser", 0.2], ...Array.from({ length: 8 }, (_, i) => [1.2 + i * 0.7, "tick", 0.2] as [number, "tick", number]),
        [7.0, "impact", 0.3], [8.0, "pop", 0.35], [8.2, "ding", 0.25], [9.8, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-10  Commission split: a gold coin over his head cuts into a pie; slices lift out with their AED share
// =====================================================================================================
const arc = (cx: number, cy: number, rr: number, a0: number, a1: number) => {
  const p = (a: number) => [cx + rr * Math.cos(a - Math.PI / 2), cy + rr * Math.sin(a - Math.PI / 2)];
  const [x0, y0] = p(a0), [x1, y1] = p(a1);
  return `M ${cx} ${cy} L ${x0} ${y0} A ${rr} ${rr} 0 ${a1 - a0 > Math.PI ? 1 : 0} 1 ${x1} ${y1} Z`;
};
const CommissionPie: React.FC = () => {
  const t = useT();
  const W = 900, H = 330;
  const coin = r(t, 0.2, 0.7, POP);
  const cut = r(t, 2.4, 3.4, EASE_IO);
  const slices = [
    { name: "Buyer's agent", pct: 50, col: C.blue, at: 4.0 },
    { name: "Seller's agent", pct: 40, col: C.green, at: 5.6 },
    { name: "Referral", pct: 10, col: C.pink, at: 7.2 },
  ];
  const R = 120, CX = 170, CY = 165;
  let acc = 0;
  const plateK = r(t, 0.2, 0.6, POP);
  const out = r(t, 11.5, 11.9, EASE_IN);
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - W / 2, top: 255, width: W, height: H, borderRadius: 40, background: "rgba(251,248,241,0.97)", color: C.ink,
        boxShadow: "0 22px 50px rgba(0,0,0,0.3)", transform: `scale(${(0.85 + 0.15 * plateK) * (1 - out * 0.3)}) ${float(t, 1, 3)}`, opacity: clamp(plateK * 1.4) * (1 - out), transformOrigin: "50% 0%" }}>
        <svg width={340} height={H} style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
          {/* coin face before the cut */}
          <g opacity={1 - cut} style={{ transformOrigin: `${CX}px ${CY}px`, transform: `scale(${coin})` }}>
            <circle cx={CX} cy={CY} r={R} fill={C.gold} />
            <circle cx={CX} cy={CY} r={R - 18} fill="none" stroke="#E2B500" strokeWidth={6} />
            <text x={CX} y={CY + 18} textAnchor="middle" fontFamily={UI} fontWeight={900} fontSize={54} fill="#7A5B00">AED</text>
          </g>
          {slices.map((s, i) => {
            const a0 = (acc / 100) * Math.PI * 2;
            acc += s.pct;
            const a1 = (acc / 100) * Math.PI * 2;
            const lift = r(t, s.at, s.at + 0.4, POP) * (1 - r(t, s.at + 1.3, s.at + 1.6, EASE_IO)) + (i === 0 ? r(t, 9.4, 9.8, POP) : 0);
            const mid = (a0 + a1) / 2 - Math.PI / 2;
            const dx = Math.cos(mid) * 22 * lift, dy = Math.sin(mid) * 22 * lift;
            // the cut grows each slice from the coin (sweep angle opens)
            const sweep = a0 + (a1 - a0) * cut;
            return cut > 0 ? <path key={i} d={arc(CX, CY, R, a0, Math.max(a0 + 0.001, sweep))} fill={s.col} stroke="#FBF8F1" strokeWidth={5} transform={`translate(${dx} ${dy})`} /> : null;
          })}
        </svg>
        <div style={{ position: "absolute", left: 340, right: 36, top: 30 }}>
          <Label color="rgba(28,28,30,0.5)">COMMISSION ON A SALE</Label>
          <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 4 }}>
            <span style={{ fontWeight: 800, fontSize: 32, opacity: 0.5 }}>AED</span><OdoC value={lerp(0, 100000, r(t, 0.6, 1.8, EASE_IO))} size={64} color={C.ink} />
          </div>
          {slices.map((s, i) => {
            const k = r(t, s.at, s.at + 0.4, POP);
            const hot = t > s.at && t < s.at + 1.5;
            return (
              <div key={i} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: i === 0 ? 14 : 6, opacity: clamp(k * 1.5),
                transform: `translateX(${(1 - k) * 40}px)`, fontWeight: 800, fontSize: 34 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  <div style={{ width: 20, height: 20, borderRadius: 10, background: s.col }} />
                  <span style={{ opacity: hot ? 1 : 0.75 }}>{s.name}</span>
                </div>
                <div style={{ display: "flex", alignItems: "baseline", gap: 6, color: s.col }}>
                  <OdoC value={1000 * s.pct * r(t, s.at, s.at + 0.8, EASE_IO)} size={36} color={s.col} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <DemoCaption text="Say the commission is 100k" from={0.6} to={3.8} />
      <DemoCaption text="it doesn't all go to one person" from={4.0} to={8.8} />
      <DemoCaption text="it gets split, every time" from={9.2} to={11.5} />
      <Sounds list={[[0.2, "pop", 0.35], [0.6, "tick", 0.2], [2.4, "swish", 0.3], [4.0, "pop", 0.3], [5.6, "pop", 0.3], [7.2, "pop", 0.3], [9.4, "ding", 0.25], [11.5, "whoosh", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-11  Service-charge breakdown: iOS light scene + face bubble; one total bar splits into rows, then folds back
// =====================================================================================================
const FaceBubble: React.FC<{ cx: number; cy: number; d: number; k?: number; ring?: string }> = ({ cx, cy, d, k = 1, ring = "#fff" }) => (
  <div style={{ position: "absolute", left: cx - d / 2, top: cy - d / 2, width: d, height: d, borderRadius: d / 2, overflow: "hidden", border: `8px solid ${ring}`,
    boxSizing: "border-box", transform: `scale(${k})`, background: "#000" }}>
    <div style={{ position: "absolute", left: d / 2 - 540 * 0.5, top: d / 2 - 960 * 0.5, width: 1080, height: 1920, transform: "scale(0.5)", transformOrigin: "0 0" }}><Backdrop /></div>
  </div>
);
const ServiceCharge: React.FC = () => {
  const t = useT();
  const parts = [
    { n: "Security", v: 7200, c: C.blue },
    { n: "Cleaning", v: 4800, c: C.teal },
    { n: "Maintenance", v: 4800, c: C.orange },
    { n: "Pool & gym", v: 3600, c: C.green },
    { n: "Reserve fund", v: 3600, c: C.purple },
  ];
  const total = 24000;
  const BW = 860, X0 = 110, TOPY = 470;
  const split = r(t, 2.6, 3.6, EASE_IO);
  const fold = r(t, 9.4, 10.3, EASE_IO);
  const k = split * (1 - fold);
  const pill = r(t, 10.2, 10.7, POP);
  const hi = r(t, 7.0, 7.4, POP) * (1 - fold);
  let acc = 0;
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: "#F2F2F7", overflow: "hidden" }}>
      <div style={{ position: "absolute", left: X0, top: 270, opacity: r(t, 0, 0.5) }}>
        <Label color="rgba(60,60,67,0.6)" size={30}>SERVICE CHARGE · EXAMPLE</Label>
        <div style={{ display: "flex", alignItems: "baseline", gap: 12, marginTop: 6, color: C.ink }}>
          <span style={{ fontWeight: 800, fontSize: 40, opacity: 0.5 }}>AED</span><OdoC value={lerp(0, total, r(t, 0.3, 1.8, EASE_IO))} size={92} color={C.ink} />
          <span style={{ fontWeight: 800, fontSize: 40, opacity: 0.5 }}>/ year</span>
        </div>
      </div>
      {parts.map((p, i) => {
        const x = X0 + (acc / total) * BW * (1 - k);
        const wSeg = (p.v / total) * BW;
        acc += p.v;
        const rowW = (p.v / 7200) * 520;
        const w = lerp(wSeg, rowW, k);
        const y = TOPY + k * (100 + i * 96);
        const hot = i === 0 ? hi : 0;
        return (
          <React.Fragment key={p.n}>
            <div style={{ position: "absolute", left: lerp(x, X0 + 300, k), top: y, width: w * r(t, 0.4 + i * 0.12, 1.0 + i * 0.12, EASE_IO), height: 80,
              background: p.c, borderRadius: lerp(i === 0 ? 0 : 0, 20, k), borderTopLeftRadius: i === 0 || k > 0 ? 20 : 0, borderBottomLeftRadius: i === 0 || k > 0 ? 20 : 0,
              borderTopRightRadius: i === 4 || k > 0 ? 20 : 0, borderBottomRightRadius: i === 4 || k > 0 ? 20 : 0, transform: `scale(${1 + hot * 0.04})`, transformOrigin: "0 50%" }} />
            <div style={{ position: "absolute", left: X0, top: y, height: 80, width: 290, display: "flex", alignItems: "center", fontWeight: 800, fontSize: 38, color: C.ink, opacity: k }}>{p.n}</div>
            <div style={{ position: "absolute", left: X0 + 300 + rowW + 18, top: y, height: 80, display: "flex", alignItems: "center", gap: 6, opacity: k, color: C.ink }}>
              <OdoC value={p.v * r(t, 3.4 + i * 0.25, 4.2 + i * 0.25, EASE_IO)} size={36} color={C.ink} />
            </div>
          </React.Fragment>
        );
      })}
      <div style={{ position: "absolute", left: 0, right: 0, top: TOPY + 120, display: "flex", justifyContent: "center", transform: float(t, 1, 3) }}>
        <Chip k={pill} bg={C.ink} size={52} style={{ padding: "16px 36px" }}>= AED 2,000 a month</Chip>
      </div>
      <FaceBubble cx={540} cy={1225} d={300} k={r(t, 0.2, 0.7, POP)} />
      <Sounds list={[[0.2, "pop", 0.3], [0.3, "tick", 0.2], [0.4, "swish", 0.2], [2.6, "whoosh", 0.3], [3.4, "tick", 0.2], [3.65, "tick", 0.2], [3.9, "tick", 0.2],
        [4.15, "tick", 0.2], [4.4, "tick", 0.2], [7.0, "pop", 0.3], [9.4, "swish", 0.3], [10.2, "pop", 0.35], [10.4, "ding", 0.25]]} />
      <SceneCap text="Where does it all go?" from={0.6} to={2.5} y={1395} size={46} />
      <SceneCap text="Security: the biggest slice" from={7.0} to={9.3} y={1395} size={46} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-12  Checklist: green colour block, an iOS list ticks item by item while a ring fills, then becomes one big tick
// =====================================================================================================
const Checklist: React.FC = () => {
  const t = useT();
  const items = ["Passport copy", "Salary certificate", "6 months bank statements", "Credit check", "Down payment ready"];
  const at = (i: number) => 2.0 + i * 1.1;
  const done = items.reduce((s, _, i) => s + r(t, at(i), at(i) + 0.4, EASE_IO), 0);
  const morph = r(t, 8.4, 9.2, EASE_IO);
  const big = r(t, 9.0, 9.5, POP);
  const card = r(t, 0.2, 0.8, POP);
  const RR = 70, circ = 2 * Math.PI * RR;
  const cursorI = Math.min(items.length - 1, Math.max(0, Math.floor((t - 1.6) / 1.1)));
  const cursorOn = t > 1.4 && t < 7.6;
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: C.green, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 270, textAlign: "center", color: "#06290F", opacity: 1 - morph }}>
        <Label color="rgba(6,41,15,0.6)" size={32}>MORTGAGE · EXAMPLE CHECKLIST</Label>
        <div style={{ fontFamily: SERIF, fontSize: 92, lineHeight: 1.05, marginTop: 4 }}>are you ready?</div>
      </div>
      <div style={{ position: "absolute", left: 540 - 430, top: 480, width: 860, background: "#fff", borderRadius: lerp(40, 300, morph), overflow: "hidden",
        height: lerp(720, 0, morph), opacity: clamp(card * 1.5) * (1 - morph), transform: `scale(${(0.85 + 0.15 * card) * (1 - morph * 0.5)})`, transformOrigin: "50% 30%" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "30px 40px", borderBottom: "2px solid #EFEFF4" }}>
          <div style={{ fontWeight: 900, fontSize: 48, color: C.ink }}>Documents</div>
          <svg width={170} height={170} viewBox="0 0 170 170" style={{ margin: "-30px -10px" }}>
            <circle cx={85} cy={85} r={RR} fill="none" stroke="#EFEFF4" strokeWidth={16} />
            <circle cx={85} cy={85} r={RR} fill="none" stroke={C.green} strokeWidth={16} strokeLinecap="round" strokeDasharray={circ}
              strokeDashoffset={circ * (1 - done / items.length)} transform="rotate(-90 85 85)" />
            <text x={85} y={97} textAnchor="middle" fontFamily={UI} fontWeight={900} fontSize={36} fill={C.ink}>{Math.round((done / items.length) * 100)}%</text>
          </svg>
        </div>
        {items.map((it, i) => {
          const k = r(t, at(i), at(i) + 0.35, POP);
          return (
            <div key={it} style={{ display: "flex", alignItems: "center", gap: 24, padding: "0 40px", height: 110, borderBottom: i < items.length - 1 ? "2px solid #EFEFF4" : undefined,
              opacity: r(t, 0.5 + i * 0.1, 0.9 + i * 0.1) }}>
              <div style={{ width: 60, height: 60, borderRadius: 30, border: `4px solid ${k > 0.5 ? C.green : "#C7C7CC"}`, background: k > 0.5 ? C.green : "transparent",
                display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 38, fontWeight: 900, boxSizing: "border-box", transform: `scale(${0.85 + 0.15 * k})` }}>
                {k > 0.5 ? "✓" : ""}</div>
              <div style={{ fontWeight: 700, fontSize: 42, color: k > 0.5 ? "#8E8E93" : C.ink }}>{it}</div>
            </div>
          );
        })}
      </div>
      {/* finger tap cursor */}
      {cursorOn && (
        <div style={{ position: "absolute", left: 175 + Math.sin(t * 2) * 6, top: 480 + 130 + cursorI * 110 + 40 + lerp(0, 0, 0) + (1 - r(t, 1.6 + cursorI * 1.1, 2.0 + cursorI * 1.1, EASE_IO)) * 60,
          width: 64, height: 64, borderRadius: 32, background: "rgba(28,28,30,0.25)", border: "4px solid rgba(28,28,30,0.55)", boxSizing: "border-box",
          transform: `scale(${t % 1.1 > 0.4 - 0.0 && Math.abs(((t - 2.0) % 1.1)) < 0.15 ? 0.8 : 1})` }} />
      )}
      {/* the card collapses into one big tick */}
      <div style={{ position: "absolute", left: 540 - 180, top: 620, width: 360, height: 360, borderRadius: 180, background: "#fff", display: "flex", alignItems: "center",
        justifyContent: "center", transform: `scale(${big}) ${float(t, 2, 5)}`, opacity: clamp(big * 2) }}>
        <svg width={200} height={200} viewBox="0 0 200 200">
          <path d="M 40 105 L 85 148 L 162 60" fill="none" stroke={C.green} strokeWidth={26} strokeLinecap="round" strokeLinejoin="round" pathLength={1}
            strokeDasharray={1} strokeDashoffset={1 - r(t, 9.3, 9.8, EASE_IO)} />
        </svg>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1040, textAlign: "center", fontWeight: 900, fontSize: 84, color: "#06290F", opacity: r(t, 9.6, 10.0),
        transform: `translateY(${(1 - r(t, 9.6, 10.0)) * 30}px)` }}>Pre-approved</div>
      <SceneCap text="Get these five ready before you view" from={2.0} to={8.2} y={1280} color="#06290F" size={50} />
      <Sounds list={[[0.2, "pop", 0.3], ...items.map((_, i) => [at(i), "tick", 0.3] as [number, "tick", number]), ...items.map((_, i) => [at(i) + 0.1, "pop", 0.2] as [number, "pop", number]),
        [8.4, "whoosh", 0.3], [9.0, "pop", 0.35], [9.4, "ding", 0.35]]} />
    </AbsoluteFill>
  );
};


// =====================================================================================================
// m5-14  Rental yield gauge: orange colour block, a flat gauge; the needle swings to 7 % as the formula fills
// =====================================================================================================
const YieldGauge: React.FC = () => {
  const t = useT();
  const CX = 540, CY = 900, R = 330;
  const draw = r(t, 0.3, 1.4, EASE_IO);
  const sweep = interpolate(t, [3.6, 5.0], [0, 1], { easing: LIQUID, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const val = 7 * sweep;
  const needleA = -180 + (val / 10) * 180 + Math.sin(t * 2.2) * 0.6 * sweep;
  const zones = [[0, 4, C.red], [4, 6, C.gold], [6, 10, C.green]] as [number, number, string][];
  const pa = (v: number) => Math.PI + (v / 10) * Math.PI;
  const pt = (v: number, rr: number) => [CX + rr * Math.cos(pa(v)), CY + rr * Math.sin(pa(v))];
  const arcD = (v0: number, v1: number, rr: number) => { const [x0, y0] = pt(v0, rr), [x1, y1] = pt(v1, rr); return `M ${x0} ${y0} A ${rr} ${rr} 0 0 1 ${x1} ${y1}`; };
  const f1 = r(t, 1.6, 2.0, POP), f2 = r(t, 2.4, 2.8, POP), f3 = r(t, 3.4, 3.8, POP);
  const verdict = r(t, 5.4, 5.8, POP);
  const compare = r(t, 8.0, 8.6, EASE_IO);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: C.orange, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 280, textAlign: "center", color: C.ink }}>
        <Label color="rgba(28,28,30,0.6)" size={32}>RENTAL YIELD</Label>
      </div>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        {zones.map(([a, b, c], i) => (
          <path key={i} d={arcD(a + 0.08, b - 0.08, R)} fill="none" stroke={c} strokeWidth={70} pathLength={1} strokeDasharray={1}
            strokeDashoffset={1 - clamp(draw * 3 - i)} />
        ))}
        {Array.from({ length: 11 }, (_, v) => {
          const [x0, y0] = pt(v, R - 60), [x1, y1] = pt(v, R - 85);
          const [tx, ty] = pt(v, R - 125);
          return (
            <g key={v} opacity={r(t, 1.0 + v * 0.04, 1.3 + v * 0.04)}>
              <line x1={x0} y1={y0} x2={x1} y2={y1} stroke={C.ink} strokeWidth={6} strokeLinecap="round" />
              {v % 2 === 0 && <text x={tx} y={ty + 12} textAnchor="middle" fontFamily={UI} fontWeight={800} fontSize={34} fill={C.ink}>{v}%</text>}
            </g>
          );
        })}
        {/* market average marker */}
        <g opacity={compare}>
          <path d={`M ${pt(5, R + 50)[0]} ${pt(5, R + 50)[1]} L ${pt(5, R + 10)[0]} ${pt(5, R + 10)[1]}`} stroke={C.ink} strokeWidth={8} strokeLinecap="round" />
        </g>
        <g transform={`rotate(${needleA} ${CX} ${CY})`}>
          <path d={`M ${CX} ${CY - 16} L ${CX + R - 70} ${CY} L ${CX} ${CY + 16} Z`} fill={C.ink} />
        </g>
        <circle cx={CX} cy={CY} r={38} fill={C.ink} />
        <circle cx={CX} cy={CY} r={14} fill={C.orange} />
      </svg>
      {/* big readout */}
      <div style={{ position: "absolute", left: 0, right: 0, top: CY + 50, display: "flex", justifyContent: "center", alignItems: "baseline", gap: 4, color: C.ink }}>
        <Odo value={val} size={150} color={C.ink} font={DISPLAY} weight={400} /><span style={{ fontFamily: DISPLAY, fontSize: 110 }}>%</span>
      </div>
      {/* formula */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 1150, display: "flex", justifyContent: "center", alignItems: "center", gap: 14 }}>
        <Chip k={f1} bg="#fff" color={C.ink} size={36}>AED 105k rent</Chip>
        <span style={{ fontWeight: 900, fontSize: 48, color: C.ink, opacity: f2 }}>÷</span>
        <Chip k={f2} bg="#fff" color={C.ink} size={36}>AED 1.5M price</Chip>
        <span style={{ fontWeight: 900, fontSize: 48, color: C.ink, opacity: f3 }}>=</span>
        <Chip k={f3} bg={C.ink} color="#fff" size={36}>7%</Chip>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1270, display: "flex", justifyContent: "center", gap: 16 }}>
        <Chip k={verdict} bg={C.green} color="#06290F" size={44}>✓ Healthy yield</Chip>
        <Chip k={compare} bg="rgba(28,28,30,0.15)" color={C.ink} size={44}>▲ above a 5% bar</Chip>
      </div>
      <Sounds list={[[0.3, "swish", 0.3], [1.0, "tick", 0.2], [1.6, "pop", 0.25], [2.4, "pop", 0.25], [3.4, "pop", 0.25], [3.6, "riser", 0.18], [4.6, "impact", 0.3],
        [5.4, "ding", 0.3], [8.0, "tick", 0.3], [8.3, "pop", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-15  Viewing booking: a light plate morphs week strip -> time slots -> confirmation, a tap cursor drives it
// =====================================================================================================
const Viewing: React.FC = () => {
  const t = useT();
  const days = [["MON", 13], ["TUE", 14], ["WED", 15], ["THU", 16], ["FRI", 17], ["SAT", 18]] as [string, number][];
  const pickDay = r(t, 2.4, 2.7, POP);
  const slots = ["10:00", "13:30", "17:30"];
  const pickSlot = r(t, 5.0, 5.3, POP);
  const ink = C.ink;
  const tapAt = (a: number) => (t > a - 0.05 && t < a + 0.12 ? 0.8 : 1);
  const week = (
    <div style={{ position: "absolute", inset: 0, padding: "26px 34px", boxSizing: "border-box", color: ink }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ fontWeight: 900, fontSize: 44 }}>Book a viewing</div>
        <Label color="rgba(28,28,30,0.5)">OCT 2026</Label>
      </div>
      <div style={{ display: "flex", gap: 12, marginTop: 22 }}>
        {days.map(([d, n], i) => {
          const on = i === 3 && pickDay > 0;
          const k = r(t, 0.5 + i * 0.08, 0.8 + i * 0.08, POP);
          return (
            <div key={d} style={{ width: 128, height: 150, borderRadius: 26, background: on ? C.blue : "#EFEDE7", color: on ? "#fff" : ink, display: "flex", flexDirection: "column",
              alignItems: "center", justifyContent: "center", transform: `scale(${(0.7 + 0.3 * k) * (i === 3 ? tapAt(2.4) : 1)})`, opacity: clamp(k * 1.5) }}>
              <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 26, opacity: 0.7 }}>{d}</div>
              <div style={{ fontWeight: 900, fontSize: 56 }}>{n}</div>
              {i === 5 && <div style={{ width: 10, height: 10, borderRadius: 5, background: C.red, marginTop: 4 }} />}
            </div>
          );
        })}
      </div>
    </div>
  );
  const time = (
    <div style={{ position: "absolute", inset: 0, padding: "26px 34px", boxSizing: "border-box", color: ink }}>
      <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
        <div style={{ width: 84, height: 84, borderRadius: 22, background: C.blue, color: "#fff", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 18 }}>THU</div><div style={{ fontWeight: 900, fontSize: 38, lineHeight: 1 }}>16</div>
        </div>
        <div style={{ fontWeight: 900, fontSize: 44 }}>Pick a time</div>
      </div>
      <div style={{ display: "flex", gap: 14, marginTop: 24 }}>
        {slots.map((s, i) => {
          const on = i === 2 && pickSlot > 0;
          const k = r(t, 3.9 + i * 0.12, 4.2 + i * 0.12, POP);
          return <div key={s} style={{ flex: 1, height: 96, borderRadius: 24, border: `3px solid ${on ? C.blue : "#E0DDD5"}`, background: on ? "rgba(10,132,255,0.12)" : "transparent",
            display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 46, color: on ? C.blue : ink, opacity: clamp(k * 1.5),
            transform: `translateY(${(1 - k) * 30}px) scale(${i === 2 ? tapAt(5.0) : 1})` }}>{s}</div>;
        })}
      </div>
    </div>
  );
  const done = (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 26, padding: "0 36px", color: "#fff" }}>
      <div style={{ width: 120, height: 120, borderRadius: 60, background: "#fff", color: C.green, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 74, fontWeight: 900,
        transform: `scale(${r(t, 6.6, 7.0, POP)})`, flexShrink: 0 }}>✓</div>
      <div>
        <div style={{ fontWeight: 900, fontSize: 58, lineHeight: 1.05 }}>Viewing booked</div>
        <div style={{ fontWeight: 700, fontSize: 38, opacity: 0.9, marginTop: 6 }}>Thu 16 Oct · 17:30</div>
      </div>
    </div>
  );
  const remind = (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 20, padding: "0 30px", color: ink }}>
      <div style={{ width: 84, height: 84, borderRadius: 22, background: C.blue, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 46, flexShrink: 0 }}>🏡</div>
      <div style={{ flex: 1 }}>
        <div style={{ display: "flex", justifyContent: "space-between" }}><Label color="rgba(28,28,30,0.5)" size={26}>REMINDER</Label><Label color="rgba(28,28,30,0.4)" size={26}>NOW</Label></div>
        <div style={{ fontWeight: 800, fontSize: 40, marginTop: 4 }}>{typed("Viewing in 1 hour. See you there!", t, 9.9, 0.035)}</div>
      </div>
    </div>
  );
  // tap cursor: hops to the day, then the slot
  const cx = t < 3.6 ? lerp(700, 540 + 3 * 140 - 350 + 64 - 10, r(t, 1.6, 2.35, EASE_IO)) : lerp(560, 540 + 290 - 120, r(t, 4.3, 4.95, EASE_IO));
  const cy = t < 3.6 ? lerp(700, 430, r(t, 1.6, 2.35, EASE_IO)) : lerp(640, 430, r(t, 4.3, 4.95, EASE_IO));
  const cOn = (t > 1.6 && t < 2.9) || (t > 4.3 && t < 5.5);
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <Morph from={0.2} to={13} border="1.5px solid rgba(0,0,0,0.06)" states={[
        { at: 0, x: 540, y: 260, w: 900, h: 270, bg: "#FBF8F1", c: week },
        { at: 3.6, x: 540, y: 260, w: 820, h: 260, bg: "#FBF8F1", c: time },
        { at: 6.2, x: 540, y: 280, w: 760, h: 200, radius: 100, bg: "#30D158", c: done },
        { at: 9.4, x: 540, y: 270, w: 900, h: 170, radius: 44, bg: "#FBF8F1", c: remind },
      ]} />
      {cOn && <div style={{ position: "absolute", left: cx - 32, top: cy - 32, width: 64, height: 64, borderRadius: 32, background: "rgba(28,28,30,0.28)",
        border: "4px solid rgba(255,255,255,0.9)", boxSizing: "border-box", transform: `scale(${Math.min(tapAt(2.4), tapAt(5.0))})` }} />}
      <DemoCaption text="Pick a day that suits you" from={0.6} to={3.5} />
      <DemoCaption text="choose a time, and it's booked" from={3.7} to={9.2} />
      <DemoCaption text="we'll remind you before you go" from={9.5} to={12.8} />
      <Sounds list={[[0.2, "pop", 0.3], [0.5, "tick", 0.15], [2.4, "tick", 0.4], [2.45, "pop", 0.2], [3.6, "whoosh", 0.25], [3.9, "tick", 0.15], [5.0, "tick", 0.4],
        [6.2, "whoosh", 0.3], [6.6, "ding", 0.35], [9.4, "swish", 0.25], [9.6, "pop", 0.3], [9.9, "type", 0.2], [12.7, "swish", 0.25]]} />
    </AbsoluteFill>
  );
};


// =====================================================================================================
// m5-17  Market trend arrow: black "stock app" scene, a green arrow climbs a zig-zag over the years, ticks land
// =====================================================================================================
const TREND: [number, number][] = [[2019, 1000], [2020, 880], [2021, 1050], [2022, 1300], [2023, 1500], [2024, 1700], [2025, 1800], [2026, 1950]];
const TrendArrow: React.FC = () => {
  const t = useT();
  const X0 = 110, X1 = 920, Y0 = 1220, Y1 = 520;   // chart box
  const vMin = 800, vMax = 2000;
  const px = (i: number) => X0 + (i / (TREND.length - 1)) * (X1 - X0);
  const py = (v: number) => Y0 - ((v - vMin) / (vMax - vMin)) * (Y0 - Y1);
  const prog = r(t, 1.0, 7.0, EASE_IO) * (TREND.length - 1);
  const seg = Math.min(TREND.length - 2, Math.floor(prog));
  const f = prog - seg;
  const head = { x: lerp(px(seg), px(seg + 1), f), y: lerp(py(TREND[seg][1]), py(TREND[seg + 1][1]), f) };
  const val = lerp(TREND[seg][1], TREND[seg + 1][1], f);
  const ang = Math.atan2(py(TREND[seg + 1][1]) - py(TREND[seg][1]), px(seg + 1) - px(seg)) * 180 / Math.PI;
  const pts = TREND.slice(0, seg + 1).map(([, v], i) => `${px(i)},${py(v)}`).concat([`${head.x},${head.y}`]).join(" ");
  const area = `M ${X0} ${Y0} L ${pts.split(" ").join(" L ")} L ${head.x} ${Y0} Z`;
  const pct = r(t, 7.2, 7.7, POP);
  const dip = r(t, 1.9, 2.3, POP) * (1 - r(t, 4.0, 4.4));
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: "#000", overflow: "hidden" }}>
      <div style={{ position: "absolute", left: X0, top: 270 }}>
        <Label color="rgba(255,255,255,0.55)">AVG PRICE / SQFT · EXAMPLE</Label>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 6 }}>
          <span style={{ fontWeight: 800, fontSize: 40, color: "rgba(255,255,255,0.6)" }}>AED</span>
          <OdoC value={val} size={100} color={val < 1000 ? C.red : "#fff"} />
          <div style={{ marginLeft: 14, transform: `scale(${0.6 + 0.4 * pct})`, opacity: clamp(pct * 1.5) }}>
            <Chip k={1} bg="rgba(48,209,88,0.2)" color={C.green} size={40}>▲ 95%</Chip>
          </div>
        </div>
      </div>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        {[0, 1, 2, 3].map((i) => <line key={i} x1={X0} x2={X1} y1={Y1 + (i * (Y0 - Y1)) / 3} y2={Y1 + (i * (Y0 - Y1)) / 3} stroke="rgba(255,255,255,0.1)" strokeWidth={2} strokeDasharray="8 10" />)}
        <path d={area} fill="rgba(48,209,88,0.16)" />
        <polyline points={pts} fill="none" stroke={C.green} strokeWidth={10} strokeLinejoin="round" strokeLinecap="round" />
        {TREND.map(([y, v], i) => {
          const k = r(t, 1.0 + (i / (TREND.length - 1)) * 6 - 0.05, 1.0 + (i / (TREND.length - 1)) * 6 + 0.25, POP);
          return (
            <g key={y} opacity={clamp(k * 1.5)}>
              <circle cx={px(i)} cy={py(v)} r={10 * k} fill="#000" stroke={i === 1 ? C.red : C.green} strokeWidth={5} />
              <line x1={px(i)} x2={px(i)} y1={Y0 + 10} y2={Y0 + 30} stroke="rgba(255,255,255,0.5)" strokeWidth={3} />
              <text x={px(i)} y={Y0 + 72} textAnchor="middle" fontFamily={MONO} fontWeight={700} fontSize={28} fill="rgba(255,255,255,0.75)">{`'${String(y).slice(2)}`}</text>
            </g>
          );
        })}
        <g transform={`translate(${head.x} ${head.y}) rotate(${ang})`}>
          <path d="M -6 -30 L 46 0 L -6 30 Z" fill={C.green} />
        </g>
      </svg>
      {/* the dip label */}
      <div style={{ position: "absolute", left: px(1) + 30, top: py(880) + 20, opacity: clamp(dip * 1.5), transform: `scale(${0.7 + 0.3 * dip})` }}>
        <Chip k={1} bg="rgba(255,69,58,0.2)" color={C.red} size={32}>the dip</Chip>
      </div>
      <SceneCap text="Everyone waited for prices to drop" from={1.0} to={4.0} y={1345} color="#fff" size={50} />
      <SceneCap text="they kept climbing, year after year" from={4.2} to={7.6} y={1345} color="#fff" size={50} />
      <SceneCap text="the best time was yesterday" from={8.0} to={11.6} y={1345} color={C.green} size={50} />
      <Sounds list={[[0.2, "whoosh", 0.25], ...TREND.map((_, i) => [1.0 + (i / (TREND.length - 1)) * 6, "tick", 0.22] as [number, "tick", number]),
        [1.9, "pop", 0.25], [5.5, "riser", 0.15], [7.2, "pop", 0.35], [7.4, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-18  Before / after slider: a plate over his head shows the same room; the handle wipes bare -> renovated
// =====================================================================================================
const RoomArt: React.FC<{ after?: boolean; w: number; h: number }> = ({ after, w, h }) => (
  <svg width={w} height={h} viewBox="0 0 900 320" preserveAspectRatio="xMidYMid slice">
    <rect width="900" height="320" fill={after ? "#F4EBDD" : "#B9B6AE"} />
    <rect x="0" y="240" width="900" height="80" fill={after ? "#C89B6D" : "#8D8A83"} />
    <rect x="560" y="40" width="200" height="170" fill={after ? "#9FD8FF" : "#D6D3CB"} stroke={after ? "#fff" : "#9C998F"} strokeWidth="10" />
    {after ? (
      <>
        <rect x="90" y="160" width="300" height="90" rx="22" fill="#5E5CE6" />
        <rect x="90" y="128" width="300" height="52" rx="20" fill="#7D7BFF" />
        <rect x="150" y="40" width="120" height="80" rx="6" fill="#FFD60A" />
        <circle cx="470" cy="205" r="36" fill="#30D158" />
        <rect x="462" y="232" width="16" height="20" fill="#8A5A2B" />
        <rect x="610" y="250" width="240" height="20" rx="10" fill="#FF9F0A" opacity="0.8" />
        <line x1="820" y1="0" x2="820" y2="70" stroke="#1C1C1E" strokeWidth="4" />
        <path d="M 790 70 L 850 70 L 838 96 L 802 96 Z" fill="#1C1C1E" />
      </>
    ) : (
      <>
        <line x1="300" y1="0" x2="300" y2="80" stroke="#555" strokeWidth="3" />
        <circle cx="300" cy="90" r="12" fill="#EEE" />
        <path d="M 120 180 L 160 120 L 175 150" fill="none" stroke="#8D8A83" strokeWidth="4" />
        <rect x="380" y="200" width="70" height="50" fill="#A39F96" />
      </>
    )}
  </svg>
);
const BeforeAfter: React.FC = () => {
  const t = useT();
  const W = 960, H = 340;
  const enter = r(t, 0.1, 0.6, POP);
  // handle position 0..1 (share of the AFTER image revealed from the right)
  const pos = interpolate(t, [0, 1.6, 3.0, 4.2, 5.4, 7.2, 8.4], [0.92, 0.92, 0.5, 0.08, 0.6, 0.6, 0.0], { easing: EASE_IO, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const hx = W * pos;
  const val = r(t, 8.5, 9.6, EASE_IO);
  const out = r(t, 12.6, 13.0, EASE_IN);
  return (
    <AbsoluteFill style={{ fontFamily: UI }}>
      <Backdrop />
      <div style={{ position: "absolute", left: 540 - W / 2, top: 255, width: W, height: H, borderRadius: 40, overflow: "hidden", boxShadow: "0 22px 50px rgba(0,0,0,0.3)",
        border: "1.5px solid rgba(255,255,255,0.2)", transform: `scale(${(0.85 + 0.15 * enter) * (1 - out * 0.3)}) ${float(t, 1, 3)}`, opacity: clamp(enter * 1.4) * (1 - out), transformOrigin: "50% 0%" }}>
        <RoomArt w={W} h={H} />
        <div style={{ position: "absolute", left: hx, top: 0, right: 0, bottom: 0, overflow: "hidden" }}>
          <div style={{ position: "absolute", right: 0, top: 0 }}><RoomArt after w={W} h={H} /></div>
        </div>
        {/* labels */}
        <div style={{ position: "absolute", left: 24, top: 22, opacity: clamp(pos * 4) }}><Chip k={1} bg="rgba(28,28,30,0.8)" size={30}>BEFORE · AED 1.8M</Chip></div>
        <div style={{ position: "absolute", right: 24, top: 22, opacity: clamp((1 - pos) * 4) }}><Chip k={1} bg={C.green} color="#06290F" size={30}>AFTER · AED 2.3M</Chip></div>
        {/* handle */}
        <div style={{ position: "absolute", left: hx - 3, top: 0, bottom: 0, width: 6, background: "#fff" }} />
        <div style={{ position: "absolute", left: hx - 38, top: H / 2 - 38, width: 76, height: 76, borderRadius: 38, background: "#fff", display: "flex", alignItems: "center",
          justifyContent: "center", fontWeight: 900, fontSize: 32, color: C.ink, boxShadow: "0 6px 16px rgba(0,0,0,0.25)" }}>◀▶</div>
      </div>
      {/* the value delta, born under the plate */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 620, display: "flex", justifyContent: "center", transform: float(t, 2, 3) }}>
        <Chip k={val * (1 - out)} bg={C.gold} color={C.ink} size={48} style={{ padding: "14px 30px" }}>
          AED 150k reno → <span style={{ display: "inline-flex", alignItems: "baseline" }}>+AED&nbsp;<OdoC value={500000 * val} size={48} color={C.ink} /></span>
        </Chip>
      </div>
      <DemoCaption text="Same villa, same street" from={0.5} to={4.2} />
      <DemoCaption text="one has been renovated" from={4.3} to={8.3} />
      <DemoCaption text="and that's worth half a million more" from={8.5} to={12.6} />
      <Sounds list={[[0.1, "pop", 0.3], [1.6, "swish", 0.3], [3.0, "swish", 0.25], [4.2, "tick", 0.2], [5.4, "swish", 0.25], [7.2, "swish", 0.3], [8.4, "tick", 0.25],
        [8.5, "pop", 0.35], [9.6, "ding", 0.3], [12.6, "whoosh", 0.25]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-19  Buying process: pink colour block, a dot travels a winding road through 6 stops; each stop opens a pill
// =====================================================================================================
const STOPS: { x: number; y: number; ic: string; n: string; w: string }[] = [
  { x: 240, y: 470, ic: "💰", n: "Budget", w: "Day 1" },
  { x: 820, y: 600, ic: "🏠", n: "Viewings", w: "Week 1" },
  { x: 260, y: 760, ic: "🤝", n: "Offer", w: "Week 2" },
  { x: 820, y: 900, ic: "📄", n: "Agreement", w: "Week 2" },
  { x: 260, y: 1060, ic: "🏦", n: "Transfer", w: "Week 4" },
  { x: 820, y: 1200, ic: "🔑", n: "Keys", w: "Week 4" },
];
const Stepper: React.FC = () => {
  const t = useT();
  const at = (i: number) => 1.2 + i * 1.5;
  // path through the stops (smooth S-curves)
  const d = STOPS.map((s, i) => {
    if (i === 0) return `M ${s.x} ${s.y}`;
    const p = STOPS[i - 1];
    return `C ${p.x} ${(p.y + s.y) / 2 + 40}, ${s.x} ${(p.y + s.y) / 2 - 40}, ${s.x} ${s.y}`;
  }).join(" ");
  const travel = interpolate(t, STOPS.map((_, i) => at(i)), STOPS.map((_, i) => i), { easing: EASE_IO, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  // approximate dot on the bezier between stop i and i+1
  const i0 = Math.min(STOPS.length - 2, Math.floor(travel)), f = travel - i0;
  const P = STOPS[i0], Q = STOPS[i0 + 1];
  const my = (P.y + Q.y) / 2;
  const bz = (a: number, b: number, c: number, e: number, u: number) => (1 - u) ** 3 * a + 3 * (1 - u) ** 2 * u * b + 3 * (1 - u) * u * u * c + u ** 3 * e;
  const dot = { x: bz(P.x, P.x, Q.x, Q.x, f), y: bz(P.y, my + 40, my - 40, Q.y, f) };
  const road = r(t, 0.2, 1.2, EASE_IO);
  const end = r(t, 10.4, 11.0, EASE_IO);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: C.pink, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 270, display: "flex", justifyContent: "center", alignItems: "center", gap: 18, color: "#fff" }}>
        <Label color="rgba(255,255,255,0.8)" size={34}>BUYING · STEP</Label>
        <div style={{ background: "#fff", color: C.pink, borderRadius: 18, padding: "0 16px" }}><Odo value={travel + 1} size={64} color={C.pink} /></div>
        <Label color="rgba(255,255,255,0.8)" size={34}>OF 6</Label>
      </div>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        <path d={d} fill="none" stroke="rgba(255,255,255,0.35)" strokeWidth={26} strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - road} />
        <path d={d} fill="none" stroke="#fff" strokeWidth={26} strokeLinecap="round" pathLength={1} strokeDasharray={1}
          strokeDashoffset={1 - clamp(travel / (STOPS.length - 1))} />
      </svg>
      {STOPS.map((s, i) => {
        const k = r(t, at(i) - 0.1, at(i) + 0.35, POP);
        const passed = travel >= i - 0.01;
        const left = s.x > 540;
        return (
          <React.Fragment key={s.n}>
            <div style={{ position: "absolute", left: s.x - 46, top: s.y - 46, width: 92, height: 92, borderRadius: 46, background: passed ? "#fff" : "rgba(255,255,255,0.3)",
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 48, transform: `scale(${0.8 + 0.2 * k})`, opacity: road }}>{s.ic}</div>
            <div style={{ position: "absolute", top: s.y - 52, ...(left ? { right: 1080 - s.x + 66 } : { left: s.x + 66 }), opacity: clamp(k * 1.5),
              transform: `translateX(${(1 - k) * (left ? 40 : -40)}px)`, textAlign: left ? "right" : "left", color: "#fff", background: C.pink, padding: "4px 16px 8px", borderRadius: 18 }}>
              <div style={{ fontWeight: 900, fontSize: 56, lineHeight: 1.05 }}>{s.n}</div>
              <Label color="rgba(255,255,255,0.8)">{s.w.toUpperCase()}</Label>
            </div>
          </React.Fragment>
        );
      })}
      {/* the travelling dot (through-line): becomes a big key at the end */}
      <div style={{ position: "absolute", left: lerp(dot.x, 540, end) - 26, top: lerp(dot.y, 1330, end) - 26, width: 52, height: 52, borderRadius: 26, background: C.ink,
        border: "6px solid #fff", boxSizing: "border-box", transform: `scale(${r(t, 0.8, 1.1, POP) * (1 - end)})` }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 1290, display: "flex", justifyContent: "center", transform: float(t, 1, 3) }}>
        <Chip k={r(t, 10.8, 11.3, POP)} bg="#fff" color={C.pink} size={50} style={{ padding: "16px 34px" }}>~ 4 weeks, door to door</Chip>
      </div>
      <Sounds list={[[0.2, "swish", 0.3], ...STOPS.map((_, i) => [at(i), "pop", 0.3] as [number, "pop", number]), ...STOPS.slice(1).map((_, i) => [at(i) + 0.3, "whoosh", 0.12] as [number, "whoosh", number]),
        [at(5) + 0.1, "ding", 0.3], [10.4, "swish", 0.25], [10.8, "pop", 0.35]]} />
    </AbsoluteFill>
  );
};

// =====================================================================================================
// m5-20  Big agency vs boutique: split screen rows tick/cross, then the boutique side takes over -> EQT logo
// =====================================================================================================
const AgentVsBoutique: React.FC = () => {
  const t = useT();
  const rows: [string, string, string][] = [
    ["Your agent", "1 of 200", "1 on 1"],
    ["Replies", "next day", "same hour"],
    ["Listings", "everything", "hand-picked"],
    ["After the sale", "gone", "still here"],
  ];
  const at = (i: number) => 1.6 + i * 1.3;
  const split = r(t, 0.1, 0.8, EASE_IO);
  const take = r(t, 7.6, 8.6, EASE_IO);
  const rowsOut = r(t, 7.4, 7.8, EASE_IN);
  const logo = [r(t, 8.6, 9.1, POP), r(t, 8.8, 9.3, POP), r(t, 9.0, 9.5, POP)];
  const full = r(t, 10.0, 10.6, EASE_IO);
  const navy = "#0B1730";
  const LW = 540 * split * (1 - take);
  return (
    <AbsoluteFill style={{ fontFamily: UI, background: navy, overflow: "hidden" }}>
      {/* left: big agency (grey) */}
      <div style={{ position: "absolute", left: 0, top: 0, width: LW, bottom: 0, background: "#3A3A3C", overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, width: 540, top: 290, textAlign: "center", color: "#fff" }}>
          <div style={{ fontSize: 80 }}>🏢</div>
          <div style={{ fontWeight: 900, fontSize: 54, marginTop: 6 }}>Big agency</div>
        </div>
      </div>
      {/* right: boutique (eqt blue) */}
      <div style={{ position: "absolute", left: LW, top: 0, right: 0, bottom: 0, background: mix(C.eqt, navy, take), overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 290, textAlign: "center", color: "#fff", opacity: 1 - take }}>
          <div style={{ fontSize: 80 }}>🤝</div>
          <div style={{ fontWeight: 900, fontSize: 54, marginTop: 6 }}>Boutique</div>
        </div>
      </div>
      {/* VS badge */}
      <div style={{ position: "absolute", left: 540 - 60, top: 330, width: 120, height: 120, borderRadius: 60, background: "#fff", color: C.ink, display: "flex", alignItems: "center",
        justifyContent: "center", fontFamily: DISPLAY, fontSize: 56, transform: `scale(${r(t, 0.6, 1.0, POP) * (1 - take)})` }}>VS</div>
      {/* rows */}
      {rows.map(([lbl, a, b], i) => {
        const k = r(t, at(i), at(i) + 0.4, POP);
        const y = 560 + i * 190;
        return (
          <div key={lbl} style={{ position: "absolute", left: 0, right: 0, top: y, opacity: clamp(k * 1.5) * (1 - rowsOut), transform: `translateY(${(1 - k) * 30}px)` }}>
            <div style={{ textAlign: "center" }}><Label color="rgba(255,255,255,0.75)" size={30}>{lbl.toUpperCase()}</Label></div>
            <div style={{ display: "flex", marginTop: 14 }}>
              <div style={{ width: 540, display: "flex", justifyContent: "center", alignItems: "center", gap: 14, color: "#fff", fontWeight: 800, fontSize: 46 }}>
                <span style={{ color: C.red, fontSize: 44 }}>✕</span>{a}</div>
              <div style={{ width: 540, display: "flex", justifyContent: "center", alignItems: "center", gap: 14, color: "#fff", fontWeight: 900, fontSize: 46 }}>
                <span style={{ width: 52, height: 52, borderRadius: 26, background: "#fff", color: C.eqt, display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 34,
                  transform: `scale(${r(t, at(i) + 0.3, at(i) + 0.6, POP)})` }}>✓</span>{b}</div>
            </div>
          </div>
        );
      })}
      {/* outro: the EQT mark assembles from its three layers, then the full logo */}
      {take > 0 && (
        <div style={{ position: "absolute", left: 540 - 170, top: 560, width: 340, height: 340, opacity: 1 - full }}>
          {["eqt/layer-bot.png", "eqt/layer-mid.png", "eqt/layer-top.png"].map((src, i) => (
            <Img key={src} src={staticFile(src)} style={{ position: "absolute", inset: 0, width: 340, height: 340, opacity: clamp(logo[i] * 1.5),
              transform: `translateY(${(1 - logo[i]) * -160}px)` }} />
          ))}
        </div>
      )}
      {full > 0 && (
        <div style={{ position: "absolute", left: 540 - 380, top: 590, width: 760, opacity: full, transform: `scale(${0.9 + 0.1 * full}) ${float(t, 1, 3)}` }}>
          <Img src={staticFile("eqt/logo-full.png")} style={{ width: 760 }} />
        </div>
      )}
      <div style={{ position: "absolute", left: 0, right: 0, top: 1000, textAlign: "center", color: "#fff", fontFamily: SERIF, fontSize: 84, opacity: r(t, 10.6, 11.2),
        transform: `translateY(${(1 - r(t, 10.6, 11.2)) * 24}px)` }}>small team, full attention</div>
      <Sounds list={[[0.1, "whoosh", 0.3], [0.6, "pop", 0.3], ...rows.map((_, i) => [at(i), "pop", 0.25] as [number, "pop", number]),
        ...rows.map((_, i) => [at(i) + 0.3, "tick", 0.3] as [number, "tick", number]), [7.6, "whoosh", 0.35], [8.6, "pop", 0.25], [8.8, "pop", 0.25], [9.0, "pop", 0.3],
        [10.0, "riser", 0.15], [10.4, "ding", 0.35], [10.6, "swish", 0.2]]} />
    </AbsoluteFill>
  );
};

export const M5: LibItem[] = [
  { id: "m5-01", title: "Price tag swing", family: FAM, dur: 12, C: PriceTag,
    note: "A cream price tag on a string above his head; each new price (2021 → 2026) kicks it into a swing, then it flips to the gain. For 'what it cost then vs now'." },
  { id: "m5-03", title: "Contract signature", family: FAM, dur: 14, C: Contract,
    note: "Cream paper contract types its fields, a pen draws both signatures, an AGREED stamp slams, then it folds into a 'Signed' chip. For MOU / signing steps." },
  { id: "m5-04", title: "60/40 payment plan", family: FAM, dur: 13, C: PaymentPlan,
    note: "Graphite plate over his head: 60/40 off-plan plan bar fills (crane → keys), morphs into the AED split, then a takeaway pill. For off-plan payment plans." },
  { id: "m5-05", title: "Rent vs buy balance", family: FAM, dur: 12, C: RentVsBuy,
    note: "Indigo colour block: a balance scale; rent chips pile up year by year while the house fills as equity, the beam tips to BUY. For rent-vs-buy talk." },
  { id: "m5-06", title: "ROI coin stack", family: FAM, dur: 13, C: RoiCoins,
    note: "Split screen: coins of rent drop into five yearly stacks while the return % counts up, then restack into one tower. For ROI / rental income talk." },
  { id: "m5-07", title: "Listing card", family: FAM, dur: 12, C: ListingCard,
    note: "A line stretches into a cream listing card over his head: price counts up, bed/bath/sqft chips, heart tap, photo swipe, NEW badge. For showing a listing." },
  { id: "m5-08", title: "Floor plan draw", family: FAM, dur: 12.5, C: FloorPlan,
    note: "Blueprint scene: walls draw themselves, doors swing, sqft counts up, rooms fill with flat colour and a dot tours the layout. For layout talk." },
  { id: "m5-09", title: "Floors counter", family: FAM, dur: 12, C: FloorsCounter,
    note: "Sky scene: a generic tower rises floor by floor with a crane while a big counter climbs to 40, then your floor lights gold. For high-floor / off-plan builds." },
  { id: "m5-10", title: "Commission split pie", family: FAM, dur: 12, C: CommissionPie,
    note: "A gold AED coin over his head is cut into a pie; each slice lifts with its share of an illustrative AED 100k commission. For how commission is split." },
  { id: "m5-11", title: "Service-charge breakdown", family: FAM, dur: 12, C: ServiceCharge,
    note: "iOS-light scene with Max in a face bubble: one AED 24k total bar splits into rows (security, cleaning…) with amounts, then folds into 'AED 2,000 a month'. For service-charge talk." },
  { id: "m5-12", title: "Mortgage checklist", family: FAM, dur: 11.5, C: Checklist,
    note: "Green colour block: an iOS documents list ticks item by item while a ring fills to 100%, then the card collapses into one big tick: 'Pre-approved'. For any what-you-need list." },
  { id: "m5-14", title: "Rental yield gauge", family: FAM, dur: 11, C: YieldGauge,
    note: "Orange colour block: a flat gauge draws its red/gold/green zones, the formula chips fill (rent ÷ price) and the needle swings to 7%. For yield talk." },
  { id: "m5-15", title: "Viewing booking", family: FAM, dur: 13, C: Viewing,
    note: "A light plate over his head morphs week strip → time slots → green 'Viewing booked' pill → reminder notification, driven by a tap cursor. For booking-a-viewing CTAs." },
  { id: "m5-17", title: "Market trend arrow", family: FAM, dur: 12, C: TrendArrow,
    note: "Black stock-app scene: a green arrow climbs a zig-zag over the years (with 'the dip'), price/sqft counts along, +95% chip lands. For 'prices kept rising' talk." },
  { id: "m5-18", title: "Before / after slider", family: FAM, dur: 13, C: BeforeAfter,
    note: "A plate over his head shows the same room bare vs renovated; the handle wipes back and forth, then a gold chip counts the added value. For renovation / value-add." },
  { id: "m5-19", title: "Buying process road", family: FAM, dur: 12, C: Stepper,
    note: "Pink colour block: a dot travels a winding road through 6 stops (budget → keys), each opens its label + week; step counter, '~4 weeks door to door'. For process explainers." },
  { id: "m5-20", title: "Agency vs boutique + EQT outro", family: FAM, dur: 12.5, C: AgentVsBoutique,
    note: "Split screen big agency (grey) vs boutique (blue), rows of ✕/✓; the blue side takes over and the EQT mark assembles from its 3 layers into the logo. Outro / why-us." },
];
