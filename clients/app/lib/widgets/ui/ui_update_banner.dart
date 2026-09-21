import 'package:alienai_c35/c/update/app_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UiUpdateChrome extends StatelessWidget {
  const UiUpdateChrome({super.key});
  static const _chromeKey = ValueKey('app-update-chrome');

  @override
  Widget build(BuildContext context) {
    if (kDebugMode || defaultTargetPlatform != TargetPlatform.windows) return const SizedBox.shrink();
    return RepaintBoundary(
      key: _chromeKey,
      child: ValueListenableBuilder<AppUpdateState>(
        valueListenable: AppUpdateService.instance.state,
        builder: (_, s, __) {
          final show = s.phase == AppUpdatePhase.ready || s.phase == AppUpdatePhase.forceRequired || s.phase == AppUpdatePhase.downloading;
          if (!show) return const SizedBox.shrink();
          final label = s.phase == AppUpdatePhase.downloading
              ? 'Downloading ${s.release?.label ?? 'update'}… ${(s.progress * 100).round()}%'
              : 'Update ${s.release?.label ?? ''} ready';
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11)),
                    if (s.phase == AppUpdatePhase.ready || s.phase == AppUpdatePhase.forceRequired) ...[
                      const SizedBox(width: 6),
                      Material(
                        color: const Color(0xFF34D399),
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: () => AppUpdateService.instance.installNow(),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('Restart', style: TextStyle(color: Color(0xFF052E1C), fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class UiUpdateForceGate extends StatelessWidget {
  const UiUpdateForceGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (kDebugMode || defaultTargetPlatform != TargetPlatform.windows) return child;
    return ValueListenableBuilder<AppUpdateState>(
      valueListenable: AppUpdateService.instance.state,
      builder: (_, s, __) {
        if (s.phase != AppUpdatePhase.forceRequired) return child;
        return ColoredBox(
          color: const Color(0xFF08080A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.system_update_alt, size: 36, color: Color(0xFF34D399)),
                  const SizedBox(height: 16),
                  Text('Update required', style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('This version is no longer supported. Install ${s.release?.label ?? 'the latest update'} to continue.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => AppUpdateService.instance.installNow(),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                    child: Text(s.progress < 1 ? 'Downloading… ${(s.progress * 100).round()}%' : 'Update now'),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
