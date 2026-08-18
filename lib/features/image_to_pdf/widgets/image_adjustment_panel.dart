import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/image_to_pdf_cubit.dart';
import '../models/image_item.dart';

class ImageAdjustmentPanel extends StatefulWidget {
  final ImageItem item;

  const ImageAdjustmentPanel({super.key, required this.item});

  @override
  State<ImageAdjustmentPanel> createState() => _ImageAdjustmentPanelState();
}

class _ImageAdjustmentPanelState extends State<ImageAdjustmentPanel> {
  late double _brightness;
  late double _contrast;
  late PageSize _pageSize;
  late double _margin;

  @override
  void initState() {
    super.initState();
    _brightness = widget.item.brightness;
    _contrast = widget.item.contrast;
    _pageSize = widget.item.pageSize;
    _margin = widget.item.margin;
  }

  void _apply() {
    context.read<ImageToPdfCubit>().updateItem(
          widget.item.copyWith(
            brightness: _brightness,
            contrast: _contrast,
            pageSize: _pageSize,
            margin: _margin,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Adjust Image',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // Brightness
            _SliderRow(
              label: 'Brightness',
              value: _brightness,
              min: -1.0,
              max: 1.0,
              icon: Icons.brightness_6,
              onChanged: (v) => setState(() => _brightness = v),
            ),
            const SizedBox(height: 16),

            // Contrast
            _SliderRow(
              label: 'Contrast',
              value: _contrast,
              min: 0.5,
              max: 2.0,
              icon: Icons.contrast,
              onChanged: (v) => setState(() => _contrast = v),
            ),
            const SizedBox(height: 24),

            // Page Size
            Text('Page Size',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<PageSize>(
              segments: const [
                ButtonSegment(value: PageSize.a4, label: Text('A4')),
                ButtonSegment(value: PageSize.letter, label: Text('Letter')),
                ButtonSegment(value: PageSize.a3, label: Text('A3')),
              ],
              selected: {_pageSize},
              onSelectionChanged: (s) =>
                  setState(() => _pageSize = s.first),
            ),
            const SizedBox(height: 24),

            // Margin
            _SliderRow(
              label: 'Margin: ${_margin.toInt()}pt',
              value: _margin,
              min: 0,
              max: 72,
              icon: Icons.space_bar,
              onChanged: (v) => setState(() => _margin = v),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _apply,
              child: const Text('Apply'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
