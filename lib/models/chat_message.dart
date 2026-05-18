class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId'];
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: sender is Map ? sender['_id']?.toString() ?? '' : sender?.toString() ?? '',
      senderName: sender is Map ? sender['name']?.toString() ?? 'User' : 'User',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
