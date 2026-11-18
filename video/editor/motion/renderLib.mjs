// Batch-render the library: node renderLib.mjs [prefix]   (prefix "L-" motion graphics, "C-" captions, default both)
// One bundle, sequential renders, skips files that already exist (delete a file to re-render it).
// Output: ../../out/library/motion/<id>.mp4 and ../../out/library/captions/<id>.mp4
import { bundle } from "@remotion/bundler";
import { getCompositions, renderMedia } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";
const cleanup = (dir) => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };

const prefix = process.argv[2] ?? "";
const only = process.argv[3] ? new Set(process.argv[3].split(",")) : null;
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve("public_lib") });   // small public dir (lib clips, sfx, eqt): the full one is 5 GB and gets copied per bundle
const comps = (await getCompositions(serveUrl)).filter((c) => /^[LC]-/.test(c.id) && c.id.startsWith(prefix) && (!only || only.has(c.id)));
const root = path.resolve("../../out/library");
for (const composition of comps) {
  const dir = path.join(root, composition.id.startsWith("L-") ? "motion" : "captions");
  fs.mkdirSync(dir, { recursive: true });
  const out = path.join(dir, `${composition.id.slice(2)}.mp4`);
  if (fs.existsSync(out)) continue;
  const t0 = Date.now();
  try {
    await renderMedia({ serveUrl, composition, codec: "h264", crf: 20, outputLocation: out + ".part.mp4", concurrency: 4,
      chromiumOptions: { gl: "angle" }, timeoutInMilliseconds: 120000 });
    fs.renameSync(out + ".part.mp4", out);
    console.log("rendered", composition.id, ((Date.now() - t0) / 1000).toFixed(0) + "s");
  } catch (e) {
    console.log("FAILED", composition.id, String(e).slice(0, 300));
  }
}
cleanup(serveUrl);
console.log("done");
