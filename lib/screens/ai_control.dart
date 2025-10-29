import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';

class AiControlScreen extends StatefulWidget {
  const AiControlScreen({super.key});

  @override
  AiControlScreenState createState() => AiControlScreenState();
}

class AiControlScreenState extends State<AiControlScreen> {
  Map<String, bool> aiStatus = {};
  bool _isLoading = true;
  String _defaultAiName = 'ChatGPT';

  @override
  void initState() {
    super.initState();
    _loadAiStatus();
  }

  Future<void> _loadAiStatus() async {
    final savedStatus = <String, bool>{};
    final defaultAi = await SharedPrefs.getDefaultAiName();

    for (var ai in aiList) {
      final name = ai['name'];
      final isEnabled = await SharedPrefs.getAiStatus(name);
      savedStatus[name] = isEnabled;
    }

    setState(() {
      aiStatus = savedStatus;
      _defaultAiName = defaultAi;
      _isLoading = false;
    });
  }

  Future<void> _updateAiStatus(String aiName, bool isEnabled) async {
    await SharedPrefs.setAiStatus(aiName, isEnabled);
    setState(() {
      aiStatus[aiName] = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Control'), centerTitle: true),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading AI settings...'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Enable or disable AI assistants. Disabled AIs will be hidden from the main list.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Default AI ($_defaultAiName) cannot be disabled',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: aiList.length,
                    itemBuilder: (context, index) {
                      final ai = aiList[index];
                      final name = ai['name'];
                      final icon = ai['icon'];
                      final color = ai['color'];
                      final isDefaultAi = name == _defaultAiName;
                      final isEnabled = aiStatus[name] ?? true;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDefaultAi
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (isDefaultAi)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: isDefaultAi
                              ? const Text('Default AI cannot be disabled')
                              : Text('Enable or disable $name'),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isDefaultAi && !isEnabled
                                  ? theme.colorScheme.primary
                                  : color,
                            ),
                          ),
                          value: isEnabled,
                          onChanged: isDefaultAi
                              ? null // Disable switch for default AI
                              : (value) {
                                  _updateAiStatus(name, value);
                                },
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
