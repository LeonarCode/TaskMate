import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/server_model.dart';
import '../../models/task_model.dart';
import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../tasks/add_task_screen.dart';
import 'server_chat_view.dart';
import 'server_tasks_view.dart';
import 'server_members_view.dart';

class ServerDetailScreen extends StatefulWidget {
  final ServerModel server;
  final String uid;

  const ServerDetailScreen({
    super.key,
    required this.server,
    required this.uid,
  });

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  int _currentIndex = 0;

  void _confirmLeaveServer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwner = widget.server.ownerId == widget.uid;
    final title = isOwner ? 'Delete Server' : 'Leave Server';
    final content = isOwner 
        ? 'Are you sure you want to permanently delete ${widget.server.name}?'
        : 'Are you sure you want to leave ${widget.server.name}?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.dark800 : Colors.white,
        title: Text(
          title,
          style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
        ),
        content: Text(
          content,
          style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isOwner) {
                await FirestoreService().deleteServer(widget.server.id);
              } else {
                await FirestoreService().leaveServer(widget.server.id, widget.uid);
              }
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Exit server screen
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red500),
            child: Text(isOwner ? 'Delete' : 'Leave', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddServerTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(serverId: widget.server.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    switch (_currentIndex) {
      case 1:
        body = ServerChatView(serverId: widget.server.id);
        break;
      case 2:
        body = ServerTasksView(serverId: widget.server.id);
        break;
      case 3:
        body = ServerMembersView(server: widget.server);
        break;
      case 0:
      default:
        body = _buildOverview(isDark);
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: Text(widget.server.name),
        backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.server.ownerId == widget.uid ? Icons.delete_rounded : Icons.exit_to_app_rounded,
              color: AppColors.red500,
            ),
            tooltip: widget.server.ownerId == widget.uid ? 'Delete Server' : 'Leave Server',
            onPressed: _confirmLeaveServer,
          ),
        ],
      ),
      body: body,
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: _showAddServerTaskDialog,
              backgroundColor: AppColors.purple600,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.purple600,
        unselectedItemColor: isDark ? AppColors.gray500 : AppColors.gray400,
        backgroundColor: isDark ? AppColors.dark800 : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Members',
          ),
        ],
      ),
      // Handle the bottom inset manually if needed, but Scaffold does it by default
    );
  }

  Widget _buildOverview(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.server.iconEmoji ?? widget.server.name.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to ${widget.server.name}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.gray900,
              ),
            ),
            if (widget.server.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.server.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 24,
              children: [
                _buildStatColumn('Members', widget.server.memberIds.length, isDark),
                _buildStatColumn('Chats', widget.server.chats.length, isDark),
                _buildStatColumn('Tasks', widget.server.tasks.length, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, bool isDark) {
    return Column(
      children: [
        Text(
          count.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.gray400 : AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
