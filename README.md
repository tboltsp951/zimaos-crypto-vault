# Cold Vault for ZimaOS

Turns the single-file `crypto-vault.html` into a self-hosted ZimaOS app.
The page keeps all of its behavior — portfolio totals, per-asset holdings,
locations (exchanges / hardware / hot wallets), manual balances, live
CoinGecko pricing, currency switching, and the Tracked coins manager
(CoinGecko search / add-by-ID to price any coin you hold) — and gains one
new thing: **data is saved to your NAS disk** via a tiny storage bridge.

The original page only had **no localStorage fallback** (just Export/Import).
With the bridge, every browser on your network sees the same portfolio, and
it survives container rebuilds.

> The only source change vs. the original file: `save()`/`load()` now use a
> `window.storage` bridge when present (injected by `server.js`), falling
> back to `localStorage` when opened directly as a plain file. Boot waits up
> to 4s for the server copy before rendering. Everything else is unchanged.

## How it works

- `app/server.js` is a dependency-free Node HTTP server.
  - Serves `app/crypto-vault.html` with a small `window.storage` bridge
    injected into `<head>`.
  - Exposes `GET/PUT /__storage__/<key>`, persisted to `/data/cold-vault.json`.
- `Dockerfile` builds a `node:20-alpine` image.
- `Apps/ColdVault/docker-compose.yml` is the ZimaOS/CasaOS app manifest
  (`x-casaos` metadata) that mounts `/DATA/AppData/cold-vault` into the
  container. The `Apps/` folder layout is what ZimaOS's third-party store
  loader scans for apps.

## Files

```
zimaos-crypto-vault/
  app/
    crypto-vault.html          the app itself (save/load patched for the bridge)
    server.js                  web server + storage bridge
  Apps/
    ColdVault/
      docker-compose.yml       ZimaOS app manifest (store entry)
      icon.svg                 app icon
      thumbnail.svg            store card image
      screenshot.svg           store screenshot
  Dockerfile
```

## Install on ZimaOS

Two paths — pick one.

### A. Build & run it yourself (no store needed)

Copy this folder to the ZimaOS device (or clone the repo), then over
SSH/terminal:

```sh
docker build -t cold-vault:latest .
docker run -d --name cold-vault \
  -p 8193:8080 \
  -v /DATA/AppData/cold-vault:/data \
  --restart unless-stopped \
  cold-vault:latest
```

Open `http://<zimaos-ip>:8193`.

### B. Add it as an app in the ZimaOS app store

1. Push this repo to GitHub (as `tboltsp951/zimaos-crypto-vault`).
2. The `publish.yml` workflow builds and pushes
   `ghcr.io/tboltsp951/zimaos-crypto-vault:latest` on every push to `main`.
3. In ZimaOS: **Settings → App Store → Add third-party store**, then paste
   the archive URL of your repo:
   `https://github.com/tboltsp951/zimaos-crypto-vault/archive/refs/heads/main.zip`
4. Install **Cold Vault**. The default host port is **8193**; change it in
   the UI if you prefer.

The icon/thumbnail URLs in the manifest point at raw GitHub files, so they
only resolve once the repo is public.

## Updating

The store manifest sets `pull_policy: always`, so every install / update /
reinstall pulls the current `:latest` image from GHCR instead of reusing a
stale cached one (ZimaOS only compares image *tags* for update detection, and
`:latest` never changes string-wise). The manifest also carries
`x-casaos.version`, bumped on each release, so the store can show an update.

Fastest refresh without waiting for the store:

```sh
docker pull ghcr.io/tboltsp951/zimaos-crypto-vault:latest
docker rm -f cold-vault     # then reinstall from ZimaOS, or docker run again
```

If your ZimaOS/compose version rejects `pull_policy`, install fails with
"Additional property pull_policy is not allowed" — remove that one line and
pull manually as above.

## Testing locally (no Docker needed)

```sh
node app/server.js          # DATA_DIR defaults to app/data, PORT defaults to 8080
```

Then open `http://localhost:8080`, add a holding, and confirm
`app/data/cold-vault.json` appears on disk.

## Notes

- The container runs as root so the bind mount at `/DATA/AppData/cold-vault`
  is always writable. Fine for a single-user home tool.
- Live CoinGecko price lookups happen straight from the browser, so they need
  outbound internet. Your CoinGecko API key (Settings) stays in the browser
  by design — it is never sent to the NAS bridge.
- The `localStorage` fallback only exists so the file also works as a plain
  double-clicked HTML. Data is server-side once served by the bridge.
- Multi-browser sharing works because storage is server-side now.
