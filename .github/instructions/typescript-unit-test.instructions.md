
---
description: "TypeScript-specific unit test rules, layered on top of the general unit test policy"
applyTo: "**/*.ts"
name: typescript-unit-test-policy
---

# TypeScript Unit Test Policy

This policy **extends** `general-unit-test.instructions.md` and applies to all **TypeScript unit tests** in this repo.

You must follow **both**:

- The general unit test policy, and
- The TypeScript-specific rules below.

If there is any conflict between these documents, **halt and notify the user.**

---

## 1. Framework and Scope

- **Testing framework**
  - All TypeScript unit tests must use **Vitest**.

- **Unit test definition**
  - Unit tests validate small, isolated behaviors (functions, helpers, small classes).
  - Unit tests must not require launching the Outlook host runtime or depending on a live Outlook web add-in context.

- **Coverage expectation**
  - All new TypeScript logic must be covered by Vitest unit tests that follow the general unit test policy.

---

## 2. Test Layout and Naming

### **File naming**

- Name test files with the `.test.ts` suffix.

### **Test location**

- Organize tests in a way that mirrors the code under test where practical (for example, `tests/unit/<module>.test.ts` for `src/<module>.ts`, or a parallel folder structure for deeper subsystems).
- Use shared setup sparingly and keep it narrowly scoped:
  - Prefer `describe()` blocks with local `beforeEach` / `afterEach` for common setup within a small group of tests.
  - Prefer small helper functions / factories (or a local test utility module) when it reduces duplication without hiding intent.
  - Avoid broad, implicit “global” setup that makes tests hard to reason about.

---

## 3. Test Style and Structure (TypeScript)

### **Focused tests**

- Each test should target one behavior.
- Prefer testing observable behavior over internal implementation details.

### **Arrange–Act–Assert**

Organize each test into:
- Arrange — inputs and setup
- Act — call the function/behavior
- Assert — verify results

### **Intent documentation**

- Test names must clearly express the scenario and expected outcome.
- If intent is not obvious, add a brief comment explaining why the case matters.

---

## 4. Mocking and Isolation

### **Avoid external dependencies**

- Unit tests must not depend on external services, network calls, or external processes.

### **Mocking guidance**

- Mock external APIs or platform dependencies to keep tests deterministic.
- Prefer targeted mocks:
  - `vi.spyOn(obj, 'method')` for specific functions
  - `vi.mock('module')` for module-level dependencies

### **Resetting mocks**

- Reset mocks between tests to ensure independence.
- Preferred pattern:
  - `afterEach(() => { vi.resetAllMocks(); });`

### **Time and timers**

- Avoid brittle timing assertions.
- Prefer fake timers (`vi.useFakeTimers()`) or injected clocks when time is part of behavior.

---

## 5. Assertions and Diagnostics

- Assertions must produce clear, actionable failures.
- Prefer simple, direct matchers (`toEqual`, `toMatchObject`, `toHaveBeenCalledWith`).
- Avoid snapshots unless they provide strong value and are stable; keep snapshots small and intentional.

---

## 6. Required Commands

When verifying TypeScript unit tests locally, use the repo-standard scripts:

- Approved command: `npm run test`

> Formatting/lint/type-check commands for the full toolchain loop are defined in the TypeScript code change policy.

---

## 7. Property-Based and Mutation Testing

- `fast-check` provides property-based tests; T1 and T2 modules require >= 1 property test per pure function.
- `StrykerJS` provides mutation testing; T1 modules require mutation score >= 75%.
- Both run in pre-merge or nightly pipelines per `.github/instructions/general-code-change.instructions.md`.

## 8. Golden Tests

- T1 classifier modules require golden-output snapshots tested against a versioned corpus.
- General guidance to avoid snapshots unless stable and intentional remains in force for all other scenarios; classifier-output and schema-evolution snapshots are explicitly permitted when versioned.

## 9. Runtime Determinism

- `Date`, `Math.random`, and `setTimeout` access must flow through an injected `Clock` / `Random` interface.
- Tests use Vitest fake timers (`vi.useFakeTimers()`).
- Prefer `await flushPromises()` over `setTimeout(0)` for awaiting micro-tasks.

## 10. Coverage Thresholds

Coverage thresholds follow the uniform tier rule defined in `.github/instructions/quality-tiers.instructions.md`: line coverage >= 85% and branch coverage >= 75% across all tiers (T1–T4). Tier-specific lower thresholds are not used. Coverage regression on changed lines is a blocking finding.
