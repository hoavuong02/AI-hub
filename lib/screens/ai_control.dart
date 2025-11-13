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
  bool _loadLastOpenedAi = true;

  @override
  void initState() {
    super.initState();
    _loadAiStatus();
  }

  Future<void> _loadAiStatus() async {
    final savedStatus = <String, bool>{};
    final defaultAi = await SharedPrefs.getDefaultAiName();
    final loadLastAi = await SharedPrefs.getLoadLastOpenedAi();

    for (var ai in aiList) {
      final name = ai['name'];
      final isEnabled = await SharedPrefs.getAiStatus(name);
      savedStatus[name] = isEnabled;
    }

    setState(() {
      aiStatus = savedStatus;
      _defaultAiName = defaultAi;
      _loadLastOpenedAi = loadLastAi;
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
    final isDefaultAiProtected = !_loadLastOpenedAi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Control'),
        centerTitle: true,
        elevation: 0,
      ),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: aiList.length,
                    itemBuilder: (context, index) {
                      final ai = aiList[index];
                      final name = ai['name'];
                      final icon = ai['icon'];
                      final color = ai['color'];
                      final desc = ai['desc'];
                      final isDefaultAi = name == _defaultAiName;
                      final isEnabled = aiStatus[name] ?? true;
                      final isSwitchDisabled =
                          isDefaultAi && isDefaultAiProtected;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: isDefaultAi && isDefaultAiProtected
                                ? Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: color, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color:
                                                  isDefaultAi &&
                                                      isDefaultAiProtected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    if (isDefaultAi && isDefaultAiProtected)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                                ),
                                if (isDefaultAi && isDefaultAiProtected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Default AI cannot be disabled when "Load last opened AI" is OFF',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                            value: isEnabled,
                            onChanged: isSwitchDisabled
                                ? null
                                : (value) {
                                    _updateAiStatus(name, value);
                                  },
                            activeThumbColor: theme.colorScheme.primary,
                          ),
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
