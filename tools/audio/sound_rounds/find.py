"""Round 6 sound candidates: search Freesound (CC0 only), keep short clips, write cands.json + download previews."""
import json, os, re, sys, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(globals().get("__file__", "find.py")))
UA = {"User-Agent": "Mozilla/5.0"}
PER = 5
BAD = re.compile(r"guitar|door|glass|bottle|turkey|truck|chair|cat|glitch|inventory|soil|synth|blaster|EVP|quack|universal|spoon|AI\b|pistol|ice|steel|notification|undo|cricket|swede|stone in", re.I)
# (slot, category, name, when, old file in assets/sfx or None, max seconds, [queries])
SLOTS = [
 ("spider_death", "Creatures: Cave Spider", "Spider dies", "a cave spider's last screech as it curls up", "spider_death_0.ogg", 3, ["insect death", "creature death small", "monster death squeal", "bug squish death"]),
 ("spider_hurt", "Creatures: Cave Spider", "Spider gets hit", "short hiss/squeal when you hit a spider", None, 1.5, ["insect screech", "creature hurt", "monster hurt small", "bug squeal"]),
 ("spider_move", "Creatures: Cave Spider", "Spider skitters", "legs tapping on stone while it runs", None, 4, ["skitter", "crawling insect", "claws tapping", "creepy crawl"]),
 ("spider_notice", "Creatures: Cave Spider", "Spider spots you", "F792: warning hiss the moment it sees you", None, 2.5, ["spider hiss angry", "creature hiss", "insect chitter"]),
 ("snail_hurt", "Creatures: Rock Snail", "Snail gets hit", "wet squelch + shell knock when hit", None, 1.5, ["squelch", "slime splat", "wet hit gore"]),
 ("snail_move", "Creatures: Rock Snail", "Snail slides", "slow slimy slide", None, 5, ["slime squish slow", "slimy movement", "wet squish"]),
 ("snail_notice", "Creatures: Rock Snail", "Snail spots you", "F792: a gurgle or bubbly hiss", None, 2.5, ["gurgle", "slime creature", "monster gurgle"]),
 ("rat_death", "Creatures: Tunnel Rat", "Rat dies", "a last squeal", None, 2, ["rat squeal", "mouse squeak", "rodent squeak death"]),
 ("rat_hurt", "Creatures: Tunnel Rat", "Rat gets hit", "short pained squeak", None, 1, ["rat squeak", "mouse squeak short", "squeak"]),
 ("rat_move", "Creatures: Tunnel Rat", "Rat scurries", "tiny claws scratching", None, 4, ["scurry", "rat", "mouse running", "claws scratching wood"]),
 ("rat_notice", "Creatures: Tunnel Rat", "Rat spots you", "F792: angry chitter/hiss", None, 2, ["rat", "rodent squeak", "hiss animal", "squeak angry"]),
 ("beetle_hurt", "Creatures: Rock Beetle", "Beetle gets hit", "a click and crunch on its hard shell", None, 1.5, ["insect click", "beetle", "crunch shell", "bug crunch"]),
 ("beetle_notice", "Creatures: Rock Beetle", "Beetle spots you", "F792: deep clicking hiss", None, 2.5, ["insect clicking", "beetle hiss", "bug clicks"]),
 ("bat_hurt", "Creatures: Cave Bat", "Bat gets hit", "a sharp squeak", None, 1, ["bat squeak", "small creature squeak", "squeak high"]),
 ("bones_hurt", "Creatures: Skeleton miner", "Skeleton gets hit", "bones clattering when hit", None, 1.5, ["bone hit", "skeleton bones", "bones clatter"]),
 ("bones_move", "Creatures: Skeleton miner", "Skeleton walks", "dry bones rattling as it walks", None, 4, ["bones rattle", "skeleton walking", "wooden rattle"]),
 ("bones_notice", "Creatures: Skeleton miner", "Skeleton spots you", "F792: a hollow groan or rattle", None, 3, ["zombie groan", "undead moan", "skeleton rattle"]),
 ("ghost_notice", "Creatures: Ghosts", "Ghost spots you", "F792: a ghostly wail (you liked two before as MAYBE)", None, 3, ["ghost wail", "ghost whisper", "spooky moan"]),
 ("level_up", "Dwarf", "Level up", "a skill goes up a level: short, warm, proud", None, 3, ["level up", "achievement chime", "success fanfare short"]),
 ("bandage", "Dwarf", "Bandage", "wrapping a cloth bandage around a wound", None, 3, ["bandage", "cloth wrap", "fabric rustle"]),
 ("hit_mace", "Weapon hits", "Mace hit", "a mace landing: dull knock with a crunch (old = today's blunt hit)", "hit_blunt_0.ogg", 1.5, ["mace hit", "blunt impact", "club hit body"]),
 ("hit_spear", "Weapon hits", "Spear hit", "a spear stabbing in", None, 1.5, ["stab flesh", "spear stab", "knife stab", "stab gore"]),
 ("hit_axe", "Weapon hits", "Axe hit", "an axe biting in (old = today's sword hit)", "hit_0.ogg", 1.5, ["axe hit", "axe chop flesh", "sword hit flesh"]),
 ("hit_axe_2h", "Weapon hits", "Two-handed axe hit", "a huge axe chop: heavier and deeper", "hit_heavy_0.ogg", 2, ["heavy axe impact", "heavy chop", "big sword impact", "gore chop"]),
 ("hit_warhammer", "Weapon hits", "Two-handed warhammer hit", "a giant hammer: a big crushing boom", "hit_heavy_0.ogg", 2, ["heavy punch impact", "heavy blunt impact", "body hit heavy", "bone crush"]),
 ("swing_heavy", "Weapon hits", "Two-handed swing", "the big slow whoosh of a two-handed weapon", "swing_0.ogg", 2, ["heavy swoosh", "whoosh heavy", "big swing whoosh"]),
]

def search(q):
    url = "https://freesound.org/search/?" + urllib.parse.urlencode(
        {"q": q, "f": 'license:"Creative Commons 0"'})
    html = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30).read().decode("utf8", "replace")
    out = []
    for block in html.split('data-sound-id="')[1:]:
        sid = block.split('"', 1)[0]
        mp3 = re.search(r'data-mp3="([^"]+)"', block)
        dur = re.search(r'data-duration="([\d.]+)"', block)
        link = re.search(r'href="/people/([^/]+)/sounds/' + sid + r'/" title="([^"]*)"', block)
        lic = re.search(r'License: ([^"<]+)', block)
        if mp3 and dur and link and lic and "Creative Commons 0" in lic.group(1):
            if not BAD.search(link.group(2)): out.append({"id": sid, "user": link.group(1), "title": link.group(2), "dur": float(dur.group(1)),
                        "mp3": mp3.group(1).replace("-lq.mp3", "-hq.mp3")})
    return out

seen, data = set(), []
for slot, cat, name, when, old, maxd, qs in SLOTS:
    lists = []
    for q in qs:
        try:
            lists.append([c for c in search(q) if c["dur"] <= maxd + 3 and c["dur"] >= 0.08])
        except Exception as e:
            print("search fail", slot, q, e); lists.append([])
        time.sleep(0.6)
    picked = []
    while len(picked) < PER and any(lists):  # take turns between queries
        for l in lists:
            while l and (l[0]["id"] in seen):
                l.pop(0)
            if l and len(picked) < PER:
                c = l.pop(0); seen.add(c["id"]); picked.append(c)
    data.append({"id": slot, "cat": cat, "name": name, "when": when, "old": old, "cands": picked})
    print(slot, len(picked), [c["title"][:30] for c in picked])
json.dump(data, open(os.path.join(HERE, "cands.json"), "w"), indent=1)
