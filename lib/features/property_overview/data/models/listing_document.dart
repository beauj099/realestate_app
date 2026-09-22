import 'enums/document_category.dart';

/// A bill or statement attached to a listing's Expenses section.
///
/// Newly picked documents exist only on the device ([localPath] set, no
/// [id]) until the section is saved; uploaded ones carry the server [id] and
/// [url].
class ListingDocument {
  final int? id;
  final DocumentCategory category;
  final String fileName;
  final String? url;
  final String? localPath;
  final int? sizeBytes;

  const ListingDocument({
    this.id,
    required this.category,
    required this.fileName,
    this.url,
    this.localPath,
    this.sizeBytes,
  });

  bool get isUploaded => id != null;

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  factory ListingDocument.fromJson(Map<String, dynamic> json) {
    return ListingDocument(
      id: json['id'] as int?,
      category: DocumentCategory.fromApi(json['category'] as String?),
      fileName: json['fileName'] as String? ?? 'Document',
      url: json['url'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    );
  }
}
