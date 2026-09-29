import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/themes.dart';

/// Asks the agent to confirm deleting their account, with their password,
/// and deletes it (`POST /api/agents/me/delete`): switched off at once,
/// restorable by signing in for 90 days, then the agent's details go; their
/// listings stay. True when it was deleted; the caller then signs out. App
/// stores require this in the app.
Future<bool> showDeleteAccountDialog(
  BuildContext context,
  RealEstateTheme theme,
) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(theme: theme),
    ) ??
    false;

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  final RealEstateTheme theme;

  const _DeleteAccountDialog({required this.theme});

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post<void>(
            ApiEndpoints.agentDeleteMe,
            data: {'password': _password.text},
          );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.response?.statusCode == 400
            ? 'That password is not right.'
            : 'Could not delete your account. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account is switched off straight away. Changed your mind? '
              'Sign in again within 90 days and everything is back as it was.\n\n'
              'After 90 days your name, contact details, registration numbers, '
              'photo, signature and profile are deleted for good. The listings '
              'you captured stay with your agency, and the sales you logged stay '
              'in the shared market data, without your name.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Your password',
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _busy ? null : _delete(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.error),
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete for good'),
        ),
      ],
    );
  }
}
