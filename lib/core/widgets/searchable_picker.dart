import 'package:flutter/material.dart';

import '../theme/themes.dart';

/// One selectable row in a [showSearchablePicker] sheet.
class PickerOption<T> {
  final T value;
  final String label;

  /// Optional heading this option is filed under (e.g. "Bedrooms").
  final String? group;

  /// Leading glyph. Options without one fall back to a neutral dot.
  final IconData? icon;

  /// Replaces the [icon] tile entirely, e.g. with a brand logo.
  final Widget? leading;

  /// Kept in the list whatever is typed — for an escape hatch such as
  /// "Other" that must stay reachable when nothing matches.
  final bool pinned;

  const PickerOption({
    required this.value,
    required this.label,
    this.group,
    this.icon,
    this.leading,
    this.pinned = false,
  });
}

/// What the user chose: either an existing [option] or a [customLabel] they
/// typed when the picker allows free text.
class PickerResult<T> {
  final PickerOption<T>? option;
  final String? customLabel;

  /// What was in the search field when the choice was made, so a follow-up
  /// step (e.g. naming an unlisted entry) can start from it.
  final String query;

  const PickerResult.option(this.option, {this.query = ''})
    : customLabel = null;
  const PickerResult.custom(this.customLabel) : option = null, query = '';

  bool get isCustom => customLabel != null;
}

/// Opens a type-to-filter picker sheet.
///
/// Replaces the full-screen grids and long chip walls the wizard used to use:
/// the agent starts typing and the list narrows, so a 25-item room list is one
/// or two keystrokes away instead of a scroll hunt. The sheet keeps its search
/// field and action bar pinned while only the results scroll, and it sizes
/// itself against the keyboard so nothing is ever clipped.
///
/// When [customLabel] is supplied the agent can also commit whatever they typed
/// as a brand-new entry, which is how custom room names are added.
Future<PickerResult<T>?> showSearchablePicker<T>({
  required BuildContext context,
  required RealEstateTheme theme,
  required String title,
  required List<PickerOption<T>> options,
  String searchHint = 'Search…',
  String? customLabel,
  String? customHint,
  T? selectedValue,
}) {
  return showModalBottomSheet<PickerResult<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.cardBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (sheetContext) => _SearchablePickerSheet<T>(
      theme: theme,
      title: title,
      options: options,
      searchHint: searchHint,
      customLabel: customLabel,
      customHint: customHint,
      selectedValue: selectedValue,
    ),
  );
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final RealEstateTheme theme;
  final String title;
  final List<PickerOption<T>> options;
  final String searchHint;
  final String? customLabel;
  final String? customHint;
  final T? selectedValue;

  const _SearchablePickerSheet({
    required this.theme,
    required this.title,
    required this.options,
    required this.searchHint,
    this.customLabel,
    this.customHint,
    this.selectedValue,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PickerOption<T>> get _filtered {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.pinned || o.label.toLowerCase().contains(needle))
        .toList();
  }

  /// True when the typed text is not already one of the options, so offering to
  /// add it as a custom entry is actually useful.
  bool get _canAddCustom {
    if (widget.customLabel == null) return false;
    final typed = _query.trim();
    if (typed.isEmpty) return false;
    return !widget.options.any(
      (o) => o.label.toLowerCase() == typed.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final media = MediaQuery.of(context);
    final results = _filtered;

    return Padding(
      // Lift the whole sheet above the keyboard so the search field and the
      // action row stay visible while typing.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    // Typed text can become a custom entry (e.g. a room
                    // name), so start it with a capital.
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: theme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      filled: true,
                      fillColor: theme.borderLight.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: results.isEmpty && !_canAddCustom
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Text(
                        'No matches for "${_query.trim()}".',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) =>
                          _buildRow(results, index, theme, textTheme),
                    ),
            ),
            _buildFooter(theme, textTheme),
          ],
        ),
      ),
    );
  }

  /// Renders one result, preceded by its group heading when the group changes.
  /// Headings are suppressed while filtering because a narrowed list reads
  /// better as a flat set of matches.
  Widget _buildRow(
    List<PickerOption<T>> results,
    int index,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    final option = results[index];
    final showHeading =
        _query.trim().isEmpty &&
        option.group != null &&
        (index == 0 || results[index - 1].group != option.group);
    final isSelected =
        widget.selectedValue != null && option.value == widget.selectedValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading)
          Padding(
            padding: EdgeInsets.fromLTRB(20, index == 0 ? 4 : 16, 20, 4),
            child: Text(
              option.group!.toUpperCase(),
              style: textTheme.labelLarge?.copyWith(
                color: theme.textLabel,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        InkWell(
          onTap: () => Navigator.pop(
            context,
            PickerResult<T>.option(option, query: _query.trim()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.08)
                : null,
            child: Row(
              children: [
                option.leading ??
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.borderLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option.icon ?? Icons.circle_outlined,
                        size: 19,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textSecondary,
                      ),
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 20, color: theme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Pinned action row: always reachable, never scrolled off the bottom.
  Widget _buildFooter(RealEstateTheme theme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(top: BorderSide(color: theme.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_canAddCustom)
              Expanded(
                child: Text(
                  '${widget.customHint ?? 'Add'} "${_query.trim()}"',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
            if (_canAddCustom) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  PickerResult<T>.custom(_query.trim()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.customLabel!,
                  style: TextStyle(color: theme.onPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
