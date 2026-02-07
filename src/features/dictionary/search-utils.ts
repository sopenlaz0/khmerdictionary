export function normalizeSearchTerm(raw: string): string {
  return raw.trim().toLowerCase();
}

export function buildPrefixPattern(searchTerm: string): string {
  return searchTerm.length === 0 ? '%' : `${searchTerm}%`;
}

export function formatDefinitionPlainText(raw: string): string {
  return raw
    .replace(/<"[^"]+">/g, '')
    .replace(/\/a/g, '')
    .replace(/\\n/g, '\n\n')
    .replace(/<[^>]+>/g, '')
    .replace(/\u200b/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
}
