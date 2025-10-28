import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';

class AiControlScreen extends StatefulWidget {
  const AiControlScreen({super.key});

  @override
  AiControlScreenState createState() => AiControlScreenState();
}

class AiControlScreenState extends State<AiControlScreen> {
  late Map<String, bool> aiStatus;
  final defaultAiName = 'ChatGPT';

  @override
  void initState() {
    super.initState();
    aiStatus = {for (var ai in aiList) ai['name']: true};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Control'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: aiList.length,
        itemBuilder: (context, index) {
          final ai = aiList[index];
          final name = ai['name'];
          final icon = ai['icon'];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('Enable or disable $name'),
              secondary: Icon(icon, color: theme.colorScheme.primary),
              value: aiStatus[name]!,
              onChanged: (value) {
                setState(() {
                  aiStatus[name] = value;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
