import 'package:flutter/material.dart';

/// A slim bar on top of the on-screen keyboard while a text field is being
/// typed in, as form-heavy apps (banking, insurance, iOS Settings) have:
/// ▲ ▼ go to the previous or next field, which scrolls into view above the
/// keyboard, and Done closes the keyboard so the rest of the screen and its
/// buttons show. With the keyboard up an agent could not tell whether more
/// fields followed; "More below" says so whenever there is a next field.
///
/// Wraps the whole app (`MaterialApp.builder`). Screens are told the keyboard
/// is the bar's height taller, so nothing they show ends up beneath it.
class KeyboardBar extends StatefulWidget {
  final Widget child;

  const KeyboardBar({super.key, required this.child});

  static const height = 44.0;

  @override
  State<KeyboardBar> createState() => _KeyboardBarState();
}

class _KeyboardBarState extends State<KeyboardBar> {
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    super.dispose();
  }

  // Every move between fields rebuilds the bar, so ▲ ▼ and "More below"
  // follow the field being typed in.
  void _focusChanged() {
    if (!mounted) return;
    setState(() => _typing = _isTextField(FocusManager.instance.primaryFocus));
  }

  static bool _isTextField(FocusNode? node) =>
      node?.context?.findAncestorStateOfType<EditableTextState>() != null;

  /// The text fields around the one being typed in, in the order the screen
  /// reads (buttons and chips in between are skipped).
  static (FocusNode?, FocusNode?) _neighbours() {
    final current = FocusManager.instance.primaryFocus;
    final scope = current?.nearestScope;
    if (current == null || scope == null) return (null, null);
    // Reading order: top to bottom, then left to right on the same line.
    final ordered =
        scope.traversalDescendants
            .where(
              (n) => n == current || (n.canRequestFocus && _isTextField(n)),
            )
            .toList()
          ..sort((a, b) {
            final dy = a.rect.top - b.rect.top;
            if (dy.abs() > 8) return dy.sign.toInt();
            return (a.rect.left - b.rect.left).sign.toInt();
          });
    final i = ordered.indexOf(current);
    if (i < 0) return (null, null);
    return (
      i > 0 ? ordered[i - 1] : null,
      i < ordered.length - 1 ? ordered[i + 1] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final show = _typing && keyboard > 0;
    if (!show) return widget.child;

    final (previous, next) = _neighbours();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        MediaQuery(
          data: media.copyWith(
            viewInsets: media.viewInsets.copyWith(
              bottom: keyboard + KeyboardBar.height,
            ),
          ),
          child: widget.child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: keyboard,
          height: KeyboardBar.height,
          child: Material(
            color: scheme.surfaceContainerHigh,
            elevation: 2,
            child: Row(
              children: [
                IconButton(
                  // No tooltips: the bar sits above the app's navigator, which
                  // holds the overlay they would need.
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    semanticLabel: 'Previous field',
                  ),
                  onPressed: previous?.requestFocus,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    semanticLabel: 'Next field',
                  ),
                  onPressed: next?.requestFocus,
                ),
                if (next != null)
                  Text(
                    'More below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
