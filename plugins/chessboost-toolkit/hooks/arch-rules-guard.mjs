#!/usr/bin/env node
import path from 'node:path';

const PROTECTED = [
  { test: (name) => name === '.dependency-cruiser.cjs', what: 'architecture rules (dependency-cruiser)' },
  { test: (name) => /^tsconfig(\..+)?\.json$/.test(name), what: 'TypeScript compiler settings' },
];

async function readStdin() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  return raw;
}

function parsePayload(raw) {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

const payload = parsePayload(await readStdin());
const filePath = payload?.tool_input?.file_path;
if (typeof filePath !== 'string') process.exit(0);

const rule = PROTECTED.find(({ test }) => test(path.basename(filePath)));
if (!rule) process.exit(0);

process.stderr.write(
  [
    `BLOCKED (arch-rules-guard): ${path.basename(filePath)} holds ${rule.what}.`,
    `File: ${filePath}`,
    'These files define the checks — loosening them to make a check pass hides the problem.',
    'Fix the code instead. If the rule itself must change, stop and ask the user: they edit',
    'the file by hand, and a decision with alternatives gets an ADR.',
    '',
  ].join('\n'),
);
process.exit(2);
