class Gamification {
  int points;
  int level;
  List<String> badges;

  Gamification({this.points = 0, this.level = 1, List<String>? badges})
      : badges = badges ?? [];

  void addPoints(int value) {
    points += value;
    _updateLevel();
  }

  void addBadge(String badge) {
    if (!badges.contains(badge)) {
      badges.add(badge);
    }
  }

  void _updateLevel() {
    // Example: every 100 points = new level
    level = (points ~/ 100) + 1;
  }

  Map<String, dynamic> toJson() => {
        'points': points,
        'level': level,
        'badges': badges,
      };

  static Gamification fromJson(Map<String, dynamic> json) => Gamification(
        points: json['points'] ?? 0,
        level: json['level'] ?? 1,
        badges: List<String>.from(json['badges'] ?? []),
      );
}