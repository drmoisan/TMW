# Fetch Polyfill Verification for openapi-fetch

Timestamp: 2026-05-14T22-42

## Scope

Verify whether the existing polyfill setup covers `openapi-fetch`'s native-`fetch` usage for the `browserslist` targets, which include `ie 11`. Per the settled decision, `browserslist` must not be modified; if the polyfill is absent the gap is recorded as a follow-up finding.

## Evidence Basis

- `webpack.config.js` defines a single `polyfill` entry: `["core-js/stable", "regenerator-runtime/runtime"]`. Both `taskpane` and `commands` HTML bundles include the `polyfill` chunk.
- `core-js` polyfills ECMAScript built-ins (Promise, Symbol, iterators, Array/Object/String methods). It does **not** polyfill the WHATWG `fetch` Web API — inspection of `node_modules/core-js/modules/` shows no `fetch` module. `fetch` is a browser/Web API, outside core-js's ECMAScript scope.
- `package.json` `dependencies` contains only `core-js` and (after this feature) `openapi-fetch`. There is no dedicated `fetch` polyfill dependency (`whatwg-fetch`, `unfetch`, `cross-fetch` are absent from `dependencies`). The `node-fetch` entry in `package-lock.json` is a transitive dependency of the `@microsoft/app-manifest` CLI tooling, not part of the add-in browser bundle.
- The existing `src/taskpane/classifier-client.ts` already calls the global `fetch` directly (lines 68 and 92, pre-migration line numbers). The codebase therefore already depends on a native `fetch` implementation; `openapi-fetch` introduces no new polyfill requirement beyond what `classifier-client.ts` already assumes.

## Output Summary

Conclusion: No dedicated `fetch` polyfill is present in the bundle. `core-js/stable` does not cover `fetch`. This is a **pre-existing gap** — the current `classifier-client.ts` already uses global `fetch` without a polyfill — and is not introduced by this feature. `openapi-fetch` (added by P2-T1) does not change the polyfill requirement because P2-T3 does not rewrite `ClassifierClient` onto an `openapi-fetch` `createClient`; only the hand-written type declarations were replaced with generated types. The runtime `fetch` calls in `classifier-client.ts` are unchanged.

`browserslist` was not modified (it still lists `last 2 versions` and `ie 11`).

### Follow-up Finding (recorded, not actioned in Issue #19)

For genuine IE 11 runtime support of any `fetch`-based code (the existing `ClassifierClient` and any future `openapi-fetch` `createClient` adoption), a `fetch` polyfill (for example `whatwg-fetch`) should be added to the `polyfill` webpack entry. This gap predates Issue #19 and is out of scope for this feature per the settled decision not to rewrite `ClassifierClient` onto `openapi-fetch` `createClient`. It is recorded here as a follow-up rather than resolved, and `ie 11` is retained in `browserslist`.
