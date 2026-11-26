"""Template (last used for round 10). Edit SLOTS + output names, run from a scratch folder holding cands*.json. Round 8: the gaps after rounds 6+7 (level up in a new style, beetle walking, ghost boss death, one-handed whoosh)."""
import json, os, re, time, urllib.request
src = open('find.py').read().split('seen, data')[0]; ns = {}; exec(src, ns); search = ns['search']
BAD = re.compile(r"fuck|shit|kill|sex|moan|orgasm|female|woman|girl|child|kid|baby|scream|pain|hurt|death|die|sound design elements|bullet|cartoon|laser|8.?bit|retro|arcade|game ?over|coin|level|achievement|synth|zap|notification|ui\b|guitar|door|glass|bottle|cat\b|glitch|loop|anvil|bell|horn|bowl|turkey|power.?up", re.I)
seen = {c['id'] for f in __import__('glob').glob('cands*.json') for s in json.load(open(f)) for c in s['cands']}
PER = 10
SLOTS = [
 ("level_up", "Dwarf", "Level up: mine sounds + tiny tunes", "a skill goes up: coins, a treasure chest, a stone thunk, or a 1-2 s tune on a lute, flute or fiddle", 3.5,
  ["lute strum short", "flute short phrase", "fiddle short", "coins pour", "treasure chest open", "pickaxe stone hit", "hammer on stone", "medieval short melody"]),
]
OLD = {"ghost_boss_death": "cand/old/ghost_death_0.ogg"}
data = []
for slot, cat, name, when, maxd, qs in SLOTS:
    lists = []
    for q in qs:
        try: lists.append([c for c in search(q) if 0.08 <= c['dur'] <= maxd + 1.5 and not BAD.search(c['title'])])
        except Exception as e: print('fail', q, e); lists.append([])
        time.sleep(0.6)
    got = []
    while len(got) < PER and any(lists):
        for l in lists:
            while l and l[0]['id'] in seen: l.pop(0)
            if l and len(got) < PER: c = l.pop(0); seen.add(c['id']); got.append(c)
    for c in got:
        c['page'] = f"https://freesound.org/people/{c['user']}/sounds/{c['id']}/"; c['file'] = f"cand/r10/{slot}/{c['id']}.mp3"
        os.makedirs(os.path.dirname(c['file']), exist_ok=True)
        open(c['file'], 'wb').write(urllib.request.urlopen(urllib.request.Request(c['mp3'], headers={"User-Agent": "Mozilla/5.0"}), timeout=60).read())
        c.pop('mp3'); c.pop('dur')
    prev = []  # (earlier MAYBEs to compare again go here)
    data.append({"id": slot, "cat": cat, "name": name, "when": when, "old": OLD.get(slot), "cands": prev + got})
    print(slot, [c['title'][:30] for c in got])
json.dump(data, open('cands10.json', 'w'), indent=1)
