import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/image_to_pdf/screens/image_picker_screen.dart';
import '../../features/image_to_pdf/screens/image_arrange_screen.dart';
import '../../features/pdf_editor/screens/pdf_editor_screen.dart';
import '../../features/pdf_editor/screens/page_manager_screen.dart';
import '../../features/recent_files/screens/recent_files_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/image-picker',
        builder: (context, state) => const ImagePickerScreen(),
      ),
      GoRoute(
        path: '/image-arrange',
        builder: (context, state) {
          final imagePaths = state.extra as List<String>? ?? [];
          return ImageArrangeScreen(imagePaths: imagePaths);
        },
      ),
      GoRoute(
        path: '/pdf-editor',
        builder: (context, state) {
          final pdfPath = state.extra as String?;
          return PdfEditorScreen(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/page-manager',
        builder: (context, state) {
          final pdfPath = state.extra as String? ?? '';
          return PageManagerScreen(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/recent-files',
        builder: (context, state) => const RecentFilesScreen(),
      ),
    ],
  );
}
