import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const settingsThemeModeKey = 'settings_theme_mode';
const _notificationsEnabledKey = 'settings_notifications_enabled';
const _exportCompletedKey = 'settings_notification_export_completed';
const _exportFailedKey = 'settings_notification_export_failed';
const _appTipsKey = 'settings_notification_app_tips';

class CineClipSettingsScreen extends StatefulWidget {
  const CineClipSettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  @override
  State<CineClipSettingsScreen> createState() => _CineClipSettingsScreenState();
}

class _CineClipSettingsScreenState extends State<CineClipSettingsScreen> {
  static const _cyan = Color(0xFF20D7FF);

  bool _notificationsEnabled = true;
  bool _exportCompleted = true;
  bool _exportFailed = true;
  bool _appTips = false;
  bool _loading = true;
  late ThemeMode _themeMode = widget.themeMode;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          preferences.getBool(_notificationsEnabledKey) ?? true;
      _exportCompleted = preferences.getBool(_exportCompletedKey) ?? true;
      _exportFailed = preferences.getBool(_exportFailedKey) ?? true;
      _appTips = preferences.getBool(_appTipsKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _saveNotificationPreference(
    String key,
    bool value,
    void Function(bool) update,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(key, value);
      if (!saved) throw StateError('Could not save this setting.');
      if (mounted) setState(() => update(value));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save setting: $error')));
    }
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    try {
      await widget.onThemeModeChanged(mode);
      if (!mounted) return;
      setState(() => _themeMode = mode);
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save appearance: $error')),
      );
    }
  }

  Future<void> _resetSettings() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will restore CineClip settings to their default values. '
          'Your saved videos and projects will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset != true || !mounted) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final defaults = <String, Object>{
        settingsThemeModeKey: 'system',
        _notificationsEnabledKey: true,
        _exportCompletedKey: true,
        _exportFailedKey: true,
        _appTipsKey: false,
      };
      for (final entry in defaults.entries) {
        final saved = switch (entry.value) {
          String value => await preferences.setString(entry.key, value),
          bool value => await preferences.setBool(entry.key, value),
          _ => false,
        };
        if (!saved) throw StateError('Could not reset setting "${entry.key}".');
      }

      await widget.onThemeModeChanged(ThemeMode.system);
      if (!mounted) return;
      setState(() {
        _themeMode = ThemeMode.system;
        _notificationsEnabled = true;
        _exportCompleted = true;
        _exportFailed = true;
        _appTips = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings restored to default.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset settings: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsGroup(
            title: 'PREFERENCES',
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: _themeModeLabel(_themeMode),
                onTap: _openAppearance,
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Choose notification preferences',
                onTap: _openNotifications,
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: _openLanguage,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'CINECLIP',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About CineClip',
                subtitle: 'Version 1.0.0',
                onTap: _openAbout,
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _openUnavailableLegalPage(
                  'Privacy Policy',
                  'An approved CineClip privacy policy has not been added yet.',
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms and Conditions',
                onTap: () => _openUnavailableLegalPage(
                  'Terms and Conditions',
                  'Approved CineClip terms have not been added yet.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'MAINTENANCE',
            children: [
              _SettingsTile(
                icon: Icons.restart_alt_rounded,
                title: 'Reset Settings to Default',
                titleColor: isDark
                    ? const Color(0xFFFF9A9A)
                    : const Color(0xFFB3261E),
                onTap: _resetSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System Default',
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
  };

  void _openAppearance() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Appearance')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const ListTile(
                title: Text('Theme Mode'),
                subtitle: Text('Choose how CineClip looks on your device.'),
              ),
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  title: Text(_themeModeLabel(mode)),
                  value: mode,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _changeThemeMode(value);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setPageState) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Choose which CineClip notifications you want to receive. '
                  'These preferences are saved, but notification delivery is '
                  'not available in this prototype yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Notifications'),
                  value: _notificationsEnabled,
                  onChanged: _loading
                      ? null
                      : (value) {
                          _saveNotificationPreference(
                            _notificationsEnabledKey,
                            value,
                            (value) {
                              _notificationsEnabled = value;
                              setPageState(() {});
                            },
                          );
                        },
                ),
                const Divider(),
                _notificationSwitch(
                  title: 'Export completed',
                  value: _exportCompleted,
                  enabled: _notificationsEnabled && !_loading,
                  key: _exportCompletedKey,
                  update: (value) => _exportCompleted = value,
                  setPageState: setPageState,
                ),
                _notificationSwitch(
                  title: 'Export failed',
                  value: _exportFailed,
                  enabled: _notificationsEnabled && !_loading,
                  key: _exportFailedKey,
                  update: (value) => _exportFailed = value,
                  setPageState: setPageState,
                ),
                _notificationSwitch(
                  title: 'App tips and updates',
                  value: _appTips,
                  enabled: _notificationsEnabled && !_loading,
                  key: _appTipsKey,
                  update: (value) => _appTips = value,
                  setPageState: setPageState,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationSwitch({
    required String title,
    required bool value,
    required bool enabled,
    required String key,
    required void Function(bool) update,
    required StateSetter setPageState,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: enabled
          ? (value) {
              _saveNotificationPreference(key, value, (value) {
                update(value);
                setPageState(() {});
              });
            }
          : null,
    );
  }

  void _openLanguage() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Language')),
          body: ListView(
            padding: EdgeInsets.all(20),
            children: [
              Text('Select the language used in CineClip.'),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.check_circle, color: _cyan),
                title: Text('English'),
                subtitle: Text('Currently supported'),
              ),
              ListTile(
                leading: Icon(Icons.translate_rounded),
                title: Text('More languages'),
                subtitle: Text(
                  'Additional translations are not available yet.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAbout() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('About CineClip')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Icon(Icons.movie_creation_rounded, size: 64, color: _cyan),
              SizedBox(height: 16),
              Text(
                'CineClip',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text('Turn Moments Into Movies', textAlign: TextAlign.center),
              SizedBox(height: 20),
              Text(
                'CineClip helps turn your favorite photos into memorable '
                'videos. Video creation and export are currently prototype '
                'features.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14),
              Text('Version 1.0.0', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _openUnavailableLegalPage(String title, String message) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                '$message Please contact the app team for current information.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Material(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
