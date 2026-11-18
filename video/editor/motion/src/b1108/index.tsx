import React from "react";
import type { Pal } from "../kit11";
import * as b035 from "./b035";
import * as b036 from "./b036";
import * as b037 from "./b037";
import * as b038 from "./b038";
import * as b039 from "./b039";
import * as b040 from "./b040";
import * as b041 from "./b041";

// Nov 8 batch (035-041): one file per video so seven edits can run in parallel without editing shared code.
const MODS: Record<string, { Scene: React.FC<any>; Card: React.FC<any> }> = { "035": b035, "036": b036, "037": b037, "038": b038, "039": b039, "040": b040, "041": b041 };
export const isBatchKind = (kind: string) => /^b0\d\d_/.test(kind) && kind.slice(1, 4) in MODS;
export const BatchScene: React.FC<{ s: { kind: string }; w: number; h: number; t: number; p: Pal }> = (props) => {
  const M = MODS[props.s.kind.slice(1, 4)];
  return <M.Scene {...props} />;
};
export type BatchCardDef = { id: string; d: Record<string, unknown> };
export const BatchCard: React.FC<{ c: BatchCardDef; pal: Pal }> = ({ c, pal }) => {
  const M = MODS[c.id];
  return M ? <M.Card d={c.d} pal={pal} /> : null;
};
