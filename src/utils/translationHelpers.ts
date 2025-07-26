// API'den veya veri kaynağından gelen yaş kategorisi anahtarlarını çeviri fonksiyonu ile çözen yardımcı fonksiyon
export function resolveAgeCategoryKey(key: string, t: ((key: string) => string) | undefined): string {
  if (!t) return key;
  if (key === 'chick' || key === 'birds.chick') return t('birds.chick');
  if (key === 'adult' || key === 'birds.adult') return t('birds.adult');
  if (key === 'juvenile' || key === 'birds.juvenile') return t('birds.juvenile');
  if (key === 'unknown' || key === 'birds.unknown') return t('birds.unknown');
  if (key === 'ageCategory' || key === 'birds.ageCategory') return t('birds.ageCategory');
  if (key.startsWith('birds.')) return resolveAgeCategoryKey(key.replace('birds.', ''), t);
  return t('birds.unknown');
}

export function normalizeAgeCategory(category: string) {
  if (!category) return 'unknown';
  if (category.startsWith('birds.')) return category.replace('birds.', '');
  return category;
}

export function extractAgeCategory(raw: string | undefined) {
  if (!raw) return undefined;
  if (raw.includes(':')) {
    return raw.split(':')[1].trim();
  }
  return raw.trim();
} 