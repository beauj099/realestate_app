import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/wizard_scaffold.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_actions.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final bottomWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(top: BorderSide(color: theme.borderLight, width: 1.0)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: CustomButton(
            theme: theme,
            text: 'Submit Listing',
            onTap: () async {
              final success = await viewModel.submitAndSave();
              if (!context.mounted) return;
              if (success) {
                viewModel.reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Property listing submitted successfully!',
                    ),
                    backgroundColor: theme.primaryColor,
                  ),
                );
                context.go('/home');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'Failed to submit listing',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );

    return WizardScaffold(
      title: 'Review & Submit',
      description: 'Review all property details before submitting.',
      onBack: () => goBackWizard(context, ref),
      bottomWidget: bottomWidget,
      children: [
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'PROPERTY TYPE',
          children: [
            _buildDetailRow(
              textTheme,
              'Type ID',
              state.propertyTypeId.toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'ADDRESS',
          children: [
            _buildDetailRow(textTheme, 'Street Number', state.streetNumber),
            _buildDetailRow(textTheme, 'Street', state.street),
            if (state.unitNumber.isNotEmpty)
              _buildDetailRow(textTheme, 'Unit', state.unitNumber),
            _buildDetailRow(textTheme, 'Suburb', state.suburb),
            _buildDetailRow(textTheme, 'City', state.city),
            _buildDetailRow(textTheme, 'Province', state.province),
            _buildDetailRow(textTheme, 'Country', state.country),
            _buildDetailRow(textTheme, 'Postal Code', state.postalCode),
            if (state.estateName.isNotEmpty)
              _buildDetailRow(textTheme, 'Estate', state.estateName),
            if (state.erfNumber.isNotEmpty)
              _buildDetailRow(textTheme, 'Erf', state.erfNumber),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'BUILDING INFO',
          children: [
            if (state.erfSize.isNotEmpty)
              _buildDetailRow(textTheme, 'Erf Size', '${state.erfSize} m\u00B2'),
            if (state.floorArea.isNotEmpty)
              _buildDetailRow(textTheme, 'Floor Area', '${state.floorArea} m\u00B2'),
            if (state.constructionYear.isNotEmpty)
              _buildDetailRow(
                textTheme,
                'Construction Year',
                state.constructionYear,
              ),
            if (state.facingId != null)
              _buildDetailRow(textTheme, 'Facing ID', state.facingId.toString()),
            if (state.zoningId != null)
              _buildDetailRow(textTheme, 'Zoning ID', state.zoningId.toString()),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'PROPERTY FEATURES',
          children: [
            _buildDetailRow(
              textTheme,
              'Rooms',
              state.rooms.isEmpty
                  ? 'None'
                  : '${state.rooms.length} room(s)',
            ),
            ...state.rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  '\u2022 ${room.name} (Condition: ${room.conditionRating ?? "Not rated"})',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ),
            if (state.parking.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                textTheme,
                'Parking',
                state.parking
                    .map((p) => 'Type ${p.parkingTypeId} x${p.quantity}')
                    .join(', '),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'VALUATION & COSTS',
          children: [
            if (state.listingValuation.ownersNetPrice.isNotEmpty)
              _buildDetailRow(
                textTheme,
                "Owner's Price",
                'R ${state.listingValuation.ownersNetPrice}',
              ),
            if (state.listingValuation.agentValuation.isNotEmpty)
              _buildDetailRow(
                textTheme,
                'Agent Valuation',
                'R ${state.listingValuation.agentValuation}',
              ),
            if (state.listingValuation.commissionPercent.isNotEmpty)
              _buildDetailRow(
                textTheme,
                'Commission',
                '${state.listingValuation.commissionPercent}%',
              ),
            if (state.propertyRunningCosts.monthlyLevy.isNotEmpty)
              _buildDetailRow(
                textTheme,
                'Monthly Levy',
                'R ${state.propertyRunningCosts.monthlyLevy}',
              ),
            if (state.propertyRunningCosts.monthlyRates.isNotEmpty)
              _buildDetailRow(
                textTheme,
                'Monthly Rates',
                'R ${state.propertyRunningCosts.monthlyRates}',
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme: theme,
          textTheme: textTheme,
          title: 'CONTACTS',
          children: [
            _buildContactReviewSection(
              theme: theme,
              textTheme: textTheme,
              label: 'Primary Contact',
              contact: state.primaryContact,
            ),
            if (state.coContacts.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...state.coContacts.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildContactReviewSection(
                    theme: theme,
                    textTheme: textTheme,
                    label: 'Co-Contact ${entry.key + 1}',
                    contact: entry.value,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildContactReviewSection({
    required RealEstateTheme theme,
    required TextTheme textTheme,
    required String label,
    required dynamic contact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: theme.textLabel,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildDetailRow(textTheme, 'Name', contact.fullName),
        _buildDetailRow(textTheme, 'Email', contact.emailAddress),
        _buildDetailRow(textTheme, 'Phone', contact.mobilePhone),
        if (contact.idNumber.isNotEmpty)
          _buildDetailRow(textTheme, 'ID Number', contact.idNumber),
        if (contact.role.isNotEmpty)
          _buildDetailRow(textTheme, 'Role', contact.role),
      ],
    );
  }

  Widget _buildSectionCard({
    required RealEstateTheme theme,
    required TextTheme textTheme,
    required String title,
    required List<Widget> children,
  }) {
    return CustomCard(
      theme: theme,
      backgroundColor: theme.cardBackgroundColor,
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: theme.textLabel,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
