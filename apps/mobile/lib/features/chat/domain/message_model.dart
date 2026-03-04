/// Domain model for a chat message.
library;

/// Represents a single message in a chat room.
class Message {
  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  /// Parses a [Message] from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        roomId: json['room_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };
}
