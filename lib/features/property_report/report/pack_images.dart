import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/photo_urls.dart';
import 'valuation_report_pdf.dart';

/// Bytes of a picture for the report pack, or null when it cannot be had or
/// is not PNG/JPEG. [ref] is a device path (not yet uploaded), an API
/// `/uploads/…` path, or an absolute URL (R2, Property24). Absolute URLs are
/// fetched on a plain client, so the agent's token never leaves for another
/// host.
Future<Uint8List?> packImageBytes(String? ref, ApiClient api) async {
  if (ref == null || ref.isEmpty) return null;
  Uint8List? bytes;
  try {
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.bytes,
        ),
      ).get<List<int>>(ref);
      bytes = response.data == null ? null : Uint8List.fromList(response.data!);
    } else if (isRemotePhoto(ref)) {
      final response = await api.get<List<int>>(
        ref,
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 20),
      );
      bytes = response.data == null ? null : Uint8List.fromList(response.data!);
    } else if (await File(ref).exists()) {
      bytes = await File(ref).readAsBytes();
    }
  } catch (e) {
    developer.log('Report pack image unavailable ($ref): $e');
  }
  return ValuationReportPdf.isEmbeddableImage(bytes) ? bytes : null;
}
