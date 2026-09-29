# c35 browser_engine

Playwright sidecar for `c_remote_browser`. Speaks IPC v1 over stdin/stdout (length-prefixed JSON).

## Build

```powershell
cd remotes/browser_engine
npm install
npm run build
```

## Run (dev)

```powershell
node dist/worker.js
```

Rust spawns `dist/worker.js` by default (override with `C35_BROWSER_ENGINE_WORKER`).

## IPC methods

`ping`, `launch`, `shutdown`, `screencast.start`, `screencast.stop`, `input`, `tab.*`, `navigate`, `task.run`