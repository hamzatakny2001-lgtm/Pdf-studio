import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

class RecentFilesScreen extends StatefulWidget {
  const RecentFilesScreen({super.key});

  @override
  State<RecentFilesScreen> createState() => _RecentFilesScreenState();
}

class _RecentFilesScreenState extends State<RecentFilesScreen> {
  List<RecentFile> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await StorageService.getRecentFiles();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _delete(RecentFile file) async {
    await StorageService.removeRecentFile(file.path);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Files'),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () async {
                await StorageService.clearAll();
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No recent files'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final file = _files[i];
                      final exists = File(file.path).existsSync();
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: exists
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: exists ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: exists ? null : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy  HH:mm')
                              .format(file.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') _delete(file);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'delete', child: Text('Remove')),
                          ],
                        ),
                        onTap: exists
                            ? () =>
                                context.push('/pdf-editor', extra: file.path)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
