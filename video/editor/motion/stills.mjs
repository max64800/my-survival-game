// Render QA stills from one bundle: node stills.mjs <props.json> <out_dir> <t1,t2,...> [composition]
// Each still is saved as <out_dir>/t<seconds>.png at FULL 1080x1920 (STILL_SCALE=0.5 for quick looks): collisions only show at full size.
import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";
const cleanup = (dir) => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };

const [propsPath, outDir, times, compId = "Edit60"] = process.argv.slice(2);
const inputProps = JSON.parse(fs.readFileSync(propsPath, "utf8"));
fs.mkdirSync(outDir, { recursive: true });
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve(process.env.PUBLIC_DIR ?? "public") });
const composition = await selectComposition({ serveUrl, id: compId, inputProps });
for (const t of times.split(",").map(Number)) {
  const frame = Math.min(composition.durationInFrames - 1, Math.round(t * composition.fps));
  const output = path.join(outDir, `t${t.toFixed(2)}.png`);
  await renderStill({ serveUrl, composition, inputProps, frame, output, scale: Number(process.env.STILL_SCALE ?? 1), chromiumOptions: { gl: "angle" } });
  console.log("still", output);
}
cleanup(serveUrl);   // the bundle copies all of public/ (GBs) into a temp dir
