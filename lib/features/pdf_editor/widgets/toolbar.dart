import 'package:flutter/material.dart';
import '../cubit/pdf_editor_cubit.dart';

class EditorToolbar extends StatelessWidget {
  final EditorTool activeTool;
  final Color drawColor;
  final double strokeWidth;
  final void Function(EditorTool) onToolSelected;
  final void Function(Color) onColorChanged;
  final void Function(double) onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onSave;

  const EditorToolbar({
    super.key,
    required this.activeTool,
    required this.drawColor,
    required this.strokeWidth,
    required this.onToolSelected,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.pan_tool,
              label: 'Select',
              tool: EditorTool.select,
              activeTool: activeTool,
              onTap: onToolSelected,
            ),
            _ToolButton(
              icon: Icons.text_fields,
              label: 'Text',
              tool: EditorTool.text,
              activeTool: activeTool,
              onTap: onToolSelected,
            ),
            _ToolButton(
              icon: Icons.highlight,
              label: 'Highlight',
              tool: EditorTool.highlight,
              activeTool: activeTool,
              onTap: onToolSelected,
            ),
            _ToolButton(
              icon: Icons.brush,
              label: 'Draw',
              tool: EditorTool.draw,
              activeTool: activeTool,
              onTap: onToolSelected,
            ),
            _ToolButton(
              icon: Icons.comment,
              label: 'Note',
              tool: EditorTool.comment,
              activeTool: activeTool,
              onTap: onToolSelected,
            ),
            // Color picker
            GestureDetector(
              onTap: () => _showColorPicker(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: drawColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outline, width: 2),
                ),
              ),
            ),
            // Undo
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: onUndo,
              tooltip: 'Undo',
            ),
            // Save
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final palette = [
      Colors.black,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pen Color',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: palette.map((c) {
                return GestureDetector(
                  onTap: () {
                    onColorChanged(c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: c == drawColor
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Stroke Width',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: strokeWidth,
              min: 1,
              max: 12,
              divisions: 11,
              label: '${strokeWidth.toInt()}px',
              onChanged: onStrokeWidthChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditorTool tool;
  final EditorTool activeTool;
  final void Function(EditorTool) onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.tool,
    required this.activeTool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = tool == activeTool;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTap(tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
