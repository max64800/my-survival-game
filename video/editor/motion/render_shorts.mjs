// YT00 renders without copying the (multi-GB) public dir: the bundle symlinks public_yt00.
// node render_yt00.mjs stills <props.json> <out_dir> <t1,t2,...>
// node render_yt00.mjs video  <props.json> <out.mp4> [fromSec toSec]
import { bundle } from "@remotion/bundler";
import { renderMedia, renderStill, selectComposition } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";

const [mode, propsPath, out, a, b] = process.argv.slice(2);
const inputProps = JSON.parse(fs.readFileSync(propsPath, "utf8"));
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve("public_yt00"), symlinkPublicDir: true });
const composition = await selectComposition({ serveUrl, id: process.env.COMP ?? "YT00", inputProps });
const t0 = Date.now();
if (mode === "stills") {
  fs.mkdirSync(out, { recursive: true });
  for (const t of a.split(",").map(Number)) {
    const frame = Math.min(composition.durationInFrames - 1, Math.round(t * 30));
    const output = path.join(out, `t${t.toFixed(2).padStart(7, "0")}.png`);
    await renderStill({ serveUrl, composition, inputProps, frame, output, scale: Number(process.env.STILL_SCALE ?? 1), timeoutInMilliseconds: 180000 });
    console.log("still", output);
  }
} else if (mode === "clips") {
  fs.mkdirSync(out, { recursive: true });
  for (const rg of a.split(",")) {
    const [x, y] = rg.split("-").map(Number);
    const output = path.join(out, `clip_${x.toFixed(1).padStart(6, "0")}.mp4`);
    await renderMedia({ serveUrl, composition, inputProps, codec: "h264", outputLocation: output, frameRange: [Math.round(x * 30), Math.min(composition.durationInFrames - 1, Math.round(y * 30) - 1)],
      crf: 23, audioCodec: "aac", concurrency: Number(process.env.CONC ?? 4), timeoutInMilliseconds: 180000 });
    console.log("clip", output);
  }
} else {
  const frameRange = a !== undefined ? [Math.round(Number(a) * 30), Math.min(composition.durationInFrames - 1, Math.round(Number(b) * 30) - 1)] : null;
  let last = 0;
  await renderMedia({
    serveUrl, composition, inputProps, codec: "h264", outputLocation: out, frameRange, crf: 18, audioCodec: "aac", audioBitrate: "256k",
    concurrency: Number(process.env.CONC ?? 4), timeoutInMilliseconds: 180000, offthreadVideoCacheSizeInBytes: 2 * 1024 ** 3,
    onProgress: ({ progress, renderedFrames }) => { const p = Math.floor(progress * 100); if (p >= last + 2) { last = p; console.log(`${p}% ${renderedFrames} frames ${((Date.now() - t0) / 60000).toFixed(1)} min`); } },
  });
}
fs.rmSync(serveUrl, { recursive: true, force: true });
console.log("done", ((Date.now() - t0) / 60000).toFixed(1), "min");
