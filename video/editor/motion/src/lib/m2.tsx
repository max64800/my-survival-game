import React, { useMemo } from "react";
import { AbsoluteFill } from "remotion";
import { ThreeCanvas } from "@remotion/three";
import { useThree } from "@react-three/fiber";
import * as THREE from "three";
import { RoundedBoxGeometry } from "three/examples/jsm/geometries/RoundedBoxGeometry.js";
import {
  useT, r, lerp, clamp, env, float, rand, mix, C, EASE, EASE_IN, EASE_IO, POP, LIQUID,
  Backdrop, Sounds, Plate, Label, Odo, DemoCaption, LibItem, UI, SERIF, MONO, DISPLAY,
} from "./common";

// Family 2 — 3D shape stories (@remotion/three). Every scene ACTS OUT an idea with flat matte shapes, soft studio light,
// no tone-mapping (so iOS colours stay exact) and slow camera moves that ease and settle. No continuous spinning props.
const FAM = "3D shape stories";

// ---------------------------------------------------------------- shared 3D helpers
type V3 = [number, number, number];
type Cam = { pos: V3; look: V3; fov?: number };
const mixV = (a: V3, b: V3, k: number): V3 => [lerp(a[0], b[0], k), lerp(a[1], b[1], k), lerp(a[2], b[2], k)];
const mixCam = (a: Cam, b: Cam, k: number): Cam => ({ pos: mixV(a.pos, b.pos, k), look: mixV(a.look, b.look, k), fov: lerp(a.fov ?? 30, b.fov ?? 30, k) });
/** camera path: start at `base`, then each [from, to, cam] glides there (EASE_IO) and settles. `drift` adds a tiny idle sway. */
const camPath = (t: number, base: Cam, moves: [number, number, Cam][], drift = 0.04): Cam => {
  let c = base;
  for (const [a, b, cam] of moves) c = mixCam(c, cam, r(t, a, b, EASE_IO));
  return { ...c, pos: [c.pos[0] + Math.sin(t * 0.5) * drift, c.pos[1] + Math.sin(t * 0.37 + 1) * drift * 0.6, c.pos[2]] };
};
const makeCam = (cam: Cam, w: number, h: number) => {
  const c = new THREE.PerspectiveCamera(cam.fov ?? 30, w / h, 0.1, 400);
  c.position.set(...cam.pos);
  c.lookAt(...cam.look);
  c.updateMatrixWorld();
  c.updateProjectionMatrix();
  return c;
};
/** world point -> pixel inside a canvas of w x h (for HTML labels that track 3D objects) */
const project = (cam: Cam, w: number, h: number, p: V3): [number, number] => {
  const v = new THREE.Vector3(...p).project(makeCam(cam, w, h));
  return [(v.x + 1) / 2 * w, (1 - v.y) / 2 * h];
};

const CamRig: React.FC<{ cam: Cam }> = ({ cam }) => {
  const { camera } = useThree();
  const pc = camera as THREE.PerspectiveCamera;
  pc.position.set(...cam.pos);
  pc.fov = cam.fov ?? 30;
  pc.near = 0.1; pc.far = 400;
  pc.lookAt(...cam.look);
  pc.updateProjectionMatrix();
  pc.updateMatrixWorld();
  return null;
};

/** soft studio light: sky/ground fill + one key light (optionally casting a soft shadow) + a cool rim */
const Lights: React.FC<{ shadows?: boolean; span?: number; keyPos?: V3; amb?: number }> = ({ shadows, span = 8, keyPos = [5, 10, 7], amb = 2.4 }) => (
  <>
    <hemisphereLight args={["#ffffff", "#c9c3b8", amb]} />
    <directionalLight position={keyPos} intensity={2.6} castShadow={shadows}
      shadow-mapSize={[4096, 4096]} shadow-bias={-0.0005} shadow-normalBias={0.02}
      shadow-camera-left={-span} shadow-camera-right={span} shadow-camera-top={span} shadow-camera-bottom={-span} shadow-camera-near={0.5} shadow-camera-far={60} />
    <directionalLight position={[-6, 4, -3]} intensity={0.5} color="#dfe8ff" />
  </>
);

/** a transparent 3D canvas placed at (x, y) on the 1080x1920 frame */
const Stage: React.FC<{ w: number; h: number; x?: number; y?: number; cam: Cam; shadows?: boolean; span?: number; lightKey?: V3; amb?: number; children: React.ReactNode }> =
  ({ w, h, x = 0, y = 0, cam, shadows, span, lightKey, amb, children }) => (
    <div style={{ position: "absolute", left: x, top: y, width: w, height: h }}>
      <ThreeCanvas width={w} height={h} flat shadows={shadows} gl={{ alpha: true, antialias: true }} style={{ backgroundColor: "transparent" }}
        camera={{ fov: cam.fov ?? 30, position: cam.pos, near: 0.1, far: 400 }}>
        <CamRig cam={cam} />
        <Lights shadows={shadows} span={span} keyPos={lightKey} amb={amb} />
        {children}
      </ThreeCanvas>
    </div>
  );

/** shadow-catching floor (invisible except for the soft shadow) */
const ShadowFloor: React.FC<{ y?: number; size?: number; opacity?: number }> = ({ y = 0, size = 60, opacity = 0.16 }) => (
  <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, y, 0]} receiveShadow>
    <planeGeometry args={[size, size]} />
    <shadowMaterial opacity={opacity} />
  </mesh>
);

/** matte material */
const Mat: React.FC<{ c: string; o?: number; rough?: number }> = ({ c, o = 1, rough = 0.85 }) =>
  <meshStandardMaterial color={c} roughness={rough} metalness={0} transparent={o < 1} opacity={o} />;

/** vertical pillar of height 1 with rounded vertical edges (scale y freely — the top stays crisp) */
const usePillar = (w: number, d: number, rad: number) => useMemo(() => {
  const s = new THREE.Shape();
  const x0 = -w / 2, z0 = -d / 2;
  s.moveTo(x0 + rad, z0); s.lineTo(x0 + w - rad, z0); s.quadraticCurveTo(x0 + w, z0, x0 + w, z0 + rad);
  s.lineTo(x0 + w, z0 + d - rad); s.quadraticCurveTo(x0 + w, z0 + d, x0 + w - rad, z0 + d);
  s.lineTo(x0 + rad, z0 + d); s.quadraticCurveTo(x0, z0 + d, x0, z0 + d - rad);
  s.lineTo(x0, z0 + rad); s.quadraticCurveTo(x0, z0, x0 + rad, z0);
  const g = new THREE.ExtrudeGeometry(s, { depth: 1, bevelEnabled: false, curveSegments: 6 });
  g.rotateX(-Math.PI / 2);          // extrude along +y
  return g;
}, [w, d, rad]);

const useRBox = (w: number, h: number, d: number, rad = 0.04) => useMemo(() => new RoundedBoxGeometry(w, h, d, 3, rad), [w, h, d, rad]);

/** big caption line for light colour scenes (ink text, no glow) */
const InkCap: React.FC<{ text: React.ReactNode; from: number; to: number; y?: number; color?: string; size?: number }> = ({ text, from, to, y = 1250, color = C.ink, size = 60 }) => {
  const t = useT();
  if (t < from || t > to) return null;
  const k = env(t, from, to, 0.25, 0.25);
  return (
    <div style={{ position: "absolute", left: 80, right: 180, top: y, textAlign: "center", fontFamily: UI, fontWeight: 800, fontSize: size, color,
      lineHeight: 1.15, opacity: k, transform: `translateY(${(1 - k) * 18}px)` }}>{text}</div>
  );
};

/** small rounded tag (HTML) anchored at a point; anchor = bottom-centre by default */
const Tag: React.FC<{ x: number; y: number; k: number; bg?: string; color?: string; size?: number; children: React.ReactNode; anchor?: "bottom" | "top" | "center" }> =
  ({ x, y, k, bg = C.ink, color = "#fff", size = 32, children, anchor = "bottom" }) => {
    if (k <= 0) return null;
    const ty = anchor === "bottom" ? "-100%" : anchor === "top" ? "0%" : "-50%";
    return (
      <div style={{ position: "absolute", left: x, top: y, transform: `translate(-50%, ${ty}) scale(${0.6 + 0.4 * clamp(k)})`, transformOrigin: anchor === "top" ? "50% 0%" : "50% 100%",
        opacity: clamp(k * 1.6), background: bg, color, fontFamily: UI, fontWeight: 800, fontSize: size, padding: `${size * 0.22}px ${size * 0.5}px`, borderRadius: size * 0.55,
        whiteSpace: "nowrap", display: "flex", alignItems: "center", gap: 8 }}>{children}</div>
    );
  };

/** comma-formatted whole number for labels that should NOT roll (static) */
const fmt = (n: number) => Math.round(n).toLocaleString("en-US");

/** odometer with thousands separators (same rolling rule as Odo: rests on whole numbers, commas sit still) */
const OdoC: React.FC<{ value: number; size: number; color?: string; font?: string }> = ({ value, size, color = "#fff", font = UI }) => {
  const v = Math.max(0, value);
  const digits = String(Math.round(v)).length;
  const cols: number[] = [];
  for (let d = digits - 1; d >= 0; d--) {
    const p = Math.pow(10, d), base = Math.floor(v / p) % 10;
    cols.push(d === 0 ? base + (v - Math.floor(v)) : base + Math.max(0, (v % p) - (p - 1)));
  }
  const lh = size * 1.05;
  return (
    <div style={{ display: "flex", height: lh, overflow: "hidden", color }}>
      {cols.map((c, i) => {
        const pos = digits - 1 - i;
        return (
          <React.Fragment key={i}>
            <div style={{ height: lh, overflow: "hidden" }}>
              <div style={{ transform: `translateY(${-c * lh}px)` }}>
                {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((n, j) => (
                  <div key={j} style={{ height: lh, fontSize: size, lineHeight: `${lh}px`, fontFamily: font, fontWeight: 900, textAlign: "center" }}>{n}</div>
                ))}
              </div>
            </div>
            {pos > 0 && pos % 3 === 0 && <div style={{ fontSize: size, lineHeight: `${lh}px`, fontFamily: font, fontWeight: 900 }}>,</div>}
          </React.Fragment>
        );
      })}
    </div>
  );
};

/** Max inside a round bubble (for full-screen scenes) */
const FaceBubble: React.FC<{ x: number; y: number; d: number; k?: number }> = ({ x, y, d, k = 1 }) => {
  const s = d / 860;   // the face zone (~860 px wide) fills the bubble
  return (
    <div style={{ position: "absolute", left: x - d / 2, top: y - d / 2, width: d, height: d, borderRadius: d / 2, overflow: "hidden", background: "#000",
      transform: `scale(${clamp(k)})`, border: "6px solid #fff", boxSizing: "border-box" }}>
      <div style={{ position: "absolute", left: d / 2 - 540 * s, top: d / 2 - 900 * s, width: 1080, height: 1920, transform: `scale(${s})`, transformOrigin: "0 0" }}>
        <Backdrop />
      </div>
    </div>
  );
};

/** split screen: Max pushed down into the lower part, the top part is a colour scene of height h */
const SplitMax: React.FC<{ h: number; shift: number }> = ({ shift }) => (
  <AbsoluteFill style={{ transform: `translateY(${shift}px)` }}><Backdrop /></AbsoluteFill>
);

// ================================================================ m2-01  price bars rising (full screen, cream)
const PRICES = [1150, 1310, 1520, 1780, 2050];
const YEARS = ["2021", "2022", "2023", "2024", "2025"];
const M01: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const pillar = usePillar(1, 1, 0.12);
  const at = (i: number) => 0.05 + i * 1.25;
  const hOf = (i: number) => PRICES[i] / 420;            // world units
  const xs = (i: number) => (i - 2) * 1.5;
  const cam = camPath(t, { pos: [-5.5, 2.2, 13], look: [-2.6, 0.9, 0], fov: 34 }, [
    [0.2, 6.6, { pos: [4.5, 7, 22], look: [0, 2.2, 0], fov: 34 }],
    [9.3, 11.6, { pos: [3.2, 7.6, 21], look: [0.2, 2.5, 0], fov: 34 }],
  ]);
  const hero = r(t, 7.0, 7.6, POP);
  const pct = r(t, 7.0, 8.2, EASE);
  return (
    <AbsoluteFill style={{ background: C.cream }}>
      <Stage w={W} h={H} cam={cam} shadows span={10}>
        <ShadowFloor />
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.001, 0]}><circleGeometry args={[6.4, 96]} /><Mat c="#ECE7DC" /></mesh>
        {PRICES.map((_, i) => {
          const k = r(t, at(i), at(i) + 1.0, EASE);
          const last = i === 4;
          const lift = last ? 1 + 0.04 * Math.sin(Math.min(1, r(t, 9.4, 10.2)) * Math.PI) : 1;
          if (k < 0.01) return null;
          return (
            <mesh key={i} geometry={pillar} position={[xs(i), 0, 0]} scale={[1, Math.max(0.001, hOf(i) * k * lift), 1]} castShadow receiveShadow>
              <Mat c={last ? C.blue : mix("#BFD9FF", "#7DB7FF", i / 3)} />
            </mesh>
          );
        })}
      </Stage>
      {/* tracking labels: value above, year on the floor */}
      {PRICES.map((p, i) => {
        const k = r(t, at(i), at(i) + 1.0, EASE);
        const [tx, ty] = project(cam, W, H, [xs(i), hOf(i) * k + 0.15, 0.5]);
        const [yx, yy] = project(cam, W, H, [xs(i), 0, 0.95]);
        const a = r(t, at(i) + 0.05, at(i) + 0.35);
        return (
          <React.Fragment key={i}>
            <div style={{ position: "absolute", left: tx, top: ty, transform: "translate(-50%,-100%)", opacity: a }}>
              <OdoC value={lerp(0, p, k)} size={40} color={i === 4 ? C.blue : C.ink} />
            </div>
            <div style={{ position: "absolute", left: yx, top: yy, transform: "translate(-50%, 6px)", opacity: a, fontFamily: MONO, fontWeight: 700, fontSize: 30, color: "rgba(28,28,30,0.6)" }}>{YEARS[i]}</div>
          </React.Fragment>
        );
      })}
      <div style={{ position: "absolute", left: 80, top: 300 }}>
        <Label color="rgba(28,28,30,0.55)" size={30}>AVG PRICE · AED / SQ FT</Label>
        <div style={{ display: "flex", alignItems: "baseline", gap: 14, marginTop: 14, opacity: clamp(hero * 1.5), transform: `scale(${0.7 + 0.3 * hero})`, transformOrigin: "0 50%" }}>
          <span style={{ fontFamily: UI, fontWeight: 900, fontSize: 120, color: C.green }}>+</span>
          <Odo value={lerp(0, 78, pct)} size={120} color={C.green} />
          <span style={{ fontFamily: UI, fontWeight: 900, fontSize: 120, color: C.green }}>%</span>
          <span style={{ fontFamily: SERIF, fontSize: 64, color: C.ink, marginLeft: 8 }}>in 5 years</span>
        </div>
      </div>
      <InkCap text="Prices nearly doubled" from={1.0} to={6.6} y={1330} />
      <InkCap text={<>And they're <span style={{ color: C.blue }}>still climbing</span></>} from={9.2} to={12} y={1330} />
      <Sounds list={[[0.3, "whoosh", 0.25], [0.35, "riser", 0.15], ...PRICES.map((_, i) => [at(i) + 0.75, "tick", 0.35] as [number, "tick", number]),
        [7.0, "impact", 0.35], [7.1, "ding", 0.3], [9.4, "swish", 0.25], [9.6, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-02  floors stacking with a counter (split screen)
const FLOORS = 40;
const M02: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1000;
  const slab = useRBox(2.4, 0.07, 2.4, 0.03);
  const glass = useRBox(2.24, 0.2, 2.24, 0.02);
  // floor i lands at landAt(i): starts slow, accelerates, last few slow again
  const landAt = (i: number) => 0.4 + 7.2 * Math.pow(i / (FLOORS - 1), 0.85);
  const FH = 0.27;
  let built = 0;
  for (let i = 0; i < FLOORS; i++) built += r(t, landAt(i) - 0.6, landAt(i) + 0.25, EASE);
  const topY = Math.max(2.2, built * FH);
  const base = { pos: [6 + topY * 0.25, 1.2 + topY * 0.8, 8 + topY * 1.15] as V3, look: [0, topY * 0.52, 0] as V3, fov: 36 };
  const cam = camPath(t, base, [
    [8.6, 11.5, { pos: [7.5, 11, 17.5], look: [0, 6.2, 0], fov: 36 }],
  ], 0.06);
  const ph = r(t, 8.3, 8.8, POP);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <SplitMax h={H} shift={520} />
      <div style={{ position: "absolute", left: 0, top: 0, width: W, height: H, background: "#0E1A33", overflow: "hidden" }}>
        <Stage w={W} h={H} cam={cam} shadows span={8} amb={1.5}>
          <mesh rotation={[-Math.PI / 2, 0, 0]} receiveShadow><circleGeometry args={[4, 64]} /><Mat c="#1B2A4A" /></mesh>
          {Array.from({ length: FLOORS }, (_, i) => {
            const a = landAt(i);
            if (t < a - 0.6) return null;
            const k = r(t, a - 0.6, a + 0.25, EASE);
            const y = i * FH + (1 - k) * 3.2;
            const top = i === FLOORS - 1;
            return (
              <group key={i} position={[0, y, 0]}>
                <mesh geometry={glass} position={[0, 0.1, 0]} castShadow><Mat c={top ? C.gold : i % 5 === 4 ? "#5FA8FF" : "#8EC5FF"} /></mesh>
                <mesh geometry={slab} position={[0, 0.235, 0]} castShadow receiveShadow><Mat c="#F4F6FA" /></mesh>
              </group>
            );
          })}
        </Stage>
        <div style={{ position: "absolute", left: 70, top: 280 }}>
          <Label size={30}>FLOOR</Label>
          <Odo value={Math.floor(built) + clamp((built % 1 - 0.6) / 0.4)} size={150} color="#fff" />
        </div>
        {(() => {
          const [x, y] = project(cam, W, H, [1.25, FLOORS * FH + 0.35, 1.25]);
          return <Tag x={x + 40} y={y - 10} k={ph} bg={C.gold} color={C.ink} size={38}>Penthouse</Tag>;
        })()}
        <div style={{ position: "absolute", left: 0, right: 0, top: H - 3, height: 3, background: "rgba(255,255,255,0.25)" }} />
      </div>
      <DemoCaption text="40 floors in 18 months" from={1} to={7.8} y={1040} />
      <DemoCaption text="and the top floor sells first" from={8.4} to={12} y={1040} />
      <Sounds list={[[0.3, "whoosh", 0.25], ...Array.from({ length: 10 }, (_, j) => [landAt(j * 4 + 3) + 0.2, "tick", 0.3] as [number, "tick", number]),
        [landAt(FLOORS - 1) + 0.2, "impact", 0.4], [8.3, "ding", 0.35], [8.8, "swish", 0.2]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-03  a generic district rising from the ground (full screen, sky)
const GRID = 7;
const M03: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const pillar = usePillar(0.82, 0.82, 0.08);
  const blocks = useMemo(() => {
    const out: { x: number; z: number; h: number; d: number; c: string; i: number }[] = [];
    let i = 0;
    for (let gx = 0; gx < GRID; gx++) for (let gz = 0; gz < GRID; gz++) {
      if (gx === 3 || gz === 3) continue;   // roads
      const x = (gx - 3) * 1.1, z = (gz - 3) * 1.1;
      const d = Math.hypot(x, z);
      const h = 0.4 + rand(gx * 13 + gz * 7) * 1.6 + (d < 2.5 ? 1.2 : 0);
      const c = rand(gx * 3 + gz * 11) > 0.82 ? "#9CCBFF" : rand(gx + gz * 5) > 0.6 ? "#E9EDF3" : "#FFFFFF";
      out.push({ x, z, h, d, c, i: i++ });
    }
    return out;
  }, []);
  const riseAt = (d: number) => -0.6 + d * 0.75;
  const heroK = r(t, 6.6, 7.8, EASE);
  const hero = blocks.reduce((a, b) => (Math.abs(b.x - 1.1) + Math.abs(b.z - 1.1) < Math.abs(a.x - 1.1) + Math.abs(a.z - 1.1) ? b : a));
  const built = blocks.filter((b) => t > riseAt(b.d) + 0.6).length;
  const cam = camPath(t, { pos: [24, 30, 24], look: [0, 0, 0], fov: 24 }, [
    [0.3, 6.4, { pos: [22, 19, 25], look: [0, 0.6, 0], fov: 24 }],
    [6.6, 9.4, { pos: [13, 11, 15], look: [hero.x * 0.6, 1.6, hero.z * 0.6], fov: 26 }],
  ], 0.05);
  const [px, py] = project(cam, W, H, [hero.x, hero.h + 1.4 + 0.2, hero.z]);
  return (
    <AbsoluteFill style={{ background: "#DCEBFB" }}>
      <Stage w={W} h={H} cam={cam} shadows span={9}>
        <ShadowFloor opacity={0.14} />
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.002, 0]} receiveShadow><planeGeometry args={[8.3, 8.3]} /><Mat c="#F3F6FA" /></mesh>
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.001, 0]}><planeGeometry args={[0.5, 8.3]} /><Mat c="#C9D2DE" /></mesh>
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.002, 0]}><planeGeometry args={[8.3, 0.5]} /><Mat c="#C9D2DE" /></mesh>
        {blocks.map((b) => {
          const k = r(t, riseAt(b.d), riseAt(b.d) + 0.9, EASE);
          const isHero = b === hero;
          const h = b.h * k + (isHero ? 1.4 * heroK : 0);
          if (h <= 0.001) return null;
          return (
            <mesh key={b.i} geometry={pillar} position={[b.x, 0, b.z]} scale={[1, h, 1]} castShadow receiveShadow>
              <Mat c={isHero && heroK > 0 ? mix(b.c === "#FFFFFF" ? "#FFFFFF" : "#E9EDF3", C.orange, heroK) : b.c} />
            </mesh>
          );
        })}
      </Stage>
      <div style={{ position: "absolute", left: 80, top: 290 }}>
        <Label color="rgba(28,28,30,0.55)" size={30}>NEW BUILDINGS</Label>
        <Odo value={built} size={130} color={C.ink} />
      </div>
      <Tag x={px} y={py} k={r(t, 7.4, 7.9, POP)} bg={C.orange} color="#fff" size={40}>📍 Buy here</Tag>
      <InkCap text="A whole district in ten years" from={1.2} to={6.4} />
      <InkCap text={<>Buy <span style={{ color: C.orange }}>before</span> it's finished</>} from={7.6} to={12} />
      <Sounds list={[[0.3, "riser", 0.2], [0.5, "whoosh", 0.25], [1.6, "tick", 0.25], [2.4, "tick", 0.25], [3.2, "tick", 0.25], [4.2, "impact", 0.3],
        [6.6, "swish", 0.3], [7.4, "pop", 0.35], [7.6, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-04  rent coins piling up per year (over video, fitted plate)
const M04: React.FC = () => {
  const t = useT();
  const PW = 940, PH = 360, CW = 560;
  const coin = useMemo(() => new THREE.CylinderGeometry(0.42, 0.42, 0.12, 48), []);
  const PER = 7, YRS = 5;
  const dropAt = (y: number, j: number) => 0.15 + y * 1.5 + j * 0.13;
  const cam = camPath(t, { pos: [0.8, 2.6, 7.2], look: [0, 0.55, 0], fov: 30 }, [
    [0.4, 8.5, { pos: [-0.8, 3.2, 7.6], look: [0, 0.7, 0], fov: 30 }],
  ], 0.04);
  const per = 96000 / PER;   // illustrative: AED 96,000 rent a year
  let landed = 0;
  for (let y = 0; y < YRS; y++) for (let j = 0; j < PER; j++) if (t > dropAt(y, j) + 0.3) landed++;
  const shown = landed * per;
  const pk = r(t, 0.1, 0.5, EASE);
  const roi = r(t, 8.4, 8.9, POP);
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={240} w={PW} h={PH} k={pk}>
        <div style={{ position: "absolute", left: 40, top: 40 }}>
          <Label size={28}>RENT COLLECTED</Label>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 10, marginTop: 12 }}>
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 38, color: "rgba(255,255,255,0.6)", paddingBottom: 10 }}>AED</span>
            <OdoC value={shown} size={66} color="#fff" />
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 26 }}>
            {Array.from({ length: YRS }, (_, y) => {
              const on = t > dropAt(y, 0);
              return <div key={y} style={{ width: 54, height: 44, borderRadius: 12, fontFamily: MONO, fontWeight: 700, fontSize: 26, display: "flex", alignItems: "center", justifyContent: "center",
                background: on ? "rgba(255,214,10,0.18)" : "rgba(255,255,255,0.07)", color: on ? C.gold : "rgba(255,255,255,0.4)" }}>Y{y + 1}</div>;
            })}
          </div>
          <div style={{ marginTop: 22, display: "inline-flex", padding: "8px 18px", borderRadius: 18, background: C.green, color: C.ink, fontFamily: UI, fontWeight: 900, fontSize: 36,
            opacity: clamp(roi * 1.5), transform: `scale(${0.6 + 0.4 * roi})`, transformOrigin: "0 50%" }}>7.2% a year</div>
        </div>
        <Stage w={CW} h={PH} x={PW - CW} cam={cam} amb={1.9} lightKey={[3, 8, 6]}>
          {Array.from({ length: YRS }, (_, y) => (
            <group key={y} position={[(y - 2) * 1.0, 0, 0]}>
              {Array.from({ length: PER }, (_, j) => {
                const a = dropAt(y, j);
                if (t < a - 0.01) return null;
                const k = r(t, a, a + 0.32, EASE_IN);
                const settle = Math.sin(r(t, a + 0.32, a + 0.6) * Math.PI) * 0.03;
                return (
                  <mesh key={j} geometry={coin} position={[Math.sin(j * 2.1 + y) * 0.03, j * 0.13 + 0.06 + (1 - k) * 2.6 + settle, Math.cos(j * 1.7) * 0.03]}>
                    <meshStandardMaterial color={C.gold} roughness={0.6} metalness={0} />
                  </mesh>
                );
              })}
            </group>
          ))}
        </Stage>
      </Plate>
      <DemoCaption text="Every year the rent piles up" from={0.8} to={8.2} />
      <DemoCaption text="7.2% back on your money" from={8.6} to={12} />
      <Sounds list={[[0.1, "swish", 0.25], ...Array.from({ length: YRS }, (_, y) => Array.from({ length: PER }, (_, j) => [dropAt(y, j) + 0.3, "tick", 0.16 + 0.02 * y] as [number, "tick", number])).flat(),
        [8.4, "ding", 0.38], [8.45, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// canvas texture (system font so it is ready on frame 1)
const useCanvasTex = (w: number, h: number, draw: (g: CanvasRenderingContext2D) => void, deps: unknown[]) => useMemo(() => {
  const c = document.createElement("canvas"); c.width = w; c.height = h;
  draw(c.getContext("2d")!);
  const tx = new THREE.CanvasTexture(c); tx.colorSpace = THREE.SRGBColorSpace; tx.anisotropy = 8;
  return tx;
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, deps);
const SYS = "-apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif";

// ================================================================ m2-05  listing cards in depth, camera dolly (full screen, graphite)
const CARDS5 = [
  { type: "STUDIO", price: "AED 750K", y: "6.1%", c: C.teal },
  { type: "1 BED", price: "AED 1.2M", y: "6.8%", c: C.blue },
  { type: "2 BED", price: "AED 1.9M", y: "7.4%", c: C.green },
  { type: "3 BED", price: "AED 2.8M", y: "6.3%", c: C.orange },
  { type: "VILLA", price: "AED 6.5M", y: "5.2%", c: C.purple },
];
const Card5: React.FC<{ i: number; pos: V3; rotY: number; dim: number }> = ({ i, pos, rotY, dim }) => {
  const d = CARDS5[i];
  const tex = useCanvasTex(720, 960, (g) => {
    g.fillStyle = "#FFFFFF"; g.beginPath(); g.roundRect(0, 0, 720, 960, 56); g.fill();
    g.fillStyle = d.c; g.beginPath(); g.roundRect(28, 28, 664, 420, 36); g.fill();
    // flat house glyph
    g.fillStyle = "rgba(255,255,255,0.95)";
    g.beginPath(); g.moveTo(360, 120); g.lineTo(520, 250); g.lineTo(200, 250); g.closePath(); g.fill();
    g.fillRect(230, 250, 260, 150);
    g.fillStyle = d.c; g.fillRect(335, 310, 50, 90);
    g.fillStyle = "#1C1C1E"; g.font = `800 92px ${SYS}`; g.fillText(d.type, 52, 580);
    g.fillStyle = "#3A3A3C"; g.font = `700 64px ${SYS}`; g.fillText(d.price, 52, 680);
    g.fillStyle = "#F2F2F7"; g.beginPath(); g.roundRect(52, 760, 616, 140, 32); g.fill();
    g.fillStyle = "#8E8E93"; g.font = `700 44px ${SYS}`; g.fillText("YIELD", 88, 846);
    g.fillStyle = d.c; g.font = `900 72px ${SYS}`; g.textAlign = "right"; g.fillText(d.y, 640, 856);
  }, [i]);
  const body = useRBox(2.4, 3.2, 0.08, 0.12);
  return (
    <group position={pos} rotation={[0, rotY, 0]}>
      <mesh geometry={body}><meshStandardMaterial color="#e9e9ee" roughness={0.8} /></mesh>
      <mesh position={[0, 0, 0.045]}><planeGeometry args={[2.4, 3.2]} /><meshBasicMaterial map={tex} toneMapped={false} transparent opacity={1 - dim} /></mesh>
    </group>
  );
};
const M05: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const zOf = (i: number) => -i * 4.2;
  const xOf = (i: number) => (i % 2 ? 0.9 : -0.9);
  const moveAt = (i: number) => 1.0 + (i - 1) * 2.0;   // camera arrives at card i (i>=1) by moveAt(i)+0.8
  const look = (i: number): Cam => ({ pos: [xOf(i) * 0.8, 0.6, zOf(i) + 16], look: [xOf(i), 0.45, zOf(i)], fov: 34 });
  const moves: [number, number, Cam][] = [1, 2, 3, 4].map((i) => [moveAt(i), moveAt(i) + 0.9, look(i)]);
  moves.push([9.9, 11.6, { pos: [10, 3.5, 9], look: [0, 0.2, -8.5], fov: 34 }]);
  const cam = camPath(t, look(0), moves, 0.05);
  const best = r(t, 11.3, 11.8, POP);
  const [bx, by] = project(cam, W, H, [xOf(2), 1.75, zOf(2)]);
  const idx = Math.min(4, Math.max(0, [1, 2, 3, 4].filter((i) => t > moveAt(i) + 0.45).length));
  return (
    <AbsoluteFill style={{ background: "#141416" }}>
      <Stage w={W} h={H} cam={cam} amb={2.2}>
        {CARDS5.map((_, i) => {
          const facing = r(t, i === 0 ? -1 : moveAt(i) + 0.2, i === 0 ? 0 : moveAt(i) + 1.0);
          const away = i < 4 ? r(t, moveAt(i + 1), moveAt(i + 1) + 0.8) : 0;
          const end = r(t, 9.9, 11.0);
          const rot = lerp(lerp(-xOf(i) * 0.35, 0, facing), xOf(i) * 0.25, away);
          const slide = Math.sign(xOf(i)) * 5 * away * (1 - r(t, 10.7, 11.7, EASE));
          return <Card5 key={i} i={i} pos={[xOf(i) + slide, 0, zOf(i)]} rotY={lerp(rot, -0.45, end)} dim={i === 2 ? 0 : 0.35 * best} />;
        })}
      </Stage>
      <div style={{ position: "absolute", left: 80, top: 290, display: "flex", alignItems: "center", gap: 18 }}>
        <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 56, color: "#fff" }}>What your budget buys</div>
      </div>
      <div style={{ position: "absolute", left: 80, top: 370, display: "flex", gap: 10 }}>
        {CARDS5.map((d, i) => <div key={i} style={{ width: 56, height: 10, borderRadius: 5, background: i <= idx ? d.c : "rgba(255,255,255,0.18)" }} />)}
      </div>
      <Tag x={bx} y={by} k={best} bg={C.green} color={C.ink} size={44}>Best yield ✓</Tag>
      <DemoCaption text="Five budgets, five homes" from={0.6} to={9.6} y={1330} />
      <DemoCaption text="the sweet spot is in the middle" from={11.2} to={13} y={1330} />
      <Sounds list={[[0.2, "swish", 0.25], ...[1, 2, 3, 4].map((i) => [moveAt(i), "whoosh", 0.28] as [number, "whoosh", number]), [9.9, "riser", 0.2], [11.3, "ding", 0.35], [11.35, "pop", 0.3]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-06  exploded view: where your money goes (full screen, mint)
const LAYERS6 = [
  { n: "Land", p: 30, c: "#A2845E" },
  { n: "Construction", p: 35, c: "#8E8E93" },
  { n: "Finishes", p: 11, c: C.teal },
  { n: "Fees & permits", p: 4, c: C.indigo },
  { n: "Developer margin", p: 20, c: C.gold },
];
const M06: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const geo = useRBox(3, 1, 3, 0.03);
  const TOT = 4.4;
  const thick = LAYERS6.map((l) => (l.p / 100) * TOT);
  const ex = r(t, 3.6, 5.2, EASE_IO);
  const gap = 0.55 * ex;
  const ys: number[] = []; { let y = 0; thick.forEach((th, i) => { ys.push(y + i * gap); y += th; }); }
  const cam = camPath(t, { pos: [12, 10.5, 15], look: [0, 2.6, 0], fov: 32 }, [
    [3.6, 6.0, { pos: [26, 12, 9.5], look: [0, 3.4, -1.4], fov: 32 }],
    [9.0, 11.0, { pos: [25.5, 12.5, 9], look: [0, 3.5, -1.4], fov: 32 }],
  ], 0.05);
  const hl = r(t, 9.0, 9.6, POP);
  return (
    <AbsoluteFill style={{ background: "#DDF3E6" }}>
      <Stage w={W} h={H} cam={cam} shadows span={6}>
        <ShadowFloor opacity={0.12} />
        {LAYERS6.map((l, i) => {
          const land = r(t, 0.2 + i * 0.5, 0.75 + i * 0.5, EASE);
          if (land <= 0) return null;
          const lift = i === 4 ? hl * 0.5 : 0;
          return (
            <mesh key={i} geometry={geo} position={[0, ys[i] + thick[i] / 2 + (1 - land) * 3 + lift, 0]} scale={[1, thick[i], 1]} castShadow receiveShadow>
              <Mat c={i < 4 && hl > 0 ? mix(l.c, "#C9D4CD", hl * 0.55) : l.c} />
            </mesh>
          );
        })}
      </Stage>
      {LAYERS6.map((l, i) => {
        const k = r(t, 4.6 + i * 0.25, 5.1 + i * 0.25, EASE);
        const [x, y] = project(cam, W, H, [0, ys[i] + thick[i] / 2 + (i === 4 ? hl * 0.5 : 0), -1.55]);
        return (
          <div key={i} style={{ position: "absolute", left: x + 30, top: y, transform: `translate(${(1 - k) * 30}px, -50%)`, opacity: k * (i < 4 ? 1 - 0.45 * hl : 1), display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 40 * k, height: 3, background: C.ink, opacity: 0.5 }} />
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: i === 4 ? 46 + 10 * hl : 40, color: C.ink }}>{l.p}%</div>
            <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: "rgba(28,28,30,0.7)" }}>{l.n}</div>
          </div>
        );
      })}
      <div style={{ position: "absolute", left: 80, top: 290 }}>
        <Label color="rgba(28,28,30,0.55)" size={30}>AN AED 2M APARTMENT</Label>
        <div style={{ fontFamily: SERIF, fontSize: 84, color: C.ink, marginTop: 6 }}>what you pay for</div>
      </div>
      <InkCap text="Take the price apart" from={0.8} to={5.0} y={1330} />
      <InkCap text={<>One fifth is <span style={{ background: C.gold, padding: "0 12px", borderRadius: 12 }}>pure margin</span></>} from={9.2} to={12} y={1330} />
      <Sounds list={[...LAYERS6.map((_, i) => [0.6 + i * 0.5, "tick", 0.3] as [number, "tick", number]), [3.6, "whoosh", 0.3], ...LAYERS6.map((_, i) => [4.6 + i * 0.25, "pop", 0.2] as [number, "pop", number]),
        [9.0, "swish", 0.25], [9.1, "ding", 0.35]]} />
    </AbsoluteFill>
  );
};


const KeyMesh: React.FC<{ bow: THREE.BufferGeometry }> = ({ bow }) => (
  // key points into -z (into the lock); bow towards the viewer
  <group rotation={[Math.PI / 2, 0, 0]}>
    <mesh geometry={bow} position={[0, 0.82, 0]} rotation={[Math.PI / 2, 0, 0]}><Mat c={C.gold} rough={0.45} /></mesh>
    <mesh position={[0, 0.3, 0]}><boxGeometry args={[0.1, 0.8, 0.07]} /><Mat c={C.gold} rough={0.45} /></mesh>
    <mesh position={[0.09, 0.06, 0]}><boxGeometry args={[0.1, 0.1, 0.07]} /><Mat c={C.gold} rough={0.45} /></mesh>
    <mesh position={[0.08, 0.24, 0]}><boxGeometry args={[0.08, 0.08, 0.07]} /><Mat c={C.gold} rough={0.45} /></mesh>
  </group>
);

// ================================================================ m2-09  blocks filling a plot = units selling out (over video, fitted plate)
const PIECES = [
  { cells: [[0, 0], [1, 0], [2, 0], [3, 0]], c: C.blue },
  { cells: [[4, 0], [5, 0], [4, 1], [5, 1]], c: C.orange },
  { cells: [[6, 0], [7, 0], [7, 1], [7, 2]], c: C.green },
  { cells: [[0, 1], [0, 2], [0, 3], [1, 3]], c: C.purple },
  { cells: [[1, 1], [2, 1], [3, 1], [2, 2]], c: C.pink },
  { cells: [[6, 1], [6, 2], [5, 2], [5, 3]], c: C.teal },
  { cells: [[3, 2], [4, 2], [4, 3]], c: C.gold },
  { cells: [[2, 3], [3, 3]], c: C.indigo },
  { cells: [[6, 3], [7, 3]], c: C.red },
  { cells: [[1, 2]], c: C.blue },
];

// ================================================================ m2-10  stairs growing, a ball hops up each step (full screen, orange)
const STEPS10 = ["Save", "Deposit", "Mortgage", "Keys", "Rent out"];
const M10: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const pillar = usePillar(1.3, 2.0, 0.07);
  const riseAt = (i: number) => 0.05 + i * 1.6;
  const SX = 1.3, SH = 0.75;
  const ball = useMemo(() => new THREE.SphereGeometry(0.32, 40, 28), []);
  // the ball hops onto step i shortly after it has risen
  const hopAt = (i: number) => riseAt(i) + 0.75;
  let bx = -SX * 1.2, by = 0.32, cur = -1;
  for (let i = 0; i < 5; i++) {
    const k = r(t, hopAt(i), hopAt(i) + 0.55, EASE_IO);
    if (k > 0) {
      const fx = i === 0 ? -SX * 1.2 : (i - 1 - 2) * SX, fy = i === 0 ? 0.32 : i * SH + 0.32;
      const tx = (i - 2) * SX, ty = (i + 1) * SH + 0.32;
      bx = lerp(fx, tx, k); by = lerp(fy, ty, k) + Math.sin(k * Math.PI) * 0.9; cur = k > 0.9 ? i : cur;
    }
  }
  const squash = (() => { let s = 0; for (let i = 0; i < 5; i++) s = Math.max(s, Math.sin(r(t, hopAt(i) + 0.5, hopAt(i) + 0.75) * Math.PI)); return s; })();
  const cam = camPath(t, { pos: [-4, 6, 21], look: [-2.2, 0.6, 0], fov: 32 }, [
    [0.5, 8.6, { pos: [5.5, 8.5, 23], look: [0.6, 1.4, 0], fov: 32 }],
    [9.0, 11.5, { pos: [3.5, 8, 24.5], look: [0.4, 1.3, 0], fov: 32 }],
  ], 0.05);
  const keyK = r(t, hopAt(4) + 0.6, hopAt(4) + 1.1, POP);
  return (
    <AbsoluteFill style={{ background: "#FF9F0A" }}>
      <Stage w={W} h={H} cam={cam} shadows span={8}>
        <ShadowFloor opacity={0.18} />
        {STEPS10.map((_, i) => {
          const k = r(t, riseAt(i), riseAt(i) + 0.7, EASE);
          if (k <= 0.001) return null;
          return <mesh key={i} geometry={pillar} position={[(i - 2) * SX, 0, 0]} scale={[1, (i + 1) * SH * k, 1]} castShadow receiveShadow><Mat c={i === 4 ? "#FFFFFF" : "#FFF4E2"} /></mesh>;
        })}
        <mesh geometry={ball} position={[bx, by, 0.2]} scale={[1 + squash * 0.18, 1 - squash * 0.2, 1 + squash * 0.18]} castShadow><Mat c={C.ink} rough={0.6} /></mesh>
      </Stage>
      {STEPS10.map((n, i) => {
        const k = r(t, riseAt(i) + 0.3, riseAt(i) + 0.8, EASE);
        const [x, y] = project(cam, W, H, [(i - 2) * SX, (i + 1) * SH * 0.5, 1.02]);
        const on = cur >= i;
        return (
          <div key={i} style={{ position: "absolute", left: x, top: y, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * k})`, opacity: k, textAlign: "center" }}>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 28, color: "rgba(28,28,30,0.55)" }}>0{i + 1}</div>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 34, color: on ? C.ink : "rgba(28,28,30,0.6)", whiteSpace: "nowrap" }}>{n}</div>
          </div>
        );
      })}
      {(() => { const [x, y] = project(cam, W, H, [2 * SX, 5 * SH + 0.9, 0.2]); return <Tag x={Math.min(x, 760)} y={y} k={keyK} bg={C.ink} color="#fff" size={40}>🔑 Passive income</Tag>; })()}
      <div style={{ position: "absolute", left: 80, top: 290 }}>
        <Label color="rgba(28,28,30,0.6)" size={30}>THE LADDER</Label>
        <div style={{ fontFamily: SERIF, fontSize: 92, color: C.ink, lineHeight: 1 }}>one step at a time</div>
      </div>
      <InkCap text="Nobody jumps straight to the top" from={0.6} to={7.0} y={1330} />
      <InkCap text="Five steps to your first rent cheque" from={7.6} to={12.5} y={1330} />
      <Sounds list={[...STEPS10.map((_, i) => [riseAt(i), "swish", 0.2] as [number, "swish", number]), ...STEPS10.map((_, i) => [hopAt(i) + 0.5, "pop", 0.32] as [number, "pop", number]),
        [hopAt(4) + 0.6, "ding", 0.35], [9.0, "whoosh", 0.2]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-11  pins drop on a grid, a route connects them (over video, light plate)
const PINS11: [number, number][] = [[-2.6, 0.6], [-0.9, -0.7], [0.8, 0.5], [2.6, -0.5]];
const M11: React.FC = () => {
  const t = useT();
  const PW = 900, PH = 400;
  const head = useMemo(() => new THREE.SphereGeometry(0.26, 32, 24), []);
  const cone = useMemo(() => { const g = new THREE.ConeGeometry(0.16, 0.5, 32); g.rotateX(Math.PI); return g; }, []);
  const dropAt = (i: number) => 0.6 + i * 1.5;
  const routeK = r(t, 6.8, 8.6, EASE_IO);
  const cam = camPath(t, { pos: [0, 4.5, 5.4], look: [0, 0.1, 0], fov: 34 }, [
    [0.5, 9, { pos: [-0.7, 3.9, 5.8], look: [0, 0.2, 0], fov: 34 }],
  ], 0.04);
  // route: straight legs between the pins, revealed by length
  const legs = PINS11.slice(1).map((p, i) => [PINS11[i], p] as const);
  const total = legs.reduce((a, [p, q]) => a + Math.hypot(q[0] - p[0], q[1] - p[1]), 0);
  let left = total * routeK;
  const ROUTE_COLORS = C.blue;
  return (
    <AbsoluteFill>
      <Backdrop />
      <Plate x={540} y={240} w={PW} h={PH} k={r(t, 0, 0.4)} dark={false}>
        <div style={{ position: "absolute", left: 36, top: 26, right: 36, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Label color="rgba(28,28,30,0.55)" size={30}>SATURDAY · VIEWINGS</Label>
          <div style={{ display: "flex", alignItems: "baseline", gap: 6, color: C.ink }}>
            <Odo value={PINS11.reduce((n, _, i) => n + r(t, dropAt(i) + 0.3, dropAt(i) + 0.6), 0)} size={52} color={C.ink} />
            <span style={{ fontFamily: UI, fontWeight: 800, fontSize: 34 }}>homes</span>
          </div>
        </div>
        <Stage w={PW} h={PH - 80} y={80} cam={cam} amb={2.4} lightKey={[3, 8, 6]}>
          <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]}><planeGeometry args={[8, 3.4]} /><Mat c="#ECE8DF" /></mesh>
          {Array.from({ length: 9 }, (_, i) => <mesh key={`v${i}`} position={[-4 + i, 0, 0]} rotation={[-Math.PI / 2, 0, 0]}><planeGeometry args={[0.025, 3.4]} /><Mat c="#D6D0C4" /></mesh>)}
          {Array.from({ length: 4 }, (_, i) => <mesh key={`h${i}`} position={[0, 0.001, -1.5 + i]} rotation={[-Math.PI / 2, 0, 0]}><planeGeometry args={[8, 0.025]} /><Mat c="#D6D0C4" /></mesh>)}
          {legs.map(([p, q], i) => {
            const len = Math.hypot(q[0] - p[0], q[1] - p[1]);
            const k = clamp(left / len); left -= len;
            if (k <= 0) return null;
            const ang = Math.atan2(q[1] - p[1], q[0] - p[0]);
            const L = len * k;
            return (
              <mesh key={i} position={[p[0] + Math.cos(ang) * L / 2, 0.02, p[1] + Math.sin(ang) * L / 2]} rotation={[-Math.PI / 2, 0, ang]}>
                <planeGeometry args={[L, 0.09]} /><meshBasicMaterial color={ROUTE_COLORS} toneMapped={false} />
              </mesh>
            );
          })}
          {PINS11.map(([x, z], i) => {
            const a = dropAt(i);
            const k = r(t, a, a + 0.4, EASE_IN);
            if (k <= 0) return null;
            const b = Math.sin(r(t, a + 0.4, a + 0.75) * Math.PI) * 0.18;
            const col = [C.red, C.orange, C.purple, C.green][i];
            return (
              <group key={i} position={[x, 0.25 + (1 - k) * 4 + b, z]}>
                <mesh geometry={cone} position={[0, 0.0, 0]}><Mat c={col} /></mesh>
                <mesh geometry={head} position={[0, 0.38, 0]}><Mat c={col} /></mesh>
                <mesh position={[0, -0.24, 0]} rotation={[-Math.PI / 2, 0, 0]} scale={k}><circleGeometry args={[0.16, 24]} /><meshBasicMaterial color="#000" transparent opacity={0.12} /></mesh>
              </group>
            );
          })}
        </Stage>
        {PINS11.map(([x, z], i) => {
          const k = r(t, dropAt(i) + 0.45, dropAt(i) + 0.8, POP);
          const [px, py] = project(cam, PW, PH - 80, [x, 1.0, z]);
          return <Tag key={i} x={px} y={py + 80} k={k} bg={C.ink} color="#fff" size={28}>{["1 BR", "Studio", "2 BR", "Villa"][i]}</Tag>;
        })}
      </Plate>
      <DemoCaption text={t < 6.8 ? "Four viewings in one afternoon" : "if you plan the route right"} from={0.6} to={12} />
      <Sounds list={[[0.1, "swish", 0.22], ...PINS11.map((_, i) => [dropAt(i) + 0.38, "pop", 0.35] as [number, "pop", number]), [6.8, "whoosh", 0.25], ...[7.3, 7.9, 8.5].map((x) => [x, "tick", 0.25] as [number, "tick", number]), [8.7, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-12  3D pie, one slice lifts out (full screen indigo + Max in a bubble)
const PIE12 = [
  { n: "Mortgage", p: 55, c: "#8E8CF5" },
  { n: "Service charge", p: 12, c: C.teal },
  { n: "Upkeep", p: 8, c: "#FFFFFF" },
  { n: "Your profit", p: 25, c: C.gold },
];
const M12: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const R = 2.4;
  const geos = useMemo(() => {
    let a = Math.PI / 2;
    return PIE12.map((s) => {
      const len = (s.p / 100) * Math.PI * 2;
      const g = new THREE.CylinderGeometry(R, R, 0.7, 64, 1, false, a, len);
      const mid = a + len / 2; a += len;
      return { g, mid };
    });
  }, []);
  const lift = r(t, 6.0, 7.2, EASE_IO);
  const cam = camPath(t, { pos: [0, 16, 0.01], look: [0, 0, 0], fov: 34 }, [
    [3.2, 5.6, { pos: [0, 9, 11.5], look: [0, 0.2, 0], fov: 34 }],
    [6.0, 8.0, { pos: [2.5, 8, 11.5], look: [0.8, 0.6, 0], fov: 34 }],
  ], 0.04);
  const W0 = 1080, H0 = 1100;
  return (
    <AbsoluteFill style={{ background: "#2A2873" }}>
      <Stage w={W0} h={H0} y={300} cam={cam} amb={2.2} lightKey={[4, 10, 6]}>
        {PIE12.map((s, i) => {
          const k = r(t, -0.2 + i * 0.6, 0.5 + i * 0.6, EASE);
          if (k <= 0) return null;
          const mid = geos[i].mid;
          const out = i === 3 ? lift : 0;
          // cylinder theta 0 is +z; position offset along the slice's mid direction
          const dx = Math.sin(mid) * out * 1.2, dz = Math.cos(mid) * out * 1.2;
          return (
            <mesh key={i} geometry={geos[i].g} position={[dx, 0.35 + out * 0.9, dz]} scale={[k, 1, k]}>
              <Mat c={i < 3 && lift > 0 ? mix(s.c, "#2A2873", lift * 0.35) : s.c} />
            </mesh>
          );
        })}
      </Stage>
      <div style={{ position: "absolute", left: 80, top: 290 }}>
        <Label size={30}>AED 10,000 RENT A MONTH</Label>
        <div style={{ fontFamily: SERIF, fontSize: 88, color: "#fff", lineHeight: 1.05 }}>where it goes</div>
      </div>
      <div style={{ position: "absolute", left: 470, top: 1120, display: "flex", flexDirection: "column", gap: 12 }}>
        {PIE12.map((s, i) => {
          const k = r(t, 0.0 + i * 0.6, 0.4 + i * 0.6);
          const hi = i === 3 ? lift : 0;
          return (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 14, opacity: k * (i < 3 ? 1 - 0.45 * lift : 1), transform: `translateX(${(1 - k) * 20}px) scale(${1 + hi * 0.12})`, transformOrigin: "0 50%" }}>
              <div style={{ width: 26, height: 26, borderRadius: 8, background: s.c }} />
              <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 38, color: "#fff", width: 90 }}>{s.p}%</div>
              <div style={{ fontFamily: UI, fontWeight: 700, fontSize: 34, color: "rgba(255,255,255,0.8)" }}>{s.n}</div>
            </div>
          );
        })}
      </div>
      <FaceBubble x={250} y={1230} d={300} k={r(t, 0.2, 0.7, POP)} />
      {(() => {
        const g = geos[3];
        const [x, y] = project(cam, W0, H0, [Math.sin(g.mid) * (R * 0.6 + 1.2), 1.9, Math.cos(g.mid) * (R * 0.6 + 1.2)]);
        return <Tag x={x} y={y + 300} k={r(t, 7.0, 7.5, POP)} bg={C.gold} color={C.ink} size={44}>AED 2,500 / mo</Tag>;
      })()}
      <Sounds list={[...PIE12.map((_, i) => [0.4 + i * 0.6, "tick", 0.3] as [number, "tick", number]), [0.2, "pop", 0.25], [3.2, "whoosh", 0.25], [6.0, "swish", 0.3], [7.0, "ding", 0.35]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-13  scattered buyers cluster into three groups (full screen, white)
const GROUPS13 = [
  { n: "Investors", p: 45, c: C.blue, at: [-2.0, 0, 0.5] as V3 },
  { n: "Living in it", p: 35, c: C.green, at: [1.9, 0, -1.5] as V3 },
  { n: "Holiday homes", p: 20, c: C.pink, at: [1.9, 0, 2.1] as V3 },
];
const M13: React.FC = () => {
  const t = useT();
  const W = 1080, H = 1920;
  const N = 60;
  const sph = useMemo(() => new THREE.SphereGeometry(0.2, 24, 16), []);
  const dots = useMemo(() => Array.from({ length: N }, (_, i) => {
    const g = i < 27 ? 0 : i < 48 ? 1 : 2;
    const j = g === 0 ? i : g === 1 ? i - 27 : i - 48;
    // phyllotaxis pack inside each cluster
    const a = j * 2.39996, rr = 0.26 * Math.sqrt(j + 0.5) * 1.18;
    const tgt: V3 = [GROUPS13[g].at[0] + Math.cos(a) * rr, 0.2 + (j % 3 === 0 ? 0 : 0), GROUPS13[g].at[2] + Math.sin(a) * rr];
    const start: V3 = [(rand(i) - 0.5) * 7.5, 0.2, (rand(i + 99) - 0.5) * 7.5];
    return { g, tgt, start, d: rand(i + 7) * 0.8 };
  }), []);
  const appear = (i: number) => 0.1 + rand(i + 3) * 1.2;
  const sort = r(t, 3.2, 3.6);   // colour reveal
  const cam = camPath(t, { pos: [0, 22, 15], look: [0, 0, -0.4], fov: 32 }, [
    [3.2, 7.0, { pos: [2.5, 20, 15], look: [0, 0, -0.2], fov: 32 }],
    [9.5, 12, { pos: [3, 19, 14.5], look: [0, 0, -0.1], fov: 32 }],
  ], 0.04);
  return (
    <AbsoluteFill style={{ background: "#F7F7F9" }}>
      <Stage w={W} h={H} cam={cam} shadows span={7}>
        <ShadowFloor opacity={0.12} />
        {dots.map((d, i) => {
          const a = r(t, appear(i), appear(i) + 0.4, POP);
          if (a <= 0) return null;
          const m = r(t, 4.2 + d.d, 6.4 + d.d, EASE_IO);
          const p = mixV(d.start, d.tgt, m);
          const hop = Math.sin(m * Math.PI) * 0.6;
          const col = mix("#C7C7CC", GROUPS13[d.g].c, r(t, 3.2 + d.d * 0.5, 3.6 + d.d * 0.5));
          return <mesh key={i} geometry={sph} position={[p[0], p[1] + hop, p[2]]} scale={a} castShadow><Mat c={col} rough={0.7} /></mesh>;
        })}
      </Stage>
      {GROUPS13.map((g, i) => {
        const k = r(t, 7.0 + i * 0.35, 7.5 + i * 0.35, POP);
        const R = 0.26 * Math.sqrt([27, 21, 12][i]) * 1.18;
        const [x, y] = project(cam, W, H, [g.at[0], 0.4, g.at[2] - R - 0.1]);
        return (
          <div key={i} style={{ position: "absolute", left: x, top: y, transform: `translate(-50%,-100%) scale(${0.6 + 0.4 * k})`, transformOrigin: "50% 100%", opacity: clamp(k * 1.5), textAlign: "center" }}>
            <div style={{ fontFamily: UI, fontWeight: 900, fontSize: 64, color: g.c, lineHeight: 1 }}>{Math.round(lerp(0, g.p, r(t, 7.0 + i * 0.35, 8.0 + i * 0.35)))}%</div>
            <div style={{ fontFamily: UI, fontWeight: 800, fontSize: 32, color: C.ink, whiteSpace: "nowrap" }}>{g.n}</div>
          </div>
        );
      })}
      <div style={{ position: "absolute", left: 80, top: 290 }}>
        <Label color="rgba(28,28,30,0.55)" size={30}>WHO BUYS HERE</Label>
        <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
          <Odo value={lerp(0, 60, r(t, 0.1, 1.6))} size={96} color={C.ink} />
          <span style={{ fontFamily: SERIF, fontSize: 64, color: C.ink }}>buyers</span>
        </div>
      </div>
      <InkCap text="Sixty buyers look the same" from={0.8} to={3.9} y={1330} />
      <InkCap text="until you sort them" from={4.2} to={6.8} y={1330} />
      <InkCap text={<>Know <span style={{ color: C.blue }}>who</span> you're selling to</>} from={9.4} to={12.5} y={1330} />
      <Sounds list={[[0.1, "pop", 0.2], [0.5, "pop", 0.18], [0.9, "pop", 0.18], [3.2, "swish", 0.25], [4.2, "whoosh", 0.3], [6.4, "impact", 0.2],
        [7.0, "tick", 0.3], [7.35, "tick", 0.3], [7.7, "tick", 0.3], [8.1, "ding", 0.3]]} />
    </AbsoluteFill>
  );
};

// ================================================================ m2-14  cubes spell RENT, then rebuild into OWN (over video, plate)
const PIX: Record<string, string[]> = {
  R: ["1110", "1001", "1001", "1110", "1010", "1001", "1001"],
  E: ["1111", "1000", "1000", "1110", "1000", "1000", "1111"],
  N: ["1001", "1101", "1101", "1011", "1011", "1001", "1001"],
  T: ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
  O: ["0110", "1001", "1001", "1001", "1001", "1001", "0110"],
  W: ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
};
const cellsOf = (word: string) => {
  const out: [number, number][] = [];
  let x = 0;
  for (const ch of word) {
    const g = PIX[ch];
    g.forEach((row, y) => row.split("").forEach((b, cx) => { if (b === "1") out.push([x + cx, 6 - y]); }));
    x += g[0].length + 1;
  }
  const w = x - 1;
  return out.map(([cx, cy]) => [cx - (w - 1) / 2, cy] as [number, number]);
};

// ================================================================ m2-15  dominoes: one rate cut knocks over the market (over video, plate)
const DOM15 = ["Rate cut", "Buyers", "Prices", "Rents", "Yields"];


// ================================================================ m2-17  balance scale: years of rent vs owning (full screen, blush + Max bubble)
const Pan17: React.FC<{ p: V3; children?: React.ReactNode }> = ({ p, children }) => (
  <group position={[p[0], p[1] - 1.1, p[2]]}>
    <mesh position={[0, 0.55, 0]}><cylinderGeometry args={[0.02, 0.02, 1.1, 8]} /><Mat c="#8E8E93" /></mesh>
    <mesh><cylinderGeometry args={[1.0, 0.85, 0.12, 48]} /><Mat c="#FFFFFF" /></mesh>
    <group position={[0, 0.06, 0]}>{children}</group>
  </group>
);



// ================================================================ m2-20  a 3D ribbon line chart drawn with the camera riding the tip (full screen, graphite)
const PTS20: [number, number][] = [[0, 0.6], [1, 0.9], [2, 0.75], [3, 1.3], [4, 1.2], [5, 1.9], [6, 2.4], [7, 2.2], [8, 3.1], [9, 3.6]];

export const M2: LibItem[] = [
  { id: "m2-01", title: "Price bars rising", family: FAM, dur: 12, C: M01,
    note: "Five extruded bars rise year by year with counting values, camera dollies along and settles; +78% hero. For price-growth lines." },
  { id: "m2-02", title: "Floors stacking", family: FAM, dur: 12, C: M02,
    note: "Split screen: a tower builds floor by floor with a floor counter, camera tilts up to a gold penthouse. For off-plan / construction progress." },
  { id: "m2-03", title: "District rising", family: FAM, dur: 12, C: M03,
    note: "A generic district grows out of the ground in a wave from the centre, then one tower turns orange: 'buy here'. For area-growth stories." },
  { id: "m2-04", title: "Rent coins piling", family: FAM, dur: 12, C: M04,
    note: "Fitted plate above Max's head: coins drop into five yearly stacks while an AED counter adds up, ends on a yield chip. For ROI / rental-income lines." },
  { id: "m2-05", title: "Listing cards dolly", family: FAM, dur: 13, C: M05,
    note: "Five listing cards stand in depth; the camera dollies card to card, then pulls back to reveal the row and flags the best yield. For 'what your budget buys'." },
  { id: "m2-06", title: "Exploded price layers", family: FAM, dur: 12, C: M06,
    note: "A price block lands slab by slab, then explodes apart into labelled layers (land, build, fees, margin); the margin slab lifts. For 'where your money goes'." },
  { id: "m2-10", title: "Stairs + hopping ball", family: FAM, dur: 13, C: M10,
    note: "Orange scene: five steps rise one by one (Save, Deposit, Mortgage, Keys, Rent out) and a ball hops up each; camera climbs with it. For step-by-step journeys." },
  { id: "m2-11", title: "Pins on a grid + route", family: FAM, dur: 11, C: M11,
    note: "Light plate above Max: four map-less pins drop onto a grid with a counter, then a blue route draws between them. For viewings / area-tour lines." },
  { id: "m2-12", title: "3D pie, slice lifts", family: FAM, dur: 11, C: M12,
    note: "Indigo scene with Max in a bubble: a rent pie builds slice by slice from top view, camera tilts to 3/4 and the profit slice lifts out. For cash-flow breakdowns." },
  { id: "m2-13", title: "Buyers clustering", family: FAM, dur: 13, C: M13,
    note: "60 grey spheres scatter, take on colours, then roll into three clusters with % labels. For 'who buys here' / audience segments." },
];
