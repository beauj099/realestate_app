import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/themes.dart';

/// Covers the whole screen while [busy]: a light grey veil that swallows every
/// tap, and a spinner in the middle with a message that changes every few
/// seconds, so a long save visibly keeps working instead of looking stuck.
///
/// Wrap the screen's whole `Scaffold` so the app bar and pinned buttons are
/// covered too.
class BusyOverlay extends StatelessWidget {
  final bool busy;
  final Widget child;
  final RealEstateTheme theme;

  /// The first line shown, e.g. "Saving Property Features…". The rotating
  /// messages follow it.
  final String? title;

  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    required this.theme,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: _BusyVeil(theme: theme, title: title),
          ),
      ],
    );
  }
}

class _BusyVeil extends StatefulWidget {
  final RealEstateTheme theme;
  final String? title;

  const _BusyVeil({required this.theme, this.title});

  @override
  State<_BusyVeil> createState() => _BusyVeilState();
}

class _BusyVeilState extends State<_BusyVeil> {
  /// Shown in turn after the title, every [_interval].
  static const messages = [
    'Working on it…',
    'Saving all information…',
    'Uploading photos…',
    'Still busy…',
    'Checking everything is in place…',
    'Calculating results…',
    'Just a little while longer…',
    'Almost there…',
  ];

  static const _interval = Duration(milliseconds: 3500);

  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) {
      if (mounted) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _message {
    final title = widget.title;
    if (title != null && _step == 0) return title;
    final index = title == null ? _step : _step - 1;
    return messages[index % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        // Swallows every tap and blocks the back gesture's hit-testing.
        const ModalBarrier(dismissible: false, color: Color(0x66A0A4AA)),
        Center(
          child: Semantics(
            liveRegion: true,
            label: _message,
            child: Container(
              width: 240,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: theme.primaryColor,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 44,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _message,
                        key: ValueKey(_step),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
