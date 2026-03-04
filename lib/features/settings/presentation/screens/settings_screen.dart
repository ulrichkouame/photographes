/// Settings screen: dark/light mode, notifications, about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Persistent provider for the current theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Persists the user's theme preference in SharedPreferences.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'dark') {
      state = ThemeMode.dark;
    } else if (stored == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system',
    );
  }
}

/// Persistent provider for push notification opt-in.
final notificationsEnabledProvider =
    StateNotifierProvider<_BoolPrefsNotifier, bool>(
        (ref) => _BoolPrefsNotifier('notifications_enabled', defaultValue: true));

class _BoolPrefsNotifier extends StateNotifier<bool> {
  _BoolPrefsNotifier(this._key, {required bool defaultValue})
      : super(defaultValue) {
    _load(defaultValue);
  }

  final String _key;

  Future<void> _load(bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? defaultValue;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// Settings screen with theme toggle, notification preference and app info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // Appearance section
          const _SectionHeader(title: 'Apparence'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined, color: AppColors.gold),
            title: const Text('Thème'),
            subtitle: Text(
              themeMode == ThemeMode.dark
                  ? 'Sombre'
                  : themeMode == ThemeMode.light
                      ? 'Clair'
                      : 'Système',
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('Système')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text('Sombre')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                }
              },
            ),
          ),
          const Divider(height: 1),

          // Notifications section
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined,
                color: AppColors.gold),
            title: const Text('Activer les notifications'),
            subtitle: const Text('Recevez les alertes de réservation et messages'),
            value: notificationsEnabled,
            activeColor: AppColors.gold,
            onChanged: (_) =>
                ref.read(notificationsEnabledProvider.notifier).toggle(),
          ),
          const Divider(height: 1),

          // About section
          const _SectionHeader(title: 'À propos'),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.gold),
            title: const Text('Version'),
            trailing: Text(
              AppConstants.appVersion,
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.gold),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined, color: AppColors.gold),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.gold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
