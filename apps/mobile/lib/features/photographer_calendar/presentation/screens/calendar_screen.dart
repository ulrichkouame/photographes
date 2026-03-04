/// Calendar screen for photographer availability management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';

final _availabilityProvider =
    FutureProvider.autoDispose<Set<DateTime>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  final data = await Supabase.instance.client
      .from('photographes_availability')
      .select('date')
      .eq('photographer_id', userId)
      .eq('is_available', true);
  return (data as List)
      .map((e) => DateTime.parse(e['date'] as String))
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();
});

/// Calendar for toggling available/unavailable dates.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  Set<DateTime> _available = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  bool _isAvailable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _available.contains(d);
  }

  Future<void> _toggleDay(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (_available.contains(d)) {
      await Supabase.instance.client
          .from('photographes_availability')
          .delete()
          .eq('photographer_id', userId)
          .eq('date', DateFormat('yyyy-MM-dd').format(d));
      setState(() => _available.remove(d));
    } else {
      await Supabase.instance.client.from('photographes_availability').upsert({
        'photographer_id': userId,
        'date': DateFormat('yyyy-MM-dd').format(d),
        'is_available': true,
      });
      setState(() => _available.add(d));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availAsync = ref.watch(_availabilityProvider);

    if (availAsync is AsyncData) {
      _available = availAsync.value!;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon agenda')),
      body: availAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Disponible', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Non disponible',
                      style: TextStyle(fontSize: 13, color: AppColors.grey)),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) =>
                  _selectedDay != null && isSameDay(d, _selectedDay!),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _toggleDay(selected);
              },
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.goldDark,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final available = _isAvailable(day);
                  if (available) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Appuyez sur une date pour la marquer comme disponible ou non.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
