import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/services/nominatim_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../data/models/nominatim_result.dart';
import '../../providers/property_provider.dart';

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

  bool _validate(String street, String city, String country) {
    _errors.clear();
    if (street.trim().isEmpty) _errors['street'] = 'Street name is required';
    if (city.trim().isEmpty) _errors['city'] = 'City is required';
    if (country.trim().isEmpty) _errors['country'] = 'Country is required';
    setState(() {});
    return _errors.isEmpty;
  }

  String? _validateLatitude(String value) {
    if (value.trim().isEmpty) return null;
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid number';
    if (v < -90 || v > 90) return 'Latitude must be between -90 and 90';
    return null;
  }

  String? _validateLongitude(String value) {
    if (value.trim().isEmpty) return null;
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid number';
    if (v < -180 || v > 180) return 'Longitude must be between -180 and 180';
    return null;
  }

  Future<void> _detectAddress() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final current = ref.read(propertyViewModelProvider);
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
          ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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

      NominatimResult? result;
      try {
        result = await _nominatimService.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        result = null;
      }

      // clear previous errors
      setState(() {
        _errors.remove('latitude');
        _errors.remove('longitude');
      });

      if (result == null) {
        viewModel.updateCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not determine the address from your location.',
            ),
            backgroundColor: theme.error,
          ),
        );
        return;
      }

      setState(() => _detectedAddress = result!.displayName);
      viewModel.updateAddress(
        streetNumber: result.houseNumber ?? '',
        street: result.road ?? '',
        unitNumber: current.unitNumber,
        suburb: result.suburb ?? result.neighbourhood ?? '',
        city: result.cityOrTown,
        province: result.state ?? '',
        country: result.country ?? '',
        postalCode: result.postcode ?? '',
      );
      viewModel.updateCoordinates(
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address detected and filled in below.'),
          backgroundColor: theme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to detect address: $e'),
          backgroundColor: theme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _saveAndPop() async {
    final state = ref.read(propertyViewModelProvider);
    final hasAnyAddress =
        state.street.trim().isNotEmpty ||
        state.city.trim().isNotEmpty ||
        state.country.trim().isNotEmpty;
    if (!hasAnyAddress) {
      if (mounted) context.pop();
      return;
    }
    if (!_validate(state.street, state.city, state.country)) {
      if (mounted) {
        final theme = ref.read(themeConfigProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlySaveMessage(const ValidationFailure().message, 'address'),
            ),
            backgroundColor: theme.error,
          ),
        );
        context.pop();
      }
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveAddress();
    if (!mounted) return;
    Navigator.pop(context);
    final error = ref.read(propertyViewModelProvider).errorMessage;
    if (error != null && mounted) {
      final theme = ref.read(themeConfigProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySaveMessage(error, 'address')),
          backgroundColor: theme.error,
        ),
      );
    }
    if (mounted) context.pop();
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
      if (k == 'latitude') {
        final err = _validateLatitude(state.latitude?.toString() ?? '');
        return err == null;
      }
      if (k == 'longitude') {
        final err = _validateLongitude(state.longitude?.toString() ?? '');
        return err == null;
      }
      return true;
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Address',
          onBack: () => Navigator.maybePop(context),
          theme: theme,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where is the property?',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the property address details.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Detect property address',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use your current GPS location to fill in the address automatically.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _isFetchingLocation
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : CustomButton(
                            text: 'Detect my address',
                            icon: Icon(
                              Icons.my_location,
                              color: theme.onPrimary,
                            ),
                            fullWidth: true,
                            theme: theme,
                            onTap: _detectAddress,
                          ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Street Address',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    key: ValueKey('street_form_$_detectedAddress'),
                    theme: theme,
                    backgroundColor: theme.borderLight.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'Street Number',
                                placeholder: '',
                                initialValue: state.streetNumber,
                                onChanged: (val) =>
                                    viewModel.updateAddress(streetNumber: val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'Unit Number (Optional)',
                                placeholder: '',
                                initialValue: state.unitNumber,
                                onChanged: (val) =>
                                    viewModel.updateAddress(unitNumber: val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CustomTextInput(
                          theme: theme,
                          label: 'Street Name',
                          placeholder: '',
                          initialValue: state.street,
                          autofillHints: const [
                            AutofillHints.streetAddressLevel1,
                          ],
                          errorText: _errors['street'],
                          onChanged: (val) =>
                              viewModel.updateAddress(street: val),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'Suburb / District',
                                placeholder: '',
                                initialValue: state.suburb,
                                onChanged: (val) =>
                                    viewModel.updateAddress(suburb: val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'City',
                                placeholder: '',
                                initialValue: state.city,
                                errorText: _errors['city'],
                                onChanged: (val) =>
                                    viewModel.updateAddress(city: val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'Province / State',
                                placeholder: '',
                                initialValue: state.province,
                                onChanged: (val) =>
                                    viewModel.updateAddress(province: val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextInput(
                                theme: theme,
                                label: 'Country',
                                placeholder: '',
                                initialValue: state.country,
                                autofillHints: const [
                                  AutofillHints.countryName,
                                ],
                                errorText: _errors['country'],
                                onChanged: (val) =>
                                    viewModel.updateAddress(country: val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CustomTextInput(
                          theme: theme,
                          label: 'Postal Code',
                          placeholder: '',
                          initialValue: state.postalCode,
                          autofillHints: const [AutofillHints.postalCode],
                          onChanged: (val) =>
                              viewModel.updateAddress(postalCode: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Additional Identifiers',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    theme: theme,
                    backgroundColor: theme.borderLight.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextInput(
                          theme: theme,
                          label: 'Estate Name (Optional)',
                          placeholder: '',
                          initialValue: state.estateName,
                          onChanged: (val) =>
                              viewModel.updateIdentifiers(estateName: val),
                        ),
                        const SizedBox(height: 16),
                        CustomTextInput(
                          theme: theme,
                          label: 'Erf Number',
                          placeholder: '',
                          initialValue: state.erfNumber,
                          subtext:
                              'Found on municipal rates bill or property deed.',
                          onChanged: (val) =>
                              viewModel.updateIdentifiers(erfNumber: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'GPS Coordinates',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional — capture the property location so the correct house can be viewed.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    theme: theme,
                    backgroundColor: theme.borderLight.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                key: ValueKey('lat_${state.latitude}'),
                                theme: theme,
                                label: 'Latitude',
                                placeholder: 'e.g. -33.9249',
                                initialValue: state.latitude?.toString() ?? '',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: true,
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^-?\d*\.?\d*'),
                                  ),
                                ],
                                errorText: _errors['latitude'],
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    _errors.remove('latitude');
                                    viewModel.updateCoordinates(
                                      latitude: null,
                                      longitude: state.longitude,
                                    );
                                    setState(() {});
                                    return;
                                  }
                                  final err = _validateLatitude(val);
                                  setState(() {
                                    if (err != null) {
                                      _errors['latitude'] = err;
                                    } else {
                                      _errors.remove('latitude');
                                    }
                                  });
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed != null && err == null) {
                                    viewModel.updateCoordinates(
                                      latitude: parsed,
                                      longitude: state.longitude,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextInput(
                                key: ValueKey('lng_${state.longitude}'),
                                theme: theme,
                                label: 'Longitude',
                                placeholder: 'e.g. 18.4241',
                                initialValue: state.longitude?.toString() ?? '',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: true,
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^-?\d*\.?\d*'),
                                  ),
                                ],
                                errorText: _errors['longitude'],
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    _errors.remove('longitude');
                                    viewModel.updateCoordinates(
                                      latitude: state.latitude,
                                      longitude: null,
                                    );
                                    setState(() {});
                                    return;
                                  }
                                  final err = _validateLongitude(val);
                                  setState(() {
                                    if (err != null) {
                                      _errors['longitude'] = err;
                                    } else {
                                      _errors.remove('longitude');
                                    }
                                  });
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed != null && err == null) {
                                    viewModel.updateCoordinates(
                                      latitude: state.latitude,
                                      longitude: parsed,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (state.latitude != null &&
                            state.longitude != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lat ${state.latitude!.toStringAsFixed(6)}, Lng ${state.longitude!.toStringAsFixed(6)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Range: latitude -90 to 90, longitude -180 to 180. Leave empty if unknown.',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.textSecondary.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
