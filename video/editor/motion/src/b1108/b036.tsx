import React from "react";
import { Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { Baby, Coins, ShoppingBag, Heart, House, MapPin, Trophy, UserRound, Waves } from "lucide-react";
import type { Pal } from "../kit11";

// Video 036 "Our best purchase in Dubai was an island" (quiet A/B day). Owned by the 036 edit only.
// Card = ONE floor-plan plate at the top that fills toward the payoff. The kitchen island is the through-line object:
// hook (Dubai flat WITH the island, "Best purchase", "In the ocean" struck -> "Our kitchen") -> Canada (walls melt away, open kitchen, the island grows big)
// -> Dubai 2-bedroom (walls draw back in, counters shrink to a tiny corner, the island leaves a dashed ghost)
// -> 2 adults + a toddler squeeze into the corner, a 12-month ring fills -> the island slides into the ghost, family spreads out
// -> gold "Best purchase" + AED 1,000 counts up -> "Favorite island in Dubai" (the one zoom, set in plan_036.py). Right column = a fill-up list per chapter. Never draws a real place or landmark.
export const Scene: React.FC<{ s: { kind: string } & Record<string, unknown>; w: number; h: number; t: number; p: Pal }> = () => null;

const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) => interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 800, fontSize: 26, letterSpacing: 2.4, textTransform: "uppercase" };

type D = { from: number; to: number; x: number; y: number; w: number; h: number; scale: number;
  notAt: number; kitchenAt: number; canadaAt: number; hugeAt: number; loveAt: number; dubaiAt: number; cornerAt: number; smallAt: number;
  people: number[]; crampedAt: number; yearAt: number; boughtAt: number; bestAt: number; priceAt: number; price: number; favAt: number; askAt: number };

// plan box (SVG units = px inside the card)
const PW = 470, PH = 300;
type Box = [number, number, number, number];            // x, y, w, h
const lb = (a: Box, b: Box, k: number): Box => [lerp(a[0], b[0], k), lerp(a[1], b[1], k), lerp(a[2], b[2], k), lerp(a[3], b[3], k)];
// counters: Canada = long run on the top wall + left wall; Dubai = tiny L in the top-left corner
const TOP_C: Box = [16, 16, 330, 44], TOP_D: Box = [16, 16, 120, 40];
const LEFT_C: Box = [16, 60, 44, 200], LEFT_D: Box = [16, 56, 40, 70];
const ISL_C: Box = [130, 128, 230, 76], ISL_D: Box = [76, 140, 120, 50];
// family spots: squeezed in the corner -> spread around the island
const SQUEEZE = [[76, 78], [130, 84], [104, 120]], SPREAD = [[56, 232], [234, 166], [142, 248]];

export const Card: React.FC<{ d: Record<string, unknown>; pal: Pal }> = ({ d: raw, pal }) => {
  const d = raw as unknown as D;
  const t = useT();
  if (t < d.from || t > d.to) return null;
  const P = 36, HEAD = 80, green = "#16A34A", red = "#E5484D", wood = "#D9A066", woodD = "#B07A43", wall = "#3B3F4A";
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);

  // ---- plan state ----
  const cw = r(t, d.canadaAt - 0.15, d.canadaAt + 0.55, IO) * (1 - r(t, d.dubaiAt - 0.15, d.dubaiAt + 0.55, IO));   // 1 = Canada
  const walls = 1 - cw;
  const gone = r(t, d.dubaiAt - 0.1, d.dubaiAt + 0.5, IO) * (1 - r(t, d.boughtAt + 0.15, d.boughtAt + 0.45, OUT));
  // the family steps aside first, then the island grows into its ghost outline (small overshoot): it never passes through them
  const back = interpolate(t, [d.boughtAt + 0.15, d.boughtAt + 0.75], [0, 1], { easing: Easing.bezier(0.2, 1.4, 0.4, 1), extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const isl = lb(ISL_D, ISL_C, cw);
  const corner = r(t, d.cornerAt, d.cornerAt + 0.45) * (1 - r(t, d.boughtAt, d.boughtAt + 0.4));
  const squeeze = Math.sin(Math.PI * r(t, d.crampedAt, d.crampedAt + 0.5, IO));   // "too cramped": the corner box pulses once
  const spread = r(t, d.boughtAt - 0.15, d.boughtAt + 0.45, IO);
  const plan = (
    <svg width={PW} height={PH} viewBox={`0 0 ${PW} ${PH}`} style={{ position: "absolute", left: P, top: HEAD + 26, overflow: "visible" }}>
      <rect x={4} y={4} width={PW - 8} height={PH - 8} rx={10} fill="#FBF7F1" stroke={wall} strokeWidth={8} />
      {/* Dubai inner walls: two bedrooms on the right, drawn in (dash offset) */}
      {[["M 300 4 L 300 120", 116], ["M 300 176 L 300 296", 120], ["M 300 150 L 466 150", 166]].map(([p, len], i) =>
        <path key={i} d={p as string} stroke={wall} strokeWidth={7} strokeLinecap="round" fill="none"
          strokeDasharray={len as number} strokeDashoffset={(len as number) * (1 - walls)} opacity={walls > 0.02 ? 1 : 0} />)}
      {["Bedroom 1", "Bedroom 2"].map((l, i) => <text key={l} x={383} y={i ? 232 : 86} textAnchor="middle" fontFamily={UI} fontWeight={700} fontSize={25}
        fill="#7A808D" opacity={walls}>{l}</text>)}
      {/* counters */}
      {[lb(TOP_D, TOP_C, cw), lb(LEFT_D, LEFT_C, cw)].map((b, i) =>
        <rect key={i} x={b[0]} y={b[1]} width={b[2]} height={b[3]} rx={6} fill="#E8DCCB" stroke="#C9B79E" strokeWidth={2.5} />)}
      {/* tiny-corner highlight */}
      <rect x={8} y={8} width={150} height={128} rx={14} fill={`${red}14`} stroke={red} strokeWidth={3.5 + 2.5 * squeeze} strokeDasharray="10 8" opacity={corner} />
      {/* island ghost (Dubai, before it's bought) */}
      <rect x={ISL_D[0]} y={ISL_D[1]} width={ISL_D[2]} height={ISL_D[3]} rx={10} fill="none" stroke="#B9BEC9" strokeWidth={3} strokeDasharray="9 7" opacity={gone} />
      {/* the island */}
      <g opacity={1 - gone} transform={t >= d.boughtAt ? `translate(${isl[0] + isl[2] / 2} ${isl[1] + isl[3] / 2}) scale(${0.5 + 0.5 * back}) translate(${-isl[0] - isl[2] / 2} ${-isl[1] - isl[3] / 2})` : undefined}>
        <rect x={isl[0]} y={isl[1]} width={isl[2]} height={isl[3]} rx={10} fill={wood} stroke={woodD} strokeWidth={3}
          style={{ filter: `drop-shadow(0 6px 8px ${woodD}66)` }} />
        <text x={isl[0] + isl[2] / 2} y={isl[1] + isl[3] / 2 + 8} textAnchor="middle" fontFamily={UI} fontWeight={800} fontSize={lerp(24, 32, cw)} fill="#fff">Island</text>
      </g>
      {/* family: 2 adults + a toddler */}
      {SQUEEZE.map((s, i) => {
        const x = lerp(s[0], SPREAD[i][0], spread), y = lerp(s[1], SPREAD[i][1], spread) + (1 - spread) * Math.sin(t * 9 + i * 2) * 3 * r(t, d.people[i], d.people[i] + 0.45);
        const R = i === 2 ? 18 : 25, k = r(t, d.people[i], d.people[i] + 0.45);
        const Icon = i === 2 ? Baby : UserRound;
        return <g key={i} opacity={k} transform={`translate(${x} ${y}) scale(${0.6 + 0.4 * k})`}>
          <circle r={R} fill={[pal.a, pal.c, pal.gold2][i]} stroke="#fff" strokeWidth={3} />
          <Icon x={-R * 0.6} y={-R * 0.6} width={R * 1.2} height={R * 1.2} color="#fff" strokeWidth={2.6} />
        </g>;
      })}
    </svg>
  );

  // ---- right column: fill-up list per chapter ----
  const CX = P + PW + 28, CW = d.w - CX - P;
  const row = (at: number, i: number, icon: React.ReactNode, bg: string, text: React.ReactNode, extra: React.CSSProperties = {}) => {
    const k = r(t, at, at + 0.45);
    return <div key={i} style={{ position: "absolute", left: CX, top: HEAD + 26 + i * 80, width: CW, height: 60, display: "flex", alignItems: "center", gap: 14,
      opacity: k, transform: `translateY(${(1 - k) * 14}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 5}px)` : undefined, ...extra }}>
      <div style={{ width: 56, height: 56, borderRadius: 17, background: bg, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center",
        boxShadow: "0 8px 16px -10px rgba(15,23,42,0.45)" }}>{icon}</div>
      <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 32, lineHeight: 1.08, color: pal.ink, whiteSpace: "nowrap" }}>{text}</div>
    </div>;
  };
  const ic = (I: typeof House, c = "#fff") => <I size={32} color={c} strokeWidth={2.4} />;
  const WARM = `linear-gradient(135deg, ${pal.a} 0%, ${pal.b} 100%)`, GOLD = `linear-gradient(135deg, ${pal.gold} 0%, ${pal.gold2} 100%)`;
  const strike = r(t, d.notAt + 0.35, d.notAt + 0.75, IO);
  const badge = (at: number, top: number) => {
    const k = r(t, at, at + 0.5, Easing.bezier(0.2, 1.3, 0.4, 1));
    return <div style={{ position: "absolute", left: CX, top, width: CW, height: 120, borderRadius: 24, background: GOLD, boxSizing: "border-box",
      padding: "0 20px", display: "flex", alignItems: "center", gap: 16, opacity: Math.min(1, k * 1.5), transform: `scale(${0.85 + 0.15 * k})`,
      boxShadow: `0 16px 30px -14px ${pal.gold2}` }}>
      <Trophy size={54} color="#fff" strokeWidth={2.4} />
      <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 38, lineHeight: 1.05, color: "#fff", letterSpacing: -0.5 }}>Best<br />purchase</div>
    </div>;
  };
  // 12-month counter (ring fills, number counts up)
  const pk = r(t, d.priceAt, d.priceAt + 0.9, IO), price = Math.round(d.price * pk).toLocaleString("en-US");
  const mk = r(t, d.yearAt, d.yearAt + 1.2, IO), months = Math.round(12 * mk);
  const ring = <svg width={52} height={52} viewBox="0 0 52 52"><circle cx={26} cy={26} r={21} fill="none" stroke="#E6EAF1" strokeWidth={6} />
    <circle cx={26} cy={26} r={21} fill="none" stroke={red} strokeWidth={6} strokeLinecap="round" strokeDasharray={132} strokeDashoffset={132 * (1 - mk)} transform="rotate(-90 26 26)" /></svg>;

  const cols: [number, React.ReactNode][] = [
    [d.from, <>
      {badge(d.from, HEAD + 26)}
      {row(d.notAt, 2, ic(Waves), "#38BDF8", <span style={{ position: "relative", color: "#64748B" }}>In the ocean
        <span style={{ position: "absolute", left: -4, top: "50%", height: 4, width: `${strike * 104}%`, background: red, borderRadius: 2 }} /></span>)}
      {row(d.kitchenAt, 3, ic(House), green, <>Our kitchen</>)}
    </>],
    [d.canadaAt - 0.15, <>
      {row(d.canadaAt, 0, ic(MapPin), red, <>Canada</>)}
      {row(d.hugeAt, 1, <svg width={32} height={20}><rect x={1} y={1} width={30} height={18} rx={4} fill={wood} stroke="#fff" strokeWidth={2} /></svg>, woodD, <>Huge island</>)}
      {row(d.loveAt, 2, ic(Heart), "#F43F5E", <>Loved it</>)}
    </>],
    [d.dubaiAt - 0.15, <>
      {row(d.dubaiAt, 0, ic(MapPin), WARM, <>Dubai</>)}
      {row(d.cornerAt, 1, <svg width={30} height={30}><path d="M4 4h22v8H12v14H4z" fill="#fff" /></svg>, red, <>Corner kitchen<br /><span style={{ fontSize: 25, color: red, opacity: r(t, d.smallAt, d.smallAt + 0.4) }}>Too small</span></>)}
      {row(d.people[0], 2, ic(UserRound), pal.a, <>2 adults<br /><span style={{ fontSize: 25, color: pal.mute, opacity: r(t, d.people[2], d.people[2] + 0.4) }}>+ 1 toddler</span></>)}
      {row(d.yearAt, 3, <div style={{ position: "relative", width: 52, height: 52 }}>{ring}</div>, "#FFFFFF",
        <span style={{ fontVariantNumeric: "tabular-nums" }}><span style={{ fontWeight: 800, fontSize: 38 }}>{months}</span> {months === 1 ? "month" : "months"}</span>)}
    </>],
    [d.boughtAt - 0.15, <>
      {row(d.boughtAt, 0, ic(ShoppingBag), green, <>Bought<br />the island</>)}
      {badge(d.bestAt, HEAD + 26 + 84)}
      {row(d.priceAt, 3, ic(Coins), GOLD, <span style={{ fontVariantNumeric: "tabular-nums" }}>AED <span style={{ fontWeight: 800, fontSize: 38 }}>{price}</span></span>,
        { top: HEAD + 26 + 84 + 120 + 26 })}
    </>],
  ];
  const vis = (i: number) => {
    const a = cols[i][0], b = i + 1 < cols.length ? cols[i + 1][0] : 1e9;
    return Math.min(i === 0 ? 1 : r(t, a, a + 0.35, IO), 1 - r(t, b, b + 0.3, IN));
  };
  // header titles run on their own clock (the last one lands on the payoff)
  const titles: [number, string][] = [[d.from, "Best purchase in Dubai"], [d.canadaAt - 0.15, "Before: Canada"], [d.dubaiAt - 0.15, "Dubai: year one"],
    [d.boughtAt - 0.15, "The island"], [d.favAt - 0.15, "Favorite island in Dubai"], [d.askAt - 0.1, "Your best buy of 2026?"]];
  const tvis = (i: number) => {
    const a = titles[i][0], b = i + 1 < titles.length ? titles[i + 1][0] : 1e9;
    return Math.min(i === 0 ? 1 : r(t, a, a + 0.35, IO), 1 - r(t, b, b + 0.3, IN));
  };
  const layer = (i: number, node: React.ReactNode, v = vis(i)) => {
    if (v <= 0.001) return null;
    return <div key={i} style={{ position: "absolute", inset: 0, opacity: v, transform: `translateY(${(1 - v) * 12}px)`, filter: v < 0.99 ? `blur(${(1 - v) * 8}px)` : undefined }}>{node}</div>;
  };

  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: d.h, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${d.scale * (0.96 + 0.04 * enter)})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.5,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.a}55 45%, ${pal.gold}88 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}66, 0 12px 26px -10px rgba(15,23,42,0.28)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #FFFFFF 0%, #F7F8FC 100%)" }}>
          {/* header: title cross-fades per chapter; the dashed rule stays */}
          {titles.map(([, tt], i) => layer(i, <div style={{ position: "absolute", left: P, right: P, top: 0, height: HEAD, display: "flex", alignItems: "center", gap: 12, ...LABEL, color: pal.ink }}>
            <div style={{ width: 14, height: 14, borderRadius: 7, background: pal.gold, boxShadow: `0 0 0 5px ${pal.gold}44` }} />{tt}</div>, tvis(i)))}
          <div style={{ position: "absolute", left: P, right: P, top: HEAD - 2, borderTop: "2.5px dashed #D9DEE8" }} />
          {plan}
          {cols.map(([, node], i) => layer(i, node))}
        </div>
      </div>
    </div>
  );
};
