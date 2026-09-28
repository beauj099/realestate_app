import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../data/models/address_suggestion.dart';
import '../../providers/property_report_provider.dart';

/// Type an address, pick it from a list — anywhere in South Africa.
///
/// Each pause in typing runs two searches at once: the Cape Town and
/// Johannesburg parcel records (under a second; every numbered result is a
/// real erf with its location) and OpenStreetMap for the whole country (a few
/// seconds). The list shows whichever has answered, merged into one order
/// ([mergeSuggestions]), at most six rows. Places near [nearLat]/[nearLng]
/// (the listing's pin) or else the agent's last known location come first.
class AddressSearchField extends ConsumerStatefulWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<AddressSuggestion> onPick;
  final double? nearLat;
  final double? nearLng;

  /// Off in tests: there is no location plugin there.
  final bool useDeviceLocation;

  const AddressSearchField({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.onPick,
    this.nearLat,
    this.nearLng,
    this.useDeviceLocation = true,
  });

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  static const _pause = Duration(milliseconds: 300);
  static const _minLength = 3;
  static const _maxRows = 6;

  final _controller = TextEditingController();
  Timer? _debounce;

  /// Only answers to the newest text are shown.
  int _generation = 0;
  List<AddressSuggestion> _city = const [];
  List<AddressSuggestion> _national = const [];
  bool _cityPending = false;
  bool _nationalPending = false;
  bool _failed = false;
  double? _deviceLat;
  double? _deviceLng;

  @override
  void initState() {
    super.initState();
    if (widget.useDeviceLocation) unawaited(_readLastKnownLocation());
  }

  /// Only if the agent has already allowed location: this never asks.
  Future<void> _readLastKnownLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final position = await Geolocator.getLastKnownPosition();
      if (position == null || !mounted) return;
      _deviceLat = position.latitude;
      _deviceLng = position.longitude;
    } catch (_) {
      // No location: suggestions are just not biased.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _typed => _controller.text.trim().length >= _minLength;

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < _minLength) {
      _generation++;
      setState(() {
        _city = const [];
        _national = const [];
        _cityPending = false;
        _nationalPending = false;
        _failed = false;
      });
      return;
    }
    // Keep showing the last answers while the next ones come.
    setState(() {});
    _debounce = Timer(_pause, () => _search(text.trim()));
  }

  void _search(String text) {
    final generation = ++_generation;
    final lat = widget.nearLat ?? _deviceLat;
    final lng = widget.nearLng ?? _deviceLng;
    final repo = ref.read(propertyReportRepositoryProvider);
    setState(() {
      _cityPending = true;
      _nationalPending = true;
      _failed = false;
    });

    Future<void> run(bool national) async {
      List<AddressSuggestion> found;
      var failed = false;
      try {
        found = await repo.suggest(
          text,
          national: national,
          lat: lat,
          lng: lng,
        );
      } catch (_) {
        found = const [];
        failed = true;
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        if (national) {
          _national = found;
          _nationalPending = false;
        } else {
          _city = found;
          _cityPending = false;
        }
        // Both searches failing is worth saying; one failing is not.
        _failed = failed && !_cityPending && !_nationalPending &&
            _city.isEmpty && _national.isEmpty;
      });
    }

    unawaited(run(false));
    unawaited(run(true));
  }

  void _clear() {
    _debounce?.cancel();
    _generation++;
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _city = const [];
      _national = const [];
      _cityPending = false;
      _nationalPending = false;
      _failed = false;
    });
  }

  void _pick(AddressSuggestion s) {
    widget.onPick(s);
    _clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = widget.textTheme;
    final rows = mergeSuggestions(_city, _national, limit: _maxRows);
    final searching = _cityPending || _nationalPending;
    final creditOsm = rows.any((s) => s.fromOpenStreetMap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextInput(
          theme: theme,
          label: 'Search address',
          placeholder: 'Street, suburb or complex',
          controller: _controller,
          onChanged: _onChanged,
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.words,
          autocorrect: false,
          prefixIcon: Icon(Icons.search, color: theme.textSecondary),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  onPressed: _clear,
                ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: !_typed
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A hairline while the slower search is still out.
                        SizedBox(
                          height: 2,
                          child: searching
                              ? LinearProgressIndicator(
                                  minHeight: 2,
                                  color: theme.primaryColor,
                                  backgroundColor: Colors.transparent,
                                )
                              : null,
                        ),
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 62,
                              color: theme.borderLight,
                            ),
                          _SuggestionRow(
                            suggestion: rows[i],
                            typed: _controller.text,
                            theme: theme,
                            textTheme: textTheme,
                            onTap: () => _pick(rows[i]),
                          ),
                        ],
                        if (rows.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            child: Text(
                              searching
                                  ? 'Searching…'
                                  : _failed
                                  ? "Couldn't search just now. Check your connection."
                                  : 'No matches yet. Keep typing, or fill in the fields below.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        if (creditOsm)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 2, 12, 8),
                            child: Text(
                              '© OpenStreetMap contributors',
                              textAlign: TextAlign.right,
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.textSecondary,
                                fontSize: 10,
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

class _SuggestionRow extends StatelessWidget {
  final AddressSuggestion suggestion;
  final String typed;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.suggestion,
    required this.typed,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  IconData get _icon => switch (suggestion.kind) {
    SuggestionKind.property || SuggestionKind.address => Icons.home_outlined,
    SuggestionKind.street => Icons.signpost_outlined,
    SuggestionKind.area => Icons.location_city_outlined,
    SuggestionKind.estate => Icons.apartment_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final base = textTheme.bodyLarge?.copyWith(
      color: theme.textPrimary,
      fontWeight: FontWeight.w400,
      fontSize: 15,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 18, color: theme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: highlightTyped(
                        suggestion.title,
                        typed,
                        base,
                        base?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title with the parts the agent typed in bold: typing "10 bosm" shows
/// **10 Bosm**an Street. Each typed word bolds the start of a word it begins.
List<TextSpan> highlightTyped(
  String title,
  String typed,
  TextStyle? normal,
  TextStyle? bold,
) {
  final words = typed
      .toLowerCase()
      .split(RegExp(r'[\s,/]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final spans = <TextSpan>[];
  for (final m in RegExp(r'\S+|\s+').allMatches(title)) {
    final piece = m.group(0)!;
    final lower = piece.toLowerCase();
    var bolded = 0;
    for (final w in words) {
      if (lower.startsWith(w) && w.length > bolded) bolded = w.length;
    }
    if (bolded == 0) {
      spans.add(TextSpan(text: piece, style: normal));
    } else {
      spans.add(TextSpan(text: piece.substring(0, bolded), style: bold));
      if (bolded < piece.length) {
        spans.add(TextSpan(text: piece.substring(bolded), style: normal));
      }
    }
  }
  return spans;
}
