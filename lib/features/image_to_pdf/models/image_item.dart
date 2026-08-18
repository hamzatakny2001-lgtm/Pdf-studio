import 'package:equatable/equatable.dart';
import 'package:pdf/pdf.dart';
import 'package:uuid/uuid.dart';

enum PageSize { a4, letter, a3, custom }

class ImageItem extends Equatable {
  final String id;
  final String path;
  final int rotation; // 0, 90, 180, 270
  final double brightness; // -1.0 to 1.0
  final double contrast;   // 0.5 to 2.0
  final PageSize pageSize;
  final double margin;     // points

  const ImageItem({
    required this.id,
    required this.path,
    this.rotation = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.pageSize = PageSize.a4,
    this.margin = 20.0,
  });

  factory ImageItem.fromPath(String path) => ImageItem(
        id: const Uuid().v4(),
        path: path,
      );

  PdfPageFormat get pageFormat {
    switch (pageSize) {
      case PageSize.a4:
        return PdfPageFormat.a4;
      case PageSize.letter:
        return PdfPageFormat.letter;
      case PageSize.a3:
        return PdfPageFormat.a3;
      case PageSize.custom:
        return PdfPageFormat.a4;
    }
  }

  ImageItem copyWith({
    String? path,
    int? rotation,
    double? brightness,
    double? contrast,
    PageSize? pageSize,
    double? margin,
  }) =>
      ImageItem(
        id: id,
        path: path ?? this.path,
        rotation: rotation ?? this.rotation,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        pageSize: pageSize ?? this.pageSize,
        margin: margin ?? this.margin,
      );

  @override
  List<Object?> get props =>
      [id, path, rotation, brightness, contrast, pageSize, margin];
}
