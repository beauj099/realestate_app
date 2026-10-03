import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../data/models/listing_details.dart';
import '../../providers/property_provider.dart';
import '../widgets/details_fields.dart';
import '../widgets/wizard_section_scaffold.dart';

/// Mandate & Listing: the myEdge form's mandate information (type, dates,
/// source, referral, reason for selling, included and excluded items,
/// defects), the tenant, and the listing's portal references. The mandate
/// document itself is made from these.
class MandateScreen extends ConsumerWidget {
  const MandateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final d = state.details;
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final currency = ref.watch(regionProvider).currencySymbol;
    final textTheme = theme.toThemeData().textTheme;
    void edit(ListingDetails Function(ListingDetails d) change) =>
        viewModel.editDetails(change);
    const gap = SizedBox(height: 14);
    const section = SizedBox(height: 26);

    return WizardSectionScaffold(
      title: 'Mandate & Listing',
      sectionName: 'mandate',
      onSave: () async {
        await viewModel.saveDetails();
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null ? null : friendlySaveMessage(error, 'mandate');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The mandate',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChoiceChips(
            options: const ['For Sale', 'For Let'],
            selected: d.forLet ? 'For Let' : 'For Sale',
            theme: theme,
            onChanged: (v) => edit((d) => d.copyWith(forLet: v == 'For Let')),
          ),
          section,
          FieldHeading('Mandate type', theme: theme),
          SingleChoiceChips(
            options: ListingDetails.mandateTypes,
            selected: d.mandateType,
            theme: theme,
            onChanged: (v) => edit((d) => d.copyWith(mandateType: v)),
          ),
          section,
          Row(
            children: [
              Expanded(
                child: DateField(
                  label: 'Signed',
                  value: d.mandateSigned,
                  theme: theme,
                  onChanged: (v) => edit(
                    (d) => v == null
                        ? d.copyWith(clearMandateSigned: true)
                        : d.copyWith(mandateSigned: v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DateField(
                  label: 'Expires',
                  value: d.mandateExpiry,
                  theme: theme,
                  onChanged: (v) => edit(
                    (d) => v == null
                        ? d.copyWith(clearMandateExpiry: true)
                        : d.copyWith(mandateExpiry: v),
                  ),
                ),
              ),
            ],
          ),
          gap,
          DateField(
            label: 'Occupation date',
            value: d.occupationDate,
            theme: theme,
            onChanged: (v) => edit(
              (d) => v == null
                  ? d.copyWith(clearOccupationDate: true)
                  : d.copyWith(occupationDate: v),
            ),
          ),
          section,
          FieldHeading('Where the mandate came from', theme: theme),
          SingleChoiceChips(
            options: ListingDetails.mandateSources,
            selected: d.mandateSource,
            theme: theme,
            onChanged: (v) => edit((d) => d.copyWith(mandateSource: v)),
          ),
          if (d.mandateSource == 'Referral') ...[
            const SizedBox(height: 16),
            FieldHeading('External agent referral', theme: theme),
            CustomTextInput(
              theme: theme,
              label: 'Agent name',
              keyboardType: TextInputType.name,
              initialValue: d.referralName,
              onChanged: (v) => edit((d) => d.copyWith(referralName: v)),
            ),
            gap,
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextInput(
                    theme: theme,
                    label: 'Cellphone',
                    keyboardType: TextInputType.phone,
                    initialValue: d.referralPhone,
                    onChanged: (v) => edit((d) => d.copyWith(referralPhone: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomTextInput(
                    theme: theme,
                    label: 'Commission %',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    initialValue: d.referralPercent,
                    onChanged: (v) =>
                        edit((d) => d.copyWith(referralPercent: v)),
                  ),
                ),
              ],
            ),
          ],
          section,
          CustomTextInput(
            theme: theme,
            label: 'Reason for selling',
            initialValue: d.reasonForSelling,
            onChanged: (v) => edit((d) => d.copyWith(reasonForSelling: v)),
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Included items',
            placeholder: 'e.g. curtains, dishwasher, pool pump',
            initialValue: d.includedItems,
            maxLines: 3,
            onChanged: (v) => edit((d) => d.copyWith(includedItems: v)),
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Excluded items',
            placeholder: 'e.g. chandelier in the dining room',
            initialValue: d.excludedItems,
            maxLines: 3,
            onChanged: (v) => edit((d) => d.copyWith(excludedItems: v)),
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Defects',
            placeholder: 'Known defects the seller has told you about',
            initialValue: d.defects,
            maxLines: 3,
            onChanged: (v) => edit((d) => d.copyWith(defects: v)),
          ),
          section,
          FieldHeading('Tenant', theme: theme),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Current rental',
                  prefixIcon: CurrencyPrefix(symbol: currency, theme: theme),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  initialValue: d.currentRental,
                  onChanged: (v) => edit((d) => d.copyWith(currentRental: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DateField(
                  label: 'Lease expires',
                  value: d.leaseExpiry,
                  theme: theme,
                  onChanged: (v) => edit(
                    (d) => v == null
                        ? d.copyWith(clearLeaseExpiry: true)
                        : d.copyWith(leaseExpiry: v),
                  ),
                ),
              ),
            ],
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Tenant details / viewing arrangements',
            initialValue: d.tenantViewing,
            maxLines: 2,
            onChanged: (v) => edit((d) => d.copyWith(tenantViewing: v)),
          ),
          section,
          FieldHeading('Listing', theme: theme),
          CustomTextInput(
            theme: theme,
            label: 'Property title',
            placeholder: 'e.g. Family home with a flatlet',
            initialValue: d.listingTitle,
            onChanged: (v) => edit((d) => d.copyWith(listingTitle: v)),
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'KWL ref',
                  initialValue: d.kwlRef,
                  onChanged: (v) => edit((d) => d.copyWith(kwlRef: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'P24 ref',
                  initialValue: d.p24Ref,
                  onChanged: (v) => edit((d) => d.copyWith(p24Ref: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Entegral ref',
                  initialValue: d.entegralRef,
                  onChanged: (v) => edit((d) => d.copyWith(entegralRef: v)),
                ),
              ),
            ],
          ),
          gap,
          MultiChoiceChips(
            options: ListingDetails.displayOptions,
            selected: d.display,
            theme: theme,
            onChanged: (v) => edit((d) => d.copyWith(display: v)),
          ),
        ],
      ),
    );
  }
}
