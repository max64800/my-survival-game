import React, { useMemo } from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { ThreeCanvas } from "@remotion/three";
import { useThree } from "@react-three/fiber";
import * as THREE from "three";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";
import { Big } from "./OverlayV2";

// Real-3D overlay: objects modelled in code, lit by a soft studio environment, animated with
// eased motion. Two layers like v2: "behind" (composited under the person matte) and "front".
// Screen mapping: camera fov 30 at z=10 -> 358 px per world unit on the z=0 plane.
const PX = 358.3;
const wx = (x: number) => (x - 540) / PX;
const wy = (y: number) => (960 - y) / PX;
const EASE = Easing.bezier(0.22, 1, 0.36, 1);
const EASE_IN = Easing.bezier(0.55, 0, 1, 0.45);
const YELLOW = "#FFD600";
const INK = "#141414";

type Base = { from: number; to: number; layer?: "behind" | "front" };
export type E3 =
  | (Base & { type: "big"; text: string; accent?: string; y?: number; size?: number })
  | (Base & { type: "wineCheese"; y: number; x?: number })
  | (Base & { type: "flag"; x: number; y: number })
  | (Base & { type: "apple"; x: number; y: number })
  | (Base & { type: "plane"; y: number })
  | (Base & { type: "sign"; x: number; y: number; flipAt: number })
  | (Base & { type: "pie"; x: number; y: number })
  | (Base & { type: "label"; x: number; y: number; text: string; accent?: boolean })
  | (Base & { type: "sticker"; art: string; x: number; y: number; size: number; rot: number; mode?: "slap" | "fly" | "swing"; dir?: number; text?: string })
  | (Base & { type: "card"; lines: { text: string; at: number; size?: number; accent?: boolean }[] })
  | (Base & { type: "cards"; x: number; y: number; cards: { title: string; sub: string; at: number }[]; pile?: { at: number; count: number } })
  | (Base & { type: "coins"; x: number; y: number; count: number; buildAt: number; halveAt: number })
  | (Base & { type: "bus"; y: number });
export type StickerEl = { art: string; x: number; y: number; size: number; rot: number; mode?: "slap" | "fly" | "swing"; dir?: number; text?: string };
export type P3 = { duration: number; layer: "behind" | "front"; elements: E3[] };

const useT = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return frame / fps;
};
const ease = (t: number, a: number, b: number, e = EASE) =>
  interpolate(t, [a, b], [0, 1], { easing: e, extrapolateLeft: "clamp", extrapolateRight: "clamp" });

// soft studio lighting so metal and glass have something to reflect
const Studio: React.FC = () => {
  const { gl, scene } = useThree();
  useMemo(() => {
    const pmrem = new THREE.PMREMGenerator(gl);
    scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
  }, [gl, scene]);
  return (
    <>
      <ambientLight intensity={0.25} />
      <directionalLight position={[-3, 5, 6]} intensity={1.7} />
      <directionalLight position={[4, -2, -3]} intensity={0.8} color="#ffe9b0" />
    </>
  );
};

// ---------- licence cards ----------
const cardTexture = (title: string, sub: string) => {
  const c = document.createElement("canvas");
  c.width = 640; c.height = 420;
  const g = c.getContext("2d")!;
  const r = 36;
  g.fillStyle = "#FFFFFF";
  g.beginPath(); g.roundRect(0, 0, 640, 420, r); g.fill();
  g.fillStyle = YELLOW; g.beginPath(); g.roundRect(0, 0, 640, 110, [r, r, 0, 0]); g.fill();
  g.fillStyle = INK; g.font = "800 46px Helvetica, Arial"; g.fillText("UK  ·  LICENCE", 36, 72);
  g.font = "900 82px Helvetica, Arial"; g.fillText(title, 36, 230);
  g.fillStyle = "#555"; g.font = "700 40px Helvetica, Arial"; g.fillText(sub, 36, 300);
  // red "APPROVED?" stamp
  g.save(); g.translate(500, 330); g.rotate(-0.25);
  g.strokeStyle = "#D32F2F"; g.lineWidth = 8; g.beginPath(); g.arc(0, 0, 70, 0, Math.PI * 2); g.stroke();
  g.fillStyle = "#D32F2F"; g.font = "900 30px Helvetica, Arial"; g.textAlign = "center"; g.fillText("PAID", 0, 11);
  g.restore();
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  return tex;
};

const Card: React.FC<{ title: string; sub: string; at: number; to: number; rest: [number, number, number]; rot: number; small?: boolean }> = (p) => {
  const t = useT();
  const tex = useMemo(() => cardTexture(p.title, p.sub), [p.title, p.sub]);
  const mats = useMemo(() => {
    const side = new THREE.MeshStandardMaterial({ color: "#f2f2f2", roughness: 0.6 });
    const face = new THREE.MeshBasicMaterial({ map: tex, toneMapped: false });   // printed face stays crisp
    return [side, side, side, side, face, side];
  }, [tex]);
  if (t < p.at || t > p.to) return null;
  const k = ease(t, p.at, p.at + 0.55);
  const out = ease(t, p.to - 0.35, p.to, EASE_IN);
  const [rx, ry, rz] = p.rest;
  const pos: [number, number, number] = [rx + (1 - k) * 1.2, ry + (1 - k) * 0.9 - out * 2.5, rz + (1 - k) * 5];
  const s = p.small ? 0.6 : 1;
  return (
    <mesh position={pos} rotation={[(1 - k) * -1.2 + 0.12, (1 - k) * 2.2 - 0.18, p.rot + (1 - k) * 0.8 + out * 0.6]} scale={[s, s, s]}>
      <boxGeometry args={[0.95, 0.62, 0.025]} />
      {mats.map((m, i) => <primitive key={i} object={m} attach={`material-${i}`} />)}
    </mesh>
  );
};

const Cards: React.FC<{ e: Extract<E3, { type: "cards" }> }> = ({ e }) => {
  const x = wx(e.x), y = wy(e.y);
  const extra = e.pile ? Array.from({ length: e.pile.count }, (_, i) => i) : [];
  return (
    <group>
      {e.cards.map((c, i) => (
        <Card key={i} title={c.title} sub={c.sub} at={c.at} to={e.to}
          rest={[x - i * 0.05, y - i * 0.09, i * 0.04]} rot={(i % 2 ? 1 : -1) * 0.07} />
      ))}
      {e.pile && extra.map((i) => (
        <Card key={`p${i}`} title="+1 MORE" sub="Another form" at={e.pile!.at + i * 0.07} to={e.to} small
          rest={[x + Math.sin(i * 2.1) * 0.55, y + 0.25 + Math.cos(i * 1.3) * 0.2, -0.6 - i * 0.03]} rot={Math.sin(i * 1.7) * 0.6} />
      ))}
    </group>
  );
};

// ---------- wine bottle + cheese wedge (simple, side by side) ----------
const WineCheese: React.FC<{ e: Extract<E3, { type: "wineCheese" }> }> = ({ e }) => {
  const t = useT();
  const wedge = useMemo(() => {
    const s = new THREE.Shape(); s.moveTo(0, 0); s.lineTo(0.62, 0); s.lineTo(0, 0.36); s.lineTo(0, 0);
    return new THREE.ExtrudeGeometry(s, { depth: 0.34, bevelEnabled: true, bevelSize: 0.015, bevelThickness: 0.015, bevelSegments: 2 });
  }, []);
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.6);
  const out = ease(t, e.to - 0.3, e.to, EASE_IN);
  const s = 0.8 * k * (1 - out);
  const sway = Math.sin((t - e.from) * 2.2) * 0.08;
  const x = wx(e.x ?? 250), y = wy(e.y) + (1 - k) * -0.8;
  return (
    <group position={[x, y, 0.5]} scale={s} rotation={[0.12, 0.15 + sway, 0]}>
      {/* bottle: two clean cylinders + cap, one matte wine colour */}
      <mesh position={[0.3, 0.32, 0]}><cylinderGeometry args={[0.15, 0.15, 0.64, 48]} /><meshStandardMaterial color="#6B1426" roughness={0.35} /></mesh>
      <mesh position={[0.3, 0.7, 0]}><cylinderGeometry args={[0.05, 0.12, 0.14, 48]} /><meshStandardMaterial color="#6B1426" roughness={0.35} /></mesh>
      <mesh position={[0.3, 0.87, 0]}><cylinderGeometry args={[0.05, 0.05, 0.22, 32]} /><meshStandardMaterial color="#6B1426" roughness={0.35} /></mesh>
      <mesh position={[0.3, 1.0, 0]}><cylinderGeometry args={[0.058, 0.058, 0.07, 32]} /><meshStandardMaterial color={YELLOW} roughness={0.4} /></mesh>
      {/* cheese: one wedge, two holes */}
      <group position={[-0.62, 0, 0.05]} rotation={[0, -0.25, 0]}>
        <mesh geometry={wedge}><meshStandardMaterial color="#F7C948" roughness={0.6} /></mesh>
        {[[0.14, 0.09, 0.05], [0.3, 0.07, 0.035]].map(([hx, hy, r], i) => (
          <mesh key={i} position={[hx, hy, 0.36]} scale={[1, 1, 0.2]}><sphereGeometry args={[r, 24, 24]} /><meshStandardMaterial color="#E0A92C" roughness={0.7} /></mesh>
        ))}
      </group>
    </group>
  );
};

// ---------- waving UK flag ----------
const flagTexture = () => {
  const c = document.createElement("canvas"); c.width = 600; c.height = 300;
  const g = c.getContext("2d")!;
  g.fillStyle = "#012169"; g.fillRect(0, 0, 600, 300);
  const diag = (w: number, col: string) => { g.strokeStyle = col; g.lineWidth = w; g.beginPath(); g.moveTo(0, 0); g.lineTo(600, 300); g.moveTo(600, 0); g.lineTo(0, 300); g.stroke(); };
  diag(60, "#FFFFFF"); diag(20, "#C8102E");
  g.fillStyle = "#FFFFFF"; g.fillRect(250, 0, 100, 300); g.fillRect(0, 100, 600, 100);
  g.fillStyle = "#C8102E"; g.fillRect(270, 0, 60, 300); g.fillRect(0, 120, 600, 60);
  const tx = new THREE.CanvasTexture(c); tx.colorSpace = THREE.SRGBColorSpace; return tx;
};
const Flag: React.FC<{ e: Extract<E3, { type: "flag" }> }> = ({ e }) => {
  const t = useT();
  const tex = useMemo(flagTexture, []);
  const geo = useMemo(() => new THREE.PlaneGeometry(1.2, 0.6, 40, 20), []);
  if (t < e.from || t > e.to) return null;
  const pos = geo.attributes.position as THREE.BufferAttribute;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    pos.setZ(i, Math.sin(x * 5 - t * 7) * 0.05 * (x + 0.6));
  }
  pos.needsUpdate = true; geo.computeVertexNormals();
  const k = ease(t, e.from, e.from + 0.5);
  const out = ease(t, e.to - 0.3, e.to, EASE_IN);
  return (
    <group position={[wx(e.x), wy(e.y) + (1 - k) * 0.6, 0.5]} rotation={[0, -0.35, 0.05]} scale={k * (1 - out)}>
      <mesh position={[-0.62, -0.35, 0]}><cylinderGeometry args={[0.018, 0.018, 1.3, 16]} /><meshStandardMaterial color="#d9d9d9" metalness={0.8} roughness={0.3} /></mesh>
      <mesh geometry={geo} position={[0, 0, 0]}><meshStandardMaterial map={tex} side={THREE.DoubleSide} roughness={0.8} /></mesh>
    </group>
  );
};

// ---------- red apple for the teacher ----------
const Apple: React.FC<{ e: Extract<E3, { type: "apple" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.5);
  const out = ease(t, e.to - 0.3, e.to, EASE_IN);
  const spin = (t - e.from) * 1.2;
  return (
    <group position={[wx(e.x), wy(e.y) + (1 - k) * -0.8, 0.6]} rotation={[0.2, spin, 0]} scale={0.9 * k * (1 - out)}>
      <mesh scale={[1, 0.9, 1]}><sphereGeometry args={[0.28, 48, 48]} /><meshPhysicalMaterial color="#C62828" roughness={0.25} clearcoat={0.8} /></mesh>
      <mesh position={[0, 0.3, 0]} rotation={[0, 0, 0.2]}><cylinderGeometry args={[0.018, 0.022, 0.14, 12]} /><meshStandardMaterial color="#5D3A1A" /></mesh>
      <mesh position={[0.09, 0.32, 0]} rotation={[0, 0, -0.7]} scale={[1, 0.45, 0.15]}><sphereGeometry args={[0.1, 24, 24]} /><meshStandardMaterial color="#43A047" roughness={0.5} /></mesh>
    </group>
  );
};

// ---------- paper plane flying across ----------
const Plane: React.FC<{ e: Extract<E3, { type: "plane" }> }> = ({ e }) => {
  const t = useT();
  const geo = useMemo(() => {
    const g = new THREE.BufferGeometry();
    // two wings + keel of a classic paper plane, nose at +x
    const v = new Float32Array([0.5, 0, 0, -0.5, 0, 0.32, -0.5, 0.02, 0, 0.5, 0, 0, -0.5, 0.02, 0, -0.5, 0, -0.32, 0.5, 0, 0, -0.5, 0.02, 0, -0.45, -0.12, 0]);
    g.setAttribute("position", new THREE.BufferAttribute(v, 3)); g.computeVertexNormals(); return g;
  }, []);
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.to, Easing.bezier(0.4, 0, 0.6, 1));
  const x = -2.2 + k * 4.4;
  const y = wy(e.y) + Math.sin(k * Math.PI) * 0.45;
  return (
    <mesh geometry={geo} position={[x, y, 0.8]} rotation={[0.5, -0.25, Math.cos(k * Math.PI) * 0.35]} scale={0.9}>
      <meshStandardMaterial color="#FFFFFF" side={THREE.DoubleSide} roughness={0.5} />
    </mesh>
  );
};

// ---------- hanging shop sign that flips OPEN -> CLOSED ----------
const signTexture = (text: string, color: string) => {
  const c = document.createElement("canvas"); c.width = 512; c.height = 256;
  const g = c.getContext("2d")!;
  g.fillStyle = "#FFFFFF"; g.beginPath(); g.roundRect(0, 0, 512, 256, 30); g.fill();
  g.strokeStyle = color; g.lineWidth = 16; g.beginPath(); g.roundRect(14, 14, 484, 228, 22); g.stroke();
  g.fillStyle = color; g.font = "900 120px Helvetica, Arial"; g.textAlign = "center"; g.fillText(text, 256, 172);
  const tx = new THREE.CanvasTexture(c); tx.colorSpace = THREE.SRGBColorSpace; return tx;
};
const Sign: React.FC<{ e: Extract<E3, { type: "sign" }> }> = ({ e }) => {
  const t = useT();
  const mats = useMemo(() => {
    const edge = new THREE.MeshStandardMaterial({ color: "#8D6E63", roughness: 0.6 });
    const front = new THREE.MeshBasicMaterial({ map: signTexture("OPEN", "#2E7D32"), toneMapped: false });
    const back = new THREE.MeshBasicMaterial({ map: signTexture("CLOSED", "#C62828"), toneMapped: false });
    return [edge, edge, edge, edge, front, back];
  }, []);
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.5);
  const out = ease(t, e.to - 0.3, e.to, EASE_IN);
  const swing = Math.sin((t - e.from) * 6) * 0.25 * Math.exp(-(t - e.from) * 2.2);
  const flip = ease(t, e.flipAt, e.flipAt + 0.6) * Math.PI;
  return (
    <group position={[wx(e.x), wy(e.y) + (1 - k) * 1.2, 0.6]} rotation={[0, 0, swing]} scale={1 - out}>
      {[-0.28, 0.28].map((sx) => (
        <mesh key={sx} position={[sx, 0.32, 0]} rotation={[0, 0, sx > 0 ? -0.35 : 0.35]}><cylinderGeometry args={[0.008, 0.008, 0.42, 8]} /><meshStandardMaterial color="#555" /></mesh>
      ))}
      <mesh rotation={[0, flip, 0]}><boxGeometry args={[0.9, 0.45, 0.04]} />{mats.map((m, i) => <primitive key={i} object={m} attach={`material-${i}`} />)}</mesh>
    </group>
  );
};

// ---------- 3D pie: where the money goes (tiny yellow profit slice) ----------
const Pie: React.FC<{ e: Extract<E3, { type: "pie" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.6);
  const out = ease(t, e.to - 0.3, e.to, EASE_IN);
  const slices = [[0.5, "#2B2B2B"], [0.22, "#FFFFFF"], [0.23, "#9E9E9E"], [0.05, YELLOW]] as const;
  let start = 0;
  const pop = ease(t, e.from + 0.7, e.from + 1.2);
  return (
    <group position={[wx(e.x), wy(e.y), 0.6]} rotation={[0.9, 0, 0]} scale={0.95 * k * (1 - out)}>
      {slices.map(([frac, col], i) => {
        const len = frac * Math.PI * 2 * k;
        const mid = start + len / 2;
        const lift = i === 3 ? pop * 0.12 : 0;
        const el = (
          <mesh key={i} position={[Math.sin(mid) * lift, lift * 0.6, Math.cos(mid) * lift]}>
            <cylinderGeometry args={[0.42, 0.42, 0.12, 64, 1, false, start, len]} />
            <meshStandardMaterial color={col} roughness={0.45} metalness={i === 3 ? 0.3 : 0} />
          </mesh>
        );
        start += len;
        return el;
      })}
    </group>
  );
};

// ---------- gold coin stack that loses half ----------
const Coins: React.FC<{ e: Extract<E3, { type: "coins" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const x = wx(e.x), y = wy(e.y);
  const out = ease(t, e.to - 0.35, e.to, EASE_IN);
  return (
    <group position={[x, y - 0.5, 0.6]} rotation={[0.35, 0.4, 0]} scale={1 - out}>
      {Array.from({ length: e.count }, (_, i) => {
        const land = ease(t, e.buildAt + i * 0.07, e.buildAt + i * 0.07 + 0.35);
        const gone = i >= e.count / 2 ? ease(t, e.halveAt + (i - e.count / 2) * 0.04, e.halveAt + (i - e.count / 2) * 0.04 + 0.6) : 0;
        if (land <= 0) return null;
        const yy = i * 0.075 + (1 - land) * 2 + gone * 1.6;
        return (
          <mesh key={i} position={[gone * (0.8 + (i % 3) * 0.3), yy, gone * 0.5]} rotation={[gone * 2, gone * 3 + i * 0.4, gone]} scale={1 - gone * 0.6}>
            <cylinderGeometry args={[0.3, 0.3, 0.065, 64]} />
            <meshStandardMaterial color="#E8A317" metalness={0.9} roughness={0.3} envMapIntensity={0.7} transparent opacity={1 - gone} />
          </mesh>
        );
      })}
    </group>
  );
};

// ---------- red double-decker bus driving across (behind the head) ----------
const Bus: React.FC<{ e: Extract<E3, { type: "bus" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.to, Easing.bezier(0.45, 0, 0.55, 1));
  const x = -3.4 + k * 6.8;
  const bump = Math.abs(Math.sin(t * 14)) * 0.012;
  const wheel = -t * 12;
  const red = <meshStandardMaterial color="#C8102E" roughness={0.35} metalness={0.1} />;
  const glass = <meshStandardMaterial color="#1b2430" roughness={0.1} metalness={0.4} />;
  return (
    <group position={[x, wy(e.y) - 0.45 + bump, -1.5]} rotation={[0.06, -0.12, 0]} scale={1.15}>
      <mesh position={[0, 0.27, 0]}><boxGeometry args={[1.7, 0.5, 0.6]} />{red}</mesh>
      <mesh position={[0, 0.78, 0]}><boxGeometry args={[1.66, 0.48, 0.58]} />{red}</mesh>
      <mesh position={[0, 1.04, 0]}><boxGeometry args={[1.62, 0.05, 0.56]} /><meshStandardMaterial color="#B00D27" roughness={0.4} /></mesh>
      <mesh position={[0, 0.53, 0]}><boxGeometry args={[1.71, 0.04, 0.61]} /><meshStandardMaterial color="#F3E9D2" roughness={0.5} /></mesh>
      {[0.36, 0.86].map((wy0, r) => [-0.6, -0.2, 0.2, 0.6].map((wx0, i) => (
        <mesh key={`${r}${i}`} position={[wx0, wy0, 0.302]}><boxGeometry args={[0.3, 0.2, 0.01]} />{glass}</mesh>
      )))}
      <mesh position={[0.851, 0.4, 0]}><boxGeometry args={[0.01, 0.3, 0.45]} />{glass}</mesh>
      <mesh position={[0.84, 0.98, 0]}><boxGeometry args={[0.02, 0.07, 0.3]} /><meshStandardMaterial color="#111" emissive="#FFB300" emissiveIntensity={0.6} /></mesh>
      {[-0.55, 0.55].map((wx0) => [-0.31, 0.31].map((wz) => (
        <mesh key={`${wx0}${wz}`} position={[wx0, 0.02, wz]} rotation={[Math.PI / 2, 0, wheel]}>
          <cylinderGeometry args={[0.13, 0.13, 0.08, 32]} />
          <meshStandardMaterial color="#111" roughness={0.8} />
        </mesh>
      )))}
    </group>
  );
};

const Label: React.FC<{ e: Extract<E3, { type: "label" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.4);
  const out = ease(t, e.to - 0.25, e.to, EASE_IN);
  return (
    <div style={{ position: "absolute", left: 56, top: e.y, transform: `translateY(${(1 - k) * 20}px)`,
      opacity: k * (1 - out), fontFamily: "Anton, Impact, sans-serif", fontSize: 74, lineHeight: 1.0, color: e.accent ? YELLOW : "#fff",
      WebkitTextStroke: `4px ${INK}`, paintOrder: "stroke fill", whiteSpace: "pre" }}>{e.text}</div>
  );
};


// ---------- flat clip-art stickers (die-cut white border, slapped on at an angle) ----------
export const ART: Record<string, React.ReactNode> = {
  ukflag: (
    <g>
      <clipPath id="fl"><rect x="10" y="30" width="180" height="140" rx="14" /></clipPath>
      <g clipPath="url(#fl)">
        <rect x="10" y="30" width="180" height="140" fill="#012169" />
        <path d="M10 30 L190 170 M190 30 L10 170" stroke="#fff" strokeWidth="30" />
        <path d="M10 30 L190 170 M190 30 L10 170" stroke="#C8102E" strokeWidth="10" />
        <rect x="85" y="30" width="30" height="140" fill="#fff" /><rect x="10" y="85" width="180" height="30" fill="#fff" />
        <rect x="91" y="30" width="18" height="140" fill="#C8102E" /><rect x="10" y="91" width="180" height="18" fill="#C8102E" />
      </g>
    </g>
  ),
  apple: (
    <g>
      <path d="M100 62 C70 40 28 52 28 100 C28 150 62 182 84 178 C92 177 96 172 100 172 C104 172 108 177 116 178 C138 182 172 150 172 100 C172 52 130 40 100 62 Z" fill="#E53935" />
      <path d="M58 82 C52 96 52 112 56 124" stroke="#FF8A80" strokeWidth="10" strokeLinecap="round" fill="none" />
      <path d="M100 62 C100 46 104 34 112 26" stroke="#6D4C41" strokeWidth="8" strokeLinecap="round" fill="none" />
      <path d="M108 40 C122 22 148 22 156 30 C146 46 124 50 108 40 Z" fill="#43A047" />
    </g>
  ),
  books: (
    <g>
      <rect x="24" y="128" width="152" height="34" rx="6" fill="#1E88E5" /><rect x="24" y="128" width="152" height="8" fill="#1565C0" />
      <rect x="34" y="94" width="136" height="34" rx="6" fill="#FFD600" /><rect x="34" y="94" width="136" height="8" fill="#F9A825" />
      <path d="M100 92 C80 76 56 82 56 104 C56 70 30 66 30 66" fill="none" />
      <circle cx="104" cy="66" r="26" fill="#E53935" /><path d="M104 40 L108 28" stroke="#6D4C41" strokeWidth="6" strokeLinecap="round" />
      <path d="M108 34 C118 22 134 24 138 30 C130 40 116 40 108 34 Z" fill="#43A047" />
    </g>
  ),
  wine: (
    <g>
      <rect x="78" y="70" width="44" height="112" rx="16" fill="#7B1E2B" />
      <rect x="90" y="22" width="20" height="56" rx="6" fill="#7B1E2B" />
      <rect x="88" y="16" width="24" height="14" rx="4" fill="#FFD600" />
      <rect x="82" y="110" width="36" height="40" rx="4" fill="#F7F1E3" />
      <rect x="82" y="118" width="36" height="5" fill="#7B1E2B" />
      <rect x="86" y="82" width="8" height="70" rx="4" fill="#A33A4A" opacity="0.7" />
    </g>
  ),
  glass: (
    <g>
      <path d="M62 30 L138 30 C138 84 122 104 100 104 C78 104 62 84 62 30 Z" fill="#E8F1F8" />
      <path d="M66 62 L134 62 C130 90 118 100 100 100 C82 100 70 90 66 62 Z" fill="#8E1B30" />
      <rect x="96" y="104" width="8" height="56" fill="#E8F1F8" /><ellipse cx="100" cy="164" rx="34" ry="8" fill="#E8F1F8" />
    </g>
  ),
  bubble: (
    <g>
      <path d="M30 40 H170 A20 20 0 0 1 190 60 V120 A20 20 0 0 1 170 140 H90 L56 172 L62 140 H30 A20 20 0 0 1 10 120 V60 A20 20 0 0 1 30 40 Z" fill="#FFFFFF" stroke="#141414" strokeWidth="8" />
    </g>
  ),
  tickets: (
    <g>
      <g transform="rotate(-12 100 100)"><rect x="22" y="58" width="150" height="72" rx="10" fill="#E53935" /><circle cx="22" cy="94" r="12" fill="#fff" opacity="0" /><rect x="118" y="58" width="4" height="72" fill="#FFCDD2" /><text x="68" y="104" fontFamily="Helvetica" fontWeight="900" fontSize="26" fill="#fff" textAnchor="middle">ADMIT</text></g>
      <g transform="rotate(8 100 100)"><rect x="36" y="92" width="150" height="72" rx="10" fill="#FFD600" /><rect x="132" y="92" width="4" height="72" fill="#FFF59D" /><text x="84" y="138" fontFamily="Helvetica" fontWeight="900" fontSize="26" fill="#141414" textAnchor="middle">ONE</text></g>
    </g>
  ),
  popcorn: (
    <g>
      {[[62, 62], [88, 46], [116, 50], [140, 64], [76, 40], [104, 32], [128, 40], [52, 80], [150, 82]].map(([x, y], i) => <circle key={i} cx={x} cy={y} r="20" fill="#FFF8E1" stroke="#F3D58A" strokeWidth="3" />)}
      <path d="M44 80 H156 L140 184 H60 Z" fill="#FFFFFF" />
      {[56, 80, 104, 128].map((x) => <path key={x} d={`M${x} 80 H${x + 12} L${x + 8} 184 H${x - 2} Z`} fill="#E53935" />)}
    </g>
  ),
  spoiler: (
    <g transform="rotate(-8 100 100)">
      <rect x="-20" y="72" width="240" height="56" fill="#FFD600" />
      {[-20, 20, 60, 100, 140, 180].map((x) => <path key={x} d={`M${x} 72 h20 l-28 56 h-20 Z`} fill="#141414" />)}
      <rect x="18" y="82" width="164" height="36" rx="6" fill="#141414" />
      <text x="100" y="108" fontFamily="Helvetica" fontWeight="900" fontSize="22" fill="#FFD600" textAnchor="middle">SPOILERS AHEAD</text>
    </g>
  ),
  repeat: (
    <g fill="none" stroke="#1E88E5" strokeWidth="18" strokeLinecap="round">
      <path d="M48 96 A54 54 0 0 1 150 70" /><path d="M152 104 A54 54 0 0 1 50 130" />
      <path d="M150 70 L156 38 M150 70 L120 62" /><path d="M50 130 L44 162 M50 130 L80 138" />
    </g>
  ),
  web: (
    <g fill="none" stroke="#141414" strokeWidth="4" strokeLinecap="round">
      {[0, 22, 45, 67, 90].map((a) => <line key={a} x1="10" y1="10" x2={10 + 180 * Math.cos((a * Math.PI) / 180)} y2={10 + 180 * Math.sin((a * Math.PI) / 180)} />)}
      {[50, 95, 140].map((r) => <path key={r} d={`M${10 + r} 10 Q${10 + r * 0.8} ${10 + r * 0.35} ${10 + r * 0.7} ${10 + r * 0.7} Q${10 + r * 0.35} ${10 + r * 0.8} 10 ${10 + r}`} />)}
    </g>
  ),
  tally: (
    <g stroke="#141414" strokeWidth="12" strokeLinecap="round">
      <rect x="14" y="40" width="172" height="120" rx="16" fill="#FFFFFF" stroke="none" />
      {[46, 74, 102, 130].map((x) => <line key={x} x1={x} y1="62" x2={x} y2="138" />)}
      <line x1="30" y1="128" x2="150" y2="72" stroke="#E53935" />
    </g>
  ),
  heart: <path d="M100 172 C40 130 18 104 18 72 C18 44 40 26 64 26 C80 26 92 34 100 48 C108 34 120 26 136 26 C160 26 182 44 182 72 C182 104 160 130 100 172 Z" fill="#E53935" />,
  mask: (
    <g>
      <path d="M14 92 C30 56 76 56 100 76 C124 56 170 56 186 92 C176 132 128 140 100 118 C72 140 24 132 14 92 Z" fill="#141414" />
      <ellipse cx="66" cy="94" rx="22" ry="14" fill="#FFFFFF" /><ellipse cx="134" cy="94" rx="22" ry="14" fill="#FFFFFF" />
    </g>
  ),
  pot: (
    <g>
      {[70, 100, 130].map((x, i) => <path key={x} d={`M${x} 60 C${x - 12} ${48 - i * 2} ${x + 12} 36 ${x} 22`} stroke="#B0BEC5" strokeWidth="8" fill="none" strokeLinecap="round" />)}
      <rect x="34" y="78" width="132" height="86" rx="18" fill="#546E7A" />
      <rect x="26" y="70" width="148" height="20" rx="10" fill="#78909C" />
      <rect x="6" y="96" width="30" height="14" rx="7" fill="#455A64" /><rect x="164" y="96" width="30" height="14" rx="7" fill="#455A64" />
    </g>
  ),
  star: <path d="M100 18 L124 74 L184 78 L138 116 L154 176 L100 142 L46 176 L62 116 L16 78 L76 74 Z" fill="#FFD600" stroke="#141414" strokeWidth="6" />,
  planet: (
    <g>
      <circle cx="100" cy="100" r="52" fill="#7E57C2" />
      <path d="M48 92 C60 82 140 82 152 92" stroke="#B39DDB" strokeWidth="10" fill="none" />
      <ellipse cx="100" cy="106" rx="92" ry="24" fill="none" stroke="#FFD600" strokeWidth="10" transform="rotate(-14 100 106)" />
    </g>
  ),
  crown: (
    <g>
      <path d="M24 150 L34 62 L72 104 L100 46 L128 104 L166 62 L176 150 Z" fill="#FFD600" stroke="#141414" strokeWidth="7" strokeLinejoin="round" />
      <rect x="24" y="148" width="152" height="24" rx="6" fill="#FBC02D" stroke="#141414" strokeWidth="7" />
      {[60, 100, 140].map((x) => <circle key={x} cx={x} cy="160" r="6" fill="#E53935" />)}
    </g>
  ),
  bus: (
    <g>
      <rect x="14" y="40" width="172" height="118" rx="16" fill="#D32F2F" />
      <rect x="14" y="40" width="172" height="12" rx="6" fill="#B71C1C" />
      <rect x="14" y="98" width="172" height="8" fill="#F5E6C8" />
      {[26, 66, 106, 146].map((x) => <rect key={`u${x}`} x={x} y="58" width="32" height="30" rx="5" fill="#263238" />)}
      {[26, 66, 106].map((x) => <rect key={`l${x}`} x={x} y="112" width="32" height="28" rx="5" fill="#263238" />)}
      <rect x="146" y="112" width="30" height="40" rx="4" fill="#37474F" />
      <rect x="30" y="44" width="60" height="9" rx="3" fill="#FFD600" />
      <circle cx="52" cy="162" r="17" fill="#212121" /><circle cx="52" cy="162" r="7" fill="#9E9E9E" />
      <circle cx="146" cy="162" r="17" fill="#212121" /><circle cx="146" cy="162" r="7" fill="#9E9E9E" />
    </g>
  ),
  cheese: (
    <g>
      <path d="M22 140 L178 140 L178 84 L22 140 Z" fill="#FBC02D" />
      <path d="M22 140 L178 84 L178 70 L22 128 Z" fill="#FFE082" />
      <path d="M22 140 L178 140 L178 162 L22 162 Z" fill="#F9A825" />
      <circle cx="120" cy="124" r="10" fill="#F57F17" opacity="0.6" /><circle cx="150" cy="110" r="7" fill="#F57F17" opacity="0.6" />
      <circle cx="80" cy="150" r="6" fill="#E65100" opacity="0.5" /><circle cx="140" cy="152" r="8" fill="#E65100" opacity="0.5" />
    </g>
  ),
};

export const Sticker: React.FC<{ e: Extract<E3, { type: "sticker" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const mode = e.mode ?? "slap";
  const dir = e.dir ?? -1;                     // -1 = comes from the left, 1 = from the right
  const out = ease(t, e.to - 0.25, e.to, EASE_IN);
  let dx = 0, dy = 0, rot = e.rot, scale = 1, opacity = 1 - out;
  let strand: { x1: number; y1: number; x2: number; y2: number } | null = null;
  if (mode === "slap") {
    const k = ease(t, e.from, e.from + 0.32);
    scale = (1.35 - 0.35 * k) * (1 - out * 0.3);
    rot = e.rot + (1 - k) * 14 * Math.sign(e.rot || 1);
    opacity = Math.min(1, k * 2) * (1 - out);
  } else if (mode === "fly") {
    // arcs in from off-screen, overshoots a touch, settles at its angle
    const k = ease(t, e.from, e.from + 0.55);
    dx = dir * (1 - k) * 900;
    dy = -Math.sin(k * Math.PI) * 120 + (1 - k) * 200;
    rot = e.rot + (1 - k) * dir * -40;
    scale = (0.7 + 0.3 * k) * (1 - out * 0.3);
    dy += out * -60;
  } else {
    // swing: hangs from a web strand anchored above the frame; damped pendulum
    const L = e.y + 60;                          // strand length from the top edge
    const tt = t - e.from;
    const theta = dir * 1.1 * Math.exp(-tt * 2.6) * Math.cos(tt * 7.5);
    const drop = ease(t, e.from, e.from + 0.25);
    dx = Math.sin(theta) * L;
    dy = (Math.cos(theta) - 1) * L - (1 - drop) * 300;
    rot = e.rot + (theta * 180) / Math.PI * 0.6;
    strand = { x1: e.x, y1: -20, x2: e.x + dx, y2: e.y + dy - e.size * 0.42 };
    dy += out * -500;                             // yanked back up on exit
    if (strand) strand.y2 += out * -500;
  }
  const id = `cut-${e.art}-${Math.round(e.from * 100)}`;
  return (
    <>
      {strand && (
        <svg style={{ position: "absolute", left: 0, top: 0, width: 1080, height: 1920, opacity: 1 - out }}>
          <line {...strand} stroke="#FFFFFF" strokeWidth="5" />
          <line {...strand} stroke="rgba(0,0,0,0.25)" strokeWidth="1.5" />
        </svg>
      )}
      <div style={{ position: "absolute", left: e.x - e.size / 2 + dx, top: e.y - e.size / 2 + dy, width: e.size, height: e.size,
        opacity, transform: `rotate(${rot}deg) scale(${scale})`,
        filter: "drop-shadow(0 12px 16px rgba(0,0,0,0.32))" }}>
        <svg viewBox="0 0 200 200" width={e.size} height={e.size}>
          <defs>
            <filter id={id} x="-20%" y="-20%" width="140%" height="140%">
              <feMorphology in="SourceAlpha" operator="dilate" radius="9" result="grow" />
              <feFlood floodColor="#FFFFFF" /><feComposite in2="grow" operator="in" result="border" />
              <feMerge><feMergeNode in="border" /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
          </defs>
          <g filter={e.art === "web" ? undefined : `url(#${id})`}>{ART[e.art]}</g>
          {e.text && <text x="100" y="98" fontFamily="Anton, Impact, sans-serif" fontSize="42" textAnchor="middle" fill="#141414">{e.text}</text>}
        </svg>
      </div>
    </>
  );
};

// full-screen kinetic-type card (cuts away from the face for a punchline)
const FullCard: React.FC<{ e: Extract<E3, { type: "card" }> }> = ({ e }) => {
  const t = useT();
  if (t < e.from || t > e.to) return null;
  const k = ease(t, e.from, e.from + 0.18);
  const out = ease(t, e.to - 0.18, e.to, EASE_IN);
  return (
    <div style={{ position: "absolute", inset: 0, background: "#F7F7F5", opacity: k * (1 - out), display: "flex",
      flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
      <svg style={{ position: "absolute", inset: 0 }} width="1080" height="1920">
        {[270, 540, 810].map((x) => <line key={x} x1={x} y1="0" x2={x} y2="1920" stroke="#E6E6E2" strokeWidth="2" />)}
        {[640, 1280].map((y) => <line key={y} x1="0" y1={y} x2="1080" y2={y} stroke="#E6E6E2" strokeWidth="2" />)}
      </svg>
      {e.lines.map((l, i) => {
        const a = ease(t, l.at, l.at + 0.35);
        return (
          <div key={i} style={{ position: "relative", fontFamily: "Anton, Impact, sans-serif", fontSize: l.size ?? 120, lineHeight: 1,
            color: l.accent ? YELLOW : INK, WebkitTextStroke: l.accent ? `8px ${INK}` : undefined, paintOrder: "stroke fill",
            opacity: a, transform: `translateY(${(1 - a) * 40}px) scale(${0.92 + 0.08 * a})`, letterSpacing: (1 - a) * -10 + 2 }}>{l.text}</div>
        );
      })}
    </div>
  );
};

export const Overlay3D: React.FC<P3> = ({ elements, layer }) => {
  const mine = elements.filter((e) => (e.layer ?? (e.type === "big" || e.type === "bus" ? "behind" : "front")) === layer);
  const bigs = mine.filter((e) => e.type === "big") as Extract<E3, { type: "big" }>[];
  const labels = mine.filter((e) => e.type === "label") as Extract<E3, { type: "label" }>[];
  const stickers = mine.filter((e) => e.type === "sticker") as Extract<E3, { type: "sticker" }>[];
  const cards = mine.filter((e) => e.type === "card") as Extract<E3, { type: "card" }>[];
  const three = mine.filter((e) => !["big", "label", "sticker", "card"].includes(e.type));
  return (
    <AbsoluteFill style={{ backgroundColor: "transparent" }}>
      {bigs.map((e, i) => <Big key={i} e={e as never} />)}
      {stickers.map((e, i) => <Sticker key={`s${i}`} e={e} />)}
      {labels.map((e, i) => <Label key={`l${i}`} e={e} />)}
      {cards.map((e, i) => <FullCard key={`c${i}`} e={e} />)}
      {three.length > 0 && (
        <ThreeCanvas width={1080} height={1920} camera={{ fov: 30, position: [0, 0, 10] }}
          gl={{ alpha: true, antialias: true }} style={{ backgroundColor: "transparent" }}>
          <Studio />
          {three.map((e, i) => {
            switch (e.type) {
              case "cards": return <Cards key={i} e={e} />;
              case "wineCheese": return <WineCheese key={i} e={e} />;
              case "coins": return <Coins key={i} e={e} />;
              case "bus": return <Bus key={i} e={e} />;
              case "flag": return <Flag key={i} e={e} />;
              case "apple": return <Apple key={i} e={e} />;
              case "plane": return <Plane key={i} e={e} />;
              case "sign": return <Sign key={i} e={e} />;
              case "pie": return <Pie key={i} e={e} />;
              default: return null;
            }
          })}
        </ThreeCanvas>
      )}
    </AbsoluteFill>
  );
};
