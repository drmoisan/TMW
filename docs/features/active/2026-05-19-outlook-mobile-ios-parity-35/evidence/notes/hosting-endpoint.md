# P6-T1 — HTTPS Hosting Endpoint (Dev Tunnel)

- Timestamp: 2026-05-20T11:58Z
- Task: P6-T1 (provision a trusted-TLS HTTPS endpoint reachable by the iOS device)
- Issue: #35

## HTTPS Endpoint

- Public URL (bundle root): `https://3zmjztsc-3000.use.devtunnels.ms/`
- Mechanism: Microsoft Dev Tunnels (`devtunnel`), tunnel `taskmaster-ios` (cluster `use`), port 3000, anonymous access.
- Local origin behind the tunnel: `http://localhost:3000` served from `dist/` via `http-server` (the tunnel terminates TLS and forwards to the local HTTP port).
- Build provenance: `npm run build` (webpack production mode) with `urlProd` set to the tunnel URL, which rewrote the bundled `manifest.xml` URLs from `https://localhost:3000/` to the tunnel host (16 occurrences). `urlProd` in `webpack.config.js` was reverted to the repository placeholder after the build; the transient tunnel URL is not committed.

## TLS Trust Basis (not self-signed)

Certificate observed via `openssl s_client` against `3zmjztsc-3000.use.devtunnels.ms:443`:

- Subject: `C=US, ST=WA, L=Redmond, O=Microsoft Corporation, CN=devtunnels.ms`
- Issuer: `C=US, O=Microsoft Corporation, CN=Microsoft TLS G2 RSA CA OCSP 10`
- Validity: notBefore `May 15 10:13:06 2026 GMT`, notAfter `Nov 11 10:13:06 2026 GMT`

The certificate chains to a publicly-trusted Microsoft CA and is therefore trusted by the iOS system trust store. It is not a self-signed development certificate.

## Reachability Confirmation (curl over HTTPS, no -k)

```
$ curl -s -I https://3zmjztsc-3000.use.devtunnels.ms/taskpane.html
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1912

$ curl -s -I https://3zmjztsc-3000.use.devtunnels.ms/manifest.xml
HTTP/1.1 200 OK
Content-Type: application/xml
Content-Length: 6807

$ curl -s -o /dev/null -w "%{http_code} %{size_download} %{content_type}" \
    https://3zmjztsc-3000.use.devtunnels.ms/assets/icon-48@3x.png
200 6922 image/png
```

Content-Length values match the built artifacts (`taskpane.html` 1912 B, `manifest.xml` 6807 B, `icon-48@3x.png` 6922 B), confirming the real bundle is served rather than a tunnel interstitial page.

## Notes / Caveats

- The bundled `dist/manifest.xml` `<AppDomain>` was patched in the served copy from `https://localhost:3000` to the tunnel host. The committed source `manifest.xml` `<AppDomain>` lacks a trailing slash, so the production build's find-replace (keyed on `https://localhost:3000/`) does not rewrite it. This is a source defect to fix (give the `<AppDomain>` a trailing slash, or list the production domain), tracked separately from this evidence note. It does not block pane loading because the `SourceLocation` domain is implicitly trusted.
- The classifier backend (P6-T5) must also be reachable over trusted HTTPS from the device; not addressed by this note.
- Dev Tunnels may present a one-time anti-phishing interstitial to interactive browser navigations. The `curl` checks above were served the real content; if the Outlook iOS WebView is blocked by the interstitial, accept the tunnel origin once in mobile Safari or move to a managed static host.

## Sustained services (for downstream P6-T2..T5 in this session)

- `devtunnel host taskmaster-ios` — running (forwarding port 3000).
- `http-server dist -p 3000 -c-1 --cors` — running (serving the built bundle).
- Sideload target for P6-T2: `dist/manifest.xml` (the rewritten copy), via Outlook on the web.
