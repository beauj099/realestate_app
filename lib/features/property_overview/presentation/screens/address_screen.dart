import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/services/nominatim_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../property_report/data/models/address_suggestion.dart';
import '../../../property_report/presentation/widgets/address_search_field.dart';
import '../../../property_report/providers/property_report_provider.dart';
import '../../../property_report/providers/city_records_autofill.dart';
import '../../../property_report/providers/report_preparer.dart';
import '../../data/models/nominatim_result.dart';
import '../../providers/property_provider.dart';
import '../widgets/property_pin_map.dart';
import '../widgets/wizard_section_scaffold.dart';
import '../../../../core/widgets/app_snack.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen>
    with WidgetsBindingObserver {
  final _errors = <String, String?>{};
  final _nominatimService = NominatimService();
  String _detectedAddress = '';
  bool _isFetchingLocation = false;
  bool _retryAfterResume = false;
  bool _placingPin = false;

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
    setState(() {});
    if (_errors.isEmpty) return null;
    return friendlySaveMessage(const ValidationFailure().message, 'address');
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
                'Location permission denied. Tap detect again to retry.',
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

  /// Puts the pin at [lat]/[lng] (the GPS fix, or where the agent tapped the
  /// map) and fills the address from it: the City's own record for the erf
  /// there (Cape Town, Johannesburg: house number, street, official suburb,
  /// erf), else OpenStreetMap's reverse lookup. The pin itself is kept as the
  /// location, never the road's position from a lookup.
  Future<void> _placeAt(double lat, double lng, {required bool fromGps}) async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.read(themeConfigProvider);
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
        _snack(
          'Pin placed on ${city.first.title}, ${city.first.suburb}. '
          'Not the right house? Tap it on the map.',
          theme.primaryColor,
        );
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
        _snack(
          'Pin placed. Could not find the address there; type it below.',
          theme.pendingColor,
        );
        return;
      }
      final current = ref.read(propertyViewModelProvider);
      setState(() => _detectedAddress = result!.displayName);
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
      final missingNumber = result.houseNumber == null;
      _snack(
        missingNumber
            ? (fromGps
                  ? 'Address detected. Add the street number — GPS could not pinpoint it.'
                  : 'Pin placed. Add the street number.')
            : 'Address filled in from the pin.',
        missingNumber ? theme.pendingColor : theme.primaryColor,
      );
    } finally {
      if (mounted) setState(() => _placingPin = false);
    }
  }

  /// "Stellenbosch Local Municipality" → "Stellenbosch".
  static String _plainTown(String name) => name
      .replaceAll(RegExp(r'\s+(Local|Metropolitan|District) Municipality$'), '')
      .replaceFirst(RegExp(r'^City of '), '');

  void _snack(String message, Color colour) {
    ScaffoldMessenger.of(
      context,
    ).showSnack(SnackBar(content: Text(message), backgroundColor: colour));
  }

  /// An address picked from the search. What it fills depends on what it is:
  /// a numbered erf from City records fills the address, erf and location;
  /// a numbered house from OpenStreetMap the address and location; a street
  /// the street (and the number typed, still to check); a suburb or town
  /// only those; a complex or estate its name. A unit typed in the search
  /// ("Unit 5, …") goes to Unit Number.
  void _pickAddress(AddressSuggestion s) {
    final theme = ref.read(themeConfigProvider);
    final (message, complete) = _fillFrom(s, keepPin: false);
    ScaffoldMessenger.of(context).showSnack(
      SnackBar(
        content: Text(message),
        backgroundColor: complete ? theme.primaryColor : theme.pendingColor,
      ),
    );
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
            'Address filled in. When you save, the erf size, floor area '
                'and zoning are filled in from City records.',
          SuggestionKind.address => 'Address filled in.',
          _ =>
            s.streetNumber == null
                ? 'Street filled in. Add the street number.'
                : 'Street filled in. Check the street number.',
        };
    }
    setState(() => _detectedAddress = s.label.isEmpty ? s.title : s.label);
    return (message, complete);
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
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    _errors.removeWhere((k, v) {
      if (k == 'street') return state.street.trim().isNotEmpty;
      if (k == 'city') return state.city.trim().isNotEmpty;
      if (k == 'country') return state.country.trim().isNotEmpty;
      return true;
    });

    return WizardSectionScaffold(
      title: 'Address',
      sectionName: 'address',
      busyMessages: const [
        "Looking the property up in the City's records…",
        'Finding the erf size and floor area…',
        'Checking the zoning…',
        'Almost there…',
      ],
      validate: _validate,
      onSave: _save,
      child: Column(
        key: ValueKey('address_form_$_detectedAddress'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressSearchField(
            theme: theme,
            textTheme: textTheme,
            onPick: _pickAddress,
            nearLat: state.latitude,
            nearLng: state.longitude,
          ),
          const SizedBox(height: 12),
          PropertyPinMap(
            theme: theme,
            lat: state.latitude,
            lng: state.longitude,
            busy: _placingPin,
            onPlacePin: (p) =>
                _placeAt(p.latitude, p.longitude, fromGps: false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _isFetchingLocation
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : CustomButton(
                    text: 'Detect my address',
                    icon: Icon(Icons.my_location, color: theme.onPrimary),
                    fullWidth: true,
                    theme: theme,
                    onTap: _detectAddress,
                  ),
          ),
          const SizedBox(height: 28),
          _label('Street Address', theme, textTheme),
          const SizedBox(height: 12),
          CustomTextInput(
            theme: theme,
            label: 'Street Number',
            initialValue: state.streetNumber,
            keyboardType: TextInputType.streetAddress,
            onChanged: (val) => viewModel.updateAddress(streetNumber: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Unit Number (Optional)',
            textCapitalization: TextCapitalization.characters,
            initialValue: state.unitNumber,
            onChanged: (val) => viewModel.updateAddress(unitNumber: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Street Name',
            textCapitalization: TextCapitalization.words,
            initialValue: state.street,
            autofillHints: const [AutofillHints.streetAddressLevel1],
            errorText: _errors['street'],
            onChanged: (val) => viewModel.updateAddress(street: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Suburb / District',
            textCapitalization: TextCapitalization.words,
            initialValue: state.suburb,
            onChanged: (val) => viewModel.updateAddress(suburb: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'City',
            textCapitalization: TextCapitalization.words,
            initialValue: state.city,
            errorText: _errors['city'],
            onChanged: (val) => viewModel.updateAddress(city: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Province / State',
            textCapitalization: TextCapitalization.words,
            initialValue: state.province,
            onChanged: (val) => viewModel.updateAddress(province: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Country',
            textCapitalization: TextCapitalization.words,
            initialValue: state.country,
            autofillHints: const [AutofillHints.countryName],
            errorText: _errors['country'],
            onChanged: (val) => viewModel.updateAddress(country: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Postal Code',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            initialValue: state.postalCode,
            autofillHints: const [AutofillHints.postalCode],
            onChanged: (val) => viewModel.updateAddress(postalCode: val),
          ),
          const SizedBox(height: 28),
          _label('Additional Identifiers', theme, textTheme),
          const SizedBox(height: 12),
          CustomTextInput(
            theme: theme,
            label: 'Estate Name (Optional)',
            textCapitalization: TextCapitalization.words,
            initialValue: state.estateName,
            onChanged: (val) => viewModel.updateIdentifiers(estateName: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Erf Number',
            textCapitalization: TextCapitalization.none,
            initialValue: state.erfNumber,
            subtext: 'Found on the municipal rates bill or title deed.',
            onChanged: (val) => viewModel.updateIdentifiers(erfNumber: val),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, theme, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.textPrimary,
      ),
    );
  }
}
