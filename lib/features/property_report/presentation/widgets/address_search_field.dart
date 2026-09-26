import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/services/nominatim_service.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../property_overview/data/models/nominatim_result.dart';
import '../../data/models/address_suggestion.dart';
import '../../providers/property_report_provider.dart';

/// Type an address, pick it from a list.
///
/// Suggestions come from the City of Cape Town's and Johannesburg's parcel records as the agent
/// types (a short pause first), so each numbered one is a real erf with its
/// location. Elsewhere in South Africa, one tap searches OpenStreetMap — once,
/// not per keystroke, which its usage policy forbids.
class AddressSearchField extends ConsumerStatefulWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<AddressSuggestion> onPickCity;
  final ValueChanged<NominatimResult> onPickElsewhere;

  const AddressSearchField({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.onPickCity,
    required this.onPickElsewhere,
  });

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  static const _pause = Duration(milliseconds: 350);

  final _controller = TextEditingController();
  final _nominatim = NominatimService();
  Timer? _debounce;

  /// Only the newest request's answer is shown.
  int _generation = 0;
  bool _loading = false;
  List<AddressSuggestion> _city = const [];
  List<NominatimResult>? _elsewhere;
  bool _searchedCity = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _elsewhere = null;
      _error = null;
      if (text.trim().length < 3) {
        _city = const [];
        _searchedCity = false;
        _loading = false;
      }
    });
    if (text.trim().length < 3) return;
    _debounce = Timer(_pause, () => _suggest(text));
  }

  Future<void> _suggest(String text) async {
    final generation = ++_generation;
    setState(() => _loading = true);
    try {
      final found = await ref
          .read(propertyReportRepositoryProvider)
          .suggest(text);
      if (!mounted || generation != _generation) return;
      setState(() {
        _city = found;
        _searchedCity = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _city = const [];
        _searchedCity = true;
        _loading = false;
      });
    }
  }

  Future<void> _searchElsewhere() async {
    final generation = ++_generation;
    setState(() => _loading = true);
    try {
      final found = await _nominatim.search(_controller.text.trim());
      if (!mounted || generation != _generation) return;
      setState(() {
        _elsewhere = found;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _elsewhere = const [];
        _error = "Couldn't search just now. Check your connection.";
        _loading = false;
      });
    }
  }

  void _clear() {
    _debounce?.cancel();
    _generation++;
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _city = const [];
      _elsewhere = null;
      _searchedCity = false;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = widget.textTheme;
    final typed = _controller.text.trim().length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextInput(
          theme: theme,
          label: 'Search address',
          placeholder: 'e.g. 17 Pine Road, Claremont',
          controller: _controller,
          onChanged: _onChanged,
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.words,
          autocorrect: false,
          prefixIcon: Icon(Icons.search, color: theme.textSecondary),
          suffixIcon: _loading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                )
              : _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  onPressed: _clear,
                ),
        ),
        if (typed && (_searchedCity || _elsewhere != null)) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderLight),
            ),
            child: Column(
              children: [
                if (_elsewhere == null) ...[
                  for (final s in _city)
                    _row(
                      icon: s.isProperty
                          ? Icons.home_outlined
                          : Icons.signpost_outlined,
                      title: s.label,
                      subtitle: s.isProperty
                          ? 'Erf ${s.erf} · ${s.city}'
                          : 'Street only · add the number',
                      onTap: () {
                        widget.onPickCity(s);
                        _clear();
                      },
                    ),
                  _row(
                    icon: Icons.travel_explore,
                    title: _city.isEmpty
                        ? 'Not found in Cape Town or Johannesburg. Search all of South Africa'
                        : 'Not listed? Search all of South Africa',
                    subtitle: null,
                    emphasise: true,
                    onTap: _searchElsewhere,
                  ),
                ] else ...[
                  for (final r in _elsewhere!)
                    _row(
                      icon: Icons.place_outlined,
                      title: r.displayName,
                      subtitle: 'OpenStreetMap',
                      onTap: () {
                        widget.onPickElsewhere(r);
                        _clear();
                      },
                    ),
                  if (_elsewhere!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _error ??
                            'No matches. Check the spelling, or fill in the fields below.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              _elsewhere == null
                  ? 'Cape Town and Johannesburg addresses from City records'
                  : 'Search results © OpenStreetMap contributors',
              style: textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
    bool emphasise = false,
  }) {
    final theme = widget.theme;
    final textTheme = widget.textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: emphasise ? theme.primaryColor : theme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: emphasise ? theme.primaryColor : theme.textPrimary,
                      fontWeight: emphasise ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
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
