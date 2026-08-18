import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/annotation.dart';

// ------- Tool -------
enum EditorTool { select, text, highlight, draw, eraser, comment }

// ------- State -------
class PdfEditorState extends Equatable {
  final String? pdfPath;
  final int currentPage;
  final int totalPages;
  final EditorTool activeTool;
  final List<Annotation> annotations;
  final List<List<Annotation>> undoStack;
  final Color drawColor;
  final double strokeWidth;
  final bool isSaving;
  final String? savedPath;
  final String? errorMessage;

  const PdfEditorState({
    this.pdfPath,
    this.currentPage = 0,
    this.totalPages = 1,
    this.activeTool = EditorTool.select,
    this.annotations = const [],
    this.undoStack = const [],
    this.drawColor = Colors.blue,
    this.strokeWidth = 3.0,
    this.isSaving = false,
    this.savedPath,
    this.errorMessage,
  });

  List<Annotation> get currentPageAnnotations =>
      annotations.where((a) => a.pageIndex == currentPage).toList();

  PdfEditorState copyWith({
    String? pdfPath,
    int? currentPage,
    int? totalPages,
    EditorTool? activeTool,
    List<Annotation>? annotations,
    List<List<Annotation>>? undoStack,
    Color? drawColor,
    double? strokeWidth,
    bool? isSaving,
    String? savedPath,
    String? errorMessage,
  }) =>
      PdfEditorState(
        pdfPath: pdfPath ?? this.pdfPath,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        activeTool: activeTool ?? this.activeTool,
        annotations: annotations ?? this.annotations,
        undoStack: undoStack ?? this.undoStack,
        drawColor: drawColor ?? this.drawColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        isSaving: isSaving ?? this.isSaving,
        savedPath: savedPath ?? this.savedPath,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        pdfPath,
        currentPage,
        totalPages,
        activeTool,
        annotations,
        undoStack,
        drawColor,
        strokeWidth,
        isSaving,
        savedPath,
        errorMessage,
      ];
}

// ------- Cubit -------
class PdfEditorCubit extends Cubit<PdfEditorState> {
  PdfEditorCubit() : super(const PdfEditorState());

  void loadPdf(String? path, int totalPages) {
    emit(state.copyWith(
      pdfPath: path,
      totalPages: totalPages,
      currentPage: 0,
    ));
  }

  void setPage(int page) => emit(state.copyWith(currentPage: page));

  void setTool(EditorTool tool) => emit(state.copyWith(activeTool: tool));

  void setDrawColor(Color color) => emit(state.copyWith(drawColor: color));

  void setStrokeWidth(double width) =>
      emit(state.copyWith(strokeWidth: width));

  void addAnnotation(Annotation annotation) {
    final snapshot = List<Annotation>.from(state.annotations);
    emit(state.copyWith(
      annotations: [...state.annotations, annotation],
      undoStack: [...state.undoStack, snapshot],
    ));
  }

  void updateAnnotation(Annotation updated) {
    final list = state.annotations
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    emit(state.copyWith(annotations: list));
  }

  void removeAnnotation(String id) {
    final snapshot = List<Annotation>.from(state.annotations);
    emit(state.copyWith(
      annotations: state.annotations.where((a) => a.id != id).toList(),
      undoStack: [...state.undoStack, snapshot],
    ));
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final stack = List<List<Annotation>>.from(state.undoStack);
    final prev = stack.removeLast();
    emit(state.copyWith(annotations: prev, undoStack: stack));
  }

  Future<void> savePdf() async {
    emit(state.copyWith(isSaving: true));
    try {
      final doc = pw.Document();
      // Create one page per totalPages, baking annotations in
      for (var i = 0; i < state.totalPages; i++) {
        final pageAnnotations =
            state.annotations.where((a) => a.pageIndex == i).toList();
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            return pw.Stack(
              children: [
                pw.SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: pw.Container(color: PdfColors.white),
                ),
                for (final ann in pageAnnotations)
                  _buildPdfAnnotation(ann, ctx),
              ],
            );
          },
        ));
      }
      final dir = await getApplicationDocumentsDirectory();
      final outPath =
          '${dir.path}/edited_${const Uuid().v4()}.pdf';
      await File(outPath).writeAsBytes(await doc.save());
      emit(state.copyWith(isSaving: false, savedPath: outPath));
    } catch (e) {
      emit(state.copyWith(
          isSaving: false, errorMessage: 'Save failed: $e'));
    }
  }

  pw.Widget _buildPdfAnnotation(
      Annotation ann, pw.Context ctx) {
    switch (ann.type) {
      case AnnotationType.text:
        return pw.Positioned(
          left: ann.position?.dx ?? 0,
          top: ann.position?.dy ?? 0,
          child: pw.Text(
            ann.text ?? '',
            style: pw.TextStyle(
              fontSize: ann.fontSize,
              color: PdfColor(
                ann.textColor.r,
                ann.textColor.g,
                ann.textColor.b,
                ann.textColor.a,
              ),
            ),
          ),
        );
      case AnnotationType.highlight:
        final r = ann.rect ?? Rect.zero;
        return pw.Positioned(
          left: r.left,
          top: r.top,
          child: pw.Container(
            width: r.width,
            height: r.height,
            color: PdfColor(
              ann.color.r,
              ann.color.g,
              ann.color.b,
              ann.color.a,
            ),
          ),
        );
      case AnnotationType.comment:
        return pw.Positioned(
          left: ann.position?.dx ?? 0,
          top: ann.position?.dy ?? 0,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.yellow100,
            child: pw.Text(ann.text ?? ''),
          ),
        );
      default:
        return pw.SizedBox();
    }
  }
}
