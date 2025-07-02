// widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../utils/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.cardBackground,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? AppTheme.primaryBlue 
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isMe 
                      ? const Radius.circular(16) 
                      : const Radius.circular(4),
                  bottomRight: message.isMe 
                      ? const Radius.circular(4) 
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: TextStyle(
                      color: message.isMe 
                          ? Colors.white70 
                          : AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.cardBackground,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}