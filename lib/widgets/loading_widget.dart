import 'package:flutter/material.dart';

class ExpressiveLoadingWidget extends StatelessWidget {
  final String aiName;
  final String domain;

  const ExpressiveLoadingWidget({
    super.key,
    required this.aiName,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            shadows: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 36,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                aiName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: ShapeDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Text(
                  domain,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Initializing AI capabilities...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
