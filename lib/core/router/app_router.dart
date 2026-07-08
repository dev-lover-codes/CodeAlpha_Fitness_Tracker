import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/views/splash_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/auth/views/forgot_password_view.dart';
import '../../features/auth/views/onboarding_view.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/workouts/views/workout_home_screen.dart';
import '../../features/workouts/views/active_workout_screen.dart';
import '../../features/workouts/views/workout_summary_screen.dart';
import '../../features/workouts/views/workout_detail_screen.dart';
import '../providers/workouts_provider.dart';
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

/// Provider exposing the reactive GoRouter configuration.
/// Watches authStateProvider and userProfileProvider to automatically compute redirections.
final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);
  final authService = ref.read(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = authService.currentUser;
      final isLoggedIn = user != null;
      
      final subState = state.uri.path;
      final isAuthRoute = subState == '/login' ||
                          subState == '/signup' ||
                          subState == '/forgot-password';
      
      final isSplash = subState == '/splash';

      // 1. If NOT logged in, redirect to login unless already on an auth route or splash
      if (!isLoggedIn) {
        if (!isAuthRoute && !isSplash) {
          return '/login';
        }
        return null;
      }

      // 2. If logged in, wait for profile loading
      if (profileAsync.isLoading) {
        // If we are already on splash or onboarding, stay there while loading
        if (isSplash || subState == '/onboarding') {
          return null;
        }
        return '/splash'; 
      }

      final profile = profileAsync.value;
      
      // Profile completion check (we use height_cm as the marker field)
      final hasCompletedProfile = profile != null && profile['height_cm'] != null;

      // If user is on splash or an auth screen but they are logged in:
      if (isSplash || isAuthRoute) {
        if (hasCompletedProfile) {
          return '/home';
        } else {
          return '/onboarding';
        }
      }

      // If the profile is not completed, force them to onboarding
      if (!hasCompletedProfile) {
        if (subState != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      // If profile is completed, prevent entering onboarding
      if (hasCompletedProfile && subState == '/onboarding') {
        return '/home';
      }

      return null; // Maintain current navigation destination
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),

      // Stateful Shell Route for persistent Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dashboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),
          // 2. Workouts Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutHomeScreen(),
              ),
            ],
          ),
          // 3. Progress Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressView(),
              ),
            ],
          ),
          // 4. Nutrition Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (context, state) => const NutritionView(),
              ),
            ],
          ),
          // 5. Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // Other Flat Sub-routes (hiding Bottom Navigation Bar)
      GoRoute(
        path: '/workouts/active',
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/workouts/summary',
        builder: (context, state) {
          final summary = state.extra as WorkoutSummary?;
          return WorkoutSummaryScreen(summary: summary);
        },
      ),
      GoRoute(
        path: '/workouts/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: '/exercises/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ExerciseDetailScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/exercises/new',
        builder: (context, state) => const CreateCustomExerciseScreen(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/goals/new',
        builder: (context, state) => const CreateGoalScreen(),
      ),
    ],
  );
});

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
