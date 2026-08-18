import 'package:flutter/material.dart';
import '../cubit/pdf_editor_cubit.dart';
import '../models/annotation.dart';

class AnnotationLayer extends StatefulWidget {
  final List<Annotation> annotations;
  final EditorTool activeTool;
  final Color drawColor;
  final double strokeWidth;
  final int pageIndex;
  final void Function(Annotation) onAnnotationAdded;
  final void Function(Annotation) onAnnotationUpdated;

  const AnnotationLayer({
    super.key,
    required this.annotations,
    required this.activeTool,
    required this.drawColor,
    required this.strokeWidth,
    required this.pageIndex,
    required this.onAnnotationAdded,
    required this.onAnnotationUpdated,
  });

  @override
  State<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends State<AnnotationLayer> {
  Offset? _dragStart;
  List<DrawPoint> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: _onTapUp,
      child: CustomPaint(
        painter: _AnnotationPainter(
          annotations: widget.annotations,
          currentStroke: _currentStroke,
          drawColor: widget.drawColor,
          strokeWidth: widget.strokeWidth,
          dragStart: _dragStart,
        ),
        child: Stack(
          children: [
            for (final ann in widget.annotations)
              if (ann.type == AnnotationType.text ||
                  ann.type == AnnotationType.comment)
                _TextAnnotationWidget(
                  annotation: ann,
                  onMoved: (newPos) => widget.onAnnotationUpdated(
                      ann.copyWith(position: newPos)),
                ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.activeTool == EditorTool.draw) {
      setState(() {
        _currentStroke = [DrawPoint(d.localPosition, isStart: true)];
      });
    } else if (widget.activeTool == EditorTool.highlight) {
      setState(() => _dragStart = d.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (widget.activeTool == EditorTool.draw) {
      setState(() => _currentStroke.add(DrawPoint(d.localPosition)));
    } else if (widget.activeTool == EditorTool.highlight) {
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (widget.activeTool == EditorTool.draw && _currentStroke.isNotEmpty) {
      widget.onAnnotationAdded(Annotation.draw(
        pageIndex: widget.pageIndex,
        strokes: List.from(_currentStroke),
        color: widget.drawColor,
        strokeWidth: widget.strokeWidth,
      ));
      setState(() => _currentStroke = []);
    } else if (widget.activeTool == EditorTool.highlight &&
        _dragStart != null) {
      // Highlight rect will be finalized on next gesture
    }
  }

  void _onTapUp(TapUpDetails d) {
    if (widget.activeTool == EditorTool.text) {
      _showTextInput(d.localPosition);
    } else if (widget.activeTool == EditorTool.comment) {
      _showCommentInput(d.localPosition);
    }
  }

  void _showTextInput(Offset pos) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter text...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                widget.onAnnotationAdded(Annotation.text(
                  pageIndex: widget.pageIndex,
                  text: ctrl.text,
                  position: pos,
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCommentInput(Offset pos) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write a note...'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                widget.onAnnotationAdded(Annotation.comment(
                  pageIndex: widget.pageIndex,
                  text: ctrl.text,
                  position: pos,
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ---- Painter ----
class _AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final List<DrawPoint> currentStroke;
  final Color drawColor;
  final double strokeWidth;
  final Offset? dragStart;

  _AnnotationPainter({
    required this.annotations,
    required this.currentStroke,
    required this.drawColor,
    required this.strokeWidth,
    this.dragStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed annotations
    for (final ann in annotations) {
      switch (ann.type) {
        case AnnotationType.highlight:
          if (ann.rect != null) {
            canvas.drawRect(
              ann.rect!,
              Paint()..color = ann.color,
            );
          }
          break;
        case AnnotationType.draw:
          _paintStrokes(canvas, ann.strokes, ann.color, ann.strokeWidth);
          break;
        default:
          break;
      }
    }

    // Draw in-progress stroke
    if (currentStroke.isNotEmpty) {
      _paintStrokes(canvas, currentStroke, drawColor, strokeWidth);
    }
  }

  void _paintStrokes(
      Canvas canvas, List<DrawPoint> points, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (points[i].isStart || i == 0) {
        path.moveTo(points[i].point.dx, points[i].point.dy);
      } else {
        path.lineTo(points[i].point.dx, points[i].point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}

// ---- Draggable text widget ----
class _TextAnnotationWidget extends StatefulWidget {
  final Annotation annotation;
  final void Function(Offset) onMoved;

  const _TextAnnotationWidget(
      {required this.annotation, required this.onMoved});

  @override
  State<_TextAnnotationWidget> createState() =>
      _TextAnnotationWidgetState();
}

class _TextAnnotationWidgetState extends State<_TextAnnotationWidget> {
  late Offset _pos;

  @override
  void initState() {
    super.initState();
    _pos = widget.annotation.position ?? Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() => _pos += d.delta);
          widget.onMoved(_pos);
        },
        child: Container(
          padding: widget.annotation.type == AnnotationType.comment
              ? const EdgeInsets.all(8)
              : EdgeInsets.zero,
          decoration: widget.annotation.type == AnnotationType.comment
              ? BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(blurRadius: 4, color: Colors.black26)
                  ],
                )
              : null,
          child: Text(
            widget.annotation.text ?? '',
            style: TextStyle(
              fontSize: widget.annotation.fontSize,
              color: widget.annotation.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
