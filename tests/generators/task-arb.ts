import * as fc from "fast-check";

/**
 * Arbitrary for a placeholder Task object used in property-based tests.
 * Generates tasks with a UUID id, arbitrary string title, and boolean completed flag.
 */
export const taskArbitrary = fc.record({
  id: fc.uuid(),
  title: fc.string(),
  completed: fc.boolean(),
});
