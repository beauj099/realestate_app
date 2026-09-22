import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/agency_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.loginPath);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final agency = ref.watch(agencyProvider);

    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: theme.cardBackgroundColor,
        title: Text('Settings', style: textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.borderLight, height: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Material(
              color: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: Text('Dark Mode', style: textTheme.titleMedium),
                subtitle: Text(
                  'Switch between light and dark appearance',
                  style: textTheme.bodyMedium,
                ),
                value: isDark,
                activeThumbColor: theme.primaryColor,
                onChanged: (value) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authState.displayName != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          AgencyLogo(agency: agency, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.displayName!,
                                  style: textTheme.titleMedium,
                                ),
                                Text(
                                  [
                                    authState.role,
                                    agency.name,
                                  ].whereType<String>().join(' · '),
                                  style: textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ListTile(
                    title: Text('My Profile', style: textTheme.titleMedium),
                    subtitle: Text(
                      'Name, contact details and agency',
                      style: textTheme.bodyMedium,
                    ),
                    leading: Icon(
                      Icons.person_outline,
                      color: theme.primaryColor,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.textSecondary,
                    ),
                    onTap: () => context.push(AppRoutes.profilePath),
                  ),
                  Divider(height: 1, color: theme.borderLight),
                  ListTile(
                    title: Text(
                      'Sign Out',
                      style: textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                    leading: Icon(Icons.logout, color: theme.primaryColor),
                    onTap: () => _handleLogout(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
