import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dto/listing_dtos.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/agency.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../property_overview/data/models/enums/property_type.dart';
import '../../../property_overview/data/models/room_score.dart';
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

  /// Which tab is showing. Active is where the agent works; Archived holds
  /// listings they have put away, searchable.
  bool _showArchived = false;

  final _searchController = TextEditingController();
  String _query = '';

  /// Listings without an address yet sit in a collapsible Drafts group below
  /// the real ones, so they don't crowd the list.
  bool _draftsExpanded = false;

  /// The Add Property button shrinks to a round "+" while scrolling down, so
  /// it covers less of the cards, and grows back when scrolling up.
  bool _fabExtended = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Archives or restores a listing, with Undo. Returns whether it worked,
  /// so a swiped card only leaves the list once the API agreed.
  Future<bool> _setArchived(ListingSummaryDto listing, bool archived) async {
    final theme = ref.read(themeConfigProvider);
    final repo = ref.read(propertyRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.setArchived(listing.id, archived: archived);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(mapFailure(e).message),
          backgroundColor: theme.error,
        ),
      );
      return false;
    }
    ref.invalidate(listingsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(archived ? 'Moved to Archived' : 'Moved back to Active'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await repo.setArchived(listing.id, archived: !archived);
            } finally {
              if (mounted) ref.invalidate(listingsProvider);
            }
          },
        ),
      ),
    );
    return true;
  }

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
      floatingActionButton: FloatingActionButton.extended(
        isExtended: _fabExtended,
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
                    // Not awaited: the busy flag only guards creating the
                    // listing. Awaiting the visit kept the button disabled
                    // for as long as that future stayed open — and a route
                    // left with go() rather than pop() never completes it,
                    // which is what left Add Property dead after a save.
                    unawaited(
                      context.push(AppRoutes.property(listingId)).then((
                        _,
                      ) async {
                        // Defer past the pop transition: invalidating the
                        // autoDispose listingsProvider synchronously swaps
                        // the ListView slivers while the outgoing route is
                        // still hit-testable (viewport.dart:1034).
                        await Future.delayed(const Duration(milliseconds: 400));
                        if (mounted) ref.invalidate(listingsProvider);
                      }),
                    );
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
      // A dark agency colour continues from the logo panel down both sides
      // and along the bottom, framing the page. A pale one (Rawson's yellow,
      // Leapfrog's lime) would be loud as a frame, so it is left out.
      body: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          border: _frameFor(theme.primaryColor),
        ),
        child: Column(
          children: [
            _HomeHeader(
              agency: agency,
              firstName: firstName,
              theme: theme,
              textTheme: textTheme,
            ),
            _ListingTabs(
              showArchived: _showArchived,
              listings: listingsAsync.value,
              theme: theme,
              textTheme: textTheme,
              onChanged: (archived) => setState(() {
                _showArchived = archived;
                _searchController.clear();
                _query = '';
              }),
            ),
            if (_showArchived)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ArchiveSearchField(
                  controller: _searchController,
                  theme: theme,
                  textTheme: textTheme,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Expanded(child: _buildListings(listingsAsync, theme, textTheme)),
          ],
        ),
      ),
    );
  }

  static const double _frameWidth = 3;

  static Border? _frameFor(Color brand) {
    if (brand.computeLuminance() > 0.4) return null;
    final side = BorderSide(color: brand, width: _frameWidth);
    return Border(left: side, right: side, bottom: side);
  }

  /// Deletes a draft listing after confirming.
  Future<void> _deleteDraft(ListingSummaryDto listing) async {
    final theme = ref.read(themeConfigProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text(
          '${listing.referenceNumber} has no address yet. Deleting it removes '
          'everything captured on it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: theme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(propertyRepositoryProvider).deleteListing(listing.id);
      ref.invalidate(listingsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('${listing.referenceNumber} deleted')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(mapFailure(e).message),
          backgroundColor: theme.error,
        ),
      );
    }
  }

  /// The listings for the current tab, newest first, filtered by the archive
  /// search.
  List<ListingSummaryDto> _visible(List<ListingSummaryDto> all) {
    final needle = _query.trim().toLowerCase();
    return all.where((l) => l.isArchived == _showArchived).where((l) {
      if (needle.isEmpty) return true;
      final haystack = l.searchText;
      // Every word typed must appear somewhere, so "cinsaut white"
      // finds Walter White's house on Cinsaut Street.
      return needle.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// A listing card that archives (or, in the archive, restores) on a swipe.
  Widget _swipeable(
    ListingSummaryDto listing,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    return Dismissible(
      key: ValueKey('listing-${listing.id}-$_showArchived'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _setArchived(listing, !_showArchived),
      background: _SwipeBackground(
        archiving: !_showArchived,
        theme: theme,
        textTheme: textTheme,
      ),
      child: _ListingCard(listing: listing, showCreatedDate: _showArchived),
    );
  }

  Widget _buildListings(
    AsyncValue<List<ListingSummaryDto>> listingsAsync,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    return listingsAsync.when(
      data: (all) {
        final listings = _visible(all);
        if (listings.isEmpty) {
          if (_showArchived) {
            return _buildArchiveEmpty(theme, textTheme);
          }
          return _buildEmptyState(theme, textTheme);
        }
        // Active tab: listings with an address, then the drafts group. The
        // archive keeps everything together (it is searched, not browsed).
        final drafts = _showArchived
            ? const <ListingSummaryDto>[]
            : listings.where((l) => l.addressLine.isEmpty).toList();
        final main = _showArchived
            ? listings
            : listings.where((l) => l.addressLine.isNotEmpty).toList();
        // With nothing but drafts, show them rather than an empty list.
        final draftsOpen = _draftsExpanded || main.isEmpty;

        final items = <Widget>[
          for (final listing in main) _swipeable(listing, theme, textTheme),
          if (drafts.isNotEmpty)
            _DraftsHeader(
              count: drafts.length,
              expanded: draftsOpen,
              canCollapse: main.isNotEmpty,
              theme: theme,
              textTheme: textTheme,
              onTap: () => setState(() => _draftsExpanded = !draftsOpen),
            ),
          if (draftsOpen)
            for (final draft in drafts)
              _DraftRow(
                listing: draft,
                theme: theme,
                textTheme: textTheme,
                onDelete: () => _deleteDraft(draft),
              ),
          if (main.isNotEmpty)
            Text(
              _showArchived
                  ? 'Swipe a property left to restore it.'
                  : 'Swipe a property left to archive it.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
        ];

        return NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            final extend = n.direction != ScrollDirection.reverse;
            if (n.direction != ScrollDirection.idle && extend != _fabExtended) {
              setState(() => _fabExtended = extend);
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(listingsProvider.future),
            child: ListView.separated(
              // Bottom padding clears the floating action button so the last
              // card is never hidden behind it.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => items[index],
            ),
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
    );
  }

  Widget _buildArchiveEmpty(RealEstateTheme theme, TextTheme textTheme) {
    final searching = _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          searching
              ? 'No archived property matches "${_query.trim()}".'
              : 'Nothing archived yet. Swipe a property left on the Active '
                    'tab to archive it.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: theme.textSecondary,
            height: 1.5,
          ),
        ),
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
/// The photo and street address lead; the reference number is left off because
/// it means nothing to the person reading it (it is still on the property
/// screen). Status stays as a badge so incomplete listings remain obvious.
class _ListingCard extends ConsumerWidget {
  final ListingSummaryDto listing;

  /// Archived cards show when the listing was created, since that is how an
  /// agent tells old listings of the same house apart.
  final bool showCreatedDate;

  const _ListingCard({required this.listing, this.showCreatedDate = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final isSubmitted = listing.status == 'submitted';
    final statusColor = isSubmitted ? theme.completeColor : theme.pendingColor;
    final propertyType = PropertyTypeExtension.fromId(listing.propertyTypeId);

    // Served inline by `GET /api/listings` — no per-card request. Older API
    // builds omit these fields, in which case the card shows placeholders.
    final addressLine = listing.addressLine;
    final ownerName = listing.ownersLine;
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderLight.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        // A ListView gives its items unbounded height, so the stretched Row needs
        // IntrinsicHeight to size itself to its tallest child. Without it layout
        // throws "BoxConstraints forces an infinite height" every frame and the
        // home screen freezes as soon as one listing is shown.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status at a glance down the list: amber in progress, green
              // submitted.
              Container(width: 4, color: statusColor),
              SizedBox(
                width: 104,
                height: 104,
                child: listing.primaryPhotoUrl == null
                    ? _PhotoPlaceholder(
                        icon: propertyType?.icon ?? Icons.home_outlined,
                        theme: theme,
                      )
                    : listingPhoto(
                        listing.primaryPhotoUrl,
                        theme: theme,
                        textTheme: textTheme,
                        cacheWidth: 300,
                        baseUrl: ref.watch(apiClientProvider).baseUrl,
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
                            : 'Draft · ${listing.referenceNumber}',
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
                      if (showCreatedDate) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: theme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Created ${DateFormat('d MMM yyyy').format(listing.createdAt.toLocal())}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // The status and type shrink (with an ellipsis) so the
                      // score badge always keeps its place on narrow phones.
                      Row(
                        children: [
                          Icon(
                            isSubmitted
                                ? Icons.check_circle_rounded
                                : Icons.pending_outlined,
                            size: 15,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: isSubmitted
                                        ? 'Submitted'
                                        : 'In progress',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (propertyType != null)
                                    TextSpan(
                                      text:
                                          '  ·  ${propertyType.displayString}',
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              style: textTheme.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (listing.houseScore case final score?) ...[
                            const SizedBox(width: 8),
                            _HouseScoreBadge(percent: score, theme: theme),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Drafts (n)" heading over the listings that have no address yet.
class _DraftsHeader extends StatelessWidget {
  final int count;
  final bool expanded;
  final bool canCollapse;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _DraftsHeader({
    required this.count,
    required this.expanded,
    required this.canCollapse,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canCollapse ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: theme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Drafts ($count)',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '  ·  no address yet',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ],
                ),
                style: textTheme.bodyMedium,
              ),
            ),
            if (canCollapse)
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: theme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact row for a draft: reference, type, when it was started, and a
/// delete button. Tapping opens it to carry on capturing.
class _DraftRow extends ConsumerWidget {
  final ListingSummaryDto listing;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onDelete;

  const _DraftRow({
    required this.listing,
    required this.theme,
    required this.textTheme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = PropertyTypeExtension.fromId(listing.propertyTypeId);
    final started = DateFormat(
      'd MMM yyyy',
    ).format(listing.createdAt.toLocal());
    return InkWell(
      onTap: () async {
        await context.push(AppRoutes.property(listing.id));
        await Future.delayed(const Duration(milliseconds: 400));
        if (context.mounted) ref.invalidate(listingsProvider);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              type?.icon ?? Icons.home_outlined,
              size: 22,
              color: theme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.referenceNumber,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [?type?.displayString, 'Started $started'].join('  ·  '),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete draft',
              icon: Icon(Icons.delete_outline, color: theme.textSecondary),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// The listing's house score as a small percentage pill.
class _HouseScoreBadge extends StatelessWidget {
  final double percent;
  final RealEstateTheme theme;

  const _HouseScoreBadge({required this.percent, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Tooltip(
      message: 'House score',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          RoomScore.percent(percent),
          style: textTheme.labelMedium?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          semanticsLabel: 'House score ${RoomScore.percent(percent)}',
        ),
      ),
    );
  }
}

/// Stand-in for a listing without a photo yet: the property-type glyph on a
/// wash of the agency colour, rather than a flat grey block.
class _PhotoPlaceholder extends StatelessWidget {
  final IconData icon;
  final RealEstateTheme theme;

  const _PhotoPlaceholder({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.16),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 30,
          color: theme.primaryColor.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Top of the home screen: the agency's logo filling a full-width panel, the
/// RealWorth wordmark beneath it, then the greeting.
///
/// The panel takes the colour of the logo artwork's own background
/// ([Agency.bannerColor]), so a square logo reads as filling it edge to edge.
class _HomeHeader extends StatelessWidget {
  final Agency agency;
  final String? firstName;

  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _HomeHeader({
    required this.agency,
    required this.firstName,
    required this.theme,
    required this.textTheme,
  });

  static const double _bannerHeight = 132;

  @override
  Widget build(BuildContext context) {
    final banner = agency.bannerColor;
    final isDarkBanner = banner.computeLuminance() < 0.5;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkBanner
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: banner,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: _bannerHeight,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: agencyLogoImage(
                        agency,
                        bundledFit: BoxFit.contain,
                        fallback: AgencyMonogram(
                          agency: agency,
                          size: _bannerHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // A solid bar in the agency's accent colour (e.g. Pam Golding's
            // gold) under the logo panel, running the full width.
            Container(height: 4, color: agency.secondaryColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The house mark is already the banner for RealWorth's own
                  // agents, so the wordmark would only repeat it.
                  if (agency != Agency.realWorth) ...[
                    Image.asset(
                      'assets/images/logo_wide.png',
                      height: 22,
                      // Navy artwork disappears on a dark surface.
                      color: isDarkMode ? theme.textPrimary : null,
                      semanticLabel: 'RealWorth',
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'My Properties',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (firstName != null && firstName!.isNotEmpty)
                    Text(
                      'Welcome back, $firstName',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active / Archived switch with counts.
class _ListingTabs extends StatelessWidget {
  final bool showArchived;
  final List<ListingSummaryDto>? listings;
  final ValueChanged<bool> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _ListingTabs({
    required this.showArchived,
    required this.listings,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final all = listings;
    String label(String name, bool archived) {
      if (all == null) return name;
      final n = all.where((l) => l.isArchived == archived).length;
      return '$name ($n)';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(label('Active', false)),
              icon: const Icon(Icons.home_work_outlined, size: 18),
            ),
            ButtonSegment(
              value: true,
              label: Text(label('Archived', true)),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
            ),
          ],
          selected: {showArchived},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: theme.primaryColor,
            selectedForegroundColor: theme.onPrimary,
            foregroundColor: theme.textSecondary,
            backgroundColor: theme.cardBackgroundColor,
            side: BorderSide(color: theme.borderLight),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Type-to-filter box for the archive: matches address, any owner, and the
/// reference numbers, updating the list as the agent types.
class _ArchiveSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _ArchiveSearchField({
    required this.controller,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      style: textTheme.bodyLarge?.copyWith(color: theme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search address, owner or reference',
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: theme.textSecondary.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(Icons.search, color: theme.textSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        isDense: true,
        filled: true,
        fillColor: theme.cardBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

/// What shows behind a card while it is swiped.
class _SwipeBackground extends StatelessWidget {
  final bool archiving;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _SwipeBackground({
    required this.archiving,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: archiving ? theme.textSecondary : theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            archiving ? Icons.inventory_2_outlined : Icons.unarchive_outlined,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            archiving ? 'Archive' : 'Restore',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
