import 'dart:convert';

import 'package:aihub/screens/ai_control.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _backupSettings() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final settings = await SharedPrefs.getAllSettings();

      final settingsJson = jsonEncode(settings);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/aihub_backup_$timestamp.json');
      await backupFile.writeAsString(settingsJson);

      await SharePlus.instance.share(
        ShareParams(
          text: 'AIHub Settings Backup',
          files: [XFile(backupFile.path)],
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings backed up successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to backup settings: $e'),
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
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Settings'),
          content: const Text(
            'This will overwrite all your current settings. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (shouldRestore != true) {
        setState(() {
          _isRestoring = false;
        });
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        if (content.isEmpty) {
          throw Exception('Backup file is empty');
        }

        final decodedJson = jsonDecode(content);
        if (decodedJson is! Map<String, dynamic>) {
          throw Exception('Invalid backup file format');
        }

        await SharedPrefs.restoreSettings(decodedJson);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          _loadSettings();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup file selected.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore settings: $e'),
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
