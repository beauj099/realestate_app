import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/themes.dart';

/// Picks one image from the gallery, scaled for upload, or null when the agent
/// cancels.
Future<String?> pickProfileImage({double maxSide = 1200}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxSide,
    maxHeight: maxSide,
    imageQuality: 85,
  );
  return picked?.path;
}

/// The agent's round profile photo with a camera badge; tap to change it.
class ProfilePhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final bool busy;
  final RealEstateTheme theme;
  final VoidCallback onTap;

  const ProfilePhotoPicker({
    super.key,
    required this.photoUrl,
    required this.initials,
    required this.busy,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final url = photoUrl;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: busy ? null : onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                  foregroundImage: url == null ? null : NetworkImage(url),
                  child: Text(
                    initials,
                    style: textTheme.headlineSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 104,
                    height: 104,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: theme.primaryColor,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: theme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            url == null ? 'Add a profile photo' : 'Change photo',
            style: textTheme.bodySmall?.copyWith(color: theme.primaryColor),
          ),
        ],
      ),
    );
  }
}

/// The signature printed under the valuation letter.
class SignatureTile extends StatelessWidget {
  final String? signatureUrl;
  final bool busy;
  final RealEstateTheme theme;
  final VoidCallback onTap;

  const SignatureTile({
    super.key,
    required this.signatureUrl,
    required this.busy,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final url = signatureUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: busy ? null : onTap,
      child: Container(
        height: 88,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderLight),
        ),
        child: busy
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : url == null
            ? Center(
                child: Text(
                  'Upload a photo or scan of your signature',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              )
            : Image.network(url, fit: BoxFit.contain),
      ),
    );
  }
}

/// The brochure pages that end the agent's report packs: their own when they
/// uploaded some, otherwise the agency's.
class BrochurePagesEditor extends StatelessWidget {
  /// The agent's own pages, or null when they use the agency's.
  final List<String>? ownPages;
  final List<String> agencyPages;
  final String agencyName;
  final bool busy;
  final RealEstateTheme theme;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onUseAgencyPages;

  const BrochurePagesEditor({
    super.key,
    required this.ownPages,
    required this.agencyPages,
    required this.agencyName,
    required this.busy,
    required this.theme,
    required this.onAdd,
    required this.onRemove,
    required this.onUseAgencyPages,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final own = ownPages;
    final pages = own ?? agencyPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          own != null
              ? 'Your own pages end every report pack.'
              : agencyPages.isEmpty
              ? '$agencyName has no brochure pages yet. Add your own.'
              : "$agencyName's pages end every report pack. Add your own to "
                    'replace them.',
          style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
        ),
        const SizedBox(height: 10),
        if (pages.isNotEmpty)
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 106,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.borderLight),
                      ),
                      child: Image.network(pages[i], fit: BoxFit.cover),
                    ),
                  ),
                  if (own != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: busy ? null : () => onRemove(pages[i]),
                        child: const CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : onAdd,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(own == null ? 'Use my own pages' : 'Add pages'),
            ),
            if (own != null)
              TextButton(
                onPressed: busy ? null : onUseAgencyPages,
                child: Text("Use $agencyName's pages"),
              ),
          ],
        ),
      ],
    );
  }
}

/// One of the office's logos: shown on white, or on the agency colour for the
/// logo drawn for it; tap to upload, the cross to go back to the agency's.
class LogoSlotTile extends StatelessWidget {
  final String label;
  final String? url;
  final bool onBrand;
  final bool busy;
  final RealEstateTheme theme;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const LogoSlotTile({
    super.key,
    required this.label,
    required this.url,
    required this.onBrand,
    required this.busy,
    required this.theme,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final background = onBrand ? theme.primaryColor : Colors.white;
    final ink = onBrand ? theme.onPrimary : theme.textSecondary;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: busy ? null : onTap,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderLight),
              ),
              child: busy
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ink,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: url == null
                              ? Text(
                                  label,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: ink,
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.network(
                                    url!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                        Icon(
                          url == null
                              ? Icons.add_photo_alternate_outlined
                              : Icons.edit_outlined,
                          color: ink,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Use the agency\'s',
            icon: Icon(Icons.close, color: theme.textSecondary),
            onPressed: busy ? null : onRemove,
          ),
      ],
    );
  }
}
