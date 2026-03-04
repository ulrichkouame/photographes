/// Photographer dashboard screen: bottom nav + KPI cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/dashboard_repository.dart';
import '../../../photographer_portfolio/presentation/screens/portfolio_management_screen.dart';
import '../../../photographer_missions/presentation/screens/missions_screen.dart';
import '../../../photographer_calendar/presentation/screens/calendar_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

final _dashboardRepoProvider = Provider<DashboardRepository>(
    (ref) => DashboardRepository(Supabase.instance.client));

final _dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.read(_dashboardRepoProvider).getStats();
});

/// Photographer app shell with 5-tab bottom navigation.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTab = 0;

  final List<Widget> _tabs = const [
    _DashboardTab(),
    MissionsScreen(),
    PortfolioManagementScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: statsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (stats) => RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async => ref.refresh(_dashboardStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voici un résumé de votre activité',
                  style: const TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _KpiCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Missions terminées',
                      value: stats.totalMissions.toString(),
                      color: AppColors.success,
                    ),
                    _KpiCard(
                      icon: Icons.attach_money_rounded,
                      label: 'Revenus',
                      value:
                          '${stats.revenue.toStringAsFixed(0)} F',
                      color: AppColors.gold,
                    ),
                    _KpiCard(
                      icon: Icons.star_rounded,
                      label: 'Note moyenne',
                      value: stats.averageRating.toStringAsFixed(1),
                      color: AppColors.gold,
                    ),
                    _KpiCard(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Demandes en attente',
                      value: stats.pendingBookings.toString(),
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _KpiCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Missions actives',
                  value: stats.activeBookings.toString(),
                  color: AppColors.success,
                  wide: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey)),
                ],
              ),
      ),
    );
  }
}
