import React from "react";
import { Composition } from "remotion";
import { Overlay, OverlayProps } from "./Overlay";
import { OverlayV2, V2Props } from "./OverlayV2";
import { Overlay3D, P3 } from "./Overlay3D";
import { Edit, EditProps } from "./Edit";
import { LIBRARY } from "./lib/registry";
import { CAPTIONS } from "./caps/registry";
import { CLIP_DUR } from "./caps/capcommon";

// One transparent 1080x1920 layer per video; its length and elements come from --props.
export const Root: React.FC = () => (
  <>
    {/* motion-graphics library + caption lab: one composition per demo (rendered by renderLib.mjs) */}
    {LIBRARY.map((it) => (
      <Composition key={it.id} id={`L-${it.id}`} component={it.C} width={1080} height={1920} fps={30} durationInFrames={Math.round(it.dur * 30)} />
    ))}
    {CAPTIONS.map((it) => (
      <Composition key={it.id} id={`C-${it.id}`} component={it.C} width={1080} height={1920} fps={30} durationInFrames={Math.round((CLIP_DUR + 0.35) * 30)} />
    ))}
    <Composition
      id="Overlay"
      component={Overlay}
      width={1080}
      height={1920}
      fps={30}
      durationInFrames={300}
      defaultProps={{ duration: 10, elements: [] } as OverlayProps}
      calculateMetadata={({ props }) => ({ durationInFrames: Math.ceil(props.duration * 30) })}
    />
    <Composition
      id="OverlayV2"
      component={OverlayV2}
      width={1080}
      height={1920}
      fps={30}
      durationInFrames={300}
      defaultProps={{ duration: 10, layer: "front", elements: [] } as V2Props}
      calculateMetadata={({ props }) => ({ durationInFrames: Math.ceil(props.duration * 30) })}
    />
    <Composition
      id="Overlay3D"
      component={Overlay3D}
      width={1080}
      height={1920}
      fps={30}
      durationInFrames={300}
      defaultProps={{ duration: 10, layer: "front", elements: [] } as P3}
      calculateMetadata={({ props }) => ({ durationInFrames: Math.ceil(props.duration * 30) })}
    />
    <Composition
      id="Edit"
      component={Edit}
      width={1080}
      height={1920}
      fps={30}
      durationInFrames={300}
      defaultProps={{ duration: 10, video: "", person: "", chunks: [], beats: [{ at: 0, zoom: 1, ox: 540, oy: 960 }], blur: [], split: [], elements: [], sfx: [] } as EditProps}
      calculateMetadata={({ props }) => ({ durationInFrames: Math.ceil(props.duration * 30) })}
    />
    <Composition
      id="Edit60"
      component={Edit}
      width={1080}
      height={1920}
      fps={60}
      durationInFrames={600}
      defaultProps={{ duration: 10, video: "", person: "", chunks: [], beats: [{ at: 0, zoom: 1, ox: 540, oy: 960 }], blur: [], split: [], elements: [], sfx: [] } as EditProps}
      calculateMetadata={({ props }) => ({ durationInFrames: Math.ceil(props.duration * 60) })}
    />
  </>
);
