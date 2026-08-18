import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/image_to_pdf_cubit.dart';

class ImagePickerScreen extends StatelessWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImageToPdfCubit(),
      child: const _ImagePickerBody(),
    );
  }
}

class _ImagePickerBody extends StatelessWidget {
  const _ImagePickerBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImageToPdfCubit>();
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<ImageToPdfCubit, ImageToPdfState>(
      listener: (context, state) {
        if (state.images.isNotEmpty && state.status == ConversionStatus.idle) {
          // Auto-navigate to arrange screen once images selected
          if (state.images.isNotEmpty &&
              ModalRoute.of(context)?.isCurrent == true) {
            // Handled by button press
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Images'),
            actions: [
              if (state.images.isNotEmpty)
                TextButton(
                  onPressed: () {
                    context.push('/image-arrange',
                        extra: state.images.map((i) => i.path).toList());
                  },
                  child: Text(
                    'Next (${state.images.length})',
                    style: TextStyle(color: colors.primary),
                  ),
                ),
            ],
          ),
          body: state.images.isEmpty
              ? _EmptyState(
                  onGallery: cubit.pickImages,
                  onCamera: cubit.pickFromCamera,
                )
              : _ImageGrid(
                  images: state.images.map((i) => i.path).toList(),
                  onAdd: cubit.pickImages,
                  onRemove: (idx) => cubit.removeImage(state.images[idx].id),
                ),
          floatingActionButton: state.images.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    context.push('/image-arrange',
                        extra: state.images.map((i) => i.path).toList());
                  },
                  label: const Text('Arrange & Convert'),
                  icon: const Icon(Icons.picture_as_pdf),
                )
              : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _EmptyState({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80, color: colors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text('Select Images',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Choose images from your gallery or take a photo to convert them to a PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a Photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImageGrid(
      {required this.images, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length + 1,
      itemBuilder: (context, index) {
        if (index == images.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        );
      },
    );
  }
}
