import 'package:flutter/material.dart';

/// How every message in the app is shown: [ScaffoldMessengerState.showSnack]
/// instead of `showSnackBar`.
///
/// - It stays as long as it takes to read ([readingTime]), then goes. Flutter
///   otherwise keeps a message with a button ("Undo") on screen until it is
///   dismissed by hand.
/// - It has a close (×) for anyone done reading sooner.
/// - A new message replaces the one showing rather than queueing behind it,
///   so a burst of messages never keeps the screen busy for a minute.
extension ShowSnack on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnack(
    SnackBar bar,
  ) {
    removeCurrentSnackBar();
    return showSnackBar(
      SnackBar(
        key: bar.key,
        content: bar.content,
        backgroundColor: bar.backgroundColor,
        elevation: bar.elevation,
        margin: bar.margin,
        padding: bar.padding,
        width: bar.width,
        shape: bar.shape,
        behavior: bar.behavior,
        action: bar.action,
        onVisible: bar.onVisible,
        dismissDirection: bar.dismissDirection,
        duration: bar.duration == _flutterDefault
            ? readingTime(_textOf(bar.content), hasAction: bar.action != null)
            : bar.duration,
        persist: false,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }
}

const _flutterDefault = Duration(milliseconds: 4000);

/// Long enough to read [text] (about four words a second, plus a moment to
/// notice it), never under 3 s nor over 5 s (the × closes it sooner).
Duration readingTime(String text, {bool hasAction = false}) {
  final words = text.trim().isEmpty
      ? 0
      : text.trim().split(RegExp(r'\s+')).length;
  final ms = 1500 + words * 250 + (hasAction ? 1500 : 0);
  return Duration(milliseconds: ms.clamp(3000, 5000));
}

String _textOf(Widget content) {
  if (content is Text) {
    return content.data ?? content.textSpan?.toPlainText() ?? '';
  }
  return '';
}
