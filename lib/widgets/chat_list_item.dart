// widgets/chat_list_item.dart
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../utils/app_theme.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        child: Text(
          chat.name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        style: const TextStyle(color: AppTheme.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(chat.lastTime),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
    } else if (date == DateTime(now.year, now.month, now.day - 1)) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year % 100}';
    }
  }
}