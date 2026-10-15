import 'dart:async';

import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF08080A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _ringTrack = Color(0xFF27272A);

/// Full-screen loading shell: back control, optional site hero with ring loader, or [UILoading].
class UiLoadingPage extends StatelessWidget {
  const UiLoadingPage({
    super.key,
    this.onBack,
    this.message,
    this.hero,
    this.error,
    this.onRetry,
  });

  final VoidCallback? onBack;
  final String? message;
  final Widget? hero;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = error != null && error!.trim().isNotEmpty;
    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, color: _text),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (failed) ...[
                        Icon(Icons.cloud_off_outlined, size: 40, color: _muted),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: const TextStyle(color: _muted, fontSize: 14, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: const Color(0xFF052E16),
                            ),
                          ),
                        ],
                      ] else if (hero != null)
                        _UiLoadingPageHeroBody(message: message, hero: hero!)
                      else
                        UILoading(message: message),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UiLoadingPageHeroBody extends StatefulWidget {
  const _UiLoadingPageHeroBody({required this.hero, this.message});

  final Widget hero;
  final String? message;

  @override
  State<_UiLoadingPageHeroBody> createState() => _UiLoadingPageHeroBodyState();
}

class _UiLoadingPageHeroBodyState extends State<_UiLoadingPageHeroBody> {
  late final Stopwatch _sw;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: kUiElapsedTickMs), _onTick);
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible) {
      if (!_sw.isRunning) _sw.start();
      setState(() {});
    } else if (_sw.isRunning) {
      _sw
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      color: _muted,
      fontSize: 13,
      height: 1.35,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.hero,
          const SizedBox(height: 28),
          Text(uiLoadingElapsedLabel(_sw.elapsedMilliseconds, compact: false), style: muted),
          if (widget.message != null) ...[
            const SizedBox(height: 8),
            Text(widget.message!, style: muted, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Site editor bootstrap hero (avatar + name). Pass [loading] to show a ring around the avatar.
class UiLoadingPageSiteHero extends StatelessWidget {
  const UiLoadingPageSiteHero({
    super.key,
    required this.name,
    this.avatar,
    this.handle,
    this.loading = false,
  });

  final String name;
  final Widget? avatar;
  final String? handle;
  final bool loading;

  static const double _avatarSize = 76;
  static const double _ringSize = 92;

  @override
  Widget build(BuildContext context) {
    final title = name.trim().isEmpty ? 'Site' : name.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatar != null) _avatarFrame(avatar!),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        if (handle != null && handle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            handle!.trim(),
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _avatarFrame(Widget avatarChild) {
    final inner = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ringTrack, width: 2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: loading ? 0.18 : 0.1),
            blurRadius: 28,
            spreadRadius: loading ? 4 : 2,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(width: _avatarSize, height: _avatarSize, child: avatarChild),
      ),
    );

    if (!loading) return inner;

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _accent,
              backgroundColor: _ringTrack.withValues(alpha: 0.65),
            ),
          ),
          inner,
        ],
      ),
    );
  }
}
