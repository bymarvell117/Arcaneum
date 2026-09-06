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
