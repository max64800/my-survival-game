// node stills_shorts.mjs <outdir> <n,n,...> [extra times per short as JSON {"1":[..]}]: full-size QA stills for the ep 0 shorts
import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";
const [out, ns, extra] = process.argv.slice(2);
const ex = extra ? JSON.parse(extra) : {};
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve("public_yt00"), symlinkPublicDir: true });
for (const n of ns.split(",")) {
  const inputProps = JSON.parse(fs.readFileSync(`src/yt00/shorts_ep0/s${n}.json`, "utf8"));
  if (process.env.GUIDES) inputProps.guides = true;
  const composition = await selectComposition({ serveUrl, id: `YT00S${n}`, inputProps });
  const times = ex[n] ?? JSON.parse(fs.readFileSync(`../../work/YT00/shorts/qa_s${n}.json`, "utf8"));
  const dir = path.join(out, `s${n}`); fs.mkdirSync(dir, { recursive: true });
  for (const t of times) {
    const frame = Math.min(composition.durationInFrames - 1, Math.round(t * 30));
    await renderStill({ serveUrl, composition, inputProps, frame, output: path.join(dir, `t${t.toFixed(2).padStart(6, "0")}.png`), timeoutInMilliseconds: 180000 });
  }
  console.log("short", n, times.length, "stills");
}
fs.rmSync(serveUrl, { recursive: true, force: true });
