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

/// Address and owner for one listing card.
///
/// Kept separate from [listingsProvider] so a card renders its reference and
/// status immediately and fills in the human-readable detail when it arrives —
/// a slow or failed enrichment never blocks the list.
final listingCardInfoProvider = FutureProvider.autoDispose
    .family<({String addressLine, String ownerName}), int>((ref, id) async {
      final repo = ref.watch(propertyRepositoryProvider);
      return repo.getListingCardInfo(id);
    });

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onPressed: () async {
          try {
            final viewModel = ref.read(propertyViewModelProvider.notifier);
            viewModel.reset();
            final listingId = await viewModel.createNewListing();
            if (context.mounted) {
              await context.push(AppRoutes.property(listingId));
              ref.invalidate(listingsProvider);
            }
          } catch (e, st) {
            debugPrint('Add Property error: $e\n$st');
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(mapFailure(e).message)));
            }
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
        error: (error, _) => _buildEmptyState(theme, textTheme),
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
    final info = ref.watch(listingCardInfoProvider(listing.id));

    final isSubmitted = listing.status == 'submitted';
    final statusLabel = isSubmitted ? 'Submitted' : 'Incomplete';
    final propertyType = PropertyTypeExtension.fromId(listing.propertyTypeId);

    final cardInfo = info.asData?.value;
    final addressLine = cardInfo?.addressLine ?? '';
    final ownerName = cardInfo?.ownerName ?? '';
    final hasAddress = addressLine.isNotEmpty;

    return InkWell(
      onTap: () async {
        await context.push(AppRoutes.property(listing.id));
        ref.invalidate(listingsProvider);
        ref.invalidate(listingCardInfoProvider(listing.id));
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
              // Photos are captured on device and not yet uploaded, so a
              // listing fetched from the API has no hero image to show.
              child: listingPhoto(
                null,
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
                      hasAddress
                          ? addressLine
                          : (info.isLoading
                                ? 'Loading address…'
                                : 'No address yet'),
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
