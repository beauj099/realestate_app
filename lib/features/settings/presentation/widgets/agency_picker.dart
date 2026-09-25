import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/agency.dart';
import '../../../../core/theme/agency_directory.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/platform_image.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/searchable_picker.dart';
import 'agency_logo.dart';

/// Sentinel for the pinned "Other" row; never returned to callers.
const Agency _otherAgency = Agency(
  slug: '__other__',
  name: 'Other (not listed)',
  monogram: '+',
  primaryColor: Colors.transparent,
  secondaryColor: Colors.transparent,
  hasLogoFile: false,
);

/// Opens the agency picker and returns the chosen agency, or null if the
/// agent backed out.
///
/// Each row shows the agency's logo. "Other" lets the agent name an agency
/// that is not listed and optionally add its logo; it is then added to the
/// shared directory, so every agent can pick it (kept on this device until
/// the API can take it, e.g. during registration).
Future<Agency?> showAgencyPicker({
  required BuildContext context,
  required WidgetRef ref,
  required RealEstateTheme theme,
  Agency? selected,
  String title = 'Your Agency',
}) async {
  final agencies = ref.read(selectableAgenciesProvider);
  final result = await showSearchablePicker<Agency>(
    context: context,
    theme: theme,
    title: title,
    searchHint: 'Search agencies…',
    selectedValue: selected,
    options: [
      for (final a in agencies)
        PickerOption<Agency>(
          value: a,
          label: a.name,
          leading: AgencyLogo(agency: a, size: 36),
        ),
      PickerOption<Agency>(
        value: _otherAgency,
        label: _otherAgency.name,
        icon: Icons.add_business_outlined,
        pinned: true,
      ),
    ],
  );
  final picked = result?.option?.value;
  if (picked == null) return null;
  if (picked != _otherAgency) return picked;
  if (!context.mounted) return null;

  final added = await _showAddAgencySheet(
    context: context,
    theme: theme,
    initialName: result!.query,
  );
  if (added == null) return null;
  return ref
      .read(agencyDirectoryProvider.notifier)
      .add(name: added.name, logoPath: added.logoPath);
}

typedef _NewAgency = ({String name, String? logoPath});

Future<_NewAgency?> _showAddAgencySheet({
  required BuildContext context,
  required RealEstateTheme theme,
  String initialName = '',
}) {
  return showRealEstateBottomSheet<_NewAgency>(
    context: context,
    theme: theme,
    builder: (_) => _AddAgencySheet(theme: theme, initialName: initialName),
  );
}

class _AddAgencySheet extends StatefulWidget {
  final RealEstateTheme theme;
  final String initialName;

  const _AddAgencySheet({required this.theme, required this.initialName});

  @override
  State<_AddAgencySheet> createState() => _AddAgencySheetState();
}

class _AddAgencySheetState extends State<_AddAgencySheet> {
  late final TextEditingController _nameController;
  String? _logoPath;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    // Rebuild on every keystroke: the initials preview follows the name, and
    // a "required" error clears as soon as the agent types.
    _nameController.addListener(() => setState(() => _nameError = null));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _logoPath = picked.path);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Agency name is required');
      return;
    }
    Navigator.pop<_NewAgency>(context, (name: name, logoPath: _logoPath));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final preview = Agency.custom(
      slug: '${Agency.customSlugPrefix}preview',
      name: _nameController.text.trim().isEmpty
          ? '?'
          : _nameController.text.trim(),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your agency',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextInput(
              theme: theme,
              label: 'Agency name',
              textCapitalization: TextCapitalization.words,
              placeholder: 'e.g. Bay Realty',
              controller: _nameController,
              isRequired: true,
              errorText: _nameError,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderLight),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: _logoPath == null
                            ? AgencyMonogram(agency: preview, size: 56)
                            : ColoredBox(
                                color: Colors.white,
                                child: localFileImage(
                                  _logoPath!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _logoPath == null ? 'Add logo' : 'Change logo',
                            style: textTheme.titleMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Optional — initials are shown without one',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_logoPath != null)
                      IconButton(
                        tooltip: 'Remove logo',
                        icon: Icon(Icons.close, color: theme.textSecondary),
                        onPressed: () => setState(() => _logoPath = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save Agency',
              fullWidth: true,
              theme: theme,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only field showing the chosen agency's logo and name; tapping it
/// opens [showAgencyPicker].
class AgencyField extends StatelessWidget {
  final Agency? agency;
  final RealEstateTheme theme;
  final VoidCallback onTap;
  final String label;
  final String? errorText;

  const AgencyField({
    super.key,
    required this.agency,
    required this.theme,
    required this.onTap,
    this.label = 'Agency / company',
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? theme.error : theme.borderLight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (agency != null)
                  AgencyLogo(agency: agency!, size: 36)
                else
                  Icon(
                    Icons.apartment_outlined,
                    size: 24,
                    color: theme.textSecondary,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelLarge?.copyWith(
                          color: hasError ? theme.error : theme.textLabel,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agency?.name ?? 'Select your agency',
                        style: textTheme.titleMedium?.copyWith(
                          color: agency == null
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontWeight: agency == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              errorText!,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: theme.error,
              ),
            ),
          ),
      ],
    );
  }
}
