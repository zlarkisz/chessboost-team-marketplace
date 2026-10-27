#!/usr/bin/env node
import path from 'node:path';

const DOMAIN_PATH = /^(.*\/apps\/server\/src\/([^/]+)\/domain)\//;
const IMPORT_SPECIFIER =
  /(?:\bfrom\s*|\bimport\s*\(?\s*|\brequire\s*\(\s*)['"]([^'"]+)['"]/g;

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

function findViolations(filePath, domainRoot, text) {
  const violations = [];
  for (const [, specifier] of text.matchAll(IMPORT_SPECIFIER)) {
    if (!specifier.startsWith('.')) {
      violations.push({ specifier, reason: 'external package' });
      continue;
    }
    const resolved = path.resolve(path.dirname(filePath), specifier);
    if (resolved !== domainRoot && !resolved.startsWith(domainRoot + path.sep)) {
      violations.push({ specifier, reason: 'leaves domain/' });
    }
  }
  return violations;
}

const payload = parsePayload(await readStdin());
const filePath = payload?.tool_input?.file_path;
if (typeof filePath !== 'string') process.exit(0);

const match = filePath.match(DOMAIN_PATH);
if (!match) process.exit(0);
const [, domainRoot, boundedContext] = match;

const text = payload.tool_input.content ?? payload.tool_input.new_string ?? '';
const violations = findViolations(filePath, domainRoot, text);
if (violations.length === 0) process.exit(0);

const lines = violations.map((v) => `  · '${v.specifier}' — ${v.reason}`);
process.stderr.write(
  [
    `BLOCKED (domain-import-guard): ${boundedContext}/domain must stay framework-free.`,
    `File: ${filePath}`,
    ...lines,
    'domain/ may import only relative paths inside its own domain/ — no npm, no @nestjs/*,',
    'no shared/, no other bounded contexts. Move framework code to application/ or',
    'infrastructure/; cross-context communication goes through shared/events from application/.',
    '',
  ].join('\n'),
);
process.exit(2);
