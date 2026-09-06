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

**Fixed:** the enforcer's head used to stay frozen in place while its body chased you (both
parts were positioned once at spawn and never re-synced). `Shared/NPC/BlockyHumanoid.lua` now
exposes `BlockyHumanoid.SetCFrame(model, cframe)`, which moves the head along with the torso —
`LawEnforcerService` uses it instead of setting `Torso.CFrame` directly.

## Terrain destruction (Phase 3)

**`Server/Services/TerrainGenerationService.lua`** sculpts real Roblox voxel `Terrain` for the
whole test area: a flat grass ground plane (`Terrain:FillBlock`) so players stand on actual
terrain instead of Studio's plastic `Baseplate`, plus a mountain (`Terrain:FillBall`) off to the
side for a bigger destruction target. It also destroys any `Baseplate` part it finds in
`workspace` at game start — this only affects the live Play session (Studio's Edit-mode place
file is never touched), so it's safe to run every time. The flat ground is filled *before* the
mountain specifically, since doing it the other way around would slice a flat grass shelf
through the mountain's base wherever they overlap.

**`Server/Services/TerrainDestructionService.lua`** carves craters into that terrain by
filling a ball of `Air` at the impact point — the crater radius scales with the damage dealt
(clamped between 1 and 15 studs), so a normal spell barely chips the rock while a very large
hit (like the **P** debug key) can punch a real hole or tunnel through it. This is a separate
system from `DestructionService` because terrain isn't made of discrete parts with health —
Roblox terrain is voxel-based and has its own carve/fill API.

Both `SpellService` and the debug damage key now check for `workspace.Terrain` specifically
(terrain isn't a `BasePart`, so it can't go through the same code path as houses/NPCs) and
route hits to `TerrainDestructionService:Carve(position, damage)` instead.

### Trying it out

The test mountain is roughly 65 studs east of the house (`Vector3.new(40, -5, 0)`, radius 25).
Walk over to it and hit it with a spell, or aim the **P** debug key at it — you should see a
crater appear where you hit, roughly proportional to the damage. Repeated big hits in the same
spot will start tunneling through the mountain.

Known limitation: crater size currently only depends on flat damage number, not on mage level
directly — once the real spell-customization UI exists (letting players actually pick high
intensity/projectile counts, gated by level), a high-level player naturally deals enough
damage per hit to carve caves, while a beginner's small hits stay cosmetic dents, matching the
original goal without needing a separate level check here.

## Economy (Phase 4)

Two currencies, matching the design goal that **1 Gold = 10 Silver**:

- **Earning it for real**: defeating the `TrainingDummy` now pays out Silver and Character XP
  (`Server/Services/TestDummyService.lua`) instead of currency only being reachable through the
  admin panel. `SpellService` and the debug damage key tag whichever Humanoid they hit with a
  `LastDamagedByUserId` attribute right before dealing damage, so any NPC's `Humanoid.Died`
  handler can look up who gets credit for the kill — the same pattern will work for future
  enemies without needing a whole combat-log system yet.
- **`Server/Services/EconomyService.lua`** handles converting between the two currencies
  (`ExchangeCurrency` remote, server-validated both ways — can't convert more than you have).
- **`Server/Services/ExchangeKioskService.lua`** spawns a physical kiosk (a wood-colored block
  with a `ProximityPrompt`) near the test house so the exchange has a place in the world rather
  than being a hidden remote. Walk up to it, hold **E** ("Exchange Currency"), and a small panel
  lets you convert 10 Silver → 1 Gold or 1 Gold → 10 Silver.
- **`Client/Controllers/CurrencyController.lua`** shows your current Silver/Gold in the
  top-left corner at all times.

This intentionally stays a currency-only exchange for now — a real shop with purchasable items
(cosmetics, housing upgrades) needs those systems to exist first, so it's scoped out until
Phase: Characters & Cosmetics and Phase: Housing land.

### Trying it out

1. Defeat the `TrainingDummy` — you should see your Silver count (top-left) go up, along with
   a small burst of Character XP.
2. Walk to the wooden kiosk near the house, hold **E**, and try both conversion buttons —
   watch Silver and Gold trade at the 10:1 rate. Try converting more Gold than you have; nothing
   should happen (the server silently rejects it).

## Quests & campaign (Phase 5)

Both share one system (`Shared/Quests/QuestDefinitions.lua` + `Server/Services/QuestService.lua`)
since a story chapter and a side quest are really the same shape (an objective, a target count,
a reward) — they're just gated differently:

- **Side quests** need to be accepted. `Server/Services/QuestGiverService.lua` spawns a yellow
  glowing marker near the house — hold **E** ("Accept Quest: Pest Control") to accept
  **Pest Control** (defeat 3 training dummies). Progress is tracked automatically as you fight;
  finishing grants Silver + Character XP and clears the slot so you can accept it again.
- **Story quests** run automatically in the background, one at a time, in a fixed order — no
  accepting needed. You start on **Chapter 1: The Awakening** (reach Mage Level 2); finishing it
  unlocks **Chapter 2: Trial by Combat** (defeat 5 dummies) automatically. This is the scaffold
  for the main campaign — actual story content (more chapters, real objectives, narrative text)
  gets written into `QuestDefinitions.lua` later without needing new systems code.
- `Client/Controllers/QuestController.lua` shows both (when active) just under the currency HUD,
  top-left: `Story: Chapter 1: The Awakening (1/2)` and `Quest: Pest Control (0/3)`.

Known limitation: quest/chapter progress lives in server memory only (not saved to the
DataStore yet like currency/XP are) — it resets if the server restarts. Worth fixing in the same
pass where we do a broader save-data review.

### Trying it out

1. Walk to the glowing yellow orb near the house and hold **E** to accept Pest Control.
2. Defeat training dummies — watch the quest line's progress count up, and see it disappear
   with a reward once you hit 3/3.
3. Separately, raise your Mage Level (via the admin panel, F6, is the fastest way to test this)
   to 2 — Chapter 1 should complete on its own within a few seconds and Chapter 2 should appear.

## Dynamic housing (Phase 5)

`Server/Services/HousingService.lua` has 2 unclaimed plots west of the test house, each marked
by a glowing green pole. Hold **E** ("Claim Plot") and a personal house (built with the same
`Shared/Buildings/HouseBuilder.lua` used by the test house) spawns there, owned by you.

- **Nobody can destroy it for free**: anyone (including the owner) can still break it apart —
  destruction rules don't change based on ownership — but the **owner damaging their own house
  no longer triggers a fine or wanted level** (`SpellService`/`DebugService` check the part's
  `OwnerId` attribute before reporting to `WantedService`), matching "you can practice on your
  own house without the law showing up."
- **It rebuilds itself**: once every part of the house is broken, `HousingService` waits 30
  seconds and rebuilds a fresh copy at the same plot for the same owner — matching "the terrain
  resets that region" from the original design, simplified to a timer for now.
- **No stealing** isn't really testable yet since there's no shared inventory/storage inside the
  house — that's future work once an inventory system exists.

Known limitations: only 2 fixed-layout starter houses exist (no real building/placement tool
for choosing your own layout yet — that's a much bigger feature), and plot ownership isn't
saved to the DataStore either, so it resets on server restart just like quest progress.

### Trying it out

1. Walk to one of the green poles west of the house and hold **E** to claim it — a house appears
   and the pole disappears.
2. Break the house apart (spells, or the **P** debug key) — confirm your wanted stars/fines
   *don't* increase while you're breaking your own house.
3. Have it fully collapse, then wait ~30 seconds — a fresh copy should rebuild itself at the
   same spot.

## Character creation & classes (Phase 6)

Every character now spawns on a **plain default R15 body** instead of the player's own Roblox
avatar (`Server/Services/CharacterAppearanceService.lua`, via
`Humanoid:ApplyDescription(HumanoidDescription.new(), Enum.HumanoidRigType.R15)`) — a clean,
consistent base to build custom character art and the armor/clothing layer system on top of
later, regardless of what any given player happens to have equipped on their account.

On first join, a character is frozen (`WalkSpeed`/`JumpPower` set to 0) and a **Choose Your
Path** screen appears (`Server/Services/CharacterCreationService.lua` +
`Client/Controllers/CharacterCreationController.lua`), listing 4 classes from
`Shared/Character/CharacterClasses.lua`:

- **Fire / Ice / Storm Mage** — flavor and identity for now (stored, shown in the picker).
  They don't yet restrict which spell words you can cast — that's intentionally left for the
  spell-customization phase next, where "your magic type" will actually matter for what you can
  build.
- **Witch Slayer** — the one distinction enforced today: **no spellcasting at all**. Picking it
  hides the spell hotbar and mana bar client-side, and `SpellService` independently rejects
  `CastSpell` server-side regardless of what the client does. The promised stamina boost,
  bonus damage vs. mages, faster weapon XP, and the one-handed crossbow are not built yet —
  those need the weapon/combat systems this phase doesn't touch.

Your choice is saved permanently (`PlayerData.CharacterClass`, part of the same DataStore
profile as currency/XP) — you only see the picker once. Picking a class immediately unfreezes
your character.

### Appearance customization

Before the class picker, a **Customize Your Character** screen appears with a live 3D preview
(a `ViewportFrame` showing a real R15 rig built via
`Players:CreateHumanoidModelFromDescription`) and three color palettes — Skin, Shirt, Pants —
matching the reference World of Magic character creator's layout. This is intentionally
**color-only** for now: no hair styles, face options, or clothing textures, because those need
real Roblox catalog accessory/asset IDs that can't be verified without live catalog access.
Once real character art direction exists, that's where accessory options would slot in.

Picked colors save permanently too (`PlayerData.SkinColor/ShirtColor/PantsColor`, stored as
plain `{R,G,B}` tables since DataStores can't hold `Color3` values directly — see
`Shared/Util/ColorSerialization.lua`) and are re-applied by `CharacterAppearanceService` on
every respawn, so you only customize once. `SetAppearance` is server-validated against the
same palette the client picked from (`Shared/Character/AppearancePalette.lua`) — an
arbitrary/off-palette color is silently rejected.

### Two known races, and how they're handled

**Server-side**: `PlayerDataService` loads each player's profile asynchronously (a DataStore
call) via its own `Players.PlayerAdded` connection, completely independent from
`CharacterCreationService`'s own `PlayerAdded`/`CharacterAdded` connections. Since Roblox
doesn't guarantee which of two unrelated Loader-spawned connections runs first,
`CharacterCreationService` can't just check `PlayerDataService:GetData(player)` once and trust
it — the profile might not be loaded yet. It handles this by freezing the character
immediately and unfreezing only once `PlayerDataService:GetData(player)` starts returning
non-nil, erring on the side of an extra half-second frozen rather than briefly showing the
picker to a returning player who already has a class.

**Client-side (the one that actually broke first)**: the very first version of this had the
server *push* the player's class to the client via a `RemoteEvent` right on join. That's a
race too — if the server fires before the client's own script has finished starting up
(`Net.GetEvent`, connecting `OnClientEvent`), the one-shot event is simply lost, and the client
never learns it should show the picker. The symptom was exactly "frozen with nothing on
screen." Fixed by having the client *pull* instead: `CharacterCreationController`,
`SpellController`, and `ManaBarController` each call a `GetCharacterClass` `RemoteFunction`
once at startup to fetch the current state on demand, rather than trusting a push to arrive in
time. The `RemoteEvent` push is kept only for updates that happen *after* the client is
already known to be connected (confirming a fresh pick, or an admin-panel class reset).

### Trying it out

1. Join and confirm you spawn frozen with the **Customize Your Character** screen up first —
   try changing the skin/shirt/pants swatches and watch the 3D preview update live.
2. Click **Next** — the **Choose Your Path** screen appears. Pick a Mage class — you should
   unfreeze immediately, see your chosen colors applied to your actual character, and still be
   able to cast spells (1/2/3 + click) exactly as before.
3. Open the admin panel (**F6**) and click **"Reset Class (re-pick path)"** — you'll freeze
   again and the picker reappears. Pick **Witch Slayer** this time — confirm the spell hotbar
   and mana bar don't appear, and pressing 1/2/3 + click does nothing (try the debug **P** key
   too — that still works, since it's a separate damage-dealing tool, not magic).
