import React from "react";
import { Easing, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import type { Pal } from "./kit11";

// 030 "game launch" (kit12 quiet): ONE Steam-style store card from frame 0 (the real Deep Rise hero art + logo from Max's Steam
// cache, a 7-day countdown), whose launch checklist fills row by row as he talks (card height grows, size-only morph), a
// "GOING LIVE" stamp on the payoff, then the rows give way to the wishlist button that gets clicked. No fake gameplay.
const { fontFamily: UI } = loadInter("normal", { weights: ["600", "700", "800"], subsets: ["latin"] });
const useT = () => { const f = useCurrentFrame(); const { fps } = useVideoConfig(); return f / fps; };
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const IO = Easing.bezier(0.65, 0, 0.35, 1);
const IN = Easing.bezier(0.3, 0, 1, 1);
const r = (t: number, a: number, b: number, e = OUT) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
const lerp = (a: number, b: number, k: number) => a + (b - a) * k;
const LABEL: React.CSSProperties = { fontFamily: UI, fontWeight: 700, fontSize: 22, letterSpacing: 2.4, textTransform: "uppercase" };

export type SteamRow = { at: number; label: string; value?: string; tone?: "mute" | "bad" | "warn" | "good";
  count?: { to: number; suffix: string; dur?: number };   // value counts 1 -> to on its word
  pill?: { at: number; text: string };                      // small status pill that joins the value later
  crew?: { dotsAt: number; dotsDur: number; nights: number } };   // one dot per day left, filling while he talks
export type SteamMedia = { at: number; src: string; aspect: number; focusY: number; video?: boolean; start?: number };
export type SteamDef = { from: number; to: number; x: number; y: number; w: number; room: number; headStart: number; media: SteamMedia[]; logo: string; ctaHead: number;
  days: number; rows: SteamRow[]; greyAt: number; colorAt: number; liveAt: number; stampTo: number; ctaAt: number; clickAt: number; cta: string };
export const STEAM_HEAD = 200, STEAM_RH = 66, STEAM_PAD = 22;
export const steamH = (rows: number, head = STEAM_HEAD) => head + STEAM_PAD * 2 + rows * STEAM_RH;

export const SteamCard: React.FC<{ d: SteamDef; pal: Pal }> = ({ d, pal }) => {
  const t = useT();
  const { fps } = useVideoConfig();
  if (t < d.from || t > d.to) return null;
  const P = 36, green = "#5BA32B", lime = "#A4D007", red = "#FF5A5F", amber = "#F2B544", blue = "#66C0F4", txt = "#C7D5E0", dim = "#8F98A0";
  const enter = r(t, d.from, d.from + 0.5), exit = r(t, d.to - 0.35, d.to, IN);
  // height: grows one row per spoken item, shrinks to the button panel at the CTA (size-only morph, content stays put)
  const grown = d.rows.reduce((acc, row) => acc + r(t, row.at - 0.05, row.at + 0.4, IO), 0);
  const ctaK = r(t, d.ctaAt - 0.1, d.ctaAt + 0.45, IO);
  // frame 1: a big header (the proof), shrinking as the checklist fills; the card scales so it always fits above his hair
  const HEADH = lerp(lerp(d.headStart, STEAM_HEAD, Math.min(1, grown / 2)), d.ctaHead, ctaK);
  const H = steamH(lerp(grown, 2, ctaK), HEADH) - STEAM_PAD * 2 * (1 - Math.min(1, grown + ctaK));   // no empty strip under the header on frame 1
  const grey = r(t, d.greyAt, d.greyAt + 0.8, IO) * (1 - r(t, d.colorAt - 0.1, d.colorAt + 0.5, IO));
  const live = r(t, d.liveAt, d.liveAt + 0.35, Easing.bezier(0.2, 0.9, 0.3, 1));
  const tone = (x?: string) => x === "bad" ? red : x === "warn" ? amber : x === "good" ? lime : x === "mute" ? dim : txt;
  // countdown: 7 days, the clock under it ticks down live (tabular numbers, fixed box so nothing jitters)
  const left = Math.max(0, 86399 - Math.floor(t));
  const clock = [Math.floor(left / 3600), Math.floor(left / 60) % 60, left % 60].map((n) => String(n).padStart(2, "0")).join(":");
  const click = r(t, d.clickAt, d.clickAt + 0.25);
  const press = Math.sin(Math.PI * r(t, d.clickAt - 0.08, d.clickAt + 0.16, IO));
  const cur = r(t, d.ctaAt + 0.3, d.clickAt - 0.08, IO);
  return (
    <div style={{ position: "absolute", left: d.x - d.w / 2, top: d.y, width: d.w, height: H, transformOrigin: "50% 0%", opacity: enter * (1 - exit),
      transform: `scale(${Math.min(1, d.room / H) * (0.96 + 0.04 * enter)})` }}>
      <div style={{ position: "absolute", left: "8%", right: "8%", top: "30%", bottom: -26, borderRadius: 36, filter: "blur(34px)", opacity: 0.45,
        background: `linear-gradient(90deg, ${pal.a}, ${pal.gold})` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 36, padding: 2, background: `linear-gradient(135deg, #FFFFFF 0%, ${pal.c}66 45%, ${pal.gold}AA 100%)`,
        boxShadow: `0 30px 60px -18px ${pal.a}AA, 0 12px 26px -10px rgba(15,23,42,0.4)` }}>
        <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 34, overflow: "hidden", background: "linear-gradient(180deg, #1B2838 0%, #131C26 100%)" }}>
          {/* header: real Deep Rise media (trailer, gameplay shots, Steam page), greys out while the game "sits there", colour back on "this week" */}
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: HEADH, overflow: "hidden" }}>
            {d.media.map((m, i) => {
              const nx = d.media[i + 1];
              const v = Math.min(i === 0 ? 1 : r(t, m.at, m.at + 0.4, IO), nx ? 1 - r(t, nx.at + 0.35, nx.at + 0.45, IN) : 1);
              if (v <= 0.001) return null;
              const mh = d.w / m.aspect, top = HEADH / 2 - m.focusY * mh;   // focusY = the media row that sits at the header's centre
              const push = m.video ? 1 : 1.03 + 0.05 * r(t, m.at, nx ? nx.at + 0.4 : d.to, (x) => x);
              const style: React.CSSProperties = { position: "absolute", left: 0, top, width: d.w, height: mh, objectFit: "cover",
                filter: `grayscale(${grey}) brightness(${(m.video ? 1.25 : 1.1) - 0.3 * grey})`, transform: `scale(${push})`, transformOrigin: `50% ${m.focusY * 100}%` };
              return <div key={i} style={{ position: "absolute", inset: 0, opacity: v }}>
                {m.video
                  ? <Sequence from={Math.round(m.at * fps) - 12} layout="none"><OffthreadVideo src={staticFile(m.src)} startFrom={Math.round((m.start ?? 0) * fps)} muted style={style} /></Sequence>
                  : <Img src={staticFile(m.src)} style={style} />}
              </div>;
            })}
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(90deg, rgba(10,14,20,0.55) 0%, rgba(10,14,20,0) 38%, rgba(10,14,20,0) 55%, rgba(10,14,20,0.8) 100%)" }} />
            <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 60, background: "linear-gradient(180deg, rgba(27,40,56,0) 0%, #1B2838 100%)" }} />
            <Img src={staticFile(d.logo)} style={{ position: "absolute", left: 22, top: 14, width: Math.min(250, HEADH - 28), height: Math.min(250, HEADH - 28), opacity: 1 - ctaK, filter: `grayscale(${grey * 0.8}) drop-shadow(0 6px 10px rgba(0,0,0,0.6))` }} />
            {/* countdown box (fixed width, right) */}
            <div style={{ position: "absolute", right: 26, top: 24, width: 236, height: 152, borderRadius: 22, background: "rgba(16,22,30,0.82)",
              border: `2px solid ${live > 0.5 ? lime : "rgba(102,192,244,0.45)"}`, boxSizing: "border-box", padding: "14px 20px" }}>
              <div style={{ ...LABEL, fontSize: 18, color: live > 0.5 ? lime : blue, opacity: 1 - live * 0 }}>{live > 0.5 ? "Early Access" : "Launches in"}</div>
              <div style={{ position: "absolute", left: 20, top: 44, display: "flex", alignItems: "baseline", gap: 10, opacity: 1 - live }}>
                <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 64, lineHeight: 1, color: "#FFFFFF", fontVariantNumeric: "tabular-nums" }}>{d.days}</span>
                <span style={{ ...LABEL, fontSize: 22, color: txt }}>days</span>
              </div>
              <div style={{ position: "absolute", left: 20, top: 112, fontFamily: UI, fontWeight: 700, fontSize: 22, color: dim, fontVariantNumeric: "tabular-nums", opacity: 1 - live }}>{clock}</div>
              <div style={{ position: "absolute", left: 20, top: 50, opacity: live, transform: `scale(${lerp(1.3, 1, live)})`, transformOrigin: "0 50%",
                fontFamily: UI, fontWeight: 800, fontSize: 40, lineHeight: 1.05, color: lime, whiteSpace: "nowrap" }}>Going<br />live</div>
            </div>
          </div>
          {/* the launch checklist: one row per spoken item */}
          <div style={{ position: "absolute", left: 0, right: 0, top: HEADH + STEAM_PAD - 6, opacity: 1 - ctaK, filter: ctaK > 0.01 ? `blur(${ctaK * 8}px)` : undefined }}>
            {d.rows.map((row, i) => {
              if (t < row.at - 0.05) return null;
              const k = r(t, row.at, row.at + 0.45);
              const n = row.count ? Math.max(1, Math.round(lerp(1, row.count.to, r(t, row.at, row.at + (row.count.dur ?? 0.7), IO)))) : 0;
              const pk = row.pill ? r(t, row.pill.at, row.pill.at + 0.4) : 0;
              const c = row.crew;
              return <div key={i} style={{ position: "absolute", left: P, right: P, top: i * STEAM_RH, height: STEAM_RH, display: "flex", alignItems: "center",
                opacity: k, transform: `translateY(${(1 - k) * 16}px)`, filter: k < 0.99 ? `blur(${(1 - k) * 8}px)` : undefined,
                borderBottom: i < d.rows.length - 1 ? "1.5px solid rgba(199,213,224,0.12)" : undefined }}>
                <span style={{ fontFamily: UI, fontWeight: 600, fontSize: 32, color: dim, width: 250 }}>{row.label}</span>
                <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 16 }}>
                  {row.pill && pk > 0 && <span style={{ ...LABEL, fontSize: 20, letterSpacing: 1.6, padding: "6px 14px", borderRadius: 14, background: "rgba(143,152,160,0.22)",
                    color: txt, opacity: pk, transform: `translateX(${(1 - pk) * 14}px)` }}>{row.pill.text}</span>}
                  {c ? <>
                    {Array.from({ length: c.nights }, (_, j) => {
                      const on = r(t, c.dotsAt + (j * c.dotsDur) / c.nights, c.dotsAt + (j * c.dotsDur) / c.nights + 0.25);
                      return <div key={j} style={{ width: 20, height: 20, borderRadius: 10, boxSizing: "border-box", border: `2.5px solid ${on > 0.5 ? amber : "rgba(199,213,224,0.3)"}`,
                        background: on > 0.5 ? amber : "transparent", transform: `scale(${1 + 0.25 * Math.sin(Math.PI * on)})` }} />;
                    })}
                  </> : <>
                    <div style={{ width: 14, height: 14, borderRadius: 7, background: tone(row.tone) }} />
                    <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 36, color: tone(row.tone), fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap" }}>
                      {row.count ? `${n} ${n === 1 ? row.count.suffix.replace("weeks", "week") : row.count.suffix}` : row.value}</span>
                  </>}
                </div>
              </div>;
            })}
            {/* payoff stamp across the checklist */}
            {live > 0 && t < d.stampTo + 0.4 && <div style={{ position: "absolute", left: "50%", top: 2 * STEAM_RH, transform: `translate(-50%, -50%) rotate(-6deg) scale(${lerp(1.6, 1, live)})`,
              opacity: Math.min(1, live * 1.5) * (1 - r(t, d.stampTo, d.stampTo + 0.35, IN)), padding: "10px 30px", border: `6px solid ${lime}`, borderRadius: 18, background: "rgba(19,28,38,0.94)",
              fontFamily: UI, fontWeight: 800, fontSize: 60, letterSpacing: 2, color: lime, whiteSpace: "nowrap", boxShadow: "0 18px 40px -14px rgba(164,208,7,0.5)" }}>GOING LIVE</div>}
          </div>
          {/* CTA: the wishlist button, a cursor glides in and clicks it on "wishlist" */}
          {ctaK > 0 && <div style={{ position: "absolute", left: P, right: P, top: HEADH + STEAM_PAD, height: STEAM_RH * 2 - 8, opacity: ctaK,
            transform: `translateY(${(1 - ctaK) * 14}px)` }}>
            <div style={{ position: "absolute", left: 0, top: 6, width: 400, fontFamily: UI, fontWeight: 700, fontSize: 30, lineHeight: 1.3, color: txt }}>{d.cta}</div>
            <div style={{ position: "absolute", right: 0, top: 4, width: 340, height: 112, borderRadius: 18, boxSizing: "border-box",
              background: click > 0.5 ? `linear-gradient(135deg, ${lime} 0%, ${green} 100%)` : `linear-gradient(135deg, #47BFFF 0%, #1A44C2 100%)`,
              transform: `scale(${1 - 0.05 * press})`, display: "flex", alignItems: "center", justifyContent: "center", gap: 14,
              boxShadow: click > 0.5 ? "0 14px 30px -12px rgba(164,208,7,0.6)" : "0 14px 30px -12px rgba(71,191,255,0.6)" }}>
              {click > 0.5 && <svg width={34} height={34} viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" /></svg>}
              <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34, color: "#fff", whiteSpace: "nowrap" }}>{click > 0.5 ? "On wishlist" : "Add to wishlist"}</span>
            </div>
            {/* cursor */}
            <svg width={44} height={52} viewBox="0 0 22 26" style={{ position: "absolute", left: lerp(380, 700, cur) - 6, top: lerp(150, 70, cur), opacity: r(t, d.ctaAt + 0.2, d.ctaAt + 0.5),
              transform: `scale(${1 - 0.12 * press})`, filter: "drop-shadow(0 3px 4px rgba(0,0,0,0.5))" }}>
              <path d="M2 2 L2 21 L7 16.5 L10.5 24 L14 22.5 L10.5 15 L17.5 15 Z" fill="#FFFFFF" stroke="#0F172A" strokeWidth={1.6} strokeLinejoin="round" />
            </svg>
          </div>}
        </div>
      </div>
    </div>
  );
};
