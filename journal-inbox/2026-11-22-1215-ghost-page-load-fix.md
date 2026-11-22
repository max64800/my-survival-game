# Ghost page wouldn't load on claude.ai (Nov 22, 2026)

**What happened:** The owner opened the Dungeon Ghosts 3D page and got "Couldn't load the ghost: Failed to load buffer data:...".

**Why:** The ghost model files carry their 3D data packed inside as a long text code (a "data link"). On Claude's own computer the page could read it, but the published claude.ai page is not allowed to open data links (a safety rule there).

**Fix:** The page now unpacks that text itself: it turns the code back into raw bytes, puts the model together in memory, and hands it to the 3D viewer directly, so no data link is ever opened (`unpack()` in `tools/dungeon_pages/ghosts_page.html`).

**Claude's mistake:** I only checked the page on my local test server before publishing, not on the real claude.ai page. Now I check the published page too; it showed the ghost fine.
