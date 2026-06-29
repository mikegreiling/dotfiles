/**
 * STUB — deterministic resource setup is not yet implemented in this skill.
 *
 * Some demos (orders, disputes, refunds, …) need a record in a specific shape
 * that doesn't exist yet — e.g. create a listing → finalize it → turn it into an
 * order → open a dispute. That seeding should eventually live here (driven by
 * fe-scripts or direct API calls), exposed so demo.config can request it and
 * scenarios can depend on it.
 *
 * See references/setup-teardown.md for the intended design. Until then: seed the
 * record manually (or via existing fe-scripts commands), put its ID in
 * demo.config.records, and flag the gap to Mike (+ propose codifying it here).
 */
export async function setup(): Promise<Record<string, string>> {
  throw new Error(
    'setup() not implemented — see references/setup-teardown.md. Seed the record manually and set demo.config.records for now.'
  )
}
