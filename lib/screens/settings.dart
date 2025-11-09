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
      if (mounted)
        setState(() {
          _isBackingUp = false;
        });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
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

      // Restore app settings
      await SharedPrefs.restoreSettings(appSettings);

      // Restore cookies
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
      if (mounted)
        setState(() {
          _isRestoring = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'AI Preferences',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              secondary: Icon(
                Icons.history_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Load last opened AI'),
              subtitle: const Text(
                'Automatically open the last used AI on startup',
              ),
              value: loadLastOpenedAi,
              onChanged: _updateLoadLastOpenedAi,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Icon(
                Icons.smart_toy_rounded,
                color: loadLastOpenedAi
                    ? Colors.grey
                    : theme.colorScheme.primary,
              ),
              title: const Text('Select Default AI'),
              subtitle: _enabledAiList.isEmpty
                  ? const Text('No enabled AIs available')
                  : Text(
                      loadLastOpenedAi
                          ? 'Disabled while "Load last opened AI" is ON'
                          : 'Choose which AI to load when app starts',
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
                        child: Text(ai['name']),
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
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Icon(
                Icons.psychology_alt_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('AI Control'),
              subtitle: const Text(
                'Enable or disable AI features individually',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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

          const SizedBox(height: 24),
          Text(
            'WebView Settings',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Icon(
                Icons.text_fields_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('WebView Font Size'),
              subtitle: const Text('Adjust text size in AI WebView content'),
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

          const SizedBox(height: 24),
          Text(
            'Data Management',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.backup_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Backup Settings'),
                  subtitle: const Text('Export your settings to a file'),
                  trailing: _isBackingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _isBackingUp ? null : _backupSettings,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.restore_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Restore Settings'),
                  subtitle: const Text('Import settings from a backup file'),
                  trailing: _isRestoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _isRestoring ? null : _restoreSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
