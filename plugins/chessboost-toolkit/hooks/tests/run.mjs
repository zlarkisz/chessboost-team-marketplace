#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

const testsDir = import.meta.dirname;
const fixturesDir = path.join(testsDir, 'fixtures');
const EXPECTED_EXIT = { block: 2, pass: 0 };

const hookNames = readdirSync(fixturesDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();
let total = 0;
let failed = 0;

for (const hookName of hookNames) {
  const hook = path.join(testsDir, '..', `${hookName}.mjs`);
  const hookFixturesDir = path.join(fixturesDir, hookName);
  const fixtures = readdirSync(hookFixturesDir).filter((f) => f.endsWith('.json')).sort();
  console.log(`\n${hookName}`);

  for (const fixture of fixtures) {
    total++;
    const expected = EXPECTED_EXIT[fixture.split('-')[0]];
    if (expected === undefined) {
      console.log(`?  ${fixture} — name must start with block- or pass-`);
      failed++;
      continue;
    }
    const { status } = spawnSync('node', [hook], {
      input: readFileSync(path.join(hookFixturesDir, fixture)),
      stdio: ['pipe', 'ignore', 'ignore'],
    });
    const ok = status === expected;
    if (!ok) failed++;
    console.log(`${ok ? '✓' : '✗'}  ${fixture.padEnd(36)} exit=${status} (expected ${expected})`);
  }
}

console.log(failed === 0 ? `\nAll ${total} passed.` : `\n${failed} of ${total} failed.`);
process.exit(failed === 0 ? 0 : 1);
