String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return '좋은 아침이에요';
  if (hour >= 12 && hour < 18) return '좋은 오후예요';
  return '좋은 저녁이에요';
}

String firstCharacter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return String.fromCharCode(trimmed.runes.first);
}
