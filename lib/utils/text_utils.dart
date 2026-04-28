String truncateWords(
  String input, {
  int maxWords = 8,
  String omission = '...',
}) {
  final normalized = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return '';
  if (maxWords <= 0) return omission;

  final words = normalized.split(' ');
  if (words.length <= maxWords) return normalized;

  return '${words.take(maxWords).join(' ')}$omission';
}
