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
            ? NetworkImage(chat.profilePicURL!)
            : null,
        backgroundColor: chat.profilePicURL!.isEmpty
            ? AppTheme.cardBackground
            : Colors.transparent,
        child: (chat.profilePicURL == null || chat.profilePicURL!.isEmpty)
            ? const Icon(Icons.person, color: Colors.white)
            : null,
        radius: 24,
      ),
      title: Text(
        chat.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Text(
        _formatTime(chat.lastTime),
        style: Theme.of(context).textTheme.bodySmall,
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
