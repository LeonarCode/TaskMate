import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/message_bubble.dart';

class ServerChatView extends StatefulWidget {
  final String serverId;
  const ServerChatView({super.key, required this.serverId});

  @override
  State<ServerChatView> createState() => _ServerChatViewState();
}

class _ServerChatViewState extends State<ServerChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _firestoreSvc = FirestoreService();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final user = context.read<AuthProvider>().userModel!;
    final message = MessageModel(
      id: '',
      senderId: user.uid,
      senderName: user.fullName,
      senderPhotoUrl: user.photoUrl,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestoreSvc.sendServerMessage(widget.serverId, message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _firestoreSvc.serverMessagesStream(widget.serverId),
            builder: (ctx, snap) {
              final messages = snap.data ?? [];
              _scrollToBottom();
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Be the first to say hello!',
                    style: TextStyle(
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) => MessageBubble(
                  message: messages[i],
                  isMe: messages[i].senderId == uid,
                ),
              );
            },
          ),
        ),
        _buildInput(isDark),
      ],
    );
  }

  Widget _buildInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.dark600 : AppColors.gray200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: null,
              onSubmitted: (_) => _send(),
              style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
              decoration: InputDecoration(
                hintText: 'Message server...',
                fillColor: isDark ? AppColors.dark700 : AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
