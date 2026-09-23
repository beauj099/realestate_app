import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/enums/document_category.dart';
import 'package:realworth/features/property_overview/data/models/listing_document.dart';

void main() {
  test('DocumentCategory.fromApi is case-insensitive', () {
    expect(DocumentCategory.fromApi('Levies'), DocumentCategory.levies);
    expect(DocumentCategory.fromApi('municipal'), DocumentCategory.municipal);
  });

  test('an unknown category files as other', () {
    expect(DocumentCategory.fromApi('insurance'), DocumentCategory.other);
    expect(DocumentCategory.fromApi(null), DocumentCategory.other);
  });

  test('ListingDocument.fromJson reads the API DTO', () {
    final doc = ListingDocument.fromJson({
      'id': 3,
      'category': 'water',
      'fileName': 'March.PDF',
      'url': '/uploads/listings/1/documents/abc.pdf',
      'contentType': 'application/pdf',
      'sizeBytes': 20480,
      'createdAt': '2026-09-22T10:00:00Z',
    });
    expect(doc.isUploaded, isTrue);
    expect(doc.category, DocumentCategory.water);
    expect(doc.isPdf, isTrue);
    expect(doc.sizeBytes, 20480);
  });

  test('a picked document is local until uploaded', () {
    const doc = ListingDocument(
      category: DocumentCategory.electricity,
      fileName: 'bill.jpg',
      localPath: '/tmp/bill.jpg',
    );
    expect(doc.isUploaded, isFalse);
    expect(doc.isPdf, isFalse);
  });
}
