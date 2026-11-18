/**
 * Surface formatting: the things that give a post away before anyone reads a
 * sentence. Emoji bullets, hashtag stacks, thread announcements, endless lists.
 */

const EMOJI_BULLET = /^[ \t]*(?:[-*+][ \t]+)?(\p{Extended_Pictographic}|[✅✔️❌➡️🔹🔸▪️•]) /u;
const HASHTAG = /(?:^|\s)#[\p{L}\p{N}_]{2,}/gu;
const THREAD_OPENER = /^[ \t]*(?:🧵|Thread:|A thread|Тред(?![\p{L}])|Гілка:)/imu;
const BULLET_LINE = /^[ \t]*(?:[-*+]|\d+[.)])[ \t]+\S/;

const MAX_BULLET_RUN = 7;
const MAX_HASHTAGS = 2;

export function formatting(text) {
  const findings = [];
  const lines = text.split('\n');

  let offset = 0;
  let bulletRun = [];
  const lineOffsets = [];
  for (const line of lines) {
    lineOffsets.push(offset);
    offset += line.length + 1;
  }

  lines.forEach((line, index) => {
    const start = lineOffsets[index];

    if (EMOJI_BULLET.test(line)) {
      findings.push({
        rule: 'emoji-bullet',
        severity: 'high',
        start,
        end: start + line.length,
        message: 'emoji used as a bullet — one or two emoji in a post is fine, a column of them is slop',
      });
    }

    if (BULLET_LINE.test(line)) {
      bulletRun.push({ start, end: start + line.length });
    } else if (line.trim().length > 0) {
      flushBullets();
    }
  });
  flushBullets();

  const hashtags = [...text.matchAll(HASHTAG)];
  if (hashtags.length > MAX_HASHTAGS) {
    const first = hashtags[MAX_HASHTAGS];
    findings.push({
      rule: 'hashtag-stack',
      severity: 'medium',
      start: first.index,
      end: text.length > first.index ? first.index + first[0].length : first.index,
      message: `${hashtags.length} hashtags — keep it to two, integrated into the sentence`,
    });
  }

  const thread = text.match(THREAD_OPENER);
  if (thread && thread.index !== undefined) {
    findings.push({
      rule: 'thread-opener',
      severity: 'high',
      start: thread.index,
      end: thread.index + thread[0].length,
      message: 'thread announcement — the content should carry the reader on its own',
    });
  }

  return findings;

  function flushBullets() {
    if (bulletRun.length > MAX_BULLET_RUN) {
      findings.push({
        rule: 'bullet-run',
        severity: 'medium',
        start: bulletRun[0].start,
        end: bulletRun[bulletRun.length - 1].end,
        message: `${bulletRun.length} bullets in a row — never more than 5-7, and make them uneven`,
      });
    }
    bulletRun = [];
  }
}
