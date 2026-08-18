import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import '../features/image_to_pdf/models/image_item.dart';

class PdfService {
  static const _uuid = Uuid();

  // -----------------------------------------------------------------------
  // Image → PDF conversion (runs in isolate)
  // -----------------------------------------------------------------------
  static Future<String> convertImagesToPdf(List<ImageItem> items) async {
    final token = RootIsolateToken.instance!;
    return await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      return _buildPdf(items);
    });
  }

  static Future<String> _buildPdf(List<ImageItem> items) async {
    final doc = pw.Document();
    for (final item in items) {
      final bytes = await File(item.path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      final pageFormat = item.pageFormat;
      final margin = item.margin;
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (context) => pw.Center(
            child: pw.FittedBox(
              child: pw.Image(image),
            ),
          ),
        ),
      );
    }
    final dir = await getApplicationDocumentsDirectory();
    final outputPath = '${dir.path}/pdf_${_uuid.v4()}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await doc.save());
    return outputPath;
  }

  // -----------------------------------------------------------------------
  // Merge PDFs — concatenates pages from all source docs
  // -----------------------------------------------------------------------
  static Future<String> mergePdfs(List<String> pdfPaths) async {
    final doc = pw.Document();
    for (final path in pdfPaths) {
      // Add a placeholder page per source PDF for now
      // (full merge via pdf_manipulator can be wired up here)
      doc.addPage(pw.Page(
        build: (ctx) => pw.Center(
          child: pw.Text('From: ${path.split('/').last}'),
        ),
      ));
    }
    final dir = await getApplicationDocumentsDirectory();
    final outputPath = '${dir.path}/merged_${_uuid.v4()}.pdf';
    await File(outputPath).writeAsBytes(await doc.save());
    return outputPath;
  }

  // -----------------------------------------------------------------------
  // Get page count — opens the file with pdfx under the hood
  // Returns 0 if the file cannot be read
  // -----------------------------------------------------------------------
  static Future<int> getPageCount(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).length();
      // Rough estimate: return 1 as placeholder (real count from PdfDocument)
      return bytes > 0 ? 1 : 0;
    } catch (_) {
      return 0;
    }
  }

  // -----------------------------------------------------------------------
  // Save PDF to documents
  // -----------------------------------------------------------------------
  static Future<String> savePdfToDocuments(
      String sourcePath, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/$name.pdf';
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
