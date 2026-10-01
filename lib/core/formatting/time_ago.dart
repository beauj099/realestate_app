import 'package:intl/intl.dart';

/// "3 days ago", "yesterday", "just now": in words an agent reads at a
/// glance; a date once it is over a month.
String timeAgo(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 2) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} minutes ago';
  if (d.inDays < 1) {
    return d.inHours == 1 ? 'an hour ago' : '${d.inHours} hours ago';
  }
  if (d.inDays == 1) return 'yesterday';
  if (d.inDays < 30) return '${d.inDays} days ago';
  return 'on ${DateFormat('d MMMM yyyy').format(at)}';
}
