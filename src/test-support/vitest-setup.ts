import { afterAll, afterEach, beforeAll, vi } from "vitest";
import { server } from "./msw-server";
import officeFake from "./office-fake";

// Inject Office global before any test runs
beforeAll(() => {
    (globalThis as Record<string, unknown>)["Office"] = officeFake;
});

// Enable fake timers by default for determinism (per typescript.md runtime determinism policy)
beforeAll(() => {
    vi.useFakeTimers();
});

// MSW server lifecycle
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
