

# Build Notes

This project started with a simple question:

> Could the Codex `/status` information be displayed in a macOS menu bar?

The obvious approach would have been to scrape the terminal output. Instead, after a bit of digging, it became clear that the Codex CLI exposes a local `app-server` with a JSON-RPC protocol. Once that was discovered, the project became much simpler.

The overall architecture ended up looking like this:

```text
Menu Bar App (Swift)
        ↓
Process()
        ↓
codex-status-script.sh
        ↓
codex app-server
        ↓
JSON protocol
```

Keeping the Bash script separate from the Swift code turned out to be a good tradeoff. The script became a tiny, debuggable API that could be tested independently before writing any AppKit code.

## Discovering the protocol

The key clue was the app-server schema:

```bash
codex app-server generate-json-schema --out codex-schema-dir
```

Searching the generated schema revealed:

- `account/rateLimits/read`
- `account/rateLimits/updated`

Those names were enough to reconstruct the handshake.

## Talking to the app-server

The protocol requires initialization before requests can be made.

```json
{"id":1,"method":"initialize","params":{...}}
{"method":"initialized"}
{"id":2,"method":"account/rateLimits/read","params":null}
```

The response contains structured usage information including:

- five-hour usage
- weekly usage
- reset times
- available reset credits

No screen scraping required.

## A useful lesson

Initially I expected the Bash script to be a temporary prototype.

Instead, it became a clean boundary between the UI and the protocol. The Swift app doesn't know anything about JSON-RPC; it simply runs a script and displays the result. That separation made development much faster.

## Running the app

During development the project is intentionally lightweight:

```bash
./run.sh
```

The helper script can also be tested directly:

```bash
./codex-status-script.sh
```

Being able to exercise the protocol without rebuilding the application made debugging dramatically easier.

## Where this could go

Eventually the JSON-RPC protocol could be implemented directly in Swift, eliminating the Bash helper entirely. For now, the current design keeps each piece small, understandable, and independently testable, which has been a pleasant way to build the project.