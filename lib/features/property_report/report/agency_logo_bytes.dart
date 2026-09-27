import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/agency.dart';
import 'valuation_report_pdf.dart';

/// The agency's logo for the PDF header, in the order the app shows it: the
/// logo an agent uploaded on this device, the API's (R2), then the bundled
/// file. Only PNG and JPEG can go in a PDF; null means "print the name".
///
/// The R2 request goes out on a plain client, never [ApiClient], so the
/// agent's token is not sent to the storage host.
Future<Uint8List?> agencyLogoBytes(Agency agency) async {
  Uint8List? usable(Uint8List? bytes) =>
      ValuationReportPdf.isEmbeddableImage(bytes) ? bytes : null;

  try {
    final path = agency.logoFilePath;
    if (path != null && await File(path).exists()) {
      final bytes = usable(await File(path).readAsBytes());
      if (bytes != null) return bytes;
    }
  } catch (e) {
    developer.log('Agency logo file unreadable: $e');
  }

  final url = agency.logoUrl;
  if (url != null) {
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
          responseType: ResponseType.bytes,
        ),
      ).get<List<int>>(url);
      final data = response.data;
      final bytes = usable(data == null ? null : Uint8List.fromList(data));
      if (bytes != null) return bytes;
    } catch (e) {
      developer.log('Agency logo download failed ($url): $e');
    }
  }

  final asset =
      agency.assetOverride ?? (agency.hasLogoFile ? agency.logoAsset : null);
  if (asset != null) {
    try {
      return usable((await rootBundle.load(asset)).buffer.asUint8List());
    } catch (e) {
      developer.log('Bundled agency logo missing ($asset): $e');
    }
  }
  return null;
}
