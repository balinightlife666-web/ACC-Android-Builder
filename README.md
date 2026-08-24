# ACC Local Roblox Publisher

Legacy repo name: `ACC-Android-Builder`. Its active purpose is now a **local Roblox maps publisher** running from an Android phone with Termux, so map publishing can continue when GitHub-hosted Actions minutes are unavailable.

## What it does

- Keeps GitHub as the source of truth.
- Pulls the latest `ardarawk-cloud/ACC-Roblox-maps` source.
- Publishes an existing registered `.rbxl` / `.rbxlx` place directly through Roblox Open Cloud.
- Uses the map registry for Universe ID, Place ID and place file path.
- Retries transient Roblox API errors using the publisher already maintained in `ACC-Roblox-maps`.
- Stores logs locally on the phone.
- Does **not** require a GitHub-hosted Actions runner for direct publish.

## One-time phone setup

From this repository folder in Termux:

```bash
git pull && ./install.sh
```

The installer creates the short `acc` command and asks once for the Roblox Open Cloud API key. The key is stored only on the phone under `~/acc-publisher/secrets.env` with restricted permissions. Never commit or send that key.

Because `ACC-Roblox-maps` is private, the Git credential configured on the phone must have read access to `ardarawk-cloud/ACC-Roblox-maps`.

## Daily commands

```bash
acc bbya
acc bbyavatar
acc becak
```

Other commands:

```bash
acc list
acc status
acc pull
acc publish <map-id>
```

Current shortcuts resolve through `maps/registry.json`:

- `bbya` → `a-club` → BBYA Social Hub
- `bbyavatar` → BBYAVATAR
- `becak` → BECAK E-BIKE

## Important limitation

This phone publisher can execute Node/Python/Open Cloud operations available on Android. Workflows that fundamentally require **Windows Roblox Studio, a live Studio/MCP session, or desktop-only tooling** cannot be reproduced by Termux alone. Direct place publishing of an already-built registered place file is supported.
