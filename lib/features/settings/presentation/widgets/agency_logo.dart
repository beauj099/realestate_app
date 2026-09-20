import 'package:flutter/material.dart';

import '../../../../core/theme/agency.dart';

/// Draws an agency's brand mark.
///
/// Prefers the logo file the brand owner drops into
/// `assets/images/agencies/<slug>.png`. No agency artwork ships with the repo,
/// so until a file is supplied this falls back to a monogram tile in the
/// agency's own colours — which keeps every screen looking finished instead of
/// showing a broken-image box.
class AgencyLogo extends StatelessWidget {
  final Agency agency;
  final double size;

  const AgencyLogo({super.key, required this.agency, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          agency.logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _monogram(),
        ),
      ),
    );
  }

  Widget _monogram() {
    return Container(
      color: agency.primaryColor,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Text(
            agency.monogram,
            style: TextStyle(
              color: agency.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
