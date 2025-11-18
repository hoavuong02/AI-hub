import 'package:aihub/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';

class AiControlScreen extends StatefulWidget {
  const AiControlScreen({super.key});

  @override
  AiControlScreenState createState() => AiControlScreenState();
}

class AiControlScreenState extends State<AiControlScreen>
    with SingleTickerProviderStateMixin {
  Map<String, bool> aiStatus = {};
  bool _isLoading = true;
  String _defaultAiName = 'ChatGPT';
  bool _loadLastOpenedAi = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

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

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        aiStatus = savedStatus;
        _defaultAiName = defaultAi;
        _loadLastOpenedAi = loadLastAi;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _updateAiStatus(String aiName, bool isEnabled) async {
    _triggerHapticFeedback();

    setState(() {
      aiStatus[aiName] = isEnabled;
    });

    await SharedPrefs.setAiStatus(aiName, isEnabled);

    _showStatusChangeSnackbar(aiName, isEnabled);
  }

  void _triggerHapticFeedback() {}

  void _showStatusChangeSnackbar(String aiName, bool isEnabled) {
    showSnackBar(
      context,
      Text('$aiName ${isEnabled ? 'enabled' : 'disabled'}'),
      SnackbarType.info,
      icon: isEnabled ? Icons.check : Icons.close,
    );
  }

  void _showAiDetails(BuildContext context, Map<String, dynamic> ai) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAiDetailSheet(context, ai),
    );
  }

  Widget _buildAiDetailSheet(BuildContext context, Map<String, dynamic> ai) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = aiStatus[ai['name']] ?? true;
    final detailedDesc = ai['detailedDesc'] ?? ai['desc'];

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ai['color'].withValues(alpha: 0.8),
                        _adjustColorBrightness(ai['color'], 1.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ai['color'].withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(ai['icon'], color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ai['name'],
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEnabled ? 'Active' : 'Inactive',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              detailedDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateAiStatus(ai['name'], !isEnabled);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(isEnabled ? 'Disable' : 'Enable'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _isLoading ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: Text(
            'AI Control Center',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _loadAiStatus,
              icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
              tooltip: 'Refresh AI Status',
            ),
        ],
      ),
      body: _isLoading
          ? _buildSimpleLoadingState(theme, colorScheme)
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _buildContent(theme, colorScheme),
            ),
    );
  }

  Widget _buildSimpleLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple animated container with icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 32),

          // Main title with fade animation
          AnimatedOpacity(
            opacity: _isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: Text(
              'AI Hub',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Loading your AI assistants...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Simple progress indicator
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the existing methods remain exactly the same...
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final isDefaultAiProtected = !_loadLastOpenedAi;
    final enabledCount = aiStatus.values.where((enabled) => enabled).length;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          sliver: SliverToBoxAdapter(
            child: _buildStatsHeader(theme, colorScheme, enabledCount),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final ai = aiList[index];
              final name = ai['name'];
              final isDefaultAi = name == _defaultAiName;
              final isEnabled = aiStatus[name] ?? true;
              final isSwitchDisabled = isDefaultAi && isDefaultAiProtected;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAiCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  ai: ai,
                  isDefaultAi: isDefaultAi,
                  isEnabled: isEnabled,
                  isSwitchDisabled: isSwitchDisabled,
                  isDefaultAiProtected: isDefaultAiProtected,
                  onChanged: (value) => _updateAiStatus(name, value),
                  onTap: () => _showAiDetails(context, ai),
                ),
              );
            }, childCount: aiList.length),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    int enabledCount,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_alt_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Ecosystem',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$enabledCount of ${aiList.length} AIs active',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(enabledCount / aiList.length * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Map<String, dynamic> ai,
    required bool isDefaultAi,
    required bool isEnabled,
    required bool isSwitchDisabled,
    required bool isDefaultAiProtected,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: isEnabled
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isDefaultAi && isDefaultAiProtected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      width: 2,
                    )
                  : null,
              gradient: isDefaultAi && isDefaultAiProtected
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.05),
                        colorScheme.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (isEnabled)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: CustomPaint(
                        painter: _AIPatternPainter(color: ai['color']),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedAIcon(ai, isEnabled),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ai['name'],
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  isDefaultAi &&
                                                      isDefaultAiProtected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    if (isDefaultAi && isDefaultAiProtected)
                                      _buildDefaultBadge(theme, colorScheme),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ai['desc'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          _buildEnhancedSwitch(
                            isEnabled: isEnabled,
                            isSwitchDisabled: isSwitchDisabled,
                            onChanged: onChanged,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatusIndicator(isEnabled, colorScheme, theme),
                          const Spacer(),
                          if (isDefaultAi && isDefaultAiProtected)
                            _buildProtectedInfo(theme, colorScheme),
                          IconButton(
                            onPressed: onTap,
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            tooltip: 'View AI Details',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAIcon(Map<String, dynamic> ai, bool isEnabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ai['color'].withValues(alpha: isEnabled ? 0.8 : 0.4),
            _adjustColorBrightness(ai['color'], isEnabled ? 1.2 : 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: ai['color'].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(ai['icon'], color: Colors.white, size: 28),
    );
  }

  Widget _buildDefaultBadge(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: colorScheme.onPrimary, size: 14),
          const SizedBox(width: 4),
          Text(
            'Default',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSwitch({
    required bool isEnabled,
    required bool isSwitchDisabled,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSwitchDisabled
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Transform.scale(
        scale: 1.1,
        child: Switch.adaptive(
          value: isEnabled,
          onChanged: isSwitchDisabled ? null : onChanged,

          activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
          inactiveThumbColor: colorScheme.outline,
          inactiveTrackColor: colorScheme.outline.withValues(alpha: 0.3),
          thumbIcon: WidgetStateProperty.all(
            Icon(
              isEnabled ? Icons.check : Icons.close,
              color: isEnabled
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    bool isEnabled,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isEnabled ? colorScheme.primary : colorScheme.outline,
              shape: BoxShape.circle,
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isEnabled ? 'Active' : 'Inactive',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isEnabled ? colorScheme.primary : colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectedInfo(ThemeData theme, ColorScheme colorScheme) {
    return Tooltip(
      message:
          'Default AI cannot be disabled when "Load last opened AI" is off',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: colorScheme.primary, size: 12),
            const SizedBox(width: 4),
            Text(
              'Protected',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _adjustColorBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(hsl.lightness * factor).toColor();
  }
}

class _AIPatternPainter extends CustomPainter {
  final Color color;

  _AIPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if ((x ~/ step + y ~/ step) % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 1, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
