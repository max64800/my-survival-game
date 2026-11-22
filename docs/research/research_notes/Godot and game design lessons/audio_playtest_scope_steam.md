# Audio, playtesting, scope control and Steam Next Fest strategy (research notes, Nov 2026)

Scope: what the earlier doc `docs/research/sound-ai-effects-addons.md` (2026-11-19) does NOT cover. That doc already covers Godot reverb areas (`Area3D` reverb bus), the ray-check muffle, Nexus Resonance, and free sound packs (Kenney, Sonniss GDC bundles, Freesound CC0, OpenGameArt, Pixabay). Those are not repeated here.

**Words used here**
- **Adaptive music:** music that changes while you play (quiet when calm, bigger when a fight starts).
- **Stems / layers:** the same song split into parts (drums, strings, etc.) that get switched on or off.
- **Next Fest:** Steam's big free-demo event. Many games show demos at once.
- **Wishlist:** a Steam "I want this" button. It is a sign of interest, not a sale.

---

## 1. Music: when silence is better, and how to build adaptive music

### Takeaway
Use no music by default. Save music for a few big moments and let the game's own sounds (digging, wind, drips) carry the mood. The one well-known survival example with sparse music, Minecraft, used long silences on purpose, and the original designer says the silence lets players hear the world.

### Cited Findings
- Minecraft's soundtrack is sparse and often has long gaps of silence. A commentary piece says the sudden return of music makes an ordinary moment feel special. — [Killscreen commentary](https://www.killscreen.com/quiet-importance-minecraft-soundtrack/)
- In a podcast, the Minecraft composer C418 (Daniel Rosenfeld) described programmed random silence as giving players time to listen to the game's own sounds. — [Twenty Thousand Hertz podcast coverage: https://gamerant.com/minecraft-c418-twenty-thousand-hertz-podcast-interview/](https://gamerant.com/minecraft-c418-twenty-thousand-hertz-podcast-interview/)
- The same composer said players often wondered where the music went, because music came back at unmarked intervals (reported as about 15 minutes apart). — [Twenty Thousand Hertz coverage](https://gamerant.com/minecraft-c418-twenty-thousand-hertz-podcast-interview/) (secondhand; the exact interval is from a summary and should be rechecked)
- The Minecraft sparse style was partly shaped by the limits of its old sound engine (interview-based coverage). — [Wikipedia, Music of Minecraft](https://wikipedia.com/wiki/Music_of_Minecraft) (summary page; check the cited interviews before quoting)
- Valheim's music shifts between calm, eerie and intense moods, with boss fights getting the biggest changes. — [GamesRadar/NME coverage of Valheim soundtrack](https://www.nme.com/news/the-official-soundtrack-to-valheim-has-been-released-3082828). The composer's sources of inspiration (Swedish folk and metal) are in the same coverage.
- Valheim fan mods change music by place: a boss track within 150 m, a shelter track inside a building, a track per biome, and a mode to turn music off. — [Thunderstore: Valheim Music Plus](https://thunderstore.io/c/valheim/p/Emberskald/Valheim_Music_Plus/v/1.13.0/), [TotemOfSongs](https://thunderstore.io/c/valheim/p/VKTR/TotemOfSongs/). Fan mods show what players ask for: a "music off" option and music tied to place.
- Godot 4.3 added three music resources: `AudioStreamInteractive` (clips plus a transition table; changes can happen on the next beat, next bar, or when a clip ends), `AudioStreamPlaylist`, and `AudioStreamSynchronized` (plays several streams in sync with a volume for each). — [Godot 4.3 release notes](https://godotengine.org/releases/4.3/index.html); class reference [AudioStreamInteractive 4.3](https://docs.godotengine.org/en/4.3/classes/class_audiostreaminteractive.html) (marked "outdated" on the page, so check the current docs)
- For layered music that can also switch sections, a Godot forum answer says to put the `AudioStreamInteractive` inside the `AudioStreamSynchronized` as one of its synced streams. — [Godot forum: combining AudioStreamInteractive and AudioStreamSynchronized](https://forum.godotengine.org/t/help-combining-audiostreaminteractive-and-audiostreamsynchronized/100519). This thread is about Godot 4.5 and the answer is from users, not the Godot team.
- Mario Kart Wii-style layering is discussed in a Godot forum thread. — [Godot forum: layered music like Mario Kart Wii](https://forum.godotengine.org/t/creating-layered-music-like-in-mario-kart-wii/124374) (not read in detail)

### Inferences
- Start with zero music. Add music only for: the first boss-like threat, the big cave reveal, the first night in the dark, and a calm theme at the home base. Each place gets at most one track, and most of the time the game is silent except for sound effects.
- A simple adaptive plan that matches the Godot 4.3+ tools: one calm bed track and one tense track, both the same length and tempo. Use `AudioStreamSynchronized` so they stay in time, then fade the tense volume up when a monster is "alert" or "chase" (the states already in `src/combat/monster.gd`). Switch only on a beat or bar so it never sounds broken.
- Give each player a "music off" option in settings (fan mods show this is asked for). Co-op ready: each player's music is local only; the host decides the state (calm or tense) and everyone's game reads it. Nothing needs to go over the network except the state name.
- Because the owner wants recorded sounds only and no synth beeps, music should be real recorded instruments (a flute, a bowed string, a drum on a skin, a hand-played hammered dulcimer). Check any music against the "no synth" rule before using it.
- Ducking (lowering music while a voice line or big sound plays) was not covered by any source found. Plan it with a Godot audio bus and a volume tween, and test by ear. No source checked.

### Gaps
- No source found on the exact Valheim music system (layers, stems or triggers). The mood description is from press, not from the developer.
- No source found on the price of commissioning a composer for a small indie game, or on a list of CC0 music libraries with good survival/cave tracks. Kenney's "Music Jingles" was mentioned in the earlier doc. Freesound and OpenGameArt music still need a license check per file.
- Ducking and mixing recipes were not found in a reliable source.

---

## 2. Voice lines (dwarf grunts and barks)

### Takeaway
Deep Rock Galactic uses one shared voice for all dwarves and a small set of event-triggered lines. The lesson for us: few lines, one voice, play them only on real events, and keep rare lines rare. I found no GDC talk on DRG barks. The license risk for voice is not covered by any source yet.

### Cited Findings
- All four Deep Rock Galactic dwarves share the same dialogue, except for class-specific lines. Lines play when certain activities or events happen. — [DRG wiki: Voicelines](https://deeprockgalactic.wiki.gg/wiki/Voicelines)
- The DRG developers chose a single voice for all dwarves; the Q&A archive says the reasons were ease of production (not a theme about the dwarves). Passive banter lines were ruled out "for now". — [DRG Development Q&A archive, Season 1](https://deeprockgalactic.wiki.gg/wiki/Development_Q%26A/Archive_Season_1) (fan wiki, quoting developer Q&A)
- The "Karl" line began as a rare voice line with about a 1% chance of appearing. The community hunt for its meaning led to it being kept. — [DRG voice line coverage via search results, TheGamer](https://www.thegamer.com/deep-rock-galactic-loot-bug-dwarves-writing/) (secondhand)
- The "die like your mother did" line was dropped from the DRG auto-battler spin-off because it could upset some players. It stayed in the main game. — [PC Gamer](https://www.pcgamer.com/deep-rock-galactic-auto-battler-nixes-upsetting-die-like-your-mother-did-voice-line-so-as-to-not-remind-some-players-of-tragic-events-in-their-life)
- DRG's minimal writing is praised for getting players attached to the dwarves. — [TheGamer coverage](https://www.thegamer.com/deep-rock-galactic-female-dwarf/) (opinion piece)

### Inferences
- Give the dwarves one voice (ours or a hired actor's) and only a few lines: a hurt cry, an effort grunt (lifting, digging), a "found something" bark, a "help" call, a low-air warning, and a "thanks" for co-op. Each line is short, because short lines keep the game from feeling noisy.
- Limits on how often a line plays: a per-dwarf cooldown (for example 8–15 seconds), a cap of one line at a time per dwarf, and a rule that a line never plays during another line. The numbers are a starting guess, not from a source; tune them in play.
- Keep a rare joke line (like Karl) at about 1–2% chance, so it feels like a find. Keep sad or upsetting lines out of the everyday mix, following the DRG example.
- Co-op: when a player's dwarf speaks, the other players' games play that same line locally. Only the event name needs to be sent.

### Gaps
- No reliable source found on how often DRG plays barks or on its cooldown rules.
- AI voice licensing: no source was checked in this round. Before any AI-made voice is used, read the exact terms of the tool and get written permission for commercial use. Recording a real person (the owner or a friend) with a signed release is the simplest route. Treat any voice-cloning tool as "not yet checked" until the terms are read. (Not sourced; flagged for a separate check.)
- Cheap legal voice sources were not searched in this round (voice-acting marketplaces and CC0 voice clips).

---

## 3. Playtesting as a solo developer

### Takeaway
Watch silently, do not help, write down what players DO (not what they say), and test one or two things per session. Use free Steam Playtest for a larger test once the game is stable.

### Cited Findings
- The rule of observation-based playtesting is not to help the tester. The developer describes not answering questions so the session matches home play. — [Playtesting guide via search results: gtstu.com, How to Playtest Your Indie Game Without a Team](https://gtstu.com/playtest-indie-game-solo-developer/)
- Watch behavior more than words; resist explaining; before the session give a short 2–5 minute overview of the concept and what you want to learn, not how to play. — [Wayline playtest blog, unmoderated vs observed](https://www.wayline.io/blog/unmoderated-playtests-vs-observed) and [gtstu.com](https://gtstu.com/playtest-indie-game-solo-developer/)
- After the session, ask why the player made each choice. — [gtstu.com](https://gtstu.com/playtest-indie-game-solo-developer/)
- Test only one or two aspects per session; testing everything at once lowers feedback quality. — [gtstu.com](https://gtstu.com/playtest-indie-game-solo-developer/)
- For early mechanic tests, three to five testers can surface the most common problems. Free channels: Reddit r/playmygame, itch.io, Discord, with screen sharing. — [gtstu.com](https://gtstu.com/playtest-indie-game-solo-developer/) (practitioner advice, not research)
- A 2024 CHI PLAY paper notes little research on the specific playtesting problems indie developers face. — cited in the search results, but the paper itself was not opened; treat as a pointer only.
- Steam Playtest is free for developers and players. It uses a separate Playtest app linked to the main game, picks players at random from those who sign up, does not support sales, and is not meant to replace Early Access. Closed betas with free release keys are still supported. — [Steamworks Playtest docs](https://partner.steamgames.com/doc/features/playtest) (summary via search; English page is authoritative)
- Steam Next Fest build review checks that promised features work and that the game runs. It is not a full QA pass and will not catch most bugs. — [Steamworks Next Fest page](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest) (fetched)

### Inferences
- The owner's own play sessions and recordings already give a free watch-and-learn source. Keep the owner's rule about not helping: note where the player stops, asks, or goes quiet.
- Use Steam Playtest after the first real vertical slice (one full cave run from start to home base). Pick a fixed set of questions for each round (for example: "Can new players find the first ore?" or "Do they understand the hunger bar?").
- Telemetry (logging clicks or deaths to a file) and heatmaps were not researched in this round. A simple log of "time to first death", "time to first dig", and "quit point" would be the first step. No source checked.

### Gaps
- No source on Godot telemetry setup or heatmap tools.
- Steam Playtest status is unclear: 2020 coverage called it beta; a later Game Developer article says it opened to all developers. Check the live Steamworks page before planning around it.

---

## 4. Scope control for a small team

### Takeaway
Pick the core experience (dig, survive, build a home with friends), cut everything outside it, and keep a "parking lot" list for later ideas. Solo developers have no QA team and must cut more.

### Cited Findings
- Finishing a smaller game beats endlessly polishing a big one. One developer cut everything not core to the experience to get a four-month window to finish *The Ramp*. — [Game Developer postmortem: The Ramp](https://gamedeveloper.com/design/postmortem-i-the-ramp-i-)
- A developer who did everything themselves had to cut many features. As a solo developer you have no QA department. — [Game Developer / gamedev.net indie advice, "mistake doing too much" part 3](https://gamedev.net/news/4388-mistake-doing-too-much-in-indie-game-dev-part-3/) (opinion)
- A failed Metroidvania postmortem blamed a sprawling design (several biomes, complex skill trees, branching story, hand-drawn animation). Its fix is a "parking lot" document for extra ideas and an honest cut list. — [Wayline blog, scope creep postmortem](https://www.wayline.io/blog/scope-creep-indie-dream-postmortem)
- Counter-example: the Dead State postmortem says the team cut no major features and the game took longer than promised. — [Game Developer: Dead State postmortem](https://gamedeveloper.com/business/postmortem-doublebear-s-i-dead-state-i---controlling-scope-in-an-rpg)

### Inferences
- Write the "core loop" in one sentence and check every new idea against it. For us: dig, find ore, build a shelter, survive a night, play with friends.
- Keep a parking-lot file for ideas (the existing `FEEDBACK.md` open list can serve this role).
- Set feature-freeze milestones before the Next Fest demo build (see section 5).
- Using the owner's "8/10 is good for now" rule already fits the cut-to-finish advice.

### Gaps
- No survival-game postmortem with hard numbers on scope or time was found. The sources above are blog posts and forum posts, so treat them as anecdotes.

---

## 5. Steam Next Fest and demo strategy

### Key date check for February 2027 (official Steamworks page, fetched)
- Registration deadline: **January 10, 2027, 11:59 pm PST**.
- Demo build and store page submitted for review by **January 18** to be live at the start of Press Preview. Store page review is required even without a separate demo page.
- Required review items: **February 1** (preparation for Next Fest, if not done for Press Preview).
- Trailer opt-out deadline: **February 11** (also Press Preview start, 10 am PST).
- Fest runs **February 22 10 am PST to March 1 10 am PST**. Demo must be set live (or opted out) before February 22 at 10 am PST. Valve encourages releasing it at least 30 minutes before the fest starts.
- Only games with a **publicly playable** demo can appear. One Next Fest per game; a game that joins one cannot join later editions. The next edition after February is **June 2027**.
- Submission deadline rule: 5 weeks before the fest if the demo releases before Press Preview; 3 weeks before if it releases before the fest. (Feb 22 minus 5 weeks = Jan 18; minus 3 weeks = Feb 1. This matches the dates above.)
- Third-party sites list other dates (demo build Jan 25, trailer pull Jan 18). These were not confirmed on Steamworks. Use the Steamworks page only.
- Sources: [Steamworks Feb 2027 Next Fest page](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027) (fetched), [Steamworks Next Fest guidance](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest) (fetched). Registration deadline also in [search summary: Steamworks](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027).

### Official rules on the demo itself (fetched)
- No requirement on demo length, exclusivity or newness.
- The game must have a publicly playable demo by the start of the fest.
- A build review checks that promised features exist and that the game runs. No more build review after an update, so the owner must make sure updates do not break the demo.
- Leaving the demo up after the fest is encouraged but optional. Valve notes that players are upset when demos vanish right away.

### Takeaway
The February 2027 deadline means a demo build is needed for review by **January 18, 2027** (about 8 weeks from today). Decide now whether the demo can be stable by then, or aim for the June 2027 Next Fest. Only one fest per game.

### Cited Findings: demo advice
- Chris Zukowski (How to Market a Game): have the demo ready well before a Next Fest, and keep it up long term. In his Mob Factory example, streamers kept finding the game after the fest ended. — [How to Market a Game (search summary): howtomarketagame.com](https://howtomarketagame.com/2023/09/11/three-inspiring-marketing-success-stories/) (summary of his writing; the wording was not read in full)
- Zukowski says demos open two channels: streamers and festivals. — [search summary of his advice](https://howtomarketagame.com/2023/09/11/three-inspiring-marketing-success-stories/)
- Zukowski advises releasing the demo after reaching about 30,000 wishlists if possible. This comes from a third-party LinkedIn summary, not from his own page. — [LinkedIn summary](https://bg.linkedin.com/in/javier-moreno-gaona) (secondhand; do not quote as his words)
- Zukowski notes demos can underperform for games built on a gimmicky, one-off mechanic. — [search summary](https://howtomarketagame.com/2023/09/11/three-inspiring-marketing-success-stories/) (secondhand)
- GameDiscoverCo: in a 2020 analysis, median wishlist growth during Next Fest was about 421% above normal, with wishlist quality at about 0.75 of normal. — [GameDiscoverCo via Game Developer, "Steam demo showcases officially good for sales"](https://www.gamedeveloper.com/business/steam-demo-showcases-officially-good-for-sales-) (2020 data, old)
- GameDiscoverCo (October 2025 report): games launched with more than 25,000 wishlists have a median first-week wishlist-to-sales conversion of 0.15x. Games priced above $10 have a lower median of 0.10x. Conversion is not falling over time; getting wishlists is getting harder. — [GameDiscoverCo via gamedevreports](https://gamedevreports.substack.com/p/gamediscoverco-the-state-of-steam) and [Gameworldobserver, wishlist-to-sales benchmark](https://gameworldobserver.com/2024/12/06/wishlist-to-sales-ratio-steam-gamediscoverco-benchmark) (secondary reports of GameDiscoverCo; original newsletter not fetched)
- Demo length claims conflict and come mostly from marketing or tool vendors: 15–30 min ([Steam Page Analyzer, blog](https://www.steampageanalyzer.com/blog/how-long-should-a-steam-demo-be)), 20–40 min, 15–20 min, and "median playtime near 14 min" in one source. One source suggests tracking completion; if fewer than 40% finish, the demo may be too long. — [search summary of vendor blogs](https://www.steampageanalyzer.com/blog/steam-demo-best-practices) and [presskit.gg](https://presskit.gg/field-guides/how-to-build-game-demo). Treat as unverified.
- Ending advice: end on a hook (a cliffhanger or a "to be continued" cave), not a simple stop after level one. A counterpoint says most players leave before the hook. — [search summary, vendor blog](https://bugnet.io/blog/how-to-run-a-successful-steam-next-fest-demo) (opinion)

### Inferences
- Demo plan for us: a 15–25 minute slice (start cave, first ore, first night, first co-op join, a clear "next" hook at a new cave). Keep the length near the vendor middle and measure how many players reach the hook in Steam Playtest or the owner's sessions.
- Put the demo live early (not on the day of the fest) if Zukowski's advice holds, because streamers and festivals need time.
- Wishlist target: no solid number. The 30k figure is secondhand; the GameDiscoverCo numbers mean wishlists are hard to get. Track our wishlists weekly from the store page once it is live.
- Store page: the trailer must be ready before the February 11 opt-out and Press Preview. Use the first 10 seconds for the main hook (a dwarf digging into a glowing cave) since Shorts already show that.

### Gaps
- No confirmed numbers on demo-to-wishlist conversion for Next Fest in 2025–2026 (the GameDiscoverCo numbers found are from 2020 or secondary).
- No source on Steam Deck demo performance or Steam Deck badge rules was checked.
- Whether demos stay after the fest is "encouraged", not required (see official rules above).
- Demo length: no reliable benchmark.
- No capsule-art guidance was checked.

---

## Actions for this game (ranked)
1. **Decide the fest now.** Feb 2027 needs a stable demo by Jan 18 (review) and registration by Jan 10. If the demo is not stable by early January, aim for June 2027.
2. **Music:** start with no music. Add two-track adaptive music only at 2–3 big moments, using `AudioStreamSynchronized` (Godot 4.3+). Add a "music off" option.
3. **Voice:** one voice, 4–6 short event lines per dwarf, per-dwarf cooldown, rare lines at 1–2%. Check voice sourcing legality first (a separate check is needed).
4. **Playtest:** run a silent watch session with the next build; test one or two things per session; use Steam Playtest later for wider tests after checking its live status.
5. **Scope:** write one-sentence core loop; create a parking-lot list; set a feature freeze before the demo build.
6. **Demo:** 15–25 min slice with a clear cave hook; release early; keep it up after the fest.
7. **Reverb:** the earlier doc's plan (built-in `Area3D` reverb bus) still holds. Check the Godot 4.7 class reference for the exact reverb property names, because the 4.7 docs snippet I saw did not show them (conflict; see gaps in the earlier doc).

## Source conflicts and caveats (for the writer)
- Next Fest dates: the Steamworks Feb 2027 page is authoritative; third-party sites list different dates (Jan 25, Jan 18 trailer pull). Not used.
- Next Fest demo length: vendor numbers conflict (14 to 40 min). No reliable benchmark.
- Zukowski's 30k wishlist threshold is secondhand (LinkedIn summary), not his own words.
- GameDiscoverCo Next Fest growth data is from 2020; the 2025 wishlist-to-sales figure is for launch week, not demo conversion.
- Godot 4.3 `AudioStreamInteractive` docs page is marked outdated; behaviour may differ in 4.7.
- Steam Playtest status: 2020 "beta" vs later "open to all"; check live docs.
- Valheim's adaptive music mechanism is not confirmed by the developer; only press descriptions and fan mods were found.
