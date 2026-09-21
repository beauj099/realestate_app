import 'package:flutter/material.dart';

import '../../../../core/theme/agency.dart';

/// Draws an agency's brand mark.
///
/// Prefers the logo file the brand owner drops into
/// `assets/images/agencies/<slug>.png`. Agencies with no bundled file
/// ([Agency.hasLogoFile] == false) render the monogram tile directly without
/// attempting an [Image.asset] load, so web builds never log a 404 for a
/// file that intentionally does not exist.
class AgencyLogo extends StatelessWidget {
  final Agency agency;
  final double size;

  const AgencyLogo({super.key, required this.agency, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // Skip the asset fetch entirely when no file ships: the errorBuilder
    // fallback would still draw the monogram, but on web the failed fetch
    // logs "Flutter Web engine failed to fetch ..." to the console first.
    if (!agency.hasLogoFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SizedBox(width: size, height: size, child: _monogram()),
      );
    }
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
