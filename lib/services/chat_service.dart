import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';

typedef ChatMessageHandler = void Function(ChatMessage message);
typedef ChatStatusHandler = void Function(String status);
typedef ChatErrorHandler = void Function(String message);

class ChatHistoryResult {
  const ChatHistoryResult({required this.roomId, required this.messages});

  final String? roomId;
  final List<ChatMessage> messages;
}

class ChatService {
  ChatService(this._client);

  final ApiClient _client;
  io.Socket? _socket;
  String? _roomId;
  ChatMessageHandler? onMessage;
  ChatStatusHandler? onStatus;
  ChatErrorHandler? onError;

  String? get roomId => _roomId;

  Future<UserModel> getStudioContact() async {
    final res = await _client.dio.get('/chat/studio');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ChatHistoryResult> getHistory({
    required String receiverId,
    String? bookingId,
  }) async {
    final res = await _client.dio.get('/chat/history', queryParameters: {
      'receiverId': receiverId,
      if (bookingId != null) 'bookingId': bookingId,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final messages = (data['messages'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    _roomId = data['roomId']?.toString();
    return ChatHistoryResult(roomId: _roomId, messages: messages);
  }

  io.Socket connect(String token) {
    _socket?.dispose();
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      onStatus?.call('Connected');
    });
    _socket!.onDisconnect((_) {
      onStatus?.call('Reconnecting…');
    });
    _socket!.onConnectError((_) {
      onStatus?.call('Connection issue');
    });
    _socket!.on('receive_message', (data) {
      if (data is! Map) return;
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      if (_roomId != null && msg.roomId.isNotEmpty && msg.roomId != _roomId) return;
      onMessage?.call(msg);
    });
    _socket!.on('error', (data) {
      String message = 'Could not send message';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
      onError?.call(message);
    });

    _socket!.connect();
    return _socket!;
  }

  void joinRoom(String receiverId, {String? bookingId}) {
    _socket?.emit('join_room', {
      'receiverId': receiverId,
      if (bookingId != null) 'bookingId': bookingId,
    });
  }

  void sendMessage(String receiverId, String message, {String? bookingId}) {
    _socket?.emit('send_message', {
      'receiverId': receiverId,
      'message': message,
      if (bookingId != null) 'bookingId': bookingId,
    });
  }

  bool get isConnected => _socket?.connected == true;

  void disconnect() {
    onMessage = null;
    onStatus = null;
    onError = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _roomId = null;
  }
}
