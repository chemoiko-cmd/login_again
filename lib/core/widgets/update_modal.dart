import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UpdateModal extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;
  final String currentVersion;
  final String latestVersion;

  const UpdateModal({
    super.key,
    required this.isOpen,
    required this.onUpdate,
    required this.onDismiss,
    required this.currentVersion,
    required this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ).animate().fade(duration: 200.ms),
        ),
        Center(
          child: Animate(
            effects: [
              FadeEffect(duration: 300.ms),
              ScaleEffect(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 300.ms,
              ),
              MoveEffect(
                begin: const Offset(0, 20),
                end: Offset.zero,
                duration: 300.ms,
              ),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Container(
                  //   height: 4,
                  //   decoration: const BoxDecoration(
                  //     gradient: LinearGradient(
                  //       colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                  //     ),
                  //     borderRadius: BorderRadius.vertical(
                  //       top: Radius.circular(24),
                  //     ),
                  //   ),
                  // ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.adjust),
                      onPressed: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        Animate(
                          onPlay: (controller) => controller.repeat(),
                          effects: [
                            RotateEffect(
                              duration: 2.seconds,
                              curve: Curves.linear,
                            ),
                          ],
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.system_update,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 12),
                        Text(
                          'A newer version of the app is available.',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update now to get the latest features and fixes.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current version: $currentVersion',
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Latest version: $latestVersion',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onUpdate,
                                icon: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: SvgPicture.asset(
                                    'assets/google_play.svg',
                                  ),
                                ),
                                label: const Text('Update Now'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
      ],
    );
  }
}
