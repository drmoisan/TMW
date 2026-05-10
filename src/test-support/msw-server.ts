import { setupServer } from "msw/node";

// Register default handlers here; test files can add per-test handlers
export const server = setupServer();
