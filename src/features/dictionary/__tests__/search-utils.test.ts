import {
  buildPrefixPattern,
  formatDefinitionPlainText,
  normalizeSearchTerm,
} from '../search-utils';

describe('dictionary search utils', () => {
  test('normalizeSearchTerm trims and lowercases user input', () => {
    expect(normalizeSearchTerm('  ភាសា  ')).toBe('ភាសា');
    expect(normalizeSearchTerm('  Khmer  ')).toBe('khmer');
  });

  test('buildPrefixPattern appends wildcard for SQL LIKE prefix search', () => {
    expect(buildPrefixPattern('khmer')).toBe('khmer%');
    expect(buildPrefixPattern('')).toBe('%');
  });

  test('formatDefinitionPlainText normalizes line breaks and strips html tags', () => {
    const raw = 'និយមន័យ\\n<b>ខ្មែរ</b> : សាកល្បង';
    expect(formatDefinitionPlainText(raw)).toBe('និយមន័យ\n\nខ្មែរ : សាកល្បង');
  });

  test('formatDefinitionPlainText strips legacy dictionary anchor tokens', () => {
    const raw = '<"8672">ព្យញ្ជនៈ/a <"5154">ទី/a ១ <"3275">ជា/a';
    expect(formatDefinitionPlainText(raw)).toBe('ព្យញ្ជនៈ ទី ១ ជា');
  });
});
