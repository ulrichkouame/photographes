/// GoRouter configuration with all application routes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/register_client_screen.dart';
import '../../features/auth/presentation/screens/register_photographer_screen.dart';
import '../../features/feed/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/photographer_profile/presentation/screens/photographer_profile_screen.dart';
import '../../features/booking/presentation/screens/booking_form_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/my_requests/presentation/screens/my_requests_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/photographer_dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/photographer_portfolio/presentation/screens/portfolio_management_screen.dart';
import '../../features/photographer_services/presentation/screens/services_screen.dart';
import '../../features/photographer_missions/presentation/screens/missions_screen.dart';
import '../../features/photographer_calendar/presentation/screens/calendar_screen.dart';
import '../../features/photographer_subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Named route constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String pin = '/pin';
  static const String registerRole = '/register-role';
  static const String registerClient = '/register-client';
  static const String registerPhotographer = '/register-photographer';
  static const String home = '/home';
  static const String search = '/search';
  static const String photographerProfile = '/photographer/:id';
  static const String booking = '/booking/:photographerId';
  static const String bookingConfirmation = '/booking-confirmation/:bookingId';
  static const String payment = '/payment/:bookingId';
  static const String chat = '/chat/:roomId';
  static const String myRequests = '/my-requests';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String photographerDashboard = '/dashboard';
  static const String photographerPortfolio = '/photographer-portfolio';
  static const String photographerServices = '/photographer-services';
  static const String photographerMissions = '/photographer-missions';
  static const String photographerCalendar = '/photographer-calendar';
  static const String photographerSubscriptions = '/photographer-subscriptions';
}

/// Riverpod provider that exposes the configured [GoRouter].
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.pin,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'verify';
          return PinScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.registerRole,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerClient,
        builder: (context, state) => const RegisterClientScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPhotographer,
        builder: (context, state) => const RegisterPhotographerScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerProfile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PhotographerProfileScreen(photographerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) {
          final photographerId = state.pathParameters['photographerId']!;
          return BookingFormScreen(photographerId: photographerId);
        },
      ),
      GoRoute(
        path: AppRoutes.bookingConfirmation,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingConfirmationScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return PaymentScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            roomId: roomId,
            otherUserName: extra?['otherUserName'] ?? '',
            otherUserId: extra?['otherUserId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myRequests,
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerPortfolio,
        builder: (context, state) => const PortfolioManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerServices,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerMissions,
        builder: (context, state) => const MissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerCalendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.photographerSubscriptions,
        builder: (context, state) => const SubscriptionsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.error}'),
      ),
    ),
  );
});
