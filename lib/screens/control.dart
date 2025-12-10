import 'dart:ui';

import 'package:aihub/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:aihub/utils/constants.dart';
import 'package:aihub/utils/shared_prefs.dart';
import 'package:flutter_svg/svg.dart';

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
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        curve: const Interval(0.1, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
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

    if (!savedStatus.containsValue(true) && savedStatus.isNotEmpty) {
      final firstAi = aiList.first['name'];
      savedStatus[firstAi] = true;
      await SharedPrefs.setAiStatus(firstAi, true);
    }

    await Future.delayed(const Duration(milliseconds: 600));

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
    final enabledCount = aiStatus.values.where((enabled) => enabled).length;
    final isDefaultAi = aiName == _defaultAiName;
    final isDefaultAiProtected = isDefaultAi && !_loadLastOpenedAi;

    if (!isEnabled && enabledCount <= 1 && !isDefaultAi) {
      _showLastAiWarning();
      return;
    }

    if (!isEnabled && isDefaultAiProtected) {
      showSnackBar(
        context,
        const Text(
          'Default AI cannot be disabled when "Load last opened AI" is off',
        ),
        SnackbarType.warning,
        icon: Icons.lock_rounded,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _triggerHapticFeedback();

    setState(() {
      aiStatus[aiName] = isEnabled;
    });

    await SharedPrefs.setAiStatus(aiName, isEnabled);

    _showStatusChangeSnackbar(aiName, isEnabled);
  }

  void _showLastAiWarning() {
    showSnackBar(
      context,
      const Text('At least one AI must remain enabled'),
      SnackbarType.warning,
      icon: Icons.warning_rounded,
      duration: const Duration(seconds: 2),
    );
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
    final enabledCount = aiStatus.values.where((enabled) => enabled).length;
    final isLastEnabled = isEnabled && enabledCount == 1;
    final isDefaultAi = ai['name'] == _defaultAiName;
    final isDefaultAiProtected = isDefaultAi && !_loadLastOpenedAi;
    final isButtonDisabled = isLastEnabled || isDefaultAiProtected;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: IntrinsicHeight(
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
                              ai['color'].withValues(alpha: 0.9),
                              _adjustColorBrightness(ai['color'], 1.3),
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
                            const SizedBox(height: 8),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                      boxShadow: isEnabled
                                          ? [
                                              BoxShadow(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.5),
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
                                      color: isEnabled
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        detailedDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isButtonDisabled)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDefaultAiProtected
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.1,
                              )
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDefaultAiProtected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: isDefaultAiProtected
                                ? colorScheme.primary
                                : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isDefaultAiProtected
                                  ? 'Default AI cannot be disabled when "Load last opened AI" is off'
                                  : 'This is your last enabled AI and cannot be disabled',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDefaultAiProtected
                                    ? colorScheme.onSurfaceVariant
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: isButtonDisabled
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _updateAiStatus(ai['name'], !isEnabled);
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: isEnabled
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEnabled ? Icons.power_off : Icons.power,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(isEnabled ? 'Disable' : 'Enable'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            'AI Control Panel',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? _buildSimpleLoadingState(theme, colorScheme)
          : _buildContent(theme, colorScheme),
    );
  }

  Widget _buildSimpleLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text(
            'Loading your AI assistants...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
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

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final enabledCount = aiStatus.values.where((enabled) => enabled).length;
    final isOnlyOneEnabled = enabledCount == 1;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          ),
        );
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                final isSwitchDisabled =
                    (isDefaultAi && !_loadLastOpenedAi) ||
                    (isOnlyOneEnabled && isEnabled && !isDefaultAi);

                return Padding(
                  padding: EdgeInsets.only(bottom: 16, top: index == 0 ? 0 : 0),
                  child: _buildAiCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    ai: ai,
                    isDefaultAi: isDefaultAi,
                    isEnabled: isEnabled,
                    isSwitchDisabled: isSwitchDisabled,
                    isDefaultAiProtected: !_loadLastOpenedAi,
                    isLastEnabled: isOnlyOneEnabled && isEnabled,
                    onChanged: (value) => _updateAiStatus(name, value),
                    onTap: () => _showAiDetails(context, ai),
                  ),
                );
              }, childCount: aiList.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    int enabledCount,
  ) {
    final isCritical = enabledCount == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCritical
                  ? Colors.orange.withValues(alpha: 0.1)
                  : colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCritical
                    ? Colors.orange.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: SvgPicture.string(
              iconSvgCode,
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(
                isCritical ? Colors.orange : colorScheme.primary,
                BlendMode.srcIn,
              ),
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
                  isCritical
                      ? 'Critical: Only 1 AI active'
                      : '$enabledCount of ${aiList.length} AIs active',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCritical
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCritical
                  ? Colors.orange.withValues(alpha: 0.1)
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCritical
                    ? Colors.orange.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${(enabledCount / aiList.length * 100).round()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCritical ? Colors.orange : colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
    required bool isLastEnabled,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    final showLastAiBadge = isLastEnabled && !isDefaultAi;
    final showProtectedInfo = isLastEnabled && !isDefaultAi;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isEnabled
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isLastEnabled && !isDefaultAi
                  ? Colors.orange.withValues(alpha: 0.3)
                  : isDefaultAi && isDefaultAiProtected
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width:
                  (isLastEnabled && !isDefaultAi) ||
                      (isDefaultAi && isDefaultAiProtected)
                  ? 2
                  : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isEnabled)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: ai['color'],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
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
                                            color: isLastEnabled && !isDefaultAi
                                                ? Colors.orange
                                                : isDefaultAi &&
                                                      isDefaultAiProtected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  if (isDefaultAi && isDefaultAiProtected)
                                    _buildDefaultBadge(theme, colorScheme),
                                  if (showLastAiBadge) _buildLastAiBadge(theme),
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
                          isLastEnabled: isLastEnabled && !isDefaultAi,
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
                        if (showProtectedInfo)
                          _buildLastAiInfo(theme, colorScheme),
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
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
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
                  color: ai['color'].withValues(alpha: 0.2),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: colorScheme.primary, size: 12),
          const SizedBox(width: 4),
          Text(
            'Default',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastAiBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, color: Colors.orange, size: 12),
          const SizedBox(width: 4),
          Text(
            'Last',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSwitch({
    required bool isEnabled,
    required bool isSwitchDisabled,
    required bool isLastEnabled,
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
          activeThumbColor: isLastEnabled ? Colors.orange : colorScheme.primary,
          activeTrackColor: isLastEnabled
              ? Colors.orange.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.3),
          inactiveThumbColor: colorScheme.outline,
          inactiveTrackColor: colorScheme.outline.withValues(alpha: 0.2),
          thumbIcon: WidgetStateProperty.all(
            Icon(
              isEnabled ? Icons.check : Icons.close,
              color: isEnabled
                  ? (isLastEnabled ? Colors.orange : Colors.white)
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
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
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

  Widget _buildLastAiInfo(ThemeData theme, ColorScheme colorScheme) {
    return Tooltip(
      message: 'This is your last active AI and cannot be disabled',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.priority_high_rounded, color: Colors.orange, size: 12),
            const SizedBox(width: 4),
            Text(
              'Protected',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectedInfo(ThemeData theme, ColorScheme colorScheme) {
    return Tooltip(
      message: 'Default AI protected when "Load last opened AI" is off',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: colorScheme.primary, size: 12),
            const SizedBox(width: 4),
            Text(
              'Locked',
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
