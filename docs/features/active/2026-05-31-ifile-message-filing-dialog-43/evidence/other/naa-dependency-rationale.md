# NAA Runtime Dependency Rationale — @azure/msal-browser

Timestamp: 2026-06-04T20-29

Dependency added: `@azure/msal-browser` (version `^5.11.0`, resolved 5.11.0 in package-lock.json), placed under `dependencies` in `package.json` (not `devDependencies` — it is a runtime dependency loaded by the add-in at runtime).

Justification:
- OD-8 designates NAA (nested app authentication) as the primary client-side token-acquisition path.
- Per the research (artifacts/research/2026-06-04-ifile-token-path-naa-vs-sso-research-43.md, section 1), NAA is the only Outlook-iOS-supported token path: `NestedAppAuth 1.1` is GA on Outlook iOS from build v4.2433.0, whereas `IdentityAPI 1.3` (which backs the legacy `Office.auth.getAccessToken` SSO path) is not listed in the Outlook iOS requirement-set support matrix.
- `@azure/msal-browser` is the official Microsoft library implementing `createNestablePublicClientApplication`, the documented entry point for NAA (research section 3.4).

Boundary constraint: This dependency may be imported ONLY by the single new host-bound module `src/taskpane/ifile/naa-token-acquirer.ts` (introduced in Phase 4). It MUST NOT be imported by any pure host-neutral iFile module or by the Office-free `bootstrap` seam in `ifile.ts`. The dependency-cruiser rule `ifile-pure-modules-no-host-deps` is extended in Phase 3 [P3-T2] to forbid `@azure/msal-browser` imports in the pure modules before the NAA adapter lands.

No other new runtime dependency was added.
