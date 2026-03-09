class AppConfig {
  /// Dev setting: when `false`, the UI will not require the user to confirm
  /// their email before proceeding.
  ///
  /// Note: Supabase Auth settings still control whether confirmation is
  /// enforced server-side.
  static const bool requireEmailConfirmation = false;
}
