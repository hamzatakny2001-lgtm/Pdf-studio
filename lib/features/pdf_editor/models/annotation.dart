import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum AnnotationType { text, highlight, draw, stamp, comment }

class DrawPoint {
  final Offset point;
  final bool isStart; // true = pen down (start of stroke)
  const DrawPoint(this.point, {this.isStart = false});
}

class Annotation extends Equatable {
  final String id;
  final int pageIndex;
  final AnnotationType type;
  // Text
  final String? text;
  final Offset? position;
  final double fontSize;
  final Color textColor;
  // Highlight / stamp rect
  final Rect? rect;
  final Color color;
  // Draw strokes
  final List<DrawPoint> strokes;
  final double strokeWidth;

  const Annotation({
    required this.id,
    required this.pageIndex,
    required this.type,
    this.text,
    this.position,
    this.fontSize = 16.0,
    this.textColor = Colors.black,
    this.rect,
    this.color = const Color(0xAAFFFF00),
    this.strokes = const [],
    this.strokeWidth = 3.0,
  });

  factory Annotation.text({
    required int pageIndex,
    required String text,
    required Offset position,
    double fontSize = 16,
    Color textColor = Colors.black,
  }) =>
      Annotation(
        id: const Uuid().v4(),
        pageIndex: pageIndex,
        type: AnnotationType.text,
        text: text,
        position: position,
        fontSize: fontSize,
        textColor: textColor,
        color: Colors.transparent,
      );

  factory Annotation.highlight({
    required int pageIndex,
    required Rect rect,
    Color color = const Color(0xAAFFFF00),
  }) =>
      Annotation(
        id: const Uuid().v4(),
        pageIndex: pageIndex,
        type: AnnotationType.highlight,
        rect: rect,
        color: color,
      );

  factory Annotation.draw({
    required int pageIndex,
    required List<DrawPoint> strokes,
    Color color = Colors.blue,
    double strokeWidth = 3.0,
  }) =>
      Annotation(
        id: const Uuid().v4(),
        pageIndex: pageIndex,
        type: AnnotationType.draw,
        strokes: strokes,
        color: color,
        strokeWidth: strokeWidth,
      );

  factory Annotation.comment({
    required int pageIndex,
    required String text,
    required Offset position,
  }) =>
      Annotation(
        id: const Uuid().v4(),
        pageIndex: pageIndex,
        type: AnnotationType.comment,
        text: text,
        position: position,
        color: const Color(0xFFFFF9C4),
      );

  Annotation copyWith({Offset? position, String? text, Rect? rect}) =>
      Annotation(
        id: id,
        pageIndex: pageIndex,
        type: type,
        text: text ?? this.text,
        position: position ?? this.position,
        fontSize: fontSize,
        textColor: textColor,
        rect: rect ?? this.rect,
        color: color,
        strokes: strokes,
        strokeWidth: strokeWidth,
      );

  @override
  List<Object?> get props => [id, pageIndex, type, text, position, rect, color];
}
