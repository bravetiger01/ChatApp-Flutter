import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../utils/app_theme.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: (chat.profilePicURL != null && chat.profilePicURL!.isNotEmpty)
            ? CachedNetworkImageProvider(chat.profilePicURL!)
            : null,
        backgroundColor: (chat.profilePicURL == null || chat.profilePicURL!.isEmpty)
            ? AppTheme.cardBackground
            : Colors.transparent,
        radius: 24,
        child: (chat.profilePicURL == null || chat.profilePicURL!.isEmpty)
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        chat.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'Say Hello ' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: chat.unreadCount > 0 ? Colors.white70 : AppTheme.textSecondary,
          fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(chat.lastTime),
            style: TextStyle(
              fontSize: 12,
              color: chat.unreadCount > 0
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
            ),
          ),
          if(chat.unreadCount > 0) ...[
            const SizedBox(height: 4,),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unreadCount > 4
                ? '4+'
                : '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
