import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/busy_overlay.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../data/models/report_settings.dart';
import '../../providers/report_settings_provider.dart';
import '../../../../core/widgets/app_snack.dart';

/// The agent's own defaults for the report pack: the costs calculator and how
/// much each kind of room counts towards the suggested house score. Each
/// report can still change the calculator figures for itself.
class ReportSettingsScreen extends ConsumerStatefulWidget {
  const ReportSettingsScreen({super.key});

  @override
  ConsumerState<ReportSettingsScreen> createState() =>
      _ReportSettingsScreenState();
}

class _ReportSettingsScreenState extends ConsumerState<ReportSettingsScreen> {
  late ReportSettings _settings;
  late final Map<String, TextEditingController> _numbers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(reportSettingsProvider);
    final c = _settings.calculator;
    String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    _numbers = {
      'early': TextEditingController(text: n(c.commissionEarlyPercent)),
      'late': TextEditingController(text: n(c.commissionLatePercent)),
      'months': TextEditingController(text: '${c.earlyMonths}'),
      'rate': TextEditingController(text: n(c.interestRatePercent)),
      'term': TextEditingController(text: '${c.bondTermYears}'),
      'deposit': TextEditingController(text: n(c.depositPercent)),
    };
  }

  @override
  void dispose() {
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(String key, double fallback) =>
      double.tryParse(_numbers[key]!.text.replaceAll(',', '.')) ?? fallback;

  Future<void> _save() async {
    final c = _settings.calculator;
    final settings = _settings.copyWith(
      calculator: c.copyWith(
        commissionEarlyPercent: _num('early', c.commissionEarlyPercent),
        commissionLatePercent: _num('late', c.commissionLatePercent),
        earlyMonths: _num('months', c.earlyMonths.toDouble()).round(),
        interestRatePercent: _num('rate', c.interestRatePercent),
        bondTermYears: _num('term', c.bondTermYears.toDouble()).round(),
        depositPercent: _num('deposit', c.depositPercent),
      ),
    );
    setState(() => _saving = true);
    try {
      await ref
          .read(agentProfileProvider.notifier)
          .saveReportSettings(settings);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnack(
        SnackBar(
          content: Text(mapFailure(e).message),
          backgroundColor: ref.read(themeConfigProvider).error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;
    final decimals = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    Widget field(String key, String label, {String? suffix}) => Expanded(
      child: CustomTextInput(
        theme: theme,
        label: label,
        controller: _numbers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: decimals,
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(widthFactor: 1, child: Text(suffix)),
              ),
      ),
    );

    return BusyOverlay(
      busy: _saving,
      theme: theme,
      title: 'Saving your settings…',
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Report settings',
          theme: theme,
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _label('Costs to seller and buyer', theme, textTheme),
              Text(
                'Your starting figures. Each report can change them.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  field('early', 'Commission, quick sale', suffix: '%'),
                  const SizedBox(width: 12),
                  field('months', 'Quick sale within', suffix: 'months'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  field('late', 'Commission after that', suffix: '%'),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add VAT (15%) to commission'),
                value: _settings.calculator.commissionIncludesVat,
                onChanged: (v) => setState(
                  () => _settings = _settings.copyWith(
                    calculator: _settings.calculator.copyWith(
                      commissionIncludesVat: v,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  field('rate', 'Home-loan interest rate', suffix: '%'),
                  const SizedBox(width: 12),
                  field('term', 'Loan term', suffix: 'years'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  field('deposit', "Buyer's deposit", suffix: '%'),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 28),
              _label('Room weights for the house score', theme, textTheme),
              Text(
                'How much each kind of room counts when the app suggests a '
                'house score from the room scores.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final c in RoomWeightClass.values)
                _WeightSlider(
                  label: c.label,
                  value: _settings.roomWeights.of(c),
                  isDefault: _settings.roomWeights.of(c) == c.defaultWeight,
                  theme: theme,
                  onChanged: (v) => setState(
                    () => _settings = _settings.copyWith(
                      roomWeights: _settings.roomWeights.withWeight(c, v),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _settings.roomWeights.isDefault
                      ? null
                      : () => setState(
                          () => _settings = _settings.copyWith(
                            roomWeights: RoomWeights.defaults,
                          ),
                        ),
                  child: const Text('Reset room weights'),
                ),
              ),
            ],
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
              child: CustomButton(
                text: 'Save',
                fullWidth: true,
                theme: theme,
                onTap: _saving ? null : _save,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, RealEstateTheme theme, TextTheme textTheme) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
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

class _WeightSlider extends StatelessWidget {
  final String label;
  final double value;
  final bool isDefault;
  final RealEstateTheme theme;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.label,
    required this.value,
    required this.isDefault,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: textTheme.bodyMedium)),
              Text(
                '×${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isDefault ? FontWeight.normal : FontWeight.bold,
                  color: isDefault ? theme.textSecondary : theme.primaryColor,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, 5),
            min: 0,
            max: 5,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
