

# Codex Status Menu Bar

A tiny macOS menu bar utility that displays your current Codex usage limits.

The app talks directly to the local `codex app-server` using its JSON protocol (rather than scraping the `/status` terminal output) to retrieve:

- Remaining 5-hour usage
- Remaining weekly usage
- Reset times
- Available usage reset credits

The current implementation is intentionally simple:

- A lightweight AppKit menu bar application written in Swift
- A small Bash script that communicates with `codex app-server`
- The menu bar app launches the script once per minute and displays the current status

## Development

Build and launch:

```bash
./run.sh
```

The helper script can also be run directly:

```bash
./codex-status-script.sh
```

## Status

This project is an early prototype intended to explore the Codex app-server protocol and provide a lightweight usage monitor for macOS.