import 'package:aihub/screens/ai_control.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool loadLastOpenedAi = true;
  String defaultAiName = 'ChatGPT';

  final GlobalKey _dropdownKey = GlobalKey();

  void _openDropdown() {
    GestureDetector? detector;
    void search(BuildContext? element) {
      element?.visitChildElements((child) {
        if (child.widget is GestureDetector) {
          detector = child.widget as GestureDetector;
        } else {
          search(child);
        }
      });
    }

    search(_dropdownKey.currentContext);
    detector?.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'AI Preferences',
            style: textTheme.titleMedium!.copyWith(
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
                'Enable this to automatically open the last used AI on startup.',
              ),
              value: loadLastOpenedAi,
              onChanged: (value) {
                setState(() => loadLastOpenedAi = value);
              },
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: loadLastOpenedAi ? null : _openDropdown,
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
                subtitle: Text(
                  loadLastOpenedAi
                      ? 'Disabled while "Load last opened AI" is ON.'
                      : 'Tap to choose which AI to load when app starts.',
                  style: TextStyle(
                    color: loadLastOpenedAi ? Colors.grey : null,
                  ),
                ),
                trailing: IgnorePointer(
                  ignoring: loadLastOpenedAi,
                  child: Opacity(
                    opacity: loadLastOpenedAi ? 0.5 : 1.0,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: _dropdownKey,
                        borderRadius: BorderRadius.circular(12),
                        value: defaultAiName,
                        items: aiList.map<DropdownMenuItem<String>>((ai) {
                          return DropdownMenuItem<String>(
                            value: ai['name'],
                            child: Text(ai['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => defaultAiName = value!);
                        },
                      ),
                    ),
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
                'Enable or disable AI features individually.',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiControlScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
