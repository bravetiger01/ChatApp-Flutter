import 'package:cached_network_image/cached_network_image.dart';
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
        backgroundImage:
            (chat.profilePicURL != null && chat.profilePicURL!.isNotEmpty)
            ? CachedNetworkImageProvider(chat.profilePicURL!)
            : null,
        backgroundColor:
            (chat.profilePicURL == null || chat.profilePicURL!.isEmpty)
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
          fontWeight: chat.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'Say Hello ' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: chat.unreadCount > 0 ? Colors.white70 : AppTheme.textSecondary,
          fontWeight: chat.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
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
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unreadCount > 4 ? '4+' : '${chat.unreadCount}',
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
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final msgDate = DateTime(time.year, time.month, time.day);

    // Get yesterday's date (subtract 1 day)
    final yesterday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 1,
    );

    // Get a date 7 days ago
    final sevenDaysAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 6,
    );

    // msgDate is "within last 7 days" if it's >= that date

    if (msgDate == now) {
      // Today -> show 12 hour time
      final hour = time.hour == 0
          ? 12
          : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (!msgDate.isBefore(sevenDaysAgo)) {
      // Withing last seven days -> show weekday name
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[time.weekday - 1];
    } else {
      // Older -> show full date
      return '${time.day}/${time.month.toString().padLeft(2, '0')}/${time.year}';
    }
  }
}
