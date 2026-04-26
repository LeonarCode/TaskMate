import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/server_model.dart';
import '../../models/user_model.dart';
import '../../models/rating_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/image_utils.dart';

class ServerMembersView extends StatefulWidget {
  final ServerModel server;
  const ServerMembersView({super.key, required this.server});

  @override
  State<ServerMembersView> createState() => _ServerMembersViewState();
}

class _ServerMembersViewState extends State<ServerMembersView> {
  final _firestoreSvc = FirestoreService();

  Future<void> _showRatingDialog(UserModel member, UserModel currentUser) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double currentRating = 3.0;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.dark800 : Colors.white,
              title: Text('Rate ${member.fullName}', style: TextStyle(color: isDark ? Colors.white : AppColors.gray900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Leave a 1 to 5 star rating for this member:', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600)),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.amber500,
                          size: 32,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            currentRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final rating = RatingModel(
                      id: '${widget.server.id}_${currentUser.uid}', // Ensure unique per user per server
                      fromUid: currentUser.uid,
                      fromName: currentUser.fullName,
                      toUid: member.uid,
                      toName: member.fullName,
                      serverId: widget.server.id,
                      serverName: widget.server.name,
                      score: currentRating,
                      timestamp: DateTime.now(),
                    );
                    await _firestoreSvc.rateUser(rating);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple600),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.read<AuthProvider>().userModel;

    return FutureBuilder<List<UserModel>>(
      future: _firestoreSvc.getServerMembers(widget.server.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return Center(child: Text('No members found.', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600)));
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isMe = currentUser?.uid == member.uid;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.purple600.withAlpha(25),
                backgroundImage: resolvePhoto(member.photoUrl),
                child: member.photoUrl == null
                    ? Text(
                        member.fullName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.purple600,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              title: Text(
                member.fullName + (isMe ? ' (You)' : ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
              subtitle: Text(
                '@${member.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
              ),
              trailing: isMe ? null : IconButton(
                icon: const Icon(Icons.star_border_rounded, color: AppColors.amber500),
                tooltip: 'Rate Member',
                onPressed: () {
                  if (currentUser != null) {
                    _showRatingDialog(member, currentUser);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
