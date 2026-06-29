/**
 * STUB — deterministic resource teardown is not yet implemented in this skill.
 *
 * If/when setup() seeds disposable records, this should clean them up (cancel the
 * order, close the dispute, delete the listing, etc.) so repeated runs stay clean.
 * See references/setup-teardown.md for the intended design.
 *
 * Until then this is a no-op; demos run against existing/long-lived records and
 * never submit unless a scenario explicitly opts in on a disposable record.
 */
export async function teardown(): Promise<void> {
  // intentionally a no-op for now
}
