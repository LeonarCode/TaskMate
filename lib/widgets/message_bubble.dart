import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.purple600.withAlpha(25),
              backgroundImage:
                  message.senderPhotoUrl != null
                      ? NetworkImage(message.senderPhotoUrl!)
                      : null,
              child:
                  message.senderPhotoUrl == null
                      ? Text(
                        message.senderName.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.purple600,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderName.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple600,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color:
                        isMe
                            ? null
                            : (isDark ? AppColors.dark700 : AppColors.gray100),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow:
                        isMe
                            ? [
                              BoxShadow(
                                color: AppColors.purple600.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isMe
                              ? Colors.white
                              : (isDark ? Colors.white : AppColors.gray900),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.gray500 : AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
