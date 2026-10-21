import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/workouts_provider.dart';
import '../ui/ui.dart';
import '../../features/auth/views/splash_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/auth/views/forgot_password_view.dart';
import '../../features/auth/views/reset_password_view.dart';
import '../../features/auth/views/onboarding_view.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/workouts/views/workout_home_screen.dart';
import '../../features/workouts/views/active_workout_screen.dart';
import '../../features/workouts/views/workout_summary_screen.dart';
import '../../features/workouts/views/workout_detail_screen.dart';
import '../../features/progress/views/progress_view.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/profile/views/edit_profile_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/nutrition/views/nutrition_view.dart';
import '../../features/exercises/views/exercise_library_screen.dart';
import '../../features/exercises/views/exercise_detail_screen.dart';
import '../../features/exercises/views/create_custom_exercise_screen.dart';
import '../../features/goals/views/goals_screen.dart';
import '../../features/goals/views/create_goal_screen.dart';
import '../../features/plan/views/plan_screen.dart';
import '../../main.dart';

/// Reactive GoRouter. Rebuilds redirects when auth, profile or recovery state changes.
final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);
  final inRecovery = ref.watch(passwordRecoveryProvider);
  final authService = ref.read(authServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = authService.currentUser != null;
      final isAuthRoute = path == '/login' || path == '/signup' || path == '/forgot-password';
      final isSplash = path == '/splash';

      if (!isSupabaseInitialized) return isSplash ? null : '/splash';

      // Opened a password-reset link: go straight to "choose a new password".
      if (inRecovery && isLoggedIn) return path == '/reset-password' ? null : '/reset-password';
      if (path == '/reset-password' && !inRecovery) return isLoggedIn ? '/home' : '/login';

      if (!isLoggedIn) return isAuthRoute ? null : '/login';

      if (profileAsync.isLoading) {
        return (isSplash || path == '/onboarding') ? null : '/splash';
      }

      final profile = profileAsync.value;
      final hasCompletedProfile = profile != null && profile['height_cm'] != null;

      if (isSplash || isAuthRoute) return hasCompletedProfile ? '/home' : '/onboarding';
      if (!hasCompletedProfile) return path == '/onboarding' ? null : '/onboarding';
      if (path == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupView()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordView()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordView()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingView()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const DashboardView()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/workouts', builder: (context, state) => const WorkoutHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', builder: (context, state) => const ProgressView()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/nutrition', builder: (context, state) => const NutritionView()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileView()),
          ]),
        ],
      ),

      // Pages pushed on top of the tabs (they get a back button).
      GoRoute(path: '/workouts/active', builder: (context, state) => const ActiveWorkoutScreen()),
      GoRoute(
        path: '/workouts/summary',
        builder: (context, state) => WorkoutSummaryScreen(summary: state.extra as WorkoutSummary?),
      ),
      GoRoute(
        path: '/workouts/detail/:id',
        builder: (context, state) => WorkoutDetailScreen(workoutId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/exercises', builder: (context, state) => const ExerciseLibraryScreen()),
      GoRoute(
        path: '/exercises/detail/:id',
        builder: (context, state) => ExerciseDetailScreen(exerciseId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: '/exercises/new', builder: (context, state) => const CreateCustomExerciseScreen()),
      GoRoute(path: '/plan', builder: (context, state) => const PlanScreen()),
      GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
      GoRoute(path: '/goals/new', builder: (context, state) => const CreateGoalScreen()),
    ],
  );
});

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider);
    final p = context.palette;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A workout in progress stays one tap away from every tab.
          if (active != null)
            Material(
              color: p.ink,
              child: InkWell(
                onTap: () => context.push('/workouts/active'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${active.name} in progress',
                          style: context.text.labelLarge!.copyWith(color: p.inkInverse),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('Resume', style: context.text.labelMedium!.copyWith(color: p.inkInverse)),
                      Icon(Icons.chevron_right, color: p.inkInverse, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center),
                  label: 'Train',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: 'Food',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'You',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
