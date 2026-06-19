import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Clés SharedPreferences ─────────────────────────────────────
const _kLanguage = 'pref_language';
const _kNotifications = 'pref_notifications';

// ── Langue ────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('fr') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kLanguage) ?? 'fr';
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
    state = code;
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((_) => LanguageNotifier());

/// Map code → libellé affiché
const languageLabels = {
  'fr': 'Français',
  'wo': 'Wolof',
};

// ── Notifications ─────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kNotifications) ?? true;
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
    state = value;
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
        (_) => NotificationsNotifier());
