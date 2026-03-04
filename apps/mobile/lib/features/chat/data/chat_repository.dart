/// Supabase real-time chat repository.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/message_model.dart';

/// Handles sending messages, streaming the message list, and marking as read.
class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  /// Sends a message in [roomId].
  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final senderId = _client.auth.currentUser?.id;
    if (senderId == null) throw Exception('Non authentifié');

    await _client.from('photographes_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns a real-time stream of messages for [roomId].
  Stream<List<Message>> streamMessages(String roomId) {
    return _client
        .from('photographes_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((list) => list.map(Message.fromJson).toList());
  }

  /// Marks all unread messages in [roomId] sent by others as read.
  Future<void> markAsRead(String roomId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('photographes_messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  /// Ensures a chat room exists for [bookingId]; returns its id.
  Future<String> getOrCreateRoom(String bookingId) async {
    final existing = await _client
        .from('photographes_chat_rooms')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('photographes_chat_rooms')
        .insert({
          'booking_id': bookingId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return created['id'] as String;
  }
}
