import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<RecentFile> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final files = await StorageService.getRecentFiles();
    if (mounted) setState(() => _recentFiles = files);
  }

  Future<void> _openPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      await StorageService.addRecentFile(RecentFile(
        path: path,
        name: name,
        createdAt: DateTime.now(),
        pageCount: 0,
        fileSizeBytes: File(path).lengthSync(),
      ));
      if (mounted) context.push('/pdf-editor', extra: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            recentFiles: _recentFiles,
            onRefresh: _loadRecents,
            onOpenPdf: _openPdf,
          ),
          const _RecentTab(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Recents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---- Home Tab ----
class _HomeTab extends StatelessWidget {
  final List<RecentFile> recentFiles;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenPdf;

  const _HomeTab({
    required this.recentFiles,
    required this.onRefresh,
    required this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'PDF Studio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Convert, edit and share PDFs',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              // Main Action Cards
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_library,
                      iconColor: colors.primary,
                      bgColor: colors.primaryContainer,
                      title: 'Images → PDF',
                      subtitle: 'Convert multiple images to a single PDF',
                      onTap: () => context.push('/image-picker'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.edit_document,
                      iconColor: colors.secondary,
                      bgColor: colors.secondaryContainer,
                      title: 'Edit PDF',
                      subtitle: 'Annotate, highlight and draw on any PDF',
                      onTap: onOpenPdf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.merge_type,
                      iconColor: colors.tertiary,
                      bgColor: colors.tertiaryContainer,
                      title: 'Merge PDFs',
                      subtitle: 'Combine multiple PDFs into one',
                      onTap: () => context.push('/page-manager', extra: ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.call_split,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.shade100,
                      title: 'Split PDF',
                      subtitle: 'Extract pages from a PDF',
                      onTap: onOpenPdf,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // Recent Files
              if (recentFiles.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Files',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () =>
                          context.push('/recent-files'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...recentFiles.take(5).map((f) => _RecentFileItem(file: f)),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open,
                            size: 60,
                            color: colors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No recent files yet',
                            style: TextStyle(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFileItem extends StatelessWidget {
  final RecentFile file;

  const _RecentFileItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final exists = File(file.path).existsSync();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
      ),
      title: Text(
        file.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        DateFormat('MMM d').format(file.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      onTap: exists
          ? () => context.push('/pdf-editor', extra: file.path)
          : null,
    );
  }
}

// ---- Recent Tab ----
class _RecentTab extends StatelessWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Files')),
      body: const RecentFilesTabBody(),
    );
  }
}

class RecentFilesTabBody extends StatefulWidget {
  const RecentFilesTabBody({super.key});

  @override
  State<RecentFilesTabBody> createState() => _RecentFilesTabBodyState();
}

class _RecentFilesTabBodyState extends State<RecentFilesTabBody> {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_files.isEmpty) {
      return const Center(
          child: Text('No recent files yet. Create or open a PDF first.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final file = _files[i];
        final exists = File(file.path).existsSync();
        return ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text(file.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(DateFormat('MMM d, yyyy').format(file.createdAt)),
          onTap: exists
              ? () => context.push('/pdf-editor', extra: file.path)
              : null,
        );
      },
    );
  }
}

// ---- Settings Tab ----
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Recent Files'),
            onTap: () async {
              await StorageService.clearAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent files cleared')),
              );
            },
          ),
          const AboutListTile(
            icon: Icon(Icons.picture_as_pdf),
            applicationName: 'PDF Studio',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 PDF Studio',
          ),
        ],
      ),
    );
  }
}
