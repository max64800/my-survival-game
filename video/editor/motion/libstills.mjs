// QA stills for library/caption demos from one bundle:
//   node libstills.mjs <out_dir> <compId>:<t1>,<t2> [<compId>:<t>...]
// e.g. node libstills.mjs /tmp/q L-m1-03:1,4.5,9 C-c1-02:2,6
// Saves <out_dir>/<compId>_t<seconds>.png at half size (540x960). Lists all ids with: node libstills.mjs list
import { bundle } from "@remotion/bundler";
import { getCompositions, renderStill } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";
const cleanup = (dir) => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };

const args = process.argv.slice(2);
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve("public_lib") });   // small public dir (lib clips, sfx, eqt): the full one is 5 GB and gets copied per bundle
const comps = await getCompositions(serveUrl);
if (args[0] === "list") { for (const c of comps) if (/^[LC]-/.test(c.id)) console.log(c.id, (c.durationInFrames / c.fps).toFixed(1) + "s"); cleanup(serveUrl); process.exit(0); }
const [outDir, ...jobs] = args;
fs.mkdirSync(outDir, { recursive: true });
for (const job of jobs) {
  const [id, times] = job.split(":");
  const composition = comps.find((c) => c.id === id);
  if (!composition) { console.error("no composition", id); continue; }
  for (const t of times.split(",").map(Number)) {
    const frame = Math.min(composition.durationInFrames - 1, Math.round(t * composition.fps));
    const output = path.join(outDir, `${id}_t${t.toFixed(2)}.png`);
    await renderStill({ serveUrl, composition, frame, output, scale: 0.5, chromiumOptions: { gl: "angle" } });
    console.log("still", output);
  }
}
cleanup(serveUrl);
