import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/theme/agency.dart';
import '../../../../core/theme/agency_directory.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/validation/phone_format.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/scoped_brand_theme.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/data/models/agent_profile.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/agency_picker.dart';
import '../widgets/profile_media.dart';
import '../widgets/signature_pad.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/circle_crop.dart';

/// Lets an agent review and change everything they entered at registration.
///
/// Picking an agency previews its colours on this screen straight away, but
/// the rest of the app only re-brands once the change is saved.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _agencyRegNoController;
  late final TextEditingController _licenceController;

  // What the report pack prints about the agent.
  final _jobTitleController = TextEditingController();
  final _ppraController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  final _qualificationsController = TextEditingController();

  // The agent's own office; empty fields use the agency's defaults.
  final _officeNameController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _officeEmailController = TextEditingController();
  final _officeWebsiteController = TextEditingController();
  final _officeSloganController = TextEditingController();
  final _officeHeadlineController = TextEditingController();
  final _officeFooterController = TextEditingController();

  /// Which upload is running: 'photo', 'signature' or 'brochure'.
  String? _uploading;

  late Agency _agency;
  bool _isSaving = false;
  bool _isDirty = false;

  /// What the form held when it was last filled from the profile. Backing out
  /// only asks to discard when the form differs from this — editing a field
  /// and putting it back, or re-picking the same agency, is not a change.
  String _baseline = '';

  String get _formContent => [
    for (final c in _fields.values) c.text.trim(),
    _agency.slug,
  ].join('\u0000');

  bool get _hasChanges => _formContent != _baseline;

  /// Inline errors keyed by field, cleared as soon as that field is edited.
  final _errors = <String, String>{};

  late final Map<String, TextEditingController> _fields;

  /// Set while fields are filled from the provider, so that is not mistaken
  /// for an edit.
  bool _populating = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _agencyRegNoController = TextEditingController();
    _licenceController = TextEditingController();

    _fields = {
      'firstName': _firstNameController,
      'lastName': _lastNameController,
      'email': _emailController,
      'mobile': _mobileController,
      'agencyRegistrationNumber': _agencyRegNoController,
      'licenceNumber': _licenceController,
      'jobTitle': _jobTitleController,
      'ppraNumber': _ppraController,
      'website': _websiteController,
      'bio': _bioController,
      'qualifications': _qualificationsController,
      'officeName': _officeNameController,
      'officeAddress': _officeAddressController,
      'officePhone': _officePhoneController,
      'officeEmail': _officeEmailController,
      'officeWebsite': _officeWebsiteController,
      'officeSlogan': _officeSloganController,
      'officeHeadline': _officeHeadlineController,
      'officeFooter': _officeFooterController,
    };
    _populate(ref.read(agentProfileProvider));
    _fields.forEach((key, controller) {
      var lastText = controller.text;
      controller.addListener(() {
        // Controllers also notify on cursor moves; only edits count.
        if (controller.text == lastText) return;
        lastText = controller.text;
        if (_populating) return;
        setState(() {
          _isDirty = true;
          _errors.remove(key);
          if (key == 'firstName' || key == 'lastName') {
            _errors.remove('displayName');
          }
        });
      });
    });

    // The cached profile shows at once; the server copy replaces it when it
    // arrives, unless the agent has already started editing.
    ref.listenManual(agentProfileProvider, (previous, next) {
      if (!_isDirty && mounted) setState(() => _populate(next));
    });
    ref.read(agentProfileProvider.notifier).refresh();
  }

  void _populate(AgentProfile profile) {
    var (first, last) = (profile.firstName, profile.lastName);
    if (first.isEmpty && last.isEmpty) {
      (first, last) = AgentProfile.splitName(
        ref.read(authProvider).displayName ?? '',
      );
    }
    _populating = true;
    _firstNameController.text = first;
    _lastNameController.text = last;
    _emailController.text = profile.email;
    _mobileController.text = CountryPhone.format(
      profile.mobile,
      ref.read(regionProvider).country,
    );
    _agencyRegNoController.text = profile.agencyRegistrationNumber;
    _licenceController.text = profile.licenceNumber;
    _jobTitleController.text = profile.jobTitle;
    _ppraController.text = profile.ppraNumber;
    _websiteController.text = profile.website;
    _bioController.text = profile.bio;
    _qualificationsController.text = profile.qualifications.join('\n');
    _agency = ref.read(agencyProvider);
    // The office as the reports print it: the agent's own value, else the
    // agency's, so the defaults are visible and can simply be changed.
    final office = profile.office.orDefaults(_agencyOffice(_agency));
    _officeNameController.text = office.name;
    _officeAddressController.text = office.address;
    _officePhoneController.text = office.phone;
    _officeEmailController.text = office.email;
    _officeWebsiteController.text = office.website;
    _officeSloganController.text = office.slogan;
    _officeHeadlineController.text = office.headline;
    _officeFooterController.text = office.footer;
    _populating = false;
    _baseline = _formContent;
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    final errors = <String, String>{
      if (_firstNameController.text.trim().isEmpty)
        'firstName': 'First name is required',
      if (email.isEmpty)
        'email': 'Email address is required'
      else if (!emailRegex.hasMatch(email))
        'email': 'Enter a valid email address',
      if (mobile.isEmpty)
        'mobile': 'Mobile number is required'
      else
        'mobile': ?CountryPhone.validate(
          mobile,
          ref.read(regionProvider).country,
        ),
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _pickAgency(RealEstateTheme theme) async {
    final agency = await showAgencyPicker(
      context: context,
      ref: ref,
      theme: theme,
      selected: _agency,
      title: 'Agency',
    );
    if (agency == null || !mounted) return;
    setState(() {
      _isDirty = _isDirty || agency != _agency;
      // Office fields still on the old agency's defaults take the new one's;
      // anything the agent typed stays.
      final before = _agencyOffice(_agency), after = _agencyOffice(agency);
      for (final (controller, was, now) in _officeFields(before, after)) {
        if (controller.text.trim().isEmpty || controller.text.trim() == was) {
          controller.text = now;
        }
      }
      _agency = agency;
    });
  }

  /// The agency's office defaults, with the house heading when it has none.
  static OfficeDetails _agencyOffice(Agency agency) => agency.office.copyWith(
    headline: agency.office.headline.isNotEmpty
        ? agency.office.headline
        : OfficeDetails.defaultHeadline,
  );

  /// Each office field's controller with its value in [a] and in [b].
  List<(TextEditingController, String, String)> _officeFields(
    OfficeDetails a,
    OfficeDetails b,
  ) => [
    (_officeNameController, a.name, b.name),
    (_officeAddressController, a.address, b.address),
    (_officePhoneController, a.phone, b.phone),
    (_officeEmailController, a.email, b.email),
    (_officeWebsiteController, a.website, b.website),
    (_officeFooterController, a.footer, b.footer),
    (_officeSloganController, a.slogan, b.slogan),
    (_officeHeadlineController, a.headline, b.headline),
  ];

  /// What the agent typed, or empty when it is the agency's own value, so
  /// the field keeps following the agency.
  String _own(TextEditingController controller, String agencyValue) {
    final text = controller.text.trim();
    return text == agencyValue.trim() ? '' : text;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final profile = ref
        .read(agentProfileProvider)
        .copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          mobile: CountryPhone.toStored(
            _mobileController.text,
            ref.read(regionProvider).country,
          ),
          agencyName: _agency.name,
          agencySlug: _agency.slug,
          agencyRegistrationNumber: _agencyRegNoController.text.trim(),
          licenceNumber: _licenceController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          ppraNumber: _ppraController.text.trim(),
          website: _websiteController.text.trim(),
          bio: _bioController.text.trim(),
          qualifications: _qualificationsController.text
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
          office: () {
            final agency = _agencyOffice(_agency);
            return OfficeDetails(
              name: _own(_officeNameController, agency.name),
              address: _own(_officeAddressController, agency.address),
              phone: _own(_officePhoneController, agency.phone),
              email: _own(_officeEmailController, agency.email),
              website: _own(_officeWebsiteController, agency.website),
              footer: _own(_officeFooterController, agency.footer),
              slogan: _own(_officeSloganController, agency.slogan),
              headline: _own(_officeHeadlineController, agency.headline),
              logos: ref.read(agentProfileProvider).office.logos,
            );
          }(),
        );

    try {
      await ref.read(agentProfileProvider.notifier).save(profile);
    } catch (e) {
      if (!mounted) return;
      final fields = mapFieldErrors(e);
      setState(() {
        _isSaving = false;
        _errors.addAll(fields);
        // The API validates one display name; show it on the first name.
        final nameError = fields['displayName'];
        if (nameError != null) _errors['firstName'] = nameError;
      });
      if (fields.isEmpty) {
        ScaffoldMessenger.of(context).showSnack(
          SnackBar(
            content: Text(mapFailure(e).message),
            backgroundColor: ref.read(themeConfigProvider).error,
          ),
        );
      }
      return;
    }

    // Saved: now the rest of the app takes on the agency's brand.
    await ref.read(agencyProvider.notifier).setAgency(_agency);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isDirty = false;
    });
    ScaffoldMessenger.of(context).showSnack(
      SnackBar(
        content: const Text('Profile updated'),
        backgroundColor: ref.read(themeConfigProvider).primaryColor,
      ),
    );
    context.pop();
  }

  /// Runs an upload (photo, signature, brochure pages), which saves at once.
  Future<void> _upload(String what, Future<void> Function() action) async {
    setState(() => _uploading = what);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnack(
          SnackBar(
            content: Text(mapFailure(e).message),
            backgroundColor: ref.read(themeConfigProvider).error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _changePhoto() async {
    final picked = await pickProfileImage(maxSide: 1600);
    if (picked == null || !mounted) return;
    // Framed by the agent in the circle it is shown in.
    final path = await cropToCircle(context, path: picked);
    if (path == null) return;
    await _upload(
      'photo',
      () => ref.read(agentProfileProvider.notifier).uploadPhoto(path),
    );
  }

  /// Draw a signature on the screen, or upload a photo of one.
  Future<void> _changeSignature(RealEstateTheme theme) async {
    final how = await showRealEstateBottomSheet<String>(
      context: context,
      theme: theme,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: const Text('Draw it on the screen'),
              subtitle: const Text('Sign with your finger'),
              onTap: () => Navigator.of(sheet).pop('draw'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Upload a photo'),
              subtitle: const Text('Your signature on white paper'),
              onTap: () => Navigator.of(sheet).pop('photo'),
            ),
          ],
        ),
      ),
    );
    if (how == null || !mounted) return;
    final path = how == 'draw'
        ? await showSignaturePad(context, theme)
        : await pickProfileImage();
    if (path == null) return;
    await _upload(
      'signature',
      () => ref.read(agentProfileProvider.notifier).uploadSignature(path),
    );
  }

  Future<void> _changeLogo(String kind) async {
    final path = await pickProfileImage(maxSide: 1200);
    if (path == null) return;
    await _upload(
      'logo-$kind',
      () =>
          ref.read(agentProfileProvider.notifier).uploadOfficeLogo(kind, path),
    );
  }

  Future<void> _addBrochurePages() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1754,
      maxHeight: 1754,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    await _upload(
      'brochure',
      () => ref.read(agentProfileProvider.notifier).addBrochurePages([
        for (final p in picked) p.path,
      ]),
    );
  }

  Future<void> _removeBrochurePage(String url) async {
    final own = ref.read(agentProfileProvider).brochurePages ?? const [];
    await _upload(
      'brochure',
      () => ref.read(agentProfileProvider.notifier).setBrochurePages([
        for (final p in own)
          if (p != url) p,
      ]),
    );
  }

  Future<void> _handleBack(RealEstateTheme theme) async {
    if (!_hasChanges) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: const Text('Discard changes?'),
        content: const Text(
          'Your profile changes have not been saved. '
          'Go back and they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Keep editing',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: theme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the agency list current if one is added from the picker.
    ref.watch(selectableAgenciesProvider);
    // Preview the selected agency here only; the global brand changes on save.
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme = isDark
        ? RealEstateTheme.fromAgencyDark(_agency)
        : RealEstateTheme.fromAgency(_agency);
    final textTheme = theme.toThemeData().textTheme;
    final country = ref.watch(regionProvider).country;
    final profile = ref.watch(agentProfileProvider);

    return ScopedBrandTheme(
      theme: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleBack(theme);
        },
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: WizardAppBar(
            title: 'My Profile',
            onBack: () => _handleBack(theme),
            theme: theme,
          ),
          body: SafeArea(
            bottom: false,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfilePhotoPicker(
                      photoUrl: profile.photoUrl,
                      initials: AgentProfile.initialsOf(
                        '${_firstNameController.text} ${_lastNameController.text}',
                      ),
                      busy: _uploading == 'photo',
                      theme: theme,
                      onTap: _changePhoto,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Agent', theme, textTheme),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            theme: theme,
                            label: 'First name',
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            errorText: _errors['firstName'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextInput(
                            theme: theme,
                            label: 'Last name',
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            errorText: _errors['lastName'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      isRequired: true,
                      errorText: _errors['email'],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Mobile number',
                      placeholder: '82 123 4567',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [CountryPhone.inputFormatter(country)],
                      prefixIcon: PhonePrefix(country: country, theme: theme),
                      isRequired: true,
                      errorText: _errors['mobile'],
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Agency', theme, textTheme),
                    AgencyField(
                      agency: _agency,
                      theme: theme,
                      onTap: () => _pickAgency(theme),
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Agency registration number',
                      keyboardType: TextInputType.datetime,
                      controller: _agencyRegNoController,
                      autocorrect: false,
                      errorText: _errors['agencyRegistrationNumber'],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'FFC number',
                      textCapitalization: TextCapitalization.characters,
                      controller: _licenceController,
                      autocorrect: false,
                      subtext: 'Fidelity Fund Certificate',
                      errorText: _errors['licenceNumber'],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'PPRA registration number',
                      controller: _ppraController,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      errorText: _errors['ppraNumber'],
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('On your reports', theme, textTheme),
                    CustomTextInput(
                      theme: theme,
                      label: 'Job title',
                      placeholder: 'e.g. Property Practitioner Specialist',
                      controller: _jobTitleController,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Your website',
                      placeholder: 'e.g. https://yourname.agency.co.za',
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      prefixIcon: Icon(
                        Icons.language,
                        color: theme.textSecondary,
                      ),
                      subtext:
                          'Printed on your report pack with your phone and email.',
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'About you',
                      placeholder:
                          'A few sentences for the "Your agent" page of the report',
                      controller: _bioController,
                      maxLines: 7,
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Qualifications & registrations',
                      placeholder: 'One per line, e.g. NQF4',
                      controller: _qualificationsController,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Signature (printed on the valuation letter)',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SignatureTile(
                      signatureUrl: profile.signatureUrl,
                      name:
                          '${_firstNameController.text} ${_lastNameController.text}',
                      busy: _uploading == 'signature',
                      theme: theme,
                      onTap: () => _changeSignature(theme),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Your office', theme, textTheme),
                    Text(
                      "Printed on your reports and letters. Filled in with "
                      "${_agency.name}'s details: change any of them for your "
                      'own office, or tap the reset button to go back to the '
                      "agency's.",
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (label, controller, fallback, keyboard, lines)
                        in [
                          (
                            'Office name',
                            _officeNameController,
                            _agency.office.name,
                            TextInputType.text,
                            1,
                          ),
                          (
                            'Office address',
                            _officeAddressController,
                            _agency.office.address,
                            TextInputType.streetAddress,
                            2,
                          ),
                          (
                            'Office phone',
                            _officePhoneController,
                            _agency.office.phone,
                            TextInputType.phone,
                            1,
                          ),
                          (
                            'Office email',
                            _officeEmailController,
                            _agency.office.email,
                            TextInputType.emailAddress,
                            1,
                          ),
                          (
                            'Office website',
                            _officeWebsiteController,
                            _agency.office.website,
                            TextInputType.url,
                            1,
                          ),
                          (
                            'Footer line',
                            _officeFooterController,
                            _agency.office.footer,
                            TextInputType.text,
                            3,
                          ),
                          (
                            'Slogan',
                            _officeSloganController,
                            _agency.office.slogan,
                            TextInputType.text,
                            1,
                          ),
                          (
                            'Your agent page heading (a *word* is in colour)',
                            _officeHeadlineController,
                            _agency.office.headline.isNotEmpty
                                ? _agency.office.headline
                                : OfficeDetails.defaultHeadline,
                            TextInputType.text,
                            1,
                          ),
                        ]) ...[
                      CustomTextInput(
                        theme: theme,
                        label: label,
                        controller: controller,
                        keyboardType: keyboard,
                        maxLines: lines,
                        autocorrect: false,
                        onChanged: (_) => setState(() {}),
                        subtext: fallback.isEmpty
                            ? null
                            : controller.text.trim() == fallback.trim()
                            ? "${_agency.name}'s"
                            : 'Your own',
                        suffixIcon:
                            fallback.isEmpty ||
                                controller.text.trim() == fallback.trim()
                            ? null
                            : IconButton(
                                tooltip: "Use ${_agency.name}'s",
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () =>
                                    setState(() => controller.text = fallback),
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 12),
                    _sectionLabel('Office logos', theme, textTheme),
                    Text(
                      'For your report pack. Empty uses ${_agency.name}\'s '
                      'logo. PNG with a clear background works best.',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (kind, label, onBrand) in [
                      ('mark', 'Square logo', false),
                      ('wide', 'Wide logo (on white)', false),
                      (
                        'wideOnBrand',
                        'Wide logo (on your agency colour)',
                        true,
                      ),
                    ]) ...[
                      LogoSlotTile(
                        label: label,
                        url: profile.office.logos[kind],
                        onBrand: onBrand,
                        busy: _uploading == 'logo-$kind',
                        theme: theme,
                        onTap: () => _changeLogo(kind),
                        onRemove: profile.office.logos[kind] == null
                            ? null
                            : () => _upload(
                                'logo-$kind',
                                () => ref
                                    .read(agentProfileProvider.notifier)
                                    .removeOfficeLogo(kind),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 18),
                    _sectionLabel('Brochure pages', theme, textTheme),
                    BrochurePagesEditor(
                      ownPages: profile.brochurePages,
                      agencyPages: _agency.brochurePages,
                      agencyName: _agency.name,
                      busy: _uploading == 'brochure',
                      theme: theme,
                      onAdd: _addBrochurePages,
                      onRemove: _removeBrochurePage,
                      onUseAgencyPages: () => _upload(
                        'brochure',
                        () => ref
                            .read(agentProfileProvider.notifier)
                            .setBrochurePages(null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              border: Border(top: BorderSide(color: theme.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _isSaving
                      ? Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : CustomButton(
                          text: 'Save Changes',
                          fullWidth: true,
                          theme: theme,
                          onTap: _save,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String text,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: theme.textLabel,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
