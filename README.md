# Arcaneum

A Roblox game synced with [Rojo](https://rojo.space/), so the game's code lives here in
this git repo instead of only inside a `.rbxl` file.

## Project layout

```
default.project.json          # Tells Rojo how src/ maps into the Roblox DataModel
rokit.toml                    # Pins the exact Rojo version for everyone on the team
src/
  ReplicatedStorage/Shared/   # Code shared by server and client
  ServerScriptService/Server/ # Server-only code
  StarterPlayer/StarterPlayerScripts/Client/ # Client-only code
```

## One-time setup (Windows)

1. **Install Rokit** (toolchain manager) if you haven't already — you already did this.
   After installing, **close and reopen PowerShell** so the updated `PATH` takes effect
   (the installer prints this, but it's easy to miss). Verify with:

   ```powershell
   rokit --version
   ```

2. **Install the pinned tools for this repo.** From the repo root in PowerShell:

   ```powershell
   cd path\to\Arcaneum
   rokit install
   rojo --version
   ```

   `rokit install` reads `rokit.toml` and installs the exact Rojo version this project
   uses, and adds a `rojo` command alias just like it did for `rokit`.

3. **Install the Rojo Studio plugin** (one-time, lets Studio talk to `rojo serve`):

   ```powershell
   rojo plugin install
   ```

   Alternatively, install "Rojo" from the Roblox Creator Store inside Studio
   (Toolbox → search "Rojo").

## Everyday workflow: syncing this repo into Studio

1. From the repo root, start the sync server:

   ```powershell
   rojo serve
   ```

   It will print something like `Rojo server listening on port 34872`. Leave this
   running in a terminal while you work.

2. Open (or create) your place file in **Roblox Studio**.

3. In Studio, open the **Rojo** plugin panel (Plugins tab → Rojo icon).

4. Click **Connect**. It should find the local server automatically (port `34872`).
   Once connected, everything under `src/` will appear in the Explorer, and any file
   you save on disk syncs into Studio live.

5. Edit code in your editor (e.g. VS Code with the "Rojo" extension for syntax help),
   save, and watch it sync into Studio automatically. Edit non-script things
   (parts, UI layout, etc.) directly in Studio as usual — Rojo only manages the
   folders listed in `default.project.json`.

6. When you're done, save your place file in Studio as normal
   (`.rbxl`/`.rbxlx` is not committed to git — see `.gitignore` — the code in `src/`
   is the source of truth).

## Adding new code

- Shared modules (used by both server & client): `src/ReplicatedStorage/Shared/`
- Server-only scripts: `src/ServerScriptService/Server/`
- Client-only scripts: `src/StarterPlayer/StarterPlayerScripts/Client/`

To map additional Roblox services (e.g. `StarterGui`, `Workspace`, `Lighting`), add
an entry to `default.project.json` pointing `$path` at a new folder under `src/`.

## Architecture (Phase 1: core + magic system)

The game uses a small custom framework instead of a third-party library like Knit:

- **`Shared/Framework/Net.lua`** — creates/fetches `RemoteEvent`/`RemoteFunction` instances
  under a shared `ReplicatedStorage/Remotes` folder, so server and client always agree on
  where to find them.
- **`Shared/Framework/Loader.lua`** — scans a folder of `ModuleScript`s, `require`s each one,
  calls `:Init()` on all of them, then `:Start()` on all of them. Server `Services` and
  client `Controllers` both use this — see `Server/Main.server.lua` and
  `Client/Main.client.lua`.
- Adding a new server feature = drop a `ModuleScript` with optional `:Init()`/`:Start()`
  methods into `src/ServerScriptService/Server/Services/`. Same idea for client features
  under `src/StarterPlayer/StarterPlayerScripts/Client/Controllers/`.

**Stats & mana** (`Shared/Combat/StatFormulas.lua`, `Server/Services/PlayerDataService.lua`):
mage/combat/character levels are derived from XP totals (no manual level-up step). Mana
regenerates over time and scales with mage level. Data is saved to a DataStore per player
(falls back to in-memory only if DataStores aren't available, e.g. running in Studio without
"Enable Studio Access to API Services").

**Spell system** (`Shared/Spells/SpellWords.lua`, `Shared/Spells/SpellBuilder.lua`,
`Server/Services/SpellService.lua`): a spell is a "word" (element — `Ignis`, `Glacies`,
`Fulgur`, `Terra` for now) combined with three tunable parameters, each clamped 1-5:

- **Intensity** — scales damage and mana cost.
- **Quantity** — how many times the spell fires in a burst (extra casts, extra total mana).
- **Projectile count** — how many projectiles fire per cast, spread in a cone.

The server (`SpellService`) is authoritative: it validates mage level, cooldown, and mana
cost before spending mana, spawning projectiles, and granting mage/combat XP. The client
(`Controllers/SpellController.lua`) only sends the cast request and plays a cosmetic flash
for instant feedback — it never decides damage or cost itself.

A `TrainingDummy` (`Server/Services/TestDummyService.lua`) is spawned near the origin, built
entirely out of Studio primitive parts + a `Humanoid` for health/damage, so there's something
to test spells against; it respawns a few seconds after being defeated.

### Trying it out in Studio

Once connected via the Rojo plugin (see above):

1. Press Play (F5) in Studio.
2. Press **1**, **2**, or **3** to select a spell (Ignis / Glacies / Fulgur) — the hotbar at
   the bottom of the screen highlights the selected slot with a white outline.
3. **Left-click** anywhere to cast toward that point. Watch the mana bar drop, and the
   training dummy (a grey block figure) take damage and eventually fall over and respawn.

This is a deliberately minimal slice — no custom spell builder UI yet, no visuals beyond a
colored ball. It exists to prove the server-authoritative loop (mana → cast → damage → XP)
works end-to-end before more systems are layered on top.

## Destructible world (Phase 2)

**`Server/Services/DestructionService.lua`** is a generic component: any `BasePart` tagged
`"Destructible"` (via `CollectionService`) with a numeric `Health` attribute can take damage
through `DestructionService:Damage(part, amount)`. When health drops to 0 the part shatters
into small debris chunks and disappears. Parts can share a `StructureId` attribute to belong
to the same building — a single hit strong enough to be "overkill" (health-relative, tunable
per part via `ShatterOverkillMultiplier`) demolishes every part sharing that `StructureId` at
once, which is how a high-level beam should be able to level an entire house instead of just
breaking the one panel it touched.

`SpellService` now routes any projectile hit that isn't a `Humanoid` through
`DestructionService:Damage`, so spells damage destructible scenery automatically.

**`Server/Services/TestHouseService.lua`** spawns a small test house near the training dummy,
built entirely from Studio primitive parts: 4 walls (200 HP each, with the west one split into
left/right/sill/lintel segments around a real window opening), a roof (150 HP), and one
low-health window (15 HP) filling that opening. A beginner-level Ignis/Glacies hit (with the
current fixed Intensity 2 default) breaks the window in one shot but barely dents a wall —
matching the "day-one player can break a window, high-level player can level the house" goal.

**Testing shortcut:** point your mouse at anything and press **P** to deal 1000 fixed damage
to it instantly (`Server/Services/DebugService.lua` + `Client/Controllers/DebugController.lua`)
— enough to one-shot the training dummy or, if the hit is strong enough relative to a part's
health, trigger the whole-structure overkill collapse on the test house. This bypasses
mana/cooldown/level entirely and is temporary; it'll be folded into the real admin panel
later. Use it to test destruction without waiting on the real spell-customization UI.

Known simplification to revisit later: spell intensity/quantity/projectile count are
hardcoded on the client for now — the real spell-customization UI comes later, along with
gating higher intensity behind mage level so low-level players can't already one-shot a wall
with a real spell (only the debug key can do that today).

## Admin panel (testing tool)

**`Server/Services/AdminService.lua`** + **`Client/Controllers/AdminController.lua`**: a
panel to set gold, silver, mage/combat/character level, and refill mana instantly, so you
don't have to grind XP manually to test level-gated content (like the Fulgur/Terra spells,
which need mage level 3/5).

- **Access**: automatically available to everyone while testing in Studio. On a published
  server, only Roblox UserIds listed in `Shared/GameConfig.lua`'s `AdminUserIds` get it — add
  your own UserId there before publishing if you want admin access outside Studio. The server
  re-checks this on every command; the client UI only ever appears for authorized players, but
  authorization is never trusted from the client.
- **Usage**: press **F6** to toggle the panel (top-left) — chosen to avoid colliding with
  Studio's own F9 developer console. Type a number next to a field and
  click **Set**. Setting a level directly sets the underlying XP total to match that level's
  threshold (`StatFormulas.XPForLevel`), so mage level changes also matter for spell level
  gates immediately.

## Law & bounty system (Phase 3)

**`Server/Services/WantedService.lua`** tracks a 0-5 "wanted level" (star rating) per player,
GTA/Cyberpunk-style, that decays slowly over time if you stay out of trouble. It's the
consequence layer on top of destruction and combat:

- **Property damage** — any hit that breaks a `Destructible` part (via
  `DestructionService`) fines the player (Silver for a normal break, a much bigger Gold fine
  plus a 2-star jump if it triggers a whole-structure collapse) and adds wanted level.
- **Civilian harm** — hitting a `Humanoid` tagged `"Civilian"` adds wanted level (more if the
  hit kills them). Hitting the training dummy does **not** count — it's tagged as a practice
  target, not a civilian.
- **`Server/Services/TestCivilianService.lua`** spawns a passive test civilian NPC (green,
  built the same way as the training dummy via the new shared
  `Shared/NPC/BlockyHumanoid.lua` builder) near the test house, so there's something to test
  the civilian-harm path against.

**`Server/Services/LawEnforcerService.lua`** is the "the law responds" half: the moment a
player's wanted level goes from 0 to something, an enforcer NPC spawns near them and homes in
to attack — its health and damage scale up with the player's star level, so a 4-5 star player
faces a genuinely tougher enforcer than a 1-star one. The enforcer despawns when defeated or
when the player's wanted level decays back to 0. Its "AI" is intentionally minimal for now (it
glides straight at the player with no obstacle avoidance) — a real pathfinding-based enemy AI
is a separate future system, this just proves the difficulty-scaling loop works.

A 5-star indicator (`Client/Controllers/WantedController.lua`) in the top-right corner fills
in gold stars as your wanted level rises.

### Trying it out

1. Hit any part of the test house (wall, window, roof) — any `Destructible` break fines you
   and nudges your wanted level up a little.
2. Use the **P** debug-damage key (or a real spell) on the green **TestCivilian** NPC near the
   house — this adds much more wanted level than property damage, and killing it adds even
   more.
3. Watch the star indicator (top-right) fill in, and a blue enforcer block should appear and
   start closing in on you, hitting you on contact.
4. Stop committing crimes and wait — wanted level decays automatically over time, and the
   enforcer disappears once it hits 0.
