#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

const testsDir = import.meta.dirname;
const fixturesDir = path.join(testsDir, 'fixtures');
const hook = path.join(testsDir, '..', 'domain-import-guard.mjs');
const EXPECTED_EXIT = { block: 2, pass: 0 };

const fixtures = readdirSync(fixturesDir).filter((f) => f.endsWith('.json')).sort();
let failed = 0;

for (const fixture of fixtures) {
  const expected = EXPECTED_EXIT[fixture.split('-')[0]];
  if (expected === undefined) {
    console.log(`?  ${fixture} — name must start with block- or pass-`);
    failed++;
    continue;
  }
  const { status } = spawnSync('node', [hook], {
    input: readFileSync(path.join(fixturesDir, fixture)),
    stdio: ['pipe', 'ignore', 'ignore'],
  });
  const ok = status === expected;
  if (!ok) failed++;
  console.log(`${ok ? '✓' : '✗'}  ${fixture.padEnd(36)} exit=${status} (expected ${expected})`);
}

console.log(failed === 0 ? `\nAll ${fixtures.length} passed.` : `\n${failed} of ${fixtures.length} failed.`);
process.exit(failed === 0 ? 0 : 1);
