import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/pdf_service.dart';
import '../../../services/storage_service.dart';

class PageManagerScreen extends StatefulWidget {
  final String pdfPath;

  const PageManagerScreen({super.key, required this.pdfPath});

  @override
  State<PageManagerScreen> createState() => _PageManagerScreenState();
}

class _PageManagerScreenState extends State<PageManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _mergeList = [];
  final Set<int> _selectedPages = {};
  int _totalPages = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.pdfPath.isNotEmpty) {
      _mergeList = [widget.pdfPath];
      _loadPageCount();
    }
  }

  Future<void> _loadPageCount() async {
    if (widget.pdfPath.isEmpty) return;
    final count = await PdfService.getPageCount(widget.pdfPath);
    if (mounted) setState(() => _totalPages = count);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge & Split'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.merge_type), text: 'Merge PDFs'),
            Tab(icon: Icon(Icons.call_split), text: 'Split Pages'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _MergeTab(
                  mergeList: _mergeList,
                  onAdd: _addPdfToMerge,
                  onRemove: (i) =>
                      setState(() => _mergeList.removeAt(i)),
                  onReorder: (old, newIdx) {
                    setState(() {
                      final item = _mergeList.removeAt(old);
                      _mergeList.insert(newIdx, item);
                    });
                  },
                  onMerge: _mergePdfs,
                ),
                _SplitTab(
                  totalPages: _totalPages,
                  selectedPages: _selectedPages,
                  onToggle: (page) {
                    setState(() {
                      if (_selectedPages.contains(page)) {
                        _selectedPages.remove(page);
                      } else {
                        _selectedPages.add(page);
                      }
                    });
                  },
                  onSplit: _splitPages,
                ),
              ],
            ),
    );
  }

  Future<void> _addPdfToMerge() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (final f in result.files) {
          if (f.path != null && !_mergeList.contains(f.path)) {
            _mergeList.add(f.path!);
          }
        }
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_mergeList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 PDFs to merge')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final outPath = await PdfService.mergePdfs(_mergeList);
      await StorageService.addRecentFile(RecentFile(
        path: outPath,
        name: 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
        createdAt: DateTime.now(),
        pageCount: 0,
        fileSizeBytes: File(outPath).lengthSync(),
      ));
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showResult(outPath, 'PDFs merged successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merge failed: $e')),
      );
    }
  }

  void _splitPages() {
    if (_selectedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select pages to extract')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Extracting pages ${_selectedPages.map((p) => p + 1).join(', ')}...'),
      ),
    );
  }

  void _showResult(String path, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)]);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

// ---- Merge Tab ----
class _MergeTab extends StatelessWidget {
  final List<String> mergeList;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;
  final VoidCallback onMerge;

  const _MergeTab({
    required this.mergeList,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: mergeList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.merge_type, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Add PDFs to merge'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add PDF'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mergeList.length,
                  onReorder: onReorder,
                  itemBuilder: (ctx, i) => ListTile(
                    key: ValueKey(mergeList[i]),
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(
                      mergeList[i].split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${i + 1} of ${mergeList.length}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => onRemove(i),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add PDF'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMerge,
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Merge All'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Split Tab ----
class _SplitTab extends StatelessWidget {
  final int totalPages;
  final Set<int> selectedPages;
  final void Function(int) onToggle;
  final VoidCallback onSplit;

  const _SplitTab({
    required this.totalPages,
    required this.selectedPages,
    required this.onToggle,
    required this.onSplit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select pages to extract into a new PDF',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: totalPages == 0
              ? const Center(child: Text('No PDF loaded'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: totalPages,
                  itemBuilder: (ctx, i) {
                    final isSelected = selectedPages.contains(i);
                    return GestureDetector(
                      onTap: () => onToggle(i),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? colors.primaryContainer
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.article,
                              size: 40,
                              color: isSelected
                                  ? colors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text('Page ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: onSplit,
            icon: const Icon(Icons.call_split),
            label: Text(selectedPages.isEmpty
                ? 'Select Pages'
                : 'Extract ${selectedPages.length} Page(s)'),
          ),
        ),
      ],
    );
  }
}
