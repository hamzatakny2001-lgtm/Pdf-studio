import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static Future<String> rotateImage(String path, int degrees) async {
    return compute(_rotateIsolate, _RotateParams(path, degrees));
  }

  static Future<String> adjustImage(
      String path, double brightness, double contrast) async {
    return compute(_adjustIsolate, _AdjustParams(path, brightness, contrast));
  }

  static Future<Uint8List> generateThumbnail(String path,
      {int size = 200}) async {
    return compute(_thumbnailIsolate, _ThumbnailParams(path, size));
  }
}

class _RotateParams {
  final String path;
  final int degrees;
  _RotateParams(this.path, this.degrees);
}

class _AdjustParams {
  final String path;
  final double brightness;
  final double contrast;
  _AdjustParams(this.path, this.brightness, this.contrast);
}

class _ThumbnailParams {
  final String path;
  final int size;
  _ThumbnailParams(this.path, this.size);
}

Future<String> _rotateIsolate(_RotateParams params) async {
  final bytes = await File(params.path).readAsBytes();
  var image = img.decodeImage(bytes)!;
  image = img.copyRotate(image, angle: params.degrees.toDouble());
  final dir = await getApplicationCacheDirectory();
  final outPath = '${dir.path}/rot_${const Uuid().v4()}.jpg';
  await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
  return outPath;
}

Future<String> _adjustIsolate(_AdjustParams params) async {
  final bytes = await File(params.path).readAsBytes();
  var image = img.decodeImage(bytes)!;
  image = img.adjustColor(
    image,
    brightness: params.brightness,
    contrast: params.contrast,
  );
  final dir = await getApplicationCacheDirectory();
  final outPath = '${dir.path}/adj_${const Uuid().v4()}.jpg';
  await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 90));
  return outPath;
}

Future<Uint8List> _thumbnailIsolate(_ThumbnailParams params) async {
  final bytes = await File(params.path).readAsBytes();
  var image = img.decodeImage(bytes)!;
  image = img.copyResize(image, width: params.size);
  return Uint8List.fromList(img.encodeJpg(image, quality: 75));
}
