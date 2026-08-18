import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import '../cubit/pdf_editor_cubit.dart';
import '../widgets/annotation_layer.dart';
import '../widgets/toolbar.dart';

class PdfEditorScreen extends StatefulWidget {
  final String? pdfPath;

  const PdfEditorScreen({super.key, this.pdfPath});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  PdfController? _pdfController;
  int _totalPages = 1;
  late PdfEditorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PdfEditorCubit()..loadPdf(widget.pdfPath, _totalPages);
    if (widget.pdfPath != null) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.pdfPath!),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PdfEditorCubit, PdfEditorState>(
        listener: (context, state) {
          if (state.savedPath != null && !state.isSaving) {
            _showSavedDialog(context, state.savedPath!);
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.pdfPath != null
                  ? widget.pdfPath!.split('/').last
                  : 'New PDF'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.merge_type),
                  onPressed: () => context.push('/page-manager',
                      extra: widget.pdfPath ?? ''),
                  tooltip: 'Merge / Split',
                ),
                if (state.savedPath != null)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Share.shareXFiles([XFile(state.savedPath!)]);
                    },
                    tooltip: 'Share',
                  ),
                if (state.isSaving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            body: widget.pdfPath == null
                ? const _EmptyPdfState()
                : Stack(
                    children: [
                      PdfView(
                        controller: _pdfController!,
                        onDocumentLoaded: (doc) {
                          setState(() => _totalPages = doc.pagesCount);
                          _cubit.loadPdf(widget.pdfPath, doc.pagesCount);
                        },
                        onPageChanged: _cubit.setPage,
                      ),
                      Positioned.fill(
                        child: AnnotationLayer(
                          annotations: state.currentPageAnnotations,
                          activeTool: state.activeTool,
                          drawColor: state.drawColor,
                          strokeWidth: state.strokeWidth,
                          pageIndex: state.currentPage,
                          onAnnotationAdded: _cubit.addAnnotation,
                          onAnnotationUpdated: _cubit.updateAnnotation,
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: EditorToolbar(
              activeTool: state.activeTool,
              drawColor: state.drawColor,
              strokeWidth: state.strokeWidth,
              onToolSelected: _cubit.setTool,
              onColorChanged: _cubit.setDrawColor,
              onStrokeWidthChanged: _cubit.setStrokeWidth,
              onUndo: _cubit.undo,
              onSave: _cubit.savePdf,
            ),
          );
        },
      ),
    );
  }

  void _showSavedDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF Saved'),
        content: const Text('Your annotated PDF has been saved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)], text: 'PDF from PDF Studio');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPdfState extends StatelessWidget {
  const _EmptyPdfState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf,
              size: 80, color: colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No PDF Loaded',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Open a PDF from Home or Recent Files.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
