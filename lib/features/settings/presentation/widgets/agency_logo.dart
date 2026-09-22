import 'package:flutter/material.dart';

import '../../../../core/theme/agency.dart';
import '../../../../core/widgets/platform_image.dart';

/// Draws an agency's brand mark.
///
/// In order of preference: a logo the agent uploaded for an agency they added
/// ([Agency.logoFilePath]), the bundled artwork ([Agency.imageAsset]), then a
/// monogram tile. Agencies with no bundled file skip the [Image.asset] load
/// entirely, so web builds never log a 404 for a file that does not exist.
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
        child: agencyLogoImage(agency, fallback: _monogram()),
      ),
    );
  }

  Widget _monogram() => AgencyMonogram(agency: agency, size: size);
}

/// The agency's artwork, unclipped, or [fallback] when it has none.
///
/// Uploaded logos can be any shape, so they are contained on white rather
/// than cropped; bundled logos are square tiles and fill their box.
Widget agencyLogoImage(
  Agency agency, {
  required Widget fallback,
  BoxFit bundledFit = BoxFit.cover,
}) {
  final filePath = agency.logoFilePath;
  if (filePath != null) {
    return ColoredBox(
      color: Colors.white,
      child: localFileImage(
        filePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
  final asset = agency.imageAsset;
  if (asset != null) {
    return Image.asset(
      asset,
      fit: bundledFit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
  return fallback;
}

/// Initials on the brand colour, for agencies without artwork.
class AgencyMonogram extends StatelessWidget {
  final Agency agency;
  final double size;

  const AgencyMonogram({super.key, required this.agency, required this.size});

  @override
  Widget build(BuildContext context) {
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
