#!/usr/bin/env node
const TOKENS_FILE = 'apps/web/app/assets/css/tailwind.css';
const ANCHOR = /\b(?:href|to)\s*=\s*(["'])#[^"']*\1/g;
const HEX = /(?<![\w&])#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})(?![0-9a-zA-Z_-])/g;
const COLOR_FN = /\b(?:rgba?|hsla?|oklch|oklab|lab|lch|hwb)\(/g;

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
const input = payload?.tool_input;
const filePath = input?.file_path;
if (typeof filePath !== 'string' || !filePath.endsWith('.vue')) process.exit(0);

const text = input.content ?? input.new_string;
if (typeof text !== 'string' || text === '') process.exit(0);

const scanned = text.replace(ANCHOR, '');
const found = [...(scanned.match(HEX) ?? []), ...(scanned.match(COLOR_FN) ?? [])];
if (found.length === 0) process.exit(0);

const unique = [...new Set(found)].slice(0, 5);

process.stderr.write(
  [
    `BLOCKED (raw-color-guard): raw color value in a .vue file: ${unique.join(', ')}`,
    `File: ${filePath}`,
    `Colors live only in ${TOKENS_FILE} as semantic roles.`,
    'Use a role utility instead: bg-primary, text-foreground, text-muted-foreground,',
    'border-border, bg-card, bg-destructive, ring-ring, etc.',
    'If no existing role fits, stop and ask the user: a new role is added to',
    `${TOKENS_FILE} and documented in docs/design/design-system.md.`,
    '',
  ].join('\n'),
);
process.exit(2);
