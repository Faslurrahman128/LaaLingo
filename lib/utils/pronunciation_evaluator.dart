/// Utility for evaluating pronunciation by comparing recognized and target words.
class PronunciationEvaluator {
  /// Dart-native Levenshtein distance implementation
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<List<int>> d = List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));
    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[s.length][t.length];
  }

  /// Returns a similarity score (0-100) and feedback message.
  static Map<String, dynamic> evaluate(String recognized, String target) {
    final distance = levenshtein(recognized.toLowerCase(), target.toLowerCase());
    final maxLen = target.length > 0 ? target.length : 1;
    final similarity = ((1 - (distance / maxLen)) * 100).clamp(0, 100).toInt();
    String feedback;
    if (similarity == 100) {
      feedback = 'Perfect! Pronunciation is correct.';
    } else if (similarity >= 80) {
      feedback = 'Good! Minor mistakes.';
    } else if (similarity >= 60) {
      feedback = 'Fair. Try to pronounce more clearly.';
    } else {
      feedback = 'Needs improvement. Listen and try again.';
    }
    return {'score': similarity, 'feedback': feedback};
  }
}
