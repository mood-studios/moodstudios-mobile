import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';

class ChatService {
  ChatService(this._client);

  final ApiClient _client;
  io.Socket? _socket;

  Future<UserModel> getStudioContact() async {
    final res = await _client.dio.get('/chat/studio');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getHistory({
    required String receiverId,
    String? bookingId,
  }) async {
    final res = await _client.dio.get('/chat/history', queryParameters: {
      'receiverId': receiverId,
      if (bookingId != null) 'bookingId': bookingId,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final messages = data['messages'] as List;
    return messages.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  io.Socket connect(String token) {
    _socket?.dispose();
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
