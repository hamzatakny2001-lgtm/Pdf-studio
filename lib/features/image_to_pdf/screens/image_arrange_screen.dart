import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/storage_service.dart';
import '../cubit/image_to_pdf_cubit.dart';
import '../models/image_item.dart';
import '../widgets/image_adjustment_panel.dart';

class ImageArrangeScreen extends StatelessWidget {
  final List<String> imagePaths;

  const ImageArrangeScreen({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ImageToPdfCubit();
        final items = imagePaths.map(ImageItem.fromPath).toList();
        cubit.loadImages(items);
        return cubit;
      },
      child: const _ArrangeBody(),
    );
  }
}

class _ArrangeBody extends StatelessWidget {
  const _ArrangeBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageToPdfCubit, ImageToPdfState>(
      listener: (context, state) async {
        if (state.status == ConversionStatus.done &&
            state.outputPath != null) {
          await StorageService.addRecentFile(RecentFile(
            path: state.outputPath!,
            name: state.outputPath!.split('/').last,
            createdAt: DateTime.now(),
            pageCount: state.images.length,
            fileSizeBytes: File(state.outputPath!).lengthSync(),
          ));
          if (!context.mounted) return;
          await _showExportDialog(context, state.outputPath!);
        } else if (state.status == ConversionStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${state.errorMessage}'),
                backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ImageToPdfCubit>();
        final isConverting = state.status == ConversionStatus.converting;

        return Scaffold(
          appBar: AppBar(
            title: Text('Arrange Images (${state.images.length})'),
            actions: [
              IconButton(
                onPressed: cubit.pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                tooltip: 'Add More',
              ),
            ],
          ),
          body: state.images.isEmpty
              ? const Center(child: Text('No images. Tap + to add.'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: state.images.length,
                  onReorder: cubit.reorderImages,
                  itemBuilder: (context, index) {
                    final item = state.images[index];
                    return _ImageCard(
                      key: ValueKey(item.id),
                      item: item,
                      index: index,
                      onRemove: () => cubit.removeImage(item.id),
                      onEdit: () => _showAdjustPanel(context, item),
                      onRotate: () => cubit.rotateImage(item.id, 90),
                    );
                  },
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: isConverting ? null : cubit.convertToPdf,
                icon: isConverting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(isConverting ? 'Converting…' : 'Convert to PDF'),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdjustPanel(BuildContext context, ImageItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ImageToPdfCubit>(),
        child: ImageAdjustmentPanel(item: item),
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context, String path) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF Created!'),
        content: const Text(
            'Your PDF has been created. Would you like to share it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)], text: 'PDF created with PDF Studio');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final ImageItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onRotate;

  const _ImageCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onEdit,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.drag_handle, size: 18, color: Colors.grey),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(item.path),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.path.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Page size: ${item.pageSize.name.toUpperCase()}  •  Margin: ${item.margin.toInt()}pt',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rotate') onRotate();
              if (value == 'edit') onEdit();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rotate', child: Text('Rotate 90°')),
              PopupMenuItem(value: 'edit', child: Text('Adjust')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}
