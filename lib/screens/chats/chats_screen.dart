import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/message_bubble.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _firestoreSvc = FirestoreService();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: const Text('Direct Messages'),
        backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showSearchUser(context, uid),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.purple600,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DMModel>>(
              stream: _firestoreSvc.userDMsStream(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.purple600,
                      ),
                    ),
                  );
                }
                final dms = snap.data ?? [];
                if (dms.isEmpty) {
                  return _buildEmpty(isDark);
                }
                return ListView.builder(
                  itemCount: dms.length,
                  itemBuilder:
                      (_, i) => _DMTile(
                        dm: dms[i],
                        currentUid: uid,
                        firestoreSvc: _firestoreSvc,
                        isDark: isDark,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.purple600.withAlpha(15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.chat_rounded,
              size: 40,
              color: AppColors.purple600.withAlpha(150),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No direct messages yet.\nTap the icon to start chatting!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.gray400 : AppColors.gray500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchUser(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _UserSearchSheet(currentUid: uid, firestoreSvc: _firestoreSvc),
    );
  }
}

// ── DM Tile ────────────────────────────────────────────────────────────────────
class _DMTile extends StatelessWidget {
  final DMModel dm;
  final String currentUid;
  final FirestoreService firestoreSvc;
  final bool isDark;

  const _DMTile({
    required this.dm,
    required this.currentUid,
    required this.firestoreSvc,
    required this.isDark,
  });

  String get otherUid {
    return dm.participants.firstWhere(
      (p) => p != currentUid,
      orElse: () => dm.participants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = dm.unreadCount[currentUid] ?? 0;

    return FutureBuilder<UserModel?>(
      future: firestoreSvc.getUserById(otherUid),
      builder: (ctx, snap) {
        final other = snap.data;
        if (other == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            firestoreSvc.markDMRead(dm.id, currentUid);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChatDetailScreen(
                      dmId: dm.id,
                      currentUid: currentUid,
                      otherUser: other,
                      firestoreSvc: firestoreSvc,
                    ),
              ),
            );
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.purple600.withAlpha(25),
                      backgroundImage:
                          other.photoUrl != null
                              ? NetworkImage(other.photoUrl!)
                              : null,
                      child:
                          other.photoUrl == null
                              ? Text(
                                other.fullName.characters.first.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.purple600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              )
                              : null,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.red500,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        other.fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      if (dm.lastMessage != null)
                        Text(
                          dm.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isDark ? AppColors.gray400 : AppColors.gray500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (dm.lastMessageTime != null)
                  Text(
                    _timeLabel(dm.lastMessageTime!),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.gray500 : AppColors.gray400,
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}';
  }
}

// ── User Search Sheet ──────────────────────────────────────────────────────────
class _UserSearchSheet extends StatefulWidget {
  final String currentUid;
  final FirestoreService firestoreSvc;

  const _UserSearchSheet({
    required this.currentUid,
    required this.firestoreSvc,
  });

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await widget.firestoreSvc.searchUsers(q.trim());
    setState(() {
      _results = results.where((u) => u.uid != widget.currentUid).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark500 : AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          TextField(
            controller: _ctrl,
            onChanged: _search,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.purple600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple600),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final user = _results[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.purple600.withAlpha(25),
                      backgroundImage:
                          user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                      child:
                          user.photoUrl == null
                              ? Text(
                                user.fullName.characters.first.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.purple600,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                              : null,
                    ),
                    title: Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.gray900,
                      ),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chat_rounded,
                      color: AppColors.purple600,
                    ),
                    onTap: () async {
                      final dmId = await widget.firestoreSvc.getOrCreateDM(
                        widget.currentUid,
                        user.uid,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChatDetailScreen(
                                  dmId: dmId,
                                  currentUid: widget.currentUid,
                                  otherUser: user,
                                  firestoreSvc: widget.firestoreSvc,
                                ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Chat Detail Screen ─────────────────────────────────────────────────────────
class ChatDetailScreen extends StatefulWidget {
  final String dmId;
  final String currentUid;
  final UserModel otherUser;
  final FirestoreService firestoreSvc;

  const ChatDetailScreen({
    super.key,
    required this.dmId,
    required this.currentUid,
    required this.otherUser,
    required this.firestoreSvc,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

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

    await widget.firestoreSvc.sendDM(widget.dmId, message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.dark800 : Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.purple600.withAlpha(25),
              backgroundImage:
                  widget.otherUser.photoUrl != null
                      ? NetworkImage(widget.otherUser.photoUrl!)
                      : null,
              child:
                  widget.otherUser.photoUrl == null
                      ? Text(
                        widget.otherUser.fullName.characters.first
                            .toUpperCase(),
                        style: TextStyle(
                          color: AppColors.purple600,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '@${widget.otherUser.username}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.gray400 : AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: widget.firestoreSvc.dmMessagesStream(widget.dmId),
              builder: (ctx, snap) {
                final messages = snap.data ?? [];
                _scrollToBottom();
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.otherUser.fullName.split(' ').first}! 👋',
                      style: TextStyle(
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                        fontSize: 15,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder:
                      (_, i) => MessageBubble(
                        message: messages[i],
                        isMe: messages[i].senderId == widget.currentUid,
                      ),
                );
              },
            ),
          ),
          _buildInput(isDark),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dark600 : AppColors.gray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.gray900,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Message...',
                fillColor: isDark ? AppColors.dark700 : AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
