import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dto/listing_dtos.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../property_overview/data/models/enums/property_type.dart';
import '../../../property_overview/providers/property_provider.dart';
import '../../../settings/presentation/widgets/agency_logo.dart';

final listingsProvider = FutureProvider.autoDispose<List<ListingSummaryDto>>((
  ref,
) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getAllListings();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;
    final listingsAsync = ref.watch(listingsProvider);
    final authState = ref.watch(authProvider);
    final agency = ref.watch(agencyProvider);
    final firstName = authState.displayName
        ?.trim()
        .split(RegExp(r'\s+'))
        .firstWhere((p) => p.isNotEmpty, orElse: () => '');

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: theme.cardBackgroundColor,
        titleSpacing: 16,
        // The agency mark makes it obvious whose white-label build this is.
        title: Row(
          children: [
            AgencyLogo(agency: agency, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My Properties',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (firstName != null && firstName.isNotEmpty)
                    Text(
                      'Welcome back, $firstName',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.borderLight, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Property',
          style: textTheme.labelLarge?.copyWith(
            color: theme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _isCreating
            ? null
            : () async {
                if (_isCreating) return;
                setState(() => _isCreating = true);
                try {
                  final viewModel = ref.read(
                    propertyViewModelProvider.notifier,
                  );
                  viewModel.reset();
                  final listingId = await viewModel.createNewListing();
                  if (context.mounted) {
                    await context.push(AppRoutes.property(listingId));
                    // Defer past the pop transition: invalidating the
                    // autoDispose listingsProvider synchronously swaps the
                    // ListView slivers while the outgoing route is still
                    // hit-testable (viewport.dart:1034 on web/desktop).
                    // Navigator.pop completes the future before the animation
                    // starts, so we wait 400ms for it to finish.
                    await Future.delayed(const Duration(milliseconds: 400));
                    if (context.mounted) {
                      ref.invalidate(listingsProvider);
                    }
                  }
                } catch (e, st) {
                  // TEMPORARY diagnostics: print the full failure so the
                  // get/post-listings problem can be traced, then remove once
                  // fixed. The SnackBar below keeps showing the user message.
                  debugPrint('Add Property error: $e\n$st');
                  if (e is DioException) {
                    debugPrint(
                      'Add Property response: '
                      '${e.response?.statusCode} ${e.response?.data}',
                    );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(mapFailure(e).message)),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isCreating = false);
                }
              },
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) return _buildEmptyState(theme, textTheme);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(listingsProvider.future),
            child: ListView.separated(
              // Bottom padding clears the floating action button so the last
              // card is never hidden behind it.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ListingCard(listing: listings[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // TEMPORARY diagnostics: show the real failure reason on screen
        // (plus full details in the console) so the get-listings problem
        // can be traced. Previously this silently showed the empty state.
        error: (error, stack) {
          debugPrint('Home listings error: $error\n$stack');
          if (error is DioException) {
            debugPrint(
              'Home listings response: '
              '${error.response?.statusCode} ${error.response?.data}',
            );
          }
          return _buildErrorState(
            theme,
            textTheme,
            mapFailure(error).message,
            onRetry: () => ref.invalidate(listingsProvider),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(RealEstateTheme theme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 80, color: theme.borderLight),
            const SizedBox(height: 24),
            Text(
              'No properties yet',
              style: textTheme.titleLarge?.copyWith(color: theme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the button below to add your first property.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TEMPORARY diagnostics widget: shows the failure reason with a retry
  /// button. Remove once the get-listings problem is fixed and restore the
  /// plain empty state for errors.
  Widget _buildErrorState(
    RealEstateTheme theme,
    TextTheme textTheme,
    String message, {
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 80, color: theme.borderLight),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load properties',
              style: textTheme.titleLarge?.copyWith(color: theme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A listing, identified the way an agent thinks of it.
///
/// The photo and street address lead; the reference number is demoted to small
/// print because it means nothing to the person reading it. Status stays as a
/// badge so incomplete listings remain obvious.
class _ListingCard extends ConsumerWidget {
  final ListingSummaryDto listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final isSubmitted = listing.status == 'submitted';
    final statusLabel = isSubmitted ? 'Submitted' : 'Incomplete';
    final propertyType = PropertyTypeExtension.fromId(listing.propertyTypeId);

    // Served inline by `GET /api/listings` — no per-card request. Older API
    // builds omit these fields, in which case the card shows placeholders.
    final addressLine = listing.addressLine;
    final ownerName = (listing.primaryOwnerName ?? '').trim();
    final hasAddress = addressLine.isNotEmpty;

    return InkWell(
      onTap: () async {
        await context.push(AppRoutes.property(listing.id));
        // Same deferral as above: let the pop animation finish before the
        // listings FutureProvider rebuilds the slivers underneath the pointer.
        await Future.delayed(const Duration(milliseconds: 400));
        if (context.mounted) {
          ref.invalidate(listingsProvider);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: listingPhoto(
                listing.primaryPhotoUrl,
                theme: theme,
                textTheme: textTheme,
                cacheWidth: 300,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasAddress ? addressLine : 'No address yet',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasAddress
                            ? theme.textPrimary
                            : theme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ownerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 13,
                            color: theme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ownerName,
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusBadge(
                          label: statusLabel,
                          isSubmitted: isSubmitted,
                          theme: theme,
                          textTheme: textTheme,
                        ),
                        if (propertyType != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            propertyType.icon,
                            size: 13,
                            color: theme.textSecondary,
                          ),
                        ],
                        const Spacer(),
                        Flexible(
                          child: Text(
                            listing.referenceNumber,
                            style: textTheme.labelMedium?.copyWith(
                              color: theme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isSubmitted;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _StatusBadge({
    required this.label,
    required this.isSubmitted,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSubmitted ? theme.completeColor : theme.pendingColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
