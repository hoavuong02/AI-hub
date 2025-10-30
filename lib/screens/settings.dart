import 'package:aihub/screens/ai_control.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool loadLastOpenedAi = true;
  String defaultAiName = 'ChatGPT';
  List<Map<String, dynamic>> _enabledAiList = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final shouldLoadLast = await SharedPrefs.getLoadLastOpenedAi();
    final defaultAi = await SharedPrefs.getDefaultAiName();

    // Load enabled AI list
    _enabledAiList = [];
    for (var ai in aiList) {
      final isEnabled = await SharedPrefs.getAiStatus(ai['name']);
      if (isEnabled) {
        _enabledAiList.add(ai);
      }
    }

    // If default AI is disabled, fallback to first enabled AI
    String finalDefaultAi = defaultAi;
    if (!_enabledAiList.any((ai) => ai['name'] == defaultAi) &&
        _enabledAiList.isNotEmpty) {
      finalDefaultAi = _enabledAiList.first['name'];
      await SharedPrefs.setDefaultAiName(finalDefaultAi);
    }

    setState(() {
      loadLastOpenedAi = shouldLoadLast;
      defaultAiName = finalDefaultAi;
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
                ).then(
                  (_) => _loadSettings(),
                ); // Reload settings when returning
              },
            ),
          ),
        ],
      ),
    );
  }
}
