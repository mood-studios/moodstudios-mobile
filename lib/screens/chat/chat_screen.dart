import 'dart:async';

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
  final List<ChatMessage> _messages = [];
  UserModel? _studio;
  bool _loading = true;
  String? _myId;
  String _status = 'Loading…';
  Timer? _pollTimer;
  ChatService? _chat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat ??= context.read<ChatService>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final chat = _chat!;
    chat.onMessage = _onIncomingMessage;
    chat.onStatus = _onStatus;
    chat.onError = _onSocketError;

    try {
      final storage = AuthStorage();
      final token = await storage.getToken();
      final me = await storage.getUser();
      final studio = await chat.getStudioContact();

      if (token != null) {
        chat.connect(token);
        chat.joinRoom(studio.id);
      }

      final result = await chat.getHistory(receiverId: studio.id);

      if (mounted) {
        setState(() {
          _studio = studio;
          _myId = me?.id;
          _messages
            ..clear()
            ..addAll(result.messages);
          _loading = false;
          _status = chat.isConnected ? 'Online' : 'Connecting…';
        });
        _scrollToEnd();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = 'Offline';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _loadHistory({required bool quiet}) async {
    if (_studio == null) return;
    final chat = _chat!;
    final result = await chat.getHistory(receiverId: _studio!.id);

    if (!mounted) return;

    if (!quiet) {
      setState(() => _messages
        ..clear()
        ..addAll(result.messages));
    } else {
      final existing = _messages.map((m) => m.id).toSet();
      final merged = [..._messages];
      for (final m in result.messages) {
        if (m.id.isNotEmpty && !existing.contains(m.id)) {
          merged.add(m);
          existing.add(m.id);
        }
      }
      merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() {
        _messages
          ..clear()
          ..addAll(merged);
      });
    }
    _scrollToEnd();
  }

  void _onIncomingMessage(ChatMessage msg) {
    if (!mounted) return;
    if (_messages.any((m) => m.id == msg.id && m.id.isNotEmpty)) return;
    setState(() {
      _messages.removeWhere((m) => m.isTemporary && m.message == msg.message && m.senderId == msg.senderId);
      _messages.add(msg);
    });
    _scrollToEnd();
  }

  void _onStatus(String status) {
    if (!mounted) return;
    setState(() => _status = status == 'Connected' ? 'Online' : status);
    if (status == 'Connected' && _studio != null) {
      _chat?.joinRoom(_studio!.id);
    }
  }

  void _onSocketError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_studio != null) _loadHistory(quiet: true);
    });
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
    if (text.isEmpty || _studio == null || _myId == null) return;

    final chat = _chat!;
    final optimistic = ChatMessage.optimistic(
      senderId: _myId!,
      senderName: 'You',
      message: text,
      roomId: chat.roomId ?? '',
    );

    setState(() => _messages.add(optimistic));
    _controller.clear();
    _scrollToEnd();

    if (chat.isConnected) {
      chat.sendMessage(_studio!.id, text);
    } else {
      _loadHistory(quiet: true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chat?.disconnect();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_studio?.name ?? 'Messages', style: const TextStyle(fontSize: 17)),
            Text(_status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Say hello — we typically reply during business hours.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
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
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.purple : AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isMe ? null : Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.message,
                                    style: TextStyle(color: isMe ? Colors.white : AppColors.text),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(m.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : AppColors.muted,
                                    ),
                                  ),
                                ],
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
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

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
