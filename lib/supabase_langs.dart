/// Utilities for working with per-language user data stored in Supabase.
///
/// New schema expects a json/jsonb column named `langs` on the `user` table:
/// {
///   "1": {"Selected_lang": [..], "Progress": [0,0,0,0], "name": "..."},
///   "2": { ... }
/// }
///
/// For backwards compatibility, if `langs` is missing, we also look for
/// numeric keys directly on the user row ("1", "2", ...).

Map<String, dynamic> extractLangs(dynamic userRow) {
  if (userRow is! Map) return <String, dynamic>{};

  final dynamic langs = userRow['langs'];
  if (langs is Map) {
    return langs.map((key, value) => MapEntry(key.toString(), value));
  }

  final out = <String, dynamic>{};
  for (final entry in userRow.entries) {
    final k = entry.key.toString();
    if (RegExp(r'^\d+$').hasMatch(k) && entry.value is Map) {
      out[k] = entry.value;
    }
  }
  return out;
}

Map<String, dynamic>? getLangSlot(dynamic userRow, int slot) {
  if (slot <= 0) return null;
  final langs = extractLangs(userRow);
  final slotVal = langs[slot.toString()];
  if (slotVal is Map) {
    return slotVal.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

int deriveCountLang(dynamic userRow) {
  if (userRow is Map) {
    final v = userRow['count_lang'];
    if (v is num) return v.toInt();
    if (v != null) {
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
  }
  // Fall back to langs size.
  return extractLangs(userRow).length;
}

Map<String, dynamic> upsertLangSlot({
  required Map<String, dynamic> currentLangs,
  required int slot,
  required Map<String, dynamic> slotData,
}) {
  final next = <String, dynamic>{...currentLangs};
  next[slot.toString()] = slotData;
  return next;
}
