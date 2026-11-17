import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/assessment/assessment_screens.dart';
import '../features/home/home_screen.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/library/library_screen.dart';
import '../features/listening/listening_screens.dart';
import '../features/path/path_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tutor/tutor_screen.dart';

GoRouter buildRouter({String initialLocation = '/home'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        _branch('/home', const HomeScreen()),
        _branch('/path', const PathScreen()),
        _branch('/practice', const PracticeScreen()),
        _branch('/library', const LibraryScreen()),
        _branch('/progress', const ProgressScreen()),
      ],
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (_, state) =>
          LessonScreen(lessonId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
    GoRoute(
      path: '/practice/:mode',
      builder: (_, state) =>
          PracticeRunScreen(mode: state.pathParameters['mode']!),
    ),
    GoRoute(
      path: '/listening',
      builder: (_, _) => const ListeningLibraryScreen(),
    ),
    GoRoute(
      path: '/listening/:id',
      builder: (_, state) =>
          DialogueScreen(dialogueId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/listening/:id/questions',
      builder: (_, state) =>
          DialogueQuestionsScreen(dialogueId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/assessment/:id',
      builder: (_, state) =>
          AssessmentScreen(assessmentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/assessment/:id/result/:attempt',
      builder: (_, state) => AssessmentResultScreen(
        assessmentId: state.pathParameters['id']!,
        attemptId: int.parse(state.pathParameters['attempt']!),
      ),
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/tutor', builder: (_, _) => const TutorScreen()),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route_rounded),
          label: 'المسار',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center_rounded),
          label: 'التدريب',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_library_outlined),
          selectedIcon: Icon(Icons.local_library_rounded),
          label: 'المكتبة',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'التقدّم',
        ),
      ],
    ),
  );
}
