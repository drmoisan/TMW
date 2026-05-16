# metadata-schema-evolution-infra (Issue #22)

- Date captured: 2026-05-15
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/metadata-schema-evolution-infra/ (Issue #22)

- Issue: #22
- Issue URL: https://github.com/drmoisan/TMW/issues/22
- Last Updated: 2026-05-16
- Work Mode: full-feature

## Problem / Why

TaskMaster metadata payloads (classification results, task metadata, tag sets, training-state references, migration provenance) are written to Microsoft Graph open extensions and a backend store without any schema versioning or compatibility gate. A breaking schema change can silently corrupt persisted data or break reader/writer compatibility across deployed versions. Before any metadata is written at scale, the write paths need schema validation and the CI pipeline needs a schema-evolution gate.

## Proposed Behavior

- A `/schemas/v{n}/` directory holds versioned JSON Schema files for every TaskMaster metadata payload type.
- Backend write paths validate payloads against the current-version schema before persisting; invalid payloads are rejected with a clear error.
- Forward-compat tests confirm that fixtures from every prior schema version are still readable by current code.
- Backward-compat tests confirm that payloads written by current code are parseable by a documented N-1 reader.
- `json-schema-diff-validator` (or equivalent) runs in the PR pipeline (stage 6); a breaking schema change without a version bump blocks the PR.
- Nightly pipeline stage 14 (schema evolution) runs forward + backward compat tests against the last three schema versions.

## Acceptance Criteria (early draft)

- [ ] `/schemas/v1/` contains JSON Schema files for: classification result, task metadata, tag set, training-state reference, migration provenance.
- [ ] Backend write paths reject payloads that fail schema validation (test coverage required).
- [ ] Forward-compat tests: v1 fixtures are readable by v1 code (baseline); on introduction of v2, v1 fixtures are readable by v2 code.
- [ ] Backward-compat tests: payloads written by current code pass the N-1 schema.
- [ ] PR pipeline stage 6 blocks merge on a breaking schema change without a version bump.
- [ ] Nightly pipeline stage 14 runs schema-evolution tests against the last three schema versions.
- [ ] An incompatible schema change without a version bump is detected and blocks the build (validation scenario).
- [ ] A version bump combined with the appropriate compat fixture passes (validation scenario).

## Constraints & Risks

- Schema payload types must be identified from the architecture research docs before writing schemas.
- The `json-schema-diff-validator` npm package (or equivalent) must be available in the CI environment.
- Forward/backward compat requires fixture management strategy (checked-in JSON fixtures per schema version).
- Nightly stage 14 is a new pipeline addition that must be wired into the existing nightly workflow YAML.

## Test Conditions to Consider

- [ ] Valid payload passes schema validation
- [ ] Invalid payload (missing required field) is rejected
- [ ] Prior-version fixture is accepted by current reader (forward compat)
- [ ] Current-version payload passes N-1 schema (backward compat)
- [ ] Breaking schema change without version bump fails CI
- [ ] Non-breaking schema change passes CI without version bump requirement
- [ ] Version bump with compat fixture passes CI

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/metadata-schema-evolution-infra/` folder from the template