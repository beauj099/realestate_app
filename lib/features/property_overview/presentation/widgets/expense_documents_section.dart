import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/photo_urls.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/enums/document_category.dart';
import '../../data/models/listing_document.dart';

/// The API's upload limit; checked here so the agent hears about it at once
/// rather than when they tap Save.
const int _maxDocumentBytes = 10 * 1024 * 1024;

enum _DocumentSource { camera, gallery, file }

/// Bills and statements backing the running costs — one row per kind of
/// account, each taking any number of photos or PDFs.
///
/// Changes stay in the shared section state until the Expenses screen is
/// saved, like every other field on it.
class ExpenseDocumentsSection extends StatelessWidget {
  final List<ListingDocument> documents;
  final RealEstateTheme theme;
  final String baseUrl;
  final ValueChanged<ListingDocument> onAdd;
  final ValueChanged<ListingDocument> onRemove;

  const ExpenseDocumentsSection({
    super.key,
    required this.documents,
    required this.theme,
    required this.baseUrl,
    required this.onAdd,
    required this.onRemove,
  });

  Future<void> _add(BuildContext context, DocumentCategory category) async {
    final source = await showRealEstateBottomSheet<_DocumentSource>(
      context: context,
      theme: theme,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () =>
                    Navigator.pop(sheetContext, _DocumentSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose a photo'),
                onTap: () =>
                    Navigator.pop(sheetContext, _DocumentSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Choose a PDF or file'),
                onTap: () => Navigator.pop(sheetContext, _DocumentSource.file),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    ListingDocument? document;
    if (source == _DocumentSource.file) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
      );
      final file = result?.files.single;
      if (file?.path == null) return;
      document = ListingDocument(
        category: category,
        fileName: file!.name,
        localPath: file.path,
        sizeBytes: file.size,
      );
    } else {
      final picked = await ImagePicker().pickImage(
        source: source == _DocumentSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Enough to read a bill, small enough to upload from site.
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      document = ListingDocument(
        category: category,
        fileName: picked.name,
        localPath: picked.path,
        sizeBytes: await picked.length(),
      );
    }

    if ((document.sizeBytes ?? 0) > _maxDocumentBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('That file is larger than 10 MB.'),
            backgroundColor: theme.error,
          ),
        );
      }
      return;
    }
    onAdd(document);
  }

  Future<void> _open(BuildContext context, ListingDocument document) async {
    final url = document.url;
    if (url == null) return;
    final opened = await launchUrl(
      Uri.parse(resolvePhotoUrl(url, baseUrl)),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supporting documents',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Attach recent accounts as photos or PDFs.',
          style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderLight),
          ),
          child: Column(
            children: [
              for (final category in DocumentCategory.values) ...[
                if (category != DocumentCategory.values.first)
                  Divider(height: 1, color: theme.borderLight),
                _CategoryRow(
                  category: category,
                  documents: documents
                      .where((d) => d.category == category)
                      .toList(),
                  theme: theme,
                  textTheme: textTheme,
                  onAdd: () => _add(context, category),
                  onOpen: (d) => _open(context, d),
                  onRemove: onRemove,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final DocumentCategory category;
  final List<ListingDocument> documents;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onAdd;
  final ValueChanged<ListingDocument> onOpen;
  final ValueChanged<ListingDocument> onRemove;

  const _CategoryRow({
    required this.category,
    required this.documents,
    required this.theme,
    required this.textTheme,
    required this.onAdd,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocs = documents.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category.icon,
                size: 20,
                color: hasDocs ? theme.completeColor : theme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.label,
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add, size: 18, color: theme.primaryColor),
                label: Text(
                  'Add',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          for (final doc in documents)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  Icon(
                    doc.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    size: 18,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: doc.isUploaded ? () => onOpen(doc) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName,
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.textPrimary,
                                decoration: doc.isUploaded
                                    ? TextDecoration.underline
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!doc.isUploaded)
                              Text(
                                'Uploads when you save',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: theme.pendingColor,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.textSecondary,
                    ),
                    onPressed: () => onRemove(doc),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
