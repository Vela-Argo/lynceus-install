 ```
  ╔══════════════════════════════════════════════════════════════════════════════╗
  ║      *         _                                                             ║
  ║      │        | |_   _ _ __   ___ ___ _   _ ___                              ║
  ║   ───┼───     | | | | | '_ \ / __/ _ \ | | / __|                             ║
  ║      │        | | |_| | | | | (_|  __/ |_| \__ \                             ║
  ║   ───┼───     |_|\__, |_| |_|\___\___|\__,_|___/                             ║
  ║      │           |___/                                                       ║
  ║   ───┼───                                                                    ║
  ║      │        ARGO agentic SDLC harness · v0.1.0                             ║
  ║      ▼                                                                       ║
  ╚══════════════════════════════════════════════════════════════════════════════╝
  ```

# Lynceus — install scripts

This repository hosts the public install scripts for **Lynceus**, the opinionated [Pi](https://pi.dev) configuration used at Vela-Argo for agentic SDLC work.

The scripts here are intentionally public so they can be fetched with a single `curl` / `iwr` command. The installable packages they pull in (`@vela-argo/cli`, `@vela-argo/lynceus`) live on **GitHub Packages and remain private to the Vela-Argo organisation** — you still need a GitHub Personal Access Token with `read:packages` scope to actually install.

## What Lynceus is

A bundle of:

- The **[Argo](https://github.com/Vela-Argo/argo-harness) harness** — gate-driven design framework (scope → spec → api → build → review → security → test → deploy) that surfaces hidden constraints in software design before code gets written.
- The **`argo` CLI** — local HTTP server that the harness runs against; `argo serve`, `argo status`, `argo stop`, `argo init`.
- The **Lynceus theme + splash** for [Pi](https://pi.dev).
- A **conversational skill** that drives the harness gate-by-gate through Pi (or any host implementing the documented tool-bindings).
- An **autostart extension** that scaffolds `.argo/` and boots the daemon on every Pi session — zero per-project setup.

Source code is in the private [`Vela-Argo/argo-harness`](https://github.com/Vela-Argo/argo-harness) repo; this public repo only ships the bootstrap scripts.

## Install — one line

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Vela-Argo/lynceus-install/main/install.sh | bash
```

### Windows PowerShell

```powershell
iwr -useb https://raw.githubusercontent.com/Vela-Argo/lynceus-install/main/install.ps1 | iex
```

Both scripts are interactive — they pause to prompt for a GitHub PAT (input hidden) the first time you run them.

## What the scripts do, in order

1. **Verify Node 20+** is on `PATH`. Exit with the install link if not.
2. **Check `~/.npmrc`** for `@vela-argo:registry`. If missing, prompt for a GitHub PAT (`read:packages` scope; SSO-authorised for Vela-Argo if your org enforces it) and write the registry + auth lines (chmod 600 on Unix).
3. **Install Pi** — `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` (per [pi.dev's recommended install](https://pi.dev/docs/latest)).
4. **Install the argo CLI** — `npm install -g @vela-argo/cli`.
5. **Install Lynceus into Pi** — `pi install npm:@vela-argo/lynceus`.

Idempotent: re-running upgrades to the latest published versions and skips the auth prompt if `~/.npmrc` is already configured.

## Prerequisites

- **Node.js 20 or newer** — install from [nodejs.org](https://nodejs.org)
- **A GitHub Personal Access Token (classic)** with the `read:packages` scope — generate at <https://github.com/settings/tokens>. If Vela-Argo enforces SSO, click "Configure SSO" next to the new token after creating it and authorise for the org.

That's it. The scripts handle everything else.

## After install

```bash
cd path/to/your/project
pi
```

On first Pi session in that folder, Lynceus's autostart extension will:

1. Render the Lynceus splash.
2. Run `argo init` to scaffold `.argo/` and starter docs in your current directory.
3. Boot the harness daemon (`argo serve --detach`).
4. Make the conversational harness skill available — ask Pi something like *"use the harness skill to walk auth-rewrite-001 through scope"*.

## What the scripts do **NOT** do

- They don't install Node.js for you. If Node is missing, they exit with the install link.
- They don't create a per-project `.pi/settings.json`. The Lynceus package ships a starter template; teams copy it into their repo themselves (or use it as documented in the `@vela-argo/lynceus` README, available after install).
- They don't run `argo init` themselves. That happens automatically on the first Pi session via Lynceus's autostart.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Error: Node 20+ is required` | Old Node | Upgrade from [nodejs.org](https://nodejs.org) |
| `npm error code E401 Unauthorized` | PAT lacks `read:packages` scope OR SSO not authorised | Regenerate the token, ensure `read:packages` is ticked, click "Configure SSO" for Vela-Argo |
| `pi`/`argo` not on PATH after install | npm global bin dir not in shell PATH | Open a new terminal; if still missing, add `$(npm root -g)/.bin` (Unix) or `npm prefix -g` (Windows) to PATH |
| `pi install` fails | Pi can't find the package on its registry | Verify `~/.npmrc` has the `@vela-argo:registry=https://npm.pkg.github.com` line |

## License

Internal use only — Vela-Argo proprietary tooling. Not licensed for redistribution.
