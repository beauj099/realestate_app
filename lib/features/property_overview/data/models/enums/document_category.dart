import 'package:flutter/material.dart';

/// Kind of supporting document attached under Expenses. [apiValue] is the
/// lowercase string the API stores.
enum DocumentCategory {
  water('water', 'Water account', Icons.water_drop_outlined),
  electricity('electricity', 'Electricity account', Icons.bolt_outlined),
  municipal('municipal', 'Municipal account', Icons.account_balance_outlined),
  levies('levies', 'Levy statement', Icons.apartment_outlined),
  other('other', 'Other document', Icons.description_outlined);

  final String apiValue;
  final String label;
  final IconData icon;

  const DocumentCategory(this.apiValue, this.label, this.icon);

  /// Unknown values (e.g. a category added server-side later) file as other.
  static DocumentCategory fromApi(String? value) => values.firstWhere(
    (c) => c.apiValue == value?.toLowerCase(),
    orElse: () => DocumentCategory.other,
  );
}
