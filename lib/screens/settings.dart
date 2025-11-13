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
          const SnackBar(
            content: Text('Backup created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
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
          title: const Text('Restore Backup'),
          content: const Text(
            'This will replace all settings and logins. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restore'),
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
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('Restored! Restart app to see changes.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('AI Preferences', Icons.smart_toy_rounded, theme),
          const SizedBox(height: 12),

          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              title: Text(
                'Load last opened AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Automatically open the last used AI on startup',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              value: loadLastOpenedAi,
              onChanged: _updateLoadLastOpenedAi,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),

          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (loadLastOpenedAi || _enabledAiList.isEmpty)
                      ? Colors.grey.withValues(alpha: 0.15)
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: (loadLastOpenedAi || _enabledAiList.isEmpty)
                      ? Colors.grey
                      : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Select Default AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: _enabledAiList.isEmpty
                  ? Text(
                      'No enabled AIs available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    )
                  : Text(
                      loadLastOpenedAi
                          ? 'Disabled while "Load last opened AI" is ON'
                          : 'Choose which AI to load when app starts',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 13,
                      ),
                    ),
              trailing: IgnorePointer(
                ignoring: loadLastOpenedAi || _enabledAiList.isEmpty,
                child: Opacity(
                  opacity: (loadLastOpenedAi || _enabledAiList.isEmpty)
                      ? 0.5
                      : 1.0,
                  child: DropdownButton<String>(
                    borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (loadLastOpenedAi || _enabledAiList.isEmpty)
                        ? null
                        : (value) {
                            if (value != null) {
                              _updateDefaultAiName(value);
                            }
                          },
                  ),
                ),
              ),
            ),
          ),

          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'AI Control',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Enable or disable AI features individually',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiControlScreen(),
                  ),
                ).then((_) => _loadSettings());
              },
            ),
          ),

          _buildSectionHeader('WebView Settings', Icons.web_rounded, theme),
          const SizedBox(height: 12),

          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.text_fields_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'WebView Font Size',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Adjust text size in AI WebView content',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              trailing: DropdownButton<String>(
                borderRadius: BorderRadius.circular(12),
                value: _fontSize,
                items: fontSizes.keys.map<DropdownMenuItem<String>>((size) {
                  return DropdownMenuItem<String>(
                    value: size,
                    child: Text(
                      size
                          .split('-')
                          .map(
                            (word) => word[0].toUpperCase() + word.substring(1),
                          )
                          .join('-'),
                      style: const TextStyle(fontSize: 13),
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

          _buildSectionHeader('Data Management', Icons.backup_rounded, theme),
          const SizedBox(height: 12),

          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.backup_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Backup Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Export your settings to a file',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  trailing: _isBackingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                  onTap: _isBackingUp ? null : _backupSettings,
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restore_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Restore Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Import settings from a backup file',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  trailing: _isRestoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                  onTap: _isRestoring ? null : _restoreSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
