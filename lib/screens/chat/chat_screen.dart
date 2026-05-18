import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/auth_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  UserModel? _studio;
  bool _loading = true;
  String? _myId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      final storage = AuthStorage();
      final token = await storage.getToken();
      final me = await storage.getUser();
      final chat = context.read<ChatService>();
      final studio = await chat.getStudioContact();

      if (token != null) {
        final socket = chat.connect(token);
        chat.joinRoom(studio.id);
        socket.on('receive_message', (data) {
          if (data is Map) {
            final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToEnd();
            }
          }
        });
      }

      final history = await chat.getHistory(receiverId: studio.id);
      if (mounted) {
        setState(() {
          _studio = studio;
          _myId = me?.id;
          _messages = history;
          _loading = false;
        });
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _studio == null) return;
    context.read<ChatService>().sendMessage(_studio!.id, text);
    _controller.clear();
  }

  @override
  void dispose() {
    context.read<ChatService>().disconnect();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_studio?.name ?? 'Messages')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isMe = m.senderId == _myId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.purple : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isMe ? null : Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            m.message,
                            style: TextStyle(color: isMe ? Colors.white : AppColors.text),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message ${_studio?.name ?? 'studio'}...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: AppColors.purple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
