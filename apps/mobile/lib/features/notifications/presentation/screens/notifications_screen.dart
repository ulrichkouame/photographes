/// Notifications list screen with unread indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';

/// Model for a notification item.
class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  factory _NotificationItem.fromJson(Map<String, dynamic> json) =>
      _NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );
}

final _notificationsProvider =
    FutureProvider.autoDispose<List<_NotificationItem>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('photographes_notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List)
      .map((e) => _NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Shows the list of in-app notifications with unread indicators.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text('Aucune notification',
                      style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.refresh(_notificationsProvider),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.gold.withOpacity(0.15),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.gold,
                        ),
                      ),
                      if (!n.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight:
                          n.isRead ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.body),
                      Text(
                        timeago.format(n.createdAt, locale: 'fr'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                  tileColor: n.isRead
                      ? null
                      : AppColors.gold.withOpacity(0.04),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
