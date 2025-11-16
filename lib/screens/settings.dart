import 'dart:convert';

import 'package:aihub/screens/ai_control.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool loadLastOpenedAi = true;
  String defaultAiName = 'ChatGPT';
  List<Map<String, dynamic>> _enabledAiList = [];
  String _fontSize = 'medium';
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final shouldLoadLast = await SharedPrefs.getLoadLastOpenedAi();
    final defaultAi = await SharedPrefs.getDefaultAiName();
    final fontSize = await SharedPrefs.getFontSize();

    _enabledAiList = [];
    for (var ai in aiList) {
      final isEnabled = await SharedPrefs.getAiStatus(ai['name']);
      if (isEnabled) {
        _enabledAiList.add(ai);
      }
    }

    String finalDefaultAi = defaultAi;
    if (!_enabledAiList.any((ai) => ai['name'] == defaultAi) &&
        _enabledAiList.isNotEmpty) {
      finalDefaultAi = _enabledAiList.first['name'];
      await SharedPrefs.setDefaultAiName(finalDefaultAi);
    }

    setState(() {
      loadLastOpenedAi = shouldLoadLast;
      defaultAiName = finalDefaultAi;
      _fontSize = fontSize;
    });
  }

  Future<void> _updateLoadLastOpenedAi(bool value) async {
    await SharedPrefs.setLoadLastOpenedAi(value);
    setState(() {
      loadLastOpenedAi = value;
    });
  }

  Future<void> _updateDefaultAiName(String value) async {
    await SharedPrefs.setDefaultAiName(value);
    setState(() {
      defaultAiName = value;
    });
  }

  Future<void> _updateFontSize(String value) async {
    await SharedPrefs.setFontSize(value);
    setState(() {
      _fontSize = value;
    });
  }

  String? _sameSiteToString(HTTPCookieSameSitePolicy? policy) {
    if (policy == null) return null;
    return switch (policy) {
      HTTPCookieSameSitePolicy.LAX => 'LAX',
      HTTPCookieSameSitePolicy.STRICT => 'STRICT',
      HTTPCookieSameSitePolicy.NONE => 'NONE',
      _ => null,
    };
  }

  HTTPCookieSameSitePolicy? _stringToSameSite(String? str) {
    if (str == null) return null;
    return switch (str) {
      'LAX' => HTTPCookieSameSitePolicy.LAX,
      'STRICT' => HTTPCookieSameSitePolicy.STRICT,
      'NONE' => HTTPCookieSameSitePolicy.NONE,
      _ => null,
    };
  }

  Future<void> _backupSettings() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final settings = await SharedPrefs.getAllSettings();
      final cookieManager = CookieManager.instance();
      final webCookies = <String, List<Map<String, dynamic>>>{};

      for (var ai in aiList) {
        final url = ai['url'] as String;
        final uri = WebUri(url);
        final domain = Uri.parse(url).host;

        final cookies = await cookieManager.getCookies(url: uri);
        if (cookies.isNotEmpty) {
          webCookies[domain] = cookies
              .map(
                (c) => {
                  'name': c.name,
                  'value': c.value,
                  'domain': c.domain,
                  'path': c.path,
                  'expiresDate': c.expiresDate,
                  'isSecure': c.isSecure,
                  'isHttpOnly': c.isHttpOnly,
                  'sameSite': _sameSiteToString(c.sameSite),
                },
              )
              .toList();
        }
      }

      final backupData = {
        'app_settings': settings,
        'webview_cookies': webCookies,
      };

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/aihub_backup_$timestamp.json');
      await file.writeAsString(jsonEncode(backupData));

      await SharePlus.instance.share(
        ShareParams(text: 'AIHub Backup', files: [XFile(file.path)]),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                const Text('Backup created successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: 8),
                Text('Backup failed: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _restoreSettings() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Icon(
            Icons.settings_backup_restore_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'Restore Backup',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'This will replace all your current settings and logins. Are you sure you want to continue?',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, false),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Restore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() {
          _isRestoring = false;
        });
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text('No file selected'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        setState(() {
          _isRestoring = false;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final appSettings = data['app_settings'] as Map<String, dynamic>;
      final rawCookies = data['webview_cookies'] as Map<String, dynamic>?;

      await SharedPrefs.restoreSettings(appSettings);

      if (rawCookies != null && rawCookies.isNotEmpty) {
        final cookieManager = CookieManager.instance();
        for (var entry in rawCookies.entries) {
          final domain = entry.key;
          final cookies = entry.value as List;
          final uri = WebUri('https://$domain');

          for (var c in cookies) {
            final map = c as Map<String, dynamic>;
            await cookieManager.setCookie(
              url: uri,
              name: map['name'],
              value: map['value'],
              domain: map['domain'],
              path: map['path'] ?? '/',
              expiresDate: map['expiresDate'],
              isSecure: map['isSecure'] ?? false,
              isHttpOnly: map['isHttpOnly'] ?? false,
              sameSite: _stringToSameSite(map['sameSite']),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                const Text('Settings restored successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: 8),
                Text('Restore failed: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpressiveSectionHeader(
              'AI Preferences',
              Icons.auto_awesome_rounded,
              theme,
            ),
            const SizedBox(height: 20),

            _buildExpressiveCard(
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  'Load last opened AI',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Automatically open the last used AI on startup',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.8),
                        colorScheme.secondary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                value: loadLastOpenedAi,
                onChanged: _updateLoadLastOpenedAi,
              ),
            ),

            if (!loadLastOpenedAi) ...[
              const SizedBox(height: 12),
              _buildExpressiveCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.tertiary.withValues(alpha: 0.8),
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Default AI',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: _enabledAiList.isEmpty
                      ? Text(
                          'No enabled AIs available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        )
                      : Text(
                          'Choose which AI to load when app starts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                  trailing: DropdownButton<String>(
                    borderRadius: BorderRadius.circular(16),
                    elevation: 4,
                    value:
                        _enabledAiList.any((ai) => ai['name'] == defaultAiName)
                        ? defaultAiName
                        : (_enabledAiList.isNotEmpty
                              ? _enabledAiList.first['name']
                              : null),
                    items: _enabledAiList.map<DropdownMenuItem<String>>((ai) {
                      return DropdownMenuItem<String>(
                        value: ai['name'],
                        child: Text(
                          ai['name'],
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateDefaultAiName(value);
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            _buildExpressiveCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiControlScreen(),
                  ),
                ).then((_) => _loadSettings());
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondary.withValues(alpha: 0.8),
                        colorScheme.tertiary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'AI Control',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Enable or disable AI features individually',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildExpressiveSectionHeader(
              'WebView Settings',
              Icons.web_rounded,
              theme,
            ),
            const SizedBox(height: 20),

            _buildExpressiveCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.8),
                        colorScheme.secondary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'WebView Font Size',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Adjust text size in AI WebView content',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: DropdownButton<String>(
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  value: _fontSize,
                  items: fontSizes.keys.map<DropdownMenuItem<String>>((size) {
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text(
                        size
                            .split('-')
                            .map(
                              (word) =>
                                  word[0].toUpperCase() + word.substring(1),
                            )
                            .join('-'),
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateFontSize(value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildExpressiveSectionHeader(
              'Data Management',
              Icons.settings_backup_restore_rounded,
              theme,
            ),
            const SizedBox(height: 20),

            isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          title: 'Backup Settings',
                          subtitle:
                              'Export your settings and login data to a secure file',
                          icon: Icons.backup_rounded,
                          color: colorScheme.primary,
                          isLoading: _isBackingUp,
                          onTap: _backupSettings,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          title: 'Restore Settings',
                          subtitle:
                              'Import your previous settings from a backup file',
                          icon: Icons.restore_rounded,
                          color: colorScheme.secondary,
                          isLoading: _isRestoring,
                          onTap: _restoreSettings,
                          theme: theme,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildActionCard(
                        title: 'Backup Settings',
                        subtitle:
                            'Export your settings and login data to a secure file',
                        icon: Icons.backup_rounded,
                        color: colorScheme.primary,
                        isLoading: _isBackingUp,
                        onTap: _backupSettings,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        title: 'Restore Settings',
                        subtitle:
                            'Import your previous settings from a backup file',
                        icon: Icons.restore_rounded,
                        color: colorScheme.secondary,
                        isLoading: _isRestoring,
                        onTap: _restoreSettings,
                        theme: theme,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressiveSectionHeader(
    String title,
    IconData icon,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.secondary.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildExpressiveCard({required Widget child, VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(minHeight: 180),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  right: -10,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(icon, size: 100, color: color),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    isLoading
                        ? LinearProgressIndicator(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: color,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
