import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/services/nominatim_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../property_report/data/models/address_suggestion.dart';
import '../../../property_report/presentation/widgets/address_search_field.dart';
import '../../../property_report/providers/property_report_provider.dart';
import '../../../property_report/providers/city_records_autofill.dart';
import '../../../property_report/providers/report_preparer.dart';
import '../../data/models/nominatim_result.dart';
import '../../data/models/property_state.dart';
import '../../providers/property_provider.dart';
import '../widgets/property_pin_map.dart';
import '../widgets/wizard_section_scaffold.dart';
import '../../../../core/widgets/app_snack.dart';

/// The address: everything else (erf, sizes, zoning, the valuation report)
/// is found from it, so a new listing opens here first ([isNew]).
///
/// One search, "Use my current location" and the pin map find it; the result
/// shows as a short summary (street, area, the erf found) to confirm with one
/// tap. The separate fields stay behind "Edit", for when a search got it
/// wrong or found nothing.
class AddressScreen extends ConsumerStatefulWidget {
  /// Opened straight after "Add Property": the keyboard opens on the search.
  final bool isNew;

  const AddressScreen({super.key, this.isNew = false});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen>
    with WidgetsBindingObserver {
  final _errors = <String, String?>{};
  final _nominatimService = NominatimService();
  final _mapKey = GlobalKey();
  bool _isFetchingLocation = false;
  bool _retryAfterResume = false;
  bool _placingPin = false;

  /// The separate fields are showing.
  bool _editing = false;

  /// The erf came from the municipality's own record for this address.
  bool _erfMatched = false;

  /// What the last search or pin found, said in the summary rather than in a
  /// message that goes away; amber when something is still missing.
  String? _note;
  bool _noteIsWarning = false;

  /// Rebuilds the fields after the address is filled in for them (they keep
  /// their own text otherwise).
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _retryAfterResume) {
      _retryAfterResume = false;
      _detectAddress();
    }
  }

  String? _validate() {
    final state = ref.read(propertyViewModelProvider);
    _errors.clear();
    if (state.street.trim().isEmpty) {
      _errors['street'] = 'Street name is required';
    }
    if (state.city.trim().isEmpty) _errors['city'] = 'City is required';
    if (state.country.trim().isEmpty) {
      _errors['country'] = 'Country is required';
    }
    // Show the fields that need attention.
    setState(() => _editing = _editing || _errors.isNotEmpty);
    if (_errors.isEmpty) return null;
    return friendlySaveMessage(const ValidationFailure().message, 'address');
  }

  void _say(String note, {bool warning = false}) {
    setState(() {
      _note = note;
      _noteIsWarning = warning;
    });
  }

  Future<void> _detectAddress() async {
    final theme = ref.read(themeConfigProvider);
    setState(() => _isFetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _retryAfterResume = true;
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Location services are off'),
            content: const Text(
              'Turn on location services so we can detect the property address.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Turn On'),
              ),
            ],
          ),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnack(
            SnackBar(
              content: const Text(
                'Location permission denied. Tap "Use my current location" '
                'again to retry.',
              ),
              backgroundColor: theme.error,
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _retryAfterResume = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnack(
          SnackBar(
            content: const Text(
              'Location permission permanently denied. Enable it in app settings.',
            ),
            backgroundColor: theme.error,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _placeAt(position.latitude, position.longitude, fromGps: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnack(
        SnackBar(
          content: Text('Failed to detect address: $e'),
          backgroundColor: theme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// "Can't find it? Set the pin on the map": bring the map into view.
  void _showMap() {
    final map = _mapKey.currentContext;
    if (map != null) {
      Scrollable.ensureVisible(
        map,
        duration: const Duration(milliseconds: 250),
        alignment: 0.1,
      );
    }
    _say(
      'Tap the house on the map; the address there is filled in. Then '
      'check it with Edit.',
    );
  }

  /// Puts the pin at [lat]/[lng] (the GPS fix, or where the agent tapped the
  /// map) and fills the address from it: the City's own record for the erf
  /// there (Cape Town, Johannesburg: house number, street, official suburb,
  /// erf), else OpenStreetMap's reverse lookup. The pin itself is kept as the
  /// location, never the road's position from a lookup.
  Future<void> _placeAt(double lat, double lng, {required bool fromGps}) async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    viewModel.updateCoordinates(latitude: lat, longitude: lng);
    setState(() => _placingPin = true);
    try {
      List<AddressSuggestion> city = const [];
      try {
        city = await ref
            .read(propertyReportRepositoryProvider)
            .addressAt(lat, lng);
      } catch (_) {
        // Not reachable: fall back to OpenStreetMap below.
      }
      if (!mounted) return;
      if (city.isNotEmpty) {
        _fillFrom(city.first, keepPin: true);
        _say('Not the right house? Tap it on the map.');
        return;
      }

      NominatimResult? result;
      try {
        result = await _nominatimService.reverseGeocode(
          latitude: lat,
          longitude: lng,
        );
      } catch (_) {
        result = null;
      }
      if (!mounted) return;
      if (result == null) {
        _say(
          'Pin placed, but there is no address on record there. Type it in '
          'below.',
          warning: true,
        );
        setState(() => _editing = true);
        return;
      }
      final current = ref.read(propertyViewModelProvider);
      viewModel.updateAddress(
        // Keep whatever is already typed when the lookup has no number —
        // detection should fill gaps, never clear work the agent did.
        streetNumber: result.houseNumber ?? current.streetNumber,
        street: result.road ?? current.street,
        unitNumber: current.unitNumber,
        suburb: result.suburb ?? result.neighbourhood ?? current.suburb,
        city: result.cityOrTown.isNotEmpty
            ? _plainTown(result.cityOrTown)
            : current.city,
        province: result.state ?? current.province,
        country: result.country ?? current.country,
        postalCode: result.postcode ?? current.postalCode,
      );
      setState(() {
        _erfMatched = false;
        _formVersion++;
      });
      final missingNumber = result.houseNumber == null;
      _say(
        missingNumber
            ? (fromGps
                  ? 'GPS could not pinpoint the street number. Add it.'
                  : 'Add the street number.')
            : 'Not the right house? Tap it on the map.',
        warning: missingNumber,
      );
    } finally {
      if (mounted) setState(() => _placingPin = false);
    }
  }

  /// "Stellenbosch Local Municipality" → "Stellenbosch".
  static String _plainTown(String name) => name
      .replaceAll(RegExp(r'\s+(Local|Metropolitan|District) Municipality$'), '')
      .replaceFirst(RegExp(r'^City of '), '');

  /// An address picked from the search. What it fills depends on what it is:
  /// a numbered erf from City records fills the address, erf and location;
  /// a numbered house from OpenStreetMap the address and location; a street
  /// the street (and the number typed, still to check); a suburb or town
  /// only those; a complex or estate its name. A unit typed in the search
  /// ("Unit 5, …") goes to Unit Number.
  void _pickAddress(AddressSuggestion s) {
    final (message, complete) = _fillFrom(s, keepPin: false);
    _say(message, warning: !complete);
  }

  /// Fills the address fields from a suggestion; returns what to tell the
  /// agent and whether the address is complete. With [keepPin] the location
  /// stays where the pin is.
  (String, bool) _fillFrom(AddressSuggestion s, {required bool keepPin}) {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final current = ref.read(propertyViewModelProvider);
    String keep(String value, String fallback) =>
        value.isNotEmpty ? value : fallback;

    final String message;
    var complete = false;
    switch (s.kind) {
      case SuggestionKind.area:
      case SuggestionKind.estate:
        viewModel.updateAddress(
          suburb: keep(s.suburb, current.suburb),
          city: keep(s.city, current.city),
          province: keep(s.province, current.province),
          country: keep(s.country, current.country),
          postalCode: s.postalCode ?? current.postalCode,
        );
        if (s.kind == SuggestionKind.estate) {
          viewModel.updateIdentifiers(estateName: s.title);
          message = 'Complex filled in. Now search the street address.';
        } else {
          message = 'Area filled in. Now search the street address.';
        }
      case SuggestionKind.property:
      case SuggestionKind.address:
      case SuggestionKind.street:
        viewModel.updateAddress(
          streetNumber: s.streetNumber ?? current.streetNumber,
          street: s.streetName,
          unitNumber: s.unit ?? current.unitNumber,
          suburb: keep(s.suburb, current.suburb),
          city: keep(s.city, current.city),
          province: keep(s.province, current.province),
          country: keep(s.country, current.country),
          postalCode: s.postalCode ?? current.postalCode,
        );
        if (s.erf != null) viewModel.updateIdentifiers(erfNumber: s.erf);
        _erfMatched = s.erf != null && s.kind == SuggestionKind.property;
        // Only a numbered address has a location of its own; a point on the
        // street is not the property.
        if (!keepPin &&
            s.kind != SuggestionKind.street &&
            s.lat != null &&
            s.lng != null) {
          viewModel.updateCoordinates(latitude: s.lat, longitude: s.lng);
        }
        complete = s.kind != SuggestionKind.street;
        message = switch (s.kind) {
          SuggestionKind.property =>
            'Found in the City records. The erf size, floor area and zoning '
                'are filled in when you confirm.',
          SuggestionKind.address => 'Not the right house? Tap it on the map.',
          _ =>
            s.streetNumber == null
                ? 'Add the street number.'
                : 'Check the street number.',
        };
    }
    setState(() => _formVersion++);
    return (message, complete);
  }

  /// One field in a small dialog: the "+ Unit or flat no." style chips.
  Future<void> _askFor({
    required String title,
    required String label,
    required String initial,
    required ValueChanged<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization? capitalization,
  }) async {
    final theme = ref.read(themeConfigProvider);
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(title),
        content: CustomTextInput(
          theme: theme,
          label: label,
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    onSaved(value);
    setState(() => _formVersion++);
  }

  Future<String?> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveAddress();
    final error = ref.read(propertyViewModelProvider).errorMessage;
    if (error != null) return friendlySaveMessage(error, 'address');
    // Fill what is still empty (erf size, floor area, zoning…) from the
    // municipality's records before going on, so the agent never types over
    // details that are still on their way. Bounded; a slow City is said, not
    // waited for.
    final theme = ref.read(themeConfigProvider);
    final slow = await ref
        .read(cityRecordsAutofillProvider.notifier)
        .fillMissing();
    // The full valuation report (with the area's sales) is made in the
    // background and kept on the phone, ready when the agent opens it.
    ref
        .read(reportPreparerProvider)
        .prepare(ref.read(propertyViewModelProvider));
    if (slow != null) {
      messenger.showSnack(
        SnackBar(content: Text(slow), backgroundColor: theme.textSecondary),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyViewModelProvider);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    _errors.removeWhere((k, v) {
      if (k == 'street') return state.street.trim().isNotEmpty;
      if (k == 'city') return state.city.trim().isNotEmpty;
      if (k == 'country') return state.country.trim().isNotEmpty;
      return true;
    });

    final hasAddress =
        state.street.trim().isNotEmpty ||
        state.suburb.trim().isNotEmpty ||
        state.city.trim().isNotEmpty;

    return WizardSectionScaffold(
      title: widget.isNew ? 'New property' : 'Address',
      sectionName: 'address',
      saveLabel: 'Confirm address',
      busyMessages: const [
        "Looking the property up in the City's records…",
        'Finding the erf size and floor area…',
        'Checking the zoning…',
        'Almost there…',
      ],
      validate: _validate,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isNew) ...[
            Text(
              'Where is the property?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everything else (erf, sizes, zoning, nearby sales) is found '
              'from the address.',
              style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
            const SizedBox(height: 16),
          ],
          AddressSearchField(
            theme: theme,
            textTheme: textTheme,
            onPick: _pickAddress,
            nearLat: state.latitude,
            nearLng: state.longitude,
            autofocus: widget.isNew && !hasAddress,
            onUseMyLocation: _detectAddress,
            onSetPinOnMap: _showMap,
          ),
          const SizedBox(height: 12),
          PropertyPinMap(
            key: _mapKey,
            theme: theme,
            lat: state.latitude,
            lng: state.longitude,
            busy: _placingPin || _isFetchingLocation,
            onPlacePin: (p) =>
                _placeAt(p.latitude, p.longitude, fromGps: false),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isFetchingLocation || _placingPin
                  ? null
                  : _detectAddress,
              icon: Icon(
                Icons.my_location,
                size: 18,
                color: theme.primaryColor,
              ),
              label: Text(
                'Use my current location',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (hasAddress)
            _AddressSummary(
              state: state,
              theme: theme,
              textTheme: textTheme,
              erfMatched: _erfMatched,
              note: _note,
              noteIsWarning: _noteIsWarning,
              editing: _editing,
              onEdit: () => setState(() => _editing = !_editing),
              onAddStreetNumber: () => _askFor(
                title: 'Street number',
                label: 'Street number',
                initial: state.streetNumber,
                keyboardType: TextInputType.streetAddress,
                capitalization: TextCapitalization.characters,
                onSaved: (v) => ref
                    .read(propertyViewModelProvider.notifier)
                    .updateAddress(streetNumber: v),
              ),
              onUnit: () => _askFor(
                title: 'Unit or flat number',
                label: 'Unit or flat no.',
                initial: state.unitNumber,
                capitalization: TextCapitalization.characters,
                onSaved: (v) => ref
                    .read(propertyViewModelProvider.notifier)
                    .updateAddress(unitNumber: v),
              ),
              onComplex: () => _askFor(
                title: 'Complex or estate',
                label: 'Complex or estate name',
                initial: state.estateName,
                capitalization: TextCapitalization.words,
                onSaved: (v) => ref
                    .read(propertyViewModelProvider.notifier)
                    .updateIdentifiers(estateName: v),
              ),
            )
          else if (!_editing)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _editing = true),
                child: Text(
                  'Or type the address in yourself',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ),
            ),
          if (_editing) ...[
            const SizedBox(height: 16),
            _AddressFields(
              key: ValueKey('address_fields_$_formVersion'),
              state: state,
              theme: theme,
              textTheme: textTheme,
              errors: _errors,
            ),
          ],
        ],
      ),
    );
  }
}

/// The address as two lines (street; complex, suburb, town, postal code),
/// what was matched, and chips for what is optional or missing.
class _AddressSummary extends StatelessWidget {
  final PropertyState state;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final bool erfMatched;
  final String? note;
  final bool noteIsWarning;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onAddStreetNumber;
  final VoidCallback onUnit;
  final VoidCallback onComplex;

  const _AddressSummary({
    required this.state,
    required this.theme,
    required this.textTheme,
    required this.erfMatched,
    required this.note,
    required this.noteIsWarning,
    required this.editing,
    required this.onEdit,
    required this.onAddStreetNumber,
    required this.onUnit,
    required this.onComplex,
  });

  @override
  Widget build(BuildContext context) {
    final street = '${state.streetNumber} ${state.street}'.trim();
    final unit = state.unitNumber.trim();
    final line1 = street.isEmpty
        ? 'Street not set yet'
        : unit.isEmpty
        ? street
        : 'Unit $unit, $street';
    final line2 = [
      state.estateName,
      state.suburb,
      state.city,
      state.postalCode,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
    final erf = state.erfNumber.trim();
    final missingNumber =
        state.street.trim().isNotEmpty && state.streetNumber.trim().isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line1,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: street.isEmpty
                            ? theme.textSecondary
                            : theme.textPrimary,
                      ),
                    ),
                    if (line2.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        line2,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  editing ? 'Hide' : 'Edit',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (erf.isNotEmpty)
                  _Badge(
                    text: erfMatched ? 'Erf $erf matched' : 'Erf $erf',
                    color: theme.completeColor,
                    icon: Icons.check,
                  ),
                if (missingNumber)
                  _ChipButton(
                    text: 'Street number',
                    theme: theme,
                    warning: true,
                    onTap: onAddStreetNumber,
                  ),
                _ChipButton(
                  text: state.unitNumber.trim().isEmpty
                      ? 'Unit or flat no.'
                      : 'Unit ${state.unitNumber.trim()}',
                  theme: theme,
                  filled: state.unitNumber.trim().isNotEmpty,
                  onTap: onUnit,
                ),
                _ChipButton(
                  text: state.estateName.trim().isEmpty
                      ? 'Complex name'
                      : state.estateName.trim(),
                  theme: theme,
                  filled: state.estateName.trim().isNotEmpty,
                  onTap: onComplex,
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    noteIsWarning ? Icons.info_outline : Icons.check_circle,
                    size: 16,
                    color: noteIsWarning
                        ? theme.pendingColor
                        : theme.completeColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note!,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Badge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "+ Unit or flat no.": an optional detail, added with a tap rather than an
/// empty box. Once set it shows the value, still tappable to change it.
class _ChipButton extends StatelessWidget {
  final String text;
  final RealEstateTheme theme;
  final bool filled;
  final bool warning;
  final VoidCallback onTap;

  const _ChipButton({
    required this.text,
    required this.theme,
    required this.onTap,
    this.filled = false,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colour = warning ? theme.pendingColor : theme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: warning ? theme.pendingColor : theme.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filled ? Icons.edit_outlined : Icons.add,
                size: 15,
                color: colour,
              ),
              const SizedBox(width: 4),
              Text(text, style: TextStyle(fontSize: 13, color: colour)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every field, grouped as an address is written.
class _AddressFields extends ConsumerWidget {
  final PropertyState state;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final Map<String, String?> errors;

  const _AddressFields({
    super.key,
    required this.state,
    required this.theme,
    required this.textTheme,
    required this.errors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    const gap = SizedBox(height: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: CustomTextInput(
                theme: theme,
                label: 'Street no.',
                initialValue: state.streetNumber,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.characters,
                onChanged: (val) => viewModel.updateAddress(streetNumber: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: CustomTextInput(
                theme: theme,
                label: 'Unit (optional)',
                textCapitalization: TextCapitalization.characters,
                initialValue: state.unitNumber,
                onChanged: (val) => viewModel.updateAddress(unitNumber: val),
              ),
            ),
          ],
        ),
        gap,
        CustomTextInput(
          theme: theme,
          label: 'Street name',
          textCapitalization: TextCapitalization.words,
          initialValue: state.street,
          autofillHints: const [AutofillHints.streetAddressLevel1],
          errorText: errors['street'],
          onChanged: (val) => viewModel.updateAddress(street: val),
        ),
        gap,
        CustomTextInput(
          theme: theme,
          label: 'Complex or estate (optional)',
          textCapitalization: TextCapitalization.words,
          initialValue: state.estateName,
          onChanged: (val) => viewModel.updateIdentifiers(estateName: val),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CustomTextInput(
                theme: theme,
                label: 'Suburb',
                textCapitalization: TextCapitalization.words,
                initialValue: state.suburb,
                onChanged: (val) => viewModel.updateAddress(suburb: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomTextInput(
                theme: theme,
                label: 'Postal code',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                initialValue: state.postalCode,
                autofillHints: const [AutofillHints.postalCode],
                onChanged: (val) => viewModel.updateAddress(postalCode: val),
              ),
            ),
          ],
        ),
        gap,
        CustomTextInput(
          theme: theme,
          label: 'City or town',
          textCapitalization: TextCapitalization.words,
          initialValue: state.city,
          errorText: errors['city'],
          onChanged: (val) => viewModel.updateAddress(city: val),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextInput(
                theme: theme,
                label: 'Province',
                textCapitalization: TextCapitalization.words,
                initialValue: state.province,
                onChanged: (val) => viewModel.updateAddress(province: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextInput(
                theme: theme,
                label: 'Country',
                textCapitalization: TextCapitalization.words,
                initialValue: state.country,
                autofillHints: const [AutofillHints.countryName],
                errorText: errors['country'],
                onChanged: (val) => viewModel.updateAddress(country: val),
              ),
            ),
          ],
        ),
        gap,
        CustomTextInput(
          theme: theme,
          label: 'Erf number',
          textCapitalization: TextCapitalization.none,
          initialValue: state.erfNumber,
          subtext: 'Found on the municipal rates bill or title deed.',
          onChanged: (val) => viewModel.updateIdentifiers(erfNumber: val),
        ),
      ],
    );
  }
}
