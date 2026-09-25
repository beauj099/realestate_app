import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/locale/countries.dart';
import '../../data/models/contact.dart';
import 'contact_fields.dart';

class ContactCard extends StatelessWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final Contact contact;
  final Country country;
  final String label;
  final bool showRemove;
  final ValueChanged<Contact> onChanged;
  final VoidCallback? onRemove;
  final Map<String, String> errors;

  const ContactCard({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.contact,
    required this.country,
    required this.label,
    required this.showRemove,
    required this.onChanged,
    this.onRemove,
    this.errors = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: theme.textLabel,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.remove_circle_outline,
                    color: theme.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ContactFields(
            theme: theme,
            textTheme: textTheme,
            contact: contact,
            country: country,
            onChanged: onChanged,
            errors: errors,
          ),
        ],
      ),
    );
  }
}
