# Steam "Coming Soon" page: the plan (written Nov 17, 2026, on the Mac)

**Goal:** a public Steam page with a working **Wishlist** button **before the first video is posted**
(videos 049-055 in the EQT Social Media repo end with "wishlist on Steam").
The owner does the Steam steps himself on the gaming PC. Claude on the PC makes the pictures, screenshots and texts.

## Steam's rules (Steamworks docs, checked Nov 17, 2026)
- **$100 fee per game.** You get it back after the game earns $1,000. Pay it in Steamworks: "Create new app".
  It's the same Steamworks account as Deep Rise.
- **Store review takes 3-5 business days.** Submit at least 7 days before you want the page live.
- The page must be public as "Coming Soon" for **at least 2 weeks** before release. The release itself can only
  come 21 days or more after the fee is paid.
- The page may only show features that will be in the game at launch.
- Capsule pictures must show a **readable game title or logo**.
- **AI disclosure:** Steam's Content Survey asks whether the game uses AI-generated content. **Answer yes and describe it
  honestly** (text below). A wrong answer can get the page pulled.

**Realistic timeline:**

| Day | What happens |
|---|---|
| 0 | Name picked, fee paid |
| 1-3 | Pictures and texts made, page filled in |
| 3 | Submitted for review |
| 6-10 | Page live, wishlists open |
| Then | Post video 049 |

## Lessons from Deep Rise (forecast report, EQT Social Media `reports/`)
- Deep Rise's capsule was a dark, low-contrast cave with an ogre, so people misread the genre. **This capsule must be bright and
  readable at a small size** and show a dwarf + a glowing cave + digging/building (genre at a glance).
- **Plain words** in the description, not jargon.
- **Fewer, accurate tags**, not as many as possible.
- **Gameplay in the first second** of every video and trailer.
- Have the page ready **before** sending people to it.

---

## Step 1 (owner): pick the name. Nothing else can start before this.
The working name is "Dwarf Game". Searches on Nov 17 found:
- **No Steam game called "Hollowbeard" or "Undermoss".**
- "Delvers" is taken (a co-op dungeon game).
- "Beardstone" is very close to "Beard of Stone".

Before paying, search Steam for the final name, plus a general web search and a trademark search
(free: tmsearch.uspto.gov, euipo.europa.eu).

## Step 2 (owner, 10 min): create the app
1. Log in to partner.steamgames.com yourself (Claude never types passwords).
2. Pay the $100 fee for a new app. Write down the **App ID**.
3. Tell the code Claude the App ID. Co-op through Steam (GodotSteam) needs it. An App ID is not a secret, so it may
   go in the repo.

## Step 3 (Claude on the PC): make everything below, then the owner checks it

### 3a. Pictures (exact sizes)
| What | Size (px) | Note |
|---|---|---|
| Header capsule | 920 × 430 | Shown most often (store, search). Title must be readable. |
| Small capsule | 462 × 174 | Shown in lists. Mostly title, tiny art. Test it at 50% size. |
| Main capsule | 1232 × 706 | Front page features. |
| Vertical capsule | 748 × 896 | Seasonal sales. |
| Screenshots | 1920 × 1080, **at least 5** (aim for 8) | From the real game, no text on top. |
| Page background | 1438 × 810 | Optional. A soft, dark cave picture. |
| Library: capsule 600 × 900, hero 3840 × 1240, logo 1280 × 720 | | Needed for release, not for Coming Soon. Can wait. |

How to make the capsules:
- The background art is a ChatGPT picture (the owner allows ChatGPT pictures) in the game's own hand-painted
  style: a stout dwarf with a lantern in a big glowing cave, crystals and roots, star-dot ceiling.
- **Never** copy another game's art.
- The **title logo** is made separately (chunky carved-stone letters), so the text is clean and sharp.
- Each capsule size gets its own layout; don't just shrink the big one.
- Log every picture in `CREDITS.md`.

Prompt to start from (add the name):
> Game key art for a 3D survival game about dwarves living underground. A short, stout dwarf with a big red braided beard
> holds up a lantern at the edge of a huge cave. The cave ceiling is covered in tiny glowing star dots, with blue and green
> crystals and giant roots. Hand-painted stylized look, chunky shapes, warm lantern light against cool cave light, bright and
> readable, NOT dark or muddy. Leave clean empty space at the top for the game title. No text. Wide format.

Screenshots to take on the PC (photo mode / F12 at 1920×1080, muted run):
1. The first cavern with the star ceiling and light snakes.
2. Digging a tunnel with the lantern.
3. A Delver's Shack house with a round door.
4. A Stonehold or Hearthbrick build.
5. A Rock Beetle charging (red eyes, glowing back).
6. Crafting at the workbench / stations.
7. Two or more players in co-op.
8. The bag/crafting menu.

Show only what really works in the game today. No mock-ups.

### 3b. Texts (draft below; Claude checks every line against the real game before it goes in)
**Short description** (Steam's limit is about 300 characters):
> Survive deep underground as a stout dwarf. Dig through living rock, light the dark with glowing crystals, build a
> home of wood, stone or brick, and fight the creatures that live below, alone or with up to 3 friends.

**About this game** (long description):
> The surface is far above. Down here it's you, your lantern and the dark.
>
> **Dig anywhere.** Carve tunnels through moss, stone and copper. Every cave is different, and some ceilings glow
> like a night sky.
>
> **Keep the light alive.** Your lantern runs on glowing crystals. Run out, and the dark gets close.
>
> **Build your home.** Three building styles: a rough log shack, a stone keep, or a warm brick cottage. Snap walls,
> floors, round doors and roofs together.
>
> **Craft and survive.** Gather roots, mushrooms and ore. Smelt copper, cook stews, make better tools and armour.
>
> **Fight what lives below.** Rock Beetles that charge, Cave Bats that dive, Rock Snails that hide in their shells.
>
> **Play together.** Up to 4 players in online co-op.
>
> *In development. Follow the build on TikTok, YouTube and Instagram.*

Before submitting, check that each line is TRUE in the current game: co-op, 3 styles, cooking, armour and all 3 monsters.
Cut any line that isn't.

**AI disclosure (Content Survey), draft:**
> The developer does not write code and builds the game with the help of AI tools (Claude). Game code and 3D models
> are generated by AI under the developer's direction, and every model is built and reviewed in Blender. Concept
> pictures and some textures were made with AI image tools and then edited. Sounds come from real recordings
> (CC0 libraries), edited. No AI generates content while the game is running.

(Claude on the PC: adjust this to what is actually true from `CREDITS.md` before the owner pastes it.)

**Tags** (pick about 12, in this order):
- Survival, Open World Survival Craft, Base Building, Crafting, Online Co-Op
- Exploration, Underground, Fantasy, Stylized, Sandbox
- Building, Mining

**Other fields:**
- Genre: Action, Adventure, Indie, Simulation, Early Access (only if it launches as Early Access).
- Languages: English (interface + subtitles; no voice).
- Release date: "Coming soon" (or "2027" once there's a plan).
- System requirements: Windows 10/11 64-bit. Measure minimum and recommended on the PC with the autopilot FPS report;
  don't guess.
- Mature content: none (mild fantasy violence against creatures).

### 3c. Trailer (optional for Coming Soon, but pages with one convert better)
- 30-60 s of real gameplay.
- Gameplay in the first second.
- Digging, the star ceiling, building, a beetle charge, then co-op.
- End on the title and "Wishlist now".
- Recorded with the game's own OBS recorder.
- Music: CC0, logged in CREDITS.md.
- It can be added after the page is live.

## Step 4 (owner): fill in and submit
1. In Steamworks → the app → "Edit Store Page": paste the texts, upload the pictures and screenshots, set the tags,
   fill in the Content Survey (with the AI disclosure).
2. Steamworks shows a checklist of what's missing; fix everything it lists.
3. Press **Submit for review**.
   - Claude can fill text fields in Chrome while you're logged in.
   - Only you press Submit.

## Step 5: when the page is live
- Check that the **Add to Wishlist** button works (log in with a second account or ask a friend).
- Put the Steam link in the TikTok / Instagram / YouTube bios.
- Change every video's last line to end with "Wishlist [name] on Steam" (EQT Social Media `video-scripts/dwarf-series-049-055-plan.md`).
- Start posting video 049.

## Checklist
- [ ] Name picked and searched (Steam, web, trademark)
- [ ] $100 fee paid, App ID written down and given to the code Claude
- [ ] Logo + 4 capsules (920×430, 462×174, 1232×706, 748×896)
- [ ] 8 real screenshots at 1920×1080
- [ ] Short + long description checked against the real game
- [ ] AI disclosure filled in honestly
- [ ] Tags, languages, system requirements (measured), release date text
- [ ] Submitted for review (owner presses Submit)
- [ ] Page live, wishlist button tested
- [ ] Bio links + video endings updated, then post 049

---

## Prompt to paste into Claude on the gaming PC
```
Pull main (git pull --ff-only). Read docs/steam/STEAM-PAGE-PLAN.md. We're making the Steam "Coming
Soon" page so people can wishlist the game before my videos go out. The game's name is: <NAME>.
I will log in to Steamworks and pay the fee myself; never type my password.

Do steps 3a-3c:
1. Logo: chunky carved-stone title letters for <NAME>.
2. The 4 store capsules at the exact sizes in the plan, each laid out for its size, bright and
   readable small. Key art from a ChatGPT picture in our hand-painted style; log it in CREDITS.md.
   Show me the capsules at real size and at 50%.
3. 8 real screenshots at 1920x1080 from the game (muted runs), following the list. No text on them,
   no mock-ups.
4. Check every line of the store texts and the AI disclosure against what's really in the game today
   (and CREDITS.md). Cut anything not true. Measure minimum and recommended system requirements
   with the autopilot FPS report.
5. Put everything in docs/steam/page/ (pictures + a texts.md I can copy from) and show me.
6. After I paste the App ID, add it where GodotSteam needs it.
Journal everything, commit and push.
```
