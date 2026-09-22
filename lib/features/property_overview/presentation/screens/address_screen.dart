import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/services/nominatim_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../data/models/nominatim_result.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_section_scaffold.dart';

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
        // Keep whatever is already typed when the lookup has no number —
        // detection should fill gaps, never clear work the agent did.
        streetNumber: result.houseNumber ?? current.streetNumber,
        street: result.road ?? current.street,
        unitNumber: current.unitNumber,
        suburb: result.suburb ?? result.neighbourhood ?? current.suburb,
        city: result.cityOrTown.isNotEmpty ? result.cityOrTown : current.city,
        province: result.state ?? current.province,
        country: result.country ?? current.country,
        postalCode: result.postcode ?? current.postalCode,
      );
      viewModel.updateCoordinates(
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (!mounted) return;

      final missingNumber = result.houseNumber == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingNumber
                ? 'Address detected. Add the street number — GPS could not '
                      'pinpoint it.'
                : 'Address detected and filled in below.',
          ),
          backgroundColor: missingNumber
              ? theme.pendingColor
              : theme.primaryColor,
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

  Future<String?> _save() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveAddress();
    final error = ref.read(propertyViewModelProvider).errorMessage;
    if (error != null) return friendlySaveMessage(error, 'address');
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
      validate: _validate,
      onSave: _save,
      child: Column(
        key: ValueKey('address_form_$_detectedAddress'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is the property?',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
            initialValue: state.unitNumber,
            onChanged: (val) => viewModel.updateAddress(unitNumber: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Street Name',
            initialValue: state.street,
            autofillHints: const [AutofillHints.streetAddressLevel1],
            errorText: _errors['street'],
            onChanged: (val) => viewModel.updateAddress(street: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Suburb / District',
            initialValue: state.suburb,
            onChanged: (val) => viewModel.updateAddress(suburb: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'City',
            initialValue: state.city,
            errorText: _errors['city'],
            onChanged: (val) => viewModel.updateAddress(city: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Province / State',
            initialValue: state.province,
            onChanged: (val) => viewModel.updateAddress(province: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Country',
            initialValue: state.country,
            autofillHints: const [AutofillHints.countryName],
            errorText: _errors['country'],
            onChanged: (val) => viewModel.updateAddress(country: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Postal Code',
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
            initialValue: state.estateName,
            onChanged: (val) => viewModel.updateIdentifiers(estateName: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Erf Number',
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
