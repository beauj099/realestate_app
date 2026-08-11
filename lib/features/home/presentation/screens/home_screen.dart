import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dto/listing_dtos.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../property_wizard/providers/property_provider.dart';

final listingsProvider = FutureProvider.autoDispose<List<ListingSummaryDto>>((
  ref,
) {
  final api = ref.watch(listingApiServiceProvider);
  return api.getAll();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: theme.cardBackgroundColor,
        title: Text('My Properties', style: textTheme.titleLarge),
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
        onPressed: () {
          ref.read(propertyViewModelProvider.notifier).reset();
          context.push('/wizard/property-type');
        },
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) return _buildEmptyState(theme, textTheme);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(listingsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _buildListingCard(listing, theme, textTheme);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildEmptyState(theme, textTheme),
      ),
    );
  }

  Widget _buildListingCard(
    ListingSummaryDto listing,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.referenceNumber,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${listing.status}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: listing.status == 'draft'
                  ? theme.pendingColor.withValues(alpha: 0.15)
                  : theme.completeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              listing.status.toUpperCase(),
              style: textTheme.labelLarge?.copyWith(
                color: listing.status == 'draft'
                    ? theme.pendingColor
                    : theme.completeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
              'Tap the button below to add your first property listing.',
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
